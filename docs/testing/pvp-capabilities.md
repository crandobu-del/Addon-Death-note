# Capacités PvP — première tranche

Date : 5 novembre 2026. Cible : Forever uniquement. Wow.exe installé : 1.60.1.70790. Source épinglée identique : `eac30af597e5aaa43a60f6675ef5fdcea100375f`.

## Ce que les sources établissent

- PLAYER_DEAD signale la mort du personnage mais ne porte pas d'identité d'attaquant dans DeathInfoDocumentation.lua.
- C_CombatLog.IsCombatLogRestricted est une requête publique renvoyant un booléen. Elle ne constitue ni une preuve de livraison d'événements ni une permission générale d'utiliser les accès internes.
- COMBAT_LOG_EVENT_UNFILTERED est déclaré HasRestrictions et CallbackEvent. Le diagnostic constate sa validité/catégorie mais ne s'abonne pas à cette voie et ne lit aucun événement de combat.
- C_CombatLogSecure est SecureOnly. Le processeur Blizzard qui l'utilise charge un environnement sécurisé, uniquement pour mainline. Aucun accès repris dans l'addon.
- Le getter de récapitulatif C_DeathRecap ne fournit pas de structure exploitable dans sa déclaration générée ; la fenêtre Blizzard correspondante est chargée pour mainline et pas explicitement pour camelot. Son existence ne prouve donc pas un moyen fiable d'attribution dans Forever.
- Les accès C_CombatLogInternal et les chaînes protégées du journal affiché ne sont pas utilisés comme solution de remplacement.

Chemins : Blizzard_APIDocumentationGenerated/{DeathInfo,CombatLog,EventUtils,CombatLogSecure,CombatLogInternal,DeathRecap}Documentation.lua ; Blizzard_CombatLogProcessor/Blizzard_CombatLogProcessor.toc ; Blizzard_DeathRecap/Blizzard_DeathRecap.toc. Ces constats de source restent distincts du comportement du client.

## Diagnostic installé

Module `dev/SyndicatRougeDemo/PvpProbe.lua`, présent seulement dans le compagnon de développement. Aucune activation automatique. Les commandes sont locales et n'envoient pas de message à la guilde :

- `/srpvp debut` : vérifie la cible avec WOW_PROJECT_CAMELOT, relève les métadonnées de build et les capacités ; tente uniquement les abonnements ordinaires PLAYER_DEAD, PLAYER_ALIVE, PLAYER_REGEN_DISABLED et PLAYER_REGEN_ENABLED.
- `/srpvp` : réaffiche les résultats et échantillonne la restriction si la session est active.
- `/srpvp fin` : arrête et nettoie les abonnements.

Les réceptions comptent des événements, sans consulter leurs arguments. Une mort observée peut être PvE, PvP ou environnementale. Aucune attribution, prime, réputation, identité, GUID, montant de dégâts ou position n'est enregistrée. Le getter de combat historique est testé pour sa présence seulement, jamais appelé. Une valeur secrète issue de la requête de restriction est marquée protégée, sans comparaison ou conversion de son contenu.

Le rapport est une nouvelle SavedVariables `SyndicatRougePvpProbe` du compagnon, séparée de l'audit des cartes. Sa persistance réelle après redémarrage reste à vérifier, en particulier au vu de la difficulté rencontrée avec le premier rapport des cartes. Un redémarrage complet peut être nécessaire pour prendre en compte cette nouvelle déclaration. Le bilan dans le chat permet la première vérification sans dépendre de sa conservation sur disque.

## Tests et limites

`node tools/test-native.mjs` : 16 contrôles propres au diagnostic passés. Ils vérifient activation explicite, cible, distinction présence/opération, abonnement et livraison séparés, absence d'abonnement restreint, absence d'appel au getter, compteur sans inférence de tueur, réinitialisation, arrêt, absence d'API, valeurs protégées, erreurs et autre client. Total Lua de cette version : 119 contrôles, dont 39 moteur. Archives natives reconstruites, deux fichiers installés et vérifiés par empreinte, originaux conservés sous dist/client-backups/pvp-probe-*.

Profil réel non isolé : les autres addons n'ont pas été désactivés par l'agent. Aucun test de mort ou combat automatisé. L'utilisateur a été invité à lancer `/reload` puis `/srpvp debut` et à fournir les lignes du bilan. Résultat réel en attente ; aucune réussite de détection ni attribution au tueur n'est annoncée.

La suite dépend de ce retour. Si l'identité n'est pas accessible par un contrat autorisé et vérifiable, une première version peut proposer des signalements manuels clairement distingués ; elle ne doit pas attribuer automatiquement le dernier attaquant supposé.
