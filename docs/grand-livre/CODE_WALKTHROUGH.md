# Grand livre — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

`lib/screens/ledger.dart`

```dart
var run = s.rawBal(la.id, '$ym-00');     // tout ce qui précède le mois
for (final e in s.entriesIn(ym)) { … run += l.dr - l.cr; … }
```

`'2026-11-00'` n'est pas une date : on compare des **chaînes**, et `-00` passe avant tous les jours du mois. De même, `-31` passe après.

`normalBal()` inverse le signe des comptes au crédit.
