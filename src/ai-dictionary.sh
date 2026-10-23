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
    echo "ERROR: Gemini API key not found."
    exit 1
fi

if [ -z "$TEXT" ]; then
    echo "No text selected."
    exit 1
fi

if [ ! -x "$SQLITE" ]; then
    echo "ERROR: sqlite3 not found."
    exit 1
fi

if [ ! -x "$UNZIP" ]; then
    echo "ERROR: unzip not found."
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
# Book-language detection and localized UI
# ------------------------------------------------------------

detect_epub_language() {
    EPUB_FILE="$1"

    [ -f "$EPUB_FILE" ] || return 1

    CONTAINER_XML="$(
        "$UNZIP" -p "$EPUB_FILE" "META-INF/container.xml" 2>/dev/null |
        tr '\n' ' '
    )"

    OPF_PATH="$(
        printf '%s' "$CONTAINER_XML" |
        sed -n 's/.*full-path="\([^"]*\)".*/\1/p' |
        head -n 1
    )"

    [ -n "$OPF_PATH" ] || return 1

    OPF_XML="$(
        "$UNZIP" -p "$EPUB_FILE" "$OPF_PATH" 2>/dev/null |
        tr '\n' ' '
    )"

    EPUB_LANG="$(
        printf '%s' "$OPF_XML" |
        sed -n             -e 's#.*<dc:language[^>]*>\([^<]*\)</dc:language>.*#\1#p'             -e 's#.*<language[^>]*>\([^<]*\)</language>.*#\1#p' |
        head -n 1 |
        sed 's/^ *//;s/ *$//' |
        tr '[:upper:]' '[:lower:]'
    )"

    case "$EPUB_LANG" in
        it|it-*|ita|italian|italiano)
            printf 'it'
            ;;
        en|en-*|eng|english)
            printf 'en'
            ;;
        es|es-*|spa|spanish|español|espanol)
            printf 'es'
            ;;
        *)
            return 1
            ;;
    esac
}

detect_text_language() {
    printf '%s' "$1" |
    awk '
    {
        text=tolower($0)
        gsub(/[^a-z]+/, " ", text)
        n=split(text, w, / +/)

        for (i=1; i<=n; i++) {
            t=w[i]

            if (t=="the" || t=="and" || t=="that" || t=="this" ||
                t=="with" || t=="was" || t=="were" || t=="have" ||
                t=="had" || t=="from" || t=="but" || t=="his" ||
                t=="her" || t=="they" || t=="you" || t=="not")
                en++

            if (t=="che" || t=="della" || t=="delle" || t=="degli" ||
                t=="questo" || t=="questa" || t=="anche" || t=="sono" ||
                t=="non" || t=="nel" || t=="nella" || t=="gli" ||
                t=="dei" || t=="dai" || t=="dove")
                it++

            if (t=="que" || t=="los" || t=="las" || t=="del" ||
                t=="pero" || t=="como" || t=="por" || t=="para" ||
                t=="estaba" || t=="esto" || t=="esta" || t=="sus" ||
                t=="muy" || t=="sin" || t=="desde")
                es++
        }
    }
    END {
        if (en > it && en > es && en > 0)
            print "en"
        else if (es > it && es > en && es > 0)
            print "es"
        else if (it > 0)
            print "it"
    }'
}

