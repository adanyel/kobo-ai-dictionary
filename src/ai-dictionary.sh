#!/bin/sh

KEY_FILE="/mnt/onboard/.adds/gemini.key"
CURL="/usr/bin/curl"
JQ="/usr/bin/jq"
SQLITE="/mnt/onboard/.adds/ai-tools/sqlite3"
UNZIP="/usr/bin/unzip"

DB="/mnt/onboard/.kobo/KoboReader.sqlite"
HTML="/mnt/onboard/.adds/ai-result.html"
TMP="/mnt/onboard/.adds/ai-result.tmp"

TEXT="$1"

# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------

KEY="$(tr -d '\r\n' < "$KEY_FILE" 2>/dev/null)"

if [ -z "$KEY" ]; then
    echo "ERRORE: API key Gemini non trovata."
    exit 1
fi

if [ -z "$TEXT" ]; then
    echo "Nessun testo."
    exit 1
fi

if [ ! -x "$SQLITE" ]; then
    echo "ERRORE: sqlite3 non trovato."
    exit 1
fi

if [ ! -x "$UNZIP" ]; then
    echo "ERRORE: unzip non trovato."
    exit 1
fi

# ------------------------------------------------------------
# Helpers for EPUB text normalization
# ------------------------------------------------------------

normalize_text() {
    sed \
        -e 's/\&nbsp;/ /g' \
        -e 's/\&#160;/ /g' \
        -e 's/\&#xA0;/ /g' \
        -e 's/\&#x00A0;/ /g' \
        -e 's/\&amp;/\&/g' \
        -e 's/\&quot;/"/g' \
        -e "s/\&apos;/'/g" \
        -e 's/\&#39;/'\''/g' \
        -e 's/\&#x2010;/-/g' \
        -e 's/\&#x2011;/-/g' \
        -e 's/\&#x201A;/-/g' \
        -e 's/\&#X2010;/-/g' \
        -e 's/\&#X2011;/-/g' \
        -e 's/\&#x2012;/-/g' \
        -e 's/\&#x2013;/-/g' \
        -e 's/\&#x2014;/-/g' \
        -e 's/\&#8208;/-/g' \
        -e 's/\&#8209;/-/g' \
        -e 's/\&#8210;/-/g' \
        -e 's/\&#8211;/-/g' \
        -e 's/\&#8212;/-/g' \
        -e 's/‐/-/g' \
        -e 's/-/-/g' \
        -e 's/‒/-/g' \
        -e 's/–/-/g' \
        -e 's/—/-/g' \
        -e 's/−/-/g' \
        -e 's/[[:space:]][[:space:]]*/ /g'
}

clean_epub_html() {
    sed \
        -e 's#</p>#\n#g' \
        -e 's#</div>#\n#g' \
        -e 's#</li>#\n#g' \
        -e 's#</h1>#\n#g' \
        -e 's#</h2>#\n#g' \
        -e 's#</h3>#\n#g' \
        -e 's#</h4>#\n#g' \
        -e 's#</h5>#\n#g' \
        -e 's#</h6>#\n#g' \
        -e 's#<br[^>]*>#\n#g' \
        -e 's#<[^>]*># #g' \
        -e 's#\&nbsp;# #g' \
        -e 's#\&#160;# #g' \
        -e 's#\&#xA0;# #g' \
        -e 's#\&amp;#\&#g' \
        -e 's#\&quot;#"#g' \
        -e "s#\&apos;#'#g" \
        -e 's#\&#39;#'\''#g' \
    | normalize_text \
    | tr -d '\302\255' \
    | sed 's/[[:space:]][[:space:]]*/ /g;s/^ *//;s/ *$//' \
    | awk 'length($0) > 0'
}

# ------------------------------------------------------------
# Current Kobo book + reading position
# ------------------------------------------------------------

BOOK=""
BOOK_TITLE=""
BOOK_AUTHOR=""
CFI=""
BOOK_CONTEXT=""
CONTEXT_SOURCE="nessuno"
EPUB=""
CHAPTER=""
FOUND=""
CTX="/mnt/onboard/.adds/ai-tools/kobo-context"

