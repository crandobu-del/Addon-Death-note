# Deuxième tranche — partage de guilde hors jeu

Autorisation : « ok la suite », après livraison du socle et de l'aperçu. Continuer sur la branche existante. Cible réelle inchangée : WoW Forever ; aucun appel réseau du client ne sera inventé dans cette tranche.

## Livrable

Modules Lua de protocole et de fusion, tests à deux registres et page de simulation avec Lÿra et Kaëlan. Un transport réel devra ensuite associer les envois à un expéditeur vérifié et à la liste de guilde du client. Le simulateur passe ces informations explicitement ; ce n'est pas une authentification en jeu.

## Politique provisoire de conflits

Une même mort peut être diffusée plusieurs fois sans être recomptée. Des contenus différents sous le même identifiant entraînent un rejet atomique du message.
Deux revendications distinctes portant sur un même incident sont toutes deux mises en attente, sans crédit de réputation pour cet incident. Les revendications complètes en conflit sont retenues sans être appliquées partiellement. Le résultat est identique quel que soit l'ordre d'arrivée. Une récompense locale peut donc redevenir provisoire après découverte d'un conflit ; cela doit être annoncé visiblement.
Il n'y a pas de décision automatique par horloge, priorité d'expéditeur ou premier message reçu. L'arbitrage d'officier reste à définir et n'est pas simulé comme disponible.

## Frontières

- Ne partager que les incidents et les revendications de vengeance, pas les états de lecture, préférences ou remerciements personnels.
- Vérifier version, guilde, expéditeur annoncé et expéditeur fourni par le transport, appartenance au roster et identités des victimes/vengeurs.
- Ne pas confondre appartenance à la guilde et preuve qu'un combat a réellement eu lieu.
- Borne de démonstration : 128 incidents et 128 revendications, avec budget de taille logique de 128 Kio par enveloppe ; dépasser la borne doit produire une erreur explicite. Compression, découpage en messages du client et pagination restent hors périmètre.
- Le rattrapage de cette tranche échange un état complet borné ; les revendications en attente sont également retransmises pour éviter d'oublier les conflits.
- Les fixtures restent hors du dossier addon ; aucun message de guilde ou Discord réel n'est émis.

## Vérification

Tests : diffusion/rattrapage, doublons, ordre d'arrivée, conflit d'identifiant, revendications concurrentes, message partiellement invalide, guilde/expéditeur/roster incorrects, limite de taille, restauration des revendications en attente et confidentialité des états personnels. Parcours navigateur : deux registres divergents, synchronisation, même classement, conflit affiché et reset.
