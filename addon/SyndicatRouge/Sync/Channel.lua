local _,ns=...
local G,V=ns.Guild,ns.Validation
local Channel={};ns.Channel=Channel
function Channel.New(context,root,roster)
    if root.guilds~=nil and type(root.guilds)~="table" then return nil,"invalid_guild_cache" end
    local saved=root.guilds and root.guilds[context.guildId]
    local session,reason
    if saved then session,reason=G.Restore(saved,context.guildId,context.owner.id,roster)
    else session,reason=G.New(context.guildId,context.owner.id,roster) end
    if not session then return nil,reason end
    local delivery;delivery,reason=ns.Delivery.Open(root,context)
    if not delivery then return nil,reason end
    return {context=context,root=root,session=session,delivery=delivery,seen={},peers={},acks=0,received=0}
end
function Channel.Commit(channel,session,delivery)
    local snapshot=G.Snapshot(session)
    local checked,reason=G.Restore(snapshot,session.guildId,session.ownerId,session.members)
    if not checked then return false,reason end
    local valid;valid,reason=ns.Delivery.Validate(delivery or channel.delivery,channel.context)
    if not valid then return false,reason end
    channel.root.guilds=channel.root.guilds or {}
    channel.root.guildDelivery=channel.root.guildDelivery or {}
    channel.root.guildDelivery[session.guildId]=valid;channel.delivery=valid
    channel.root.guilds[session.guildId]=snapshot;channel.session=checked
    return true
end
function Channel.Envelope(c,kind,id,target)
    return {version=1,guildId=c.context.guildId,senderId=c.context.owner.id,kind=kind,id=id,target=target}
end
function Channel.State(c,id,target)
    for _,row in pairs(c.session.incidents) do
        if row.source=="demo" and not c.context.test then return nil,"demo_not_shareable" end
        if c.context.test and (row.source~="demo" or row.id:sub(1,5)~="test:") then return nil,"test_records_only" end
    end
    if c.context.test then
        for _,row in pairs(c.session.claims) do if row.id:sub(1,5)~="test:" then return nil,"test_records_only" end end
    end
    -- Collected reports have their own paged, author-confirmed route. Never
    -- republish the full report-derived bounty ledger as a legacy union.
    local legacy={guildId=c.session.guildId,ownerId=c.session.ownerId,members=c.session.members,incidents={},claims={}}
    for id,row in pairs(c.session.incidents)do if id:sub(1,7)~="report:"then legacy.incidents[id]=row end end
    for id,row in pairs(c.session.claims)do
        local complete=true;for _,ref in ipairs(row.incidentIds)do if not legacy.incidents[ref]then complete=false;break end end
        if complete then legacy.claims[id]=row end
    end
    local msg,reason=ns.Protocol.Export(legacy)
    if not msg then return nil,reason end
    local out=Channel.Envelope(c,"state",id,target);out.message=msg;return out
end
function Channel.Receive(c,envelope,sender,roster)
    if type(envelope)~="table" or envelope.version~=1 or envelope.guildId~=c.context.guildId
        or envelope.senderId~=sender or not V.String(envelope.id,64) or not roster[sender] then return false,"invalid_envelope" end
    if envelope.target and envelope.target~=c.context.owner.id then return false,"other_target" end
    if sender==c.context.owner.id then return false,"self" end
    local key=sender..":"..envelope.id
    if c.seen[key] then return false,"duplicate" end
    if envelope.kind=="state" then
        if type(envelope.message)~="table" or type(envelope.message.incidents)~="table" then return false,"invalid_state" end
        for _,row in pairs(envelope.message.incidents) do
            if type(row)~="table" or (row.source=="demo" and not c.context.test) then return false,"demo_not_shareable" end
            if not c.context.test and ns.ReportsRuntime and not ns.ReportsRuntime.AllowIncident(row,sender,c.session)then return false,"report_author_confirmation_required"end
            if c.context.test and (row.source~="demo" or type(row.id)~="string" or row.id:sub(1,5)~="test:") then return false,"test_records_only" end
        end
        if c.context.test then
            if type(envelope.message.claims)~="table" then return false,"invalid_state" end
            for _,row in pairs(envelope.message.claims)do
                if type(row)~="table" or type(row.id)~="string" or row.id:sub(1,5)~="test:" then return false,"test_records_only" end
            end
        end
        if not c.context.test then
            if type(envelope.message.claims)~="table"then return false,"invalid_state"end
            for _,claim in pairs(envelope.message.claims)do
                if type(claim)~="table" or (not c.session.claims[claim.id] and (type(claim.avenger)~="table" or claim.avenger.id~=sender))then return false,"claim_author_confirmation_required"end
            end
        end
        local candidate,reason=G.Restore(G.Snapshot(c.session),c.context.guildId,c.context.owner.id,roster)
        if not candidate then return false,reason end
        local ok,result=G.Receive(candidate,envelope.message,sender)
        if not ok then return false,result end
        ok,reason=Channel.Commit(c,candidate)
        if not ok then return false,reason end
        c.received=c.received+1
    elseif envelope.kind=="thank" or envelope.kind=="thank_ack" then
        local delivery,reason
        if envelope.kind=="thank" then delivery,reason=ns.Delivery.Receive(c.delivery,c.session,envelope,sender)
        else delivery,reason=ns.Delivery.Acknowledge(c.delivery,c.session,envelope,sender) end
        if not delivery then return false,reason end
        local ok,errorCode=Channel.Commit(c,c.session,delivery)
        if not ok then return false,errorCode end
    elseif envelope.kind=="report" then
        if c.context.test then return false,"reports_not_in_simulation"end
        if type(envelope.report)~="table"then return false,"invalid_report_envelope"end
    elseif envelope.kind=="sighting" then
        if not ns.Sightings.Validate(envelope.sighting,c.context)then return false,"invalid_sighting"end
    elseif envelope.kind=="ack" then
        if not V.String(envelope.ack,64) then return false,"invalid_ack" end
    elseif envelope.kind~="hello" and envelope.kind~="test" then return false,"unknown_kind" end
    if V.Count(c.seen)>=512 then c.seen={} end
    c.seen[key]=true;c.peers[sender]=true
    return true,envelope.kind
end
function Channel.Change(c,operation,payload)
    if operation=="incident" and type(payload)=="table" and payload.source=="demo" and not c.context.test then return false,"demo_not_shareable" end
    if c.context.test and (operation=="incident" or operation=="claim") then
        if type(payload)~="table" or type(payload.id)~="string" or payload.id:sub(1,5)~="test:"
            or (operation=="incident" and payload.source~="demo") then return false,"test_records_only" end
    end
    if operation=="read" and type(payload)=="string" and payload:sub(1,7)=="thanks:" then
        local delivery,reason=ns.Delivery.Read(c.delivery,payload)
        if not delivery then return false,reason end
        return Channel.Commit(c,c.session,delivery)
    end
    local delivery=c.delivery
    if operation=="thank" then
        local reason;delivery,reason=ns.Delivery.Queue(c.delivery,c.session,payload)
        if not delivery then return false,reason end
        local note=ns.Notifications.All(c.session.db)[payload]
        if note.thanked then return Channel.Commit(c,c.session,delivery) end
    end
    local result=G.Execute(G.Snapshot(c.session),c.context.guildId,c.context.owner.id,c.session.members,operation,payload)
    if not result.ok then return false,result.reason end
    local session,reason=G.Restore(result.snapshot,c.context.guildId,c.context.owner.id,c.session.members)
    if not session then return false,reason end
    return Channel.Commit(c,session,delivery)
end
