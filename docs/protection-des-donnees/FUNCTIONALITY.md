# Protection des données — fonctionnement

[← Toutes les fonctionnalités](../README.md) · [Parcours du code](CODE_WALKTHROUGH.md)

- Des données locales illisibles n'empêchent **pas** l'app de s'ouvrir.
- Une **copie exacte** est gardée avant toute écriture. Un bandeau l'explique, avec « Enregistrer la copie » ; le bouton reste dans Paramètres.
- Si cette copie échoue (disque plein), **rien n'est enregistré** jusqu'au redémarrage, et l'app le dit.
- La synchro est débranchée : la démo affichée ne peut pas écraser la bonne copie du dossier.
- Pour récupérer ses données : rebrancher le dossier, puis « Utiliser le dossier ».
