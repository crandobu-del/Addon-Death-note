local _,ns=...
local D={attacks={},clock=0,status="waiting",duel=false,dead=false,serial=0};ns.DeathDetector=D
local O,C,R,V=ns.EnemyObserver,ns.GuildContext,ns.ReportSchema,ns.Validation
local damage={SWING_DAMAGE=true,RANGE_DAMAGE=true,SPELL_DAMAGE=true,SPELL_PERIODIC_DAMAGE=true,DAMAGE_SHIELD=true,DAMAGE_SPLIT=true,ENVIRONMENTAL_DAMAGE=true}
local function flag(n,mask)return V.Integer(n,0,4294967295) and math.floor(n/mask)%2==1 end
function D.CleanEntry(e,now)
    if not C.Public(e) or type(e)~="table"then return nil end
    -- Do not coerce or compare any field until its access guard passes.
    for _,k in ipairs({"sourceGUID","sourceName","sourceFlags","event","overkill","timestamp"})do if not C.Public(e[k])then return nil end end
    if not damage[e.event] or type(e.timestamp)~="number" or e.timestamp~=e.timestamp or e.timestamp<now-15 or e.timestamp>now+1 then return nil end
    local row={event=e.event,at=e.timestamp}
    if type(e.overkill)=="number" and e.overkill==e.overkill and math.abs(e.overkill)<=1000000000 then row.overkill=e.overkill end
    local guid=e.sourceGUID
    if R.Text(guid,100) and guid:match("^[%w%-]+$")then row.guid=guid end
    if flag(e.sourceFlags,0x40) and flag(e.sourceFlags,0x100) then
        if flag(e.sourceFlags,0x400) and row.guid and row.guid:match("^Player%-")then
            row.actor=O.ByGUID(row.guid) or {guid=row.guid}
            if not row.actor.name and R.Text(e.sourceName,100)then row.actor.name=e.sourceName end
            row.pvp=true
        elseif (flag(e.sourceFlags,0x1000) or flag(e.sourceFlags,0x2000)) and row.guid then
            row.actor=O.Owner(row.guid);row.pvp=true;row.unknownPet=not row.actor
        end
    end
    return row
