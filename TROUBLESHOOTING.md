# Troubleshooting

## AI Dictionary does not appear

Check that NickelMenu is installed and that these files exist:

`.adds/nm/ai-dictionary`

`.adds/nm/ai-search`

Restart the Kobo after copying or modifying NickelMenu files.

## Manual search or keyboard does not appear

Manual search requires:

`/usr/bin/qndb`

This executable is installed by NickelDBus.

Reinstall NickelDBus from its official release if the installation checker reports `qndb` as missing.

## sqlite3 not found

The file must be located exactly at:

`.adds/ai-tools/sqlite3`

A verified source is the Kobo-UNCaGED release package, where it is normally found at:

`.adds/kobo-uncaged/bin/sqlite3`

## unzip not found

The main script requires:

`/usr/bin/unzip`

Install KoboStuff, then run:

**AI Dictionary - Check installation**

If `unzip` is still missing, do not copy a random executable built for another architecture. The Kobo requires an ARM-compatible binary.

## Gemini API key not found

Check:

`.adds/gemini.key`

The file must:

- be plain text;
- contain only the API key;
- not accidentally be named `gemini.key.txt`.

## Gemini returns an error

Possible causes include:

- the Kobo is not connected to Wi-Fi;
- the API key is invalid or revoked;
- the Gemini quota is exhausted;
- the configured API/model has changed;
- Gemini is temporarily unavailable.

The installation checker never prints the API key.

## The wrong book is detected or book context is unavailable

The original first-release script chose books using saved `DateLastRead` ordering and could temporarily use the previous book after a switch. Update `src/ai-dictionary.sh` on the Kobo to use the current renderer-based selection.

The current script requires exactly one EPUB held by Kobo's Adobe renderer. It reads metadata and saved positions only for that EPUB, verifies helper output contains the selected text, and keeps fallback searches inside the same book. It does not guess from `ReadStatus` or timestamps if the renderer is unavailable or ambiguous.

“Book context unavailable” means a general explanation is being shown. Open a supported local EPUB in the standard reader and try again. Other reading engines, unsupported formats, or multiple distinct open EPUBs may prevent identification.

For diagnosis, run `diagnostics/book-switch.sh` immediately after a switch and compare the open renderer path with the saved database rows. Keep the output private because it contains book metadata. See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for the investigation and validation limits.

## The interface language is wrong

The result language is chosen locally from the EPUB language metadata first.

If the EPUB does not declare a supported language, the script falls back to a small local text-language detector.

Supported result languages are:

- English
- Italian
- Spanish

If detection remains inconclusive, English is used by default.

Incorrect EPUB metadata can therefore cause a wrong interface language even when the book text is different.

## Words contain an invisible hyphen

Nickel may pass selected text containing Unicode soft hyphens.

The script removes soft hyphens for searching while preserving the original selection for display.

## The result page does not open

The generated result is written to:

`.adds/ai-result.html`

The NickelMenu configuration opens this file using Kobo's internal browser.

## Does this require KOReader?

No.

KOReader is intentionally not required. This project targets Kobo's standard Nickel reader.

## Firmware compatibility

The project has been validated on Kobo Libra Colour firmware **4.45.23792**.

Other models and firmware versions should be treated as unverified until tested with the full workflow.
