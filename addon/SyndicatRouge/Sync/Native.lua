local _,ns=...
local N={prefix="SRGuild4",queue={},pool={},pending={},counter=0,status="inactive",clock=0};ns.GuildNative=N
local C,Ch=ns.GuildContext,ns.Channel
local function say(s) print("Tableau des primes : "..s) end
local function refresh()
    if N.changed then N.changed() end
    if ns.WantedMarkers then ns.WantedMarkers.Refresh() end
end
local function clear(reason)
    if ns.ReportSync then ns.ReportSync.Reset()end
    if ns.ReportsRuntime then ns.ReportsRuntime.projection={};ns.ReportsRuntime.projectKeys=nil end
    if ns.Sightings then ns.Sightings.Reset()end
    N.channel=nil;N.queue={};N.pool={};N.pending={};N.sightingPackets={};N.packetRates={};N.sendPaused=false;N.sendRetries=0;N.status=reason;refresh()
end
function N.Suspend() clear("inactive") end
local function current()
    local ok,context,reason=pcall(C.Current)
    if not ok then return nil,"guild_context_unavailable" end
    if context and N.testMode then
        context=ns.Validation.Copy(context);context.guildId=context.guildId..":test-v1"
        context.legacyGuildId=nil;context.test=true
    end
    return context,reason
end
function N.OutgoingRestriction()
    if not C_ChatInfo or type(C_ChatInfo.AreOutgoingAddonChatMessagesRestricted)~="function" then return true,"restriction_api_missing" end
    local ok,value=pcall(C_ChatInfo.AreOutgoingAddonChatMessagesRestricted)
    if not ok then return true,"restriction_query_failed" end
    if not C.Public(value) then return true,"restriction_value_protected" end
    if value==true then return true,"realm_restricted" end
    if value==false then return false,"allowed" end
    return true,"restriction_result_invalid"
end
function N.OutgoingGate()
    local _,flag=N.OutgoingRestriction()
    if flag~="allowed" and flag~="realm_restricted" then return true,flag end
    if not C_ChatInfo or type(C_ChatInfo.InChatMessagingLockdown)~="function" then return true,"lockdown_api_missing" end
    local ok,locked=pcall(C_ChatInfo.InChatMessagingLockdown)
    if not ok or not C.Public(locked) or type(locked)~="boolean" then return true,"lockdown_unavailable" end
    if locked then return true,"chat_lockdown" end
    return false,flag=="realm_restricted" and "allowed_realm_flag_observed" or "allowed"
end
local function nextId()
    N.counter=N.counter+1
    return N.nonce.."-"..N.counter
end
local function probeSummary()
    local p=N.probe
    if not p then say("aucune sonde lancée. /srsync sonde");return end
    say("sonde v4 : envoi="..p.result.." ; écho personnel="..(p.echo and "oui" or "non").." ; signaux d’autres membres="..p.peers.." ; "..(p.finished and "terminée" or "en observation")..". Aucun incident ni point créé.")
    say("sonde réception : messages="..p.received.." ; jeton personnel="..(p.tokenSeen and "oui" or "non").." ; expéditeur="..p.senderState..".")
end
function N.Probe(listenOnly)
    if not listenOnly and N.lastProbeRequest and N.clock-N.lastProbeRequest<30 then say("patiente 30 secondes entre deux sondes.");return end
    local context,reason=current()
    if not context then say("sonde refusée : "..tostring(reason)..".");return end
    local _,restriction=N.OutgoingRestriction()
    if restriction~="allowed" and restriction~="realm_restricted" then say("sonde refusée : "..restriction..".");return end
    if not C_ChatInfo or type(C_ChatInfo.InChatMessagingLockdown)~="function" or type(C_ChatInfo.SendAddonMessage)~="function" then say("sonde refusée : chat_api_unavailable.");return end
    local ok,locked=pcall(C_ChatInfo.InChatMessagingLockdown)
    if not ok or not C.Public(locked) or locked~=false then say("sonde refusée : chat_lockdown_or_unavailable.");return end
    if type(C_ChatInfo.RegisterAddonMessagePrefix)~="function" then say("sonde refusée : prefix_api_unavailable.");return end
    local registered,code=pcall(C_ChatInfo.RegisterAddonMessagePrefix,"SRProbe1")
    if not registered or not C.Public(code) or (code~=0 and code~=1) then say("sonde refusée : prefix_registration_failed.");return end
    local p=N.probe
    if not p or p.finished or N.clock-p.at>=120 or p.guildId~=context.guildId or p.ownerId~=context.owner.id then
        p={token="SRP1:"..nextId(),guildId=context.guildId,ownerId=context.owner.id,at=N.clock,result="not_sent",echo=false,peers=0,seen={},received=0,tokenSeen=false,senderState="not_observed"}
    end
    N.probe=p
    if listenOnly then say("sonde v4 : écoute prête pour deux minutes ; aucun envoi. Quand vous êtes tous deux prêts : /srsync sonde.");return end
    N.lastProbeRequest=N.clock
    p.token="SRP1:"..nextId();p.at=N.clock;p.result="pending";p.echo=false;p.tokenSeen=false
    local sent,result=pcall(C_ChatInfo.SendAddonMessage,"SRProbe1",p.token,"GUILD")
    if not sent then p.result="call_failed"
    elseif not C.Public(result) then p.result="protected_result"
    elseif type(result)~="number" or result%1~=0 or result<0 or result>12 then p.result="invalid_result"
    elseif result==0 then p.result="accepted_code_0"
    else p.result="refused_code_"..result end
    say("sonde unique v4 : indicateur="..restriction.." ; envoi="..p.result..". Écoute pendant deux minutes ; /srsync sondebilan pour le bilan actuel.")
