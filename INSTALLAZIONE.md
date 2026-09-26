# Installazione passo passo

Questa guida è scritta per chi **non programma** e vuole installare Kobo AI Dictionary mantenendo l'interfaccia Kobo standard.

Configurazione testata: **Kobo Libra Colour, firmware 4.45.23792**.

## Prima di iniziare

Servono:

- un computer;
- un cavo USB;
- Wi-Fi sul Kobo;
- un account Google con una chiave Gemini API;
- firmware Kobo 4.x compatibile con NickelMenu.

Il progetto **non richiede KOReader**.

Quando colleghi il Kobo al computer vedrai una memoria chiamata normalmente `KOBOeReader`.

Alcune cartelle iniziano con un punto, per esempio `.kobo` e `.adds`, e possono essere nascoste.

### Mostrare i file nascosti

- Windows: abilita **Elementi nascosti** in Esplora file.
- macOS: nel Finder premi **Cmd + Shift + .**
- Linux: normalmente **Ctrl + H** nel file manager.

## Regola importante per i file KoboRoot.tgz

NickelMenu, NickelDBus e KoboStuff usano tutti un file chiamato `KoboRoot.tgz`.

Installali **uno alla volta**:

1. copia un solo `KoboRoot.tgz` dentro `.kobo`;
2. espelli il Kobo in modo sicuro;
3. lascia che il Kobo installi e si riavvii;
4. ricollegalo al computer;
5. passa al componente successivo.

Non copiare più `KoboRoot.tgz` contemporaneamente.

---

## 1. Installa NickelMenu

Repository ufficiale:

https://github.com/pgaskin/NickelMenu

Pagina release:

https://github.com/pgaskin/NickelMenu/releases

Scarica la release, prendi `KoboRoot.tgz` e copialo in:

`.kobo/KoboRoot.tgz`

Espelli il Kobo e attendi il riavvio.

Dopo l'installazione dovrebbe comparire NickelMenu.

> NickelMenu dichiara che firmware Kobo 5.x non è attualmente supportato.

---

## 2. Installa NickelDBus

Repository ufficiale:

https://github.com/shermp/NickelDBus

Release:

https://github.com/shermp/NickelDBus/releases

Scarica `KoboRoot.tgz`, copialo in:

`.kobo/KoboRoot.tgz`

Espelli il Kobo e attendi il riavvio.

NickelDBus installa anche il comando:

`/usr/bin/qndb`

Questo comando è necessario per la finestra con tastiera usata da `ai-search.sh`.

---

## 3. Installa KoboStuff

KoboStuff di NiLuJe fornisce le utility Unix aggiuntive usate dal progetto.

Thread/progetto originale:

https://www.mobileread.com/forums/showthread.php?t=254214

Archivio utilizzato e verificato durante lo sviluppo:

`kobo-stuff-1.6.N-r18901.tar.xz`

Una copia archivistica dello stesso pacchetto è disponibile qui:

https://github.com/usetrmnl/trmnl-kobo/tree/main/doc/distrib/kobostuff

Scarica l'archivio e aprilo sul computer. All'interno della cartella `KoboStuff` trovi un file:

`KoboRoot.tgz`

Copia quel file in:

`.kobo/KoboRoot.tgz`

Espelli il Kobo e attendi il riavvio.

Nel setup funzionante KoboStuff fornisce le utility usate dal progetto, in particolare:

- `/usr/bin/curl`;
- `/usr/bin/jq`;
- l'ambiente BusyBox/core utilities nel quale è disponibile `/usr/bin/unzip`.

### Nota su unzip

Il nostro Kobo funzionante dispone di:

`/usr/bin/unzip`

e lo script lo usa per leggere i file interni degli EPUB.

La documentazione pubblica di KoboStuff conferma che il pacchetto installa il core di utility e contiene modifiche a BusyBox. BusyBox prevede l'applet `unzip` proprio in `/usr/bin/unzip`.

Non abbiamo però un manifest testuale pubblico dell'esatto archivio `1.6.N-r18901` che elenchi ogni file installato. Per questo la guida non presume ciecamente la presenza di `unzip`: alla fine useremo la verifica automatica inclusa nel progetto.

---

## 4. Procurati sqlite3

Lo script legge il database Kobo in modalità read-only e richiede un eseguibile `sqlite3`.

La fonte verificata è Kobo-UNCaGED:

https://github.com/shermp/Kobo-UNCaGED

Release:

https://github.com/shermp/Kobo-UNCaGED/releases

Scarica il file ZIP della release sul computer e aprilo.

