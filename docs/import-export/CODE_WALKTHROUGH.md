# Import and export — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

- `lib/screens/settings.dart`, `_DataPanel`.
- `lib/files.dart`: file picker. Android: the `ledger/files` channel; Linux: `zenity`.
- `LedgerFile.parse` (`lib/model.dart`) checks: JSON, structure, unique ids, known types, **real dates**, balance, existing accounts. A failure throws a `FormatException` with a translated message.
- `mergeFiles`: see [Sync](../sync/CODE_WALKTHROUGH.md).

Tests: `test/sync_test.dart`, `test/import_flow_test.dart`, `test/sync_guards_test.dart`.
