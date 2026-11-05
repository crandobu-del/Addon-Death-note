# Interface native 0.4.0-dev — résultats du 5 novembre 2026

## Remplacement de la carte illustrative par les cartes du jeu

UI/Map.lua utilise C_Map.GetMapInfo/GetMapArtLayers/GetMapArtLayerTextures du client 1.60.1.70790 (source épinglée identique ci-dessous). Les tuiles sont ordonnées par lignes, les marges des dernières tuiles recadrées et l'ensemble ajusté proportionnellement dans l'encart 360×180. Le marqueur utilise la même transformation que le fond et uniquement les coordonnées enregistrées. Il ne représente jamais la position actuelle de l'ennemi. Sans coordonnées : carte de zone et mention de position précise inconnue. Sans carte/API/textures : état indisponible explicite, sans ancienne illustration de secours.

La démonstration résout ses noms de zones auprès de l'arbre réel du client via GetFallbackWorldMapID/GetMapChildrenInfo. Les identifiants historiques des fixtures ne sont plus imposés au client ; un nom ambigu ou inconnu ne produit ni carte devinée ni coordonnées. Les lieux de démonstration restent fictifs même lorsque leur fond provient du jeu. Aucun fond Blizzard n'est téléchargé, copié ou redistribué ; l'ancienne illustration est exclue des nouvelles archives.

Tests après modification : 19 UI, 14 cartes et 39 moteur passés (72 contrôles locaux). Couverture cartes : assemblage, tuiles de bord, proportions, coordonnées, absence de position, indisponibilité API/fond, nettoyage et réutilisation des textures, résolution des noms et ambiguïtés. Les tests utilisent des identifiants synthétiques, pas une preuve de présence des cartes réelles.

Installation : sept fichiers copiés et vérifiés par empreinte dans le client, avec sauvegarde sous dist/client-backups/game-maps-*. Validation visuelle de cette nouvelle version dans le client : en attente du `/reload` utilisateur et d'une capture. Nouveau parcours UIForever non exécuté pour cette tranche ; les captures précédentes illustrent l'ancien fond et ne valident pas les cartes natives. La capture automatique du client avait échoué lors des essais précédents. Recharger, ouvrir `/srdemo`, sélectionner Mornecroc puis une cible sans coordonnées et vérifier carte/lieu/marqueur et absence d'erreur Lua.

## Premier retour du client réel — correction SetFont

Client installé identifié par les métadonnées Wow.exe : 1.60.1.70790. Capture fournie par l'utilisateur après `/srdemo` : en-tête, textures et onglets visibles, puis erreur `UI/Window.lua:44: bad argument #3 to 'SetFont'`. L'ouverture complète échoue ; ce retour ne constitue donc pas une validation du client. La capture automatique du jeu reste indisponible.

Cause : `EditBox:SetFont(fontFile, height, flags)` requiert le troisième argument sur Forever. La déclaration épinglée `Blizzard_APIDocumentationGenerated/SimpleEditBoxAPIDocumentation.lua` marque flags non nullable. Le simulateur et le double de test acceptaient à tort son omission. Le champ de recherche fournit maintenant `""` ; le helper FontString utilise aussi explicitement cette valeur.

Vérification : double renforcé sur EditBox, échec reproduit avant correction, puis 19 tests UI et 39 tests moteur passés. Les deux archives sont reconstruites. Window.lua et Widgets.lua sont copiés dans l'installation avec sauvegarde sous dist/client-backups et comparaison des empreintes. Étape restante : `/reload`, puis `/srdemo` dans le jeu et nouveau retour utilisateur ; le succès après correction n'est pas encore observé. Aucun réglage global du jeu n'est modifié par le correctif.

Demande : programmer directement l'interface Forever à partir du concept v3. Branche `codex/structure-syndicat-rouge`, base `c9aa7401aaa457e71e2034d023136b8ad061d348`.

## Livraison

`dist/SyndicatRouge-forever-0.4.0-dev.zip` : un dossier SyndicatRouge, TOC, moteur, UI, police sous OFL et textures TGA RGB24 non compressées. Pas d'exemples enregistrés, de relais, de secrets ou de dépendance Node/Python dans le paquet.

`dist/SyndicatRouge-forever-0.4.0-dev-avec-demo.zip` : même addon plus SyndicatRougeDemo. Les huit incidents et trois vengeances proviennent de `demo/src/scenario.js`, générés uniquement dans cette extension séparée. `/srdemo` ouvre le registre fictif en mémoire ; recharger le réinitialise. Le compagnon tente aussi une ouverture sur PLAYER_LOGIN, mais le test observé utilise explicitement `/srdemo`.

Le paquet principal ouvre un registre vide avec `/sr` ou `/syndicat`. Cette tranche n'ajoute pas de SavedVariables ni de fournisseur de données réelles. Les états lu/remercié sont locaux à la session. Le point d'injection accepte un fournisseur View/Read/Thank pour la suite ; il ne constitue pas un transport de guilde.