# Kobo puo' avere piu' record con ReadStatus=1.
# Non assumiamo che il primo sia il libro visibile:
# proviamo i candidati e scegliamo quello in cui kobo-context
# trova realmente la parola selezionata.

# Nickel/Kobo puo' passare parole con soft-hyphen (U+00AD):
# "go­ril­la" invece di "gorilla".
# TEXT resta invariato per la visualizzazione; TEXT_CLEAN viene usato
# per cercare il termine nel libro.
TEXT_CLEAN="$(printf '%s' "$TEXT" | tr -d '\302\255' | sed 's/[[:space:]][[:space:]]*/ /g')"

DEBUG_FILE="/mnt/onboard/.adds/ai-dictionary-debug.txt"
: > "$DEBUG_FILE" 2>/dev/null
printf 'TEXT_RAW=[%s]\n' "$TEXT" >> "$DEBUG_FILE"
printf 'TEXT_CLEAN=[%s]\n' "$TEXT_CLEAN" >> "$DEBUG_FILE"
printf 'CTX=[%s]\n' "$CTX" >> "$DEBUG_FILE"

CANDIDATES="$($SQLITE -readonly -noheader -batch "$DB" \
    "SELECT ContentID, COALESCE(Title,''), COALESCE(Attribution,''), COALESCE(ChapterIDBookmarked,'')
     FROM content
     WHERE ContentType=6 AND ReadStatus=1
       AND ContentID LIKE 'file:///mnt/onboard/%.epub%'
       AND COALESCE(ChapterIDBookmarked,'') <> ''
     ORDER BY DateLastRead DESC;" 2>/dev/null)"

printf '%s\n' '--- CANDIDATES ---' >> "$DEBUG_FILE"
printf '%s\n' "$CANDIDATES" >> "$DEBUG_FILE"

if [ -n "$CANDIDATES" ] && [ -x "$CTX" ]; then
    while IFS= read -r ROW; do
        [ -z "$ROW" ] && continue

        C_BOOK="$(printf '%s\n' "$ROW" | cut -d'|' -f1)"
        C_TITLE="$(printf '%s\n' "$ROW" | cut -d'|' -f2)"
        C_AUTHOR="$(printf '%s\n' "$ROW" | cut -d'|' -f3)"
        C_CFI="$(printf '%s\n' "$ROW" | cut -d'|' -f4)"

        case "$C_BOOK" in
            file:///mnt/onboard/*)
                C_EPUB="/mnt/onboard/${C_BOOK#file:///mnt/onboard/}"
                ;;
            *)
                C_EPUB=""
                ;;
        esac

        case "$C_EPUB" in
            *.epub\#*) C_EPUB="${C_EPUB%%#*}" ;;
        esac

        case "$C_CFI" in
            *"#point("*)
                C_CHAPTER="${C_CFI%%#point(*}"
                C_POINT="${C_CFI#*#point(}"
                C_POINT="${C_POINT%)}"
                C_POINT="point($C_POINT)"
                ;;
            *)
                {
                    printf '\n--- CANDIDATE SKIPPED ---\n'
                    printf 'TITLE=[%s]\n' "$C_TITLE"
                    printf 'REASON=CFI_NON_POINT\n'
                    printf 'CFI=[%s]\n' "$C_CFI"
                } >> "$DEBUG_FILE" 2>/dev/null
                continue
                ;;
        esac

        # Non verifichiamo piu' EPUB/chapter con unzip prima della chiamata:
        # kobo-context deve ricevere esattamente gli stessi argomenti gia'
        # verificati manualmente come funzionanti.
        C_TMP="/mnt/onboard/.adds/ai-kobo-context-candidate.txt"
        "$CTX" \
            -epub "$C_EPUB" \
            -chapter "$C_CHAPTER" \
            -cfi "$C_POINT" \
            -needle "$TEXT_CLEAN" \
            -max 7000 \
            > "$C_TMP" 2>/dev/null
        C_RC=$?
        C_CONTEXT="$(cat "$C_TMP" 2>/dev/null)"

        {
            printf '\n--- CANDIDATE TEST ---\n'
            printf 'TITLE=[%s]\n' "$C_TITLE"
            printf 'AUTHOR=[%s]\n' "$C_AUTHOR"
            printf 'EPUB=[%s]\n' "$C_EPUB"
            printf 'CHAPTER=[%s]\n' "$C_CHAPTER"
            printf 'POINT=[%s]\n' "$C_POINT"
            printf 'NEEDLE=[%s]\n' "$TEXT_CLEAN"
            printf 'KOBO_CONTEXT_RC=%s\n' "$C_RC"
            printf 'CONTEXT_LEN=%s\n' "${#C_CONTEXT}"
            printf '%s\n' "$C_CONTEXT"
        } >> "$DEBUG_FILE" 2>/dev/null

        if [ -n "$C_CONTEXT" ]; then
            BOOK="$C_BOOK"
            BOOK_TITLE="$C_TITLE"
            BOOK_AUTHOR="$C_AUTHOR"
            CFI="$C_CFI"
            EPUB="$C_EPUB"
            CHAPTER="$C_CHAPTER"
            FOUND="$C_CHAPTER"
            BOOK_CONTEXT="$C_CONTEXT"
            CONTEXT_SOURCE="posizione corrente del libro (kobo-context)"

            printf '%s\n' "$BOOK_CONTEXT" \
                > /mnt/onboard/.adds/ai-kobo-context.txt 2>/dev/null

            break
        fi

    done <<EOF_CANDIDATES
