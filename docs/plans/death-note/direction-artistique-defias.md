# Death Note — registre défias

> Document historique du concept v2. Pour l'identité courante, lire [Le Syndicat Rouge](identite-syndicat-rouge.md). Les références textuelles à la faction mentionnée ci-dessous sont désormais exclues du produit ; seul le style de registre clandestin reste retenu.

## Choix utilisateur

Disposition retenue : première maquette « Registre de chasse ». Liste des ennemis à gauche, dossier détaillé à droite. Direction demandée : mafia / confrérie défias, parchemin, notes manuscrites, prime détaillée, portraits race/classe, niveau, carte et tampon de vengeance. Le rendu révisé est un concept, pas encore une validation finale de l'apparence.

## Composition du concept

- Reliure de cuir sombre, renforts de fer et accent de tissu rouge ; ne pas encombrer les contrôles.
- Feuilles ivoire usées, encre brune, rouge sombre pour les contrats et tampons.
- Titres et noms à l'écriture manuscrite ; petits textes, chiffres, lieux et dates avec une police très lisible.
- Navigation : Recherchés, Vengeurs, Journal, Notifications.
- Liste compacte : portrait, nom, race/classe, niveau, dernière zone et prime symbolique.
- Dossier : avis de recherche, grand portrait, classe, niveau, prime de recherche et récompense en réputation.
- Deux encarts dans le bas du dossier : carte du dernier meurtre connu et historique des incidents.
- Tampon « Vengé » sur l'incident clôturé. Une fiche ennemi n'est entièrement vengée que lorsqu'aucun incident à venger ne subsiste ; ne pas estampiller globalement un ennemi ayant encore des victimes non vengées.
- Notification personnelle avec nom du vengeur et action volontaire de remerciement.
- Ajout demandé après le concept v2 : marqueur au-dessus du pseudo en jeu d'un joueur recherché. Proposition : petit emblème défias rouge, accompagné de « +3 réputation » selon les incidents encore ouverts. Lisible sans masquer le nom, la barre de vie ou les marqueurs existants. Affichage local à chaque membre équipé, ancré à une plaque visible si Forever le permet. La récompense et le marqueur doivent être actualisés à la synchronisation et à la clôture des incidents. Cet élément ne figure pas encore sur l'image v2.

## Sémantique de la réputation

La prime mesure les méfaits de l'ennemi. La réputation récompense les membres qui vengent la guilde. Ce sont deux valeurs distinctes.
Base de travail : 1 réputation par incident encore ouvert clôturé. Exemple de maquette : trois incidents ouverts donnent +3 réputation ; un ancien incident vengé n'entre pas dans ce calcul. Les règles de groupe et la résolution de deux revendications simultanées restent à préciser.
Il s'agit de réputation interne à l'addon. Aucun effet sur les factions Blizzard et aucun or. Aucune fonction de dépense, transfert ou boutique n'a été demandée.

## Carte et portraits

Le concept utilise une carte et des portraits illustratifs. Les lieux, heures, niveaux, races et classes affichés sont fictifs.
En production : utiliser les cartes du client Forever avec leurs coordonnées de carte vérifiées. Le marqueur est le lieu enregistré du dernier meurtre connu, pas la position en temps réel de la cible. Ne pas inventer une coordonnée quand seule la zone est connue.
Les portraits peuvent être des images génériques de race et de classe ; ne pas promettre une représentation exacte de l'apparence du joueur distant.

## Plan d'assets pour une future interface Lua

Prévoir séparément : texture du parchemin, cadre/reliure, emblème rouge, tampon transparent, icônes et portraits de substitution vérifiés. Les textes, lignes d'incidents, cartes et zones cliquables doivent rester dynamiques et utilisables, sans transformer l'interface entière en image figée.
Après validation de la direction, conserver l'image acceptée comme référence et comparer le rendu Lua avec elle avant de déclarer une correspondance visuelle. Les polices et textures réellement disponibles/licenciées restent à sélectionner.

## Vérification

Concept généré avec l'outil de création d'images intégré, enregistré dans [death-note-defias-v2.png](assets/death-note-defias-v2.png). Contrôle visuel effectué : disposition liste/dossier conservée, portrait orc guerrier et niveau visibles, carte illustrative avec marqueur et heure, récompense +3 réputation pour trois incidents ouverts, tampons et notification avec remerciement. Les personnages secondaires ont été réinterprétés par la génération et restent des exemples fictifs ; ce rendu ne fixe pas leur race/classe pour la production.
Prototype initial : navigation et états simulés, pas une preuve de prise en charge Forever. Tests en jeu reportés à la disponibilité du client selon l'utilisateur.

## Prompt de direction utilisé (synthèse fidèle)

Maquette française d'addon WoW Forever, nom DEATH NOTE, disposition Registre de chasse avec liste à gauche et dossier à droite. Registre clandestin défias : parchemin ivoire, encre sépia, reliure cuir, fer et tissu rouge ; titres manuscrits lisibles. Portrait orc guerrier niveau 60, prime 7 et récompense +3 réputation pour trois incidents ouverts. Carte illustrative de Strangleronce avec marqueur historique vers Grom'gol, heure et victime. Historique avec trois incidents à venger et un incident clôturé tamponné VENGÉ. Notifications et remerciement volontaire. Interface entière visible de face, sans décor de jeu, aucune monnaie en or. Le prompt détaillé figure dans l'appel de génération de cette conversation.
