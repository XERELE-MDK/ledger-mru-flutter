# Thèmes — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

`lib/theme.dart`

- `AppTheme` : couleurs, rampes 100–900, polices.
- `AppTheme.generate()` fabrique tout un thème à partir de **5 couleurs**.
- `C` : façade lue par tous les écrans (`C.bg`, `C.a700`). Aucune couleur en dur ailleurs.
- Règle : 100–300 = fonds teintés, 700–900 = texte posé dessus, dans tous les thèmes.

Changer de thème change la `key` de `MaterialApp` : tout l'arbre est reconstruit et relit `C`.

Tests : contrastes WCAG de chaque thème, présence de chaque police.
