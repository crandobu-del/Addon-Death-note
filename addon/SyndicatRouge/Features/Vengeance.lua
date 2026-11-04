local _, ns = ...
local V = ns.Validation
ns.Vengeance = {}

function ns.Vengeance.Resolve(db, input)
    if type(input) ~= "table" or not V.String(input.id) or input.guildId ~= db.guildId
        or not V.String(input.enemyId) or not V.Integer(input.occurredAt)
        or type(input.incidentIds) ~= "table" then return false, "invalid_vengeance" end
    local avenger = V.Actor(input.avenger)
    if not avenger or avenger.id == input.enemyId then return false, "invalid_avenger" end
    local ids, unique = {}, {}
    for index, id in pairs(input.incidentIds) do
        if not V.Integer(index, 1, ns.Config.maxRecords) or not V.String(id) or unique[id] then
            return false, "invalid_incident_ids"
        end
        unique[id] = true; ids[#ids + 1] = id
    end
    if #ids == 0 or #ids > ns.Config.maxRecords then return false, "invalid_incident_ids" end
    table.sort(ids)
    local record = { id = input.id, guildId = db.guildId, enemyId = input.enemyId,
        avenger = avenger, occurredAt = input.occurredAt, incidentIds = ids }
    if db.vengeances[record.id] then
        local old = V.Copy(db.vengeances[record.id]); old.reward = nil
        return false, V.Same(old, record) and "duplicate" or "vengeance_id_conflict"
    end
    if V.Count(db.vengeances) >= ns.Config.maxRecords then return false, "capacity" end
    -- Validate every referenced incident before applying any transition.
    for _, id in ipairs(ids) do
        local incident = db.incidents[id]
        if not incident then return false, "unknown_incident" end
        if incident.enemy.id ~= record.enemyId then return false, "enemy_mismatch" end
        if incident.occurredAt > record.occurredAt then return false, "vengeance_before_incident" end
        if incident.vengeanceId then return false, "incident_closed" end
    end
    record.reward = #ids * ns.Config.reputationPerIncident
    db.vengeances[record.id] = record
    for _, id in ipairs(ids) do db.incidents[id].vengeanceId = record.id end
    return true, V.Copy(record)
end
