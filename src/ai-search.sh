#!/bin/sh

QNDB="/usr/bin/qndb"
DICT="/bin/sh /mnt/onboard/.adds/ai-dictionary.sh"
HTML="file:///mnt/onboard/.adds/ai-result.html"

# Create the text-input dialog
"$QNDB" -m dlgConfirmCreate true
"$QNDB" -m dlgConfirmSetTitle "AI Dictionary"
"$QNDB" -m dlgConfirmSetBody "Enter a word or expression:"
"$QNDB" -m dlgConfirmSetLEPlaceholder "e.g. reluctant"
"$QNDB" -m dlgConfirmSetAccept "Search"
"$QNDB" -m dlgConfirmSetReject "Cancel"
"$QNDB" -m dlgConfirmSetModal true

# Show the dialog and wait for input.
RESULT="$("$QNDB" -s dlgConfirmTextInput -m dlgConfirmShow 2>/dev/null)"

TEXT="${RESULT#dlgConfirmTextInput }"
TEXT="$(printf '%s' "$TEXT" | tr -d '\r')"

[ -z "$TEXT" ] && exit 0

# Generate the HTML page
eval "$DICT \"\$TEXT\""

# Open the result in the Kobo browser
"$QNDB" -m bwmOpenBrowser true "$HTML"
