# Première tranche hors jeu

Autorisation : « ok go » après proposition de développer le socle des incidents et de la réputation puis de le brancher sur l'interface. Réalisation dans la session courante, sans demander une nouvelle validation de ce périmètre.

## Livrable

Moteur Lua indépendant des API WoW, testé hors jeu, et aperçu navigateur à quatre onglets utilisant exactement ces mêmes modules Lua via Fengari. Aucune fixture dans le dossier addon. Aucun TOC présenté comme installable. Aucune détection, synchronisation réseau, position en temps réel ou connexion Discord simulée comme active.

## Décisions de cette tranche

- Identités explicites comprenant royaume et personnage ; ne pas fusionner deux homonymes.
- Une base séparée par identifiant de guilde. Schéma versionné.
- Prime provisoire : nombre total d'incidents distincts attribués à l'ennemi, conservé dans son historique. Statut recherché et récompense dépendent des incidents encore ouverts. Cette formule reste ajustable.
- 1 réputation par incident ouvert clôturé. La clôture reçoit une liste explicite d'incidents et un seul vengeur désigné ; elle est atomique. Aucun algorithme de répartition en groupe ou de fusion concurrente réseau n'est livré dans cette tranche.
- Une répétition identique ne change rien ; un même identifiant avec un contenu différent est un conflit, pas une mise à jour silencieuse.
- Une notification par vengeance et victime concernée, indépendamment du nombre de ses incidents clôturés. Remerciement volontaire mémorisé localement ; aucun message réellement envoyé.
- Les noms, dates, lieux, portraits et marqueurs de l'aperçu sont fictifs. La mémoire locale du navigateur concerne uniquement cette démonstration et ne valide pas les SavedVariables.

## Travail et vérifications

1. Tests Lua : identités, validation, doublons, conflits, horodatages, clôture atomique, réputation, récidive, classement, notifications et restauration.
2. Implémenter Init/Config, Store/Validation, Incidents/Wanted/Vengeance/Reputation/Notifications et Core sans dépendance au client.
3. Construire un hôte Lua de développement et une fixture reproductible hors du dossier addon.
4. Aperçu : liste et dossier, carte illustrative du dernier meurtre, classement, journal et notifications. Commande locale de simulation de vengeance uniquement en mode démonstration. Réinitialisation et erreur de sauvegarde explicites.
5. Vérifier les interactions à largeur bureau et mobile, capturer le rendu réel et noter les écarts aux concepts. Les textes et contrôles restent dynamiques ; une image complète de maquette n'est pas une interface fonctionnelle.

Couverture : REQ-002/004 (modèle seulement), REQ-005/007/008/009/010/011/016 (logique locale), REQ-012/014/015/018 (aperçu). REQ-001/003/006 (client réel), REQ-013 (coordonnées réelles), REQ-017 et REQ-019 restent à vérifier/implémenter comme indiqué dans la matrice.
