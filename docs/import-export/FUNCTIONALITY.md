# Import et export — fonctionnement

[← Toutes les fonctionnalités](../README.md) · [Parcours du code](CODE_WALKTHROUGH.md)

**Exporter** enregistre tout le livre dans un fichier JSON lisible par les trois versions.

**Importer** vérifie le fichier **en entier** avant de toucher à quoi que ce soit, puis propose :

| Choix | Effet |
|---|---|
| **Fusionner** | garde les deux côtés, suppressions comprises. L'aperçu dit ce qui changera. |
| **Remplacer** | prend le fichier tel quel. Refusé pendant la synchro. |

**Annuler** est proposé ensuite.

Limite connue : annuler un import **fusionné** ne tient pas si la synchro est active.
