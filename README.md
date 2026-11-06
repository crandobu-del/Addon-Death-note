# Tableau des primes — Le Syndicat Rouge

Nom affiché demandé le 5 novembre 2026. Les dossiers `SyndicatRouge`, les commandes et les sauvegardes gardent leurs identifiants internes. Les anciennes publications gardent leur historique ; la version 0.5.1 inclut le nouveau nom, le bouton de minicarte et le correctif de carte Arathi.

Projet d'addon de guilde pour **WoW Forever uniquement** : joueurs recherchés, incidents, vengeances, réputation, classement, notifications et relais Discord optionnel.

Version **0.7.0-dev** : collecte automatique prudente des morts PvP, rapports personnels/partagés, attribution explicite et rattrapage progressif auprès de deux sources de guilde au maximum. La collecte repose sur les données publiques réellement accessibles ; un récapitulatif protégé ou une identité incomplète ne donne pas lieu à une accusation inventée. [Fonctionnement, compatibilité et essais](docs/testing/pvp-reports-070.md).

Dans `/sr`, **Rapports** règle la collecte, le partage, les fins PvE/chute (ignorer par défaut, estimation seule en option), la conservation et les plafonds. **Synchroniser** active/reprend le transport et tente un envoi depuis le clic si nécessaire. Les rapports apparaissent dans Journal ; un rapport relayé n'alimente les primes qu'après confirmation de la victime, et une estimation ne crée aucune prime. Les duels, BG et arènes sont exclus. Les réglages et anciens registres sont conservés.

Tous les membres doivent installer **0.7.0** : le protocole natif utilise un nouveau préfixe. Portée : membres vérifiés du Syndicat Rouge effectivement joignables via **GUILD**, sans garantie inter-faction/inter-royaume ni diffusion universelle/instantanée. Aucun canal personnalisé ou relais externe. La preuve et le crédit des **vengeances réelles** restent à valider ; cette collecte ne valide pas un kill ennemi. Aucun service Discord actif.

Les archives 0.7.0 sont préparées ; leur publication est suivie dans [le registre de livraison](docs/releasing.md). Les préversions ne constituent pas une certification en jeu.
## Gank répété, présence et accès de guilde

Le bonus est calculé séparément pour chaque victime, sur les incidents ouverts ; son pic est conservé jusqu’à clôture. Les récompenses historiques ne sont pas réécrites. L’alerte de présence exige une cible réellement observée et identifiable, une prime ouverte et le partage actif. Elle indique la zone de l’observateur ; déduplication cinq minutes, pas de radar. La notification reste dans l’addon si le chat est refusé. `/srpresence` donne le bilan.

Sans mort réelle : chacun fait `/srtest debut`, un seul membre `/srtest gank`, puis son ami `/srtest venger traqueur` : six incidents et 24 réputation de test. `/srtest fin` rétablit le registre réel. Les identités de guilde temporairement indisponibles ferment l’accès jusqu’à vérification, sans effacer les sauvegardes.

## Marques des recherchés sur les plaques

`/srmarque apercu` présente la vignette locale, sans données réelles. Pour essayer sur un ami : activer ses plaques amies dans le jeu, `/srtest debut`, puis `/srmarque essai Prénom Nom` avec le nom complet d'un autre membre vérifié. Marqueur clairement TEST, soixante secondes, sans prime ni point ; `/srtest fin` revient au mode normal. `/srmarque` affiche le bilan, `activer`/`arreter` enregistrent la préférence si le profil est modifiable.

Les marqueurs automatiques exigent un joueur publiquement identifiable et une prime réelle ouverte correspondante. Pas de lecture de nom protégé, pas de marqueur de raid global ; création/ancrage différés en combat. L'aperçu est vérifié dans le simulateur ; l'ancrage réel et le comportement en PvP sont encore à tester. [Guide détaillé](docs/testing/wanted-nameplates.md).

## Jeu de données fictives pour tout tester

Sur les deux clients à jour (0.7.0) : `/reload`, puis `/srtest debut`. Un seul joueur charge `/srtest charger` après reconnaissance de l'ami. Cinq incidents, quatre recherchés, commandes de vengeances simulées, notifications et mercis dans un registre de test avec préfixe réseau distinct ; aucun point réel modifié. `/srtest fin` revient au registre normal. Après un reload, `/srtest debut` reprend le test sauvegardé. [Procédure et résultats attendus](docs/testing/jeu-de-test.md), [JSON de référence](test-data/primes-partage-v1.json). Le scénario partagé n'est pas encore validé en jeu ; il ne valide pas la détection automatique de kills.

## Installer l'addon sur WoW Forever

