# Import et export — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

- `lib/screens/settings.dart`, `_DataPanel`.
- `lib/files.dart` : sélecteur de fichiers. Android : canal `ledger/files` ; Linux : `zenity`.
- `LedgerFile.parse` (`lib/model.dart`) contrôle : JSON, structure, identifiants uniques, types connus, **dates réelles**, équilibre, comptes existants. Un échec lève une `FormatException` au message traduit.
- `mergeFiles` : voir [Synchronisation](../synchronisation/CODE_WALKTHROUGH.md).

Tests : `test/sync_test.dart`, `test/import_flow_test.dart`, `test/sync_guards_test.dart`.
