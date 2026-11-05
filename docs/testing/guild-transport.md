# Partage natif Forever — 5 novembre 2026

Base : 2b4b56f2da7c8de2cc33efb99f4c32b91c549eac. Client installé : 1.60.1.70790, interface 16001, projet Camelot observé auparavant. Sources épinglées : [Gethe/wow-ui-source eac30af](https://github.com/Gethe/wow-ui-source/tree/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated).

## Livré

`Sync/Wire.lua` sérialise uniquement des données, limite taille/profondeur/nœuds et réassemble des fragments de 180 octets, isolés par expéditeur/transfert, pendant 300 secondes. Au maximum 4 transferts entrants, 2 par expéditeur, 128 Kio chacun ; paquets ≤240 octets. Aucune exécution de texte reçu.

`Sync/Context.lua` vérifie le projet, le club de guilde réel et son nom exact, puis les identités publiques via `UnitFullName` et `MemberExistsByName`. Refuse les identités masquées `|K`, valeurs secrètes et membres non reconnus. Le ClubId est transmis à l'API dans son type d'origine, sans conversion numérique risquant de perdre de la précision.

`Sync/Channel.lua` applique le protocole existant, fusionne atomiquement, conserve les revendications conflictuelles et sauvegarde les sessions sous `SyndicatRougeCharacterDB.guilds[guildId]`. Le registre personnel `ledger` reste distinct. Les notifications personnelles restent dans le cache local ; seuls incidents/revendications normalisés sont transmis. Les exemples `source=demo` sont refusés à la publication, à l'export et à la réception.

`Sync/Native.lua` propose activation explicite, préférence de démarrage, HELLO/rattrapage, accusés ciblés et signal de test. Tout passe par GUILD. Débit maximal d'environ 3,3 paquets/seconde ; queue ≤1500 paquets ; limites/throttles/restrictions traités séparément. Succès d'API = paquet soumis, pas preuve de réception ; seul un accusé corrélé compte. Changement de guilde/identité : purge et arrêt. `/sr` utilise le cache partagé quand le partage est actif ; lectures/remerciements sauvegardés localement.

## Vérifications automatisées

- `node tools/test-lua.mjs` : 54 tests dont 15 nouveaux pour codec, fragments, deux registres, rattrapage, récompenses, données privées, démo et cache invalide.
- `node tools/test-native.mjs` : 147 contrôles/scénarios dont 16 nouveaux sur API, enums 0/1, restriction, throttle, filtrage secret/canal, accusés, changement de guilde, arrêt, lecture seule et branchement du fournisseur partagé dans l'interface. Doubles injectés, pas un client de jeu.
- Paquets de production et avec démo préparés séparément. Nouvelle capture native non exécutée : outils de capture indisponibles pour WoW dans cette session.

## Essai réel à deux membres — à faire

Installation locale : 30 fichiers copiés, empreintes vérifiées, anciens fichiers conservés sous `dist/client-backups/guild-transport-20261105-171030`. L'utilisateur indique que le deuxième membre installe ; aucun résultat réseau réel communiqué.

1. Installer la même nouvelle version de `SyndicatRouge` pour les deux membres dans `_forever_/Interface/AddOns/`, avec un seul dossier `SyndicatRouge` et son TOC directement dedans. Le compagnon de démonstration est facultatif.
2. Dans le jeu, chacun saisit `/reload`, puis `/srsync activer`.
3. Un membre saisit `/srsync test`. L'autre doit lire « signal de partage reçu de … » ; l'émetteur doit lire « réception confirmée par … (test) ».
4. Refaire dans l'autre sens. Chacun saisit `/srsync` pour voir membres vus, accusés reçus, état et éventuel problème.
5. `/reload`, puis `/srsync` : activation conservée, rattrapage demandé. `/sr` affiche « Registre de guilde · partage activé ». Le test laisse le registre vide.

Si une commande indique `restricted`, `send_code_11` ou une identité inaccessible, conserver le résultat et arrêter le test ; aucun contournement des protections du client. Le démarrage peut nécessiter `/srsync reprendre` si les communautés ne sont pas encore initialisées. L'activation enregistrée ne signifie pas qu'un envoi a été autorisé.

## Limites ouvertes

Le test en jeu à deux membres n'est pas encore exécuté. La détection réelle des meurtres et des vengeances reste séparée et non validée ; aucun événement réel n'est créé automatiquement par cette tranche. Le registre personnel et les exemples ne sont pas migrés automatiquement. `GuildNative.Change` est le point interne pour brancher la collecte validée ; il n'y a pas de formulaire manuel livré ici.

Plafond actuel : 128 incidents et 128 revendications, sans pagination. Un historique contenant une victime/vengeur ayant quitté la guilde ne sera pas écrasé, mais pourra empêcher la réouverture/fusion tant que la politique d'historique n'est pas étendue. Les faits sont attestés par des membres, pas certifiés par le serveur ; pas de signature cryptographique de l'auteur initial. Les remerciements ne sont pas envoyés à l'avengeur. Aucun envoi Discord. Le dernier test utilisateur de déconnexion/redémarrage complet de la sauvegarde personnelle reste différé.
