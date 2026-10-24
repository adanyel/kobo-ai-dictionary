# Known issues

## Previous book context after switching books — unresolved

The first release has a known issue: after changing books, the dictionary may temporarily use the previous book's context for some lookups. Users report that it tends to correct itself after a few searches; there is no guaranteed number of searches or recovery time.

This can affect the title, author, excerpt, contextual explanation, and language chosen from the selected EPUB. Check the displayed title and excerpt before trusting a book-specific interpretation. Repeating a search is not a reliable fix.

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