$CANDIDATES
EOF_CANDIDATES
fi

# Se nessun candidato ha prodotto contesto, manteniamo il record piu'
# recente solo per poter usare i fallback successivi.
if [ -z "$BOOK" ] && [ -n "$CANDIDATES" ]; then
    ROW="$(printf '%s\n' "$CANDIDATES" | head -n 1)"
    BOOK="$(printf '%s\n' "$ROW" | cut -d'|' -f1)"
    BOOK_TITLE="$(printf '%s\n' "$ROW" | cut -d'|' -f2)"
    BOOK_AUTHOR="$(printf '%s\n' "$ROW" | cut -d'|' -f3)"
    CFI="$(printf '%s\n' "$ROW" | cut -d'|' -f4)"
fi

[ -z "$BOOK_TITLE" ] && BOOK_TITLE="Libro non identificato"
[ -z "$BOOK_AUTHOR" ] && BOOK_AUTHOR="Autore non identificato"

if [ -z "$EPUB" ]; then
    case "$BOOK" in
        file:///mnt/onboard/*)
            EPUB="/mnt/onboard/${BOOK#file:///mnt/onboard/}"
            ;;
    esac
    case "$EPUB" in
        *.epub\#*) EPUB="${EPUB%%#*}" ;;
    esac
fi

if [ -z "$CHAPTER" ] && [ -n "$CFI" ]; then
    case "$CFI" in
        *"#point("*)
            CHAPTER="${CFI%%#point(*}"
            ;;
    esac
fi

if [ -z "$FOUND" ] && [ -f "$EPUB" ] && [ -n "$CHAPTER" ]; then
    if "$UNZIP" -Z1 "$EPUB" 2>/dev/null |
        grep -F -x -- "$CHAPTER" >/dev/null 2>&1
    then
        FOUND="$CHAPTER"
    else
        C_NAME="${CHAPTER##*/}"
        FOUND="$(
            "$UNZIP" -Z1 "$EPUB" 2>/dev/null |
            awk -v n="$C_NAME" '{
                b=$0
                sub(/^.*\//,"",b)
                if (tolower(b)==tolower(n)) {
                    print $0
                    exit
                }
            }'
        )"
    fi
fi

# Prima fonte: kobo-context con la parola normalizzata.
if [ -z "$BOOK_CONTEXT" ] &&
   [ -x "$CTX" ] &&
   [ -f "$EPUB" ] &&
   [ -n "$FOUND" ]
