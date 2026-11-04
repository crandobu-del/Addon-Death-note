local _, ns = ...
local V = ns.Validation
ns.Store = {}

function ns.Store.New(guildId)
    if not V.String(guildId) then return nil, "invalid_guild" end
    return { schemaVersion = ns.Config.schemaVersion, guildId = guildId,
        incidents = {}, vengeances = {}, notificationState = {} }
end
function ns.Store.Snapshot(db) return V.Copy(db) end

function ns.Store.Restore(snapshot, guildId)
    if type(snapshot) ~= "table" or snapshot.schemaVersion ~= ns.Config.schemaVersion then
        return nil, "unsupported_schema"
    end
    if snapshot.guildId ~= guildId then return nil, "guild_mismatch" end
    if type(snapshot.incidents) ~= "table" or type(snapshot.vengeances) ~= "table"
        or type(snapshot.notificationState) ~= "table" then return nil, "invalid_snapshot" end
    if V.Count(snapshot.incidents) > ns.Config.maxRecords or V.Count(snapshot.vengeances) > ns.Config.maxRecords
        or V.Count(snapshot.notificationState) > ns.Config.maxRecords then return nil, "capacity" end
    local db, reason = ns.Store.New(guildId)
    if not db then return nil, reason end
    for key, incident in pairs(snapshot.incidents) do
        if type(incident) ~= "table" or key ~= incident.id then return nil, "invalid_incident_key" end
        local ok, errorCode = ns.Incidents.Add(db, incident)
        if not ok then return nil, errorCode end
    end
    local claims = {}
    for key, claim in pairs(snapshot.vengeances) do
        if type(claim) ~= "table" or key ~= claim.id then return nil, "invalid_vengeance_key" end
        if not V.Integer(claim.occurredAt) then return nil, "invalid_time" end
        claims[#claims + 1] = claim
    end
    table.sort(claims, function(a, b)
        if a.occurredAt ~= b.occurredAt then return a.occurredAt < b.occurredAt end
        return a.id < b.id
    end)
    for _, claim in ipairs(claims) do
        local ok, errorCode = ns.Vengeance.Resolve(db, claim)
        if not ok then return nil, errorCode end
    end
    -- Closure and rewards are reconstructed from validated claims, not trusted counters.
    local known = ns.Notifications.All(db)
    for id, state in pairs(snapshot.notificationState) do
        if not known[id] or type(state) ~= "table" or type(state.read) ~= "boolean"
            or type(state.thanked) ~= "boolean" then return nil, "invalid_notification_state" end
        db.notificationState[id] = { read = state.read, thanked = state.thanked }
    end
    return db
end
