local _,ns=...
local T={clock=0,identities={},status="waiting",projection={}};ns.ReportsRuntime=T
local S,V,C,O=ns.ReportStore,ns.Validation,ns.GuildContext,ns.EnemyObserver
function T.Changed()
    T.dirty=true
end
function T.QueueIdentity(guid,actor)
    if V.Count(T.identities)<16 or T.identities[guid]then T.identities[guid]=V.Copy(actor)end
end
function T.Project(row)
    if not S.writable or row.confidence~="confirmed" or not row.killer or not row.killer.id then return false,"unconfirmed_attribution"end
    local stored=S.data.shared[row.id]
    if not stored or stored.trust~="author" or not V.Same(stored.row,row)then return false,"author_confirmation_required"end
    local channel=ns.GuildNative.channel
    if ns.GuildNative.testMode then return false,"simulation_active"end
    local enemy=V.Actor(row.killer);local victim=V.Actor(row.victim)
    if not enemy or not victim then return false,"identity_incomplete"end
    local id="report:"..row.id
    local location=V.Copy(row.location)
    -- The engine requires a display label, without inventing one in the saved report.
    location.zone=location.zone or "Lieu inconnu"
    if not channel then
        local context=C.Current()
        if not context or context.guildId~=row.guildId or context.owner.id~=row.victim.id or not T.runtime.writable then return false,"sharing_inactive"end
        if T.runtime.db.incidents[id]then return true end
        local candidate,reason=ns.Store.Restore(ns.Store.Snapshot(T.runtime.db),ns.Persistence.scope)
        if not candidate then return false,reason end
        local ok;ok,reason=ns.Incidents.Add(candidate,{id=id,guildId=ns.Persistence.scope,enemy=enemy,victim=victim,occurredAt=row.at,source="observed",instanceType=row.instanceType,location=location})
        if not ok then return false,reason end
        local previous=T.runtime.db;T.runtime.db=candidate
        ok,reason=ns.Persistence.Checkpoint(T.runtime)
        if not ok then T.runtime.db=previous;return false,reason end
        T.Changed();return true
    end
    if channel.context.guildId~=row.guildId then return false,"guild_mismatch"end
    if channel.session.incidents[id]then T.projection[row.id]=true;return true end
    local incident={id=id,guildId=row.guildId,enemy=enemy,victim=victim,occurredAt=row.at,source="observed",instanceType=row.instanceType,location=location}
    local roster=C.Roster(channel.context,ns.Guild.Snapshot(channel.session),{incidents={incident}})
    if not roster then return false,"membership_unavailable"end
    local candidate,reason=ns.Guild.Restore(ns.Guild.Snapshot(channel.session),row.guildId,channel.context.owner.id,roster)
    if not candidate then return false,reason end
    local ok;ok,reason=ns.Guild.Receive(candidate,{version=1,guildId=row.guildId,senderId=row.victim.id,incidents={incident},claims={}},row.victim.id)
    if not ok then T.status=reason;return false,reason end
    ok,reason=ns.Channel.Commit(channel,candidate)
    if ok then T.projection[row.id]=true;T.Changed()else T.status=reason end
    return ok,reason
end
function T.AllowIncident(incident,sender,session)
    if type(incident)~="table" or type(incident.id)~="string"then return false end
    if incident.id:sub(1,7)~="report:"then
        if session and session.incidents[incident.id]then return true end
        return type(incident.victim)=="table" and incident.victim.id==sender
    end
    if not S.writable then return false end
    local e=S.data.shared[incident.id:sub(8)]
    if not e or e.trust~="author" or e.row.confidence~="confirmed" or not e.row.killer then return false end
    local r=e.row
    local loc=V.Copy(r.location);loc.zone=loc.zone or "Lieu inconnu"
    return V.Same(incident.enemy,V.Actor(r.killer)) and V.Same(incident.victim,V.Actor(r.victim)) and incident.occurredAt==r.at
        and incident.guildId==r.guildId and incident.instanceType==r.instanceType and incident.source=="observed" and V.Same(incident.location,loc)
end
function T.Captured(row)
    local now=O.Now();if not now then return end
    local ok,reason=S.Put(row,"author",now,true)
    if not ok then T.status=reason;return false end
    S.Put(row,"author",now,false)
    T.Project(row);ns.ReportSync.Publish(row);T.status="saved_"..row.confidence;T.Changed();return true
