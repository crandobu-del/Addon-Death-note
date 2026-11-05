# Death Note — Le Syndicat Rouge

Projet d'addon de guilde pour **WoW Forever uniquement** : joueurs recherchés, incidents, vengeances, réputation, classement, notifications et relais Discord optionnel.

Version **0.4.0-dev — alpha** : interface native à quatre onglets, sauvegarde par personnage et transport de guilde implémentés. L'interface, les cartes et la conservation des réglages après `/reload` ont été observées sur Forever. Le partage à deux membres est en cours de validation ; l'identification automatique des meurtres et des vengeances reste à finaliser. Aucun service Discord actif.

## Installer l'addon sur WoW Forever

1. Récupérer `SyndicatRouge-forever-0.4.0-dev.zip`. Pour essayer les exemples, utiliser plutôt `SyndicatRouge-forever-0.4.0-dev-avec-demo.zip`. Les archives préparées se trouvent dans `dist/` ; ce dossier n'est pas versionné sur GitHub. L'archive du code source GitHub ne constitue pas directement le paquet à installer.
2. Fermer WoW si c'est la première installation. Lors d'une mise à jour, conserver une copie de l'ancien dossier de l'addon.
3. Extraire le dossier **SyndicatRouge** dans le dossier du client Forever : `World of Warcraft/_forever_/Interface/AddOns/`.
4. Vérifier que le fichier se trouve directement ici : `_forever_/Interface/AddOns/SyndicatRouge/SyndicatRouge.toc`. Éviter un dossier supplémentaire tel que `SyndicatRouge/SyndicatRouge/`.
5. Si l'archive avec exemples a été choisie, placer aussi **SyndicatRougeDemo** à côté de **SyndicatRouge** dans `AddOns/`.
6. Relancer le jeu, puis activer **DEATH NOTE — Le Syndicat Rouge** dans la liste des addons de l'écran des personnages. Le compagnon de démonstration est facultatif.
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

| Commande | Fonction |
|---|---|
| `/sr` ou `/syndicat` | Ouvrir/fermer le vrai registre ; quitter la démonstration |
| `/srsave` | Vérifier et préparer la sauvegarde locale |
| `/srsync` | Afficher l'état du partage et ses sous-commandes |
| `/srdemo` | Ouvrir les exemples, uniquement avec le compagnon installé |

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
