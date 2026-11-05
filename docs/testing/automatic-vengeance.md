# Vengeances automatiques — preuve réelle requise

## Choix et état

L'utilisateur demande la validation de vengeances réelles et répond **« Automatique uniquement »**. Pas de saisie manuelle ou de présomption de dernier attaquant en remplacement. Aucun point réel ni incident fictif ajouté. La collecte d'incidents est encore non branchée et le test de partage à deux membres attend toujours son résultat.

## Source vérifiée

Le 5 novembre 2026, la branche Forever résout encore sur **eac30af597e5aaa43a60f6675ef5fdcea100375f**, daté du 4 novembre ; client installé **1.60.1.70790**. [UnitDocumentation.lua épinglé](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua) :

- `PARTY_KILL(attackerGUID,targetGUID)` : événement synchrone, `SecretWhenUnitIdentityRestricted`. Deux identités déclarées, pas de garantie de livraison PvP.
- `UNIT_DIED(unitGUID)` : pas d'attaquant. `PLAYER_PVP_KILLS_CHANGED(unitTarget)` : pas de victime liée à un tueur.
- `UnitGUID(unit)` : argument `UnitTokenPvPRestrictedForAddOns`, identité conditionnellement secrète. Le diagnostic ne l'appelle que pour **player**, jamais pour target/focus/nameplate.
- `UnitNameFromGUID` : identité conditionnellement secrète ; aucune résolution tentée par le diagnostic.

[PvpInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/PvpInfoDocumentation.lua) : les scores agrégés et killingBlows ne lient pas une victime à un attaquant ; GetScoreInfo est secret pendant un match actif. Pas une preuve de vengeance. Le journal de combat reste restreint selon le retour utilisateur antérieur, aucun accès interne/sécurisé essayé.

## Diagnostic livré

Compagnon uniquement, `KillProofProbe.lua`, commande explicite `/srkill debut|bilan|fin`. Pas de nouvelle SavedVariables, pas d'activation au chargement. Les requêtes EventUtils et l'abonnement sont rapportés séparément. Le gestionnaire vérifie chaque argument avec `issecretvalue` avant type, longueur, motif ou égalité. En cas de protection : compteur et arrêt du traitement de cette réception, aucune autre voie tentée.

Si les deux arguments sont publics et valides, seul le propre GUID public est interrogé pour constater que l'attaquant est le personnage de l'utilisateur. Les arguments sont ensuite abandonnés ; seules catégories et compteurs restent en mémoire. Pas de GUID/nom dans le chat, rapport, sauvegarde ou réseau. Pas de recherche de l'identité cible, de création de revendication ni de récompense. Une paire publique n'établit pas à elle seule un kill de joueur recherché : elle peut concerner un PNJ, et la correspondance avec un incident ouvert n'est pas établie.

## Vérification

`node tools/test-native.mjs` : 168 contrôles/scénarios passés, dont 21 nouveaux pour le diagnostic (gardes secret/erreur/absence, champs nil/masqués, propre GUID protégé, autre attaquant, égalité avec soi, abonnement, callback, mauvais client, arrêt/redémarrage, absence de mutation et d'accès cible ou combat). Les 54 tests moteur/transport de la tranche précédente sont inchangés. Aucune preuve de fonctionnement réel n'est déduite de ces doubles injectés.

Installés : `KillProofProbe.lua` et `SyndicatRougeDemo.toc`, copies vérifiées par empreintes, ancien TOC conservé sous `dist/client-backups/kill-proof-20261105-185611`. Archive optionnelle distincte `dist/SyndicatRougeDemo-forever-kill-proof.zip`, exige l'addon principal déjà installé. Aucun fichier des archives GitHub/CurseForge publiées n'a été remplacé. Pas de nouvelle capture graphique nécessaire pour ce diagnostic textuel ; aucune nouvelle capture du jeu réalisée.

## Étapes utilisateur en attente

1. `/reload`, puis `/srkill debut`. Recopier la ligne `PARTY_KILL` et `Résultat` pour vérifier disponibilité/abonnement.
2. Lors d'un prochain combat PvP normal, après un kill réellement réalisé par l'utilisateur, `/srkill bilan` avant de recharger. Recopier les compteurs.
3. `/srkill fin` arrête le diagnostic ; un reload le désactive également. `/srchat debut` doit être réactivé séparément si le test de message personnel doit continuer.

Si aucune réception : livraison PvP non démontrée, pas d'inférence d'absence universelle. Si identités protégées : cette voie ne fournit pas de preuve exploitable ; pas de contournement. Si une paire propre publique est observée : vérifier ensuite sa correspondance à un joueur et à son identité canonique dans des conditions autorisées avant tout branchement au crédit automatique. Le diagnostic ne suffit pas pour annoncer l'addon fonctionnel.
