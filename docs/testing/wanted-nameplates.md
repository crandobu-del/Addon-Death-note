# Marques des recherchés — REQ-017 / IMP-012

6 novembre 2026. Tranche de préparation Forever uniquement, client observé précédemment 1.60.1.70790/interface 16001. Source conservée au pin `eac30af597e5aaa43a60f6675ef5fdcea100375f` pour correspondre à ce contrat ; aucun changement de cible ou de build réel déduit de la date.

## Plan de réalisation et critères

Direction acceptée du Syndicat Rouge : petit badge de cuir/bordeaux, bord bronze, emblème existant et texte RECHERCHÉ + récompense en réputation. Ancrage au-dessus de la plaque native, sans changer sa taille, ses clics ou les marqueurs de raid. Pas de nouvelle maquette demandée : cette tranche suit la disposition/charte et la proposition de marqueur déjà enregistrées.

1. Résoudre uniquement les identités publiques complètes de joueurs visibles. Même format régional que le partage ; aucun GUID PvP, prénom seul, texte de plaque décodé ou repli après valeur protégée.
2. Indexer les incidents réels encore ouverts du registre courant ; ignorer démonstrations et données du registre de test pour les marqueurs automatiques. Ne pas dépendre de l'onglet ouvert ni de `/srdemo`.
3. Pool borné de badges par plaque, évènements ajout/retrait/nom/caméra, contrôles d'accès et revalidation périodique. Ne jamais demander de plaque interdite. Création/ancrage seulement hors verrouillage de combat ; en combat un badge existant n'est montré que s'il reste non protégé et si l'identité exacte est publiquement relisible.
4. Retirer dès un retrait/réemploi de plaque, un nom non lisible, une identité différente, une cible derrière la caméra, la désactivation ou la clôture. Réactualisation du registre sur changements, avec contrôle périodique borné.
5. Préférences activer/arrêter, bilan sans noms, aperçu indépendant et essai de 60 secondes sur un autre membre vérifié uniquement quand `/srtest debut` est actif. Le test ne modifie ni les incidents ni la réputation et porte explicitement TEST.
6. Tests avec doubles : PNJ, identités régionales et classiques, secrets, homonymes, réemploi, clôture, parent interdit/protégé, création différée en combat, mode démo/test et sauvegardes. Capture du vrai rendu de l'aperçu dans UIForever ; présence et comportement sur de vraies plaques du client à faire vérifier séparément.

## Sources examinées

- `Blizzard_APIDocumentationGenerated/NamePlateDocumentation.lua` : `C_NamePlate.GetNamePlateForUnit(unitToken, includeForbidden=false)` ; GetNamePlates sans argument dans la déclaration générée. N'utiliser aucun argument permettant l'accès aux plaques interdites.
- `Blizzard_NamePlates/Blizzard_NamePlates.toc` : adaptations Camelot et bases communes effectivement chargées.
- `Blizzard_NamePlates/Blizzard_NamePlates.lua` : événements NAME_PLATE_UNIT_ADDED/REMOVED et distinction explicite des FORBIDDEN_ ; ne pas reprendre les accès secure/issecure du code Blizzard pour un addon tiers.
- `Blizzard_NamePlates/Blizzard_NamePlateBase.lua` : GetUnit renvoie le jeton courant ; les bases et UnitFrames sont réutilisés, donc toute association doit être revalidée.
- `Blizzard_NamePlates/Blizzard_NamePlateUnitFrame.lua` : événement NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED, nom de joueur et position du texte natif ; pas de lecture de la FontString du nom.
- `UnitDocumentation.lua` : UnitIsPlayer, UnitNameUnmodified/UnitFullName (SecretWhenUnitIdentityRestricted), RegionalUniqueNamesEnabled. Ne pas utiliser UnitGUID sur des jetons PvP ni chercher une autre source après protection.

Ces déclarations ne prouvent pas l'accessibilité dans le client réel. Les métadonnées, la présence, le rendu de l'aperçu et le fonctionnement sur une vraie plaque restent des résultats distincts.

## Réalisation 0.5.5-dev

`UI/WantedMarkers.lua` est chargé avant Bootstrap. Le module observe les événements de plaques normaux uniquement, conserve au plus 80 jetons/badges et revalide toutes les demi-secondes. Il ne remplace aucun script Blizzard et ne change aucun CVar, clic, taille de plaque ou symbole de raid. GetNamePlateForUnit est toujours appelé avec `false`, et GetNamePlates sans argument.

