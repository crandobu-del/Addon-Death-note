# Interface native — tranche du 5 novembre 2026

Objectif : programmer les quatre onglets en Lua, avec le moteur existant et la composition du concept v3 accepté. Exécution directe demandée ; pas de nouvelle validation de maquette.

Architecture : `UI/Model.lua` présente les données sans dépendance graphique ; `UI/Widgets.lua` crée les contrôles natifs ; `UI/Window.lua` porte la fenêtre et la navigation ; `UI/Views.lua` dessine les dossiers. `Bootstrap.lua` initialise après ADDON_LOADED. Une extension de développement distincte injecte les exemples, jamais le paquet de production.

Contraintes : Forever uniquement ; identité Le Syndicat Rouge ; aucun crédit de réputation par un bouton d'interface ; pas de données fictives dans les SavedVariables réelles ; texte des joueurs échappé ; aucune connexion Discord ni opération protégée. Carte illustrative explicitement signalée en démonstration ; pas de localisation réelle inventée.

- [x] Ajouter Model.Filter/Selected, tester recherche vide, caractères spéciaux, sélection conservée et changement d'onglet.
- [x] Ajouter fenêtre native déplaçable, fermeture, recherche, défilement et quatre panneaux avec état vide.
- [x] Ajouter TOC 16001 de développement, chargement ordonné, textures TGA et paquet indépendant de démonstration.
- [x] Tester import, rendu, navigation et diagnostics dans UIForever ; comparer au concept, consigner les écarts.
- [x] Mettre à jour le suivi et livrer les archives ; publication préparée sur la branche existante, avec vérification de l'identité des fichiers.

Preuves API : source Gethe/wow-ui-source branche forever épinglée à `eac30af597e5aaa43a60f6675ef5fdcea100375f`, version source 1.60.1.70790. Interface 16001 provisoire jusqu'au client réel. `Blizzard_ProjectConstants/Blizzard_ProjectConstants.toc` charge Camelot/ProjectConstants.lua : WOW_PROJECT_CAMELOT=18. Les méthodes de Frame, Texture, FontString, EditBox et ScrollFrame sont examinées dans Blizzard_APIDocumentationGenerated ; UIParent.lua démontre SetScript. Les méthodes de cadres propres à l'addon ne donnent aucun accès aux opérations protégées. Aucun contrat d'événement PvP ou plaque de nom n'est ajouté dans cette tranche.

Validation réelle du client, sauvegarde en jeu, combat, collecte PvP, transport de guilde, portraits réels et carte géographique native : non exécutés / hors de cette tranche. Le simulateur reste une preuve distincte.
