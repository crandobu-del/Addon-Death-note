# Death Note — suivi de réalisation

Exigences : [requirements.md](requirements.md). Responsable : Codex. Mise à jour : 4 novembre 2026.

| Travail | Exigences | Résultat attendu | Dépendances | État / preuve |
|---|---|---|---|---|
| IMP-001 | REQ-001, REQ-002, REQ-004 | Vérifier le client et sonder les informations de mort PvP accessibles | Build réel et recherche des contrats API | Recherche en cours ; source épinglée à eac30af597e5aaa43a60f6675ef5fdcea100375f, restrictions déclarées sur le journal de combat ; aucun test en jeu |
| IMP-002 | REQ-002, REQ-004, REQ-006 | Enregistrer et retrouver une fiche d'incident locale | IMP-001 pour la détection réelle | Modèle local, validation et restauration implémentés/testés hors jeu ; SavedVariables et détection non testés |
| IMP-003 | REQ-003, REQ-006 | Partager et rattraper les incidents, rejeter les doublons | IMP-002 et validation des communications | Protocole logique, fusion et restauration testés avec registres simulés. Échange complet borné ; pas de transport de guilde réel, segmentation ou pagination |
| IMP-004 | REQ-005, REQ-007 | Classer les récidivistes avec une prime symbolique | IMP-002 | Calcul local testé : prime provisoire = total des incidents distincts ; récompense = incidents ouverts. Aucun réseau |
| IMP-005 | REQ-003, REQ-004, REQ-005 | Liste des recherchés, fiche et journal avec notifications | Choix UI puis IMP-002 à IMP-004 | Aperçu navigateur fonctionnel utilisant Lua ; aucune UI native WoW ou synchro livrée ; différences visuelles documentées |
| IMP-006 | REQ-008 | Valider une vengeance, clôturer les incidents concernés et créditer les points une seule fois | IMP-001 à IMP-003, preuve de mort ennemie et règle de groupe | Clôture atomique/idempotente testée. Revendications concurrentes conservées et mises en attente sans double crédit dans le simulateur. Preuve de mort, groupes et arbitrage réel non implémentés |
| IMP-007 | REQ-009 | Classement des vengeurs cohérent entre membres | IMP-006 | Classement déterministe et convergence testés entre registres simulés ; aucune vérification à deux clients réels |
| IMP-008 | REQ-010 | Notification personnelle aux victimes vengées, sans doublon et avec rattrapage | IMP-003, IMP-006 | Notification dérivée par victime et restauration locale testées ; pas de livraison inter-clients |
| IMP-009 | REQ-011 | Remerciement volontaire du vengeur | IMP-008 et choix du canal | Choix et état local implémentés/testés dans l'aperçu ; aucun message effectivement envoyé |
| IMP-010 | REQ-012, REQ-014, REQ-015, REQ-016 | Registre clandestin du Syndicat Rouge, portraits, niveaux, tampon et récompense en réputation | Retour utilisateur sur la première maquette | Concept v2 historique ; correction d'identité suivie dans IMP-013, prototype HTML non adapté à l'art du concept |
| IMP-011 | REQ-013 | Carte du lieu du dernier meurtre connu dans la fiche | IMP-001 pour les données, IMP-010 pour la composition | Planifié ; carte de concept illustrative, coordonnées réelles non testées |
| IMP-012 | REQ-017 | Marqueur rouge propre à la guilde au-dessus du nom des joueurs recherchés | Accès aux plaques et à l'identité vérifié sur Forever, IMP-003 et IMP-006 | Planifié ; déclaration C_NamePlate et TOC examinés au commit épinglé. Tester combat, disparition/réutilisation des plaques et clôture des incidents ; aucun test en jeu |
| IMP-013 | REQ-018, REQ-014, REQ-017 | Identité « Le Syndicat Rouge », suppression des mentions textuelles Défias dans les interfaces courantes et marqueur propre à la guilde | Correction explicite utilisateur | Concept v3 corrigé et contrôlé visuellement : assets/death-note-syndicat-rouge-v3.png. Identité du prototype HTML corrigée ; marqueur en jeu non réalisé |
| IMP-014 | REQ-019 | Notifications Discord configurables et dédupliquées | IMP-003, IMP-006 et étude d'un relais externe | Export de démo et relais Python implémentés/testés hors réseau : file, catégories, regroupement, corrections et résultats incertains. Envoi désactivé ; aucun service configuré ni export réel du jeu |
| IMP-015 | REQ-009, REQ-010, REQ-011, REQ-012, REQ-014, REQ-018, REQ-019 | Montrer les onglets Vengeurs, Journal et Notifications dans l'identité courante | Concept v3, demande utilisateur | Trois concepts réalisés, inspectés et présentés ; images assets/death-note-{vengeurs,journal,notifications}-v1.png, détails dans onglets-maquettes.md ; retour utilisateur attendu, aucune fonctionnalité de production livrée |
| IMP-016 | REQ-001 à REQ-019 | Prévoir l'arborescence de développement et les frontières de modules | Demande utilisateur d'arborescence | Architecture documentée dans docs/architecture.md ; dossiers de base créés, README et .gitignore ajoutés. Aucun Lua/TOC ou relais fonctionnel créé |
| IMP-017 | REQ-002/004/005/007/008/009/010/011/012/014/015/016/018 | Première tranche hors jeu : règles Lua et aperçu à quatre onglets | « ok go » après proposition du socle puis de l'interface | Implémentée pour le périmètre hors jeu ; 16 tests Lua et parcours navigateur passés. Voir docs/testing/offline-core.md. Le périmètre réel Forever reste ouvert |
| IMP-018 | REQ-003/006/008/009/010/011 | Partage entre registres simulés, rattrapage et conflits | « ok la suite », après IMP-017 | Implémenté hors jeu ; 18 tests Lua de partage et parcours navigateur dédiés passés. Voir docs/testing/offline-sync.md ; transport et arbitrage réel non livrés |
| IMP-019 | REQ-019, REQ-018 | Export et annonces Discord testables sans réseau | « ok la suite », après IMP-018 | Module Lua, relais Python, exemples navigateur et téléchargement JSON fictif réalisés. Tests dans docs/testing/offline-discord.md ; aucune requête réelle envoyée à Discord |

