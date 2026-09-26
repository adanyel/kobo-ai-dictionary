#!/bin/sh

QNDB="/usr/bin/qndb"
DICT="/bin/sh /mnt/onboard/.adds/ai-dictionary.sh"
HTML="file:///mnt/onboard/.adds/ai-result.html"

# Crea la finestra con tastiera
"$QNDB" -m dlgConfirmCreate true
"$QNDB" -m dlgConfirmSetTitle "AI Dictionary"
"$QNDB" -m dlgConfirmSetBody "Inserisci una parola o un'espressione:"
"$QNDB" -m dlgConfirmSetLEPlaceholder "es. reluctant"
"$QNDB" -m dlgConfirmSetAccept "Cerca"
"$QNDB" -m dlgConfirmSetReject "Annulla"
"$QNDB" -m dlgConfirmSetModal true

# Mostra la finestra e aspetta il testo inserito.
RESULT="$("$QNDB" -s dlgConfirmTextInput -m dlgConfirmShow 2>/dev/null)"

TEXT="${RESULT#dlgConfirmTextInput }"
TEXT="$(printf '%s' "$TEXT" | tr -d '\r')"

[ -z "$TEXT" ] && exit 0

# Genera la pagina HTML
eval "$DICT \"\$TEXT\""

# Apre il risultato nel browser Kobo
"$QNDB" -m bwmOpenBrowser true "$HTML"
