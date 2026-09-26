# kobo-ai-dictionary

AI dictionary for Kobo Libra Colour using Gemini, NickelMenu, NickelDBus and Kobo book context.

## Status

The validated development setup runs on a Kobo Libra Colour with firmware 4.45.23792.

The working script is the **v9** implementation developed and tested during the project.

## What it does

The dictionary is launched from the native Kobo text-selection menu. It:

1. receives the selected word;
2. identifies the currently read Kobo book and reading position from `KoboReader.sqlite`;
3. extracts book context using `kobo-context`;
4. sends the word and context to Gemini;
5. generates a Kobo-friendly HTML result;
6. displays the result through the Kobo/Nickel integration.

## Important security note

Do not commit any Gemini API key, Kobo database, personal ebook, reading data, or other private device data.

## Dependencies

See [DEPENDENCIES.md](DEPENDENCIES.md) for the exact runtime requirements and upstream projects.

## Installation

Installation instructions are being documented from the validated device setup. The repository intentionally does not bundle third-party Kobo binaries or the private Gemini API key.
