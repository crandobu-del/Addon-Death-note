# Sauvegarde personnelle Forever — 5 novembre 2026

## Livraison

`SyndicatRougeCharacterDB` est déclaré en SavedVariablesPerCharacter dans le TOC principal. Le registre est séparé par personnage et n'est pas stocké dans le compagnon. Conteneur `formatVersion=1`, scope `character-local`, ledger validé pour `local:forever`, préférences et compteur de révision.

Sont conservés : incidents, vengeances, états lu/remercié des notifications et onglet/ancrage de la fenêtre. La réputation, les récompenses et les clôtures sont reconstruites via Store.Restore à partir des faits validés. Aucun compteur de réputation fourni par la sauvegarde n'est utilisé comme autorité.

ADDON_LOADED ouvre le profil après chargement des variables. PLAYER_LOGOUT produit un checkpoint ; WoW réalise l'écriture du fichier lors du rechargement/déconnexion. Un changement d'onglet, la fin d'un déplacement ou la fermeture enregistrent les préférences en mémoire. `/srsave` force un checkpoint et affiche l'état ; cette commande ne prétend pas forcer immédiatement une écriture disque indépendante du cycle de WoW.

Une sauvegarde future, d'un scope différent ou invalide reste intacte, avec registre vide en lecture seule et avertissement. Un checkpoint invalide conserve le dernier ledger validé. Les réglages de fenêtre sont limités à des points d'ancrage connus et des coordonnées finies/bornées, relatifs à UIParent. Les coordonnées protégées ne sont pas inspectées.

`/sr` et `/syndicat` ouvrent le registre personnel. `/srdemo` reste explicite ; il ne s'ouvre plus tout seul au login. Incidents, réputation, notifications et réglages de démonstration ne remplacent jamais le profil réel. `/sr` permet de quitter la vue de démo et de retrouver les réglages réels. Aucun fixture ajouté au paquet de production.

Le registre personnel est actuellement vide faute de collecte et de fournisseur d'identité réels. Le stockage des incidents et notifications est prêt/testé, mais cela ne constitue pas encore leur livraison en jeu. Le scope personnel ne sera pas diffusé comme s'il identifiait une guilde réelle ; un branchement/migration explicite reste requis pour la synchronisation.

## Tests locaux

- 24 contrôles dédiés au profil : nouveau/restauré, incidents, clôture, réputation recalculée, lu/remercié, réglages, invalidité runtime, conservation du dernier état valide, version future, profil corrompu, scope, préférences invalides, isolation de personnage, séparation de démo, retour à la vue réelle et événement logout.
- 4 scénarios avec nouvelles machines Lua : initialisation et checkpoint de faits synthétiques, nouvelle VM chargeant le profil sérialisé et la fenêtre, profil futur non modifié malgré sauvegarde/logout, nouveau personnage vide.
- Ensemble : 170 contrôles/scénarios Lua passés, dont 39 tests du moteur. Les 4 VM simulent le cycle de chargement ; elles ne simulent pas l'écriture disque de WoW.
- Ordre du TOC vérifié et archives reconstruites. Cinq fichiers d'addon installés et vérifiés par empreinte ; anciens fichiers sauvegardés sous `dist/client-backups/persistence-*`. Aucun fichier WTF existant modifié par l'installateur.

## Résultat réel

L'utilisateur a redémarré le client pour charger la nouvelle déclaration, puis a confirmé que l'onglet Vengeurs et la position sont conservés après `/reload` et `/sr`.

Une première lecture du fichier du moteur montre formatVersion=1, scope personnel, onglet=2, révision=3, registre vide ; l'ancrage est encore CENTER, ce qui ne prouve pas un déplacement non nul. Un second contrôle ciblé a été demandé : déplacer la fenêtre vers la gauche, `/srsave`, `/reload`, `/sr`. L'utilisateur confirme qu'elle reste à gauche. Le fichier relu contient TOPLEFT relatif à TOPLEFT, x≈96, y≈−63, onglet=2 et révision=9. Cette lecture confirme l'écriture des réglages par WoW ; la restauration visuelle est attestée par l'utilisateur, pas par une capture automatique de l'agent.

Les fichiers sont lus comme texte uniquement, sans exécuter leur contenu dans un outil extérieur et sans copier de chemin d'identité de compte/personnage dans le dépôt.

| Vérification | Résultat |
|---|---|
| Écriture du profil par le moteur WoW | Observée dans le fichier réel |
| Onglet après /reload | Confirmé par l'utilisateur et fichier tab=2 |
| Ancrage non central après /reload | Confirmé par l'utilisateur et coordonnées non nulles dans le fichier |
| Incidents/réputation/notifications à travers une nouvelle VM | Passé sur faits synthétiques |
| Conservation de faits réels après /reload | Non exécutée : collecte non branchée, registre réel vide |
| Déconnexion/reconnexion après modification | Différée par l'utilisateur (« Je testerai plus tard ») |
| Fermeture/redémarrage complet après modification | Différée par l'utilisateur |
| Autre personnage réel | Non exécutée ; isolation déclarée au TOC et testée hors jeu |
| Rendu dans UIForever après cette tranche | Non exécuté ; pas de nouvelle disposition graphique |

Le redémarrage initial pour prendre en compte le TOC ne remplace pas le test d'un redémarrage effectué **après** les modifications de réglages. Les limites ci-dessus restent ouvertes.

## Reproduire les étapes différées

Avec `/sr`, choisir un onglet et déplacer la fenêtre. Déconnecter/reconnecter le personnage, rouvrir `/sr` et contrôler les deux réglages. Fermer/relancer complètement le jeu, puis contrôler `/sr` de nouveau. Les diagnostics temporaires, notamment `/srchat`, doivent être réactivés après un rechargement/redémarrage si l'on souhaite les poursuivre.

Client : Forever, Wow.exe identifié précédemment 1.60.1.70790 ; source épinglée eac30af597e5aaa43a60f6675ef5fdcea100375f. GetPoint est vérifié dans SimpleScriptRegionResizingAPIDocumentation.lua, avec son annotation SecretWhenAnchoringSecret. Aucun nouveau flux de données d'ennemi ou accès de combat ajouté.
