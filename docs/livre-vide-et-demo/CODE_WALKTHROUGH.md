# Livre vide et démo — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md)

- `seedData()` (`lib/model.dart`) crée les exemples ; leurs identifiants ont la forme `s<AAAAMMJJ>-<n>`.
- `isDemoEntry()` les reconnaît, `removeDemo()` les retire avec des pierres tombales.
- `useDeviceLanguage()` (`lib/main.dart`) est appelé **avant** `load()` : sans cela, la démo serait toujours en anglais.
- `demoOnlyHere()` (`lib/sync.dart`) trouve la démo à laisser de côté en rejoignant un dossier.
- `_DemoCard` n'apparaît que si le livre ne contient que de la démo.

Tests : `test/start_empty_test.dart`, qui vérifie aussi **tous les écrans sans aucune écriture**.
