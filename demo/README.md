# Aperçu hors jeu

Interface de développement utilisant les modules Lua réels via Fengari. Toutes les données et actions sont fictives. Pas d'accès au jeu, pas de message de guilde ni d'envoi Discord.

Depuis la racine du dépôt :

```text
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm build:demo
pnpm demo
```

Ouvrir http://127.0.0.1:8765. Le serveur écoute uniquement sur la machine locale. `demo/build/index.html` peut également être ouvert directement après compilation. Le répertoire généré contient les ressources locales ; aucun CDN requis.

Personnage de démonstration : Lÿra. Sélectionner Mornecroc, puis « Simuler une vengeance ». La simulation attribue la récompense à Kaëlan ; les notifications personnelles ne concernent que les victimes réellement incluses dans la clôture. Remercier reste un choix et ne publie aucun message.
Les préférences et l'état du scénario sont conservés dans le navigateur si son stockage est disponible. Un bouton permet de réinitialiser ce scénario ; la vraie sauvegarde WoW n'est pas testée.

## Tester deux membres

Depuis le registre, cliquer sur **Tester le partage de guilde**, ou ouvrir `demo/build/sync.html` après compilation. Cette deuxième page montre deux registres indépendants : celui de Lÿra et celui de Kaëlan.

1. Synchroniser pour transmettre le premier incident à Kaëlan.
2. Déconnecter un membre, simuler une attaque dans l'autre registre, puis reconnecter et synchroniser.
3. Simuler une vengeance chez un membre puis synchroniser : les deux voient le même classement.
4. Rejouer le dernier échange : aucun point supplémentaire.
5. Essayer un conflit : les deux revendications sur la même mort restent en attente, avec la réputation concernée suspendue.

Tout se déroule dans le navigateur. Cette page repart à zéro à l'ouverture ; elle n'envoie aucun message de guilde. Le rattrapage est borné à 128 incidents et 128 revendications. L'arbitrage des conflits et le vrai transport Forever ne sont pas livrés.

`python tools/package-demo.py` produit l'archive de démonstration version 0.2.0, à extraire avant d'ouvrir `index.html` ou `sync.html`.

## Exemples Discord

La livraison courante 0.3.0 inclut aussi `discord.html`, accessible par **Aperçu Discord** depuis la page principale. Afficher ou masquer les catégories ne change que cette prévisualisation. Les annonces proviennent du formateur du relais Python et d'un scénario fictif indépendant ; le bouton d'export télécharge ce scénario, pas l'état sauvegardé de ton registre.

Le relais reste non configuré et tous les exports actuels portent le mode fictif. Aucun message n'est envoyé. Pour régénérer ces exemples lors d'un développement : `node tools/export-discord-fixture.mjs`, puis `python tools/generate-discord-preview.py`, puis recompiler la démonstration.

`python tools/package-demo.py` produit désormais `dist/SyndicatRouge-demo-hors-jeu-0.3.0.zip`, avec les trois pages et leurs ressources locales.

Le cadre supérieur et les portraits proviennent des images de concept générées pour le projet ; les contenus, onglets et contrôles sont dynamiques. Les portraits sont génériques, pas des captures de personnages réels. La carte reste illustrative et montre un lieu passé du scénario.

Ce livrable est un aperçu fonctionnel hors jeu, pas un paquet installable WoW. La reproduction exacte des textures, la conversion en ressources du client et le rendu Lua natif restent à développer.