## Vérifications

- Moteur : `node tools/test-lua.mjs`, 39 tests Lua passés sous Fengari 0.1.4 (16 socle + 18 partage + 5 export) ; pas une validation du Lua du client.
- Relais : 35 tests Python passés sous unittest, transports factices uniquement ; validation, état durable, doublons, conflits, limites et reprises vérifiés. Aucun envoi Discord réel.
- Aperçu : compilation passée ; parcours automatisés sous Chrome 156.0.8078.80 passés, largeurs 1180 et 360 px, ouverture directe du fichier testée. Captures réelles inspectées ; différences aux concepts documentées.
- Livraison : archive de démonstration locale générée dans dist/, contenant uniquement l'aperçu et ses ressources, aucun addon installable. Aucun test UIForever exécuté.
- Jeu Forever : non exécutée, client/build inconnu.
- Synchronisation entre deux membres : non exécutée.
- Partage simulé : `node tools/test-sync-demo.mjs`, parcours passé à 1180/360 px et en ouverture directe ; aucune exception JavaScript. Deux membres réels : non testé.
- Aperçu Discord : `node tools/test-discord-demo.mjs` vérifie catégories, compact/déplié, téléchargement fictif, ouverture directe et absence de requêtes extérieures. Livraison de démonstration 0.3.0, trois pages, sans secret ni relais actif.

## Point de reprise

- Dépôt : https://github.com/crandobu-del/Addon-Death-note ; branche `codex/structure-syndicat-rouge`.
- Révision de départ de la tranche Discord : `0dcd50ecb8d4e2b6ac9e10559af0a6ecdb533fe5`. Lire le HEAD courant et comparer les changements avant reprise ; IMP-019 est livré dans le commit suivant cette base.
- Dernier travail : exporteur fictif Lua, file SQLite, relais webhook désactivé, aperçu Discord et tests ajoutés ; archive 0.3.0 préparée. Les préférences et remerciements personnels ne sont pas exportés. Aucun service Discord connecté ni message réel envoyé.
- Prochaine action : poursuivre l'interface native ou les adaptateurs Forever à partir des sources vérifiées, puis tester le client lorsqu'il sera disponible. Fixer la preuve des combats, les permissions et l'arbitrage, ainsi que la méthode/fréquence d'export réel avant d'activer le relais. Récapitulatif de classement Discord et surveillance automatique non implémentés.
- Lire requirements.md puis ce suivi avant reprise.
- Exigences sans ligne : aucune. Les fonctions locales d'IMP-017 sont réalisées ; les fonctions et vérifications du client, réseau, marqueurs et Discord restent à développer/vérifier, ainsi que l'apparence native finale.
