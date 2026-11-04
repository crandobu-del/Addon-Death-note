# Death Note — Le Syndicat Rouge

Projet d'addon de guilde pour **WoW Forever uniquement** : joueurs recherchés, incidents, vengeances, réputation, classement, notifications et relais Discord optionnel.

Le socle Lua, le protocole de partage logique et un aperçu interactif hors jeu sont développés. La démonstration utilise des données fictives et le même moteur de règles que les modules de l'addon. Aucun addon installable n'est encore livré et aucune connexion Discord n'est active.

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
