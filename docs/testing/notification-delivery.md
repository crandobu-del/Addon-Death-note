# Livraison des notifications et remerciements — 0.5.0-dev

5 novembre 2026. Cible Forever uniquement, 1.60.1.70790/interface 16001 ; source eac30af597e5aaa43a60f6675ef5fdcea100375f re-confirmée. Pas de nouvelle API moteur ; réutilisation des messages addon GUILD, gardes secret, débit et résultats énumérés déjà documentés. [Plan](../plans/death-note/notification-delivery.md).

## Comportement livré

Les vengeances acceptées par le moteur existant produisent des notifications pour leurs victimes. L'arrivée ou le rattrapage déclenche jusqu'à trois alertes chat détaillées puis un compteur, avec badge non lu dans l'onglet. L'état d'alerte est conservé : un doublon, un reload ou une reconnexion ne réaffiche pas les mêmes alertes. Les entrées restent consultables dans l'onglet. Une vengeance en conflit ne produit pas de fausse alerte.

Le clic **Remercier** crée une boîte de sortie dans `SyndicatRougeCharacterDB.guildDelivery[guildId]`, distincte du registre et des préférences. Session et livraison sont validées avant d'être remplacées ensemble en mémoire. Le merci est ciblé sur le vengeur de cette notification ; seul son accusé peut le passer de **pending** à **delivered**. Le destinataire doit appartenir à la guilde, connaître la vengeance et reconnaître l'expéditeur comme sa victime. Ni texte libre, lecture personnelle, fenêtre ni préférence transmis.

La file reprend au démarrage et au retour d'un pair ; quatre demandes au maximum par passage de quinze secondes, rotation pour les files longues, avec le limiteur général de paquets existant. Réception enregistrée avant mise en file de l'accusé. Un ACK perdu entraîne un nouvel envoi, sans deuxième merci reçu ni nouvelle alerte. Pas de serveur de courrier : les deux personnages doivent finir par être connectés simultanément avec le partage actif. Une restriction client suspend l'émission. Les identités/guildes changées purgent la file réseau ; les caches restent séparés par ClubId et propriétaire. Activation sauvegardée : nouvelle tentative après quinze secondes si la guilde n'était pas encore initialisée.

Le vengeur consulte les mercis dans son onglet Notifications et peut les marquer comme lus. La victime voit **En attente**, puis **Merci reçu** après ACK. Les anciennes marques locales de la version 0.4 ne sont pas envoyées automatiquement : un nouveau clic explicite **Envoyer le merci** est nécessaire. Aucun merci à soi-même et aucune réputation supplémentaire. Démonstration strictement locale.

## Sauvegarde et limites

Cache de livraison versionné, 256 éléments maximum par boîte/liste d'alertes. Format futur/invalide : échec de l'ouverture et préservation de l'original. Lecture et remerciements sortants sont locaux ; les seuls faits du registre continuent à être exportés par Protocol.Export. Une paire de guilde ciblée passe quand même via GUILD : pas de confidentialité cryptographique entre clients de guilde.

La sauvegarde est un checkpoint en mémoire ; WoW écrit le fichier sur reload/logout/fermeture normale. Un crash avant cette écriture peut perdre les dernières modifications. L'échec d'ouverture d'un historique contenant des membres partis reste une limite du transport existant. Les mercis associés à une vengeance devenue conflictuelle sont masqués/suspendus, sans effacer leur état.

## Vérifications

- `node tools/test-lua.mjs` : **72 tests**, dont 18 sur la livraison : queue avant envoi, reprise, accusé perdu, doublons, expéditeur/cible/claim incorrects, lecture, alertes de rattrapage, vieilles marques locales, auto-merci, formats futurs, capacité, conflits, absence de fuite des états privés et absence de gain de points.
- `node tools/test-native.mjs` : **169 contrôles/scénarios** de widgets, API et cycle existants, puis un nouveau parcours à deux VM natives isolées. Ce parcours utilise les vrais gestionnaires Native/Channel, les paquets Wire, le bouton UI, un reload de l'expéditeur, la perte de l'ACK, un reload du destinataire, la reprise, la confirmation et la lecture persistante. Faits injectés uniquement dans ces VM de test.
- **Pas un essai à deux clients de jeu**. Pas de nouvelle capture graphique en jeu : la disposition et les ressources restent conservées ; libellés, badge et branche « merci reçu » contrôlés par doubles de widgets, rendu réel à confirmer.

## Recette en jeu à réaliser

[Préversion GitHub 0.5](https://github.com/crandobu-del/Addon-Death-note/releases/tag/v0.5.0-alpha.1) publiée sur le commit **6f038500fb59e317c7206fb4866cf4303f80545b**, avec les deux ZIP dans Assets. Empreinte affichée publiquement de l'archive principale vérifiée identique à la locale. Capture de publication conservée hors git sous `docs/testing/screenshots/notification-delivery-release.png`. CurseForge reste sur la soumission 0.4 ; son état actuel n'a pas été revérifié ici.

Installation locale confirmée par empreintes : 31 fichiers principaux ; sauvegarde des anciens sous `dist/client-backups/guild-transport-20261105-200813`. Le compagnon de diagnostic déjà installé reste présent. Les deux archives 0.5 contiennent le principal à jour, celle avec compagnon contient aussi le diagnostic `/srkill`. L'archive principale a pour SHA256 `b4350bfa1fc7f3dc47540b37b27a6e614a93fb62ff06779cb93c150791681675`.

Les deux membres installent la version **0.5.0-dev**, font `/reload`, puis `/srsync activer`. `/srsync test` vérifie le transport sans créer de fait fictif. Sur une vengeance réelle déjà validée et partagée, la victime reçoit une alerte, ouvre `/sr` → Notifications, clique **Remercier**. Le vengeur doit recevoir l'alerte et l'entrée ; la victime doit voir **Merci reçu**. Refaire après un reload et avec le vengeur reconnecté après le clic : une seule entrée et aucun point supplémentaire.

**Blocage de la recette réelle :** la détection automatique de kill/vengeance reste en enquête. Le premier bilan `/srkill` confirme validité et abonnement, mais zéro événement reçu. Aucun point réel ni vengeance fictive n'a été créé pour présenter cette livraison comme validée. La fonctionnalité est implémentée et testée hors jeu ; validation opérationnelle réelle encore ouverte. Le choix utilisateur **automatique uniquement** est conservé. Aucun message Discord envoyé.
