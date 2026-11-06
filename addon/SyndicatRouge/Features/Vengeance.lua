local _, ns = ...
local V = ns.Validation
ns.Vengeance = {}
function ns.Vengeance.Reward(db,record)
    if record.rewardRule~=2 then return #record.incidentIds*ns.Config.reputationPerIncident end
    local incidents={};for _,id in ipairs(record.incidentIds)do incidents[#incidents+1]=db.incidents[id] end
    local reward,_,reason=ns.BountyRules.Calculate(incidents)
    return reward,reason
end

function ns.Vengeance.Normalize(db, input)
    if type(input) ~= "table" or not V.String(input.id) or input.guildId ~= db.guildId
        or not V.String(input.enemyId) or not V.Integer(input.occurredAt)
        or type(input.incidentIds) ~= "table" then return nil, "invalid_vengeance" end
    local scopeOK, scopeReason = ns.PvpScope.Validate(input.instanceType)
    if not scopeOK then return nil, scopeReason end
    local avenger = V.Actor(input.avenger)
    if not avenger or avenger.id == input.enemyId then return nil, "invalid_avenger" end
    local ids, unique = {}, {}
    for index, id in pairs(input.incidentIds) do
        if not V.Integer(index, 1, ns.Config.maxRecords) or not V.String(id) or unique[id] then
            return nil, "invalid_incident_ids"
        end
        unique[id] = true; ids[#ids + 1] = id
    end
    if #ids == 0 or #ids > ns.Config.maxRecords then return nil, "invalid_incident_ids" end
    for index = 1, #ids do
        if input.incidentIds[index] == nil then return nil, "invalid_incident_ids" end
    end
    table.sort(ids)
    local record = { id = input.id, guildId = db.guildId, enemyId = input.enemyId,
        avenger = avenger, occurredAt = input.occurredAt, incidentIds = ids }
    record.instanceType = input.instanceType
    if input.rewardRule~=nil and input.rewardRule~=1 and input.rewardRule~=2 then return nil,"unsupported_reward_rule" end
    if input.rewardRule==2 then record.rewardRule=2 end
    for _, id in ipairs(ids) do
        local incident = db.incidents[id]
        if not incident then return nil, "unknown_incident" end
        if incident.enemy.id ~= record.enemyId then return nil, "enemy_mismatch" end
        if incident.occurredAt > record.occurredAt then return nil, "vengeance_before_incident" end
    end
    return record
end

function ns.Vengeance.Resolve(db, input)
    local record, reason = ns.Vengeance.Normalize(db, input)
    if not record then return false, reason end
    local ids = record.incidentIds
    if db.vengeances[record.id] then
        local old = V.Copy(db.vengeances[record.id]); old.reward = nil
        return false, V.Same(old, record) and "duplicate" or "vengeance_id_conflict"
    end
    if V.Count(db.vengeances) >= ns.Config.maxRecords then return false, "capacity" end
    -- Validate every referenced incident before applying any transition.
    for _, id in ipairs(ids) do
        local incident = db.incidents[id]
        if incident.vengeanceId then return false, "incident_closed" end
    end
    local reward,errorCode=ns.Vengeance.Reward(db,record)
    if not reward then return false,errorCode end
    record.reward=reward
    db.vengeances[record.id] = record
    for _, id in ipairs(ids) do db.incidents[id].vengeanceId = record.id end
    return true, V.Copy(record)
end
