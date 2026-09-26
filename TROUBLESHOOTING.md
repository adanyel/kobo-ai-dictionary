# Risoluzione problemi

## Non compare AI Dictionary

Controlla che NickelMenu sia installato e che esistano:

`.adds/nm/ai-dictionary`

`.adds/nm/ai-search`

Dopo aver copiato o modificato i file, riavvia il Kobo.

## Non compare la ricerca manuale o la tastiera

La ricerca manuale usa:

`/usr/bin/qndb`

Questo file viene installato da NickelDBus.

Reinstalla NickelDBus dalla release ufficiale se la verifica segnala `qndb` come mancante.

## Errore sqlite3 non trovato

Il file deve trovarsi esattamente qui:

`.adds/ai-tools/sqlite3`

Puoi ricavarlo dal pacchetto Kobo-UNCaGED, dove si trova normalmente in:

`.adds/kobo-uncaged/bin/sqlite3`

## Errore unzip non trovato

Lo script richiede:

`/usr/bin/unzip`

Installa KoboStuff e poi usa:

**AI Dictionary - Verifica installazione**

Se `unzip` continua a risultare mancante, non sostituirlo con un eseguibile casuale per un'altra architettura: serve un binario compatibile con il Kobo ARM.

## Gemini API key non trovata

Controlla il file:

`.adds/gemini.key`

Deve:

- essere un normale file di testo;
- contenere la chiave e niente altro;
- non chiamarsi `gemini.key.txt`.

Su Windows abilita la visualizzazione delle estensioni dei file per controllare il nome reale.

## Gemini restituisce un errore

Possibili cause:

- Kobo non connesso al Wi-Fi;
- chiave API errata o revocata;
- quota API esaurita;
- cambiamenti del modello/API Gemini;
- problemi temporanei del servizio.

La chiave non viene stampata dallo script di verifica.

## Il dizionario trova il libro sbagliato

Il database Kobo può contenere più record con `ReadStatus=1`.

La versione attuale prova i candidati e usa `kobo-context` per scegliere il libro nel quale trova realmente la parola selezionata.

Se il problema si ripete, conserva il file di debug solo per diagnosi privata: può contenere nomi di libri o testo e non deve essere pubblicato automaticamente.

## Parole spezzate con trattino invisibile

Nickel può passare parole contenenti soft hyphen Unicode.

Lo script normalizza il testo usato per la ricerca, mantenendo la forma originale per la visualizzazione.

## Il risultato non si apre

Il risultato viene scritto in:

`.adds/ai-result.html`

La configurazione NickelMenu lo apre tramite il browser interno Kobo.

Controlla che `.adds/nm/ai-dictionary` sia quello presente nel repository.

## Il progetto funziona con KOReader?

KOReader non è richiesto e non è il target del progetto.

Kobo AI Dictionary è stato progettato appositamente per lavorare con il reader Kobo/Nickel standard.

## Firmware 5.x

NickelMenu dichiara attualmente che firmware 5.x non è supportato.

Non considerare Kobo AI Dictionary compatibile con firmware 5.x finché NickelMenu e l'intero flusso non saranno verificati.
