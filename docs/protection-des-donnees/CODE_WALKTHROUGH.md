# Protection des données — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

`AppState.load` et `_keepDamaged` (`lib/model.dart`), `SyncService.load` (`lib/sync.dart`), `_DamagedNotice` (`lib/main.dart`).

1. Toute la lecture est dans un `try`.
2. Le texte d'origine rejoint la liste `ledger-mru-damaged`, et l'écriture est **attendue** avant de toucher à la clé principale.
3. `savingOff` bloque `_save` si la copie n'a pas pu être gardée.
4. L'appareil reçoit un **nouvel identifiant** : son ancien fichier, dans le dossier, devient celui d'« un autre appareil », donc récupérable.

Tests : `test/damaged_data_test.dart`, avec un stockage qui refuse d'écrire.
