# Empty book and demo — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

- `seedData()` (`lib/model.dart`) creates the examples; their ids look like `s<YYYYMMDD>-<n>`.
- `isDemoEntry()` recognises them, `removeDemo()` removes them with tombstones.
- `useDeviceLanguage()` (`lib/main.dart`) is called **before** `load()`: otherwise the demo would always be in English.
- `demoOnlyHere()` (`lib/sync.dart`) finds the demo to leave out when joining a folder.
- `_DemoCard` only shows while the book holds nothing but demo data.

Tests: `test/start_empty_test.dart`, which also checks **every screen with no entry at all**.
