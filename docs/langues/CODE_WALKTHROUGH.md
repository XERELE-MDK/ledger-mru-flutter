# Langues — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

`lib/l10n.dart`, classe `S` : chaque texte est écrit une fois avec ses trois versions.

```dart
String get tabHome => _t('Home', 'Accueil', 'ホーム');
```

Oublier une traduction ne compile pas. `lib/format.dart` lit `S.current` pour les formats. `flutter_localizations` traduit les widgets Material.

En français, `:` `;` `»` sont précédés d'une **espace insécable** (U+00A0).

Tests : matrice 3 langues × 6 thèmes × 10 écrans à 360 dp, sans débordement.
