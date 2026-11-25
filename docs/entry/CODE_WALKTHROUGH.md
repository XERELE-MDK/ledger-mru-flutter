# Adding an entry — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

## Files

| File | Role |
|---|---|
| `lib/sheets.dart` | `_AddEntry` (form), `_EntryDetail` (detail and delete), `SheetBody` |
| `lib/format.dart` | `parseAmount`, `f0`, `f2` |
| `lib/model.dart` | `AppState.addEntry`, `deleteEntry`, `restoreEntry`, `newEntryId` |

## From Simple to debit / credit

```dart
(String?, String?) sides() {
  if (s.isPro) return (dr, cr);
  if (kind == Kind.income) return (via, cat);
  return (cat, via);
}
```

## Worth knowing

- `SheetBody` pins the buttons at the bottom: only the fields scroll, even with the keyboard open.
- `parseAmount` returns `0` for "invalid". Its cases live in `test/fixtures/amounts.json`, **shared with the Rust version**.
- `restoreEntry` recreates the entry under a **new id**: the old one carries a tombstone, which always wins a merge.

## Tests

`test/ledger_test.dart`, `test/i18n_theme_test.dart` (amounts), `test/opening_test.dart` (shared cases).