end
function N.ReceiveProbe(prefix,packet,distribution,sender)
    local p=N.probe
    if not p or p.finished or N.clock-p.at>120 then return end
    if not C.Public(prefix) or not C.Public(packet) or not C.Public(distribution) then return end
    if prefix~="SRProbe1" or distribution~="GUILD" or type(packet)~="string" or #packet>80 or not packet:match("^SRP1:%d+%-%d+%-%d+$") then return end
    local context=current()
    if not context or context.guildId~=p.guildId or context.owner.id~=p.ownerId then return end
    p.received=math.min(99,p.received+1)
    if packet==p.token then p.tokenSeen=true end
    if not C.Public(sender) then p.senderState="protected";return end
    local regional=C.ProbeSender(sender,context)
    if regional then
        p.senderState=regional
        if regional=="self" and packet==p.token and not p.echo then
            p.echo=true;say("sonde : écho personnel reçu, nom régional reconnu.")
        elseif regional=="verified_member" and p.peers<4 and not p.seen[sender] then
            p.seen[sender]=true;p.peers=p.peers+1
            say("sonde : signal reçu d’un membre vérifié par son nom régional.")
        end
        return
    end
    local actor=C.Actor(sender,context.owner.realm)
    if not actor then p.senderState="invalid";return end
    if actor.id==p.ownerId then
        p.senderState="self"
        if packet==p.token and not p.echo then p.echo=true;say("sonde : écho personnel reçu sur le canal de guilde.") end
    elseif p.peers<4 and not p.seen[actor.id] and C.Member(actor,context) then
        p.senderState="verified_member"
        p.seen[actor.id]=true;p.peers=p.peers+1
        say("sonde : signal reçu d’un autre membre vérifié. Aucun accusé automatique envoyé.")
    elseif not p.seen[actor.id] then p.senderState="membership_unavailable"
    end
