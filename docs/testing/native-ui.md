# Interface native 0.4.0-dev — résultats du 5 novembre 2026

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
