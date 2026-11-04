local _, ns = ...
local V = ns.Validation
ns.Reputation = {}

function ns.Reputation.Ranking(db)
    local groups, rows = {}, {}
    for _, claim in pairs(db.vengeances) do
        local id = claim.avenger.id
        local group = groups[id]
        if not group then
            group = { member = V.Copy(claim.avenger), reputation = 0, victims = {},
                victimsAvenged = 0, vengeances = {}, latestTime = -1, latestId = "" }
            groups[id] = group
        end
        group.reputation = group.reputation + #claim.incidentIds * ns.Config.reputationPerIncident
        group.vengeances[#group.vengeances + 1] = V.Copy(claim)
        if claim.occurredAt > group.latestTime or (claim.occurredAt == group.latestTime and claim.id < group.latestId) then
            group.member = V.Copy(claim.avenger); group.latestTime = claim.occurredAt; group.latestId = claim.id
        end
        for _, incidentId in ipairs(claim.incidentIds) do group.victims[db.incidents[incidentId].victim.id] = true end
    end
    for _, row in pairs(groups) do
        row.victimsAvenged = V.Count(row.victims); row.victims = nil; row.latestTime = nil; row.latestId = nil
        table.sort(row.vengeances, V.Newest); rows[#rows + 1] = row
    end
    table.sort(rows, function(a,b)
        if a.reputation ~= b.reputation then return a.reputation > b.reputation end
        if a.victimsAvenged ~= b.victimsAvenged then return a.victimsAvenged > b.victimsAvenged end
        return a.member.id < b.member.id
    end)
    return rows
end
