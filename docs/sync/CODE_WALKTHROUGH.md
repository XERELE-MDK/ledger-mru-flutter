# Sync — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md) · [Setup](INSTALL.md)

`lib/sync.dart`

| Piece | Role |
|---|---|
| `FolderBackend` | `SafFolder` (Android), `IoFolder` (Linux), `MemoryFolder` (tests) |
| `readFolder` | reads and merges the neighbours' files, writes nothing |
| `SyncService` | triggers, state, writing |

## Tricky parts

- **Only write when the content differs** (`_writeIfChanged`). Rewriting an identical file changes its date, wakes the other devices, which rewrite theirs, forever.
- **Redo the merge on the current data**: the user may have typed during the read. No `await` between the snapshot and applying it.
- **Fingerprint** the names and dates of **all** neighbours: Syncthing keeps original dates, so a file can arrive late and still be older.
- An unreadable file is skipped, and retried when it changes.
- `.sync-conflict-` copies are merged, then deleted.

`mergeFiles` (`lib/model.dart`) follows the same rules as `Book::merge` (Rust), checked on the same files (`test/fixtures/merge_*.json`, hashes in `CONTRACT.sha256`).

Tests: `test/folder_sync_test.dart`, `test/sync_guards_test.dart`, `test/sync_test.dart`.
