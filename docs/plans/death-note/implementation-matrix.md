# Death Note — suivi de réalisation

Exigences : [requirements.md](requirements.md). Responsable : Codex. Mise à jour : 4 novembre 2026.

| Travail | Exigences | Résultat attendu | Dépendances | État / preuve |
|---|---|---|---|---|
| IMP-001 | REQ-001, REQ-002, REQ-004 | Vérifier le client et sonder les informations de mort PvP accessibles | Build réel et recherche des contrats API | Recherche en cours ; source épinglée à eac30af597e5aaa43a60f6675ef5fdcea100375f, restrictions déclarées sur le journal de combat ; aucun test en jeu |
| IMP-002 | REQ-002, REQ-004, REQ-006 | Enregistrer et retrouver une fiche d'incident locale | IMP-001 pour la détection réelle | Modèle local, validation et restauration implémentés/testés hors jeu ; SavedVariables et détection non testés |
| IMP-003 | REQ-003, REQ-006 | Partager et rattraper les incidents, rejeter les doublons | IMP-002 et validation des communications | Planifié ; aucun code |
| IMP-004 | REQ-005, REQ-007 | Classer les récidivistes avec une prime symbolique | IMP-002 | Calcul local testé : prime provisoire = total des incidents distincts ; récompense = incidents ouverts. Aucun réseau |
| IMP-005 | REQ-003, REQ-004, REQ-005 | Liste des recherchés, fiche et journal avec notifications | Choix UI puis IMP-002 à IMP-004 | Aperçu navigateur fonctionnel utilisant Lua ; aucune UI native WoW ou synchro livrée ; différences visuelles documentées |
| IMP-006 | REQ-008 | Valider une vengeance, clôturer les incidents concernés et créditer les points une seule fois | IMP-001 à IMP-003, preuve de mort ennemie et règle de groupe | Clôture locale atomique et idempotente testée. Preuve de mort, attribution en groupe et concurrence réseau non implémentées |
| IMP-007 | REQ-009 | Classement des vengeurs cohérent entre membres | IMP-006 | Classement local et ordre déterministe testés ; cohérence réseau non testée |
| IMP-008 | REQ-010 | Notification personnelle aux victimes vengées, sans doublon et avec rattrapage | IMP-003, IMP-006 | Notification dérivée par victime et restauration locale testées ; pas de livraison inter-clients |
| IMP-009 | REQ-011 | Remerciement volontaire du vengeur | IMP-008 et choix du canal | Choix et état local implémentés/testés dans l'aperçu ; aucun message effectivement envoyé |
| IMP-010 | REQ-012, REQ-014, REQ-015, REQ-016 | Registre clandestin du Syndicat Rouge, portraits, niveaux, tampon et récompense en réputation | Retour utilisateur sur la première maquette | Concept v2 historique ; correction d'identité suivie dans IMP-013, prototype HTML non adapté à l'art du concept |
| IMP-011 | REQ-013 | Carte du lieu du dernier meurtre connu dans la fiche | IMP-001 pour les données, IMP-010 pour la composition | Planifié ; carte de concept illustrative, coordonnées réelles non testées |
| IMP-012 | REQ-017 | Marqueur rouge propre à la guilde au-dessus du nom des joueurs recherchés | Accès aux plaques et à l'identité vérifié sur Forever, IMP-003 et IMP-006 | Planifié ; déclaration C_NamePlate et TOC examinés au commit épinglé. Tester combat, disparition/réutilisation des plaques et clôture des incidents ; aucun test en jeu |
| IMP-013 | REQ-018, REQ-014, REQ-017 | Identité « Le Syndicat Rouge », suppression des mentions textuelles Défias dans les interfaces courantes et marqueur propre à la guilde | Correction explicite utilisateur | Concept v3 corrigé et contrôlé visuellement : assets/death-note-syndicat-rouge-v3.png. Identité du prototype HTML corrigée ; marqueur en jeu non réalisé |
| IMP-014 | REQ-019 | Notifications Discord configurables et dédupliquées | IMP-003, IMP-006 et étude d'un relais externe | Cadré dans discord-notifications.md ; documentation webhook Discord consultée, aucun envoi ou service configuré |
| IMP-015 | REQ-009, REQ-010, REQ-011, REQ-012, REQ-014, REQ-018, REQ-019 | Montrer les onglets Vengeurs, Journal et Notifications dans l'identité courante | Concept v3, demande utilisateur | Trois concepts réalisés, inspectés et présentés ; images assets/death-note-{vengeurs,journal,notifications}-v1.png, détails dans onglets-maquettes.md ; retour utilisateur attendu, aucune fonctionnalité de production livrée |
| IMP-016 | REQ-001 à REQ-019 | Prévoir l'arborescence de développement et les frontières de modules | Demande utilisateur d'arborescence | Architecture documentée dans docs/architecture.md ; dossiers de base créés, README et .gitignore ajoutés. Aucun Lua/TOC ou relais fonctionnel créé |
| IMP-017 | REQ-002/004/005/007/008/009/010/011/012/014/015/016/018 | Première tranche hors jeu : règles Lua et aperçu à quatre onglets | « ok go » après proposition du socle puis de l'interface | Implémentée pour le périmètre hors jeu ; 16 tests Lua et parcours navigateur passés. Voir docs/testing/offline-core.md. Le périmètre réel Forever reste ouvert |

## Vérifications

- Moteur : `node tools/test-lua.mjs`, 16 tests Lua passés sous Fengari 0.1.4 ; pas une validation du Lua du client.
- Aperçu : compilation passée ; parcours automatisés sous Chrome 156.0.8078.80 passés, largeurs 1180 et 360 px, ouverture directe du fichier testée. Captures réelles inspectées ; différences aux concepts documentées.
- Livraison : archive de démonstration locale générée dans dist/, contenant uniquement l'aperçu et ses ressources, aucun addon installable. Aucun test UIForever exécuté.
- Jeu Forever : non exécutée, client/build inconnu.
- Synchronisation entre deux membres : non exécutée.

## Point de reprise

- Dépôt : https://github.com/crandobu-del/Addon-Death-note ; branche `codex/structure-syndicat-rouge`.
- Révision de départ de la tranche : `35431d6a3e44948d6db7287dd94538798931d1d2`. Lire le HEAD courant et comparer les changements avant reprise ; les éléments d'IMP-017 sont livrés dans le commit de socle hors jeu succédant à cette base.
- Dernier travail : socle Lua et aperçu navigateur à quatre onglets développés et vérifiés. Ressources de démonstration et fixtures hors du dossier addon. Documentation et tests ajoutés. Aucun service Discord connecté ou message envoyé.
- Prochaine action : recueillir le retour sur l'aperçu fonctionnel ; poursuivre l'adaptation visuelle et les modules d'intégration selon docs/architecture.md. Reporter la sonde et les tests en jeu à la sortie de Forever. Attribution en groupe et arbitrage réseau restent ouverts. Ne pas confondre prime ennemie et récompense gagnée.
- Lire requirements.md puis ce suivi avant reprise.
- Exigences sans ligne : aucune. Les fonctions locales d'IMP-017 sont réalisées ; les fonctions et vérifications du client, réseau, marqueurs et Discord restent à développer/vérifier, ainsi que l'apparence native finale.
