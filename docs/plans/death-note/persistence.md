# Sauvegarde locale réelle — 5 novembre 2026

Demande autorisée : sauvegarder le registre, la réputation calculée, l'état des notifications et les préférences de fenêtre, indépendamment des exemples.

Architecture : Data/Persistence.lua gère un conteneur formatVersion=1 avec ledger Store.Snapshot et ui validé. SavedVariablesPerCharacter `SyndicatRougeCharacterDB` : un registre personnel par personnage, scope explicite local:forever ; aucune guilde réelle déduite ni transfert automatique au futur réseau. Bootstrap ouvre ce registre sur ADDON_LOADED et le sauvegarde sur PLAYER_LOGOUT et après les changements locaux. La réputation et les clôtures sont recalculées via Store.Restore, jamais chargées comme compteurs de confiance.

Préférences : onglet et ancrage de la fenêtre propre à l'addon, relatif à UIParent, valeurs finies/bornées ; recherche et visibilité non conservées. Un ancrage protégé/non accessible n'est pas inspecté. /syndicat ou /sr revient au vrai registre ; /srdemo ouvre explicitement les exemples en mémoire, sans ouverture automatique au login. Démo et réglages de démo ne remplacent pas la sauvegarde réelle.

Données anciennes/futures/invalides : le conteneur original reste intact ; ouverture d'un écran vide en lecture seule avec avertissement si la restauration n'est pas fiable. Pas d'effacement ni de migration conjecturale. Le profil version 1 peut être rouvert ; un changement futur de format ou de scope devra avoir une migration explicite. Échec de checkpoint : conserver le dernier état validé.

Étapes : tests de restauration, fidélité des notifications et reconstruction des récompenses ; implémentation du conteneur puis branchement au cycle réel et aux préférences ; tests de séparation démo, /reload simulé, profil invalide, positions et versions ; paquet, installation sauvegardée ; vérification utilisateur de /reload, reconnexion et redémarrage complet séparément. Une vérification hors jeu n'est pas une preuve de persistance en jeu.

Cible/source : Forever installé 1.60.1.70790, commit API eac30af597e5aaa43a60f6675ef5fdcea100375f. ADDON_LOADED/PLAYER_LOGOUT et SavedVariables sont le cycle d'addon utilisé. SimpleScriptRegionResizingAPIDocumentation.lua vérifie GetPoint(anchorIndex,resolveCollapsed=false), SetPoint et les restrictions d'ancrage. Aucun accès à un joueur ennemi, journal de combat ou plaque n'est ajouté. La collecte et le partage restent ouverts.