set_ui_labels() {
    case "$1" in
        it)
            OUTPUT_LANGUAGE="Italian"
            L_PRONUNCIATION="Pronuncia"
            L_MEANING="Significato"
            L_CONTEXT="Contesto"
            L_ETYMOLOGY="Etimologia"
            L_FROM_BOOK="Dal libro"
            L_SYNONYMS="Sinonimi"
            L_COLLOCATIONS="Collocazioni"
            L_EXAMPLE="Esempio"
            L_TRANSLATION="Traduzione"
            L_USAGE="Uso"
            L_FALSE_FRIEND="Falso amico"
            L_GRAMMAR="Grammatica"
            L_LANG_IT="Italiano"
            L_LANG_EN="Inglese"
            L_LANG_ES="Spagnolo"
            ;;
        es)
            OUTPUT_LANGUAGE="Spanish"
            L_PRONUNCIATION="Pronunciación"
            L_MEANING="Significado"
            L_CONTEXT="Contexto"
            L_ETYMOLOGY="Etimología"
            L_FROM_BOOK="Del libro"
            L_SYNONYMS="Sinónimos"
            L_COLLOCATIONS="Colocaciones"
            L_EXAMPLE="Ejemplo"
            L_TRANSLATION="Traducción"
            L_USAGE="Uso"
            L_FALSE_FRIEND="Falso amigo"
            L_GRAMMAR="Gramática"
            L_LANG_IT="Italiano"
            L_LANG_EN="Inglés"
            L_LANG_ES="Español"
            ;;
        *)
            OUTPUT_LANGUAGE="English"
            L_PRONUNCIATION="Pronunciation"
            L_MEANING="Meaning"
            L_CONTEXT="Context"
            L_ETYMOLOGY="Etymology"
            L_FROM_BOOK="From the book"
            L_SYNONYMS="Synonyms"
            L_COLLOCATIONS="Collocations"
            L_EXAMPLE="Example"
            L_TRANSLATION="Translation"
            L_USAGE="Usage"
            L_FALSE_FRIEND="False friend"
            L_GRAMMAR="Grammar"
            L_LANG_IT="Italian"
            L_LANG_EN="English"
            L_LANG_ES="Spanish"
            ;;
    esac
}

make_display_context() {
    FULL_CONTEXT="$1"
    NEEDLE="$2"

    case "$FULL_CONTEXT" in
        ""|"[NO SPECIFIC PASSAGE RETRIEVED FROM THE BOOK]")
            return 0
            ;;
    esac

    printf '%s' "$FULL_CONTEXT" |
    tr '\r\n\t' '   ' |
    sed 's/[[:space:]][[:space:]]*/ /g;s/^ *//;s/ *$//' |
    awk -v needle="$NEEDLE" '
    {
        text=$0
        low=tolower(text)
        n=tolower(needle)
        pos=index(low,n)
        maxlen=560

        if (length(text) <= maxlen) {
            print text
            exit
        }

        if (pos > 0) {
            start=pos-180
            if (start < 1)
                start=1
        } else {
            start=1
        }

        out=substr(text,start,maxlen)

        if (start > 1) {
            sub(/^[^ ]* /,"",out)
            out="… " out
        }

        if (start+maxlen <= length(text)) {
            sub(/ [^ ]*$/,"",out)
            out=out " …"
        }

        print out
        exit
    }'
}

# ------------------------------------------------------------
# Current Kobo book + reading position
# ------------------------------------------------------------

BOOK=""
BOOK_TITLE=""
BOOK_AUTHOR=""
CFI=""
BOOK_CONTEXT=""
CONTEXT_SOURCE="none"
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
            CONTEXT_SOURCE="current book position (kobo-context)"

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

[ -z "$BOOK_TITLE" ] && BOOK_TITLE="Book not identified"
[ -z "$BOOK_AUTHOR" ] && BOOK_AUTHOR="Author not identified"

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
                CONTEXT_SOURCE="current book position (kobo-context)"
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
            CONTEXT_SOURCE="exact occurrence in current chapter"
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

            CONTEXT_SOURCE="exact occurrence found in book"
        fi
    fi
fi

# ------------------------------------------------------------
# No context
# ------------------------------------------------------------

if [ -z "$BOOK_CONTEXT" ]; then

    BOOK_CONTEXT="[NO SPECIFIC PASSAGE RETRIEVED FROM THE BOOK]"

    CONTEXT_SOURCE="no specific passage retrieved"

fi

# ------------------------------------------------------------
# Detect book language locally, without an extra API request
# ------------------------------------------------------------

BOOK_LANG="$(detect_epub_language "$EPUB" 2>/dev/null)"

if [ -z "$BOOK_LANG" ]; then
    BOOK_LANG="$(detect_text_language "$BOOK_CONTEXT")"
fi

# English is the project default when language detection is uncertain.
[ -z "$BOOK_LANG" ] && BOOK_LANG="en"

set_ui_labels "$BOOK_LANG"

BOOK_CONTEXT_DISPLAY="$(make_display_context "$BOOK_CONTEXT" "$TEXT_CLEAN")"

printf 'BOOK_LANG=[%s]\n' "$BOOK_LANG" >> "$DEBUG_FILE" 2>/dev/null
printf 'BOOK_CONTEXT_DISPLAY_LEN=%s\n' "${#BOOK_CONTEXT_DISPLAY}" >> "$DEBUG_FILE" 2>/dev/null

