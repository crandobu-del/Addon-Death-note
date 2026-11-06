local _, ns = ...
local V = ns.Validation
local G = {}
ns.Guild = G

function G.New(guildId, ownerId, roster)
    local db, reason = ns.Store.New(guildId)
    if not db then return nil, reason end
    if type(roster) ~= "table" then return nil, "invalid_roster" end
    local members = {}
    for _, input in pairs(roster) do
        local member = V.Actor(input)
        if not member or members[member.id] then return nil, "invalid_roster" end
        members[member.id] = member
    end
    if not members[ownerId] then return nil, "owner_not_member" end
    return { version = 1, guildId = guildId, ownerId = ownerId, members = members,
        incidents = {}, claims = {}, notificationState = {}, db = db, conflicts = {} }
end

local function rebuild(session, incidents, claims, privateState)
    local candidate = { guildId = session.guildId, ownerId = session.ownerId,
        members = session.members, incidents = incidents, claims = claims }
    local message, reason = ns.Protocol.Export(candidate)
    if not message then return nil, reason end
    local db = ns.Store.New(session.guildId)
    local incidentMap, claimMap, owners = {}, {}, {}
    for _, incident in ipairs(message.incidents) do
        local ok, row = ns.Incidents.Add(db, incident)
        if not ok then return nil, row end
        incidentMap[row.id] = V.Copy(row)
    end
    for _, claim in ipairs(message.claims) do
        claimMap[claim.id] = claim
        for _, incidentId in ipairs(claim.incidentIds) do
            owners[incidentId] = owners[incidentId] or {}
            owners[incidentId][#owners[incidentId] + 1] = claim.id
        end
    end
    local conflicts = {}
    for incidentId, ids in pairs(owners) do
        if #ids > 1 then
            table.sort(ids)
            for _, id in ipairs(ids) do
                conflicts[id] = conflicts[id] or { claimId = id, incidentIds = {} }
                conflicts[id].incidentIds[#conflicts[id].incidentIds + 1] = incidentId
            end
        end
    end
    for _, conflict in pairs(conflicts) do table.sort(conflict.incidentIds) end
    for _, claim in ipairs(message.claims) do
        if not conflicts[claim.id] then
            local ok, result = ns.Vengeance.Resolve(db, claim)
            if not ok then return nil, result end
        end
    end
    local personal = privateState or session.notificationState
    if type(personal) ~= "table" or V.Count(personal) > ns.Config.maxRecords then return nil, "invalid_private_state" end
    local known = ns.Notifications.All(db)
    local validatedPrivate = {}
    for id, state in pairs(personal) do
        if not V.String(id, 300) or type(state) ~= "table" or type(state.read) ~= "boolean"
            or type(state.thanked) ~= "boolean" then return nil, "invalid_private_state" end
        validatedPrivate[id] = { read = state.read, thanked = state.thanked }
        if known[id] and known[id].victimId == session.ownerId then db.notificationState[id] = V.Copy(validatedPrivate[id]) end
    end
    return { db = db, incidents = incidentMap, claims = claimMap,
        notificationState = validatedPrivate, conflicts = conflicts }
end

local function apply(session, candidate)
    for key, value in pairs(candidate) do session[key] = value end
end

function G.Receive(session, message, transportSender)
    local decoded, reason = ns.Protocol.Decode(message, session.guildId, transportSender, session.members)
    if not decoded then return false, reason end
    local incidents, claims = V.Copy(session.incidents), V.Copy(session.claims)
    local changed = false
    for _, row in ipairs(decoded.incidents) do
        if incidents[row.id] and not V.Same(incidents[row.id], row) then return false, "incident_id_conflict" end
        if not incidents[row.id] then incidents[row.id] = row; changed = true end
    end
    for _, row in ipairs(decoded.claims) do
        if claims[row.id] and not V.Same(claims[row.id], row) then return false, "vengeance_id_conflict" end
        if not claims[row.id] then claims[row.id] = row; changed = true end
    end
    local candidate, errorCode = rebuild(session, incidents, claims)
    if not candidate then return false, errorCode end
    apply(session, candidate)
    return true, changed and "merged" or "unchanged"
end

function G.AddIncident(session, input)
    local db = ns.Store.Restore(ns.Store.Snapshot(session.db), session.guildId)
    local ok, record = ns.Incidents.Add(db, input)
    if not ok then return false, record end
    local incidents = V.Copy(session.incidents); incidents[record.id] = record
    local candidate, reason = rebuild(session, incidents, session.claims)
    if not candidate then return false, reason end
    apply(session, candidate); return true
end

function G.Claim(session, input)
    input=V.Copy(input)
    if type(input)=="table" and input.rewardRule==nil then input.rewardRule=2 end
    if type(input) ~= "table" or type(input.avenger) ~= "table" or input.avenger.id ~= session.ownerId then
        return false, "claim_owner_mismatch"
    end
    local normalized, validationError = ns.Vengeance.Normalize(session.db, input)
    if not normalized then return false, validationError end
    if session.claims[normalized.id] then
        return false, V.Same(session.claims[normalized.id], normalized) and "duplicate" or "vengeance_id_conflict"
    end
    local db = ns.Store.Restore(ns.Store.Snapshot(session.db), session.guildId)
    local ok, record = ns.Vengeance.Resolve(db, input)
    if not ok then return false, record end
    record.reward = nil
    local claims = V.Copy(session.claims); claims[record.id] = record
    local candidate, reason = rebuild(session, session.incidents, claims)
    if not candidate then return false, reason end
    apply(session, candidate); return true
end

function G.Snapshot(session)
    return V.Copy({ version = 1, guildId = session.guildId, ownerId = session.ownerId,
        incidents = session.incidents, claims = session.claims, notificationState = session.notificationState })
end

function G.Restore(snapshot, guildId, ownerId, roster)
    local session, reason = G.New(guildId, ownerId, roster)
    if not session then return nil, reason end
    if type(snapshot) ~= "table" or snapshot.version ~= 1 or snapshot.guildId ~= guildId
        or snapshot.ownerId ~= ownerId then return nil, "invalid_session" end
    for _, key in ipairs({"incidents", "claims"}) do
        if type(snapshot[key]) ~= "table" or V.Count(snapshot[key]) > ns.Protocol.maxRecords then return nil, "session_limit" end
        for id, row in pairs(snapshot[key]) do
            if type(row) ~= "table" or row.id ~= id then return nil, "invalid_session_key" end
        end
    end
    local candidate, errorCode = rebuild(session, snapshot.incidents, snapshot.claims, snapshot.notificationState)
    if not candidate then return nil, errorCode end
    apply(session, candidate); return session
end

function G.View(session)
    local view = ns.Core.View(session.db, session.ownerId)
    view.owner = V.Copy(session.members[session.ownerId])
    view.conflicts = {}
    local pending = {}
    for _, conflict in pairs(session.conflicts) do
        local row = V.Copy(conflict); row.avenger = V.Copy(session.claims[row.claimId].avenger)
        view.conflicts[#view.conflicts + 1] = row
        for _, incidentId in ipairs(session.claims[row.claimId].incidentIds) do pending[incidentId] = true end
    end
    table.sort(view.conflicts, function(a,b) return a.claimId < b.claimId end)
    view.pendingIncidentIds = {}
    for incidentId in pairs(pending) do view.pendingIncidentIds[#view.pendingIncidentIds + 1] = incidentId end
    table.sort(view.pendingIncidentIds)
    view.incidentCount = V.Count(session.incidents)
    view.claimCount = V.Count(session.claims)
    return view
end

function G.Execute(snapshot, guildId, ownerId, roster, operation, payload, senderId)
    local session, reason
    if snapshot then session, reason = G.Restore(snapshot, guildId, ownerId, roster)
    else session, reason = G.New(guildId, ownerId, roster) end
    if not session then return { ok = false, reason = reason } end
    local ok, result = true, nil
    if operation == "incident" then ok, result = G.AddIncident(session, payload)
    elseif operation == "claim" then ok, result = G.Claim(session, payload)
    elseif operation == "receive" then ok, result = G.Receive(session, payload, senderId)
    elseif operation == "thank" or operation == "read" then
        local fn = operation == "thank" and ns.Notifications.Thank or ns.Notifications.Read
        ok, result = fn(session.db, payload, ownerId)
        for id, state in pairs(session.db.notificationState) do session.notificationState[id] = V.Copy(state) end
    elseif operation ~= "view" and operation ~= "export" then ok, result = false, "unknown_operation" end
    local message, exportError = ns.Protocol.Export(session)
    if not message then return { ok = false, reason = exportError } end
    return { ok = ok, reason = result, snapshot = G.Snapshot(session), view = G.View(session), message = message }
end
