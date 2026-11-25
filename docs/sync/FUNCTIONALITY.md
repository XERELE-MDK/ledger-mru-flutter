# Sync — how it works

[← All features](../README.md) · [Code walkthrough](CODE_WALKTHROUGH.md) · [Setup](INSTALL.md)

## What it does

Each device writes **its own file** into a shared folder (Syncthing, for example) and merges the others'.

```
~/Sync/Ledger/
  ledger-android-02b6cc.json   written only by the phone
  ledger-desktop-768eb8.json   written only by the Rust app
  ledger-linux-1a2b3c.json     written only by the Flutter Linux app
```

Nobody writes someone else's file: no conflict.

## When

- when you come back to the app, then every 20 s;
- 1.2 s after a change;
- when you leave the app;
- with "Sync now".

## Merge rules

- Entries: union by id, minus those with a tombstone.
- Accounts: the most recent change wins. An account deleted but still used is kept.
- Settings (language, theme, mode): per device.

## Limits

- App closed: no sync.
- "Most recent wins" assumes the devices' clocks are right.
- Files are stored in plain text.
