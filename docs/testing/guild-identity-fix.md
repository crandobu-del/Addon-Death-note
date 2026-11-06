# Reconnaissance du personnage — 0.5.1-dev

5 novembre 2026, Forever uniquement. L'utilisateur rapporte le blocage `player_identity_unavailable` chez lui et chez son ami. Une première capture du diagnostic 0.5.1 établit ensuite : nom public, royaume fourni, membre non confirmé, `player_guild_membership_unavailable`. Le royaume manquant n'était donc pas la cause observée de ce cas réel.

La version corrige deux défauts de construction d'identité et sépare les erreurs :

- Quand `UnitFullName("player")` ne fournit pas de royaume **et que ses deux résultats sont publics**, utilise le propre royaume public de `GetNormalizedRealmName`. Si une valeur est protégée, aucune substitution ni autre tentative de lecture.
- Un nom de personnage fourni séparément de son royaume reste opaque : ses tirets ne sont pas interprétés comme un séparateur de royaume. Les expéditeurs du transport restent traités comme des noms éventuellement qualifiés.

Le blocage réellement observé vient de l'usage d'une recherche de membre comme prérequis pour reconnaître **le propre personnage**. `C_Club.GetGuildClubId()` fournit déjà sa propre guilde, et le nom public du club est vérifié contre Le Syndicat Rouge. La version utilise cette autorité pour soi (`membre=own_guild_club`). Les autres membres restent soumis à la vérification native : nom complet d'abord, nom court seulement pour un royaume local publiquement établi, sans retour protégé/erroné ni nom court ambigu contenant un tiret. Un message d'un autre membre non reconnu reste rejeté, avec `sender_membership_unavailable` dans le bilan.

Référence de build : source épinglée **eac30af597e5aaa43a60f6675ef5fdcea100375f**, `ClubDocumentation.lua` (`GetGuildClubId`, `GetClubInfo`), `GuildInfoDocumentation.lua` (`MemberExistsByName`, `GuildRoster`), `UnitDocumentation.lua` (`UnitFullName`), `PlayerScriptDocumentation.lua` (`GetNormalizedRealmName`, global, Environment All). Les requêtes d'identité restent gardées ; aucun décodage de noms `|K`, aucune lecture de roster protégé, aucune API de combat.

`/srsync diagnostic` affiche seulement la version et des catégories d'état. Une activation demandée reste en attente avec nouvelle tentative toutes les quinze secondes lorsque le profil est modifiable. Demande de rafraîchissement du roster au démarrage, pas à chaque paquet. Les anciennes sauvegardes et caches sont préservés ; pas de réattribution d'événements ou de points.

## Validation

`node tools/test-native.mjs` : **187 contrôles/scénarios** dont 26 du transport natif ; cas de royaume absent/protégé, tirets, vérification locale/distante, diagnostic sans mutation, propre guilde sans roster, autres membres toujours refusés si non reconnus. Le parcours à deux VM passe avec clic UI, ACK perdu, reloads et livraison confirmée. `node tools/test-lua.mjs` : **72 tests** passés sur règles, fusion, wire et mercis. Faits et API injectés, pas des preuves de partage réel en jeu.

Installation principale vérifiée, 32 fichiers ; copie de secours finale `dist/client-backups/guild-transport-20261105-212534`. Après demande de `/reload`, diagnostic puis activation, l'utilisateur répond **« oui »** à la présence de `identité=ready`, `membre=own_guild_club` et « partage de guilde activé ». Activation locale confirmée par ce retour, pas encore échange avec l'ami. Les deux archives 0.5.1 regroupent aussi Arathi, le nom Tableau des primes et le bouton TP. Publication GitHub effectuée : [v0.5.1-alpha.1](https://github.com/crandobu-del/Addon-Death-note/releases/tag/v0.5.1-alpha.1), commit `4acc6c90d5531d5804b1a08426f5d1b441f4f392`. Les ZIP précédents restent inchangés. Capture : `docs/testing/screenshots/guild-identity-release.png`. SHA256 du principal : `82723e444fc2b7e95a43ad5489675c24b929a6250f65ddd35138c5eeccac16fd` ; avec démo : `7050385efe9a70a0c5a7fc04a57d9156160a51952f439c9b7fdfa159316ed533`.

À vérifier à deux après mise à jour identique : chacun `/srsync activer`, puis `/srsync test` dans chaque sens ; relever les accusés et `/srsync` si un paquet reste en attente. L'activation locale ne prouve ni autorisation d'envoyer sur le serveur, ni réception, ni attribution automatique de vengeance. Ces limites restent ouvertes.

## Restriction d'envoi observée ensuite

Les deux clients rapportent `partage : restricted ; membres vus : 0 ; accusés reçus : 0 ; messages en file : 3 ; mercis en attente : 0`. Le statut précédent regroupait absence d'API, erreur, résultat protégé, résultat invalide et refus public du royaume : il ne permet pas encore d'affirmer lequel s'applique.

Diagnostic local ajouté le 5 novembre : `/srsync diagnostic` affiche aussi `diagnostic envoi=allowed|realm_restricted|restriction_api_missing|restriction_query_failed|restriction_value_protected|restriction_result_invalid`. Aucun envoi ni changement du registre par cette commande. Les cinq échecs continuent à bloquer l'envoi, sans inspecter les valeurs protégées ni contourner un refus. La boucle reprend son fonctionnement normal seulement si l'API renvoie publiquement `false`.

Contrat revérifié via le connecteur GitHub à la même source épinglée, `ChatInfoDocumentation.lua` : `C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()` renvoie un booléen non nil ; `false` autorise les messages sortants et le contrôle dépend du royaume, indépendamment de la réception. Existence/exécution réelle et cause du blocage restent à observer.

`node tools/test-native.mjs` : 188 contrôles/scénarios (27 transport natif), plus parcours de livraison à deux VM, passés. Test de refus public, absence, erreur, protection et valeurs invalides sans envoi ni retrait de file ; reprise après autorisation publique. Installation locale des 32 fichiers vérifiée avec sauvegarde `dist/client-backups/guild-transport-20261105-214904`. Diagnostic non ajouté aux archives GitHub déjà publiées ; seul le client local est mis à jour pour identifier le blocage avant une nouvelle livraison. Résultat en jeu encore attendu.
