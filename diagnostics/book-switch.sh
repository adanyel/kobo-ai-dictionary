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
echo "Run this immediately after switching books, before repeated lookups."
echo "Do not publish the output without reviewing it: it contains book metadata."
