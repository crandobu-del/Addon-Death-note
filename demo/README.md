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

Le cadre supérieur et les portraits proviennent des images de concept générées pour le projet ; les contenus, onglets et contrôles sont dynamiques. Les portraits sont génériques, pas des captures de personnages réels. La carte reste illustrative et montre un lieu passé du scénario.

Ce livrable est un aperçu fonctionnel hors jeu, pas un paquet installable WoW. La reproduction exacte des textures, la conversion en ressources du client et le rendu Lua natif restent à développer.