# Localize generic missing metadata only after the book language is known.
case "$BOOK_LANG" in
    it)
        [ "$BOOK_TITLE" = "Book not identified" ] && BOOK_TITLE="Libro non identificato"
        [ "$BOOK_AUTHOR" = "Author not identified" ] && BOOK_AUTHOR="Autore non identificato"
        ;;
    es)
        [ "$BOOK_TITLE" = "Book not identified" ] && BOOK_TITLE="Libro no identificado"
        [ "$BOOK_AUTHOR" = "Author not identified" ] && BOOK_AUTHOR="Autor no identificado"
        ;;
esac

# ------------------------------------------------------------
# Gemini prompt
# ------------------------------------------------------------

PROMPT=$(cat <<EOF2
You are a contextual AI dictionary for a book reader.

SELECTED TEXT:
$TEXT

BOOK TITLE:
$BOOK_TITLE

AUTHOR:
$BOOK_AUTHOR

EPUB FILE NAME:
${EPUB##*/}

BOOK LANGUAGE DETECTED LOCALLY:
$BOOK_LANG

INTERFACE AND EXPLANATION LANGUAGE:
$OUTPUT_LANGUAGE

CONTEXT SOURCE:
$CONTEXT_SOURCE

CONTEXT EXTRACTED FROM THE BOOK:
$BOOK_CONTEXT

CONTEXT INTERPRETATION:

The book title and author are important information and must be actively used
to interpret the selected text.

Do not automatically limit the answer to the most common dictionary meaning.

If the selected text is used in the work as a proper noun, place name, venue,
bar, restaurant, person, character, brand, title, object, special expression,
or another specific entity, seriously consider that interpretation.

Use together:
- the selected text;
- the passage retrieved from the book, when available;
- the book title;
- the author;
- your reliable knowledge of the work and its content.

If you know the specific reference in the work, use it to explain the
contextual meaning.

If the retrieved passage contains the occurrence, prioritize what is supported
by that passage.

If the passage does not contain the occurrence but the title, author, and
reliable knowledge of the work allow a specific reference to be identified,
you may use that knowledge. In the "context" field, distinguish what comes
from the retrieved passage from what comes from knowledge of the work.

Never invent quotations from the book.
Never invent a passage that is not present.

If the specific reference cannot be established with sufficient confidence,
still provide the most useful general lexical explanation and state the
uncertainty.

Do not automatically turn a proper noun into a common meaning simply because
the common meaning is better known.

LANGUAGE RULES:

- automatically identify whether the selected text is English, Italian, or Spanish;
- write ALL explanations in the interface language: $OUTPUT_LANGUAGE;
- the values of "language" and "category" must also be in $OUTPUT_LANGUAGE;
- preserve quotations and book excerpts in their original language;
- translate the selected word or phrase into the other two supported languages;
- in the "translations" field, use stable technical prefixes, one per line:
  IT:, EN:, ES:;
- do not include the source language in "translations";
- do not force literal translations for proper nouns.

ETYMOLOGY:

Explain the etymology properly: ancient or root form, original meaning,
relevant intermediate stages, and development of the modern meaning.

Do not stop at statements such as "from Latin/Greek".
Do not invent connections.
If the etymology is uncertain or disputed, say so.

ELI5:

Explain the concept in very simple language, always in $OUTPUT_LANGUAGE.

STYLE:

- concise but informative;
- good dictionary tone;
- no unnecessary introductions or conclusions;
- no tables;
- no numbered lists;
- use italics or bold only when useful;
- do not repeat field names inside field values.

Return ONLY the JSON required by the schema.
All properties must be present.
When a field is not relevant, return an empty string.
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
            '.error.message // "No response from Gemini."' \
            2>/dev/null
    )"

    printf 'Gemini ERROR: %s\n' "$ERROR"

    exit 1
fi

if ! printf '%s' "$JSON_TEXT" |
    "$JQ" empty >/dev/null 2>&1
then

    echo "ERROR: invalid JSON response."

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

    printf '%s\n' "$VALUE" |
    while IFS= read -r LINE || [ -n "$LINE" ]; do

        LINE="$(
            printf '%s' "$LINE" |
            sed 's/^ *//;s/ *$//'
        )"

        [ -z "$LINE" ] && continue

        case "$LINE" in

            IT:*|Italiano:*|Italian:*)

                V="${LINE#*:}"

                printf \
                    '<div class="translation"><span class="label">%s:</span> %s</div>\n' \
                    "$L_LANG_IT" \
                    "$(format_inline "$(printf '%s' "$V" | sed 's/^ *//')")" \
                    >> "$TMP"
                ;;

            EN:*|Inglese:*|English:*|Inglés:*)

                V="${LINE#*:}"

                printf \
                    '<div class="translation"><span class="label">%s:</span> %s</div>\n' \
                    "$L_LANG_EN" \
                    "$(format_inline "$(printf '%s' "$V" | sed 's/^ *//')")" \
                    >> "$TMP"
                ;;

            ES:*|Spagnolo:*|Spanish:*|Español:*)

                V="${LINE#*:}"

                printf \
                    '<div class="translation"><span class="label">%s:</span> %s</div>\n' \
                    "$L_LANG_ES" \
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
# Build reader HTML
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
    font-size:20px;
    line-height:1.34;
    padding:18px 20px 26px 20px;
    box-sizing:border-box
}