then
    case "$CFI" in
        *"#point("*)
            POINT="${CFI#*#point(}"
            POINT="${POINT%)}"
            POINT="point($POINT)"

            KOBO_TMP="/mnt/onboard/.adds/ai-kobo-context-primary.txt"
            "$CTX" \
                -epub "$EPUB" \
                -chapter "$FOUND" \
                -cfi "$POINT" \
                -needle "$TEXT_CLEAN" \
                -max 7000 \
                > "$KOBO_TMP" 2>/dev/null
            KOBO_RC=$?
            BOOK_CONTEXT="$(cat "$KOBO_TMP" 2>/dev/null)"
            printf 'PRIMARY_KOBO_CONTEXT_RC=%s\n' "$KOBO_RC" >> "$DEBUG_FILE" 2>/dev/null
            printf 'PRIMARY_KOBO_CONTEXT_LEN=%s\n' "${#BOOK_CONTEXT}" >> "$DEBUG_FILE" 2>/dev/null

            if [ -n "$BOOK_CONTEXT" ]; then
                CONTEXT_SOURCE="posizione corrente del libro (kobo-context)"
                printf '%s\n' "$BOOK_CONTEXT" \
                    > /mnt/onboard/.adds/ai-kobo-context.txt 2>/dev/null
            fi
            ;;
    esac
fi

# Fallback: lettura diretta del capitolo, mantenuto dal comportamento precedente.
if [ -z "$BOOK_CONTEXT" ] && [ -n "$FOUND" ] && [ -f "$EPUB" ]; then
    RAW="/mnt/onboard/.adds/ai-context-raw.html"
    CLEAN="/mnt/onboard/.adds/ai-context-clean.txt"
    NORM="/mnt/onboard/.adds/ai-context-normalized.txt"
    "$UNZIP" -p "$EPUB" "$FOUND" > "$RAW" 2>/dev/null
    if [ -s "$RAW" ]; then
        clean_epub_html < "$RAW" > "$CLEAN"
        cp "$CLEAN" "$NORM" 2>/dev/null
        MATCHES="$(grep -iF -n -m 5 -- "$TEXT_CLEAN" "$NORM" 2>/dev/null)"
        if [ -z "$MATCHES" ]; then
            NEEDLE_COMPACT="$(printf '%s' "$TEXT_CLEAN" | sed 's/[[:space:]-]//g' | tr '[:upper:]' '[:lower:]')"
            MATCHES="$(awk -v n="$NEEDLE_COMPACT" '{x=$0;gsub(/[[:space:]-]/,"",x);x=tolower(x);if(index(x,n))print NR ":" $0}' "$NORM" 2>/dev/null | head -n 5)"
        fi
        if [ -n "$MATCHES" ]; then
            BOOK_CONTEXT="$(printf '%s\n' "$MATCHES" | while IFS=: read -r LN REST; do [ -z "$LN" ] && continue; START=$((LN-1)); [ "$START" -lt 1 ] && START=1; END=$((LN+1)); sed -n "${START},${END}p" "$NORM"; printf '\n'; done | head -c 7000)"
            CONTEXT_SOURCE="occorrenza esatta nel capitolo corrente"
        fi
    fi
fi

# Fallback: search the entire EPUB
# ------------------------------------------------------------

if [ -z "$BOOK_CONTEXT" ] &&
   [ -n "$EPUB" ] &&
   [ -f "$EPUB" ]
