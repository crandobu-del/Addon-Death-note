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
    return {context=context,root=root,session=session,seen={},peers={},acks=0,received=0}
end
function Channel.Commit(channel,session)
    local snapshot=G.Snapshot(session)
    local checked,reason=G.Restore(snapshot,session.guildId,session.ownerId,session.members)
    if not checked then return false,reason end
    channel.root.guilds=channel.root.guilds or {}
    channel.root.guilds[session.guildId]=snapshot;channel.session=checked
    return true
end
function Channel.Envelope(c,kind,id,target)
    return {version=1,guildId=c.context.guildId,senderId=c.context.owner.id,kind=kind,id=id,target=target}
end
function Channel.State(c,id,target)
    for _,row in pairs(c.session.incidents) do if row.source=="demo" then return nil,"demo_not_shareable" end end
    local msg,reason=ns.Protocol.Export(c.session)
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
            if type(row)~="table" or row.source=="demo" then return false,"demo_not_shareable" end
        end
        local candidate,reason=G.Restore(G.Snapshot(c.session),c.context.guildId,c.context.owner.id,roster)
        if not candidate then return false,reason end
        local ok,result=G.Receive(candidate,envelope.message,sender)
        if not ok then return false,result end
        ok,reason=Channel.Commit(c,candidate)
        if not ok then return false,reason end
        c.received=c.received+1
    elseif envelope.kind=="ack" then
        if not V.String(envelope.ack,64) then return false,"invalid_ack" end
    elseif envelope.kind~="hello" and envelope.kind~="test" then return false,"unknown_kind" end
    if V.Count(c.seen)>=512 then c.seen={} end
    c.seen[key]=true;c.peers[sender]=true
    return true,envelope.kind
end
function Channel.Change(c,operation,payload)
    if operation=="incident" and type(payload)=="table" and payload.source=="demo" then return false,"demo_not_shareable" end
    local result=G.Execute(G.Snapshot(c.session),c.context.guildId,c.context.owner.id,c.session.members,operation,payload)
    if not result.ok then return false,result.reason end
    local session,reason=G.Restore(result.snapshot,c.context.guildId,c.context.owner.id,c.session.members)
    if not session then return false,reason end
    return Channel.Commit(c,session)
end
