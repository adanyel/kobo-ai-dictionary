# Kobo AI Dictionary

**Context-aware AI dictionary for Kobo's standard Nickel reader — no KOReader required.**

Kobo AI Dictionary lets you select a word or expression while reading an EPUB and get an AI-generated explanation based on the actual passage, book title, author, and reading position.

It is designed for readers who want AI-assisted vocabulary and contextual explanations **without replacing Kobo's native reading interface**.

## Why this project

Most advanced Kobo extensions rely on alternative reading software. This project takes a different approach:

- keep reading in the standard Kobo/Nickel interface;
- keep Kobo-managed reading progress, highlights, and notes;
- launch the dictionary directly from selected text;
- use the surrounding EPUB passage to interpret ambiguous words, names, places, and expressions;
- use Gemini only for the dictionary response, while book detection and language detection happen locally on the Kobo;
- no KOReader required.

## Automatic language localization

The result interface follows the language of the book.

Currently supported:

- English
- Italian
- Spanish

The script first reads the EPUB language metadata locally. If that is unavailable, it falls back to language detection on the extracted book text.

Examples:

- English book → English interface and explanations
- Italian book → Italian interface and explanations
- Spanish book → Spanish interface and explanations

The original book excerpt is always preserved in its original language.

If language detection is inconclusive, **English is the default**.

## What the dictionary can show

Depending on the selected text, the result may include:

- pronunciation;
- meaning;
- contextual interpretation;
- etymology;
- a short excerpt from the book;
- a simple ELI5 explanation;
- synonyms;
- translations;
- collocations;
- examples;
- usage notes;
- false friends;
- grammar.

The full extracted context can be sent to Gemini for interpretation, but the reader UI shows only a short excerpt around the selected term to keep the page compact.

## How it works

1. Select a word or expression in an EPUB.
2. Tap **AI Dictionary** from the Kobo selection menu.
3. The script reads Kobo's database in read-only mode to identify candidate books and the current reading position.
4. `kobo-context` checks the EPUB and extracts nearby text.
5. The EPUB language is detected locally.
6. Gemini receives the selected text plus relevant book context.
7. A lightweight HTML result opens in Kobo's internal browser.

A separate **AI Dictionary - Search** entry is also available for manual searches.

## Tested configuration

Validated on:

- Kobo Libra Colour
- Kobo firmware **4.45.23792**
- native Kobo/Nickel reader
- sideloaded/local EPUB files
- NickelMenu
- NickelDBus
- KoboStuff
- Gemini API

Other Kobo models and firmware 4.x versions may work but have not yet been fully validated.

## Installation

The project is documented for users who do not program.

Start here:

**[INSTALLATION.md](INSTALLATION.md)**

Also see:

- [DEPENDENCIES.md](DEPENDENCIES.md) — where every dependency comes from
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — common installation/runtime issues
- [THIRD_PARTY.md](THIRD_PARTY.md) — upstream projects and licenses

## Project files

Project-specific components included in this repository:

- `src/ai-dictionary.sh` — main dictionary engine
- `src/ai-search.sh` — manual search dialog
- `src/check-install.sh` — installation checker
- `ai-tools/kobo-context` — ARMv7 EPUB context extraction helper
- `nm/ai-dictionary` — NickelMenu selected-text entry
- `nm/ai-search` — NickelMenu manual-search entry
- `nm/ai-check` — NickelMenu installation-check entry

Third-party Kobo utilities are not duplicated here unless they are part of this project. Users install them from their original upstream projects.

## Privacy

To generate a contextual response, the script may send Gemini:

- the selected word or expression;
- book title;
- author;
- EPUB filename;
- a nearby excerpt from the book.

The Gemini API key remains on the Kobo at:

`/mnt/onboard/.adds/gemini.key`

Never commit this file, `KoboReader.sqlite`, personal EPUBs, or debug files containing book text.

## Known issue in the first release

After switching from one EPUB to another, Kobo AI Dictionary may temporarily use the previous book's metadata or context for the first lookup(s). After Nickel updates its reading state, subsequent lookups normally use the new book correctly.

This is currently treated as a known issue rather than silently hidden with an untested workaround.

Technical notes and the current investigation are documented in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## Current limitations

- primarily validated on Kobo Libra Colour;
- validated on firmware 4.45.23792;
- designed for EPUB files accessible on the device filesystem;
- Kobo Store KEPUB, PDF, and other formats are not currently considered supported;
- Wi-Fi is required when contacting Gemini;
- the manual-search dialog uses English by default because it can be opened without an active book context;
- the project depends on third-party Kobo utilities.

## Safety copy of the earlier Italian-first build

The earlier working Italian-first state is preserved in:

`release/v1.0.0-it`

The current `main` branch is English-first and automatically localizes dictionary results by book language.

## Independent project

Kobo AI Dictionary is an independent project and is not affiliated with or endorsed by Rakuten Kobo, Google, or the authors of the third-party tools it uses.
