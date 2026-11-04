local _, ns = ...
local V = ns.Validation
ns.Incidents = {}

function ns.Incidents.Add(db, input)
    if type(input) ~= "table" or not V.String(input.id) or input.guildId ~= db.guildId
        or not V.Integer(input.occurredAt) then return false, "invalid_incident" end
    local enemy, victim, location = V.Actor(input.enemy), V.Actor(input.victim), V.Location(input.location)
    if not enemy or not victim or not location or enemy.id == victim.id then return false, "invalid_incident" end
    if input.source ~= "demo" and input.source ~= "manual" and input.source ~= "observed" then
        return false, "invalid_source"
    end
    local record = { id = input.id, guildId = db.guildId, enemy = enemy, victim = victim,
        location = location, occurredAt = input.occurredAt, source = input.source }
    if db.incidents[record.id] then
        local old = V.Copy(db.incidents[record.id]); old.vengeanceId = nil
        return false, V.Same(old, record) and "duplicate" or "incident_id_conflict"
    end
    if V.Count(db.incidents) >= ns.Config.maxRecords then return false, "capacity" end
    db.incidents[record.id] = record
    return true, V.Copy(record)
end

function ns.Incidents.List(db)
    local rows = {}
    for _, row in pairs(db.incidents) do rows[#rows + 1] = V.Copy(row) end
    table.sort(rows, V.Newest)
    return rows
end
