# Data safety — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

`AppState.load` and `_keepDamaged` (`lib/model.dart`), `SyncService.load` (`lib/sync.dart`), `_DamagedNotice` (`lib/main.dart`).

1. The whole read is inside a `try`.
2. The original text joins the `ledger-mru-damaged` list, and that write is **awaited** before the main key is touched.
3. `savingOff` blocks `_save` if the copy could not be kept.
4. The device gets a **new id**: its old file in the folder becomes "another device's", so it can be recovered.

Tests: `test/damaged_data_test.dart`, with a storage that refuses to write.
