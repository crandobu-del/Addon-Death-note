# Contrôle de toutes les cartes de zones — 5 novembre 2026

Périmètre confirmé : toutes les cartes de type Zone accessibles dans l'arbre du client Forever, pas seulement les quatre exemples. Aucune téléportation, exploration ou action de jeu nécessaire.

L'observation native du jeu échoue encore (capture expirée ; nouvelle tentative interrompue par une interaction utilisateur). Aucun connecteur Witchcraft découvert. Ne pas annoncer un contrôle visuel complet à partir du seul code.

Plan : ajouter au compagnon de développement un catalogue parcourant les racines accessibles, un contrôle séquentiel du même composant de carte que le dossier, puis une galerie précédente/suivante. Chaque carte reçoit des résultats distincts : rendu sans erreur Lua, tuiles effectivement chargées via IsObjectLoaded, validation visuelle manuelle ou non effectuée. Les échecs, interruptions, limites de parcours et API indisponibles restent visibles. Un rapport local SavedVariables du compagnon contient seulement build, interface, identifiants/noms de cartes et résultats ; aucune identité ou position du personnage.

Sources identiques au client : eac30af597e5aaa43a60f6675ef5fdcea100375f, version 1.60.1.70790. MapConstantsDocumentation.lua : UIMapType.Zone=3 ; SimpleRegionAPIDocumentation.lua : IsObjectLoaded()->bool. APIs de carte et scripts de cadres déjà vérifiés. Aucun nouveau module Glue ni bibliothèque externe.

Étapes : catalogue borné et tests ; contrôle des tuiles/galerie et tests ; installation sauvegardée ; exécution dans le jeu via /sraudit lancer ; sauvegarde /reload et lecture du rapport local. Toute étape dépendant d'une action ou capture non reçue reste en attente, pas passée. Une racine non exposée au catalogue public n'est pas couverte par la seule découverte.
