# Échanges Forever : recherche du 5 novembre 2026

## Correction du diagnostic précédent

L'utilisateur confirme `identité=ready`, `membre=own_guild_club` et `diagnostic envoi=realm_restricted` sur le client local. Cela établit le booléen public renvoyé par l'API, **pas un refus observé de SendAddonMessage** : notre boucle ne l'appelait jamais dans cet état. La conclusion donnée à l'utilisateur (« partage impossible sur le royaume ») était trop forte.

## Campkeeper : même indicateur, envoi et écho rapportés

Source primaire lue par le connecteur GitHub, commit épinglé `ef13a90864ebf4767366c7f6414230ebc2229ccb` :

- [Comm.lua](https://github.com/Vikquick/Campkeeper/blob/ef13a90864ebf4767366c7f6414230ebc2229ccb/Campkeeper/Comm/Comm.lua).
- [beta-checklist.md](https://github.com/Vikquick/Campkeeper/blob/ef13a90864ebf4767366c7f6414230ebc2229ccb/docs/testing/beta-checklist.md).
- [Publication 0.2.1](https://www.curseforge.com/wow/addons/campkeeper/files/9129067/additional-files), changelog concordant.

Le code lit InChatMessagingLockdown et AreOutgoingAddonChatMessagesRestricted mais `holds` ne met en attente que le verrouillage. Envoi via AceComm/ChatThrottleLib vers GUILD, PARTY/RAID et canal optionnel ; `/ck commtest` appelle directement l'API publique SendAddonMessage et compte les échos de son propre message. Aucun remplacement d'API sécurisée nécessaire à ce mécanisme.

Le journal de l'auteur indique le 10 octobre, build **70334**, 112 mesures où le drapeau restait vrai, alors que GUILD et CHANNEL renvoyaient Success et leur propre écho. Important : B3/B4/B5 (échanges entre deux personnes) restent non validés dans cette checklist. Il s'agit d'une observation d'un autre auteur sur un ancien build, pas d'une preuve sur notre build 70790 ni d'un test à deux réussi pour Tableau des primes.

## Autres mécanismes repérés

- [Smoke Signals Forever](https://www.curseforge.com/wow/addons/smoke-signals-forever) : l'auteur annonce un partage explicite au clic, même faction/zone, hors donjons et champs de bataille. Les [notes 0.10.2](https://www.curseforge.com/wow/addons/smoke-signals-forever/files/9095073/additional-files) décrivent canaux temporaires, relais et accusés par chuchotement ; publication liée au geste utilisateur. Code source de cet addon non inspecté ici ; ne pas transposer ses relais/identités à notre protocole.
- [LibDeltaSync](https://www.curseforge.com/wow/addons/deltasync) : l'auteur décrit Ace3/AceCommQueue, compression/deltas, synchronisation entre pairs. La note Forever de la fiche demande des chuchotements adressés au nom sans suffixe de royaume. Cela concerne l'adressage et ne prouve pas une levée de restriction. Source Lua de cette bibliothèque non inspectée ici.
- [DOINK](https://github.com/ryan-flan/DOINK) : documentation du projet lue. Export SavedVariables vers un compagnon Windows pour Discord, mode expérimental via affichage à l'écran. Ce trajet vers un service externe ne prouve aucune réception en jeu par un autre addon ; il n'est pas nécessaire pour essayer le canal de guilde normal.

## Suite fondée sur ces preuves

Ne pas déclarer le partage impossible sur la seule base du drapeau. Tester une opération publique bornée, déclenchée explicitement, avec payload synthétique sans incident/point, contrôle du verrouillage du chat et des valeurs protégées, retour d'envoi distingué de l'écho et de l'accusé d'un autre client. Ne pas vider automatiquement le registre en file ni relâcher les contrôles des expéditeurs à partir du seul exemple externe. Si le client refuse réellement, conserver ce refus sans autre route destinée à contourner la protection. Aucun changement du transport ni nouvelle installation effectué pendant cette recherche.

## Sonde explicite installée après accord utilisateur

`/srsync sonde` : vérifie le contexte Forever et la propre guilde ; exige un résultat public `false` de `InChatMessagingLockdown`. L'indicateur d'envoi est enregistré et doit être un booléen public valide ; seuls `allowed` et `realm_restricted` permettent cette opération de diagnostic. Enregistre un préfixe distinct `SRProbe1` et appelle une fois l'API publique SendAddonMessage vers GUILD avec un jeton numérique synthétique. Pas de contenu du registre, de nouvelle prime, de réputation ni de vidage de la file normale. Une nouvelle commande est nécessaire pour recommencer, au moins trente secondes plus tard ; aucun retry automatique ni ACK de sonde.

Le retour d'envoi (code 0 accepté pour soumission, autres codes refusés, erreur, protégé ou invalide) est distinct de l'écho personnel reçu et des signaux éventuels d'autres membres vérifiés. Fenêtre d'observation de dix secondes ; bilan automatique et `/srsync sondebilan`. Les signaux distants nécessitent la sonde installée sur les deux clients et des fenêtres simultanées ; l'installation présente concerne seulement le client local, donc ce compteur peut normalement rester à zéro. Les échos n'alimentent ni les pairs ni les ACK de la synchronisation normale. Valeurs protégées, autres canaux, mauvais préfixe, contexte changé et membres non reconnus sont ignorés. État de sonde temporaire en mémoire, pas de nouvelles données sauvegardées.

Validation : `node tools/test-native.mjs`, **192 contrôles/scénarios** dont 31 transport natif, plus parcours de livraison à deux VM, passés. Vérifie envoi unique malgré le drapeau, respect du verrouillage, absence/erreur/protection/retour invalide, refus natif sans retry, écho corrélé, appartenance, fenêtre/cooldown et absence de mutation du profil/file. Tests injectés, pas un test réel du client.

Installation des 32 fichiers vérifiée avec sauvegarde `dist/client-backups/guild-transport-20261105-220648`. Version locale 0.5.1-dev avec diagnostic, archives GitHub déjà publiées inchangées. Retour demandé hors combat et hors instance : `/reload`, `/srsync sonde`, attendre dix secondes puis `/srsync sondebilan`. Aucun résultat d'envoi réel encore établi sur build 70790.

## Premier résultat réel et sonde v2

L'utilisateur rapporte `indicateur=realm_restricted ; envoi=accepted_code_0`, puis écho personnel non et zéro signal distant. Le code zéro prouve l'acceptation pour soumission par l'API publique, pas la réception ni l'arrivée au serveur. Le client de l'ami ne disposait pas encore de la sonde ; zéro pair n'est donc pas un échec de test à deux. L'écho pourrait aussi avoir été ignoré lors de la résolution d'identité : aucun compteur antérieur ne permettait de l'exclure.

Sonde v2 : fenêtre étendue à trente secondes ; compte les payloads de diagnostic GUILD publics et valides (compteur saturé à 99) avant la vérification d'expéditeur, distingue jeton personnel observé et identité propre confirmée. Catégories d'expéditeur seulement : not_observed, protected, invalid, self, verified_member, membership_unavailable. Aucune valeur protégée ni nom brut affiché/sauvegardé, aucun relâchement pour les primes/registre/transport réel. Pas d'ACK automatique. Les signaux de tiers non reconnus restent exclus du compteur des membres vérifiés.

`node tools/test-native.mjs` : **193 contrôles/scénarios**, dont 32 natifs de guilde, plus parcours à deux VM, passés. Tests supplémentaires : payload personnel visible avec expéditeur protégé/invalide/non reconnu sans faux écho, compteurs bornés et arrêt à expiration. 32 fichiers installés avec sauvegarde `dist/client-backups/guild-transport-20261105-221043`.

Archive séparée créée et chaque entrée comparée au fichier source par SHA256 avec `tools/package-sync-probe.ps1` : `dist/SyndicatRouge-forever-0.5.1-dev-sonde-v2.zip`, SHA256 `88155f97bae8108d78c21f5e98e0008e7008bf902131557bbee193ed7a470715`. Version diagnostique locale à transmettre à l'ami ; aucune publication GitHub/CurseForge, ZIP historiques inchangés. Le générateur Python habituel n'a pas pu tourner (alias WindowsApps indisponible) ; générateur PowerShell distinct, aucun nouvel outil installé.

Test à deux proposé : ami installe ce ZIP puis tous deux reload ; lancer la sonde chacun une première fois pour enregistrer les préfixes des deux côtés. Attendre au moins trente-cinq secondes, la relancer chacun à quelques secondes d'intervalle, puis relever les deux lignes de bilan après trente secondes. Échange réel et reconnaissance des deux identités toujours à confirmer.

## Réception réelle confirmée ; reconnaissance régionale dans la sonde v3

Retour utilisateur v2 : `envoi=accepted_code_0 ; écho personnel=non ; signaux d’autres membres=0`, puis `messages=2 ; jeton personnel=oui ; expéditeur=membership_unavailable`. Le payload personnel est bien arrivé par CHAT_MSG_ADDON/GUILD ; le faux négatif « écho personnel non » venait de la reconnaissance d'expéditeur. Deux messages ne prouvent pas à eux seuls l'identité d'un autre membre (aucune déduplication des messages bruts) ni un échange à deux authentifié. Le blocage permanent d'envoi n'est pas établi ; la réception native l'est.

Source Campkeeper `Core/Util.lua` au commit épinglé ef13a90864ebf4767366c7f6414230ebc2229ccb : quand RegionalUniqueNamesEnabled est vrai, assemble les deux valeurs UnitNameUnmodified avec un espace. Les noms de chat régionaux sont « Name Surname ». Contrats `RegionalUniqueNamesEnabled`, `UnitNameUnmodified` et `MemberExistsByName` relus dans les documents générés du même pin Blizzard eac30af ; noms/retours gardés avant toute comparaison. Le document généré conserve le libellé unitServer pour le second retour ; le sens régional est corroboré par l'implémentation et le journal de Campkeeper, à confirmer sur notre client par la sonde.

V3 locale seulement : `C.ProbeSender` exige un booléen public vrai du mode régional, lit uniquement l'identité propre publique, reconnaît son nom complet exact avec espace ; pour autrui interroge MemberExistsByName avec le nom natif exact, sans suffixe de royaume ajouté ni troncature. Aucun fallback après erreur/protection du mode ou de l'identité propre. Le chemin historique reste pour le mode explicitement faux ou API absente. Aucun changement de C.Current/Member/Actor, identités persistées, registre, file d'événements ni transport normal. Préfixe et jeton inchangés, donc un ami utilisant la v2 peut émettre vers la v3 sans nouvelle archive. La v3 de la sonde n'est pas publiée dans les ZIP publics.

`node tools/test-native.mjs` : **194 contrôles/scénarios**, dont 33 guilde, plus parcours deux VM, passés. Test noms régionaux avec tiret dans le nom de famille, requête distante exacte, déduplication, refus des valeurs protégées et absence de mutation du profil. Installation locale avec sauvegarde ; résultat en jeu de la résolution régionale toujours attendu. Demande : reload côté local puis sonde chacun à quelques secondes d'intervalle ; relever le bilan local après trente secondes. Le support régional du registre normal demandera aussi une décision/migration des anciennes identités construites avec l'autre format, sans réattribution silencieuse.

## Identité propre confirmée ; préparation explicite des deux récepteurs

Le retour v3 local confirme `envoi=accepted_code_0 ; écho personnel=oui ; signaux d’autres membres=0`, `messages=1 ; jeton personnel=oui ; expéditeur=self`. Même bilan local répété, sans bilan de l'autre côté dans ces messages. La capture ensuite fournie pour le résultat demandé à l'ami montre encore **v2**, `accepted_code_0`, `messages=1`, `jeton personnel=oui`, `membership_unavailable` : cohérent avec le défaut d'identité propre de cette version. Aucun signal croisé observé dans les fenêtres rapportées. Cela ne distingue pas absence effective de livraison d'un décalage entre l'enregistrement des préfixes et l'envoi.

V4 : `/srsync ecouter` prépare explicitement le préfixe et une fenêtre de **120 secondes sans envoi**, puis chacun `/srsync sonde` effectue son envoi unique. Les signaux reçus après préparation sont conservés quand on envoie à son tour. `/srsync sondebilan` consulte le bilan sans interrompre l'écoute ; bilan automatique après expiration. Toujours aucune relance automatique ni envoi de données du registre, aucune modification des contrôles du transport normal.

`node tools/test-native.mjs` : **195 contrôles/scénarios**, dont 34 guilde, plus parcours deux VM de livraison, passés. Nouveau test : préparation sans envoi/mutation, signal reçu à conserver pendant son propre envoi, écoute encore active après 35 secondes, expiration après 120 secondes.

Installation locale de 32 fichiers vérifiée, sauvegarde `dist/client-backups/guild-transport-20261105-223738`. Archive `dist/SyndicatRouge-forever-0.5.1-dev-sonde-v4.zip` vérifiée entrée par entrée, SHA256 `6ab3b9a7f2d32140c93d3aa6dcfb078b2478c3ea1ebcc889de27e58878b9ec86`. À transmettre à l'ami, pas publiée sur GitHub/CurseForge. Demande : ami remplace son dossier par cette archive ; tous deux reload, tous deux ecouter et confirmer v4 prête, puis chacun sonde dans les deux minutes et relever les deux bilans. Échange croisé et vérification de membre distant restent ouverts.
