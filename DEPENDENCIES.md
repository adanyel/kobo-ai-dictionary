# Dependencies

This page documents the actual dependencies used by the validated Kobo AI Dictionary setup.

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

https://github.com/pgaskin/NickelMenu

Used to expose the dictionary, manual search, and installation checker in Kobo's normal UI.

## NickelDBus and qndb

https://github.com/shermp/NickelDBus

The official NickelDBus build installs:

`src/cli/qndb:/usr/bin/qndb`

The manual search dialog depends on this executable.

## KoboStuff

Reference:

https://www.mobileread.com/forums/showthread.php?t=254214

Validated archive:

`kobo-stuff-1.6.N-r18901.tar.xz`

Archive mirror:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

The validated setup uses KoboStuff for additional Kobo shell utilities including `curl` and `jq`.

### unzip

The main script requires:

`/usr/bin/unzip`

This executable is present and working on the validated Kobo.

KoboStuff provides the extended utility/core environment used by the setup and includes BusyBox-related utilities. BusyBox includes an `unzip` applet under `/usr/bin`.

No public text manifest was found for the exact KoboStuff archive that proves every installed pathname individually, so the project deliberately verifies `/usr/bin/unzip` at runtime instead of making an unsupported stronger claim.

## sqlite3

Verified source:

https://github.com/shermp/Kobo-UNCaGED

The Kobo-UNCaGED Makefile compiles SQLite and packages the executable as:

`.adds/kobo-uncaged/bin/sqlite3`

For Kobo AI Dictionary, copy that executable to:

`/mnt/onboard/.adds/ai-tools/sqlite3`

Kobo-UNCaGED itself does not need to be used as an application.

## kobo-context

Included in this repository:

`ai-tools/kobo-context`

Install on Kobo at:

`/mnt/onboard/.adds/ai-tools/kobo-context`

Validated binary:

- ELF 32-bit LSB;
- ARM, EABI5;
- statically linked;
- stripped;
- size: 2,031,768 bytes;
- SHA-256: `90081b09970f5e8478896d881590f82779ba1549fc9c7a1b76633c56c9cf4484`.

## Gemini API

https://ai.google.dev/gemini-api/docs/api-key

The key is read from:

`/mnt/onboard/.adds/gemini.key`

Never commit the key to GitHub.

## Kobo database

The script reads:

`/mnt/onboard/.kobo/KoboReader.sqlite`

in read-only mode to identify the current book and reading position.

Do not publish this database.

## Standard shell utilities

The script also uses commands such as `sed`, `awk`, `grep`, `cut`, `tr`, `head`, `cat`, `cp`, `mv`, and `rm`.

These are available in the validated Kobo/Linux utility environment.

## Why third-party binaries are not copied here

The project intentionally points users to original upstream projects because:

- NickelMenu and NickelDBus have their own official releases;
- KoboStuff contains many utilities with different licenses;
- Kobo-UNCaGED has its own license and release cycle;
- copied binaries can quickly become outdated;
- separating project code from prerequisites makes provenance clearer.
