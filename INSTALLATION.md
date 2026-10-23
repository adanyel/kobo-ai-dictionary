# Installation

This guide is written for users who want Kobo AI Dictionary in Kobo's standard reading interface and do not need programming experience.

Validated configuration: **Kobo Libra Colour, firmware 4.45.23792**.

## Before you start

You need:

- a computer;
- a USB cable;
- Wi-Fi on the Kobo;
- a Google account with a Gemini API key;
- a compatible Kobo firmware setup.

KOReader is **not required**.

When the Kobo is connected by USB, its storage normally appears as `KOBOeReader`.

Folders beginning with a dot, such as `.kobo` and `.adds`, may be hidden.

### Show hidden files

- Windows: enable **Hidden items** in File Explorer.
- macOS: press **Cmd + Shift + .** in Finder.
- Linux: usually press **Ctrl + H** in the file manager.

## Important rule for KoboRoot.tgz

NickelMenu, NickelDBus, and KoboStuff each install through a file named `KoboRoot.tgz`.

Install them **one at a time**:

1. copy one `KoboRoot.tgz` into `.kobo`;
2. safely eject the Kobo;
3. allow it to install and reboot;
4. reconnect the Kobo by USB;
5. continue with the next component.

Do not place several different `KoboRoot.tgz` files in `.kobo` at the same time.

---

## 1. Install NickelMenu

Official repository:

https://github.com/pgaskin/NickelMenu

Releases:

https://github.com/pgaskin/NickelMenu/releases

Download the release and copy its `KoboRoot.tgz` to:

`.kobo/KoboRoot.tgz`

Safely eject the Kobo and wait for the reboot.

---

## 2. Install NickelDBus

Official repository:

https://github.com/shermp/NickelDBus

Releases:

https://github.com/shermp/NickelDBus/releases

Download `KoboRoot.tgz` and copy it to:

`.kobo/KoboRoot.tgz`

Safely eject the Kobo and wait for the reboot.

NickelDBus also installs:

`/usr/bin/qndb`

This command is required by the manual-search dialog.

---

## 3. Install KoboStuff

KoboStuff by NiLuJe provides additional Unix utilities used by this project.

Reference thread:

https://www.mobileread.com/forums/showthread.php?t=254214

Archive used by the validated setup:

`kobo-stuff-1.6.N-r18901.tar.xz`

An archival copy is available here:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

Extract the archive on your computer. Inside the `KoboStuff` folder, locate:

`KoboRoot.tgz`

Copy it to:

`.kobo/KoboRoot.tgz`

Safely eject the Kobo and wait for the reboot.

The validated setup uses:

- `/usr/bin/curl`;
- `/usr/bin/jq`;
- `/usr/bin/unzip`.

### About unzip

The working setup has `/usr/bin/unzip`, and the dictionary uses it to inspect EPUB contents.

Because there is no public text manifest for the exact KoboStuff archive listing every installed path, the included installation checker verifies `unzip` directly on the Kobo.

---

## 4. Obtain sqlite3

The dictionary reads Kobo's database in read-only mode and needs an ARM-compatible `sqlite3` executable.

Verified source:

https://github.com/shermp/Kobo-UNCaGED

Releases:

https://github.com/shermp/Kobo-UNCaGED/releases

Download the release ZIP and open it on your computer.

Locate:

`.adds/kobo-uncaged/bin/sqlite3`

You do not need to use Kobo-UNCaGED as an application.

Keep `sqlite3` ready for step 6.

---

## 5. Download Kobo AI Dictionary

Open:

https://github.com/adanyel/kobo-ai-dictionary

Choose:

**Code → Download ZIP**

Extract the ZIP on your computer.

You should find:

`src/ai-dictionary.sh`

`src/ai-search.sh`

`src/check-install.sh`

`ai-tools/kobo-context`

`nm/ai-dictionary`

`nm/ai-search`

`nm/ai-check`

---

## 6. Copy the project files to the Kobo

Create these folders on the Kobo if they do not already exist:

`.adds`

`.adds/ai-tools`

`.adds/nm`

Copy the files as follows:

| Repository file | Kobo destination |
|---|---|
| `src/ai-dictionary.sh` | `.adds/ai-dictionary.sh` |
| `src/ai-search.sh` | `.adds/ai-search.sh` |
| `src/check-install.sh` | `.adds/ai-check-install.sh` |
| `ai-tools/kobo-context` | `.adds/ai-tools/kobo-context` |
| `nm/ai-dictionary` | `.adds/nm/ai-dictionary` |
| `nm/ai-search` | `.adds/nm/ai-search` |
| `nm/ai-check` | `.adds/nm/ai-check` |
| `sqlite3` from Kobo-UNCaGED | `.adds/ai-tools/sqlite3` |

The relevant part of the Kobo filesystem should look like:

```text
KOBOeReader/
└── .adds/
    ├── ai-dictionary.sh
    ├── ai-search.sh
    ├── ai-check-install.sh
    ├── gemini.key
    ├── ai-tools/
    │   ├── kobo-context
    │   └── sqlite3
    └── nm/
        ├── ai-dictionary
        ├── ai-search
        └── ai-check
```

---

## 7. Create a Gemini API key

Google documentation:

https://ai.google.dev/gemini-api/docs/api-key

Create or copy a Gemini API key in Google AI Studio.

Create a plain text file named:

`gemini.key`

It must contain only the API key on one line.

Copy it to:

`.adds/gemini.key`

Never publish this file or commit it to GitHub.

---

## 8. Safely eject and restart

Safely eject the Kobo.

Restart the device once after copying all project files.

---

## 9. Check the installation

Open a book and choose:

**AI Dictionary - Check installation**

The checker verifies:

- curl;
- jq;
- unzip;
- qndb;
- sqlite3;
- kobo-context;
- project scripts;
- Gemini key file;
- Kobo database.

It does not display the API key.

If all entries show `OK`, the base installation is complete.

---

## 10. Use the dictionary

### Selected text

1. open an EPUB;
2. select a word or expression;
3. open the selection menu;
4. choose **AI Dictionary**;
5. wait for the response;
6. the result opens in Kobo's internal browser.

The result language follows the detected language of the book: English, Italian, or Spanish.

### Manual search

Choose:

**AI Dictionary - Search**

Type a word or expression and press **Search**.

The manual-search dialog itself is English-first because it can be opened without enough book context to choose a UI language.

---

## What is sent to Gemini

To interpret selected text correctly, the request may include:

- selected text;
- book title;
- author;
- EPUB filename;
- nearby book text.

If you do not want book context sent to an external service, do not use the dictionary on that content.

---

## Firmware updates

Firmware updates can affect compatibility.

Before updating:

- check the compatibility of the Kobo modifications you use;
- keep a backup of the project files;
- keep your API key separately;
- run **AI Dictionary - Check installation** again after the update.

The project has been validated on firmware **4.45.23792**.