end
function N.Enqueue(envelope,expectsAck)
    if not envelope then return false,"missing_envelope" end
    local packets,reason=ns.Wire.Packets(envelope,envelope.id)
    if not packets then return false,reason end
    if #N.queue+#packets>1500 then return false,"queue_limit" end
    if expectsAck and ns.Validation.Count(N.pending)>=128 then return false,"pending_limit"end
    for _,packet in ipairs(packets) do N.queue[#N.queue+1]=packet end
    if expectsAck then N.pending[envelope.id]={kind=envelope.kind,at=N.clock,peers={}} end
    return true
end
local function state(target)
    local envelope,reason=Ch.State(N.channel,nextId(),target)
    if not envelope then return false,reason end
    return N.Enqueue(envelope,true)
end
function N.SendLegacyState(target)return state(target)end
function N.Publish()
    if not N.channel then return false,"sharing_inactive" end
    local ok,reason=state(nil)
    if ok then N.Notify();refresh() end
    return ok,reason
end
function N.SendSighting(row)
    if not N.channel or N.testMode or not ns.Access.Allowed()then return false end
    local context=current()
    if not context or context.guildId~=N.channel.context.guildId then return false end
    local envelope=Ch.Envelope(N.channel,"sighting",nextId());envelope.sighting=row
    local ok,reason=N.Enqueue(envelope,false)
    if ok then
        N.sightingPackets=N.sightingPackets or {}
        N.sightingPackets[N.queue[#N.queue]]={row=ns.Validation.Copy(row),owner=ns.Validation.Copy(context.owner)}
    end
    return ok,reason
end
function N.Notify()
    if not N.channel then return end
    local delivery,vengeances,thanks=ns.Delivery.Alerts(N.channel.delivery,N.channel.session)
    if not delivery then N.lastError=vengeances;return end
    local ok,reason=Ch.Commit(N.channel,N.channel.session,delivery)
    if not ok then N.lastError=reason;return end
    local function alert(rows,isThanks)
        if #rows==0 then return end
        for i=1,math.min(#rows,3) do
            local row=rows[i]
            local function name(actor)return actor.name:gsub("|","||") end
            local label=N.testMode and "[TEST] " or ""
            say(label..(isThanks and (name(row.victim).." te remercie d’avoir vengé sa mort contre "..name(row.enemy)..".")
                or (name(row.avenger).." t’a vengé contre "..name(row.enemy).." !")))
        end
        if #rows>3 then say((#rows-3).." autre(s) "..(isThanks and "remerciement(s)" or "notification(s) de vengeance").." à consulter dans /sr, onglet Notifications.") end
    end
    alert(vengeances,false);alert(thanks,true)
end
function N.PumpThanks()
    if not N.channel or #N.queue>100 then return end
    local rows=ns.Delivery.Pending(N.channel.delivery,N.channel.session)
    if #rows==0 then return end
    for _=1,math.min(4,#rows) do
        N.thankCursor=((N.thankCursor or 0)%#rows)+1
        local row=rows[N.thankCursor]
        if C.Member(N.channel.session.members[row.toId],N.channel.context) then
            local envelope=Ch.Envelope(N.channel,"thank",nextId(),row.toId)
            envelope.notificationId=row.notificationId;envelope.claimId=row.claimId
            local ok,reason=N.Enqueue(envelope,false)
            if not ok then N.lastError=reason;return end
        end
    end
end
function N.Start()
    if not N.runtime or not N.runtime.writable then return false,"profile_not_writable" end
    clear("initializing")
    if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) end
    local context,reason=current()
    if not context then N.status=reason;return false,reason end
    N.prefix=N.testMode and "SRGuildTest4" or "SRGuild4"
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
    N.status="active";N.cooldowns={};N.thankCursor=0;N.nextThanks=N.clock+3
    if context.legacyGuildId and saved and saved[context.legacyGuildId] and not N.legacyNotice then
        N.legacyNotice=true;say("ancien registre de guilde conservé séparément ; nouveau registre aux noms régionaux. Aucun ancien événement ni point réattribué.")
    end
    if N.testMode or not ns.ReportStore or not ns.ReportStore.writable then N.Enqueue(Ch.Envelope(N.channel,"hello",nextId()),false)end
    N.Notify()
    if ns.ReportSync then ns.ReportSync.Start(context)end
    refresh();return true
end
function N.Receive(prefix,packet,distribution,sender)
    if not N.channel or not C.Public(prefix) or not C.Public(packet) or not C.Public(distribution) or not C.Public(sender) then return end
    if prefix~=N.prefix or distribution~="GUILD" then return end
    local context=current()
    if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed");return end
    local actor=C.Sender(sender,context)
    if not actor or actor.id==context.owner.id then return end
    if not C.Member(actor,context) then N.lastError="sender_membership_unavailable";return end
    N.packetRates=N.packetRates or {}
    local rate=N.packetRates[actor.id]
    if not rate or N.clock-rate.at>=10 then
        if ns.Validation.Count(N.packetRates)>=128 then N.lastError="sender_rate_capacity";return end
        rate={at=N.clock,n=0};N.packetRates[actor.id]=rate
    end
    rate.n=rate.n+1;if rate.n>60 then N.lastError="packet_rate_limit";return end
    local envelope,reason=ns.Wire.Receive(N.pool,actor.id,packet,N.clock)
    if not envelope then if reason~="pending" then N.lastError=reason end;return end
    if type(envelope)~="table" then N.lastError="invalid_envelope";return end
    local roster
    roster,reason=C.Roster(context,ns.Guild.Snapshot(N.channel.session),envelope.message,actor)
    if not roster then N.lastError=reason;return end
    local ok,kind=Ch.Receive(N.channel,envelope,actor.id,roster)
    if not ok then if kind~="duplicate" and kind~="other_target" then N.lastError=kind end;return end
    if kind=="report" then
        local accepted,errorCode=ns.ReportSync.Receive(envelope,actor)
        if not accepted and errorCode~="duplicate"then N.lastError=errorCode end
        return
    elseif kind=="sighting" then ns.Sightings.Receive(envelope.sighting,actor);return
    elseif kind=="thank" then
        local ack=Ch.Envelope(N.channel,"thank_ack",nextId(),actor.id)
        ack.notificationId=envelope.notificationId;ack.claimId=envelope.claimId
        N.Enqueue(ack,false);N.Notify();refresh()
    elseif kind=="thank_ack" then
        refresh()
    elseif kind=="ack" then
        local request=N.pending[envelope.ack]
        if request and not request.peers[actor.id] then
            request.peers[actor.id]=true;N.channel.acks=N.channel.acks+1
            say("réception confirmée par "..actor.name.." ("..request.kind..").")
        end
    elseif kind=="hello" then
        if not N.testMode and ns.ReportStore and ns.ReportStore.writable then return end
        N.nextThanks=N.clock+3
        if not N.cooldowns[actor.id] or N.clock-N.cooldowns[actor.id]>30 then
            N.cooldowns[actor.id]=N.clock;state(actor.id)
        end
    else
        local ack=Ch.Envelope(N.channel,"ack",nextId(),actor.id);ack.ack=envelope.id;N.Enqueue(ack,false)
        if kind=="state" then
            -- One targeted union in response to a targeted catch-up; a broadcast has no reply loop.
            if envelope.target and (N.testMode or not ns.ReportStore or not ns.ReportStore.writable)then state(nil)end
            N.Notify();refresh()
        elseif kind=="test" then say("signal de partage reçu de "..actor.name..".") end
    end
end
function N.Tick(elapsed)
    N.clock=N.clock+elapsed
    if N.probe and not N.probe.finished and N.clock-N.probe.at>=120 then N.probe.finished=true;probeSummary() end
    for id,p in pairs(N.pending) do if N.clock-p.at>600 then N.pending[id]=nil end end
    if N.clock>=(N.nextPacketSweep or 0)then
        N.nextPacketSweep=N.clock+30
        for peer,r in pairs(N.packetRates or {})do if N.clock-r.at>30 then N.packetRates[peer]=nil end end
    end
    if not N.channel then
        if N.runtime and N.runtime.writable and N.runtime.root.syncEnabled==true and N.clock>=(N.nextConnect or 0) then
            N.nextConnect=N.clock+15;N.Start()
        end
        return
    end
    N.wait=(N.wait or 0)-elapsed
    if N.wait>0 then return end
    N.wait=0.3
    local context=current()
    if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed");return end
    local blocked,restriction=N.OutgoingGate()
    N.restrictionReason=restriction
    if blocked then N.status="restricted";return end
    N.status="active"
    if N.sendPaused then N.status="user_retry_required";return end
    if N.clock>=(N.nextThanks or 0) then N.nextThanks=N.clock+15;N.PumpThanks() end
    if #N.queue==0 then return end
    local ok,result=pcall(C_ChatInfo.SendAddonMessage,N.prefix,N.queue[1],"GUILD")
    if not ok or not C.Public(result) then N.lastError="send_failed";N.wait=3;return end
    if result==0 then
        N.sendRetries=0
        local packet=table.remove(N.queue,1)
        local sighting=N.sightingPackets and N.sightingPackets[packet]
        if sighting then N.sightingPackets[packet]=nil;ns.Sightings.Sent(sighting.row,sighting.owner)end
    elseif result==3 or result==8 or result==11 then
        N.lastError="send_code_"..result;N.sendRetries=(N.sendRetries or 0)+1;N.wait=3*N.sendRetries
        if N.sendRetries>=3 then N.sendPaused=true;N.status="user_retry_required"end
    else N.lastError="send_code_"..tostring(result);N.queue={};say("envoi interrompu ("..N.lastError.."). /srsync reprendre pour réessayer.") end
end
function N.UserSend()
    N.sendPaused=false;N.sendRetries=0;N.wait=0
    -- Called by the existing interface's synchronization button. Gates remain
    -- enforced; if this client needs a hardware action, this sends one fragment.
    N.Tick(0)
end
function N.Change(operation,payload)
    if not N.channel then return false,"sharing_inactive" end
    local context=current()
    if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed");return false,N.status end
    if operation~="read" and operation~="thank" and operation~="incident" and operation~="claim" then return false,"invalid_operation" end
    if operation=="incident" or operation=="claim" then
        if operation=="incident" and not N.testMode and (type(payload)~="table" or type(payload.victim)~="table" or payload.victim.id~=context.owner.id)then return false,"direct_victim_mismatch"end
        local message={incidents=operation=="incident" and {payload} or {},claims=operation=="claim" and {payload} or {}}
        local roster,reason=C.Roster(context,ns.Guild.Snapshot(N.channel.session),message)
        if not roster then return false,reason end
        N.channel.session.members=roster
    end
    local ok,reason=Ch.Change(N.channel,operation,payload)
    if ok and operation=="thank" then N.nextThanks=N.clock+0.5 end
    if ok and (operation=="incident" or operation=="claim") then
        local queued,errorCode=state(nil)
        if not queued then N.lastError=errorCode;say("événement sauvegardé, diffusion en attente ("..errorCode..").") end
    end
    if ok then N.Notify();refresh() end
    return ok,reason
end
function N.Bind(runtime,changed)
    N.runtime=runtime;N.changed=changed
    N.nonce=tostring(math.random(100000,999999)).."-"..tostring(math.floor((GetTime and GetTime() or 0)*1000))
    SLASH_SYNDICATROUGESYNC1="/srsync"
    SlashCmdList.SYNDICATROUGESYNC=function(command)
        local runtime=N.runtime
        command=command:lower():match("^%s*(.-)%s*$")
        if command~="diagnostic" and not ns.Access.Require()then return end
        if command=="activer" or command=="reprendre" then
            if runtime.writable then runtime.root.syncEnabled=true end
            local ok,reason=N.Start()
            if ok then runtime.root.syncEnabled=true;say("partage de guilde activé. /srsync test pour vérifier la réception.")
            else say("partage en attente ("..tostring(reason).."). "..(runtime.writable and "Nouvelle tentative automatique ; " or "Profil en lecture seule ; ").."/srsync diagnostic pour le détail.") end
        elseif command=="sonde" then N.Probe()
        elseif command=="ecouter" then N.Probe(true)
        elseif command=="sondebilan" then probeSummary()
        elseif command=="diagnostic" then
            local context,reason=current()
            local check=C.lastCheck or {}
            say("version "..ns.version.." ; identité="..(context and "ready" or tostring(reason)).." ; nom="..(check.name or "not_checked").." ; royaume="..(check.realm or "not_checked").." ; membre="..(check.member or "not_checked")..".")
            local _,restriction=N.OutgoingRestriction()
            say("diagnostic envoi="..restriction.." ; aucun message envoyé par ce diagnostic.")
            local _,gate=N.OutgoingGate()
            say("diagnostic transport="..gate.." ; noms="..(context and context.nameMode or "unavailable")..".")
        elseif command=="arreter" or command=="arrêter" then
            if runtime.writable then runtime.root.syncEnabled=false end
            clear("inactive");say("partage arrêté.")
        elseif command=="test" or command=="actualiser" then
            if not N.channel then say("active d’abord le partage avec /srsync activer.");return end
            if N.lastRequest and N.clock-N.lastRequest<10 then say("patiente quelques secondes avant un autre test.");return end
            N.lastRequest=N.clock
            local ok,reason
            if command=="test" then ok,reason=N.Enqueue(Ch.Envelope(N.channel,"test",nextId()),true)
            elseif ns.ReportStore and ns.ReportStore.writable and not N.testMode then ok,reason=ns.ReportSync.Request()
            else ok,reason=N.Enqueue(Ch.Envelope(N.channel,"hello",nextId()),false) end
            say(ok and "demande mise en file ; en attente d’un membre connecté." or "demande refusée ("..tostring(reason)..").")
        else
            local c=N.channel
            say("partage : "..N.status..(N.status=="restricted" and N.restrictionReason and " ("..N.restrictionReason..")" or "").." ; membres vus : "..(c and ns.Validation.Count(c.peers) or 0).." ; accusés reçus : "..(c and c.acks or 0).." ; messages en file : "..#N.queue.." ; mercis en attente : "..(c and #ns.Delivery.Pending(c.delivery,c.session) or 0)..(N.lastError and " ; dernier problème : "..N.lastError or "")..". /srsync activer | test | actualiser | arreter")
        end
    end
    local f=CreateFrame("Frame");N.frame=f
    f:RegisterEvent("CHAT_MSG_ADDON");f:RegisterEvent("PLAYER_LOGIN");f:RegisterEvent("PLAYER_GUILD_UPDATE")
    f:SetScript("OnEvent",function(_,event,...)
        if event=="CHAT_MSG_ADDON" then N.ReceiveProbe(...);N.Receive(...)
        elseif event=="PLAYER_LOGIN" then if runtime.writable and runtime.root.syncEnabled==true then N.Start() end
        elseif N.channel then
            local context=current()
            if not context or context.guildId~=N.channel.context.guildId or context.owner.id~=N.channel.context.owner.id then clear("guild_context_changed") end
        end
    end)
    f:SetScript("OnUpdate",function(_,elapsed) N.Tick(elapsed) end)
    if ns.SyncTest then ns.SyncTest.Bind(runtime) end
end
