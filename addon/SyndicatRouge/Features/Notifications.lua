local _, ns = ...
local V = ns.Validation
ns.Notifications = {}

function ns.Notifications.All(db)
    local notifications = {}
    for _, claim in pairs(db.vengeances) do
        local victims = {}
        for _, incidentId in ipairs(claim.incidentIds) do
            local incident = db.incidents[incidentId]
            if not victims[incident.victim.id] then
                victims[incident.victim.id] = { victim = incident.victim, enemy = incident.enemy, count = 0 }
            end
            victims[incident.victim.id].count = victims[incident.victim.id].count + 1
        end
        for victimId, details in pairs(victims) do
            local id = tostring(#claim.id) .. ":" .. claim.id .. victimId
            local state = db.notificationState[id] or { read = false, thanked = false }
            notifications[id] = { id = id, victimId = victimId, victim = V.Copy(details.victim),
                enemy = V.Copy(details.enemy), avenger = V.Copy(claim.avenger),
                occurredAt = claim.occurredAt, reward = claim.reward, incidentCount = details.count,
                read = state.read, thanked = state.thanked }
        end
    end
    return notifications
end
function ns.Notifications.List(db, viewerId)
    local rows = {}
    for _, row in pairs(ns.Notifications.All(db)) do
        if row.victimId == viewerId then rows[#rows + 1] = row end
    end
    table.sort(rows, V.Newest)
    return rows
end
local function stateFor(db, id, viewerId)
    local row = ns.Notifications.All(db)[id]
    if not row or row.victimId ~= viewerId then return nil end
    if not db.notificationState[id] then db.notificationState[id] = { read = false, thanked = false } end
    return db.notificationState[id]
end
function ns.Notifications.Read(db, id, viewerId)
    local state = stateFor(db, id, viewerId)
    if not state then return false, "unknown_notification" end
    state.read = true; return true
end
function ns.Notifications.Thank(db, id, viewerId)
    local state = stateFor(db, id, viewerId)
    if not state then return false, "unknown_notification" end
    if state.thanked then return false, "duplicate" end
    state.read = true; state.thanked = true
    return true
end
