# ai-tools

Questa cartella contiene gli strumenti binari usati da Kobo AI Dictionary.

## Incluso nel repository

- `kobo-context`: helper ARMv7 specifico del progetto.

## Da aggiungere sul Kobo durante l'installazione

- `sqlite3`: dipendenza esterna, ricavata dal pacchetto Kobo-UNCaGED.

Sul dispositivo i due file devono trovarsi in:

```text
/mnt/onboard/.adds/ai-tools/kobo-context
/mnt/onboard/.adds/ai-tools/sqlite3
```

`sqlite3` non viene duplicato in questo repository. Segui [INSTALLAZIONE.md](../INSTALLAZIONE.md).
