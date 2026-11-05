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

Installation principale vérifiée, 32 fichiers ; copie de secours finale `dist/client-backups/guild-transport-20261105-212534`. Après demande de `/reload`, diagnostic puis activation, l'utilisateur répond **« oui »** à la présence de `identité=ready`, `membre=own_guild_club` et « partage de guilde activé ». Activation locale confirmée par ce retour, pas encore échange avec l'ami. Les deux archives 0.5.1 regroupent aussi Arathi, le nom Tableau des primes et le bouton TP. Publication GitHub en préparation ; ne pas remplacer silencieusement les ZIP précédents.

À vérifier à deux après mise à jour identique : chacun `/srsync activer`, puis `/srsync test` dans chaque sens ; relever les accusés et `/srsync` si un paquet reste en attente. L'activation locale ne prouve ni autorisation d'envoyer sur le serveur, ni réception, ni attribution automatique de vengeance. Ces limites restent ouvertes.
