# Dipendenze

Questa pagina documenta le dipendenze reali usate dalla configurazione funzionante di Kobo AI Dictionary.

Il progetto è stato validato su **Kobo Libra Colour, firmware 4.45.23792**.

## Riepilogo

| Componente | Percorso/uso | Provenienza | Incluso qui? |
|---|---|---|---|
| NickelMenu | integrazione nel menu Kobo | pgaskin/NickelMenu | No |
| NickelDBus | controllo dialog/browser Nickel | shermp/NickelDBus | No |
| qndb | `/usr/bin/qndb` | installato da NickelDBus | No |
| curl | `/usr/bin/curl` | KoboStuff | No |
| jq | `/usr/bin/jq` | KoboStuff | No |
| unzip | `/usr/bin/unzip` | utility BusyBox/core; presente nel setup con KoboStuff | No |
| sqlite3 | `.adds/ai-tools/sqlite3` | binario ricavato da Kobo-UNCaGED | No |
| kobo-context | `.adds/ai-tools/kobo-context` | questo progetto | **Sì** |
| Gemini API key | `.adds/gemini.key` | Google AI Studio / utente | No |
| KoboReader.sqlite | `.kobo/KoboReader.sqlite` | firmware Kobo | già sul dispositivo |

## NickelMenu

Repository:

https://github.com/pgaskin/NickelMenu

NickelMenu permette di aggiungere le voci:

- `AI Dictionary` nella selezione del testo;
- `AI Dictionary - Cerca parola` nel reader;
- `AI Dictionary - Verifica installazione`.

NickelMenu dichiara attualmente che firmware Kobo 5.x non è supportato.

## NickelDBus e qndb

Repository:

https://github.com/shermp/NickelDBus

Il progetto usa NickelDBus per aprire la finestra di input della ricerca manuale e interagire con Nickel.

Il Makefile ufficiale di NickelDBus installa esplicitamente:

`src/cli/qndb:/usr/bin/qndb`

Quindi `/usr/bin/qndb` non è un file del firmware Kobo standard: arriva da NickelDBus.

## KoboStuff

Progetto originale/discussione:

https://www.mobileread.com/forums/showthread.php?t=254214

Archivio usato nel setup validato:

`kobo-stuff-1.6.N-r18901.tar.xz`

Mirror archivistico:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

KoboStuff è la fonte usata per:

- `/usr/bin/curl`;
- `/usr/bin/jq`;
- utility shell/core aggiuntive.

### unzip

Lo script richiede:

`/usr/bin/unzip`

Nel dispositivo validato questo eseguibile è presente e funzionante nello stesso ambiente in cui è installato KoboStuff.

KoboStuff documenta modifiche e ampliamenti a BusyBox. BusyBox include l'applet `unzip` e la definisce con destinazione `/usr/bin`.

Non è stato trovato un manifest testuale pubblico dell'esatto archivio KoboStuff `1.6.N-r18901` che consenta di attribuire con certezza assoluta ogni singolo file installato.

Per questo:

1. KoboStuff resta il percorso d'installazione consigliato per le utility;
2. la presenza di `/usr/bin/unzip` viene verificata dallo script `check-install.sh`;
3. non viene copiata nel repository una versione casuale di `unzip`.

## sqlite3

Fonte verificata:

https://github.com/shermp/Kobo-UNCaGED

Il Makefile ufficiale di Kobo-UNCaGED compila SQLite e inserisce il binario nel pacchetto come:

`.adds/kobo-uncaged/bin/sqlite3`

Per Kobo AI Dictionary il binario viene copiato manualmente in:

`/mnt/onboard/.adds/ai-tools/sqlite3`

Non è necessario usare Kobo-UNCaGED come applicazione.

## kobo-context

Incluso nel repository:

`ai-tools/kobo-context`

Installazione sul Kobo:

`/mnt/onboard/.adds/ai-tools/kobo-context`

Binario validato:

- ELF 32-bit LSB;
- ARM, EABI5;
- staticamente linkato;
- stripped;
- dimensione: 2,031,768 byte;
- SHA-256: `90081b09970f5e8478896d881590f82779ba1549fc9c7a1b76633c56c9cf4484`.

## Gemini API

Documentazione ufficiale:

https://ai.google.dev/gemini-api/docs/api-key

La chiave viene letta da:

`/mnt/onboard/.adds/gemini.key`

Il file deve contenere soltanto la chiave.

La chiave **non deve essere caricata su GitHub**.

## Database Kobo

Lo script legge:

`/mnt/onboard/.kobo/KoboReader.sqlite`

in modalità read-only per ottenere libro e posizione di lettura.

Il database non fa parte del progetto e non deve essere pubblicato.

## Utility standard

Lo script usa inoltre normali comandi shell come `sed`, `awk`, `grep`, `cut`, `tr`, `head`, `cat`, `cp`, `mv` e `rm`.

Queste utility fanno parte dell'ambiente Linux/Kobo e/o del layer di utility installato sul dispositivo. La configurazione validata le dispone già.

## Perché le dipendenze esterne non vengono copiate qui

Alcuni componenti potrebbero tecnicamente essere ridistribuiti, ma non è la scelta predefinita del progetto perché:

- NickelMenu e NickelDBus hanno release ufficiali proprie;
- KoboStuff contiene molte utility e componenti con licenze differenti;
- Kobo-UNCaGED ha la propria licenza e il proprio ciclo di release;
- duplicare binari di terzi rende più facile distribuire versioni obsolete;
- è più chiaro separare il codice di Kobo AI Dictionary dalle sue dipendenze.

Vedi [THIRD_PARTY.md](THIRD_PARTY.md).
