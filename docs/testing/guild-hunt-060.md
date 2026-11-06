# Tableau des primes 0.6.0-dev — chasse de guilde

Livraison du 6 novembre 2026, Forever uniquement. Implémente REQ-023/024/025. Source API Forever épinglée : `eac30af597e5aaa43a60f6675ef5fdcea100375f` (1.60.1.70790). Aucun code ou asset HeadHunter incorporé. Choix UI déjà accepté : développer directement, conserver la charte du registre.

## Prime de gank répété

`Features/BountyRules.lua` calcule le nombre maximal de morts d'une même paire ennemi/victime dans une fenêtre strictement inférieure à 3 600 secondes : palier de trois, multiplicateurs ×2/×4/×8 à 3/6/9 morts. Calcul séparé par victime ; récompenses additionnées ensuite. Le pic reste applicable aux incidents ouverts de cette victime jusqu'à leur clôture, même après une heure. Pas de diminution horaire de la prime acquise.

La catégorie GANK est visible dans la liste et le dossier ; rechercher « gank répété » filtre ces dossiers. La cible au-dessus des plaques reprend le montant du même calcul. La clôture d'une vengeance utilise uniquement l'ensemble immuable des incidents qu'elle référence : une clôture partielle recalcule son propre ensemble, pas la totalité affichée. Les clôtures normales de l'ensemble ouvert ont le même montant que le dossier. Refus explicite si le montant sort des entiers exactement représentables ; aucun infini ni plafond silencieux.

Les nouvelles revendications du chemin de guilde portent `rewardRule=2`. Les anciennes sans ce champ gardent le barème historique. Restauration et classement reconstruisent la récompense depuis les incidents validés, sans faire confiance à un compteur sauvegardé ; des incidents ajoutés ultérieurement ne changent pas la récompense d'une ancienne revendication. Le préfixe réseau normal passe à **SRGuild2**, celui du test à **SRGuildTest2** : tous les membres doivent mettre à jour, les versions 0.5.x n'échangent plus avec cette livraison. Les caches existants sont conservés.

## Signalements de présence

`Sync/Sightings.lua` observe uniquement des plaques de joueurs à identité publique exacte correspondant à une prime ouverte du registre partagé réel. Il ne lit aucun GUID ennemi. L'alerte indique **repéré depuis la zone de l'observateur**, car GetBestMapForUnit ne fonctionne que pour player et les membres du groupe selon la documentation ; elle ne garantit pas la zone précise du joueur à une frontière ni sa position actuelle. Aucun radar de tous les ennemis de la zone.

Canal technique GUILD : expéditeur vérifié par le transport existant, enveloppe bornée, cible connue, observation de moins de 60 secondes, zone/heure valides. Aucune prime, vengeance ou réputation créée par une présence. Mode test interdit pour les observations réelles. Notifications récentes dans l'onglet Notifications, marquables comme lues ; au plus 20 en mémoire, visibilité cinq minutes, pas de rattrapage d'anciennes présences après reload.

Une alerte logique par cible/zone pendant cinq minutes. L'observateur n'entre dans l'élection qu'après acceptation de son dernier paquet sortant ; élection déterministe de trois secondes parmi les observateurs annoncés. Les simples récepteurs ne republient pas le chat. File retardée couverte par deux VM ; pertes/partition ou livraison plus lente que l'élection peuvent toujours empêcher une alerte ou provoquer une répétition, sans serveur coordinateur. Aucune garantie de livraison exactement une fois en cas de coupure.

L'élu tente `C_ChatInfo.SendChatMessage(message,"GUILD")` après le contrôle du verrou de chat. L'API déclare HasRestrictions et ne retourne pas d'accusé de livraison. L'état `submitted_not_confirmed` indique seulement un appel sans erreur. Si l'appel est bloqué, absent ou échoue, la notification addon reste visible ; aucune tentative de contournement. Le message est borné à 255 octets et sans balisage de joueur. L'index des primes est recalculé une seule fois par remplacement du registre, pas pour chaque plaque.

## Accès réservé

