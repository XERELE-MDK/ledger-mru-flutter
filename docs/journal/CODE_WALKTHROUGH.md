# Journal — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

`lib/screens/journal.dart`

- `JournalScreen` reads `s.entriesIn(s.month)` and groups by date while walking the list backwards.
- `entryLines()` draws the Dr / Cr lines; the entry detail uses it too.
- `describe()` (`lib/model.dart`) tells whether an entry is an expense, an income or a transfer: an expense account wins over an income account.

Nothing is stored: everything is recomputed on every frame that needs it.
