#!/bin/sh

OK=1

check_exec() {
    LABEL="$1"
    PATH_TO_CHECK="$2"

    if [ -x "$PATH_TO_CHECK" ]; then
        printf 'OK   %-18s %s\n' "$LABEL" "$PATH_TO_CHECK"
    else
        printf 'Manca %-17s %s\n' "$LABEL" "$PATH_TO_CHECK"
        OK=0
    fi
}

check_file() {
    LABEL="$1"
    PATH_TO_CHECK="$2"

    if [ -f "$PATH_TO_CHECK" ]; then
        printf 'OK   %-18s %s\n' "$LABEL" "$PATH_TO_CHECK"
    else
        printf 'Manca %-17s %s\n' "$LABEL" "$PATH_TO_CHECK"
        OK=0
    fi
}

check_nonempty() {
    LABEL="$1"
    PATH_TO_CHECK="$2"

    if [ -s "$PATH_TO_CHECK" ]; then
        printf 'OK   %-18s %s\n' "$LABEL" "$PATH_TO_CHECK"
    else
        printf 'Manca/vuoto %-11s %s\n' "$LABEL" "$PATH_TO_CHECK"
        OK=0
    fi
}

echo "Kobo AI Dictionary - verifica installazione"
echo "-------------------------------------------"

check_exec "curl" "/usr/bin/curl"
check_exec "jq" "/usr/bin/jq"
check_exec "unzip" "/usr/bin/unzip"
check_exec "qndb" "/usr/bin/qndb"
check_exec "sqlite3" "/mnt/onboard/.adds/ai-tools/sqlite3"
check_exec "kobo-context" "/mnt/onboard/.adds/ai-tools/kobo-context"

check_file "ai-dictionary.sh" "/mnt/onboard/.adds/ai-dictionary.sh"
check_file "ai-search.sh" "/mnt/onboard/.adds/ai-search.sh"
check_nonempty "gemini.key" "/mnt/onboard/.adds/gemini.key"
check_file "KoboReader.sqlite" "/mnt/onboard/.kobo/KoboReader.sqlite"

echo "-------------------------------------------"

if [ "$OK" -eq 1 ]; then
    echo "Tutto OK: prerequisiti principali trovati."
    exit 0
fi

echo "Installazione incompleta: controlla le voci segnate come Manca."
exit 1
