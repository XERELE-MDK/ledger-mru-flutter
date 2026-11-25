# Comptes et budgets — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

- `lib/screens/accounts.dart` : liste groupée par type.
- `lib/sheets.dart`, `_AccountEditor` : formulaire.
- `AppState.upsertAccount` date chaque modification (`updatedAt`) : à la fusion, **la plus récente gagne**.
- `AppState.newAccountId` fabrique l'identifiant à partir du nom (`Gaz & eau` → `gaz-eau`, puis `gaz-eau-2`).
- `deleteAccount` laisse une pierre tombale.
