# Soldes de départ — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

| Fichier | Rôle |
|---|---|
| `lib/sheets.dart` | `showOpeningSheet`, `_Opening` |
| `lib/model.dart` | `openingRows`, `openingDate`, `setOpening`, `isOpeningEntry` |
| `lib/main.dart` | `_EmptyCard` |

## Reconnaître l'écriture

Son identifiant commence par `o` suivi de l'heure en millisecondes (`o1795…-3fa2`). C'est ce qui permet de la remplacer sans toucher aux autres.

## Équilibrer

```dart
final diff = (lines.fold(0.0, (t, l) => t + l.dr - l.cr) * 100).round() / 100;
if (diff != 0) lines.add(diff > 0 ? Line(eq, 0, diff) : Line(eq, -diff, 0));
```

L'arrondi au centième évite une ligne fantôme : `0.1 + 0.2 - 0.3` ne vaut pas exactement 0 en binaire.

Mêmes règles que `Book::set_opening` (Rust). Tests : `test/opening_test.dart`.
