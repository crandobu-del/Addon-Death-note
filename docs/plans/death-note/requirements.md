# Tableau des primes — cadrage du projet

Suivi actualisé le 5 novembre 2026 : interface native installée, cartes et icônes du client affichées, sauvegarde personnelle et réglages confirmés après /reload. Transport de guilde implémenté et installé ; validation réelle à deux membres en cours. Collecte automatique encore non validée. Les observations initiales ci-dessous sont complétées par implementation-matrix.md et les rapports de tests successifs.
Cible exclusive confirmée : WoW Forever. Ne pas substituer Retail ou Classic. Guilde : **Le Syndicat Rouge**. Suivi : [implementation-matrix.md](implementation-matrix.md).

## Objectif

Permettre aux membres d'une guilde de partager un registre de joueurs ennemis à rechercher, avec le contexte des attaques et une progression des primes en cas de récidive.

## Exigences

| ID | Origine | Comportement et critère d'acceptation | État |
|---|---|---|---|
| REQ-001 | Utilisateur | Fonctionner sur WoW Forever ; chargement et fonctions vérifiés sur le client réel avant livraison. | Requis |
| REQ-002 | Utilisateur | Lorsqu'un membre se fait tuer par un joueur, répertorier ce joueur ; une mort PvP observable produit une fiche associant victime et ennemi. L'attribution exacte reste à vérifier. | Requis |
| REQ-003 | Utilisateur | Informer les autres membres de la guilde ; deux membres équipés de l'addon reçoivent le même événement sans doublon. | Requis |
| REQ-004 | Utilisateur | Voir qui a attaqué qui, où et quand ; chaque incident affiche auteur observé, victime, zone et date/heure, ou une indication explicite de donnée inconnue. | Requis |
| REQ-005 | Utilisateur, précisé le 6 novembre 2026 | Augmenter la prime et la visibilité des récidivistes ; plusieurs incidents distincts font progresser leur classement. Catégorie renforcée pour gank répété d'un même membre : REQ-023. | Requis ; barème spécial à confirmer |
| REQ-006 | Utilisateur, « la sauvegarde go » | Conserver les incidents après rechargement et reconnexion ; les fiches réapparaissent sans duplication. | Requis ; profil personnel implémenté, réglages confirmés après /reload, cycle des faits testé hors jeu ; reconnexion/redémarrage différés |
| REQ-007 | Utilisateur, précision du 4 novembre 2026 | Utiliser des primes symboliques, sans financement en or. Distinguer le niveau de recherche d'un ennemi et les points gagnés par un membre qui venge la guilde. | Requis |
| REQ-008 | Utilisateur | Attribuer des points de vengeance aux membres ; une vengeance validée associe le membre, l'ennemi et les incidents vengés, et ne crédite pas deux fois le même événement synchronisé. | Requis ; 1 réputation par incident clôturé, réseau et groupes à définir |
| REQ-009 | Utilisateur, proposition | Afficher un classement des membres ayant vengé la guilde, calculé à partir des points de vengeance et cohérent après synchronisation. | Proposition utilisateur à inclure au périmètre |
| REQ-010 | Utilisateur | Notifier chaque victime concernée lorsqu'elle a été vengée ; identifier le vengeur et l'ennemi. Prévoir la réception après reconnexion et dédupliquer les notifications. | Requis ; rattrapage proposé |
| REQ-011 | Utilisateur | Laisser la victime remercier librement le vengeur ; aucune émission automatique de remerciement, aucun paiement imposé. La forme du remerciement reste à définir. | Requis |
| REQ-012 | Utilisateur, retour sur la maquette | Conserver la disposition « Registre de chasse » : liste à gauche, dossier de l'ennemi sélectionné à droite. | Requis ; disposition choisie |
| REQ-013 | Utilisateur | Afficher un encart de carte WoW avec le lieu du dernier meurtre connu de l'ennemi, accompagné de sa date/heure ; ne pas présenter ce marqueur comme une position actuelle. Si les coordonnées ne sont pas accessibles, indiquer seulement la zone connue. | Requis ; accès aux coordonnées à vérifier |
| REQ-014 | Utilisateur, correction d'identité | Direction artistique de registre clandestin : parchemin, écriture manuscrite lisible, encre, accents rouges et tampon « Vengé ». Identité propre au Syndicat Rouge ; aucune référence textuelle aux Défias dans l'interface. | Requis ; rendu à valider |
| REQ-015 | Utilisateur | Dossier détaillé avec portrait ou image race/classe, niveau de l'ennemi et prime ; n'afficher que les attributs réellement connus en production. | Requis ; illustrations fictives dans la maquette |
| REQ-016 | Utilisateur | Nommer la monnaie virtuelle de récompense « réputation » et afficher la quantité offerte pour une vengeance. Réputation interne à l'addon, distincte de la réputation de faction Blizzard et de la prime de recherche de l'ennemi. | Requis |
| REQ-017 | Utilisateur | Afficher en jeu un marqueur au-dessus du pseudo des joueurs recherchés. Proposition visuelle : petit emblème rouge propre à la guilde et récompense en réputation, sur la plaque de nom lorsqu'elle est visible. L'affichage est local chez chaque membre équipé de l'addon. Retirer le marqueur après clôture des incidents selon la règle de vengeance, à la disparition de la plaque ou lors de sa réutilisation pour un autre joueur. | Prototype 0.5.5 livré/installé ; 16 tests et aperçu simulateur passés ; ancrage réel et PvP Forever à valider |
| REQ-018 | Utilisateur | La guilde s'appelle exactement « Le Syndicat Rouge ». Afficher ce nom dans l'identité de l'interface. Supprimer les références textuelles aux Défias, y compris devises et inscriptions décoratives. Le nom affiché de l'addon est désormais « Tableau des primes », selon la demande du 5 novembre 2026. | Requis |
| REQ-019 | Utilisateur | Prévoir des notifications Discord en cas d'événement, désactivables et configurables par catégorie. Propositions de catégories : nouveau recherché, prime augmentée, vengeance accomplie et récapitulatif du classement. Un événement partagé entre plusieurs membres ne doit produire qu'une notification logique ; stratégie de déduplication et cas de résultat réseau incertain à définir. | Requis ; catégories proposées, intégration non configurée |

