local _, ns = ...
local V = ns.Validation
ns.Wanted = {}

function ns.Wanted.List(db)
    local groups, rows = {}, {}
    for _, incident in ipairs(ns.Incidents.List(db)) do
        local id = incident.enemy.id
        local group = groups[id]
        if not group then
            group = { enemy = V.Copy(incident.enemy), bounty = 0, openCount = 0,
                reward = 0, victimCount = 0, incidents = {}, lastIncident = V.Copy(incident), victims = {} }
            groups[id] = group
        end
        group.bounty = group.bounty + 1
        group.incidents[#group.incidents + 1] = incident
        group.victims[incident.victim.id] = true
        if not incident.vengeanceId then group.openCount = group.openCount + 1 end
    end
    for _, group in pairs(groups) do
        group.reward = group.openCount * ns.Config.reputationPerIncident
        group.victimCount = V.Count(group.victims); group.victims = nil
        rows[#rows + 1] = group
    end
    table.sort(rows, function(a,b)
        if (a.openCount > 0) ~= (b.openCount > 0) then return a.openCount > 0 end
        if a.bounty ~= b.bounty then return a.bounty > b.bounty end
        return a.enemy.id < b.enemy.id
    end)
    return rows
end
