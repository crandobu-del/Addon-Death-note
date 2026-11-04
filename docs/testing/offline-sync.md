# Vérification du partage hors jeu — 0.2.0

## Résultats

`node tools/test-lua.mjs` : 34 tests passés, dont les 16 scénarios du socle et 18 nouveaux scénarios de partage. Les mêmes fichiers Lua sont intégrés aux deux pages de démonstration.

Cas vérifiés : rattrapage d'incidents et de vengeances, répétition d'un échange, guilde étrangère, expéditeur inconnu, identité du transport différente de l'enveloppe, version inconnue, tableau creux, conflit sous un même identifiant, rejet atomique, victimes/vengeurs extérieurs au roster, revendications qui se recouvrent entièrement ou partiellement, revendications indépendantes, relais des conflits à un troisième membre, restauration des conflits, confidentialité des états de lecture/remerciement, limites par message et après fusion, budget logique et incohérence nom/royaume sous un identifiant de membre.

`node tools/test-sync-demo.mjs` : tests dans Chrome, bureau 1180 px et petit écran 360 px. Le parcours simule une déconnexion, un incident local non encore partagé, la reconnexion/récupération, une vengeance, le classement identique et un remerciement personnel. Le scénario de conflit affiche les deux revendications en attente dans les deux registres et ne crédite personne. Les répétitions ne changent pas les résultats. La réinitialisation et l'ouverture directe de `sync.html` sont vérifiées ; aucune exception JavaScript relevée.

Les tests existants `node tools/test-demo.mjs` sont conservés pour vérifier la première page à quatre onglets.

## Contrôle visuel

Captures réelles inspectées : `docs/testing/screenshots/sync-shared-desktop.png` et `sync-conflict-desktop.png` ; capture mobile produite par le même parcours. Deux registres lisibles, identité Le Syndicat Rouge et distinction explicite entre scénario simulé et jeu réel. Les captures sont locales, régénérables et exclues de Git. Aucun débordement horizontal détecté aux deux largeurs.

## Contrat et limites

`Protocol.lua` gère une enveloppe logique versionnée, pas des paquets de chat sérialisés. Le budget logique est une borne prudente calculée sur les données normalisées ; il ne certifie pas la taille d'une future chaîne réseau. Le futur adaptateur doit limiter les octets avant décodage et traiter encodage, compression éventuelle, segmentation, débit, pertes, reprise et roster réel.

L'expéditeur et le roster sont fournis explicitement par l'hôte de simulation. Les valider ne prouve pas la réalité des combats et ne constitue pas une authentification cryptographique ou une vérification de permissions sur Forever. La mise en attente des revendications concurrentes est une politique provisoire, pas un arbitrage d'officier. Les changements de nom/royaume et de guilde doivent faire l'objet d'un contrat d'identité client avant intégration.

Une revendication en conflit est conservée et retransmise, même si ses points sont suspendus. Une revendication comprenant plusieurs incidents reste entièrement en attente si l'un d'eux est disputé. Les incidents couverts redeviennent ouverts dans l'état dérivé ; aucune notification de vengeance n'est émise pour une revendication en attente.

La simulation repart de son scénario initial à l'ouverture de la page. La restauration d'un registre sérialisé est testée en Lua ; les états de cette page ne sont pas sauvegardés dans le navigateur. La première page à quatre onglets conserve sa sauvegarde locale indépendante.

## Non exécuté

Messages de guilde du client Forever, test à deux joueurs réels, observation de morts, autorisations en combat, arbitrage réseau autoritaire, migrations de guilde et notifications Discord : non implémentés/non testés. Aucun message extérieur au navigateur n'a été envoyé.
