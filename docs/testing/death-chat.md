# Test ciblé du message personnel de mort

## Retour réel du Goulet des Chanteguerres — 6 novembre 2026

Captures transmises par l'utilisateur après des morts en champ de bataille : diagnostic actif, **2 morts observées**, **0 candidat associé**. `CHAT_MSG_SYSTEM` : abonnement `registered`, 19 réceptions, 0 reconnu, 19 protégés. `CHAT_MSG_COMBAT_MISC_INFO` : abonnement `registered`, 0 réception, 0 reconnu, 0 protégé. Dernier résultat : `chat_message_protected`. Aucun incident ni point créé.

Le compteur « protégés » additionne les valeurs secrètes et les textes contenant une enveloppe `|K`/`|k` ; ce bilan ne permet pas de distinguer les deux. Le code refuse ces entrées avant de rechercher une identité. Il ne s'agit donc pas d'un simple échec du motif de phrase pour les 19 messages reçus. La capture du journal de combat affiche des dégâts de plusieurs attaquants et « [Vous avez succombé.] » ; elle ne présente pas la phrase nominative attendue et ne prouve pas lequel a porté le coup fatal.

Conclusion limitée à cette session : mort détectée, attribution du tueur non validée par les deux événements testés. Aucune conclusion générale sur les messages hors champ de bataille ou sur toutes les API Forever ; aucun contournement par lecture de cadres, décodage de noms protégés ou dernier attaquant supposé. Le diagnostic de preuve de kill `/srkill` reste un test indépendant, à relever après un kill ennemi si l'utilisateur en a l'occasion. Pas de modification de code, de paquet ou de publication pour ce seul retour.

Retour utilisateur suivant : capture du message d'aide initial, donc aucune session de chat diagnostiquée active à cet instant. La commande exacte saisie et un éventuel rechargement antérieur ne sont pas connus ; ce n'est pas une preuve d'échec de lecture du message de mort. La commande accepte maintenant début/debut, majuscules et espaces de bord ; elle affiche un avertissement distinct pour un argument inconnu et précise qu'il faut réactiver après rechargement. Trois contrôles de commande ajoutés (22 tests du module), passés. Le fichier installé est sauvegardé, remplacé et vérifié. Le prochain résultat attendu est d'abord « test du message : actif », avant toute occurrence réelle.

Phrase fournie par l'utilisateur : `Vous avez été tué par "JoueurX"`. Il rapporte qu'elle apparaît dans Général et Journal de combat. Son événement d'origine, sa provenance Blizzard/serveur/autre addon, sa lisibilité en contexte et sa corrélation avec une mort réelle ne sont pas encore observés par l'agent.

Module ajouté au compagnon seulement : ChatDeathProbe.lua. Aucun abonnement à COMBAT_LOG_MESSAGE ni au journal restreint ; aucune lecture de cadre ou de chaîne protégée par une autre voie. Les événements testés sont CHAT_MSG_SYSTEM, CHAT_MSG_COMBAT_MISC_INFO et PLAYER_DEAD. Le premier est déclaré SecretInChatMessagingLockdown dans ChatInfoDocumentation.lua au commit Forever eac30af597e5aaa43a60f6675ef5fdcea100375f ; sa présence dans le chat n'implique donc pas qu'il soit toujours lisible.

Avant toute inspection, le module exige issecretvalue et refuse les valeurs secrètes ou un garde absent/en erreur. Il rejette les enveloppes |K/|k, ne les décode pas. Pour un texte ordinaire, le parseur accepte la phrase entière, des guillemets droits/français, la ponctuation finale et des liens player publics dont cible et libellé concordent. Il ne prend ni les canaux de guilde ni les chuchotements ni les messages ordinaires des joueurs.

Les seuls candidats conservés sont des noms reconnus et leur source, dans une mémoire de session bornée. Leur fenêtre de corrélation avec PLAYER_DEAD est de cinq secondes, avant ou après. Les passages par deux événements sont dédupliqués ; des noms concurrents donnent un résultat ambigu. Une chaîne simple peut désigner un PNJ : ce n'est pas à elle seule une preuve PvP. Aucun registre, incident, point ou message extérieur n'est créé ; les textes bruts et noms candidats ne sont pas écrits dans SavedVariables.

Vérification locale : 19 tests ajoutés et passés pour le texte utilisateur, accents, guillemets, liens ordinaires, lien incohérent, autre type de lien, faux préfixe, nom non valide, wrapper protégé, valeur secrète, garde absent, allowlist, corrélation avant/après mort, délai, doublons, ambiguïté et arrêt. Total Lua de cette version : 138 contrôles. Cela prouve le comportement sur des entrées synthétiques, pas la réception du message dans Forever.

Les archives sont reconstruites ; ChatDeathProbe.lua et le TOC du compagnon sont installés avec sauvegarde et comparaison d'empreinte. L'installation du jeu n'est pas déclarée validée après ce changement.

## Test réel à effectuer lors d'une occurrence normale

1. `/reload`, puis `/srchat debut` pour activer le diagnostic.
2. À la prochaine mort PvP rencontrée pendant le jeu, observer le message. Aucune action de combat n'est automatisée et il n'est pas nécessaire de provoquer une mort pour ce test.
3. Sans recharger entre-temps, `/srchat bilan` et transmettre le bilan : source d'événement, compteurs reçus/reconnus/protégés, résultat et nom candidat éventuel.
4. `/srchat fin` arrête l'écoute. Le bilan de session reste visible jusqu'au rechargement ; aucune conservation de noms n'est attendue après celui-ci.

La suite dépend de cette observation. Un compteur nul peut signifier un autre événement, un autre format ou un message ajouté uniquement à l'affichage ; il ne démontre pas une interdiction globale. Un texte protégé reste exclu. Une reconnaissance positive sera encore à vérifier pour distinguer joueur/PNJ, identité inter-royaume et preuve fiable de l'incident avant automatisation.
