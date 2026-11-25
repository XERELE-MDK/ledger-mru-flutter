# Synchronisation — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md) · [Mise en place](INSTALL.md)

`lib/sync.dart`

| Élément | Rôle |
|---|---|
| `FolderBackend` | `SafFolder` (Android), `IoFolder` (Linux), `MemoryFolder` (tests) |
| `readFolder` | lit et fusionne les fichiers voisins, sans rien écrire |
| `SyncService` | déclencheurs, état, écriture |

## Points délicats

- **N'écrire que si le contenu diffère** (`_writeIfChanged`). Réécrire un fichier identique change sa date, réveille les autres appareils, qui réécrivent le leur, sans fin.
- **Refaire la fusion sur les données du moment** : l'utilisateur a pu saisir pendant la lecture. Aucun `await` entre l'instantané et l'application.
- **Empreinte** des noms et dates de **tous** les voisins : Syncthing garde les dates d'origine, un fichier peut arriver tard et être plus ancien.
- Un fichier illisible est sauté, et réessayé quand il change.
- Les copies `.sync-conflict-` sont fusionnées puis supprimées.

`mergeFiles` (`lib/model.dart`) suit les mêmes règles que `Book::merge` (Rust), vérifiées sur les mêmes fichiers (`test/fixtures/merge_*.json`, empreintes dans `CONTRACT.sha256`).

Tests : `test/folder_sync_test.dart`, `test/sync_guards_test.dart`, `test/sync_test.dart`.
