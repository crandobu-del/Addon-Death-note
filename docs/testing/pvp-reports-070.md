# Rapports de morts PvP — 0.7.0-dev

Demande du 6 novembre 2026 : intégrer une collecte et un partage progressif inspirés des mécanismes de HeadHunter, sans remplacer l'addon. Base Git `8a24247`, avec correctif 0.6.1 déjà présent et conservé. Interface directe autorisée antérieurement ; quatre onglets et direction artistique conservés.

## Analyse et compatibilité

- Cible unique : **Forever 1.60.1.70790 / interface 16001**, source Gethe/wow-ui-source branche forever résolue le 6 novembre au commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`.
- Source de référence HeadHunter : branche main résolue à `bb83c4bfb37d6c382e31591cd2e00ccf4d02c836`. `Detection/ForeverDeaths.lua` confirme le mécanisme récapitulatif différé, GUID/cache et overkill >= 0. Code original écrit pour notre architecture, sans copier son implémentation. Les suppositions de propriétaire par proximité/classe et de dernière cible ne sont pas reprises.
- `DeathRecapDocumentation.lua` déclare `C_DeathRecap.HasRecapEvents()` et `GetRecapEvents()` dans All. Les champs d'entrée restent non documentés dans la structure générée : chaque champ utilisé est protégé par un garde et un contrôle de fraîcheur. Leur disponibilité réelle doit être vérifiée dans le jeu.
- `CombatLogDocumentation.lua` déclare CLEU restreint et événement callback sur cette révision. Aucune souscription à une route callback de frame ni lecture de journal restreint. L'adaptateur CLEU est dormant tant que le client ne fournit pas explicitement un événement de frame non-callback et un journal non restreint. Aucune API interne/secure et aucune inspection du texte de chat protégé.
- `DuelInfoDocumentation.lua` déclare DUEL_REQUESTED, DUEL_TO_THE_DEATH_REQUESTED, DUEL_FINISHED et DUEL_INBOUNDS. Exclusion suivie par ces événements, avec cinq secondes de grâce après la fin pour l'ordre fin-duel/mort. Rechargement au milieu d'un duel à tester : aucune API publique d'état de duel n'est déclarée dans ce fichier ; on ne prétend pas reconnaître un état antérieur non observé.

## Détection et enregistrement

`Reports/Observer.lua` observe sur événements cible, survol, plaques et joueur. Cache 200 GUID, cinq minutes ; relations familiers 200, soixante secondes. Un propriétaire doit être établi par un token de familier ou une relation SPELL_SUMMON publique si le journal est autorisé. Un gardien de propriétaire inconnu reste inconnu. Aucune recherche globale permanente ni propriétaire supposé.

`Reports/Detector.lua` capture PLAYER_DEAD, identité de la victime, heure serveur et lieu au moment de la mort. Journal autorisé : seulement dégâts reçus par le joueur et invocations utiles, fenêtre 15 secondes/128 entrées. Récapitulatif : tentatives 0,3 / 1 / 2 secondes ; rejet des entrées protégées, anciennes et du récapitulatif déjà consommé, dont l'horodatage est conservé au rechargement.

- Coup fatal hostile contrôlé par joueur, overkill >= 0, sans ambiguïté : `confirmed` signifie **coup fatal identifié côté client**, jamais preuve serveur.
- PvP récent sans coup fatal identifié : `estimated` ; attribution impossible : `unknown`. Aucune prime créée pour ces deux catégories.
- PvE pur : ignoré. Un récapitulatif frais montrant une fin PvE est terminal, sans repli qui contredirait la décision.
- Monstre/chute après PvP : réglage initial **ignorer**, option **estimation seule** dans Rapports. Cette option ne désigne jamais un joueur avec certitude.
- BG/arène/duel, accès de guilde absent ou mode test : aucune collecte. Si toutes les preuves sont protégées/indisponibles, aucun auteur n'est inventé.

Le rapport contient un ID victime/heure/compteur persistant, date, victime, responsable facultatif, attaquants dédupliqués par GUID/propriétaire connu, source/confiance et contexte. Nom complet, niveau, race, classe, sexe, faction et guilde sont facultatifs. Carte/coordonnées ne sont prises que sur le joueur ; couche absente faute d'API vérifiée. Une identité observée plus tard enrichit le même ID et incrémente sa révision. Une identité partielle de récapitulatif ne suffit pas à rapprocher une prime régionale.

## Sauvegarde et confiance

Sous-sauvegarde `SyndicatRougeCharacterDB.pvpReports`, version 1 : `personal` et `shared`, paramètres et compteur. Les autres réglages, anciens registres et archives de test sont conservés. Format futur/invalide : conserver l'objet intact et lire les rapports en lecture seule. Valeurs initiales : 30 jours, 5000 rapports partagés, 1000 personnels. Le panneau propose 7/30/90 jours et 500/1000/5000 entrées ; les paramètres valides du schéma acceptent aussi d'autres limites entre 50 et 5000.

Formats, clés, nombres, identités, dates (fenêtre de rétention, +30 secondes maximum), doublons, tailles (8192 octets encodés par rapport), tableaux et fréquences sont contrôlés. Ces contrôles ne prouvent pas qu'un événement a eu lieu : un client modifié peut mentir.

Un rapport direct doit avoir pour victime l'expéditeur vérifié par le transport natif. Un relais reste `relay`, sans influence sur prime/classement/sanction. Seule une réponse de la victime d'origine passe à `author` ; ce choix est plus strict que le vote de plusieurs relais. La confirmation remplace tout le contenu du relais et n'authentifie jamais ses champs supplémentaires. Les anciens messages d'observation ne contournent pas cette règle : nouveau décès direct = victime/expéditeur ; nouvelle revendication = vengeur/expéditeur. Les anciens faits déjà connus sont conservés, leurs conflits restent rejetés.

Une attribution exacte **et** confirmée par l'auteur **et** munie d'identités canoniques complètes peut alimenter les primes existantes, une seule fois. Les estimations et rapports incomplets restent au Journal. La capacité locale du registre est 5000, indépendante des messages historiques limités à 128 éléments. Les rapports dérivés ne sont jamais exportés en union complète ; ils utilisent leur route paginée. Aucune preuve de vengeance réelle ni crédit automatique d'un kill n'est ajoutée par cette tranche.

Sans transport actif, une mort exacte du joueur peut également alimenter son registre personnel, sans envoi. Activer le partage matérialise ensuite le même ID dans le registre de guilde sans doubler la prime dans un même registre.

## Portée et rattrapage

Transport réutilisé : `C_ChatInfo.SendAddonMessage`, distribution **GUILD**, préfixes **SRGuild4 / SRGuildTest4**. Même version nécessaire chez tous. Aucune route personnalisée, PARTY, RAID ou WHISPER ajoutée. Les cibles logiques de messages restent des enveloppes sur GUILD, pas des chuchotements. Seuls les membres du Syndicat Rouge que Forever rend effectivement joignables par ce canal peuvent échanger. Les noms régionaux ou qualifiés par royaume suivent les conventions déjà validées. Pas de garantie inter-faction, inter-royaume, inter-groupe ni de livraison universelle/instantanée ; aucune passerelle Discord ou autre relais externe.

Après connexion avec partage activé : petite requête après 2–5 secondes ; offres décalées de 1–5 secondes ; collecte des offres sur 45 secondes pour tolérer le débit et les files. Au plus 16 offres examinées, **deux sources choisies**, quatre rapports/page et huit pages/source/session. Curseurs sauvegardés, suite différée de 30 secondes si un lot reste incomplet. Un parcours fini remet le curseur à zéro pour retrouver aussi les enrichissements et les ajouts tardifs au prochain parcours. Délai de page 90 secondes et trois tentatives ; absence de source/interruption : nouvelles tentatives bornées puis action manuelle.

Relais d'un original confirmé : **un saut**, expiration de l'enveloppe **120 secondes**, sans réémission d'un relais non confirmé. La confirmation de l'auteur a une file distincte de 64 demandes, trois tentatives décalées, durée dix minutes ; reconnexion réarme les rapports en attente. Les IDs de rapports et enveloppes évitent doublons et boucles. Une perte de paquet peut retarder le rattrapage ; aucune garantie de consensus serveur.

File logique 32 enveloppes/30 secondes, priorités contrôles/directs avant pages ; file native préexistante 1500 fragments maximum, émission un fragment/0,3 seconde. Messages complets : 12/10 secondes/expéditeur ; fragments : 60/10 secondes/expéditeur, 128 compteurs maximum. Caches de transferts, ACK et déduplication bornés. Après trois refus natifs temporaires, pause et reprise par **Synchroniser** : le clic tente directement un fragment en respectant toujours les gardes, puis poursuit si le client l'autorise. Le code d'acceptation ne prouve pas la réception.

## Interface et performances

Quatre onglets et boutons de la charte conservés. **Rapports** ouvre les seuls réglages utiles ; **Synchroniser** lance/reprend le partage. État compact en bas du tableau et diagnostic facultatif. Les rapports non projetés apparaissent dans Journal avec provenance et confiance. Pagination de 100 lignes, pool de 100 boutons par onglet. Pas de scan mondial ni de traitement lourd par image ; ordonnanceur 0,25 seconde, enrichissement par petits lots, index partagé trié réutilisé entre pages et projection tournante de huit dossiers. Nettoyage périodique borné. La collecte ne diffuse jamais les fixtures `/srtest` ou `/srdemo`.

## Vérifications

Suites : `node tools/test-lua.mjs` (72), `node tools/test-native.mjs` (base 255 + nouveaux cas de rapports), `node tools/test-reports-lifecycle.mjs` (clients Lua isolés, vrai format de fragments GUILD). Cas : PvP/PvE, fatal zéro, fin mixte/chute, familier/gardien connu ou inconnu, valeurs protégées, doublon, enrichissement, identité relayée forgée, faux expéditeur, renommage d'un incident, dates/format invalides, plafond plein/éviction, récapitulatif ancien/réutilisé, reconnexion, continuation >32 rapports, deux sources maximum, confirmation indépendante, file pleine/expiration, simulation, historique futur préservé et projection >128.

Revue indépendante : huit problèmes concrets corrigés, dont contamination d'identité de relais, répétition de récapitulatif, reprise de confirmation perdue, éviction, starvation de projection, repli PvE, ancien protocole et copies d'enrichissement. Contrôles de régression dédiés ajoutés.

Visuel : UIForever `https://uiforever.com/app?flavor=forever`, build annoncé 1.60.1.70450, jeu 1920×1080 / échelle 0,71. Aperçu `...preview2.zip`, guilde fictive uniquement dans la console du simulateur. Panneau corrigé pour éviter les chevauchements ; quatre onglets et charte conservés, onglet Errors sans erreur. Capture `screenshots/reports-settings-070.png`. Ajustement temporaire du viewport réinitialisé. Les dernières corrections non graphiques sont couvertes par les tests Lua ; le simulateur ne certifie pas les restrictions réelles ni les communications.