`Access.lua` réutilise GuildContext.Current : propre guilde native et nom exact Le Syndicat Rouge, identité publique complète. Contrôles à la connexion, au changement de guilde, périodiquement et aux points d'entrée. Hors guilde/autre guilde/identité indisponible : registre fermé, bouton caché, marqueurs retirés, file de partage et présences abandonnées, écritures bloquées. Les commandes de démonstration et les diagnostics du compagnon sont gardés ; les diagnostics déjà lancés sont arrêtés sur révocation. Sauvegardes existantes conservées ; retour après appartenance vérifiée. Le contrôle est local à l'addon distribué, pas une authentification serveur.

## Vérifications

- `node tools/test-native.mjs` : **242 contrôles/scénarios**, dont 24 nouveaux sur barème, historique, overflow, rendu calculé, accès et présences ; quatre parcours VM (livraison classique, noms régionaux, test partagé enrichi et présences à deux VM avec file retardée).
- `node tools/test-lua.mjs` : **72 tests** moteur/transport supplémentaires passent.
- Revue indépendante : corrections de l'élection avant vidage de file, du recalcul de l'index à chaque plaque et des diagnostics restant actifs après départ de guilde. Régressions correspondantes ajoutées.
- UIForever Forever : ZIP de prévisualisation frais, six incidents fictifs sur une victime, prime 24 et libellé GANK RÉPÉTÉ ×4 visibles, pas d'erreur Lua observée ; capture `screenshots/gank-bounty-060.jpg`. Appartenance de guilde simulée uniquement dans la console du simulateur. Les tuiles de Strangleronce apparaissent en damier dans cette session du simulateur ; rendu des cartes du client réel déjà vérifié auparavant, aucune nouvelle validation de carte réelle déduite de cette image. Des ajouts ultérieurs au classement/scénario de test ont été vérifiés en VM, pas par un second import graphique.
- Pas d'essai de cette version dans un vrai client ni d'envoi réel au chat de guilde par l'agent. Le diagnostic de récapitulatif de mort reste à développer ; collecte automatique des meurtres et preuve de vengeance réelle toujours non connectées/validées.

## Essai utilisateur sans mort réelle

Livraison : installation locale vérifiée (37 fichiers principaux et compagnon), archives publiées sur [GitHub v0.6.0-alpha.1](https://github.com/crandobu-del/Addon-Death-note/releases/tag/v0.6.0-alpha.1), commit `d8a59d403d655a1d270f520ea3cdb7028f444bbf`. Empreintes des deux assets GitHub comparées aux archives vérifiées. CurseForge **9473302**, canal Release, état **Processing** observé après rechargement du portail ; publication automatique après approbation, disponibilité publique pas encore confirmée. Capture `screenshots/curseforge-060-submitted.jpg`. Archive principale SHA256 `a4e279bf42b3adc4c0b6d1d36b94671f274d1db5fcf3b8f58e02a1baca538587`, avec démo `974499b8197116235cf374db7ad86f432c7ed9c784ac101c8fbc8acc9fb689fa`.

1. Mettre la même version 0.6.0 sur les deux clients, `/reload`, puis `/srsync activer` et test dans les deux sens.
2. Chacun lance `/srtest debut`. Un seul membre lance `/srtest gank` : six morts fictives de TEST Traqueur ; dossier GANK, récompense 24 de test.
3. L'autre membre lance `/srtest venger traqueur` : 24 réputation de test, notification et merci comme dans le scénario existant. Refaire la commande ne doit pas créditer à nouveau.
4. `/srtest fin` rend le registre réel. Ce scénario ne valide pas une preuve de kill réel et n'émet pas d'alerte de présence réelle.
5. `/srpresence` affiche l'état du suivi et le résultat du dernier appel de chat. Le test de présence réel exige un vrai dossier ouvert avec identité publique correspondante ; sans collecte réelle validée, aucune présence inventée pour ce test. Le blocage hors guilde se teste sur un personnage déjà hors guilde, sans faire quitter la guilde au personnage principal.
