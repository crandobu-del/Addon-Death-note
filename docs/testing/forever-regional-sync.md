# Partage normal Forever — 0.5.2-dev

5 novembre 2026. Cible : Forever 1.60.1.70790, interface 16001, projet Camelot 18 ; source Blizzard épinglée `eac30af597e5aaa43a60f6675ef5fdcea100375f`. Pas de support Retail/Classic ajouté.

## Preuve et cause

Après les sondes précédentes, l'utilisateur rapporte en v4 : `envoi=accepted_code_0 ; écho personnel=oui ; signaux d’autres membres=1`, `messages=2 ; jeton personnel=oui ; expéditeur=verified_member`. Capture jointe : signal d'un membre vérifié par son nom régional et écho propre reconnu. Cela établit une réception de pair dans la sonde, pas encore la livraison du protocole normal ni d'un merci réel. Voir [historique et sources primaires](forever-communications-research.md).

Deux défauts empêchaient le transport normal : attente perpétuelle sur un drapeau public vrai malgré l'acceptation/livraison observée ; interprétation des noms régionaux comme Name-Realm. Le mode régional de Forever utilise des noms complets avec espace et des lookups natifs sans suffixe ajouté.

## Changement

- `Context.NameMode` exige une API RegionalUniqueNamesEnabled présente, un appel réussi et un booléen public. Si régional : identité propre obtenue par UnitNameUnmodified, deux retours gardés avant toute inspection, assemblage avec espace. Nom complet conservé, y compris les tirets. Aucun GUID PvP ou roster protégé lu.
- Espace d'identité interne explicite `forever-regional` dans le champ générique `realm` des acteurs ; ce champ est ici un namespace technique, pas le nom du royaume. Nom transporté et requête MemberExistsByName = nom complet natif exact. Aucun retrait de nom de famille, aucun suffixe de royaume ajouté. Les expéditeurs natifs restent liés à l'enveloppe et vérifiés dans la guilde courante ; les retours protégés/erreurs refusent l'acteur.
- Registre de guilde régional sous `guild:<ClubId>:regional-v1` pour chaque personnage. Les anciennes entrées sous `guild:<ClubId>` dans guilds et guildDelivery restent intactes : aucune conversion des identités ambiguës ni réattribution d'incident, merci ou réputation. Le registre régional est créé séparément ; un message informe de cette séparation si un ancien cache existe. Les données personnelles, profil et réglages ne changent pas. Les autres clients doivent utiliser la même version pour ce scope ; un paquet d'un ancien scope ne fusionne pas.
- La file normale vérifie InChatMessagingLockdown : absent, erreur, protégé, invalide ou vrai = envoi suspendu. AreOutgoingAddonChatMessagesRestricted reste un indicateur ; un vrai public ne bloque plus à lui seul sur le Forever observé. Valeur absente/erronée/protégée/invalide toujours bloquante. L'appel normal SendAddonMessage garde ses résultats et limites : aucune API remplacée, aucune protection contournée, aucun envoi hors GUILD. Code 0 = soumis ; seul ACK d'un autre membre vérifié = réception confirmée.
- Le contrôle des destinataires des mercis utilise le même contexte régional. La sonde reste distincte et ne crée ni primes ni points. Aucune détection de mort/kill ni attribution automatique supplémentaire branchée dans cette tranche.

Contrats revérifiés dans UnitDocumentation (RegionalUniqueNamesEnabled, UnitNameUnmodified), GuildInfoDocumentation (MemberExistsByName), ChatInfoDocumentation (requêtes de restriction et SendAddonMessage) au pin ci-dessus. Campkeeper Core/Util.lua et Comm/Comm.lua au pin ef13a90864ebf4767366c7f6414230ebc2229ccb corroborent la construction du nom régional ; les retours réels v3/v4 la confirment sur ce client.

## Vérifications

`node tools/test-native.mjs` : **197 contrôles/scénarios**, dont 36 de guilde, plus deux parcours complets entre VM isolées : identités Name-Realm historiques et identités régionales Forever avec drapeau public vrai. Chaque parcours vérifie rattrapage, clic Remercier de l'interface, reload expéditeur, ACK perdu, reload destinataire, nouvelle tentative, déduplication, livraison confirmée et état lu persistant. Ce sont des scénarios simulés, pas des vengeances ou mercis réels en jeu.

Tests de contexte : identité régionale propre, nom distant exact, rejet de l'écho propre, conservation des anciens caches même non vides, restauration du nouveau scope, mode/identités protégés ; tests de verrouillage normal absent/erreur/protégé/invalide et attente/reprise. `git diff --check` passé. L'affichage général n'a pas été modifié et n'a pas fait l'objet d'une nouvelle capture visuelle.

## Livraison

Principal installé : 32 fichiers comparés par SHA256, sauvegarde `dist/client-backups/guild-transport-20261105-224658`. Version principale/TOCs/générateurs **0.5.2-dev**. Le compagnon précédemment installé reste utilisable ; la mise à jour principale ne le remplace pas. Archive principale vérifiée entrée par entrée par `tools/package-sync-probe.ps1 -Release` :

`dist/SyndicatRouge-forever-0.5.2-dev.zip`

SHA256 `92e9b9fed34571e2c10863c24b5087331ce2c3c86ff15355ff904f58fdc31f12`.

ZIP local à transmettre à l'ami ; pas de publication GitHub/CurseForge effectuée pour 0.5.2, anciennes publications inchangées. Aucun fichier WTF modifié extérieurement.

Acceptation en jeu attendue : ami installe le principal 0.5.2, tous deux reload puis `/srsync activer`, `/srsync test` chacun à son tour. Attendre « signal de partage reçu de… » et « réception confirmée par… (test) » dans les deux sens. Sinon relever `/srsync` et `/srsync diagnostic` des deux joueurs. L'activation et les preuves de sonde seules ne suffisent pas à marquer le protocole normal validé.

### Retour d'acceptation

Après livraison 0.5.2 et demande explicite du parcours activer/test avec signaux et confirmations dans les deux sens, l'utilisateur répond **« ça fonctionne »** le 5 novembre 2026. Partage normal à deux confirmé par ce retour utilisateur ; pas de nouvelle capture ou de compteurs détaillés fournis pour ce parcours. Cela ne valide pas encore la collecte d'un incident réel, la preuve automatique de vengeance, la livraison d'un remerciement réel ni la persistance réseau après déconnexion complète.
