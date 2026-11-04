# Vérification du relais Discord — 0.3.0

## Exécution

Le relais est testé avec des réponses et transports factices : aucun webhook configuré, aucune requête réelle envoyée à Discord. `WebhookTransport` est vérifié par injection d'un faux opener HTTP, et la file SQLite est testée en mémoire et dans des dossiers temporaires.

## Couverture

- Lua : 39 scénarios au total (16 socle, 18 partage, 5 export). L'exporteur actuel marque toujours ses données comme fictives et n'inclut pas les préférences, lectures, remerciements ou secrets.
- Python : 35 tests passés. Validation JSON stricte et bornée, aucune exécution Lua ; versions/cibles, références des revendications, doublons et conflit de faits ; séparation de guilde et de mode ; catégories désactivées ; annonces regroupées ; annulation d'une vengeance contestée avant envoi et correction après envoi confirmé ; réponse incertaine, résolution explicite, récupération après arrêt, exclusion mutuelle ; 429/délai serveur, rejet 4xx, 5xx/timeout, pause si quota inconnu ; URL limitée à Discord HTTPS et redirections refusées ; mentions neutralisées et erreurs sans secret.
- Navigateur : exemples issus du formateur Python, filtres de catégories, affichage compact/déplié, téléchargement d'un export fictif, bureau 1180 px et mobile 360 px, ouverture directe de `discord.html`. Aucun débordement horizontal, aucune exception JavaScript, aucune requête extérieure aux ressources locales.
- Les parcours existants du registre et du partage ont également passé les vérifications après compilation de la livraison.

## Interface et ressources

Captures réelles produites et inspectées dans `docs/testing/screenshots/discord-desktop.png` et `discord-mobile.png` (exclues de Git). Le cadre reprend l'identité du Syndicat Rouge ; les exemples de messages utilisent une présentation sombre proche d'un salon, avec un état explicite d'aperçu non connecté. Les filtres n'activent pas le relais. Les exemples sont indépendants du scénario sauvegardé du registre ; ce point est indiqué à l'écran.

Les exemples de messages sont générés par `tools/generate-discord-preview.py` à partir d'un export créé par le moteur Lua réel. Le supplément « prime augmentée » provient de deux imports successifs dans une file en mémoire, sans confirmation réseau fabriquée. Le test Python compare les messages de base au formateur courant pour repérer une fixture périmée.

## Résultats non revendiqués

Pas d'essai sur un vrai salon, pas de création de webhook, pas de bot, pas de surveillance permanente, pas de tâche planifiée. Aucun mécanisme d'export réel ou de délai en temps réel depuis Forever n'a été vérifié. L'existence d'un client HTTP n'est pas une validation de l'export du jeu. La publication exactement une fois n'est pas garantie en cas de perte de confirmation ; ces cas sont mis en attente d'une décision humaine.

Les corrections ne peuvent partir qu'après confirmation que l'annonce initiale a été publiée. Un conflit découvert via une copie plus récente n'est pas effacé par la réception d'une copie ancienne. La vérité des observations de combat et l'identité du membre émetteur restent des responsabilités de l'intégration Forever à venir.

Références de comportement consultées : [exécution des webhooks et confirmation `wait`](https://docs.discord.com/developers/resources/webhook), [429, Retry-After et en-têtes de quota](https://docs.discord.com/developers/topics/rate-limits).
