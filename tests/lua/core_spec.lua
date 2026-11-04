local ns = ...
local passed = 0
local function eq(actual, expected)
    assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
end
local function test(name, fn)
    local ok, message = pcall(fn)
    assert(ok, name .. ": " .. tostring(message))
    passed = passed + 1
end
local function actor(id, name, realm)
    return { id = id, name = name or id, realm = realm or "Forever" }
end
local function incident(id, enemy, victim, timestamp)
    return { id = id, guildId = "guild-A", enemy = actor(enemy or "enemy"),
        victim = actor(victim or "victim"), occurredAt = timestamp or 100,
        location = { zone = "Strangleronce" }, source = "demo" }
end
local function claim(id, ids, avenger, time)
    return { id = id, guildId = "guild-A", enemyId = "enemy", avenger = actor(avenger or "avenger"),
        occurredAt = time or 200, incidentIds = ids }
end
local function fresh() return assert(ns.Core.New("guild-A")) end

test("invalid records cannot mutate the store", function()
    local db = fresh()
    local row = incident("a"); row.occurredAt = 0/0
    eq(ns.Incidents.Add(db, row), false)
    row = incident("a"); row.guildId = "another-guild"
    eq(ns.Incidents.Add(db, row), false)
    row = incident("a"); row.location = { zone = "Test", x = 0.4 }
    eq(ns.Incidents.Add(db, row), false)
    eq(next(db.incidents), nil)
end)
test("identical incident duplicates are harmless; ID collisions are rejected", function()
    local db = fresh()
    eq(ns.Incidents.Add(db, incident("a")), true)
    local ok, reason = ns.Incidents.Add(db, incident("a")); eq(ok, false); eq(reason, "duplicate")
    ok, reason = ns.Incidents.Add(db, incident("a", nil, "someone-else"))
    eq(ok, false); eq(reason, "incident_id_conflict")
    eq(#ns.Wanted.List(db), 1); eq(ns.Wanted.List(db)[1].bounty, 1)
end)
test("input mutation cannot rewrite stored history", function()
    local db = fresh(); local row = incident("a")
    ns.Incidents.Add(db, row); row.enemy.name = "forged"; row.location.zone = "changed"
    eq(db.incidents.a.enemy.name, "enemy"); eq(db.incidents.a.location.zone, "Strangleronce")
end)
test("last known kill is chronological, not arrival order", function()
    local db = fresh(); ns.Incidents.Add(db, incident("new", nil, nil, 200))
    ns.Incidents.Add(db, incident("old", nil, nil, 100))
    eq(ns.Wanted.List(db)[1].lastIncident.id, "new")
end)
test("same character names on different realms stay separate", function()
    local db = fresh(); local a = incident("a", "enemy-realm-a"); a.enemy.name = "Mornecroc"
    local b = incident("b", "enemy-realm-b"); b.enemy.name = "Mornecroc"; b.enemy.realm = "Other"
    ns.Incidents.Add(db, a); ns.Incidents.Add(db, b); eq(#ns.Wanted.List(db), 2)
end)
test("one reputation per open incident and one notification per victim", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a")); ns.Incidents.Add(db, incident("b"))
    local ok, result = ns.Vengeance.Resolve(db, claim("v", {"a", "b"}))
    eq(ok, true); eq(result.reward, 2)
    eq(ns.Reputation.Ranking(db)[1].reputation, 2)
    eq(ns.Reputation.Ranking(db)[1].victimsAvenged, 1)
    eq(#ns.Notifications.List(db, "victim"), 1)
    eq(ns.Wanted.List(db)[1].openCount, 0)
    eq(ns.Wanted.List(db)[1].bounty, 2)
end)
test("a duplicate vengeance cannot issue another reward", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a"))
    ns.Vengeance.Resolve(db, claim("v", {"a"}))
    local ok, reason = ns.Vengeance.Resolve(db, claim("v", {"a"})); eq(ok, false); eq(reason, "duplicate")
    ok, reason = ns.Vengeance.Resolve(db, claim("v2", {"a"}, "other"))
    eq(ok, false); eq(reason, "incident_closed"); eq(#ns.Reputation.Ranking(db), 1)
end)
test("a reused vengeance ID with changed content is a conflict", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a")); ns.Incidents.Add(db, incident("b"))
    ns.Vengeance.Resolve(db, claim("v", {"a"}))
    local ok, reason = ns.Vengeance.Resolve(db, claim("v", {"b"}))
    eq(ok, false); eq(reason, "vengeance_id_conflict"); eq(db.incidents.b.vengeanceId, nil)
end)
test("a mixed invalid claim cannot partially close valid incidents", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a"))
    eq(ns.Vengeance.Resolve(db, claim("v", {"a", "missing"})), false)
    eq(db.incidents.a.vengeanceId, nil); eq(next(db.vengeances), nil)
    eq(#ns.Notifications.List(db, "victim"), 0)
end)
test("wrong enemy, foreign guild and pre-death vengeance are refused", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a"))
    local c = claim("v", {"a"}); c.enemyId = "another-enemy"
    eq(ns.Vengeance.Resolve(db, c), false)
    c = claim("v", {"a"}); c.guildId = "another-guild"
    eq(ns.Vengeance.Resolve(db, c), false)
    eq(ns.Vengeance.Resolve(db, claim("v", {"a"}, nil, 99)), false)
    eq(db.incidents.a.vengeanceId, nil)
end)
test("duplicate IDs inside a single claim do not multiply points", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a"))
    eq(ns.Vengeance.Resolve(db, claim("v", {"a", "a"})), false)
    eq(db.incidents.a.vengeanceId, nil)
end)
test("an enemy becomes wanted again only after a new incident", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a")); ns.Vengeance.Resolve(db, claim("v", {"a"}))
    ns.Incidents.Add(db, incident("b", nil, "victim2", 300))
    local row = ns.Wanted.List(db)[1]; eq(row.openCount, 1); eq(row.reward, 1); eq(row.bounty, 2)
    eq(ns.Reputation.Ranking(db)[1].reputation, 1)
end)
test("personal notification and thanks belong only to the victim", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a")); ns.Vengeance.Resolve(db, claim("v", {"a"}))
    eq(#ns.Notifications.List(db, "other"), 0)
    local n = ns.Notifications.List(db, "victim")[1]
    eq(ns.Notifications.Thank(db, n.id, "other"), false)
    eq(ns.Notifications.Thank(db, n.id, "victim"), true)
    eq(ns.Notifications.Thank(db, n.id, "victim"), false)
    eq(ns.Notifications.List(db, "victim")[1].thanked, true)
    eq(ns.Reputation.Ranking(db)[1].reputation, 1)
end)
test("snapshot roundtrip preserves identity, rewards and notification state", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a")); ns.Vengeance.Resolve(db, claim("v", {"a"}))
    ns.Notifications.Thank(db, ns.Notifications.List(db, "victim")[1].id, "victim")
    local snapshot = ns.Store.Snapshot(db); local restored = assert(ns.Store.Restore(snapshot, "guild-A"))
    eq(ns.Reputation.Ranking(restored)[1].reputation, 1)
    eq(ns.Notifications.List(restored, "victim")[1].thanked, true)
    snapshot.incidents.a.enemy.name = "mutated"
    eq(restored.incidents.a.enemy.name, "enemy")
end)
test("unknown schema, guild mismatch and forged reward cannot be restored", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a")); ns.Vengeance.Resolve(db, claim("v", {"a"}))
    local snapshot = ns.Store.Snapshot(db); snapshot.schemaVersion = 999
    eq(ns.Store.Restore(snapshot, "guild-A"), nil)
    snapshot = ns.Store.Snapshot(db); eq(ns.Store.Restore(snapshot, "other"), nil)
    snapshot.vengeances.v.reward = 999
    local restored = assert(ns.Store.Restore(snapshot, "guild-A"))
    eq(ns.Reputation.Ranking(restored)[1].reputation, 1)
end)
test("ranking ties have a deterministic identity order", function()
    local db = fresh(); ns.Incidents.Add(db, incident("a")); ns.Incidents.Add(db, incident("b", nil, "victim2"))
    ns.Vengeance.Resolve(db, claim("v1", {"a"}, "B")); ns.Vengeance.Resolve(db, claim("v2", {"b"}, "A"))
    eq(ns.Reputation.Ranking(db)[1].member.id, "A")
end)
return { passed = passed }
