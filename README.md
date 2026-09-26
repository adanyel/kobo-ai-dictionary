# Kobo AI Dictionary

Dizionario AI per **Kobo con interfaccia standard Nickel**, senza KOReader.

Il progetto permette di selezionare una parola direttamente durante la lettura di un EPUB sul Kobo e ottenere una spiegazione contestuale generata con Gemini. È disponibile anche una ricerca manuale con tastiera.

> **Lingua del progetto:** al momento il progetto è pensato principalmente per utenti italiani. Interfaccia, documentazione e risposte del dizionario sono principalmente in italiano. Il dizionario riconosce italiano, inglese e spagnolo e fornisce traduzioni nelle altre due lingue.

## Perché questo progetto

L'obiettivo è avere un dizionario AI senza sostituire il lettore Kobo originale.

- si continua a leggere nell'interfaccia Kobo/Nickel;
- non serve KOReader;
- note, evidenziazioni e avanzamento di lettura restano gestiti dal Kobo;
- il database Kobo viene letto in modalità read-only;
- il contesto viene ricavato dalla posizione corrente nell'EPUB quando possibile.

## Stato e compatibilità

Configurazione realmente testata:

- Kobo Libra Colour;
- firmware **4.45.23792**;
- EPUB sideloaded/locali;
- NickelMenu;
- NickelDBus;
- KoboStuff;
- Gemini API.

NickelMenu dichiara attualmente che il firmware Kobo **5.x non è supportato**. Per questo motivo il progetto va considerato, per ora, un progetto per firmware Kobo 4.x.

Altri modelli Kobo e altri firmware 4.x potrebbero funzionare, ma non sono ancora stati verificati.

## Funzioni

### Dizionario dalla parola selezionata

Durante la lettura:

1. seleziona una parola o espressione;
2. scegli **AI Dictionary**;
3. lo script identifica libro e posizione;
4. estrae il contesto dall'EPUB;
5. interroga Gemini;
6. apre una pagina con spiegazione, contesto, etimologia, traduzioni, sinonimi, collocazioni, esempi e note grammaticali.

### Ricerca manuale

Nel menu del lettore è disponibile:

**AI Dictionary - Cerca parola**

Apre una finestra di input tramite NickelDBus/qndb.

## File creati per questo progetto

Questi sono i componenti specifici di Kobo AI Dictionary presenti nel repository:

- `src/ai-dictionary.sh` → script principale;
- `src/ai-search.sh` → ricerca manuale;
- `ai-tools/kobo-context` → helper ARMv7 che estrae il contesto dalla posizione dell'EPUB;
- `nm/ai-dictionary` → voce NickelMenu per il testo selezionato;
- `nm/ai-search` → voce NickelMenu per la ricerca manuale.

È presente anche una verifica opzionale dell'installazione:

- `src/check-install.sh`;
- `nm/ai-check`.

Le altre componenti necessarie sono progetti esterni e **non vengono duplicate nel repository**: in questo modo l'utente può installarle dalle rispettive fonti ufficiali e non rimaniamo bloccati a copie vecchie o con licenze differenti.

## Installazione per utenti non tecnici

Segui la guida:

**[INSTALLAZIONE.md](INSTALLAZIONE.md)**

La guida parte da un Kobo non modificato e indica esattamente cosa scaricare, dove copiarlo e in quale ordine.

Per capire da dove arrivano tutte le dipendenze:

**[DEPENDENCIES.md](DEPENDENCIES.md)**

Per licenze e progetti esterni:

**[THIRD_PARTY.md](THIRD_PARTY.md)**

## Privacy

Per generare la risposta, lo script invia all'API Gemini:

- parola o espressione cercata;
- titolo e autore del libro;
- nome del file EPUB;
- contesto estratto dal libro, quando disponibile.

La chiave API rimane nel file locale:

`/mnt/onboard/.adds/gemini.key`

Non caricare mai questo file su GitHub.

L'uso dell'API Gemini è soggetto alle condizioni, alle quote e all'eventuale fatturazione dell'account Google dell'utente.

## Limiti attuali

- testato principalmente su Kobo Libra Colour;
- testato su firmware 4.45.23792;
- pensato per EPUB accessibili come file sul dispositivo;
- Kobo Store/KEPUB, PDF e altri formati non sono ancora considerati supportati;
- il progetto è principalmente in italiano;
- richiede Wi-Fi quando viene effettuata la richiesta a Gemini;
- dipende da componenti Kobo di terze parti.

## Sicurezza dei dati

Non includere mai nel repository:

- `gemini.key`;
- `KoboReader.sqlite`;
- EPUB personali;
- file di debug contenenti testo dei libri;
- dati personali del dispositivo.

## Crediti

Questo progetto utilizza o si appoggia a software di terze parti, tra cui NickelMenu, NickelDBus, KoboStuff, SQLite/Kobo-UNCaGED e Gemini API. I relativi autori e repository sono indicati in [THIRD_PARTY.md](THIRD_PARTY.md).