| REQ-020 | Utilisateur, 5 novembre 2026 | Bouton à côté de la minicarte en haut à droite du jeu pour ouvrir l'interface ; clic gauche ouvre/ferme le même registre que `/sr`. | Implémenté, installé ; présence et fonctionnement confirmés par l'utilisateur |
| REQ-023 | Utilisateur, 6 novembre 2026 | Catégorie spéciale avec prime/récompense en réputation renforcée lorsqu'un même ennemi gank à répétition un même membre. Toutes les 3 morts distinctes en moins d'une heure, récompense doublée : ×2 à 3 morts, ×4 à 6, ×8 à 9. Afficher et créditer le même barème sans doublon. | Implémenté 0.6.0, tests VM passés ; validation client à faire ; [spécification](guild-hunt-features.md) |
| REQ-024 | Utilisateur, 6 novembre 2026 | Avertir la guilde lorsqu'un membre observe réellement un joueur recherché dans sa zone, dans le chat de guilde et par notification addon. Identité exacte publique, zone/heure/observateur, déduplication entre observateurs et récepteurs ; aucune fausse promesse de radar ou distance précise. | Implémenté 0.6.0 ; envoi réel du chat à confirmer ; [spécification](guild-hunt-features.md) |
| REQ-025 | Utilisateur, 6 novembre 2026 | Réserver l'utilisation de l'addon aux membres vérifiés du Syndicat Rouge, y compris interface, marqueurs, collecte et partage. Attente explicite si l'identité de guilde manque ; arrêt au départ de guilde sans effacer les sauvegardes. | Implémenté 0.6.0 ; restriction globale testée hors jeu ; [spécification](guild-hunt-features.md) |

## Proposition de première version — non encore acceptée

