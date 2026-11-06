# PvP reports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Collect guarded personal PvP death reports and progressively share them with verified guild members without treating relays or estimates as proved kills.

**Architecture:** Add a versioned report substore to the existing character profile, separate from existing ledgers and test profiles. Event-driven observations feed a bounded 15-second attack window and delayed recap classifier. Reuse existing GUILD framing and send gate for a bounded request/offer/page protocol; only author-confirmed exact reports may project into existing bounties. Preserve current four tabs and add compact controls/report rows.

**Tech Stack:** Lua/TOC Forever 1.60.1.70790; existing Fengari tests, native widgets, SavedVariables and GUILD addon transport.

**Spec:** User pasted request dated 2026-11-06; durable requirements REQ-027..031 in `docs/plans/death-note/requirements.md`.

## Global Constraints
- Forever only; pinned UI source eac30af597e5aaa43a60f6675ef5fdcea100375f.
- No protected-data inspection, alternative protected routes or unsupported custom-channel assumptions.
- Guild-only access; retain battleground/arena exclusions, duel exclusion, existing UI art and test isolation.
- No manual vengeance validation or claim of server proof; unknown fields remain absent.
- Defaults: 30-day retention, 5000 shared reports, 1000 personal, 200 observations, 128 recent attacks, 2 sync sources, 4 reports/page, 8 pages/source/session, 3 attempts, bounded queues.

## Review Focus
- Old character settings and unknown future report schema survive initialization unchanged.
- Stale/protected recap cannot attribute an earlier death to a new report.
- A cached target or unowned pet alone never proves a player killer.
- A delayed relay cannot upgrade conflicting content to author-confirmed status.
- Reconnection/test mode/guild departure cannot leak reports across guild or simulation scopes.

### Task 1: Report schema and retention store
Files: create `Reports/Schema.lua`, `Reports/Store.lua`, tests `tests/lua/reports_spec.lua`; update manifest/TOC.
Interfaces: `ReportSchema.Normalize(row,now,days)`, `ReportStore.Open(root,now)`, `Put(row,trust,now)`, `Cleanup(now)`, `List(personal)`, `Enrich(guid,actor)`.
- [x] Test validation, dates, dedup, identity enrichment, retention, limits, future schemas and author/relay conflicts.
- [x] Implement independent substore, immutable death facts and additive identity updates, author-only trust promotion.
- [x] Run targeted tests.

### Task 2: Public observations and death classifier
Files: create `Reports/Observer.lua`, `Reports/Detector.lua`, tests `tests/lua/death_reports_spec.lua`.
Interfaces: `EnemyObserver.Observe(unit)`, `ByGUID(guid)`, `Owner(guid)`, `DeathDetector.Attack(event)`, `Classify(entries,death,policy)`, `OnDeath()`, `Tick(dt)`.
- [x] Test player/PvE/pet/unknown/fatal-zero/estimated mixed deaths, stale recap, repeated PLAYER_DEAD and exclusions.
- [x] Guard every client return before inspection; subscribe CLEU only when unrestricted non-callback delivery exists; recap retry at 0.3/1/2 sec. Capture location/scope at death.
- [x] Run targeted and existing API tests.

### Task 3: Progressive sync and trust
Files: create `Reports/Sync.lua`, update `Sync/Native.lua`, `Sync/Channel.lua`, test isolated Lua clients.
Interfaces: `ReportSync.Start(context)`, `Reset()`, `Tick(dt)`, `Receive(envelope,sender)`, `Request()`; existing `GuildNative.Enqueue` bounds and GUILD gate retained.
- [x] Test direct victim match, malformed/flooded traffic, delayed offers, two-source limit, cursor pages, timeouts/retries, queue saturation, relays and author confirmation.
- [x] Implement lightweight seek, staggered offers, targeted bounded pages, relay TTL/hop=1 and dedup; no report-triggered broadcast loop.
- [x] Keep legacy union messages separate from report sync and avoid report snapshots as full-ledger broadcasts.

### Task 4: Existing UI integration and delivery
Files: create `Reports/Runtime.lua`; update Bootstrap/UI Window/Views, versions, docs and tests.
- [x] Add report rows to Journal, confidence/source/trust labels, activation/share/sync controls and mixed-finish policy, retention/cap controls in a small existing-style panel.
- [x] Project only exact author-confirmed, canonically identified deaths into bounties, idempotently; never auto-credit vengeance.
- [x] Run full local suites, package/inspect, install with backup, inspect simulator UI if available; record game-only tests separately.
- [x] Obtain fresh independent review, fix material issues, reconcile requirements and outcomes.

Execution authorized by user: implement after analysis; no additional plan approval gate. Existing direct-UI implementation choice applies. Prior 0.6.1 changes are uncommitted and must be preserved.
