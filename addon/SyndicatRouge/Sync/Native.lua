local _,ns=...
local N={prefix="SRGuild1",queue={},pool={},pending={},counter=0,status="inactive",clock=0};ns.GuildNative=N
local C,Ch=ns.GuildContext,ns.Channel
local function say(s) print("DEATH NOTE : "..s) end
local function refresh()
    if N.changed then N.changed() end
end
local function clear(reason)
    N.channel=nil;N.queue={};N.pool={};N.pending={};N.status=reason;refresh()
end
local function current()
    local ok,context,reason=pcall(C.Current)
    if not ok then return nil,"guild_context_unavailable" end
    return context,reason
end
local function restricted()
    if not C_ChatInfo or not C_ChatInfo.AreOutgoingAddonChatMessagesRestricted then return true end
    local ok,value=pcall(C_ChatInfo.AreOutgoingAddonChatMessagesRestricted)
    return not ok or not C.Public(value) or value~=false
end
local function nextId()
    N.counter=N.counter+1
    return N.nonce.."-"..N.counter
end
function N.Enqueue(envelope,expectsAck)
    if not envelope then return false,"missing_envelope" end
    local packets,reason=ns.Wire.Packets(envelope,envelope.id)
    if not packets then return false,reason end
    if #N.queue+#packets>1500 then return false,"queue_limit" end
    for _,packet in ipairs(packets) do N.queue[#N.queue+1]=packet end
    if expectsAck then N.pending[envelope.id]={kind=envelope.kind,at=N.clock,peers={}} end
    return true
end
local function state(target)
    local envelope,reason=Ch.State(N.channel,nextId(),target)
    if not envelope then return false,reason end
    return N.Enqueue(envelope,true)
end
function N.Start()
    if not N.runtime or not N.runtime.writable then return false,"profile_not_writable" end
    clear("initializing")
    local context,reason=current()
    if not context then N.status=reason;return false,reason end
    if not C_ChatInfo or not C_ChatInfo.RegisterAddonMessagePrefix or not C_ChatInfo.SendAddonMessage then N.status="chat_api_unavailable";return false,N.status end
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,N.prefix)
    if not ok or not C.Public(result) or (result~=0 and result~=1) then N.status="prefix_registration_failed";return false,N.status end
    local saved=N.runtime.root.guilds
    if saved~=nil and type(saved)~="table" then N.status="invalid_guild_cache";return false,N.status end
    local roster
    roster,reason=C.Roster(context,saved and saved[context.guildId])
    if not roster then N.status=reason;return false,reason end
    N.channel,reason=Ch.New(context,N.runtime.root,roster)
    if not N.channel then N.status=reason;return false,reason end
    local committed
    committed,reason=Ch.Commit(N.channel,N.channel.session)
    if not committed then clear(reason);return false,reason end
    N.status="active";N.cooldowns={}
    N.Enqueue(Ch.Envelope(N.channel,"hello",nextId()),false)
    refresh();return true
end
function N.Receive(prefix,packet,distribution,sender)
    if not N.channel or not C.Public(prefix) or not C.Public(packet) or not C.Public(distribution) or not C.Public(sender) then return end
    if prefix~=N.prefix or distribution~="GUILD" then return end
    local context=current()
    if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed");return end
    local actor=C.Actor(sender,context.owner.realm)
    if not actor or actor.id==context.owner.id or not C.Member(actor) then return end
    local envelope,reason=ns.Wire.Receive(N.pool,actor.id,packet,N.clock)
    if not envelope then if reason~="pending" then N.lastError=reason end;return end
    if type(envelope)~="table" then N.lastError="invalid_envelope";return end
    local roster
    roster,reason=C.Roster(context,ns.Guild.Snapshot(N.channel.session),envelope.message,actor)
    if not roster then N.lastError=reason;return end
    local ok,kind=Ch.Receive(N.channel,envelope,actor.id,roster)
    if not ok then if kind~="duplicate" and kind~="other_target" then N.lastError=kind end;return end
    if kind=="ack" then
        local request=N.pending[envelope.ack]
        if request and not request.peers[actor.id] then
            request.peers[actor.id]=true;N.channel.acks=N.channel.acks+1
            say("réception confirmée par "..actor.name.." ("..request.kind..").")
        end
    elseif kind=="hello" then
        if not N.cooldowns[actor.id] or N.clock-N.cooldowns[actor.id]>30 then
            N.cooldowns[actor.id]=N.clock;state(actor.id)
        end
    else
        local ack=Ch.Envelope(N.channel,"ack",nextId(),actor.id);ack.ack=envelope.id;N.Enqueue(ack,false)
        if kind=="state" then
            -- One targeted union in response to a targeted catch-up; a broadcast has no reply loop.
            if envelope.target then state(nil) end
            refresh()
        elseif kind=="test" then say("signal de partage reçu de "..actor.name..".") end
    end
