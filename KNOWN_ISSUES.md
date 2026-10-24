# Known issues and book-switch fix

## Original first release: previous book context after switching books

The original first-release build has a known issue: after changing books, some dictionary lookups may temporarily use the previous book's title, author, or context. Users report that it tends to correct itself after a few searches; recovery is not guaranteed.

The fix in the current code, also installed and tested on the connected Kobo, replaces saved database ordering with the EPUB held open by Kobo's running Adobe renderer. Validation and remaining limits are described below. The original behavior is preserved for reference in `backup/main-before-context-fix-2026-10-24`.

## Confirmed cause on the connected Kobo

During a live test on 2026-10-24, the user opened EPUB A and then EPUB B without running the dictionary between the change and inspection.

- `/usr/local/Kobo/adobehost` immediately held EPUB B in an open file descriptor and no longer held EPUB A.
- `KoboReader.sqlite` still ordered EPUB A first by `DateLastRead`.
- EPUB B retained its older `DateLastRead` and `ChapterIDBookmarked` values.
- Multiple books retained `ReadStatus=1`.

This directly demonstrated that saved reading state can lag behind the currently displayed book on the tested firmware, **4.46.23836**. It does not establish update timing for every Kobo firmware.

The old script tested those saved rows in timestamp order and accepted the first nonempty `kobo-context` result. A fresh invocation of the installed helper reproduced the previously logged case: exit status 0 and a 784-character passage without the selected term. A synthetic EPUB test confirmed that the helper can distinguish present and absent terms in a simple case, so a nonempty output must still be checked independently.

Each dictionary invocation initializes its variables and makes a new Gemini request. The inspected path does not reload the previous generated answer as conversation history. The confirmed cause is book selection from stale saved state, not a persistent AI conversation cache.

## Current behavior

1. Find `adobehost` processes and verify their executable path is `/usr/local/Kobo/adobehost`.
2. Read their open file descriptors and require exactly one distinct local EPUB path. Duplicate descriptors for the same EPUB are harmless; different paths are ambiguous.
3. Query only that EPUB's `ContentID` for metadata and its saved chapter position. `ReadStatus`, missing bookmarks, and `DateLastRead` no longer exclude or select a book.
4. Accept helper output only if its exit status is zero and its normalized passage contains the selected text.
5. Keep chapter and full-EPUB fallbacks restricted to that same file. The fallback HTML cleaner also corrects three unescaped numeric-entity delimiters that otherwise caused `sed` to fail. EPUB member listing supports both Info-ZIP `-Z1` and the installed BusyBox `-lq` output; the installed BusyBox rejects `-Z1`.
6. Check the renderer path again after extraction. If it changed, discard the book metadata and passage for that lookup.

If no unambiguous supported renderer path is available, the page explicitly says book context is unavailable and the prompt requests a general lexical explanation. There is no fallback to the most recently read book.

## Validation

Twelve automated regression tests execute the production shell functions and extraction block, using synthetic process descriptors, a real temporary SQLite database, and temporary EPUBs. They cover stale timestamps, unread status, filenames containing apostrophes, missing chapter positions, helper errors, non-matching passages, ambiguous or unavailable renderer state, unsupported row delimiters, whitespace/soft-hyphen normalization, numeric HTML entities, BusyBox-compatible archive listing, and a switch during extraction.

Extraction-only copies of the corrected pipeline were run directly on the Kobo in both switch directions, including two filesystem copies of the same title. Each selected the EPUB actually held by the renderer, despite stale database ordering. A forced helper-unavailable test also retrieved a matching passage from the correct chapter using BusyBox unzip.

After installation, a full dictionary invocation completed successfully (exit status 0, empty error log) and generated an HTML result with the correct title/author and Italian localization. The previous book title was absent from that result. This validates extraction, the Gemini response, and HTML generation. The user then switched to the other EPUB and immediately ran AI Dictionary from the selection menu; they confirmed that the first displayed result identified the correct book.

The previous installed script was preserved as `.adds/ai-dictionary.sh.before-context-fix-20261024`. The installed fix was verified against the repository script by SHA-256.

The database remained read-only. No firmware, reader libraries, renderer processes, or database records were modified. Personal database files and extracted passages are not included in this repository.

## Remaining limitations

- The original release was validated on firmware 4.45.23792. Live investigation of this fix used firmware 4.46.23836; other renderer/firmware combinations need validation.
- Book-specific context currently requires the identifiable Adobe EPUB renderer. Other formats and reading engines may use general mode.
- A saved chapter position can still lag within the correct book. A full-book fallback may select another occurrence of the same word; exact current-sentence identification is not guaranteed.
- Multiple distinct EPUB descriptors cause general mode rather than an arbitrary choice.
- AI explanations can still be inaccurate. Check the displayed title and excerpt.

Use `diagnostics/book-switch.sh` to inspect both saved database candidates and live reader descriptors. Keep its output private because it contains book metadata. The first release remains experimental.
