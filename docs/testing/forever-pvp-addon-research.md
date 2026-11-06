# Recherche : attribution des morts et kills dans les autres addons

Date : 6 novembre 2026. Demande : rechercher comment les autres addons réussissent le suivi PvP, après les bilans réels du Goulet. Étude de sources primaires uniquement, sans installation ni exécution du code tiers. Aucun incident/point créé, aucune modification du paquet.

## Révisions vérifiées

- HeadHunter : branche main résolue à `8b6392d51d4f799c584204f4b217276b8c7870fe`, 5 novembre 2026 ; TOC 11509/16001, version 1.0.3.
- Bounty Ledger : branche main résolue à `b1ae562f25718c8692dfb27086146c720aac98d8`, 4 novembre 2026 ; Core annonce 0.1.4. La page CurseForge consultée affiche encore 0.1.3 : ne pas confondre code étudié et archive diffusée. Licence All Rights Reserved ; consultation du comportement, pas de copie de code.
- Source UI Forever : `eac30af597e5aaa43a60f6675ef5fdcea100375f`, version 1.60.1.70790, inchangée lors de la résolution du 6 novembre.

## Ce que font réellement les addons

| Route | Code vérifié | Limite pour Tableau des primes |
|---|---|---|
| Mort sur Classic Era | HeadHunter `Detection/EraDeaths.lua` écoute COMBAT_LOG_EVENT_UNFILTERED, retient les dégâts et le coup fatal puis traite PLAYER_DEAD. | Dépend du journal de combat ; ne constitue pas une solution Forever. Ses replis vers les dégâts récents ne prouvent pas toujours le coup fatal. |
| Mort sur Forever | HeadHunter `Detection/ForeverDeaths.lua` écoute PLAYER_DEAD puis relit C_DeathRecap.HasRecapEvents()/GetRecapEvents() à 0,3/1/2 secondes. Cherche sources hostiles et indicateur overkill ; enrichit les noms depuis son cache. | Piste distincte du chat, présente dans la source, non testée chez l'utilisateur. L'addon recourt aussi au premier attaquant, à un propriétaire de familier supposé ou à une cible récente : ces replis ne satisfont pas notre exigence de preuve automatique. |
| Mort via lien du chat | Bounty Ledger `BountyLedger/Witness.lua` extrait un identifiant public de lien death et appelle GetRecapEvents(id), puis choisit une entrée overkill > 0 ou, à défaut, la première. | Notre chat était protégé au Goulet. Ne pas lire/décoder une entrée protégée pour obtenir le lien. Ne pas assimiler automatiquement la première entrée à une preuve vérifiée. |
| Kill direct | Bounty Ledger `Witness.lua` écoute l'événement de frame PARTY_KILL, exige le monde ouvert, une victime joueur et un attaquant correspondant au personnage ; un membre du groupe peut cosigner. | Même événement que notre diagnostic. Son existence dans le code ne prouve pas sa livraison sur le client actuel. Notre résultat nul au Goulet n'est pas un test en monde ouvert. |
| Participation à un kill | HeadHunter `Sync/Witness.lua` observe une cible/plaque recherchée vivante puis morte ; `Sync/Justice.lua` rapproche cette observation d'une ligne CHAT_MSG_COMBAT_HONOR_GAIN dans une fenêtre temporelle. | Le gain d'honneur peut créditer une participation. Sans victime nommée, le rapprochement peut être ambigu, notamment si plusieurs ennemis meurent. Ce n'est pas une preuve du coup fatal personnel et il ne faut pas créditer arbitrairement un seul vengeur. |

### Monde ouvert et champs de bataille

HeadHunter `Core/Guards.lua` suspend le suivi dans toutes les instances, dont les champs de bataille. Bounty Ledger `Core.lua` définit InOpenWorld() avec IsInInstance(), et Witness applique ce garde aux kills et morts. Les tests de l'utilisateur ont été réalisés au Goulet : ils établissent le comportement des deux diagnostics dans ce parcours, mais pas celui des routes utilisées par ces addons en monde ouvert. Notre conseil initial d'un test au Goulet ne reproduisait pas ce périmètre ; le corriger pour les prochains tests.

