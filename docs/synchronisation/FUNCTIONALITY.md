# Synchronisation — fonctionnement

[← Toutes les fonctionnalités](../README.md) · [Parcours du code](CODE_WALKTHROUGH.md) · [Mise en place](INSTALL.md)

## Ce que ça fait

Chaque appareil écrit **son propre fichier** dans un dossier partagé (par Syncthing, par exemple) et fusionne ceux des autres.

```
~/Sync/Ledger/
  ledger-android-02b6cc.json   écrit seulement par le téléphone
  ledger-desktop-768eb8.json   écrit seulement par l'app Rust
  ledger-linux-1a2b3c.json     écrit seulement par l'app Flutter Linux
```

Personne n'écrit le fichier d'un autre : pas de conflit.

## Quand

- au retour dans l'app, puis toutes les 20 s ;
- 1,2 s après une modification ;
- en quittant l'app ;
- avec « Synchroniser ».

## Règles de fusion

- Écritures : union par identifiant, moins celles qui ont une pierre tombale.
- Comptes : la modification la plus récente gagne. Un compte supprimé mais encore utilisé est gardé.
- Réglages (langue, thème, mode) : propres à chaque appareil.

## Limites

- App fermée : pas de synchro.
- « Le plus récent gagne » suppose des appareils à l'heure.
- Les fichiers sont en clair.
