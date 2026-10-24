# Dependencies

This page documents the dependencies used by the validated Kobo AI Dictionary setup.

Validated platform: **Kobo Libra Colour, firmware 4.45.23792**.

## Summary

| Component | Path / purpose | Source | Included here? |
|---|---|---|---|
| NickelMenu | Kobo menu integration | pgaskin/NickelMenu | No |
| NickelDBus | Nickel dialog/browser control | shermp/NickelDBus | No |
| qndb | `/usr/bin/qndb` | installed by NickelDBus | No |
| curl | `/usr/bin/curl` | KoboStuff | No |
| jq | `/usr/bin/jq` | KoboStuff | No |
| unzip | `/usr/bin/unzip` | BusyBox/core utility environment; present in validated setup | No |
| sqlite3 | `.adds/ai-tools/sqlite3` | extracted from Kobo-UNCaGED package | No |
| kobo-context | `.adds/ai-tools/kobo-context` | this project | **Yes** |
| Gemini API key | `.adds/gemini.key` | user / Google AI Studio | No |
| KoboReader.sqlite | `.kobo/KoboReader.sqlite` | Kobo firmware | already on device |

## NickelMenu

Repository:

https://github.com/pgaskin/NickelMenu

NickelMenu exposes the project in Kobo's native UI:

- `AI Dictionary` from selected text;
- `AI Dictionary - Search` in the reader menu;
- `AI Dictionary - Check installation`.

## NickelDBus and qndb

Repository:

https://github.com/shermp/NickelDBus

The project uses NickelDBus for the manual text-input dialog and browser interaction.

The official NickelDBus build installs:

`src/cli/qndb:/usr/bin/qndb`

Therefore `/usr/bin/qndb` comes from NickelDBus rather than standard Kobo firmware.

## KoboStuff

Reference project/thread:

https://www.mobileread.com/forums/showthread.php?t=254214

Archive used in the validated setup:

`kobo-stuff-1.6.N-r18901.tar.xz`

Archival mirror:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

The validated setup uses KoboStuff for additional shell utilities, particularly:

- `/usr/bin/curl`;
- `/usr/bin/jq`;
- the extended core/BusyBox utility environment.

### unzip

The main dictionary script requires:

`/usr/bin/unzip`

The validated Kobo has this executable and uses it successfully to inspect EPUB contents.

KoboStuff documents BusyBox/core utility support, and BusyBox includes an `unzip` applet intended for `/usr/bin`. However, no public text manifest was found for the exact `1.6.N-r18901` archive listing every installed path individually.

For that reason:

1. KoboStuff remains the recommended utility installation path;
2. `src/check-install.sh` verifies `/usr/bin/unzip` directly;
3. this repository does not bundle an arbitrary replacement `unzip` binary.

## sqlite3

Verified source:

https://github.com/shermp/Kobo-UNCaGED

The Kobo-UNCaGED build packages SQLite as:

`.adds/kobo-uncaged/bin/sqlite3`

For Kobo AI Dictionary, copy that executable to:

`/mnt/onboard/.adds/ai-tools/sqlite3`

Kobo-UNCaGED itself does not need to run as an application.

## kobo-context

Included in this repository:

`ai-tools/kobo-context`

Install it on the Kobo at:

`/mnt/onboard/.adds/ai-tools/kobo-context`

Validated binary properties:

- ELF 32-bit LSB
- ARM, EABI5
- statically linked
- stripped
- size: 2,031,768 bytes
- SHA-256: `90081b09970f5e8478896d881590f82779ba1549fc9c7a1b76633c56c9cf4484`

## Gemini API

Documentation:

https://ai.google.dev/gemini-api/docs/api-key

The API key is read from:

`/mnt/onboard/.adds/gemini.key`

Never publish or commit this file.

## Kobo database

The script reads:

`/mnt/onboard/.kobo/KoboReader.sqlite`

in read-only mode to retrieve metadata and the saved reading position for the EPUB already identified from the live renderer. Database timestamps do not select the book.

Do not copy this database into the repository.

## Standard shell utilities

Book identification reads `/proc/<pid>/exe` and `/proc/<pid>/fd` for `/usr/local/Kobo/adobehost`. It requires `pidof`, `readlink`, `sort`, and `wc`, available in the tested environment. If these checks cannot identify exactly one EPUB, the dictionary uses general mode. No new daemon or database writer is installed.

The scripts also use standard commands such as `sed`, `awk`, `grep`, `cut`, `tr`, `head`, `cat`, `cp`, `mv`, and `rm`.

These are available in the validated Kobo/Linux utility environment.

## Why third-party binaries are not copied here

The project intentionally points users to upstream projects because:

- NickelMenu and NickelDBus publish their own releases;
- KoboStuff contains multiple utilities with different licensing considerations;
- Kobo-UNCaGED has its own license and release cycle;
- copied binaries become outdated easily;
- keeping upstream dependencies separate makes provenance clearer.

See [THIRD_PARTY.md](THIRD_PARTY.md).
