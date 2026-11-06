# Exclusion des champs de bataille et arènes — 0.6.1-dev

Demande du 6 novembre 2026 : désactiver les morts et vengeances en champ de bataille et en arène. Cible inchangée : Forever 1.60.1.70790, interface 16001. Pas de modification graphique.

`Features/PvpScope.lua` contrôle `IsInInstance()` à chaque mutation locale, avant stockage et diffusion. Les types `pvp` et `arena` sont refusés. Les autres contextes reconnus restent autorisés ; une API absente, en erreur, incohérente ou protégée refuse la mutation. Aucun accès aux valeurs protégées n'est tenté. Le contexte est conservé dans `instanceType` des nouveaux incidents et revendications.

Les entrées locales `Guild.AddIncident`, `Guild.Claim` et `Core.Execute` appliquent le filtre ; le décodage des données refuse également les enregistrements explicitement marqués `pvp` ou `arena`. Aucun incident, compteur de gank, clôture, point ou notification de vengeance ne découle d'une mutation refusée. La consultation, les remerciements et la réception d'événements extérieurs restent disponibles en instance. Ce contrôle ne désactive pas les diagnostics temporaires sans attribution de points ni les marqueurs des dossiers déjà existants.

La restauration et la réception ne dépendent pas du lieu actuel du lecteur. Les anciennes données sans contexte sont préservées ; il est impossible d'en déduire après coup si elles provenaient d'un champ de bataille. Les préfixes `SRGuild3` et `SRGuildTest3` isolent les nouvelles sessions des clients plus anciens qui n'appliquent pas cette règle. Tous les membres doivent mettre à jour. Comme tout addon local, ce n'est pas une attestation serveur contre un client modifié.

Source Forever résolue le 6 novembre 2026 : `Gethe/wow-ui-source` branche `forever`, commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`. Déclaration vérifiée : `Interface/AddOns/Blizzard_APIDocumentationGenerated/InstanceDocumentation.lua`, `IsInInstance()` retourne `isInInstance: bool` et `instanceType: cstring`. Les valeurs sont vérifiées par le garde avant toute utilisation.

Vérification : 13 nouveaux scénarios ciblent morts et vengeances dans les deux contextes, absence de mutation/points/notification, rejet des origines exclues au décodage réseau, conservation et réception du monde extérieur depuis une arène, reprise en sortant du champ de bataille, historique ancien, API absente/erronée/protégée et maintien des autres types d'instance. Les suites moteur, natives et cycles à deux clients simulés complètent ces contrôles. Ce ne sont pas des tests dans le jeu.

La collecte automatique des morts réelles et les preuves des vengeances réelles restent non connectées/validées : ce filtre encadre les écritures existantes et les futures entrées de collecte ; il ne prétend pas livrer cette collecte. Une future collecte différée doit capturer le contexte au moment de l'événement et rejeter un événement capturé dans un contexte exclu, même si le joueur est déjà sorti lors de son traitement.

Acceptation en jeu à faire : charger 0.6.1 avec `/reload`, vérifier qu'une tentative de scénario partagé d'incidents/vengeance est refusée dans un champ de bataille puis une arène ; vérifier la reprise après sortie et la consultation d'un registre extérieur sans modification des anciens points. Les diagnostics seuls peuvent continuer à compter des événements, sans créer de prime.

Archives locales préparées : `dist/SyndicatRouge-forever-0.6.1-dev.zip` et `dist/SyndicatRouge-forever-0.6.1-dev-avec-demo.zip`. Correctif mineur local ; aucune nouvelle publication CurseForge ou GitHub dans cette tranche.

Livraison locale vérifiée le 6 novembre 2026 : 38 fichiers du module principal et compagnon installé mis à jour, comparaison des empreintes après copie, aucune modification de WTF. Sauvegardes : `dist/client-backups/guild-transport-20261106-134423` et `dist/client-backups/guild-hunt-demo-20261106-134424`. `/reload` est nécessaire dans le jeu. Les deux ZIP ont été contrôlés entrée par entrée contre les sources, y compris le nouveau module au manifeste. SHA256 principal : `311d111ba474d45cf5cf9031c0308c1dd8f5becb736ba953b912e8d76a8463d3` ; avec démo : `f2184e58e910c8cfd90d495dff0b0a812f850fcd5cfc31aa2f00b7cd1403c568`.

Bilan final : 72 tests moteur/transport et 255 contrôles/scénarios natifs (dont 13 nouveaux), plus cycles de sauvegarde et quatre parcours de livraison entre clients Lua isolés. Tous passent ; journal natif `dist/test-native-061-final.log`. `git diff --check` passe. Aucun test réel de champ de bataille/arène exécuté par l'agent.
