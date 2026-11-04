# Onglets du Syndicat Rouge — concepts visuels

## Référence commune

Référence : [identité courante, concept v3](assets/death-note-syndicat-rouge-v3.png).
Conserver DEATH NOTE, Le registre du Syndicat Rouge, Le Syndicat Rouge, WoW Forever, le repère MAQUETTE, la reliure de cuir, le parchemin, les accents rouges, les titres et noms manuscrits lisibles. Aucune référence textuelle à une autre faction. Données fictives, pas un addon fonctionnel.

## Vengeurs

Liste classée à gauche avec rang, portrait, membre, réputation et nombre de membres distincts vengés. Fiche du membre sélectionné à droite : portrait, classe/niveau, réputation cumulée et dernières vengeances. Base d'exemple : Kaëlan 18 réputation / 12 membres vengés, Lÿra 12 / 8, Thörin 9 / 6, Maëlys 5 / 4.
Afficher la règle : 1 réputation par incident vengé ; aucun double comptage d'un incident clôturé. Ces valeurs cumulées ne découlent pas des seuls incidents récents visibles.

## Journal

Chronologie partagée des attaques et vengeances, avec date/heure, acteurs, lieu et état. Filtres de présentation Tout / Attaques / Vengeances proposés. Les entrées clôturées restent dans l'historique et affichent un tampon VENGÉ. Exemple : mort de Lÿra contre Brisecroc à 20:14, vengeance par Kaëlan à 20:42.
Ne pas présenter le journal comme une preuve de qui a commencé un combat : les événements exacts restent à vérifier sur Forever.

## Notifications

Boîte personnelle à gauche : vengeance avec nom du vengeur, ennemi et incident concerné, action de remerciement volontaire ; puis nouvelles recherches et hausses de prime. Réglages proposés à droite : catégories d'alertes personnelles et catégories Discord de la guilde. Discord doit apparaître « Non configuré » et « Relais externe requis », car aucune intégration n'est active. Les autorisations de modification des réglages collectifs restent à définir.
L'action de remerciement est une intention d'interface, pas un message envoyé.

## Réalisation

Trois images distinctes demandées avec l'outil de création d'images intégré, en prenant le concept v3 comme référence. Elles explorent l'apparence ; les interactions, données réelles, synchronisation et restrictions Forever n'ont pas été testées.

Images réalisées et inspectées :
- [Vengeurs](assets/death-note-vengeurs-v1.png) : onglet actif correct, tableau et valeurs conformes, fiche membre et dernières vengeances visibles. La génération a ajouté un tampon décoratif sur le classement ; en production, réserver VENGÉ aux incidents clôturés, pas aux membres du classement.
- [Journal](assets/death-note-journal-v1.png) : chronologie, filtres et correspondance 20:14 / 20:42 lisibles, bonne identité et tampon de vengeance.
- [Notifications](assets/death-note-notifications-v1.png) : notification personnelle, remerciement et catégories d'alerte visibles ; Discord clairement non configuré. Les cases cochées sont des choix fictifs de la maquette, pas des envois autorisés ou une configuration existante.

Toutes trois préservent le cadre et le nom Le Syndicat Rouge, sans référence textuelle à une autre faction. Il s'agit de concepts statiques à soumettre au retour utilisateur, pas d'une validation visuelle d'une interface Lua.

## Prompts utilisés — synthèse

Base commune : maquette française paysage de l'addon, conserver exactement le cadre et l'identité visuelle du concept v3 ; remplacer le contenu principal et activer le bon onglet. Parchemin, cuir, fer, rouge, titres manuscrits et texte de lecture net. Pas de référence textuelle aux Défias. Pas de boutique ni de fonctionnalités de jeu inventées.
Vengeurs : tableau de quatre membres avec les valeurs ci-dessus, Kaëlan sélectionné et dernières vengeances dans sa fiche.
Journal : quatre événements 21:06, 20:51, 20:42 et 20:14, chronologie inversée et relation entre mort et vengeance de Lÿra.
Notifications : notification « Tu as été vengée ! », bouton « Remercier Kaëlan », liste d'alertes et réglages incluant Discord non configuré.
Les prompts détaillés sont conservés dans les trois appels de génération de cette conversation.
