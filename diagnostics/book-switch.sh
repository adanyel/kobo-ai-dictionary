#!/bin/sh

SQLITE="/mnt/onboard/.adds/ai-tools/sqlite3"
DB="/mnt/onboard/.kobo/KoboReader.sqlite"
QNDB="/usr/bin/qndb"

echo "Kobo AI Dictionary - book switch diagnostic"
echo "==========================================="

if [ -x "$QNDB" ]; then
    VIEW="$("$QNDB" -m ndbCurrentView 2>/dev/null)"
    echo "Nickel view: $VIEW"
else
    echo "Nickel view: qndb unavailable"
fi

echo
echo "Top EPUB candidates (read-only):"
echo "--------------------------------"

if [ ! -x "$SQLITE" ]; then
    echo "sqlite3 not found: $SQLITE"
    exit 1
fi

"$SQLITE" -readonly -header -column "$DB" "
SELECT
    Title,
    Attribution AS Author,
    DateLastRead,
    ReadStatus,
    ChapterIDBookmarked,
    ContentID
FROM content
WHERE ContentType = 6
  AND ReadStatus = 1
  AND ContentID LIKE 'file:///mnt/onboard/%.epub%'
  AND COALESCE(ChapterIDBookmarked,'') <> ''
ORDER BY DateLastRead DESC
LIMIT 8;
" 2>/dev/null

echo
echo "EPUB file descriptors held by Kobo reader processes (read-only):"
echo "------------------------------------------------"
NICKEL_PIDS="$(pidof adobehost nickel 2>/dev/null)"
if [ -z "$NICKEL_PIDS" ]; then
    echo "Kobo reader processes not found."
else
    for NICKEL_PID in $NICKEL_PIDS; do
        printf "Reader PID: %s (%s)\n" "$NICKEL_PID" "$(readlink "/proc/$NICKEL_PID/exe" 2>/dev/null)"
        for FD in /proc/"$NICKEL_PID"/fd/*; do
            TARGET="$(readlink "$FD" 2>/dev/null)" || continue
            case "$TARGET" in
                /mnt/onboard/*.epub|/mnt/onboard/*.kepub.epub)
                    printf '%s -> %s\n' "${FD##*/}" "$TARGET"
                    ;;
            esac
        done
    done
fi

echo
echo "Run this immediately after switching books, before repeated lookups."
echo "Do not publish the output without reviewing it: it contains book metadata."