## Tests locaux

- `node tools/test-lua.mjs` : 39 tests du moteur existant passés.
- `node tools/test-native.mjs` : 18 contrôles passés sous Fengari, en chargeant l'ordre réel du TOC et un double des widgets. Recherche littérale, échappement du texte WoW, sélection, état vide, identité des notifications, classement filtré, remerciement, fermeture, réutilisation des cadres, réinitialisation des dossiers et séparation de la démo. Ce double ne prouve pas le rendu ni la sécurité du client.
- `tools/package-native.py` : fichiers du TOC présents, extensions permises, licence et séparation du compagnon contrôlées. Conversion des textures vérifiée par Pillow : dimensions puissances de deux, mode RGB.

## Vérification UIForever

URL https://uiforever.com/app?flavor=forever ; navigateur intégré de Codex. Build affiché : **1.60.1.70450**, interface **16001**. Source API utilisée : Gethe/wow-ui-source commit **eac30af597e5aaa43a60f6675ef5fdcea100375f**, version **1.60.1.70790**. Ces builds sont distincts. Interface à confirmer par GetBuildInfo dans le client réel avant diffusion stable.

Import frais des deux addons, sans WTF personnel ; deux imports puis /reload. Scénario Solo. Résolutions observées : 2560×1440 / échelle 0,64, puis 1920×1080 / échelle effective affichée environ 0,71 et vue Fit plein écran. Le panneau Developer a conservé la résolution du chargement initial jusqu'au rechargement ; ne pas la confondre avec les dimensions de la vue courante.

Observations :

- `/srdemo` affiche les données du vrai moteur Lua dans des widgets natifs.
- Clics Recherchés, Vengeurs, Journal, Notifications : panneaux et détails changent.
- Clic Remercier : texte « Remerciement enregistré » dans la liste et le bouton ; aucune livraison à un tiers.
- Diagnostics consultés : « No Lua errors. » ; Missing APIs ne présente aucune entrée lors de l'inspection.
- Carte initialement coupée : dimensions et emplacement corrigés. Le second import a révélé un chevauchement portrait/lieu ; portrait ramené à 100×100 et statut remonté à y=170. Ces deux derniers réglages ont été appliqués dans la console Lua visible pour comparer le rendu, puis conservés à l'identique dans les sources et l'archive reconstruite. L'archive finale reconstruite n'a pas subi un troisième import complet ; les 18 tests locaux passent après correction.
- L'import de ZIP a été anormalement lent dans l'outil navigateur. Aucun contournement du navigateur, rapport support, publication de configuration ou import de données personnelles effectué.

Captures locales ignorées par Git : `docs/testing/screenshots/native-wanted.png` (rendu corrigé), `native-journal.png`, `native-notifications.png` (remerciement confirmé). Elles sont issues du rendu, pas de la maquette.

## Comparaison au concept et limites visibles

Composition conservée : liste environ un tiers, dossier deux tiers ; parchemin, cuir, foulard rouge, emblème, noms manuscrits, réputation, dernier incident et carte. Les textes et contrôles sont vivants, pas une capture de maquette servant d'interface.

Finition non terminée : onglets rectangulaires et typographie du titre simplifiés ; statut [ VENGÉ ] textuel, tampon usé illustré encore à produire ; portrait conceptuel de Mornecroc seulement dans la démonstration, autres portraits à compléter ; Vengeurs n'a pas encore les portraits du concept. Carte fictive et croix fixe explicitement indiquées comme illustratives : aucune correspondance géographique avec les coordonnées des incidents. Portraits réels et carte native attendent leur adaptateur Forever.

Recherche et défilement testés dans le double de widgets ; pas de parcours visuel complet du clavier, de la molette, du déplacement de fenêtre ou de l'échappement dans le simulateur. Dungeon/Raid, combat, taint, réel accès aux API, affichage sur plaques, sauvegarde et synchronisation à deux clients : non exécutés. Cette tranche ne certifie pas la compatibilité en jeu.

## Reproduire sans jeu

1. Exécuter `node tools/prepare-native.mjs`, `node tools/test-native.mjs`, puis `python tools/package-native.py`.
2. Dans UIForever Forever, ADDONS → Choose ZIP → archive avec démo → Import → /reload.
3. Dans Lua Console, `/srdemo`. Comparer les quatre onglets et le bouton Remercier. Le bandeau doit indiquer DÉMONSTRATION.
4. Contrôler Errors/Missing APIs et le build Developer. Pour un état vide, désactiver uniquement SyndicatRougeDemo, recharger puis `/syndicat`.

Les dépendances Lua natives se limitent aux cadres propres à l'addon ; aucun appel de combat, action protégée ou connexion extérieure ajouté. Le TOC est exclusivement préparé pour Forever, sans détection Retail de secours.
