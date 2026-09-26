# Kobo AI Dictionary — English Beta

AI-powered dictionary for **Kobo's standard Nickel interface**, without KOReader.

This branch is the English beta of Kobo AI Dictionary. The stable Italian version is preserved in `main` and `release/v1.0.0-it`.

> **Beta version:** `v1.1.0-beta.1`
>
> The interface, documentation, error messages, and AI explanations are primarily in English. Book excerpts remain in the original language, and the dictionary automatically handles English, Italian, and Spanish.

## Why this project exists

The goal is to add an AI dictionary directly to the normal Kobo reading experience without replacing Nickel.

- Keep using the standard Kobo reader.
- No KOReader required.
- Reading progress, highlights, and notes remain managed by Kobo.
- `KoboReader.sqlite` is read in read-only mode.
- The selected word is interpreted using the current EPUB context whenever possible.

## Tested configuration

Validated on:

- Kobo Libra Colour
- firmware **4.45.23792**
- EPUB files stored on the device
- NickelMenu
- NickelDBus
- KoboStuff
- Gemini API

Other Kobo models and firmware 4.x releases may work, but are not yet validated.

NickelMenu currently states that Kobo firmware 5.x is not supported, so this project should presently be treated as a firmware 4.x project.

## Features

### Dictionary from selected text

While reading an EPUB:

1. select a word or expression;
2. choose **AI Dictionary**;
3. the script identifies the current book and reading position;
4. `kobo-context` extracts nearby text;
5. Gemini interprets the selected text using that context;
6. the result opens in Kobo's internal browser.

The result can include:

- pronunciation;
- meaning;
- contextual interpretation;
- etymology;
- simple explanation;
- translations;
- synonyms;
- collocations;
- examples;
- usage notes;
- false friends;
- grammar.

### Manual search

Choose:

**AI Dictionary - Search**

A NickelDBus/qndb dialog lets you type a word or expression manually.

### Installation check

Choose:

**AI Dictionary - Check installation**

The checker verifies that the required executables and project files are present.

## Project files

Files created specifically for this project:

- `src/ai-dictionary.sh` — main dictionary engine;
- `src/ai-search.sh` — manual search dialog;
- `src/check-install.sh` — installation checker;
- `ai-tools/kobo-context` — ARMv7 context extraction helper;
- `nm/ai-dictionary` — NickelMenu selected-text entry;
- `nm/ai-search` — NickelMenu manual-search entry;
- `nm/ai-check` — NickelMenu installation-check entry.

External dependencies are not duplicated here unless they are part of this project. Install them from their original projects.

## Installation

Follow:

**[INSTALLATION.md](INSTALLATION.md)**

It is written for users who do not need programming knowledge.

For dependency provenance:

**[DEPENDENCIES.md](DEPENDENCIES.md)**

For third-party software and licenses:

**[THIRD_PARTY.md](THIRD_PARTY.md)**

For common problems:

**[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**

## Language behavior

This beta separates the language of the interface from the language of the book:

- interface language: English;
- explanation language: English;
- book excerpt: original language;
- selected-text language: auto-detected;
- supported selected-text languages: English, Italian, Spanish;
- translations: into the other two supported languages.

For example, if you read an Italian novel and select an Italian word, the original Italian excerpt is preserved while the explanation is written in English.

## Privacy

To generate a contextual answer, the script may send Gemini:

- the selected word or expression;
- book title;
- author;
- EPUB filename;
- a nearby excerpt from the book.

The API key stays locally in:

`/mnt/onboard/.adds/gemini.key`

Never commit this file to GitHub.

Use of the Gemini API is subject to Google's terms, quotas, and any billing associated with the user's account.

## Current limitations

- primarily tested on Kobo Libra Colour;
- validated on firmware 4.45.23792;
- intended for EPUB files accessible on the device filesystem;
- Kobo Store KEPUB, PDF, and other formats are not currently considered supported;
- requires Wi-Fi when contacting Gemini;
- depends on third-party Kobo components;
- this branch is a beta and may still need testing on additional books and Kobo models.

## No KOReader required

KOReader is intentionally not part of this project.

Kobo AI Dictionary is designed specifically for users who want to keep the standard Kobo/Nickel reading environment.

## Stable Italian version

The current stable Italian version is preserved in:

- branch: `main`
- frozen branch: `release/v1.0.0-it`

The English beta lives only in:

- branch: `beta/english`
