# Known Issues

## Book switch can temporarily use the previous book

**Status:** confirmed by device use; root cause still under investigation.

### Symptom

After leaving one EPUB and opening another, the first AI Dictionary lookup may occasionally show the title, author, or contextual interpretation of the previously opened book.

After one or more additional lookups, the dictionary normally starts using the new book correctly.

### What we know

Kobo AI Dictionary does not keep the selected book in a persistent cache between lookups. Each invocation starts a fresh shell process and opens `KoboReader.sqlite` through a new `sqlite3` process.

The current selection logic asks Kobo's database for all EPUB rows matching:

- `ContentType = 6`
- `ReadStatus = 1`
- a non-empty `ChapterIDBookmarked`

and orders them by `DateLastRead DESC`.

The script then tests the candidates with `kobo-context` and currently accepts the first candidate that returns non-empty context.

### Most likely explanation

The observed behavior is consistent with Kobo/Nickel not having written the newly opened book's latest `DateLastRead` and/or `ChapterIDBookmarked` state to `KoboReader.sqlite` yet when the first lookup is launched.

If the previous book is still ordered first, the current candidate-selection heuristic can choose it.

This is a working hypothesis, not yet a confirmed upstream Kobo behavior.

### Additional weakness in the current heuristic

The candidate loop currently checks whether `kobo-context` returned non-empty text. It does not independently verify that the returned context actually contains the normalized selected text before accepting that candidate.

A possible future mitigation is to require a real selected-text match before accepting a candidate. This should reduce false positives, but it cannot fully solve cases where the same selected word occurs in both the previous and current book.

### Why this is not patched yet

There is no documented NickelMenu substitution for the current book ID/path: selection substitutions expose the selected text only.

NickelDBus exposes the current Nickel view, but not a documented current-book ContentID.

Because the existing reading-context pipeline is otherwise stable, the project does not currently apply an untested delay, forced database refresh, or write operation to `KoboReader.sqlite`.

The database remains read-only.

### Reproduction

1. Open EPUB A and use AI Dictionary.
2. Leave EPUB A.
3. Open EPUB B.
4. Immediately select a word in EPUB B and run AI Dictionary.
5. Check the title/author and contextual explanation in the result.
6. Repeat the lookup once or twice.

On affected runs, the first result may refer to EPUB A before later lookups correctly use EPUB B.

### Planned investigation

The safest next test is to capture, immediately after a book switch:

- the top `ReadStatus=1` rows;
- `DateLastRead`;
- `ChapterIDBookmarked`;
- candidate order;
- whether each `kobo-context` result actually contains the selected term.

The optional diagnostic script in `diagnostics/book-switch.sh` is intended for this investigation.
