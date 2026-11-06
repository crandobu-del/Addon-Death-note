local _, ns = ...
ns.Core = {}
function ns.Core.New(guildId) return ns.Store.New(guildId) end

function ns.Core.View(db, viewerId)
    local timeline = {}
    for _, incident in ipairs(ns.Incidents.List(db)) do
        timeline[#timeline + 1] = { id = incident.id, kind = "incident", occurredAt = incident.occurredAt, incident = incident }
    end
    for _, claim in pairs(db.vengeances) do
        timeline[#timeline + 1] = { id = claim.id, kind = "vengeance", occurredAt = claim.occurredAt,
            vengeance = ns.Validation.Copy(claim), enemy = ns.Validation.Copy(db.incidents[claim.incidentIds[1]].enemy) }
    end
    table.sort(timeline, ns.Validation.Newest)
    return { guildId = db.guildId, guildName = ns.Config.guildName, target = ns.target,
        wanted = ns.Wanted.List(db), ranking = ns.Reputation.Ranking(db), journal = timeline,
        notifications = ns.Notifications.List(db, viewerId) }
end

-- Development host adapter: all rules above are also callable directly from Lua.
-- There is no network receiver or game-event subscription in this tranche.
function ns.Core.Execute(snapshot, guildId, operation, payload, viewerId)
    local db, reason
    if snapshot then db, reason = ns.Store.Restore(snapshot, guildId) else db, reason = ns.Store.New(guildId) end
    if not db then return { ok = false, reason = reason } end
    if operation == "incident" or operation == "vengeance" then
        payload, reason = ns.PvpScope.Prepare(payload)
        if not payload then return { ok = false, reason = reason, snapshot = ns.Store.Snapshot(db), view = ns.Core.View(db, viewerId) } end
    end
    local ok, result = true, nil
    if operation == "incident" then ok, result = ns.Incidents.Add(db, payload)
    elseif operation == "vengeance" then ok, result = ns.Vengeance.Resolve(db, payload)
    elseif operation == "thank" then ok, result = ns.Notifications.Thank(db, payload, viewerId)
    elseif operation == "read" then ok, result = ns.Notifications.Read(db, payload, viewerId)
    elseif operation ~= "view" then ok, result = false, "unknown_operation" end
    return { ok = ok, reason = type(result) == "string" and result or nil,
        snapshot = ns.Store.Snapshot(db), view = ns.Core.View(db, viewerId) }
end