Projet publié sous l’ancien nom : [Death Note - Guild Ledger sur CurseForge](https://www.curseforge.com/wow/addons/death-note-guild-ledger). La 0.5.6 Release est approuvée, vérifiée le 6 novembre 2026. La **0.6.0-dev** a été déposée en Release pour Forever 1.60.1 (fichier 9473302) et attend son traitement/approbation. Le canal Release ne retire pas les limites fonctionnelles du paquet de développement.

1. Télécharger [l'archive installable SyndicatRouge-forever-0.7.0-dev.zip](https://github.com/crandobu-del/Addon-Death-note/releases/download/v0.7.0-alpha.1/SyndicatRouge-forever-0.7.0-dev.zip). Pour essayer les exemples et diagnostics, choisir [l'archive avec compagnon](https://github.com/crandobu-del/Addon-Death-note/releases/download/v0.7.0-alpha.1/SyndicatRouge-forever-0.7.0-dev-avec-demo.zip). Les deux fichiers se trouvent dans les **Assets** de [la préversion GitHub](https://github.com/crandobu-del/Addon-Death-note/releases/tag/v0.7.0-alpha.1), sans attendre CurseForge. Les fichiers **Source code** sont les sources du dépôt et ne constituent pas directement le paquet à installer.
2. Fermer WoW si c'est la première installation. Lors d'une mise à jour, conserver une copie de l'ancien dossier de l'addon.
3. Extraire le dossier **SyndicatRouge** dans le dossier du client Forever : `World of Warcraft/_forever_/Interface/AddOns/`.
4. Vérifier que le fichier se trouve directement ici : `_forever_/Interface/AddOns/SyndicatRouge/SyndicatRouge.toc`. Éviter un dossier supplémentaire tel que `SyndicatRouge/SyndicatRouge/`.
5. Si l'archive avec exemples a été choisie, placer aussi **SyndicatRougeDemo** à côté de **SyndicatRouge** dans `AddOns/`.
6. Relancer le jeu, puis activer **Tableau des primes — Le Syndicat Rouge** dans la liste des addons de l'écran des personnages. Le compagnon de démonstration est facultatif.
7. En jeu, saisir `/sr` ou `/syndicat` pour ouvrir le registre. Après une mise à jour d'une installation déjà chargée, saisir `/reload`.

L'addon cible **Forever uniquement**, actuellement le client 1.60.1/interface 16001. Le partage est réservé à la guilde **Le Syndicat Rouge**. Le registre réel démarre vide ; installer l'addon ne crée pas automatiquement de prime à chaque mort dans cette version.

## Activer et vérifier le partage entre membres

Chaque membre doit installer la **même nouvelle version** de l'addon et être connecté dans la guilde.

1. Chacun saisit `/reload`, puis `/srsync activer`.
2. Un premier membre saisit `/srsync test`. L'autre doit recevoir « signal de partage reçu de … » ; l'émetteur doit recevoir « réception confirmée par … (test) ».
3. Refaire le test dans l'autre sens.
4. Saisir `/srsync` pour consulter l'état, les membres vus, les accusés reçus et les éventuels problèmes.

Le test échange uniquement un signal : aucun incident ni point fictif n'est ajouté. `/srsync actualiser` demande un rattrapage des données ; `/srsync reprendre` relance la connexion après un échec d'initialisation ; `/srsync arreter` désactive le partage en conservant son cache. L'activation est sauvegardée par personnage.

Si `restricted`, `send_code_11` ou une identité inaccessible est signalé, recopier ce résultat pour diagnostic : le partage respecte les restrictions de Forever. Le succès d'un envoi ne prouve pas sa réception ; attendre l'accusé de l'autre membre. [Périmètre, tests et limites du partage](docs/testing/guild-transport.md).

## Commandes et sauvegarde

Un bouton **TP** à gauche de la minicarte ouvre et ferme **Tableau des primes** avec un clic gauche. Le survol indique le nom et l'action. Il utilise le même registre que `/sr`. Présent dans les sources et l'installation mises à jour ; les archives antérieures à cet ajout ne contiennent pas encore le bouton.

Dans **Notifications**, une vengeance acceptée déclenche une alerte et apparaît pour chaque victime concernée, y compris après rattrapage. Le bouton **Remercier** enregistre une demande volontaire puis affiche **En attente**. Lorsque le vengeur l'a reçue, l'état devient **Merci reçu** ; le vengeur voit le remerciement dans son propre onglet et peut le marquer comme lu. Les mercis ne rapportent aucun point supplémentaire.

L'envoi est repris après rechargement et retenté tant que la réception n'est pas confirmée. Les deux personnages doivent finir par être connectés ensemble, avec le partage actif et la version 0.5 installée. Un ancien merci enregistré uniquement localement propose **Envoyer le merci** : il ne part pas sans nouveau clic. Les messages ciblés passent par le canal technique GUILD ; ils ne sont pas privés vis-à-vis des autres clients de guilde. [Livraison, tests et limites](docs/testing/notification-delivery.md).

| Commande | Fonction |
|---|---|
| `/sr` ou `/syndicat` | Ouvrir/fermer le vrai registre ; quitter la démonstration |
| `/srsave` | Vérifier et préparer la sauvegarde locale |
| `/srsync` | Afficher l'état du partage et ses sous-commandes |
| `/srsync diagnostic` | Afficher la version et les étapes de reconnaissance du personnage, sans révéler de nom ni royaume |
| `/srdemo` | Ouvrir les exemples, uniquement avec le compagnon installé |
| `/srkill debut`, `/srkill bilan`, `/srkill fin` | Diagnostic optionnel de preuve de kill, avec le compagnon de diagnostic récent ; aucun point attribué |

WoW écrit les sauvegardes au rechargement, à la déconnexion ou à la fermeture normale. Les réglages de fenêtre, le registre personnel et le cache partagé sont conservés par personnage. Les exemples restent séparés et ne sont jamais partagés. Pour mettre à jour, remplacer les fichiers de l'addon en conservant les sauvegardes dans `WTF/` ; ne pas supprimer ce dossier.

Si `/sr` ne répond pas, vérifier d'abord le chemin du TOC, l'activation de l'addon et l'utilisation du client `_forever_`. Fermer et relancer complètement le jeu après une première installation. En cas d'erreur Lua, conserver son texte exact pour le diagnostic.

## Interface native Forever

Voir [le guide et les résultats de test](docs/testing/native-ui.md). Le paquet principal ouvre un registre personnel sauvegardé par personnage, ou le cache de guilde lorsque le partage est activé. La collecte réelle reste à connecter au transport et à valider en jeu.

La sauvegarde conserve le registre validé, les notifications et les préférences de fenêtre ; la réputation est recalculée à la restauration. `/srsave` affiche l'état et prépare un checkpoint ; WoW écrit les données au rechargement/déconnexion. Le test réel confirme la position et l'onglet après `/reload`. Les tests de reconnexion et de redémarrage après modification restent différés. [Résultats et protection des données existantes](docs/testing/persistence.md).

```text
node tools/prepare-native.mjs
node tools/test-native.mjs
python tools/package-native.py
```

Les textures TGA et la police manuscrite libre sont incluses. Les sources graphiques et leur conversion reproductible sont documentées dans `addon/SyndicatRouge/Media/ASSETS.txt`. L'archive avec démonstration peut être importée dans UIForever sans posséder le jeu.

Le compagnon fournit `/sraudit lancer` pour inventorier les zones du client et contrôler le chargement de leurs fonds, puis `/sraudit` pour la galerie de vérification manuelle. Le premier bilan transmis en jeu est de **50 fonds chargés sur 50, sans anomalie technique** ; ce n'est pas une validation visuelle de chaque carte. [Résultats, limites et conservation du rapport](docs/testing/all-zone-maps.md).

`/srpvp debut` lance la première vérification des capacités de mort/combat du client, `/srpvp` affiche le bilan et `/srpvp fin` l'arrête. Le retour réel confirme un journal restreint ; aucune identification automatique fiable du tueur n'est encore établie. Le diagnostic ne lit pas de données protégées et ne crée aucune prime. [Contrats et résultats](docs/testing/pvp-capabilities.md).

La piste du message personnel « Vous avez été tué par… » dispose d'un test distinct : `/srchat debut`, puis `/srchat bilan` après une occurrence normale et avant de recharger. `/srchat fin` arrête l'écoute. Aucun nom ou texte de chat sauvegardé ; [réception réelle encore à vérifier](docs/testing/death-chat.md).

## Essayer sans WoW

Voir [le guide de démonstration](demo/README.md). L'aperçu compilé s'ouvre directement dans un navigateur, sans serveur et sans accès au jeu.

```text
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm build:demo
pnpm demo
```

Le moteur Lua calcule les incidents, primes, vengeances, réputation, classement et notifications. Les tests navigateur couvrent les quatre onglets, la simulation d'une vengeance, les remerciements et la sauvegarde locale. [Résultats et limites](docs/testing/offline-core.md).

La version 0.2.0 ajoute un atelier **Tester le partage de guilde** : deux registres simulés, rattrapage après déconnexion, doublons et revendications contradictoires mises en attente. Le protocole est testé hors jeu ; le transport réel Forever reste à implémenter. [Tests de partage](docs/testing/offline-sync.md).

La version 0.3.0 ajoute **Aperçu Discord**, un export fictif et un [relais Python optionnel](bridge/README.md) : validation des données, file persistante, catégories, regroupement, doublons, corrections et gestion des confirmations incertaines. La configuration est désactivée ; aucun message réel envoyé. Le branchement à un export réel Forever reste à développer. [Tests Discord](docs/testing/offline-discord.md).

- [Arborescence et architecture prévues](docs/architecture.md)
- [Besoins du projet](docs/plans/death-note/requirements.md)
- [Suivi de réalisation](docs/plans/death-note/implementation-matrix.md)
- [Identité visuelle](docs/plans/death-note/identite-syndicat-rouge.md)
- [Autres onglets](docs/plans/death-note/onglets-maquettes.md)

Le code Lua est sous `addon/SyndicatRouge/`, l'aperçu sous `demo/`, le futur relais extérieur au jeu sous `bridge/`, les tests sous `tests/` et les archives générées sous `dist/`.

Les fichiers `.gitkeep` conservent les dossiers réservés au développement. `dist/` sera créé lors de la préparation des archives et reste exclu des sources. La licence MIT du dépôt est conservée.