.card{
    width:100%;
    margin:0
}

.headword{
    font-size:30px;
    line-height:1.08;
    font-weight:700;
    margin:0 0 5px 0;
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
    margin:0 0 10px 0
}

.label{
    font-weight:700
}

.translation{
    margin:0 0 7px 0
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
    margin:3px 0 13px 0;
    padding:7px 10px 7px 11px;
    border-left:2px solid #777;
    font-size:17px;
    line-height:1.35;
    color:#333
}

.bookctx-text{
    font-style:italic
}

.small{
    font-size:17px;
    color:#444
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

LANGUAGE="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.language // ""'
)"

CATEGORY="$(
    printf '%s' "$JSON_TEXT" |
    "$JQ" -r '.category // ""'
)"

HEADWORD="$(
    printf '%s' "$TEXT" |
    tr '\n' ' ' |
    sed 's/[[:space:]][[:space:]]*/ /g;s/^ *//;s/ *$//'
)"

printf \
    '<div class="headword">%s</div>\n' \
    "$(escape_html "$HEADWORD")" \
    >> "$TMP"

if [ -n "$LANGUAGE" ]; then
    printf \
        '<div class="subhead">%s' \
        "$(escape_html "$LANGUAGE")" \
        >> "$TMP"

    [ -n "$CATEGORY" ] &&
        printf ' · %s' "$(escape_html "$CATEGORY")" >> "$TMP"

    printf '</div>\n' >> "$TMP"
fi

printf \
    '<div class="small"><strong>%s</strong> · %s</div>\n' \
    "$(escape_html "$BOOK_TITLE")" \
    "$(escape_html "$BOOK_AUTHOR")" \
    >> "$TMP"

printf '<hr class="rule">\n' >> "$TMP"

# ------------------------------------------------------------
# Extract Gemini fields
# ------------------------------------------------------------

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
# Dictionary fields
# ------------------------------------------------------------

render_field "$L_PRONUNCIATION" "$PRONUNCIATION"

render_field "$L_MEANING" "$MEANING"

render_field "$L_CONTEXT" "$CONTEXT"

render_field "$L_ETYMOLOGY" "$ETYMOLOGY"

# ------------------------------------------------------------
# Short source excerpt for the reader.
# The full BOOK_CONTEXT is still sent to Gemini.
# ------------------------------------------------------------

if [ -n "$BOOK_CONTEXT_DISPLAY" ]; then

    printf \
        '<div class="bookctx"><span class="label">%s:</span> <span class="bookctx-text">%s</span></div>\n' \
        "$L_FROM_BOOK" \
        "$(format_inline "$BOOK_CONTEXT_DISPLAY")" \
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

render_field "$L_SYNONYMS" "$SYNONYMS"

render_translation_lines "$TRANSLATIONS"

render_field "$L_COLLOCATIONS" "$COLLOCATIONS"

if [ -n "$EXAMPLE" ]; then

    printf \
        '<div class="example"><span class="label">%s:</span> %s</div>\n' \
        "$L_EXAMPLE" \
        "$(format_inline "$EXAMPLE")" \
        >> "$TMP"

fi

render_field "$L_TRANSLATION" "$EXAMPLE_TRANSLATION"

render_field "$L_USAGE" "$USAGE"

render_field "$L_FALSE_FRIEND" "$FALSE_FRIEND"

render_field "$L_GRAMMAR" "$GRAMMAR"

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