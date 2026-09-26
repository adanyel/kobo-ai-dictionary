# Third-party software

Kobo AI Dictionary depends on third-party projects but does not automatically redistribute them in this repository.

Install them from their original sources.

## NickelMenu

https://github.com/pgaskin/NickelMenu

Repository license: MIT.

Purpose: adds custom entries to the Kobo/Nickel interface.

## NickelDBus

https://github.com/shermp/NickelDBus

Repository license: MIT.

Purpose: interaction with Nickel and installation of `/usr/bin/qndb`, used by manual search.

## KoboStuff

Author/project: NiLuJe.

Reference thread:

https://www.mobileread.com/forums/showthread.php?t=254214

Archived package copy:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

Purpose: additional Unix utilities used by the validated Kobo environment.

KoboStuff bundles several utilities and dependencies, so this repository does not duplicate the archive.

## Kobo-UNCaGED

https://github.com/shermp/Kobo-UNCaGED

Repository license: AGPL-3.0.

Kobo AI Dictionary does not depend on Kobo-UNCaGED as an application. Its release package is a verified source of a Kobo-compatible `sqlite3` executable.

## SQLite

https://www.sqlite.org/

SQLite states that its code is in the public domain.

The project uses the `sqlite3` command-line client only to read Kobo's database in read-only mode.

## BusyBox / unzip

https://busybox.net/

BusyBox includes an `unzip` applet.

The validated setup contains `/usr/bin/unzip`. See [DEPENDENCIES.md](DEPENDENCIES.md) for the provenance note and verification strategy.

## Google Gemini API

https://ai.google.dev/gemini-api/

Gemini is an external service and is not distributed with this repository.

Each user must use their own API key and accept the terms applicable to their Google account.

## No affiliation

Kobo AI Dictionary is an independent project.

It is not affiliated with, sponsored by, or endorsed by Rakuten Kobo, Google, or the authors of the third-party projects listed above.