end
function N.Tick(elapsed)
    N.clock=N.clock+elapsed
    for id,p in pairs(N.pending) do if N.clock-p.at>600 then N.pending[id]=nil end end
    if not N.channel then return end
    N.wait=(N.wait or 0)-elapsed
    if N.wait>0 then return end
    N.wait=0.3
    local context=current()
    if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed");return end
    if restricted() then N.status="restricted";return end
    N.status="active"
    if #N.queue==0 then return end
    local ok,result=pcall(C_ChatInfo.SendAddonMessage,N.prefix,N.queue[1],"GUILD")
    if not ok or not C.Public(result) then N.lastError="send_failed";N.wait=3;return end
    if result==0 then table.remove(N.queue,1)
    elseif result==3 or result==8 or result==11 then N.lastError="send_code_"..result;N.wait=3
    else N.lastError="send_code_"..tostring(result);N.queue={};say("envoi interrompu ("..N.lastError.."). /srsync reprendre pour réessayer.") end
end
function N.Change(operation,payload)
    if not N.channel then return false,"sharing_inactive" end
    local context=current()
    if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed");return false,N.status end
    if operation~="read" and operation~="thank" and operation~="incident" and operation~="claim" then return false,"invalid_operation" end
    if operation=="incident" or operation=="claim" then
        local message={incidents=operation=="incident" and {payload} or {},claims=operation=="claim" and {payload} or {}}
        local roster,reason=C.Roster(context,ns.Guild.Snapshot(N.channel.session),message)
        if not roster then return false,reason end
        N.channel.session.members=roster
    end
    local ok,reason=Ch.Change(N.channel,operation,payload)
    if ok and (operation=="incident" or operation=="claim") then
        local queued,errorCode=state(nil)
        if not queued then N.lastError=errorCode;say("événement sauvegardé, diffusion en attente ("..errorCode..").") end
    end
    if ok then refresh() end
    return ok,reason
end
function N.Bind(runtime,changed)
    N.runtime=runtime;N.changed=changed
    N.nonce=tostring(math.random(100000,999999)).."-"..tostring(math.floor((GetTime and GetTime() or 0)*1000))
    SLASH_SYNDICATROUGESYNC1="/srsync"
    SlashCmdList.SYNDICATROUGESYNC=function(command)
        command=command:lower():match("^%s*(.-)%s*$")
        if command=="activer" or command=="reprendre" then
            local ok,reason=N.Start()
            if ok then runtime.root.syncEnabled=true;say("partage de guilde activé. /srsync test pour vérifier la réception.")
            else say("partage indisponible ("..tostring(reason)..").") end
        elseif command=="arreter" or command=="arrêter" then
            if runtime.writable then runtime.root.syncEnabled=false end
            clear("inactive");say("partage arrêté.")
        elseif command=="test" or command=="actualiser" then
            if not N.channel then say("active d’abord le partage avec /srsync activer.");return end
            if N.lastRequest and N.clock-N.lastRequest<10 then say("patiente quelques secondes avant un autre test.");return end
            N.lastRequest=N.clock
            local ok,reason
            if command=="test" then ok,reason=N.Enqueue(Ch.Envelope(N.channel,"test",nextId()),true)
            else ok,reason=N.Enqueue(Ch.Envelope(N.channel,"hello",nextId()),false) end
            say(ok and "demande mise en file ; en attente d’un membre connecté." or "demande refusée ("..tostring(reason)..").")
        else
            local c=N.channel
            say("partage : "..N.status.." ; membres vus : "..(c and ns.Validation.Count(c.peers) or 0).." ; accusés reçus : "..(c and c.acks or 0).." ; messages en file : "..#N.queue..(N.lastError and " ; dernier problème : "..N.lastError or "")..". /srsync activer | test | actualiser | arreter")
        end
    end
    local f=CreateFrame("Frame");N.frame=f
    f:RegisterEvent("CHAT_MSG_ADDON");f:RegisterEvent("PLAYER_LOGIN");f:RegisterEvent("PLAYER_GUILD_UPDATE")
    f:SetScript("OnEvent",function(_,event,...)
        if event=="CHAT_MSG_ADDON" then N.Receive(...)
        elseif event=="PLAYER_LOGIN" then if runtime.writable and runtime.root.syncEnabled==true then N.Start() end
        elseif N.channel then
            local context=current()
            if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed") end
        end
    end)
    f:SetScript("OnUpdate",function(_,elapsed) N.Tick(elapsed) end)
end