- Liste « Recherchés » triée par indice, avec nombre de morts, nombre de victimes distinctes et dernière zone connue.
- Fiche par ennemi avec historique chronologique des incidents.
- Journal de guilde avec notifications configurables.
- Prime symbolique confirmée par l'utilisateur ; formule et éventuelle expiration à définir.
- Classement distinct des vengeurs de la guilde, avec points et nombre de membres vengés.
- Règle de base retenue après « ok super » : +1 réputation par incident encore ouvert vengé ; un incident déjà clôturé ne rapporte plus de points. Les morts suivantes du même ennemi ne rapportent rien sans nouvel incident ouvert. Règles de contribution en groupe et preuve de mise à mort à étudier.
- Notification personnelle de vengeance avec possibilité de remercier volontairement ; canal et texte à préciser.
- Clarification du vocabulaire : les points de vengeance sont désormais nommés « réputation ». Barème initial conservé : 1 réputation par incident encore ouvert vengé. Une récompense de +3 réputation correspond donc à trois incidents ouverts clôturés ; les modalités d'attribution en groupe restent ouvertes. Aucune dépense de réputation n'est encore spécifiée.
- Stockage local et synchronisation entre membres équipés ; protocole, rattrapage hors ligne et limites à étudier.
- Signaler séparément les observations automatiques et les déclarations manuelles si celles-ci sont retenues.

## Cible et limites de preuve

