# English beta notes

Version: **v1.1.0-beta.1**

This branch is intended to test an English-first user experience without changing the stable Italian v1.

## What changed

- Gemini explanations are requested in English.
- Book excerpts remain in their original language.
- English, Italian, and Spanish are auto-detected.
- Translations are requested into the other two supported languages.
- HTML field labels are in English.
- Manual-search dialogs are in English.
- NickelMenu entries are in English.
- Installation checker output is in English.
- Documentation is English-first.

## What did not change

The tested engine logic remains based on the Italian v1:

- Kobo database lookup;
- candidate-book selection;
- CFI handling;
- `kobo-context` integration;
- soft-hyphen cleanup;
- direct chapter fallback;
- whole-EPUB fallback;
- Gemini JSON schema;
- Kobo browser result flow.

## Testing requested

Before promoting this beta to a stable international release, test:

- English books;
- Italian books with English explanations;
- Spanish books with English explanations;
- proper nouns and place names;
- hyphenated/soft-hyphen words;
- manual search;
- books with several Kobo `ReadStatus=1` records;
- offline/error behavior;
- several Kobo models if available.
