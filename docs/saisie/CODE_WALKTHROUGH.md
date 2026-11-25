# Saisir une écriture — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

## Fichiers

| Fichier | Rôle |
|---|---|
| `lib/sheets.dart` | `_AddEntry` (formulaire), `_EntryDetail` (détail et suppression), `SheetBody` |
| `lib/format.dart` | `parseAmount`, `f0`, `f2` |
| `lib/model.dart` | `AppState.addEntry`, `deleteEntry`, `restoreEntry`, `newEntryId` |

## La conversion Simple → débit / crédit

```dart
(String?, String?) sides() {
  if (s.isPro) return (dr, cr);
  if (kind == Kind.income) return (via, cat);
  return (cat, via);
}
```

## Ce qu'il faut savoir

- `SheetBody` fixe les boutons en bas : seuls les champs défilent, même clavier ouvert.
- `parseAmount` rend `0` pour « invalide ». Ses cas sont dans `test/fixtures/amounts.json`, **partagés avec la version Rust**.
- `restoreEntry` recrée l'écriture sous un **nouvel identifiant** : l'ancien porte une pierre tombale, qui gagne toujours lors d'une fusion.

## Tests

`test/ledger_test.dart`, `test/i18n_theme_test.dart` (montants), `test/opening_test.dart` (cas partagés).
