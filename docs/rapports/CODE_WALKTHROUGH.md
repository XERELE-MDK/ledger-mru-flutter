# Rapports — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

`lib/screens/reports.dart` : `_TrialBalance`, `_Monthly`, `_Budgets`, choisis par `s.report`.

- La balance masque les soldes inférieurs à 0,005 et se dit équilibrée à 0,01 près : les montants sont des `double`.
- Les barres sont des `FractionallySizedBox` ; l'échelle est le plus grand montant des 6 mois.
- `compareText()` sert aussi à l'accueil Éditorial.
