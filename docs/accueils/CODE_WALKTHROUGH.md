# Écrans d'accueil — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

- `lib/screens/home.dart` (Aperçu), `lib/screens/home_alt.dart` (les trois autres).
- `lib/main.dart`, `Shell` : un `switch (s.homeStyle)` choisit le widget.
- Galets : diamètre = `56 + √(montant / max) × 86`. L'œil compare des **surfaces**, d'où la racine carrée.
- `inkOn()` choisit l'encre selon la luminance du fond.

Ajouter un accueil : un widget, un cas dans le `switch`, une ligne dans `settings.dart`, deux textes dans `l10n.dart`, et l'ajouter à la matrice de `test/i18n_theme_test.dart`.
