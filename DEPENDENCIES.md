# Dependencies

This project is a shell-based AI dictionary for the Kobo Libra Colour.

The repository contains the project code and documentation. Third-party Kobo utilities are **not bundled** in this repository unless their redistribution terms are verified.

## Required platform

- Kobo Libra Colour
- Kobo firmware: 4.45.23792 (validated during development)
- Native Kobo/Nickel UI
- NickelMenu
- NickelDBus

## Runtime tools

The working setup uses these executables:

| Tool | Required path on Kobo | Role | Source / status |
|---|---|---|---|
| `curl` | `/usr/bin/curl` | HTTPS requests to the Gemini API | KoboStuff 1.6.N-r18901 |
| `jq` | `/usr/bin/jq` | JSON construction and parsing | KoboStuff 1.6.N-r18901 |
| `sqlite3` | `/mnt/onboard/.adds/ai-tools/sqlite3` | Read KoboReader.sqlite | Kobo-UNCaGED |
| `unzip` | `/usr/bin/unzip` | Read EPUB ZIP contents | Origin not yet verified |
| `kobo-context` | `/mnt/onboard/.adds/ai-tools/kobo-context` | Extract reading-position context from an EPUB | Project-specific ARMv7 helper; installed manually |

## External projects

### KoboStuff

Version used in the validated setup:

`kobo-stuff-1.6.N-r18901.tar.xz`

Repository reference:

https://github.com/usetrmnl/trmnl-kobo

The archive is preserved there under:

`doc/distrib/kobostuff/kobo-stuff-1.6.N-r18901.tar.xz`

KoboStuff is the documented source for the `curl` and `jq` utilities used by this project.

### Kobo-UNCaGED

Repository:

https://github.com/shermp/Kobo-UNCaGED

The Kobo-UNCaGED build system compiles and packages a Kobo ARM `sqlite3` binary as:

`.adds/kobo-uncaged/bin/sqlite3`

For this project, that binary is placed manually at:

`/mnt/onboard/.adds/ai-tools/sqlite3`

Kobo-UNCaGED also packages NickelDBus.

### NickelMenu

Repository:

https://github.com/pgaskin/NickelMenu

NickelMenu is used to expose/launch the dictionary from the native Kobo interface.

### NickelDBus

Repository:

https://github.com/shermp/NickelDBus

NickelDBus is required by the validated Kobo integration used to display/control the result from the native UI.

## API key

Create this file on the Kobo:

`/mnt/onboard/.adds/gemini.key`

It must contain the Gemini API key only.

**Never commit or upload the API key to GitHub.**

## Kobo database

The script reads this database in read-only mode:

`/mnt/onboard/.kobo/KoboReader.sqlite`

The database is part of the Kobo device and must not be copied into this repository.

## kobo-context

`kobo-context` is the project-specific ARMv7 helper used by the validated setup.

Repository path:

`ai-tools/kobo-context`

Install it on the Kobo at:

`/mnt/onboard/.adds/ai-tools/kobo-context`

Validated binary properties:

- ELF 32-bit LSB executable
- ARM, EABI5
- statically linked
- stripped
- SHA-256: `90081b09970f5e8478896d881590f82779ba1549fc9c7a1b76633c56c9cf4484`

The executable must have execute permission on the Kobo.

## Open item: unzip provenance

The validated runtime requires:

`/usr/bin/unzip`

The executable was present and working on the validated Kobo, but the original installation source has not yet been established from the preserved project material.

Until that is verified, installation documentation must treat `unzip` as a separate prerequisite rather than incorrectly attributing it to KoboStuff, NickelMenu, or KOReader.
