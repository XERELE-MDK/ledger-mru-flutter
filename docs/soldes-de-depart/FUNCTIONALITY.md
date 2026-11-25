# Soldes de départ — fonctionnement

[← Toutes les fonctionnalités](../README.md) · [Parcours du code](CODE_WALKTHROUGH.md)

*Depuis la 1.2.0.*

## Ce que ça fait

Un champ par compte d'actif (« ce que j'ai ») et de passif (« ce que je dois »), à une date donnée. L'app en fait **une seule écriture équilibrée** : la différence va dans les capitaux propres. Ce n'est **pas un revenu**.

> J'ai 3 000 en espèces et 21 000 en banque, je dois 2 000 → Dr Espèces 3 000, Dr Banque 21 000 / Cr Dette 2 000, Cr Solde d'ouverture 22 000.

## Où

- Sur l'accueil, quand le livre est vide.
- Dans **Comptes → Soldes de départ**, à tout moment.

## Règles

- Rouvrir l'écran montre les soldes enregistrés ; les changer **remplace** l'écriture.
- Tout effacer la retire.
- Vos propres écritures sur le compte de capitaux ne sont jamais touchées.
- S'il n'y a plus de compte de capitaux, il est recréé.
