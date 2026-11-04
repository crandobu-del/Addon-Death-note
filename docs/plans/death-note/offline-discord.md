# Troisième tranche — relais Discord hors jeu

Autorisation : « ok la suite », après le partage simulé. Aucune autorisation d'envoyer un message réel à Discord n'est déduite de cette demande. Développer et tester avec un transport factice ; conserver le réseau réel désactivé dans la configuration d'exemple.

## Périmètre

Export JSON versionné à partir des faits partagés du moteur Lua ; lecture stricte de JSON dans un relais Python sans exécution de Lua ou de SavedVariables. File SQLite persistante, événements dédupliqués, catégories configurables, aperçu des annonces et client webhook activable explicitement plus tard. Aucun webhook ni bot créé, aucun secret demandé dans le chat.

## Politique de publication

- Exporter tous les incidents et toutes les revendications, y compris en conflit, pour que le relais reconstitue les contradictions observées.
- Une seule file configurée par guilde et mode (démo ou réel). Le relais conserve l'union des faits ; une copie plus ancienne ne peut pas effacer un conflit découvert.
- Nouvelle cible : annonce regroupée de son niveau actuel de prime ; nouvelles attaques : mise à jour regroupée tant que l'annonce est encore en attente.
- Vengeance : uniquement les revendications sans chevauchement ; annuler une annonce non envoyée si elle devient contestée.
- Si une vengeance déjà annoncée devient contestée, préparer une correction. Une correction d'un message effectivement publié reste nécessaire même si les autres catégories sont ensuite désactivées.
- Les décisions de débit dépendent des réponses Discord, pas d'une limite fixe supposée.
- Délai, erreur réseau ou réponse indéterminée : état « incertain », sans réessai aveugle. Un opérateur devra vérifier avant de déclarer livré, annuler ou autoriser un réessai.
- Un verrou logique de file empêche import et envoi simultanés ; après arrêt brutal, récupération manuelle des envois interrompus en « incertain ».

## Commandes prévues

`preview` : prévisualisation en mémoire, sans réseau ni fichier d'état.
`enqueue` : import atomique dans une file locale.
`status` : inspection de la file.
`send` : nécessite configuration activée, export non fictif et webhook dans une variable d'environnement ; non exécuté sur Discord pendant cette tranche.
`recover` et `resolve` : récupération et traitement explicite des résultats incertains.

## Tests

Export Lua sans données personnelles, format/version/guilde/mode, limites et conflits de faits, catégories désactivées, doublons, regroupement de primes, vengeance contestée avant et après annonce, réponse confirmée, 429, 4xx, 5xx/timeout, récupération après arrêt, envois concurrents refusés, mentions bloquées, URL webhook contrôlée et absence de secret dans les diagnostics. Vérifier également l'aperçu navigateur et les parcours existants.

La disponibilité et la cadence d'un véritable export depuis Forever restent inconnues ; cette tranche ne promet pas de notifications en temps réel.
