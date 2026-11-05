# Cartes du client Forever — 5 novembre 2026

Demande : remplacer l'illustration par les vraies cartes du client, sans changer la composition acceptée.

- Ajouter `UI/Map.lua` : lecture de C_Map.GetMapInfo/GetMapArtLayers/GetMapArtLayerTextures, assemblage des tuiles, cadrage proportionnel et marqueur normalisé. Pas de carte inventée si les API ou le mapID sont indisponibles ; pas de marqueur sans coordonnées.
- Remplacer l'image illustrative dans Views.lua, conserver la zone et la date du dernier incident. Les cartes sont lues depuis le client, jamais copiées dans le dépôt.
- Adapter seulement le compagnon de démonstration : résoudre les zones des exemples dans l'arbre des cartes du client via GetFallbackWorldMapID/GetMapChildrenInfo ; ne pas supposer que les anciens identifiants sont ceux de Forever. Coordonnées des exemples toujours signalées comme fictives.
- Tester tuiles de bord, ordre lignes/colonnes, changement de cible, absence d'API/carte/coordonnées et réutilisation des textures. Reconstruire, installer avec sauvegarde, publier. Validation visuelle réelle à effectuer après rechargement par l'utilisateur.

Source : Gethe/wow-ui-source `eac30af597e5aaa43a60f6675ef5fdcea100375f`, version 1.60.1.70790 correspondant à Wow.exe installé. Contrats dans Blizzard_APIDocumentationGenerated/MapDocumentation.lua ; index des tuiles confirmé dans Blizzard_MapCanvas/Blizzard_MapCanvasDetailLayer.lua. Chargement du canevas via Blizzard_WorldMap_Mainline.toc : fichiers Camelot autorisés pour camelot. Le composant utilise directement les API natives C_Map, sans reprendre le canevas global ou charger ses fournisseurs.

Restrictions : arguments publics issus du registre, aucun accès à une unité ennemie, aucune modification de WorldMapFrame, aucun suivi de position actuelle. La marque indique uniquement le dernier incident enregistré. Pas d'exploration/fog-of-war ajoutée dans cette tranche.
