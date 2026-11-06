local _,ns=...
local C,V,N=ns.GuildContext,ns.Validation,ns.GuildNative
local S={groups={},notes={},units={},clock=0};ns.Sightings=S
S.cooldown=300;S.lifetime=60;S.election=3
local function publicCall(fn,...)
    if type(fn)~="function"then return nil end
    local ok,value=pcall(fn,...)
    if not ok or not C.Public(value)then return nil end
    return value
end
local function wanted(id)
    if not N.channel or N.testMode then return nil end
    local db=N.channel.session.db
    if S.indexDb~=db then
        S.indexDb=db;S.index={}
        for _,row in ipairs(ns.Wanted.List(db))do if row.openCount>0 then S.index[row.enemy.id]=row.enemy end end
    end
    return S.index[id]
end
local function now()local t=publicCall(GetServerTime);if V.Integer(t,1)then return t end end
function S.Validate(row,context)
    if type(row)~="table" or context.test or not V.String(row.enemyId) or row.enemyId:find("|",1,true)
        or not V.Integer(row.mapId,1) or not V.Integer(row.at,1) or not V.String(row.zone,80)
        or row.zone:find("|",1,true)then return false end
    local time=now()
    return time and row.at<=time+5 and time-row.at<=S.lifetime and wanted(row.enemyId)~=nil or false
end
function S.Reset()S.groups={};S.notes={};S.units={};S.outstanding={};S.indexDb=nil;S.index={} end
function S.Read(id)
    for _,row in ipairs(S.notes)do if row.id==id then row.read=true;return true end end
    return false
end
function S.Decorate(view)
    if N.testMode or not ns.Access.Allowed()then return view end
    local time=now()
    for _,row in ipairs(S.notes)do
        if time and time-row.occurredAt<=S.cooldown and wanted(row.enemy.id)then
            view.notifications[#view.notifications+1]=V.Copy(row)
        end
    end
    table.sort(view.notifications,function(a,b)if a.occurredAt~=b.occurredAt then return a.occurredAt>b.occurredAt end;return a.id<b.id end)
    return view
end
function S.Receive(row,actor)
    if not N.channel or not ns.Access.Allowed() or not S.Validate(row,N.channel.context)then return false end
    local key=row.enemyId..":"..row.mapId
    local group=S.groups[key]
    if not group or S.clock-group.started>=S.cooldown then
        if V.Count(S.groups)>=128 then return false end
        group={started=S.clock,due=S.clock+S.election,leader=actor.id,row=V.Copy(row),observer=V.Copy(actor)};S.groups[key]=group
        local enemy=wanted(row.enemyId)
        local note={id="sighting:"..key..":"..row.at,kind="sighting",enemy=V.Copy(enemy),observer=V.Copy(actor),
            zone=row.zone,occurredAt=row.at,read=false}
        table.insert(S.notes,1,note);while #S.notes>20 do table.remove(S.notes)end
        print("Tableau des primes : "..enemy.name:gsub("|","||").." repéré depuis "..row.zone.." par "..actor.name:gsub("|","||")..".")
        if N.changed then N.changed()end
    elseif S.clock<group.due and actor.id<group.leader then group.leader=actor.id end
    return true
end
function S.Observe(unit)
    if not ns.Access.Allowed() or not N.channel or N.testMode then return false end
    local actor=ns.WantedMarkers.Actor(unit)
    if not actor or not wanted(actor.id)then return false end
    local mapId=publicCall(C_Map and C_Map.GetBestMapForUnit,"player")
    local info=mapId and publicCall(C_Map and C_Map.GetMapInfo,mapId)
    if not V.Integer(mapId,1) or type(info)~="table" or not C.Public(info.name)then return false end
    local at=now();if not at then return false end
    local row={enemyId=actor.id,mapId=mapId,zone=info.name,at=at}
    local key=actor.id..":"..mapId;local group=S.groups[key]
    if group and group.localSent and S.clock-group.started<S.cooldown then return false end
    S.outstanding=S.outstanding or {}
    if S.outstanding[key] and S.clock-S.outstanding[key]<S.lifetime then return false end
    if not S.Validate(row,N.channel.context)then return false end
    if not N.SendSighting(row)then return false end
    S.outstanding[key]=S.clock;return true
end
-- A queued packet is not an announced candidacy. Start the election only after
-- the final wire frame was accepted; a peer's earlier election stays final.
function S.Sent(row,owner)
    local key=row.enemyId..":"..row.mapId
    if S.Receive(row,owner)then S.groups[key].localSent=true end
end
function S.Tick(dt)
    S.clock=S.clock+dt
    if not ns.Access.Allowed() or not N.channel or N.testMode then S.Reset();return end
    local time=now()
    for key,at in pairs(S.outstanding or {})do if S.clock-at>=S.lifetime then S.outstanding[key]=nil end end
    for key,g in pairs(S.groups)do
        if S.clock-g.started>=S.cooldown then S.groups[key]=nil
        elseif not g.finished and S.clock>=g.due then
            g.finished=true
            if g.leader==N.channel.context.owner.id and time and time-g.row.at<=S.lifetime and wanted(g.row.enemyId)then
                local blocked=N.OutgoingGate()
                if blocked or not C_ChatInfo or type(C_ChatInfo.SendChatMessage)~="function"then S.lastChat="restricted_or_unavailable"
                else
                    local enemy=wanted(g.row.enemyId)
                    local stamp=type(date)=="function" and date("%H:%M",g.row.at) or tostring(g.row.at)
                    local text="[Primes] "..enemy.name:gsub("|","").." repéré depuis "..g.row.zone.." à "..stamp.." par "..g.observer.name:gsub("|","").."."
                    if #text>255 then text="[Primes] "..enemy.name:gsub("|","").." repéré depuis "..g.row.zone.." à "..stamp..". /sr pour les détails."end
                    if #text<=255 then
                        local ok=pcall(C_ChatInfo.SendChatMessage,text,"GUILD")
                        S.lastChat=ok and "submitted_not_confirmed" or "send_failed"
                    else S.lastChat="message_too_long"end
                end
            end
        end
    end
    S.scan=(S.scan or 0)+dt
    if S.scan>=1 then
        S.scan=0;local units={}
        for unit in pairs(S.units)do units[unit]=true end
        for unit in pairs(ns.WantedMarkers.units)do units[unit]=true end
        for unit in pairs(units)do S.Observe(unit)end
    end
end
function S.Initialize()
    SLASH_SYNDICATROUGEPRESENCE1="/srpresence"
    SlashCmdList.SYNDICATROUGEPRESENCE=function()
        if not ns.Access.Require()then return end
        print("Tableau des primes : présence "..(N.channel and not N.testMode and "active" or "en attente du partage réel").." ; observations récentes="..#S.notes.." ; chat="..(S.lastChat or "not_observed")..". Une soumission au chat ne confirme pas sa réception.")
    end
    local f=CreateFrame("Frame");S.frame=f
    f:RegisterEvent("NAME_PLATE_UNIT_ADDED");f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    f:SetScript("OnEvent",function(_,event,unit)
        if not C.Public(unit) or type(unit)~="string" or not unit:match("^nameplate%d+$")then return end
        if event=="NAME_PLATE_UNIT_REMOVED"then S.units[unit]=nil
        elseif V.Count(S.units)<80 then S.units[unit]=true;S.Observe(unit)end
    end)
    f:SetScript("OnUpdate",function(_,dt)S.Tick(dt)end)
end