then

    ALLRAW="/mnt/onboard/.adds/ai-all-book-raw.txt"
    ALLTXT="/mnt/onboard/.adds/ai-all-book.txt"

    : > "$ALLRAW"

    "$UNZIP" -Z1 "$EPUB" 2>/dev/null |
        grep -Ei '\.(xhtml|html|htm)$' |
        while IFS= read -r F; do

            printf '\n---FILE:%s---\n' "$F"

            "$UNZIP" -p "$EPUB" "$F" 2>/dev/null

            printf '\n'

        done > "$ALLRAW"

    if [ -s "$ALLRAW" ]; then

        clean_epub_html < "$ALLRAW" > "$ALLTXT"

        MATCH_LINE="$(
            grep -iF -n -m 1 -- \
                "$TEXT_CLEAN" \
                "$ALLTXT" \
                2>/dev/null
        )"

        if [ -z "$MATCH_LINE" ]; then

            NEEDLE_COMPACT="$(
                printf '%s' "$TEXT_CLEAN" |
                sed 's/[[:space:]-]//g' |
                tr '[:upper:]' '[:lower:]'
            )"

            MATCH_LINE="$(
                awk -v n="$NEEDLE_COMPACT" '
                {
                    x=$0
                    gsub(/[[:space:]-]/,"",x)
                    x=tolower(x)

                    if (index(x,n)) {
                        print NR ":" $0
                        exit
                    }
                }' \
                "$ALLTXT" \
                2>/dev/null
            )"
        fi

        if [ -n "$MATCH_LINE" ]; then

            LN="${MATCH_LINE%%:*}"

            START=$((LN-2))
            [ "$START" -lt 1 ] && START=1

            END=$((LN+2))

            BOOK_CONTEXT="$(
                sed -n "${START},${END}p" "$ALLTXT" |
                head -c 7000
            )"

            CONTEXT_SOURCE="occorrenza esatta trovata nel libro"
        fi
    fi
fi

# ------------------------------------------------------------
# No context
# ------------------------------------------------------------

if [ -z "$BOOK_CONTEXT" ]; then

    BOOK_CONTEXT="[NESSUN PASSAGGIO SPECIFICO RECUPERATO DAL LIBRO]"

    CONTEXT_SOURCE="nessun passaggio specifico recuperato"

fi

# ------------------------------------------------------------
# Gemini prompt
# ------------------------------------------------------------

PROMPT=$(cat <<EOF2
Sei un dizionario AI per un lettore italiano che legge e studia
inglese, spagnolo e italiano.

TESTO CERCATO:
$TEXT

TITOLO DELL'OPERA:
$BOOK_TITLE

AUTORE:
$BOOK_AUTHOR

NOME FILE EPUB:
${EPUB##*/}

FONTE DEL CONTESTO:
$CONTEXT_SOURCE

CONTESTO ESTRATTO DAL LIBRO:
$BOOK_CONTEXT

INTERPRETAZIONE DEL CONTESTO:

Il titolo dell'opera e l'autore sono informazioni importanti e devono essere
usati attivamente per interpretare il termine.

Non limitarti automaticamente al significato generale da dizionario.

Se il termine è usato nell'opera come nome proprio, nome di luogo, nome di un
locale, bar, ristorante, persona, personaggio, marchio, titolo, oggetto,
espressione particolare o altra entità specifica, considera seriamente questa
interpretazione.

Usa insieme:
- il termine cercato;
- il brano recuperato dal libro, quando disponibile;
- il titolo dell'opera;
- l'autore;
- la tua conoscenza dell'opera e del suo contenuto.

Se conosci il riferimento specifico nell'opera, utilizzalo per spiegare il
significato contestuale.

Se il brano recuperato contiene l'occorrenza, privilegia ciò che emerge dal
brano.

Se il brano non contiene l'occorrenza ma titolo, autore e conoscenza dell'opera
permettono di identificare un riferimento specifico, puoi utilizzarlo.
Distingui però nel campo "contesto" ciò che deriva dal brano da ciò che deriva
dalla conoscenza dell'opera.

Non inventare citazioni del libro.

Non inventare un passaggio inesistente.

Se non puoi stabilire con sufficiente sicurezza il riferimento specifico,
fornisci comunque la spiegazione lessicale generale più utile e indica
l'incertezza.

Non trasformare automaticamente un nome proprio in un significato comune solo
perché quest'ultimo è più noto.

REGOLE LINGUISTICHE:

- identifica automaticamente inglese, spagnolo o italiano;
- tutte le spiegazioni sono in italiano;
- traduci sempre nelle altre due lingue;
- per una frase traduci nelle altre due lingue;
- per un nome proprio non forzare una traduzione letterale.

ETIMOLOGIA:

Spiega davvero l'etimologia: forma o radice antica, significato originario,
eventuali passaggi intermedi e sviluppo del significato.

Non limitarti a dire "deriva dal latino/greco".

Non inventare collegamenti.

Se l'etimologia è incerta o controversa, dichiaralo.

ELI5:

Spiega il concetto in modo molto semplice.

STILE:

- conciso ma informativo;
- tono da buon dizionario;
- niente introduzioni inutili;
- niente conclusioni inutili;
- niente tabelle;
- niente elenchi numerati;
- usa corsivo o grassetto quando utile.

Devi restituire SOLO il JSON richiesto dallo schema.

Tutte le proprietà devono essere presenti.

Quando una voce non è pertinente, restituisci una stringa vuota.
EOF2
)

# ------------------------------------------------------------
# JSON schema
# ------------------------------------------------------------

RESPONSE_SCHEMA='{
  "type": "OBJECT",
  "properties": {
    "language": {"type": "STRING"},
    "category": {"type": "STRING"},
    "pronunciation": {"type": "STRING"},
    "meaning": {"type": "STRING"},
    "context": {"type": "STRING"},
    "etymology": {"type": "STRING"},
    "eli5": {"type": "STRING"},
    "synonyms": {"type": "STRING"},
    "translations": {"type": "STRING"},
    "collocations": {"type": "STRING"},
    "example": {"type": "STRING"},
    "example_translation": {"type": "STRING"},
    "usage": {"type": "STRING"},
    "false_friend": {"type": "STRING"},
    "grammar": {"type": "STRING"}
  },
  "required": [
    "language",
    "category",
    "pronunciation",
    "meaning",
    "context",
    "etymology",
    "eli5",
    "synonyms",
    "translations",
    "collocations",
    "example",
    "example_translation",
    "usage",
    "false_friend",
    "grammar"
  ]
}'

