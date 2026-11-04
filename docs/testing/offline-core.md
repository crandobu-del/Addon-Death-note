# Vérification de la première tranche hors jeu

## Périmètre

WoW Forever reste la cible exclusive. Cette tranche ne fait appel à aucune API de jeu ; elle ne certifie donc pas le fonctionnement sur le client. Aucun manifeste TOC ou archive d'addon installable n'est livré.

## Moteur de règles

`node tools/test-lua.mjs` : 16 scénarios Lua passés, exécutés sur les modules du dossier addon avec Fengari 0.1.4. Fengari implémente Lua 5.3 ; les modules utilisent volontairement une syntaxe et des bibliothèques communes à Lua 5.1, mais cela ne remplace pas un test sur le Lua de Forever.

Couverture : données invalides, copies défensives, doublons et conflits d'identifiants, ordre d'arrivée différent de l'ordre des événements, homonymes de royaumes différents, attribution de réputation, notifications par victime, impossibilité de récompenser un incident déjà clôturé, atomicité d'une clôture mixte valide/invalide, guilde/ennemi/date incohérents, récidive, remerciement, restauration et schéma inconnu. Les récompenses sont recalculées à partir des incidents clôturés, jamais depuis un compteur fourni par une sauvegarde.

## Aperçu navigateur

Construction : `node tools/build-demo.mjs`. Tests : `node tools/test-demo.mjs` avec un navigateur Chromium de Playwright, ou `PW_CHANNEL=chrome` lorsque Chrome est déjà disponible. Sur PowerShell, affecter la variable d'environnement avant la commande.

Vérifications réalisées :
- affichage des quatre ennemis et sélection d'un dossier ;
- fermeture/réouverture du registre ;
- vengeance simulée de trois incidents : récompense +3, Kaëlan passe de 1 à 4 réputation et l'action devient indisponible ;
- mise à jour des quatre onglets à partir du même moteur Lua ;
- filtres du journal, notification personnelle dédupliquée et remerciement volontaire ;
- restauration du scénario et des préférences après rechargement ;
- recherche sans résultat et texte contenant des balises ;
- absence de débordement horizontal à 1180 px et 360 px ;
- réinitialisation du scénario ;
- signalement d'une sauvegarde corrompue sans l'écraser silencieusement ;
- ouverture directe du fichier compilé `demo/build/index.html`, sans serveur ;
- aucune exception JavaScript relevée pendant ces parcours.

Les captures réelles sont enregistrées localement dans `docs/testing/screenshots/` par les tests : wanted-desktop, avengers-desktop, journal-desktop, notifications-desktop et notifications-mobile. Elles peuvent être régénérées et sont exclues de Git. Les captures ne sont pas des images du client WoW.

## Comparaison visuelle

Références : concepts v3 du registre et concepts des trois autres onglets dans `docs/plans/death-note/assets/`.
Inspection des captures : hiérarchie liste/dossier conservée, emblème et nom de guilde conformes, portraits recadrés, réputation distincte de la prime, tampon appliqué seulement aux incidents ou ennemis entièrement vengés, carte indépendante sans texte peint ni marqueur fixe. Les noms, données, marqueur et contrôles de l'aperçu sont dynamiques.

Écarts encore ouverts : le parchemin principal et les bords utilisent une composition CSS simplifiée, les polices sont celles du système, le dossier du vengeur est plus sobre que le concept, et le mode mobile réorganise le contenu. Les ressources natives de WoW, leurs formats et leur rendu restent à développer. Aucune correspondance visuelle exacte avec les concepts ni interface Lua native terminée n'est revendiquée.

## Résultats non exécutés

Détection PvP, accès aux identités/coordonnées, SavedVariables dans le client, plaques de nom en combat, synchronisation à deux clients, résolution concurrente de revendications, attribution en groupe, accès Discord et UIForever : non exécutés / non implémentés dans cette tranche. Un test navigateur n'est pas un test UIForever.

## Livraison locale

`python tools/package-demo.py` prépare `dist/SyndicatRouge-demo-hors-jeu-0.1.0.zip`. Son dossier `SyndicatRouge-demo/` contient uniquement l'aperçu et ses ressources locales. Extraire puis ouvrir `index.html`. L'archive n'est pas un paquet d'addon WoW.
