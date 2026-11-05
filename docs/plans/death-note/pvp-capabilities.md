# Première vérification PvP Forever — 5 novembre 2026

Objectif autorisé : déterminer si une mort réelle peut être attribuée à un joueur de façon fiable. Cette tranche vérifie les capacités ; elle ne déclare pas la détection automatique implémentée.

Client installé : Wow.exe 1.60.1.70790. Source exacte : Gethe/wow-ui-source eac30af597e5aaa43a60f6675ef5fdcea100375f. DeathInfoDocumentation.lua expose PLAYER_DEAD sans argument d'auteur. CombatLogDocumentation.lua marque COMBAT_LOG_EVENT_UNFILTERED HasRestrictions=true et CallbackEvent=true. C_CombatLog.IsCombatLogRestricted()->bool est une requête publique. EventUtilsDocumentation.lua permet IsEventValid/IsCallbackEvent(eventName)->bool.

Ne pas substituer C_CombatLogSecure (Environment=SecureOnly), appeler les accès internes, extraire les chaînes protégées |K du journal affiché, ou traiter le dernier attaquant/cible comme une preuve du tueur. Le processeur de journal est sécurisé et AllowLoadGameType mainline ; ce n'est pas une preuve de disponibilité pour Camelot. La fenêtre DeathRecap est aussi AllowLoadGameType mainline, et son schéma généré DeathRecapEventInfo est vide : aucune lecture de son contenu retenue pour Forever.

Implémentation prévue : module de diagnostic dans le compagnon uniquement, commande /srpvp. Il enregistre métadonnées de build/projet, présence des API, statut de restriction, validité/catégorie des événements. Il peut souscrire PLAYER_DEAD/PLAYER_ALIVE/PLAYER_REGEN_DISABLED/PLAYER_REGEN_ENABLED et compter les réceptions ; il ne collecte aucun payload, nom, GUID, dégât ou position. Aucun abonnement au journal restreint, aucune lecture du getter de combat, aucun recours à une voie interne. Les tests vérifient aussi le nettoyage des abonnements et l'absence d'inférence de tueur.

Le diagnostic ne doit pas partir tout seul. /srpvp debut démarre une session explicite ; /srpvp affiche le bilan local dans le chat ; /srpvp fin arrête les abonnements. Une nouvelle SavedVariables du compagnon conserve les seules observations techniques ; redémarrage complet requis pour vérifier sa prise en compte. Aucun envoi aux autres joueurs ou à Discord.

Critère suivant : résultat réel du diagnostic puis, si l'accès documenté le permet, un scénario PvP réalisé par l'utilisateur. Une souscription ou un compteur de mort ne prouve jamais l'accès à l'identité du tueur. En cas de restriction, prévoir un signalement manuel clairement identifié plutôt qu'une attribution automatique inventée.