REQUEST="$(
    "$JQ" -n \
        --arg prompt "$PROMPT" \
        --argjson schema "$RESPONSE_SCHEMA" \
        '{
            contents: [
                {
                    parts: [
                        {
                            text: $prompt
                        }
                    ]
                }
            ],
            generationConfig: {
                maxOutputTokens: 1300,
                temperature: 0.2,
                responseMimeType: "application/json",
                responseSchema: $schema
            }
        }'
)"

RESPONSE="$(
    "$CURL" -sk --max-time 15 \
        -X POST \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent" \
        -H "x-goog-api-key: $KEY" \
        -H "Content-Type: application/json" \
        -d "$REQUEST" \
        2>/dev/null
)"

JSON_TEXT="$(
    printf '%s' "$RESPONSE" |
    "$JQ" -r '
        if .error then
            empty
        else
            .candidates[0].content.parts[0].text // empty
        end
    '
)"

if [ -z "$JSON_TEXT" ]; then

    ERROR="$(
        printf '%s' "$RESPONSE" |
        "$JQ" -r \
            '.error.message // "Nessuna risposta da Gemini."' \
            2>/dev/null
    )"

    printf 'ERRORE Gemini: %s\n' "$ERROR"

    exit 1
fi

if ! printf '%s' "$JSON_TEXT" |
    "$JQ" empty >/dev/null 2>&1
then

    echo "ERRORE: risposta JSON non valida."

    exit 1
fi

# ------------------------------------------------------------
# HTML helpers
# ------------------------------------------------------------

escape_html() {

    printf '%s' "$1" |
    sed \
        -e 's/\&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g'
}

format_inline() {

    ESCAPED="$(escape_html "$1")"

    printf '%s' "$ESCAPED" |
    sed \
        -e 's/\*\*\([^*][^*]*\)\*\*/<strong>\1<\/strong>/g' \
        -e 's/\*\([^*][^*]*\)\*/<em>\1<\/em>/g'
}

render_field() {

    LABEL="$1"
    VALUE="$2"

    [ -z "$VALUE" ] && return 0

    printf \
        '<div class="section"><span class="label">%s:</span> %s</div>\n' \
        "$LABEL" \
        "$(format_inline "$VALUE")" \
        >> "$TMP"
}