**Essais en jeu restants** : après `/reload`, ouvrir `/sr` puis Rapports, activer le diagnostic facultatif ; mourir en PvP monde ouvert et vérifier source/confiance/identité. Tester une mort purement PvE, une fin mixte dans les deux réglages, un familier/gardien, les exclusions BG/arène/duel (dont ordre des événements et rechargement en duel). Avec deux membres à jour, interrompre/reprendre le partage, se reconnecter pour le rattrapage et comparer les rapports confirmés. Vérifier les retours de refus et le clic Synchroniser si nécessaire. Aucun test de mort réelle, couche, inter-faction ou inter-royaume effectué par l'agent.

## Livraison locale

35 nouveaux scénarios de rapports passent ; total natif 290, moteur/transport 72, cycles existants et deux parcours multi-clients de rapports réussis. `git diff --check` passe. Sources et ordre TOC contrôlés ; chaque entrée des deux ZIP correspond aux sources. Installé le 6 novembre : 44 fichiers principaux + compagnon, empreintes après copie vérifiées, aucun WTF modifié. Sauvegardes `dist/client-backups/guild-transport-20261106-174257` et `dist/client-backups/guild-hunt-demo-20261106-174258`. Nécessite `/reload`.

Paquet principal SHA256 `ff6a6f9214edd7cd7c3b33ab8c5b7431c1894ff7a73faefc2e7d88d87bbbcc73` ; avec démo `b9069c4034f1e3f551c5f2a5016b4b4426a9a5872cd769f66c44efd1dc989a5b`. Archives `dist/SyndicatRouge-forever-0.7.0-dev.zip` et `dist/SyndicatRouge-forever-0.7.0-dev-avec-demo.zip`. Les previews sont conservées comme preuves visuelles et ne sont pas les paquets finaux. Suivi de publication dans `docs/releasing.md`.