Build installé et interface : inconnus. Aucun test en jeu effectué.
Le skill installé cite des sources Forever datées ; elles ne certifient pas les capacités du client de la guilde.
Après un échec via la navigation web, la consultation via le connecteur GitHub a réussi le 4 novembre 2026.
Source épinglée : Gethe/wow-ui-source, commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`, version déclarée `1.60.1.70790`. Ce build source ne prouve pas le build installé.
`Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogDocumentation.lua` déclare `C_CombatLog.IsCombatLogRestricted()` et marque `COMBAT_LOG_EVENT_UNFILTERED` avec `HasRestrictions = true` et `CallbackEvent = true` : ne pas supposer qu'un addon tiers peut lire les attaquants.
`Interface/AddOns/Blizzard_APIDocumentationGenerated/DeathInfoDocumentation.lua` déclare `PLAYER_DEAD` sans information d'auteur. Cet événement seul ne permet donc pas d'identifier le tueur.
À vérifier avant de choisir les API : événements de combat accessibles, identification des attaquants et morts, zone/heure, messages d'addon de guilde, restrictions et persistance.
La validation des vengeances et l'attribution des points demandent aussi une preuve de mort de l'ennemi et une règle d'attribution au membre/groupe ; elles ne sont pas encore vérifiées sur Forever.
Pour REQ-017, sources examinées au même commit épinglé : `Interface/AddOns/Blizzard_APIDocumentationGenerated/NamePlateDocumentation.lua` déclare `C_NamePlate.GetNamePlateForUnit(unitToken, includeForbidden=false)` et `GetNamePlates()`. `Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlates.toc` sélectionne des constantes et adaptations Camelot ainsi que les composants partagés. Ces déclarations sont une piste d'implémentation, pas une validation des accès, de l'identité lisible, des ancres ou du fonctionnement en combat sur le client Forever. Ne pas demander de plaques interdites ni contourner les restrictions. Prévoir une icône locale de l'addon ; aucune icône de raid globale n'est promise.
Ne pas présenter un participant observé ou le dernier coup comme preuve de qui a commencé une attaque. Ne pas inventer de position ou d'événement hors observation.

## Interface

Choix utilisateur actualisé : travailler sur la maquette et l'interface en attendant la sortie de WoW Forever. Cette demande remplace le choix antérieur de développement direct sans maquette.
Maquette interactive initiale : [prototype de disposition](../../prototypes/death-note-interface.html). Ce fichier est un fragment destiné à la prévisualisation ; les images de référence sont consultables directement dans `assets/`.
Deux dispositions initiales : « Registre de chasse » (liste et fiche) et « Tableau des contrats » (cartes et fiche). L'utilisateur a choisi « Registre de chasse ». Navigation Recherchés / Vengeurs / Journal / Notifications, sélection d'un ennemi, recherche et remerciement simulé. Données entièrement fictives, aucun envoi réel, aucune connexion au client.
Retour artistique : remplacer l'aspect initial par une direction défias / mafia avec parchemin, manuscrit, portraits, niveaux, carte du dernier meurtre, tampons et récompense en réputation. Concept v2 réalisé : [image](assets/death-note-defias-v2.png) et [direction artistique](direction-artistique-defias.md). Ce concept ne constitue pas encore un design intégralement accepté ni une modification de l'interface Lua. Le prototype HTML initial n'a pas encore été adapté à cette nouvelle direction.
Identité corrigée : la référence visuelle courante est [Le Syndicat Rouge — v3](assets/death-note-syndicat-rouge-v3.png). Contrôle visuel : nom de guilde et sous-titre corrigés, inscription de faction retirée. Le concept v2 reste historique. Voir [identité courante](identite-syndicat-rouge.md).
À la demande de l'utilisateur, déclinaison des onglets Vengeurs, Journal et Notifications : voir [les concepts d'onglets](onglets-maquettes.md). Même identité et cadre que le concept v3 ; données fictives. Discord doit rester visiblement non configuré. Ces propositions ne modifient pas les règles de calcul ni les limites Forever.
Aperçu fonctionnel hors jeu : [guide](../../../demo/README.md), utilisant le même socle Lua que les futurs appels du client. Les contrôles, listes et valeurs sont dynamiques ; les ressources natives et la fidélité visuelle exacte restent ouvertes. [Tests et différences connues](../../testing/offline-core.md).
Atelier de partage ajouté en version 0.2.0 : deux registres simulés, rattrapage, doublons et conflits conservés sans double récompense. Protocole logique et fusion testés en Lua ; aucun transport réel Forever. [Périmètre et politique provisoire](offline-sync.md), [tests](../../testing/offline-sync.md).
Version 0.3.0 : exporteur Lua de démonstration, relais Python, file persistante et aperçu des formats Discord. Le relais est désactivé par défaut ; les exports fictifs sont refusés par la commande d'envoi réel. Aucun export du jeu, salon ou webhook actif. [Périmètre](offline-discord.md), [guide](../../../bridge/README.md), [tests](../../testing/offline-discord.md).

## Questions ouvertes

- Q-001 résolue : prime symbolique, confirmation utilisateur du 4 novembre 2026. Points de vengeance distincts de la prime ennemie.
- Q-002 actualisée : maquette et interface demandées explicitement après le choix initial de développement direct.
- Q-003 : déclenchement uniquement sur mort PvP ou aussi attaques sans mort ? Proposition initiale : morts PvP.
- Q-004 : barème, récidive, expiration et clôture des contrats ; distinguer victimes et incidents afin de limiter le farming.
- Q-005 : déclaration manuelle, corrections et droits des officiers ?
- Q-006 différée à la sortie : l'utilisateur indique que le jeu n'est pas encore sorti et fournira sa version plus tard. Ne pas exiger de test en jeu pour avancer sur la maquette. Les sources consultées restent de la documentation, pas une preuve de disponibilité publique ni de fonctionnement.
- Q-007 : attribution en groupe, clôture de plusieurs incidents lors d'une seule vengeance et barème des points ; proposition initiale ci-dessus.
- Q-007a : politique provisoire des revendications concurrentes dans le simulateur : conserver toutes les versions et suspendre les récompenses des revendications en conflit, sans appliquer une revendication partiellement. L'arbitrage d'officier reste ouvert.
- Q-008 : forme des remerciements (message privé, réaction interne ou autre) et réception des notifications hors ligne.
- Q-009 : Discord — salon, catégories, mentions éventuelles et mode de relais externe. Aucun webhook créé, aucun secret demandé ni message envoyé. Ne pas promettre un envoi instantané depuis l'addon. Les canaux d'export et leur délai restent à vérifier sur Forever.

## Livraison

REQ-022 — Repeaufiner les boutons et ascenseurs dans la charte parchemin/cuir/bronze/rouge, priorité aux contrôles. Conserver la disposition acceptée, ajouter des états lisibles et un défilement par curseur cohérent avec molette/flèches. [Réalisation et preuves](../../testing/buttons-polish.md).

REQ-021 — Jeu de données demandé par l'utilisateur, choix « Tout » (interface, partage et remerciements à deux). Fournir des incidents/vengeances fictifs, des résultats attendus et un mode partagé explicitement activé, avec registre, données sauvegardées, réputation et préfixe réseau séparés du mode normal. Permettre sortie/reprise/effacement du test sans réattribuer de vrais événements ni points. Les commandes de simulation ne constituent pas une validation manuelle des vengeances réelles : l'exigence de preuve automatique reste intacte. [Scénario](../../testing/jeu-de-test.md).

Le cadrage n'est pas une validation de faisabilité. La livraison exige des tests de détection, partage, doublons, reconnexion, classement et interface sur Forever ; les fonctions indisponibles devront être signalées et discutées.
