local _, ns = ...
local V = ns.Validation
local P = { version = 1, maxRecords = 128, maxBudget = 131072 }
ns.Protocol = P

local function array(value,limit)
    if type(value) ~= "table" then return nil end
    local count = V.Count(value)
    if count > (limit or P.maxRecords) then return nil end
    for key in pairs(value) do if not V.Integer(key, 1, count) then return nil end end
    return count
end
local function budget(value)
    if type(value) == "string" then return #value * 2 + 8 end
    if type(value) ~= "table" then return 24 end
    local size = 8
    for key, item in pairs(value) do size = size + budget(key) + budget(item) end
    return size
end
local function identityMatches(actor, member)
    return actor.id == member.id and actor.name == member.name and actor.realm == member.realm
end

function P.Decode(message, guildId, transportSender, members, internal)
    if type(message) ~= "table" or message.version ~= P.version then return nil, "protocol_version" end
    if message.guildId ~= guildId then return nil, "guild_mismatch" end
    if message.senderId ~= transportSender or not members[transportSender] then return nil, "sender_mismatch" end
    local limit=internal and ns.Config.maxRecords or P.maxRecords
    if not array(message.incidents,limit) or not array(message.claims,limit) then return nil, "message_limit" end
    local db = ns.Store.New(guildId)
    local normalized = { version = P.version, guildId = guildId, senderId = transportSender,
        incidents = {}, claims = {} }
    for _, input in ipairs(message.incidents) do
        local ok, record = ns.Incidents.Add(db, input)
        if not ok then return nil, record end
        if not members[record.victim.id] then return nil, "victim_not_member" end
        if not identityMatches(record.victim, members[record.victim.id]) then return nil, "member_identity_mismatch" end
        normalized.incidents[#normalized.incidents + 1] = record
    end
    local seen = {}
    for _, input in ipairs(message.claims) do
        local claim, reason = ns.Vengeance.Normalize(db, input)
        if not claim then return nil, reason end
        if seen[claim.id] then return nil, "duplicate_claim_id" end
        if not members[claim.avenger.id] then return nil, "avenger_not_member" end
        if not identityMatches(claim.avenger, members[claim.avenger.id]) then return nil, "member_identity_mismatch" end
        seen[claim.id] = true
        normalized.claims[#normalized.claims + 1] = claim
    end
    if not internal and budget(normalized) > P.maxBudget then return nil, "message_budget" end
    table.sort(normalized.incidents, function(a,b) return a.id < b.id end)
    table.sort(normalized.claims, function(a,b) return a.id < b.id end)
    return normalized
end

function P.Export(session,internal)
    local message = { version = P.version, guildId = session.guildId, senderId = session.ownerId,
        incidents = {}, claims = {} }
    for _, row in pairs(session.incidents) do
        local incident = V.Copy(row); incident.vengeanceId = nil
        message.incidents[#message.incidents + 1] = incident
    end
    for _, row in pairs(session.claims) do message.claims[#message.claims + 1] = V.Copy(row) end
    return P.Decode(message, session.guildId, session.ownerId, session.members,internal)
end
