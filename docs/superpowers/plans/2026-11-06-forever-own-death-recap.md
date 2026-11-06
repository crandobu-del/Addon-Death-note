# Forever Own Death Recap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vérifier si le récapitulatif de la propre mort expose des données publiques exploitables sur le client Forever de l'utilisateur, sans créer de prime ni attribuer de réputation.

**Architecture:** Compagnon de diagnostic séparé de l'addon principal. Une sonde active explicitement relève la disponibilité des API et des champs, puis effectue trois lectures bornées après une mort. Le bilan contient uniquement des catégories et compteurs publics ; le registre, les communications de guilde et les notifications restent indépendants.

**Tech Stack:** Lua WoW Forever, compagnon SyndicatRougeDemo, tests Lua dans les VM natives du projet, outils Node et packaging PowerShell existants.

**Spec:** [Audit fonctionnel HeadHunter](../../testing/headhunter-functional-audit.md), [exigences](../../plans/death-note/requirements.md), [contrats et limites PvP](../../testing/forever-pvp-addon-research.md).

## Global Constraints

- WoW Forever uniquement, interface 16001 ; source vérifiée `eac30af597e5aaa43a60f6675ef5fdcea100375f`, pas de preuve de fonctionnement déduite de cette seule déclaration.
- Choix utilisateur : « Automatique uniquement ». Cette tranche diagnostique ne crée aucun incident, vengeance, point ou message extérieur.
- Licence HeadHunter All Rights Reserved : implémentation originale ; aucun code ou asset tiers incorporé.
- Vérifier l'accessibilité avant comparaison, type, indexation, longueur ou conversion ; aucun contournement par chat/cadre/infobulle/API interne.
- Pas de lecture UnitGUID sur target/focus/nameplate. Pas de propriétaire de familier deviné, pas de rapprochement d'identité par prénom seul.
- Aucune nouvelle SavedVariables ; pas de nom, GUID, texte brut ni entrée de récapitulatif conservés après la lecture.
- BG et monde ouvert sont relevés séparément ; aucune modification du périmètre des primes n'est introduite par ce diagnostic.

## Review Focus

- Ancien récapitulatif encore disponible : ne pas le présenter comme une nouvelle preuve ; données temporelles non validées = fraîcheur inconnue.
- Nouvelle mort avant la fin des tentatives, arrêt ou redémarrage : invalider les anciens callbacks sans modifier le nouveau rapport.
- Tableau ou champs protégés : ne pas évaluer une condition ou parcourir une table avant le contrôle d'accès ; compteurs seulement.
- Mort PvE, familier inconnu ou plusieurs coups fatals candidats : bilan non attribuable, aucune récompense.
- Répétition du même récapitulatif aux trois lectures et changement de contexte : ne pas additionner trois fois les mêmes entrées ni mélanger BG/monde ouvert.

### Task 1: Diagnostic du récapitulatif propre

**Files:**
- Create: `dev/SyndicatRougeDemo/DeathRecapProbe.lua`.
- Create: `tests/lua/death_recap_probe_spec.lua`.
- Modify: `dev/SyndicatRougeDemo/SyndicatRougeDemo.toc` pour charger le module avant Demo.lua.
- Modify: `tools/test-native.mjs` pour charger le module et sa suite.
- Modify: `tools/prepare-native.mjs` si le générateur réécrit la liste du compagnon, afin de préserver le module.
- Create: `docs/testing/death-recap-probe.md` pour la procédure, les résultats et la séparation déclaration/opération.

**Interfaces:**
- Consumes: C_DeathRecap.HasRecapEvents() et GetRecapEvents(), sans recapID ; PLAYER_DEAD ; C_Timer.After ; horloges et contexte uniquement si publics.
- Produces: `demo.DeathRecapProbe.Start()`, `.Stop()`, `.Show()` et `.Read()` ; commande `/srrecap debut|bilan|fin`.
- `.Read()` retourne un rapport neuf de catégories/compteurs publics, sans entrée brute : `status`, `entries`, `publicSources`, `fatalCandidates`, `protectedFields`, `freshness` (`unknown|stale|current`), `context` (`world|battleground|other_instance|unknown`). Un candidat fatal est un indicateur public à vérifier, pas une attribution de tueur.
- `.Start()` réinitialise les compteurs, relève la disponibilité et active l'écoute ; `.Stop()` invalide la génération de tentatives ; `.Show()` affiche seulement le bilan assaini.

- [ ] **Step 1: Write the failing tests** dans `tests/lua/death_recap_probe_spec.lua` : `api_absent`/`call_error` sans plantage ; `secret_container`/`secret_field` sans inspection ; `stale_recap` jamais current ; `unknown_clock` freshness inconnue ; `superseded_death` et `stop_invalidates_retries` ; `pve_or_unknown_pet` sans attribution ; `multiple_fatal_candidates` ambigu ; `repeat_reads_not_added` ; `context_kept_per_death` ; `zero_side_effects` avec registre/sauvegardes/file réseau inchangés.
- [ ] **Step 2: Run tests to verify they fail** : `node tools/test-native.mjs`, après ajout du chargement de la suite ; échec attendu sur le module absent.
- [ ] **Step 3: Implement the module** en code original. Refuser si le garde de valeurs manque/échoue ; protéger conteneur et accès table avant parcours. Limiter à 64 entrées inspectées par lecture, trois tentatives à 0,3/1/2 secondes après la mort, un numéro de génération et aucun ticker permanent. Les champs sourceName/sourceGUID/sourceFlags/overkill/timestamp restent des champs observés à vérifier, pas un contrat garanti. Ne comparer des temps qu'après validation d'une échelle publique compatible ; sinon freshness unknown. Les rapports successifs remplacent l'échantillon courant plutôt que cumuler les lignes.
- [ ] **Step 4: Run meaningful checks** : `node tools/test-native.mjs` et `git diff --check` ; toutes les suites existantes et la nouvelle passent. Vérifier le TOC et les fichiers du paquet sans ajouter la sonde au TOC principal.
- [ ] **Step 5: Commit and prepare a separate diagnostic package** ; vérifier que seuls les fichiers du compagnon nécessaires sont inclus, préserver la 0.5.6 publiée et les sauvegardes utilisateur. Consigner l'empreinte et la procédure avant installation autorisée dans le client.
- [ ] **Step 6: Validate on the actual client** : relever présence/appels d'abord, puis une mort réelle avec son contexte, délai et compteurs. Pas de demande de morts répétées sans nouvelle hypothèse. Les valeurs protégées, données anciennes ou identités incomplètes donnent un résultat non exploitable. Aucune création d'incident avant une tranche suivante et une preuve réelle suffisante.

## Self-review

La tâche couvre seulement l'observation requise pour REQ-002/004, pas leur livraison complète. Les cinq classes du Review Focus ont des tests nommés. Les identités complètes, la preuve d'un kill ennemi, les points, l'interface et les alertes sont des tranches distinctes ; rien dans ce plan ne change leurs règles. Exécution non commencée à l'issue de l'étude HeadHunter du 6 novembre 2026.
