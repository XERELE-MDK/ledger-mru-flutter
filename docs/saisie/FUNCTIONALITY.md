# Saisir une écriture — fonctionnement

[← Toutes les fonctionnalités](../README.md) · [Parcours du code](CODE_WALKTHROUGH.md)

## Ce que ça fait

Le bouton **+** ouvre une feuille. En mode **Simple**, on choisit une intention et l'app écrit la partie double :

| Choix | Débit | Crédit | Exemple |
|---|---|---|---|
| Dépense | la catégorie | le moyen de paiement | Taxi 300 : Transport / Espèces |
| Revenu | le compte qui reçoit | la source | Salaire : Banque / Salaire |
| Virement | « Vers » | « Depuis » | Retrait : Espèces / Banque |

En mode **Comptable**, on choisit soi-même le compte débité et le compte crédité.

## Règles

- Montant strictement positif, deux comptes différents.
- Le montant se tape comme on veut : `1 250,50`, `1,250.50`, `1.250,50`, `1250.5`. `1,250` vaut **1250**, `12,5` vaut 12,5. Un aperçu montre ce qui a été compris.
- Note vide : l'app écrit un libellé (« Transport », « Virement vers Épargne »…).
- La date proposée est aujourd'hui, ou le 1er du mois affiché s'il est différent.

## Corriger ou supprimer

Une écriture ne se modifie pas : on la supprime et on en crée une autre, comme en comptabilité. La suppression propose **Annuler** pendant 4 s.
