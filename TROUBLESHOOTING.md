# Troubleshooting

## AI Dictionary does not appear

Check that NickelMenu is installed and these files exist:

`.adds/nm/ai-dictionary`

`.adds/nm/ai-search`

Restart the Kobo after copying or changing menu files.

## Manual search or keyboard does not appear

Manual search requires:

`/usr/bin/qndb`

This executable is installed by NickelDBus.

Reinstall NickelDBus from its official release if the installation checker reports `qndb` as missing.

## sqlite3 not found

The file must be exactly here:

`.adds/ai-tools/sqlite3`

A verified source is the Kobo-UNCaGED release package, where it is normally located at:

`.adds/kobo-uncaged/bin/sqlite3`

## unzip not found

The script requires:

`/usr/bin/unzip`

Install KoboStuff and run:

**AI Dictionary - Check installation**

If `unzip` is still missing, do not copy a random executable built for another architecture. The Kobo needs an ARM-compatible binary.

## Gemini API key not found

Check:

`.adds/gemini.key`

The file must:

- be plain text;
- contain only the API key;
- not accidentally be named `gemini.key.txt`.

## Gemini returns an error

Possible causes include:

- no Wi-Fi connection;
- invalid or revoked API key;
- exhausted API quota;
- API/model changes;
- a temporary Gemini service problem.

## The wrong book is detected

Kobo's database can contain several books with `ReadStatus=1`.

The current script tries candidate books and uses `kobo-context` to choose the book in which the selected text is actually found.

## Words contain an invisible hyphen

Nickel may pass selected text containing Unicode soft hyphens.

The script removes soft hyphens for searching while preserving the original selection for display.

## The result page does not open

The generated result is written to:

`.adds/ai-result.html`

The NickelMenu configuration opens that file with Kobo's internal browser.

## Does this require KOReader?

No.

KOReader is intentionally not required. The project targets the standard Kobo/Nickel reader.

## Firmware 5.x

NickelMenu currently states that firmware 5.x is not supported.

Do not assume this project works on firmware 5.x until the full workflow has been tested there.
