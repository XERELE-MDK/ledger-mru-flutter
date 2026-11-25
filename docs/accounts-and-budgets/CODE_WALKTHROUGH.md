# Accounts and budgets — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

- `lib/screens/accounts.dart`: list grouped by type.
- `lib/sheets.dart`, `_AccountEditor`: the form.
- `AppState.upsertAccount` stamps every change (`updatedAt`): on merge, **the most recent wins**.
- `AppState.newAccountId` builds the id from the name (`Gas & water` → `gas-water`, then `gas-water-2`).
- `deleteAccount` leaves a tombstone.
