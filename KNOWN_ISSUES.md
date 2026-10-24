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

### Investigation on 2026-10-24

The connected Kobo was accessible as a USB volume. Inspection was read-only; no device scripts, database records, firmware, or settings were changed. Personal database copies were temporary and were not committed. The installed `ai-dictionary.sh` and `kobo-context` matched the repository versions by SHA-256.

A temporary local copy of `KoboReader.sqlite` passed SQLite `quick_check`. Eight records matched the script's candidate query:

- `ContentType=6`, `ReadStatus=1`;
- a local EPUB `ContentID`;
- a nonempty `ChapterIDBookmarked`;
- ordered by `DateLastRead DESC`.

Multiple books retained `ReadStatus=1`; it is not an active-book flag. `ChapterIDBookmarked` contained saved chapter/point positions for multiple candidates. `DateLastRead` provides the ordering used by the script, but a static USB snapshot cannot establish when Nickel updates it during a book switch. Delayed database updates remain a hypothesis, not a verified firmware behavior.

The existing device debug log showed a successful helper call (exit status 0) returning 784 characters without the selected term. The script accepted that first candidate and did not test the others. This demonstrates that nonempty helper output is not proof of a selected-text match. It does not establish which book was visible at the time of that lookup.

A controlled local test executed the actual candidate-loop block from `src/ai-dictionary.sh` with two synthetic candidates and a stub helper returning a non-matching passage. It reproduced selection of the previous book and termination after one candidate.

### Cause and limits

The menu passes selected text only, without a book identifier. The candidate loop treats any nonempty helper result as a match, ignores its exit status when deciding acceptance, and stops at the first such result. Later fallback stages continue using the chosen book. This is a confirmed selection weakness that can explain the reported symptom when candidate ordering is stale or ambiguous.

The script initializes its book variables on each invocation, reads helper output from a freshly redirected file, and makes a new Gemini request. The inspected path does not reload a previous generated answer as a conversation or use an old context file as its input. This points toward book selection rather than an AI conversation cache; it does not exclude other runtime issues.

`kobo-context` is supplied here as a stripped ARMv7 binary without source. It could not be executed natively on the host. Existing on-device output was inspected, but no live Nickel book-switch sequence or new end-to-end Gemini lookup was performed over the USB connection.

### Why no runtime change was made

Requiring the selected term in a passage could reject one observed false match, but common words can occur in multiple books, and the saved position may omit the current selection. Restricting selection to the newest row still relies on the timestamp whose update timing is unverified. Neither change establishes the active book reliably.

No speculative delays, database writes, cache deletion, helper replacement, or infrastructure changes were introduced. A safe fix needs a verified active-book signal or a validated way to decline book-specific context when identity is ambiguous.

### Validation needed before resolving

On the running Kobo reader, capture candidate ordering and saved positions before and after switching between two EPUBs. Test both a distinctive expression and a word shared by the books. Compare the visible book with the chosen candidate and verify helper behavior for a missing term, a nonzero exit, and stale chapter positions. Keep logs private because they may contain book excerpts.

### Release assessment

Appropriate for a clearly labeled experimental first release on the documented tested configuration, with this limitation prominently disclosed. Not ready to claim stable active-book detection. The issue remains open; no release tag or GitHub Release was created by this investigation.
