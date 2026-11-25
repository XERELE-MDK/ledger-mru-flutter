# Ledger — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

`lib/screens/ledger.dart`

```dart
var run = s.rawBal(la.id, '$ym-00');     // everything before the month
for (final e in s.entriesIn(ym)) { … run += l.dr - l.cr; … }
```

`'2026-11-00'` is not a date: dates are compared as **strings**, and `-00` sorts before every day of the month. Likewise `-31` sorts after.

`normalBal()` flips the sign of credit-side accounts.
