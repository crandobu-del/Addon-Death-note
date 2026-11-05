# Message personnel de mort — diagnostic ciblé

Phrase fournie : `Vous avez été tué par "JoueurX"`, visible selon l'utilisateur dans Général et Journal de combat. Cette observation ouvre une piste distincte du journal restreint, sans prouver que le texte soit accessible à un addon.

Source Forever 1.60.1.70790, commit eac30af597e5aaa43a60f6675ef5fdcea100375f : ChatInfoDocumentation.lua déclare CHAT_MSG_SYSTEM (SecretInChatMessagingLockdown=true) et CHAT_MSG_COMBAT_MISC_INFO. PLAYER_DEAD est sans payload d'auteur. Le test écoutera uniquement ces deux événements de chat et la mort personnelle, pendant une activation explicite. Aucun COMBAT_LOG_MESSAGE, hook de fenêtre ou accès interne.

Ajouter au compagnon ChatDeathProbe.lua et /srchat. Vérifier issecretvalue avant toute opération sur le texte ; si le garde est absent/échoue ou la valeur est protégée, ne pas lire. Rejeter les enveloppes |K/|k. Reconnaître seulement la phrase entière, les variantes de guillemets et les liens publics player dont cible et libellé concordent. Aucun chat libre/guilde/chuchotement, aucun décodage protégé. Ne conserver que quelques candidats reconnus, temporairement en mémoire et cinq secondes autour de PLAYER_DEAD. Le nom reste candidat, pas preuve PvP pour une chaîne simple ; aucune prime/réputation créée.

Tester texte exact, accents, guillemets, point final, liens normaux, texte protégé, faux format, secret non converti, corrélation avant/après mort, délais, doublons, ambiguïtés et nettoyage. Installer, puis demander un bilan après une occurrence réelle. La correspondance de texte hors jeu n'est pas une validation de la réception dans Forever.
