# Journal des versions

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) · numéros : [SemVer](https://semver.org/lang/fr/).
Les trois dépôts ([rust](https://github.com/XERELE-MDK/ledger-mru-rust), [flutter](https://github.com/XERELE-MDK/ledger-mru-flutter), [mobile](https://github.com/XERELE-MDK/ledger-mru-mobile)) avancent avec **le même numéro**.

> Le suivi git commence à la **1.1.3**. Les versions antérieures sont décrites ici pour mémoire : leur code n'a pas été conservé, elles n'ont donc ni étiquette ni fichiers publiés.

## [1.2.0] — 2026-11-25

### Ajouté
- **Soldes de départ** : ce qu'on a et ce qu'on doit au début, en une écriture équilibrée ([doc](docs/soldes-de-depart/FUNCTIONALITY.md)).
- Documentation par fonctionnalité, compilations automatiques, licence GPL-3.0.
### Corrigé
- Espaces insécables manquantes dans plusieurs messages en français.

## [1.1.3] — 2026-11-25

### Ajouté
- « Commencer avec un livre vide » : retire la démo, et rien d'autre.
### Corrigé
- Au premier lancement, la démo était toujours créée en anglais.
- Deux démos dans deux langues n'entrent plus en conflit.

## 1.1.2 — 2026-11-25

### Corrigé
- Synchro en boucle : un fichier identique n'est plus réécrit.
- Une saisie faite pendant une synchro pouvait être perdue ou oubliée.
- Annuler une suppression déjà synchronisée ne tenait pas.
- « Revenir à la démo » et « Remplacer » sont refusés pendant la synchro.
- Un bandeau « Annuler » ne se fermait plus tout seul.

## 1.1.1 — 2026-11-25

### Corrigé
- Des données locales illisibles empêchaient l'app de s'ouvrir, ou étaient écrasées.

## 1.1.0 — 2026-11-24

### Ajouté
- 6 thèmes complets, 3 langues (français, anglais, japonais), écran Paramètres.
- Accueils Éditorial, Compte en T et Galets. Nouvelle icône.
### Corrigé
- Saisie « 1,250 », montants infinis ou négatifs, fausses dates à l'import.

[1.2.0]: https://github.com/XERELE-MDK/ledger-mru-flutter/releases/tag/v1.2.0
[1.1.3]: https://github.com/XERELE-MDK/ledger-mru-flutter/releases/tag/v1.1.3
