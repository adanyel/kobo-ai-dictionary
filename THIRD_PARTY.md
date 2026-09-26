# Software di terze parti

Kobo AI Dictionary non sostituisce né incorpora automaticamente i progetti elencati qui sotto.

L'utente deve installarli dalle rispettive fonti.

## NickelMenu

Repository:

https://github.com/pgaskin/NickelMenu

Licenza indicata dal repository: MIT.

Funzione nel progetto: aggiunge le voci di menu nella UI Kobo/Nickel.

## NickelDBus

Repository:

https://github.com/shermp/NickelDBus

Licenza indicata dal repository: MIT.

Funzione nel progetto: interazione con Nickel; installa anche `/usr/bin/qndb`, usato dalla ricerca manuale.

## KoboStuff

Autore/progetto: NiLuJe.

Thread di riferimento:

https://www.mobileread.com/forums/showthread.php?t=254214

Archivio conservato anche da:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

Funzione nel progetto: fornisce utility Unix aggiuntive, tra cui quelle usate dalla configurazione validata per `curl` e `jq`, oltre al relativo ambiente core/BusyBox.

KoboStuff è una raccolta di più utility e dipendenze. Per evitare di mescolare licenze e versioni, il suo archivio non viene copiato dentro questo repository.

## Kobo-UNCaGED

Repository:

https://github.com/shermp/Kobo-UNCaGED

Licenza indicata dal repository: AGPL-3.0.

Kobo AI Dictionary non usa Kobo-UNCaGED come applicazione. Il pacchetto è una fonte pratica e verificata per il binario ARM `sqlite3` compilato per Kobo.

Il Makefile di Kobo-UNCaGED scarica SQLite e costruisce il relativo eseguibile.

## SQLite

Sito:

https://www.sqlite.org/

SQLite dichiara il proprio codice come public domain.

Nel progetto serve esclusivamente il client a riga di comando `sqlite3` per leggere `KoboReader.sqlite` in modalità read-only.

## BusyBox / unzip

Sito:

https://busybox.net/

BusyBox include una implementazione dell'applet `unzip`.

La configurazione validata dispone di `/usr/bin/unzip`. Vedi [DEPENDENCIES.md](DEPENDENCIES.md) per la nota sulla provenienza e sulla verifica.

## Google Gemini API

Documentazione:

https://ai.google.dev/gemini-api/

Google Gemini è un servizio esterno e non fa parte del software distribuito nel repository.

Ogni utente deve usare la propria chiave API e accettare le condizioni applicabili al proprio account.

## Nessuna affiliazione

Kobo AI Dictionary è un progetto indipendente.

Non è affiliato, sponsorizzato o approvato da Rakuten Kobo, Google o dagli autori dei progetti di terze parti elencati sopra.