L'identité est résolue via UnitIsPlayer puis le mode régional public et les deux parties publiques du nom ; aucun autre chemin n'est tenté après une protection. Le badge exige une correspondance canonique exacte avec un ennemi d'incident réel encore ouvert. Les démonstrations et le registre partagé fictif n'alimentent jamais cet index. Ouvrir `/srdemo` ne change pas sa source de données. Les mises à jour du partage rafraîchissent également les badges, même quand le tableau est fermé.

Les enfants des plaques sont créés et ancrés hors verrouillage de combat, puis réutilisés sans reparentage. En combat, seuls les badges déjà préparés peuvent réapparaître, à condition que l'identité reste publique et que l'objet de l'addon ne soit ni interdit ni protégé. Une nouvelle plaque attend la sortie du combat. Si une identité n'est pas lisible, le marqueur est retiré ; la feature ne permet pas de récupérer cette identité autrement. Aucun fonctionnement universel en PvP/instance n'est promis avant essai réel.

Lors d'un réemploi d'une base, son badge est masqué **avant** la résolution du nouvel occupant, y compris si l'ancien événement de retrait manque. Le jeton fourni par GetUnit est revérifié contre l'événement courant. La clôture des incidents, le retrait et la caméra déclenchent un rafraîchissement ; les scans ne réinitialisent pas un état derrière la caméra. Les échecs de création sont mémorisés pour éviter une allocation répétée sur une plaque inaccessible.

Réglage local `wantedMarkers` dans le profil personnel : activé par défaut, persistant si le profil est modifiable, sinon changement de session uniquement. Aucun incident, GUID ou nouveau nom de joueur sauvegardé par le module. L'essai temporaire retient seulement l'identité publique explicitement demandée pendant sa durée.

## Commandes et contrôle sans mort PvP

1. `/reload`, puis `/srmarque apercu` : aperçu graphique local pendant vingt secondes, avec nom et barre fictifs, sans plaque de joueur réelle. Relancer la commande le masque.
2. Pour l'ancrage réel, hors combat et hors instance : activer les plaques de nom **amies dans les options du jeu**, se placer près d'un autre membre de la guilde, puis `/srtest debut` et `/srmarque essai Prénom Nom` avec son nom complet exact.
3. Son nom doit porter **TEST RECHERCHÉ / 3 réputation (test)** pendant soixante secondes sur ce client seulement. Aucune prime n'est ajoutée, aucun kill simulé et aucun point attribué par cette commande. L'ami n'a pas besoin d'activer le test de son côté pour cet essai local. Il doit avoir lui aussi le nouvel addon s'il veut voir ses propres marqueurs locaux.
4. `/srtest fin` termine également l'essai, au prochain rafraîchissement. Pour arrêter tous les marqueurs réels : `/srmarque arreter`. Réactiver : `/srmarque activer`.
5. `/srmarque` ou `/srmarque bilan` : compteurs de primes ouvertes, plaques suivies, marqueurs affichés et dernier état. Pas de nom/GUID imprimé par le bilan. Si rien n'apparaît, relever ce bilan ; ne pas modifier les valeurs protégées pour forcer l'affichage.

La préférence de marqueurs ne force jamais l'activation des plaques natives. Un marqueur est local à l'utilisateur équipé de l'addon, pas un symbole global visible par tous.

## Validation

`node tools/test-native.mjs` : **218 contrôles/scénarios**, dont 16 nouveaux tests d'identité, de cycle de vie et d'accès des marqueurs. Les trois parcours de partage/merci entre VM passent toujours. Cas couverts : noms régionaux complets, homonymes, PNJ, noms/mode/métadonnées protégés, absence de repli, réemploi sans retrait, clôture, parents interdits, badges protégés, création différée en combat, caméra et rescans, démonstration exclue, essai de guilde explicite et expirant, préférence et lecture seule, aperçu sans données, limites de pool. Ce sont des tests à API injectées, pas une observation du PvP réel.

UIForever **1.60.1.70450 / interface 16001**, Solo, résolution sélectionnée 1920×1080, échelle UI affichée .71. ZIP principal et compagnon importés ; pas de WTF personnel. L'aperçu a été exécuté via la console du simulateur ; Errors indiquait **No Lua errors**, Missing APIs avait un tableau vide sur ce parcours. La petite fenêtre du navigateur et le mode Fit réduisaient beaucoup la vignette ; inspection à **100 %** dans l'interface du simulateur. Un menu du jeu ouvert pendant la navigation a été fermé avant la capture finale.