render_translation_lines() {

    VALUE="$1"

    [ -z "$VALUE" ] && return 0

    printf \
        '<div class="section"><span class="label">Traduzioni:</span></div>\n' \
        >> "$TMP"

    printf '%s\n' "$VALUE" |
    while IFS= read -r LINE || [ -n "$LINE" ]; do

        LINE="$(
            printf '%s' "$LINE" |
            sed 's/^ *//;s/ *$//'
        )"

        [ -z "$LINE" ] && continue

        case "$LINE" in

            Italiano:*)

                V="${LINE#Italiano:}"

                printf \
                    '<div class="translation"><span class="label">Italiano:</span> %s</div>\n' \
                    "$(format_inline "$(printf '%s' "$V" | sed 's/^ *//')")" \
                    >> "$TMP"
                ;;

            Inglese:*)

                V="${LINE#Inglese:}"

                printf \
                    '<div class="translation"><span class="label">Inglese:</span> %s</div>\n' \
                    "$(format_inline "$(printf '%s' "$V" | sed 's/^ *//')")" \
                    >> "$TMP"
                ;;

            Spagnolo:*)

                V="${LINE#Spagnolo:}"

                printf \
                    '<div class="translation"><span class="label">Spagnolo:</span> %s</div>\n' \
                    "$(format_inline "$(printf '%s' "$V" | sed 's/^ *//')")" \
                    >> "$TMP"
                ;;

            *)

                printf \
                    '<div class="translation">%s</div>\n' \
                    "$(format_inline "$LINE")" \
                    >> "$TMP"
                ;;
        esac

    done
}

# ------------------------------------------------------------
# Build HTML
# ------------------------------------------------------------

cat > "$TMP" <<'EOF3'
<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
>

<style>

html,body{
    margin:0;
    padding:0;
    background:#fff;
    color:#111
}

body{
    font-family:Georgia,"Times New Roman",serif;
    font-size:21px;
    line-height:1.25;
    padding:16px 22px 24px 22px;
    box-sizing:border-box
}

.card{
    width:100%;
    margin:0
}

.headword{
    font-size:28px;
    line-height:1.10;
    font-weight:700;
    margin:0 0 4px 0;
    overflow-wrap:anywhere
}

.subhead{
    font-size:16px;
    line-height:1.25;
    font-style:italic;
    color:#333;
    margin:0 0 10px 0
}

.rule{
    border:0;
    border-top:1px solid #777;
    margin:0 0 13px 0
}

.section{
    margin:0 0 9px 0
}

.label{
    font-weight:700
}

.translation{
    margin-left:10px;
    margin-bottom:5px
}

.example{
    margin:5px 0 8px 8px;
    padding-left:10px;
    border-left:3px solid #777;
    font-style:italic
}

.eli5{
    margin-left:0;
    padding-left:10px;
    border-left:3px solid #999
}

.bookctx{
    margin:6px 0 12px 8px;
    padding:8px 10px;
    border-left:3px solid #555;
    font-size:19px;
    line-height:1.25;
    font-style:italic
}

.small{
    font-size:17px;
    color:#444
}

.prompt-rule{
    margin-top:18px;
    margin-bottom:8px
}

.prompt-title{
    font-size:14px;
    font-weight:700;
    color:#555;
    margin-bottom:5px
}

.prompt-box{
    font-family:monospace;
    font-size:11px;
    line-height:1.25;
    color:#555;
    white-space:pre-wrap;
    overflow-wrap:anywhere;
    margin-bottom:12px
}

em{
    font-style:italic
}

strong{
    font-weight:700
}

</style>

</head>

<body>

<div class="card">

EOF3

HEADWORD="$(
    printf '%s' "$TEXT" |
    tr '\n' ' ' |
    sed 's/[[:space:]][[:space:]]*/ /g;s/^ *//;s/ *$//'
)"

printf \
    '<div class="headword">%s</div>\n' \
    "$(escape_html "$HEADWORD")" \
    >> "$TMP"

printf \
    '<div class="small"><strong>%s</strong> · %s</div>\n' \
    "$(escape_html "$BOOK_TITLE")" \
    "$(escape_html "$BOOK_AUTHOR")" \
    >> "$TMP"

printf '<hr class="rule">\n' >> "$TMP"

