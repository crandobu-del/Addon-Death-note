# Death Note — suivi de réalisation

Exigences : [requirements.md](requirements.md). Responsable : Codex. Mise à jour : 4 novembre 2026.

| Travail | Exigences | Résultat attendu | Dépendances | État / preuve |
|---|---|---|---|---|
| IMP-001 | REQ-001, REQ-002, REQ-004 | Vérifier le client et sonder les informations de mort PvP accessibles | Build réel et recherche des contrats API | Recherche en cours ; source épinglée à eac30af597e5aaa43a60f6675ef5fdcea100375f, restrictions déclarées sur le journal de combat ; aucun test en jeu |
| IMP-002 | REQ-002, REQ-004, REQ-006 | Enregistrer et retrouver une fiche d'incident locale | IMP-001 | Planifié ; aucun code |
| IMP-003 | REQ-003, REQ-006 | Partager et rattraper les incidents, rejeter les doublons | IMP-002 et validation des communications | Planifié ; aucun code |
| IMP-004 | REQ-005, REQ-007 | Classer les récidivistes avec une prime symbolique | IMP-002 | Planifié ; système symbolique confirmé, barème à définir |
| IMP-005 | REQ-003, REQ-004, REQ-005 | Liste des recherchés, fiche et journal avec notifications | Choix UI puis IMP-002 à IMP-004 | Maquette interactive réalisée ; aucune UI Lua de production ; design en attente de retour |
| IMP-006 | REQ-008 | Valider une vengeance, clôturer les incidents concernés et créditer les points une seule fois | IMP-001 à IMP-003, preuve de mort ennemie et règle de groupe | Planifié ; attribution à vérifier sur Forever |
| IMP-007 | REQ-009 | Classement des vengeurs cohérent entre membres | IMP-006 | Planifié ; aucun code |
| IMP-008 | REQ-010 | Notification personnelle aux victimes vengées, sans doublon et avec rattrapage | IMP-003, IMP-006 | Planifié ; aucun code |
| IMP-009 | REQ-011 | Remerciement volontaire du vengeur | IMP-008 et choix du canal | Planifié ; aucun envoi automatique autorisé |
| IMP-010 | REQ-012, REQ-014, REQ-015, REQ-016 | Registre clandestin du Syndicat Rouge, portraits, niveaux, tampon et récompense en réputation | Retour utilisateur sur la première maquette | Concept v2 historique ; correction d'identité suivie dans IMP-013, prototype HTML non adapté à l'art du concept |
| IMP-011 | REQ-013 | Carte du lieu du dernier meurtre connu dans la fiche | IMP-001 pour les données, IMP-010 pour la composition | Planifié ; carte de concept illustrative, coordonnées réelles non testées |
| IMP-012 | REQ-017 | Marqueur rouge propre à la guilde au-dessus du nom des joueurs recherchés | Accès aux plaques et à l'identité vérifié sur Forever, IMP-003 et IMP-006 | Planifié ; déclaration C_NamePlate et TOC examinés au commit épinglé. Tester combat, disparition/réutilisation des plaques et clôture des incidents ; aucun test en jeu |
| IMP-013 | REQ-018, REQ-014, REQ-017 | Identité « Le Syndicat Rouge », suppression des mentions textuelles Défias dans les interfaces courantes et marqueur propre à la guilde | Correction explicite utilisateur | Concept v3 corrigé et contrôlé visuellement : assets/death-note-syndicat-rouge-v3.png. Identité du prototype HTML corrigée ; marqueur en jeu non réalisé |
| IMP-014 | REQ-019 | Notifications Discord configurables et dédupliquées | IMP-003, IMP-006 et étude d'un relais externe | Cadré dans discord-notifications.md ; documentation webhook Discord consultée, aucun envoi ou service configuré |
| IMP-015 | REQ-009, REQ-010, REQ-011, REQ-012, REQ-014, REQ-018, REQ-019 | Montrer les onglets Vengeurs, Journal et Notifications dans l'identité courante | Concept v3, demande utilisateur | Trois concepts réalisés, inspectés et présentés ; images assets/death-note-{vengeurs,journal,notifications}-v1.png, détails dans onglets-maquettes.md ; retour utilisateur attendu, aucune fonctionnalité de production livrée |
| IMP-016 | REQ-001 à REQ-019 | Prévoir l'arborescence de développement et les frontières de modules | Demande utilisateur d'arborescence | Architecture documentée dans docs/architecture.md ; dossiers de base créés, README et .gitignore ajoutés. Aucun Lua/TOC ou relais fonctionnel créé |

## Vérifications

- Statique maquette : script extrait puis `node --check`, réussi ; vérification de syntaxe uniquement, pas un test d'interaction ou d'addon.
- Visuelle / simulateur : non exécutée ; maquette à examiner dans la conversation, aucun rendu WoW vérifié.
- Jeu Forever : non exécutée, client/build inconnu.
- Synchronisation entre deux membres : non exécutée.

## Point de reprise

- Dépôt : https://github.com/crandobu-del/Addon-Death-note ; branche `codex/structure-syndicat-rouge`.
- Révision de base : `84a04a660abe31d4ac4406890c84ee044d11b2f6`. Les fichiers de ce cadrage sont ajoutés par le commit de structure sur cette branche ; lire son HEAD pour reprendre. Aucun fichier Lua d'addon implémenté.
- Dernier travail : arborescence prête pour Git, dossiers réservés matérialisés par des .gitkeep, README, .gitignore, documentation, prototype initial et maquettes regroupés. Licence MIT existante conservée. Code futur dans addon/SyndicatRouge/, relais facultatif dans bridge/. Aucun service Discord connecté ou message envoyé.
- Prochaine action : partir de docs/architecture.md pour préciser les contrats de données et les règles d'attribution avant le développement du socle, puis des quatre vues. Les retours artistiques restent ouverts. Reporter la sonde et les tests en jeu à la sortie de Forever. Barème de base +1 réputation par incident vengé ; attribution en groupe ouverte. Ne pas confondre prime ennemie et récompense gagnée. Réserver le tampon VENGÉ aux incidents, pas aux lignes du classement.
- Lire requirements.md puis ce suivi avant reprise.
- Exigences sans ligne : aucune. Toutes les fonctionnalités restent à développer et à vérifier.
