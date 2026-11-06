# Boutons et ascenseurs — 0.5.4-dev

5 novembre 2026, demande explicite : reprendre l'interface dans la charte graphique et se concentrer sur les boutons et les ascenseurs. Disposition et direction déjà acceptées ; pas de nouvelle demande de maquette. Cible Forever seulement, source API inchangée `eac30af597e5aaa43a60f6675ef5fdcea100375f`, client utilisateur 1.60.1.70790 / interface 16001.

## Référence et réalisation

Référence inspectée : capture utilisateur `codex-clipboard-50c43ca2-eb8e-4a78-88e0-1e55f165d337.png`, 1259×981 : registre parchemin, cuir sombre, bronze et rouge, deux colonnes. La disposition 1080×720 unités reste la référence ; le titre actuel reste Tableau des primes. Les boutons plats et minuscules flèches textuelles sont remplacés, sans modifier les règles de primes, les données ou le réseau.

| Élément | Réalisation |
|---|---|
| Boutons d'action | Grain de cuir du Register.tga existant, UV .24–.75 / .915–.963, bords bronze/dark brown, filet de lumière, ombre et coutures discrètes ; texte centré |
| Remercier | Accent bordeaux pour l'action principale, mêmes états et dimensions que le bouton secondaire |
| Onglets | Même peau, rouge et soulignement persistants pour l'onglet actif, état de survol distinct ; retrait du préfixe puce au profit de la sélection visuelle |
| Fermeture / flèches | Croix et chevrons dessinés avec deux lignes natives ; pas de caractère coupé dans une étiquette trop étroite |
| Lignes de dossiers | Texture parchemin du même Register.tga, UV .26–.72 / .36–.63 ; bord léger, survol et marque rouge de sélection |
| Ascenseurs | Rail de cuir/bronze, Slider natif vertical avec curseur proportionnel et trois traits de prise, flèches de 20×22 ; mêmes coordonnées pour molette, flèches et curseur |
| Contenu sans débordement | Curseur caché et flèches désactivées ; retour au début et plage recalculée après réduction du contenu/recherche |

Les textures sont des régions natives, avec l'art déjà livré derrière elles. Aucune génération d'image, aucune modification des cartes/portraits et aucun nouvel asset tiers. Les géométries restent interactives, texte et données ne sont pas peints dans une image. Les objets sont créés une fois et recolorés selon normal/survol/appui/sélection/désactivation ; aucune allocation de cadres au survol.

## Contrats vérifiés

Documents générés au pin ci-dessus : SimpleSliderAPI (SetOrientation, SetMinMaxValues, SetValue, SetValueStep, SetObeyStepOnDrag, SetThumbTexture, SetEnabled), SimpleScrollFrameAPI (UpdateScrollChildRect), SimpleFrameAPI (CreateLine), SimpleLineAPI (SetStartPoint, SetEndPoint, SetThickness). Régions et valeurs sont celles des contrôles de l'addon ; pas d'action de combat ou de donnée protégée ajoutée.

Premier rendu : une rotation des coordonnées d'une texture unie ne dessine pas une diagonale ; corrigé par de vraies lignes pour les glyphes. Un test du journal a aussi révélé que la plage du curseur restait à 1 malgré 391 unités de débordement dans le simulateur. Correction : UpdateScrollChildRect et mise à jour explicite des deux barres à la fin du rendu, y compris l'état vide. Le contrôle ultérieur établit **240 / 391** après SetValue(240).

## Validation

`node tools/test-native.mjs` : **202 contrôles/scénarios**, dont quatre nouveaux contrôles de widgets : molette/curseur/flèches bornés, retour à zéro quand le contenu rétrécit, état sélectionné et désactivé, recalcul de plage lors du rendu/recherche. Les trois parcours de livraison entre VM passent toujours (historique, régional et jeu de test isolé).

UIForever disponible le 5 novembre, Forever **1.60.1.70450 / interface 16001**, distinct du client 70790 et du pin source. Import du ZIP principal + compagnon, pas de WTF personnel importé ; Solo, sélection 1920×1080, échelle UI affichée .71, vue Fit puis plein écran. `/srdemo` et appels explicites des callbacks des onglets/Marquer comme lu et du survol, via la console Lua de ce simulateur ; curseur testé via SetValue. Le glissement réel au pointeur et le maintien du clic en jeu ne sont pas certifiés par ces appels.

Rendu Notifications inspecté : textes des deux boutons dans leurs bornes, bouton principal bordeaux, onglet actif cohérent, croix lisible, rail sans faux curseur quand tout tient. Journal inspecté à 240/391 : curseur visible et proportionnel, chevrons, dossiers défilés et onglet actif. Panneau Errors : **No Lua errors**. Missing APIs : tableau vide après le parcours final. Les cartes de Strangleronce affichaient un damier dans ce simulateur sur un aperçu précédent ; aucun changement de carte effectué, son affichage réel avait déjà été validé par l'utilisateur. La preuve finale Notifications/Journal évite de confondre ce manque du simulateur avec le travail sur les contrôles.

Captures non retouchées :

- `docs/testing/screenshots/buttons-notifications-final-054.jpg` — rendu final Notifications.
- `docs/testing/screenshots/buttons-scrollbar-054.jpg` — Journal, défilement 240/391.

Capture intermédiaire `buttons-notifications-054.jpg` conservée séparément. Aperçus ZIP de travail conservés sous suffixes preview1/preview2, non livrés comme versions finales. Pas de nouvelle comparaison visuelle dans le client réel ; à vérifier après `/reload` puis `/sr`, ou `/srtest debut` pour reprendre le scénario existant.

## Livraison

Principal installé : **33 fichiers**, empreintes comparées à la source, sauvegarde `dist/client-backups/guild-transport-20261105-234530`. Aucun WTF modifié extérieurement. Le compagnon déjà installé reste utilisable.

Archives finales vérifiées entrée par entrée :

- `dist/SyndicatRouge-forever-0.5.4-dev.zip` — SHA256 `694748259de938668bb3d9365d5127fc51a45167c89435bd83eef66dd8f71b0a`.
- `dist/SyndicatRouge-forever-0.5.4-dev-avec-demo.zip` — SHA256 `f003c89433fbd57238a80d67bdae5818bb6461f95b74a3b05e6f2c00329a7c1c`.

Pas de publication GitHub/CurseForge effectuée ; les archives publiques antérieures sont inchangées. Le changement de version ne change ni les scopes ni les préfixes de partage et de test.