end
function T.Decorate(view)
    if not S.writable or ns.GuildNative.testMode then return view end
    local context=C.Current();if not context then return view end
    local seen={};for _,e in ipairs(view.journal)do if e.incident then seen[e.incident.id]=true end end
    for _,entry in ipairs(S.List(false,context.guildId))do
        local row=entry.row
        if not seen["report:"..row.id]then view.journal[#view.journal+1]={id="journal:"..row.id,kind="report",occurredAt=row.at,report=row,trust=entry.trust}end
    end
    table.sort(view.journal,V.Newest);return view
end
function T.Control(action)
    if not ns.Access.Require() or not S.writable then return false end
    if ns.GuildNative.testMode or (ns.UI.provider and ns.UI.provider.demo)then return false,"simulation_active"end
    local cfg=S.Settings()
    if action=="enabled"then cfg.enabled=not cfg.enabled;ns.DeathDetector.Reset();O.Reset()
    elseif action=="sharing"then cfg.sharing=not cfg.sharing;if cfg.sharing then
        T.runtime.root.syncEnabled=true;ns.GuildNative.Start()
    else ns.ReportSync.Reset()end
    elseif action=="mixed"then cfg.mixed=cfg.mixed=="ignore" and "estimate" or "ignore"
    elseif action=="days"then cfg.days=cfg.days==30 and 7 or cfg.days==7 and 90 or 30;S.Cleanup(O.Now() or 0)
    elseif action=="limit"then cfg.maxShared=cfg.maxShared==5000 and 1000 or cfg.maxShared==1000 and 500 or 5000;S.Cleanup(O.Now() or 0)
    elseif action=="personalLimit"then cfg.maxPersonal=cfg.maxPersonal==1000 and 500 or cfg.maxPersonal==500 and 5000 or 1000;S.Cleanup(O.Now() or 0)
    elseif action=="sync"then
        T.runtime.root.syncEnabled=true
        if not ns.GuildNative.channel then ns.GuildNative.Start()end
        local ok,reason=ns.ReportSync.Request();T.status=reason or (ok and "sync_requested" or "sync_waiting")
        ns.ReportSync.UserFlush()
    elseif action=="diagnostic"then cfg.diagnostic=not cfg.diagnostic end
    T.Changed();return true
end
function T.Status()
    if not S.writable then return "Rapports : lecture seule ("..S.status..")"end
    local cfg=S.Settings()
    return (cfg.enabled and "Collecte active" or "Collecte arrêtée").." · "..(cfg.sharing and (ns.GuildNative.channel and "Guilde" or "Partage à activer") or "Local").." · Sync : "..ns.ReportSync.status
        ..(ns.GuildNative.sendPaused and " · Cliquer Synchroniser pour reprendre" or "")
end
function T.Initialize(runtime)
    T.runtime=runtime
    S.Open(runtime.root,O.Now() or 1000)
    ns.DeathDetector.Initialize()
    table.insert(ns.Access.revocations,function()ns.DeathDetector.Reset();O.Reset();ns.ReportSync.Reset();T.identities={};T.projection={}end)
    local f=CreateFrame("Frame");T.frame=f
    f:SetScript("OnUpdate",function(_,dt)
        T.clock=T.clock+dt;O.clock=T.clock
        if T.clock<(T.nextTick or 0)then return end
        local elapsed=T.lastTick and T.clock-T.lastTick or .25;T.lastTick=T.clock;T.nextTick=T.clock+.25
        ns.DeathDetector.Tick(elapsed);ns.ReportSync.Tick(elapsed)
        if T.clock>=(T.nextWork or 0)then
            T.nextWork=T.clock+2
            if S.writable and ns.Access.Allowed() and not ns.GuildNative.testMode then
                local ctx=C.Current();local now=O.Now()
                if ctx and now then
                    for guid,actor in pairs(T.identities)do
                        local changed=S.Enrich(guid,actor,now,ctx.owner.id)or{}
                        for _,row in ipairs(changed)do ns.ReportSync.Publish(row);T.Project(row)end
                        if #changed<8 then T.identities[guid]=nil end;break
                    end
                    if T.clock>=(T.nextProjection or 0)then
                        T.nextProjection=T.clock+2
                        if not T.projectKeys or T.projectIndex>#T.projectKeys then
                            T.projectKeys={};T.projectIndex=1
                            for id in pairs(S.data.shared)do T.projectKeys[#T.projectKeys+1]=id end
                        end
                        for _=1,8 do
                            local id=T.projectKeys[T.projectIndex];if not id then break end;T.projectIndex=T.projectIndex+1
                            local entry=S.data.shared[id]
                            if entry and entry.row.guildId==ctx.guildId and not T.projection[id]then T.Project(entry.row)end
                        end
                    end
                end
            end
            if T.dirty then T.dirty=false;if ns.UI.window and ns.UI.window:IsShown()then ns.UI.Refresh()end end
        end
    end)
end