## Vérification du contrat Forever

[DeathRecapDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/DeathRecapDocumentation.lua) déclare C_DeathRecap.HasRecapEvents(recapID?) et GetRecapEvents(recapID?), environnement All. La structure DeathRecapEventInfo n'y expose pas ses champs : noms, flags, overkill et horodatages restent à vérifier en exécution et à protéger avant toute inspection. SecretArguments=AllowedWhenUntainted n'est pas une garantie de retours lisibles par l'addon.

Le code de présentation Blizzard_DeathRecap/Mainline/Blizzard_DeathRecap.lua utilise sourceName, amount, overkill, timestamp et marque la première entrée causedDeath dans son fournisseur de données. Son TOC limite ces fichiers de présentation à mainline : cela n'établit pas leur chargement sur Forever. L'API générée All et l'utilisation dans un addon Forever sont des pistes, pas une certification opérationnelle. Ne pas lire les cadres protégés du récapitulatif ni employer C_CombatLogInternal/Secure pour contourner une restriction.

[UnitDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua) déclare PARTY_KILL(attackerGUID,targetGUID), SecretWhenUnitIdentityRestricted. [ChatInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua) déclare CHAT_MSG_COMBAT_HONOR_GAIN ; il faut garder les vérifications de secret sur texte et identités et ne pas considérer la seule présence d'un événement comme une preuve de livraison.

## Suite proposée, sans assouplir la règle « automatique uniquement »

1. Préparer un diagnostic isolé du récapitulatif propre, sans création de prime : présence, résultat d'appel, fraîcheur, entrées/champs publics et indication de coup fatal. Refuser les valeurs protégées, tableaux inaccessibles, données anciennes et cas ambigus. Vérifier aussi si le nom permet d'identifier exactement un personnage régional Forever ; prénom seul insuffisant pour rapprocher une prime.
2. Comparer l'accès au récapitulatif en BG et en monde ouvert ; les deux contextes doivent être consignés séparément. Une donnée lisible après la mort n'établit pas son accessibilité en combat ou celle du récapitulatif d'autrui.
3. Refaire PARTY_KILL en monde ouvert si une occasion réelle se présente, en distinguant coup fatal personnel, familier et simple participation. Pas besoin de répéter immédiatement le même scénario au Goulet.
4. Garder la corrélation mort/honneur de HeadHunter comme option de recherche sur une participation vérifiée, pas comme attribution exacte du kill. Aucun changement de règle de réputation sans décision explicite et preuve compatible.

## Sources tierces épinglées

- [HeadHunter : ForeverDeaths](https://github.com/GudaAddons/HeadHunter/blob/8b6392d51d4f799c584204f4b217276b8c7870fe/Detection/ForeverDeaths.lua)
- [HeadHunter : Classic Era](https://github.com/GudaAddons/HeadHunter/blob/8b6392d51d4f799c584204f4b217276b8c7870fe/Detection/EraDeaths.lua)
- [HeadHunter : garde des instances](https://github.com/GudaAddons/HeadHunter/blob/8b6392d51d4f799c584204f4b217276b8c7870fe/Core/Guards.lua)
- [HeadHunter : mort observée et honneur](https://github.com/GudaAddons/HeadHunter/blob/8b6392d51d4f799c584204f4b217276b8c7870fe/Sync/Justice.lua)
- [HeadHunter : observation des recherchés](https://github.com/GudaAddons/HeadHunter/blob/8b6392d51d4f799c584204f4b217276b8c7870fe/Sync/Witness.lua)
- [Bounty Ledger : preuves](https://github.com/Atlas-CommandOps/bounty-ledger/blob/b1ae562f25718c8692dfb27086146c720aac98d8/BountyLedger/Witness.lua)
- [Bounty Ledger : garde du monde ouvert](https://github.com/Atlas-CommandOps/bounty-ledger/blob/b1ae562f25718c8692dfb27086146c720aac98d8/BountyLedger/Core.lua)
- [Page auteur de Bounty Ledger](https://www.curseforge.com/wow/addons/bounty-ledger)
