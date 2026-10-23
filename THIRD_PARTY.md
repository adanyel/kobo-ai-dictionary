# Third-party software

Kobo AI Dictionary depends on several third-party projects but does not automatically redistribute them in this repository.

Install them from their original sources.

## NickelMenu

Repository:

https://github.com/pgaskin/NickelMenu

Repository license: MIT.

Purpose: adds custom entries to the Kobo/Nickel interface.

## NickelDBus

Repository:

https://github.com/shermp/NickelDBus

Repository license: MIT.

Purpose: interaction with Nickel. It also installs `/usr/bin/qndb`, used by the manual search dialog.

## KoboStuff

Author/project: NiLuJe.

Reference thread:

https://www.mobileread.com/forums/showthread.php?t=254214

Archived package copy:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

Purpose: provides additional Unix utilities used by the validated Kobo environment, including the setup used for `curl` and `jq`.

KoboStuff contains multiple utilities and dependencies. To avoid mixing versions and licensing terms, its archive is not copied into this repository.

## Kobo-UNCaGED

Repository:

https://github.com/shermp/Kobo-UNCaGED

Repository license: AGPL-3.0.

Kobo AI Dictionary does not use Kobo-UNCaGED as an application. Its release package is a verified practical source for a Kobo-compatible ARM `sqlite3` executable.

## SQLite

Website:

https://www.sqlite.org/

SQLite states that its code is in the public domain.

This project uses the `sqlite3` command-line client only to read `KoboReader.sqlite` in read-only mode.

## BusyBox / unzip

Website:

https://busybox.net/

BusyBox includes an `unzip` applet.

The validated environment contains `/usr/bin/unzip`. See [DEPENDENCIES.md](DEPENDENCIES.md) for the provenance note and runtime verification approach.

## Google Gemini API

Documentation:

https://ai.google.dev/gemini-api/

Gemini is an external service and is not distributed with this repository.

Each user must provide their own API key and accept the terms applicable to their Google account.

## No affiliation

Kobo AI Dictionary is an independent project.

It is not affiliated with, sponsored by, or endorsed by Rakuten Kobo, Google, or the authors of the third-party projects listed above.