All'interno trovi:

`.adds/kobo-uncaged/bin/sqlite3`

Per Kobo AI Dictionary non è necessario usare le funzioni di Kobo-UNCaGED. Ci serve soltanto questo eseguibile.

Tieni `sqlite3` da parte: lo copieremo nel punto 6.

---

## 5. Scarica Kobo AI Dictionary

Apri:

https://github.com/adanyel/kobo-ai-dictionary

Premi:

**Code → Download ZIP**

Estrai lo ZIP sul computer.

Troverai, tra gli altri:

`src/ai-dictionary.sh`

`src/ai-search.sh`

`src/check-install.sh`

`ai-tools/kobo-context`

`nm/ai-dictionary`

`nm/ai-search`

`nm/ai-check`

---

## 6. Copia i file del progetto sul Kobo

Sul Kobo crea, se non esistono:

`.adds`

`.adds/ai-tools`

`.adds/nm`

Copia i file in questo modo:

| File nel repository | Destinazione sul Kobo |
|---|---|
| `src/ai-dictionary.sh` | `.adds/ai-dictionary.sh` |
| `src/ai-search.sh` | `.adds/ai-search.sh` |
| `src/check-install.sh` | `.adds/ai-check-install.sh` |
| `ai-tools/kobo-context` | `.adds/ai-tools/kobo-context` |
| `nm/ai-dictionary` | `.adds/nm/ai-dictionary` |
| `nm/ai-search` | `.adds/nm/ai-search` |
| `nm/ai-check` | `.adds/nm/ai-check` |
| `sqlite3` preso da Kobo-UNCaGED | `.adds/ai-tools/sqlite3` |

Alla fine la parte importante deve assomigliare a questa:

```text
KOBOeReader/
└── .adds/
    ├── ai-dictionary.sh
    ├── ai-search.sh
    ├── ai-check-install.sh
    ├── gemini.key          <-- da creare nel prossimo passaggio
    ├── ai-tools/
    │   ├── kobo-context
    │   └── sqlite3
    └── nm/
        ├── ai-dictionary
        ├── ai-search
        └── ai-check
```

---

## 7. Crea la chiave Gemini API

Google spiega come creare una chiave qui:

https://ai.google.dev/gemini-api/docs/api-key

In Google AI Studio crea o copia una chiave Gemini API.

Sul computer crea un semplice file di testo chiamato:

`gemini.key`

Il file deve contenere **solo la chiave**, su una singola riga.

Esempio della struttura, non usare questa stringa:

```text
AIza...la_tua_chiave...
```

Copia il file in:

`.adds/gemini.key`

Non pubblicare mai questo file e non aggiungerlo a GitHub.

---

## 8. Espelli il Kobo e riavvia

Espelli il Kobo in modo sicuro.

Per sicurezza, riavvia il dispositivo una volta dopo aver copiato tutti i file.

---

## 9. Verifica l'installazione

Apri un libro.

Nel menu del lettore dovresti vedere:

**AI Dictionary - Verifica installazione**

Selezionalo.

La verifica controlla senza mostrare la tua chiave API:

- curl;
- jq;
- unzip;
- qndb;
- sqlite3;
- kobo-context;
- script principali;
- file della chiave Gemini;
- database Kobo.

Se tutti i componenti risultano `OK`, l'installazione di base è completa.

---

## 10. Usa il dizionario

### Da una parola nel libro

1. apri un EPUB;
2. seleziona una parola o espressione;
3. apri il menu della selezione;
4. scegli **AI Dictionary**;
5. attendi la risposta;
6. il risultato si apre nel browser interno Kobo.

### Ricerca manuale

Nel menu durante la lettura scegli:

**AI Dictionary - Cerca parola**

Digita la parola e premi **Cerca**.

---

## Cosa viene inviato a Gemini

Per interpretare correttamente la parola nel libro, possono essere inviati a Gemini:

- parola selezionata;
- titolo;
- autore;
- nome file EPUB;
- porzione di testo circostante.

Se non vuoi inviare il contesto di un libro a un servizio esterno, non usare il dizionario su quel contenuto.

---

## Aggiornamenti firmware

Gli aggiornamenti firmware Kobo possono modificare compatibilità e componenti di sistema.

Prima di aggiornare:

- controlla la compatibilità di NickelMenu;
- conserva una copia dei file del progetto;
- conserva la tua chiave API separatamente;
- dopo l'aggiornamento esegui di nuovo **AI Dictionary - Verifica installazione**.

Il progetto è stato verificato su firmware **4.45.23792**.