Capture non retouchée de l'aperçu : `docs/testing/screenshots/wanted-marker-preview-final-055.jpg`. Vignette bordeaux/bronze et emblème existant, deux lignes lisibles : RECHERCHÉ / 3 réputation. Le nom fictif et la mention APERÇU LOCAL distinguent cette présentation de la plaque PNJ visible derrière dans la scène. Cette capture n'est pas une preuve d'ancrage sur une vraie plaque de joueur. Le fonctionnement sur un autre joueur, la portée, les différentes tailles de plaques, les autres addons de plaques, les changements en combat et le PvP restent à contrôler dans le client utilisateur.

## Livraison

Version **0.5.5-dev**, principal installé : **34 fichiers**, empreintes comparées, sauvegarde `dist/client-backups/guild-transport-20261106-004604`. Aucun WTF modifié extérieurement et aucun message envoyé à un service externe par cette feature. Les packages ont été vérifiés entrée par entrée :

Le FileVersion du Wow.exe installé a été relu pendant cette tranche : **1.60.1.70790**, identique au pin déjà sélectionné. Cela vérifie le binaire installé, pas une exécution du marqueur sur le personnage.

- `dist/SyndicatRouge-forever-0.5.5-dev.zip`, SHA256 `d5cce98a57530455a0eb5f0359d2b2326191d13cbfaee61ee31a49b0df7d58d5`.
- `dist/SyndicatRouge-forever-0.5.5-dev-avec-demo.zip`, SHA256 `19dd0132ca6e03e99f9ccfa3626e0e60cced3c0b2bed3b66f940b2b2946cf436`.

Pas de publication GitHub/CurseForge effectuée. Le compagnon déjà installé reste compatible et n'est pas nécessaire à l'aperçu ou à l'essai local du marqueur.

## Direction graphique actualisée — cible wanted 0.5.6-dev

Demande utilisateur : « Une cible genre wanted graphiquement ». Remplace la vignette rectangulaire avec emblème par un réticule de recherche : double cercle bronze/rouge, quatre traits de visée avec ombre et point rouge central. Le symbole domine le marqueur ; une petite étiquette de cuir de 106×27 garde RECHERCHÉ et la réputation, sous la cible. Ensemble 106×69 unités, ancré dix unités au-dessus de la plaque. En test, les mentions TEST et réputation (test) restent visibles. Pas de nouvelle image IA, de portrait ou de marqueur de raid ; géométrie en lignes natives (API déjà vérifiées à la tranche de boutons).

Ce changement ne touche ni l'identification, ni les règles d'accès, la création différée en combat, les données ou les conditions de disparition. `node tools/test-native.mjs` : **218 contrôles/scénarios**, dont 16 marqueurs, et trois parcours VM passent. Version principale/TOCs/générateurs 0.5.6-dev.

Installation locale initiale : 34 fichiers vérifiés, sauvegarde `dist/client-backups/guild-transport-20261106-010017`. Après correction des étiquettes, nouvelle installation vérifiée avec sauvegarde `dist/client-backups/guild-transport-20261106-014028`. Archives finales vérifiées :

- `dist/SyndicatRouge-forever-0.5.6-dev.zip`, SHA256 `508b008d88573b504ad198bb1495617a732844aa0eb0483fbcee3980b93312fa`.
- `dist/SyndicatRouge-forever-0.5.6-dev-avec-demo.zip`, SHA256 `bb7d6c588ff26de0a873ba1733e6ecd66ccfeede5e7bb54e1fd59756e9672d8b`.

L'import UIForever de l'aperçu initial a établi le rendu de la cible. Il a révélé une superposition : le cadre de fond de la petite étiquette masquait les FontStrings restées sur le parent. Correction source : création des deux textes sur le cadre de l'étiquette lui-même. Vérification dans l'instance déjà chargée en y recréant les FontStrings sur ce bon parent via la console, plutôt que de réimporter l'archive entière après un import excessivement lent. La capture n'est donc pas un second import frais du ZIP corrigé. Le rendu corrigé montre cible + RECHERCHÉ + 3 réputation ; capture native non retouchée `docs/testing/screenshots/wanted-target-complete-056.jpg`. Vue 100 %, Solo, même simulateur 70450 et mêmes paramètres que ci-dessus. Panneau Errors : No Lua errors lors du contrôle intermédiaire. Les captures et ZIPs intermédiaires sont conservés sous leurs noms de prévisualisation, sans remplacer les versions précédentes.

Les commandes d'aperçu et d'essai ne changent pas. Le fonctionnement sur une vraie plaque et en PvP reste une validation séparée, non établie par les tests de géométrie ou l'aperçu.