end
function D.Classify(entries,death,policy,source)
    local hits,attackers,order={}, {},{}
    local fatal,fatalConflict,latest
    for i=1,math.min(#entries,128)do
        local e=D.CleanEntry(entries[i],death.at)
        if e then
            hits[#hits+1]=e
            if e.pvp then
                local actor=e.actor or {guid=e.guid};local guid=actor.guid
                if guid and not attackers[guid] and #order<16 then attackers[guid]=actor;order[#order+1]=guid end
                if e.actor and (not latest or e.at>latest.at)then latest=e end
            end
            if e.overkill and e.overkill>=0 then
                if fatal and (e.at~=fatal.at or e.guid~=fatal.guid)then fatalConflict=true end
                fatal=e
            end
        end
    end
    if #order==0 then return nil,"no_pvp_evidence"end
    local finish=fatal and (fatal.pvp and "player" or fatal.event=="ENVIRONMENTAL_DAMAGE" and "environment" or "pve") or "unknown"
    if fatal and not fatal.pvp and policy=="ignore"then return nil,"mixed_finish_ignored"end
    local killer,confidence
    if fatal and not fatalConflict and fatal.pvp and fatal.actor then killer=fatal.actor;confidence="confirmed"
    elseif latest then killer=latest.actor;confidence="estimated"
    else confidence="unknown"end
    if fatalConflict then confidence=killer and "estimated" or "unknown";finish="unknown"end
    local list={};for _,guid in ipairs(order)do list[#list+1]=attackers[guid]end
    return {version=1,id=death.id,at=death.at,guildId=death.guildId,victim=death.victim,killer=killer,attackers=list,location=death.location,
        source=source or "death_recap",confidence=confidence,finish=finish,instanceType=death.instanceType,pvp=true,revision=1}
end
function D.Reset()D.attacks={};D.pending=nil;D.dead=false;D.status="waiting"end
function D.Attack(entry)
    local now=O.Now();if not now then return end
    local row=D.CleanEntry(entry,now);if not row then return end
    -- Keep bounded raw public fields only; no allocation for unrelated CLEU events.
    if #D.attacks>=128 then table.remove(D.attacks,1)end
    D.attacks[#D.attacks+1]={sourceGUID=entry.sourceGUID,sourceName=entry.sourceName,sourceFlags=entry.sourceFlags,event=entry.event,overkill=entry.overkill,timestamp=entry.timestamp}
end
function D.CombatEvent()
    if O.Read(C_CombatLog and C_CombatLog.IsCombatLogRestricted)~=false or type(CombatLogGetCurrentEventInfo)~="function"then return end
    local ok,t,event,_,guid,name,flags,_,dest,_,_,_,a,b,c,d,e=pcall(CombatLogGetCurrentEventInfo)
    if not ok then return end
    if not C.Public(t) or not C.Public(event) or not C.Public(guid) or not C.Public(name) or not C.Public(flags) or not C.Public(dest)then return end
    if event=="SPELL_SUMMON"then
        if flag(flags,0x100) and flag(flags,0x400)then O.LinkOwner(guid,name,dest)end
        return
    end
    if not damage[event]then return end
    local own=O.Read(UnitGUID,"player");if not own or dest~=own then return end
    local overkill
    if event=="SWING_DAMAGE"then overkill=b elseif event=="ENVIRONMENTAL_DAMAGE"then overkill=c else overkill=e end
    if not C.Public(overkill)then return end
    D.Attack({sourceGUID=guid,sourceName=name,sourceFlags=flags,event=event,overkill=overkill,timestamp=t})
end
function D.OnDeath()
    if D.dead then return end;D.dead=true
    if not ns.ReportStore.writable or not ns.ReportStore.Settings().enabled or not ns.Access.Allowed() or ns.GuildNative.testMode or D.duel or D.clock<(D.duelUntil or 0)then D.status="excluded";return end
    local scope,reason=ns.PvpScope.Current();if not scope then D.status=reason;return end
    local context=C.Current();local now=O.Now();if not context or not now then D.status="identity_or_time_unavailable";return end
    local victim=O.Observe("player") or V.Copy(context.owner)
    -- Public guild identity is authoritative for the local report author.
    for k,v in pairs(context.owner)do victim[k]=v end
    D.pending={id=ns.ReportStore.NextId(victim,now),at=now,guildId=context.guildId,victim=victim,location=O.Location(),instanceType=scope,started=D.clock,attempt=0,entries=V.Copy(D.attacks)}
    D.attacks={};D.status="recap_pending"
end
local delays={.3,1,2}
function D.Tick(dt)
    D.clock=D.clock+dt
    local p=D.pending;if not p or D.clock-p.started<delays[p.attempt+1]then return end
    p.attempt=p.attempt+1
    if not ns.Access.Allowed() or ns.GuildNative.testMode or not ns.ReportStore.Settings().enabled then D.pending=nil;D.status="interrupted";return end
    local context=C.Current()
    if not context or context.guildId~=p.guildId or context.owner.id~=p.victim.id then D.pending=nil;D.status="guild_changed";return end
    local entries
    if O.Read(C_DeathRecap and C_DeathRecap.HasRecapEvents)==true then
        local value=O.Read(C_DeathRecap.GetRecapEvents)
        if type(value)=="table"then entries=value end
    end
    local row,reason
    if entries then
        local ok,result,why,stamp=pcall(function()
            local fresh=false;local newest
            for i=1,math.min(#entries,128)do
                local e=D.CleanEntry(entries[i],p.at)
                if e and e.at>=p.at-3 and (not D.lastRecapStamp or e.at>D.lastRecapStamp)then fresh=true end
                if e and (not newest or e.at>newest)then newest=e.at end
            end
            if not fresh then return nil,"stale_recap"end
            local row,reason=D.Classify(entries,p,ns.ReportStore.Settings().mixed,"death_recap")
            return row,reason,newest
        end)
        if ok then row=result;reason=why;p.recapStamp=stamp or p.recapStamp else reason="recap_inaccessible"end
    end
    if p.recapStamp and not row and (reason=="mixed_finish_ignored" or reason=="no_pvp_evidence")then
        D.pending=nil;D.lastRecapStamp=p.recapStamp;ns.ReportStore.data.lastRecapStamp=p.recapStamp;D.status=reason;return
    end
    if not row and p.attempt<3 then return end
    if not row then row,reason=D.Classify(p.entries,p,ns.ReportStore.Settings().mixed,"combat_log")end
    D.pending=nil;D.status=reason or "captured"
    if p.recapStamp then D.lastRecapStamp=p.recapStamp;ns.ReportStore.data.lastRecapStamp=p.recapStamp end
    if row then
        ns.ReportsRuntime.Captured(row);D.status="captured_"..row.confidence
    end
end
function D.Initialize()
    D.lastRecapStamp=ns.ReportStore.writable and ns.ReportStore.data.lastRecapStamp or nil
    local f=CreateFrame("Frame");D.frame=f
    for _,event in ipairs({"PLAYER_DEAD","PLAYER_ALIVE","PLAYER_UNGHOST","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","DUEL_REQUESTED","DUEL_TO_THE_DEATH_REQUESTED","DUEL_FINISHED","DUEL_INBOUNDS"})do pcall(f.RegisterEvent,f,event)end
    if O.Read(C_CombatLog and C_CombatLog.IsCombatLogRestricted)==false
        and O.Read(C_EventUtils and C_EventUtils.IsEventValid,"COMBAT_LOG_EVENT_UNFILTERED")==true
        and O.Read(C_EventUtils and C_EventUtils.IsCallbackEvent,"COMBAT_LOG_EVENT_UNFILTERED")==false then
        pcall(f.RegisterEvent,f,"COMBAT_LOG_EVENT_UNFILTERED")
    end
    f:SetScript("OnEvent",function(_,event,unit)
        if event=="PLAYER_DEAD"then D.OnDeath()
        elseif event=="PLAYER_ALIVE" or event=="PLAYER_UNGHOST"then D.dead=false
        elseif event=="DUEL_REQUESTED" or event=="DUEL_TO_THE_DEATH_REQUESTED" or event=="DUEL_INBOUNDS"then D.duel=true
        elseif event=="DUEL_FINISHED"then if D.duel then D.duelUntil=D.clock+5 end;D.duel=false;D.attacks={}
        elseif event=="COMBAT_LOG_EVENT_UNFILTERED"then if ns.Access.Allowed() and ns.ReportStore.Settings().enabled and not ns.GuildNative.testMode then D.CombatEvent()end
        elseif event=="PLAYER_TARGET_CHANGED"then O.Observe("target")
        elseif event=="UPDATE_MOUSEOVER_UNIT"then O.Observe("mouseover")
        elseif event=="NAME_PLATE_UNIT_ADDED"then O.Observe(unit)end
    end)
end