# ------------------------------------------------------------
# Extract Gemini fields
# ------------------------------------------------------------

LANGUAGE="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.language // ""'
)"

CATEGORY="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.category // ""'
)"

PRONUNCIATION="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.pronunciation // ""'
)"

MEANING="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.meaning // ""'
)"

CONTEXT="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.context // ""'
)"

ETYMOLOGY="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.etymology // ""'
)"

ELI5="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.eli5 // ""'
)"

SYNONYMS="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.synonyms // ""'
)"

TRANSLATIONS="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.translations // ""'
)"

COLLOCATIONS="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.collocations // ""'
)"

EXAMPLE="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.example // ""'
)"

EXAMPLE_TRANSLATION="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.example_translation // ""'
)"

USAGE="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.usage // ""'
)"

FALSE_FRIEND="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.false_friend // ""'
)"

GRAMMAR="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.grammar // ""'
)"

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

if [ -n "$LANGUAGE" ]; then

    printf \
        '<div class="subhead">%s' \
        "$(escape_html "$LANGUAGE")" \
        >> "$TMP"

    [ -n "$CATEGORY" ] &&
        printf \
            ' · %s' \
            "$(escape_html "$CATEGORY")" \
            >> "$TMP"

    printf '</div>\n' >> "$TMP"
fi

# ------------------------------------------------------------
# Dictionary fields
# ------------------------------------------------------------

render_field "Pronuncia" "$PRONUNCIATION"

render_field "Significato" "$MEANING"

render_field "Contesto" "$CONTEXT"

render_field "Etimologia" "$ETYMOLOGY"

# ------------------------------------------------------------
# Book context
# ------------------------------------------------------------

printf \
    '<div class="section small"><span class="label">Dal libro (%s):</span></div>\n' \
    "$(escape_html "$CONTEXT_SOURCE")" \
    >> "$TMP"

if [ -n "$BOOK_CONTEXT" ]; then

    printf \
        '<div class="bookctx">%s</div>\n' \
        "$(format_inline "$BOOK_CONTEXT")" \
        >> "$TMP"

fi

# ------------------------------------------------------------
# Remaining fields
# ------------------------------------------------------------

if [ -n "$ELI5" ]; then

    printf \
        '<div class="section eli5"><span class="label">ELI5:</span> %s</div>\n' \
        "$(format_inline "$ELI5")" \
        >> "$TMP"

fi

render_field "Sinonimi" "$SYNONYMS"

render_translation_lines "$TRANSLATIONS"

render_field "Collocazioni" "$COLLOCATIONS"

if [ -n "$EXAMPLE" ]; then

    printf \
        '<div class="example"><span class="label">Esempio:</span> %s</div>\n' \
        "$(format_inline "$EXAMPLE")" \
        >> "$TMP"

fi

render_field "Traduzione" "$EXAMPLE_TRANSLATION"

render_field "Uso" "$USAGE"

render_field "Falso amico" "$FALSE_FRIEND"

render_field "Grammatica" "$GRAMMAR"

# ------------------------------------------------------------
# Prompt transparency
# ------------------------------------------------------------

printf '<hr class="rule prompt-rule">\n' >> "$TMP"

printf \
    '<div class="prompt-title">Prompt utilizzato:</div>\n' \
    >> "$TMP"

printf \
    '<div class="prompt-box">%s</div>\n' \
    "$(escape_html "$PROMPT")" \
    >> "$TMP"

cat >> "$TMP" <<'EOF4'

</div>

</body>
</html>

EOF4

# ------------------------------------------------------------
# Save result
# ------------------------------------------------------------

mv "$TMP" "$HTML"

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

rm -f \
    /mnt/onboard/.adds/ai-kobo-context.txt \
    /mnt/onboard/.adds/ai-context-raw.html \
    /mnt/onboard/.adds/ai-context-clean.txt \
    /mnt/onboard/.adds/ai-context-normalized.txt \
    /mnt/onboard/.adds/ai-all-book-raw.txt \
    /mnt/onboard/.adds/ai-all-book.txt \
    2>/dev/null

exit 0