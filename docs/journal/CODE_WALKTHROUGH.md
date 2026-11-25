# Journal — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

`lib/screens/journal.dart`

- `JournalScreen` lit `s.entriesIn(s.month)` et regroupe par date en parcourant la liste à l'envers.
- `entryLines()` dessine les lignes Dr / Cr ; elle sert aussi au détail d'une écriture.
- `describe()` (`lib/model.dart`) dit si une écriture est une dépense, un revenu ou un virement : la présence d'un compte de dépense l'emporte sur celle d'un revenu.

Rien n'est stocké : tout est recalculé à chaque affichage.
