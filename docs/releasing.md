# Publications de Tableau des primes

## Consigne permanente de l'utilisateur

Depuis le 6 novembre 2026, publier une archive à jour sur **CurseForge après chaque grosse modification** livrée : nouvelle fonctionnalité, changement notable de l'interface ou correctif important de compatibilité/partage. Cette consigne autorise ces mises à jour pendant les travaux du projet ; elle ne crée pas de surveillance en arrière-plan.

Regrouper les petites retouches avant publication. Conserver GitHub pour les sources, les préversions et le compagnon facultatif de démonstration.

## Contrôles de publication

1. Vérifier la version des TOC, les fichiers chargés et les contrôles pertinents.
2. Produire l'archive Forever contenant directement `SyndicatRouge/`, sans sauvegardes personnelles ni fichiers temporaires. Vérifier son empreinte.
3. Déposer le paquet principal dans le projet CurseForge existant **1785349**, slug `death-note-guild-ledger`, avec la version de jeu réellement prise en charge et un journal des changements.
4. À la demande explicite de l'utilisateur du 6 novembre 2026 (« sort une release »), la 0.5.6 est distribuée sur le canal **Release** de CurseForge. Cette demande remplace la consigne précédente de classement Alpha pour cette version. Le paquet reste `0.5.6-dev` ; documenter la collecte automatique réelle non connectée/validée et les validations encore nécessaires pour les marqueurs en jeu. Le canal de distribution ne prouve pas la complétude fonctionnelle. Ne pas présenter les simulations comme des preuves PvP.
5. Choisir la publication automatique après approbation. Vérifier le résultat affiché et enregistrer l'identifiant du fichier, son état et son empreinte. Distinguer dépôt, traitement et approbation ; ne pas annoncer une disponibilité avant confirmation.
6. Actualiser le README et le point de reprise. Les Alpha sont proposées par lien direct sur CurseForge ; le portail indique qu'elles ne sont pas visibles dans son application.

## Historique

- **0.4.0-dev** : fichier CurseForge **9455678**, Alpha Forever 1.60.1 ; projet et fichier approuvés, vérifiés dans le portail le 6 novembre 2026.
- **0.5.6-dev** : préversion GitHub `v0.5.6-alpha.1`, commit `9d79d32cb9a2732d84ee4d195e1f8236c0403bfa`. Archive principale déposée sur CurseForge le 6 novembre 2026, fichier **9472153**, Alpha Forever 1.60.1, publication automatique après approbation. Dernier état vérifié après rechargement du portail : **Processing** ; approbation et disponibilité publique pas encore confirmées. Capture locale : `testing/screenshots/curseforge-056-submitted.jpg`. SHA256 : `508b008d88573b504ad198bb1495617a732844aa0eb0483fbcee3980b93312fa`.
- **0.5.6-dev, passage Release** : même fichier **9472153**, même archive et même empreinte ; type **Release**, titre « Tableau des primes 0.5.6-dev — Forever ». Notes ajustées pour distinguer le canal Release du statut de développement, limites conservées. Dernier état observé : **Under Review** ; approbation et disponibilité publique pas encore confirmées. Capture locale : `testing/screenshots/curseforge-056-release.jpg`. Aucun nouveau code ni changement du paquet ; GitHub conserve sa préversion existante.
