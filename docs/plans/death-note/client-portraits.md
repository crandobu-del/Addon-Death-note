# Icônes du client — 5 novembre 2026

Demande : supprimer les images IA des personnages ; utiliser les ressources du client Forever pour la race, le sexe connu et la classe. Conserver le cadre accepté. Choix : icône de race et vignette de classe, pas de portrait prétendant reproduire l'apparence exacte d'un joueur hors de vue.

Ajouter UI/Portrait.lua, conserver raceID/classID/sex (male/female) comme métadonnées optionnelles validées dans les acteurs et le lecteur du relais. Résoudre les noms de fichiers via C_CreatureInfo ; vérifier l'existence de chaque atlas via C_Texture.GetAtlasInfo avant SetAtlas. Sans sexe connu, aucune silhouette sexuée inventée : icône de classe uniquement. Aucun fichier Blizzard copié ni ressource IA de personnage chargée. Exclure Portraits.tga du paquet.

La capture utilisateur prouve aussi l'échec de la résolution de la carte, pas un échec des textures : étendre la recherche du compagnon aux parents de la carte du joueur, aux enfants directs et aux alias exacts de zone. Ne jamais reprendre des coordonnées d'une zone différente.

Sources Forever 1.60.1.70790, commit eac30af597e5aaa43a60f6675ef5fdcea100375f : CreatureInfoDocumentation.lua (GetRaceInfo/GetClassInfo), TextureUtilsDocumentation.lua (GetAtlasInfo), SimpleTextureBaseAPIDocumentation.lua (SetAtlas, bool useAtlasSize explicite), PortraitFrame.lua (texture UI-Classes-Circles et CLASS_ICON_TCOORDS). Les ressources de création de personnage Camelot confirment l'utilisation des atlas du client, mais ses fonctions Glue ne seront pas appelées en jeu. Les identifiants d'atlas sont vérifiés à l'exécution, leur présence visuelle reste à valider dans le client.

Tests : sexe masculin/féminin/inconnu, classe, atlas absent, réutilisation sans ancien portrait ; conservation/restauration des champs ; lecteur Discord ; recherche de carte depuis une autre racine, alias et absence/ambiguïté. Installer avec sauvegarde et demander /reload pour vérifier dans le jeu ; ne pas annoncer de validation visuelle non observée.
