local _,ns=...
local M={units={},badges={},failed={},assigned={},behind={},index={},clock=0,enabled=true,limit=80,count=0}
ns.WantedMarkers=M
local C,V,W=ns.GuildContext,ns.Validation,ns.UI.Widgets
local function say(text)print("Tableau des primes : "..text)end
local function read(fn,...)
    if type(fn)~="function" then return nil,"api_unavailable" end
    local ok,value=pcall(fn,...)
    if not ok then return nil,"query_failed" end
    if not C.Public(value) then return nil,"protected_value" end
    return value
end
local function token(unit)
    return C.Public(unit) and type(unit)=="string" and #unit<=20 and unit:match("^nameplate%d+$")~=nil
end
local function allowed(frame,owned)
    if not C.Public(frame) or (type(frame)~="table" and type(frame)~="userdata") then return false end
    if read(frame.IsForbidden,frame)~=false then return false end
    return not owned or read(frame.IsProtected,frame)==false
end
local function hide(badge)
    if badge and allowed(badge,true) then pcall(badge.Hide,badge) end
end
function M.HideAll()
    for _,badge in pairs(M.assigned)do hide(badge)end
    M.assigned={}
end
function M.Remove(unit)
    if not token(unit) then return end
    hide(M.assigned[unit]);M.assigned[unit]=nil;M.units[unit]=nil;M.behind[unit]=nil
end
function M.Actor(unit)
    if not token(unit) then return nil,"invalid_unit" end
    if read(UnitIsPlayer,unit)~=true then return nil,"not_public_player" end
    local mode,reason=C.NameMode()
    if not mode then return nil,reason end
    local fn=mode=="regional" and UnitNameUnmodified or UnitFullName
    if type(fn)~="function" then return nil,"unit_name_api_unavailable" end
    local ok,name,second=pcall(fn,unit)
    if not ok or not C.Public(name) or not C.Public(second) then return nil,"unit_identity_unavailable" end
    -- Validate each part before concatenation or fallback. No alternate read
    -- after an inaccessible identity and no inspection of name FontStrings.
    if type(name)~="string" or not C.Named(name,"validation") then return nil,"unit_identity_invalid" end
    if second~=nil and second~="" and (type(second)~="string" or not C.Named(second,"validation")) then return nil,"unit_identity_invalid" end
    if mode=="regional" then return C.Named(name..((second~=nil and second~="") and " "..second or ""),C.regionalRealm) end
    if second==nil or second=="" then second=C.LocalRealm() end
    return C.Named(name,second)
end
function M.Rebuild()
    M.index={}
    if ns.GuildNative.testMode then return end
    local channel=ns.GuildNative.channel
    local db=channel and channel.session.db or M.runtime and M.runtime.db
    if not db or type(db.incidents)~="table" then return end
    local filtered={incidents={}}
    for id,row in pairs(db.incidents)do if row.source~="demo"then filtered.incidents[id]=row end end
    local rewards={};for _,row in ipairs(ns.Wanted.List(filtered))do rewards[row.enemy.id]=row.reward end
    for _,row in pairs(db.incidents)do
        if (row.source=="observed" or row.source=="manual") and not row.vengeanceId and type(row.enemy)=="table" then
            local actor=C.Named(row.enemy.name,row.enemy.realm)
            if actor and actor.id==row.enemy.id then
                local item=M.index[actor.id] or {actor=actor,reward=0}
                item.reward=rewards[actor.id] or 0;M.index[actor.id]=item
            end
        end
    end
end
function M.Badge(parent)
    local b=CreateFrame("Frame",nil,parent);b:Hide()
    if not allowed(b,true) then return nil end
    b:SetSize(106,69);b:EnableMouse(false)
    b:SetPoint("BOTTOM",parent,"TOP",0,10)
    local function stroke(x1,y1,x2,y2,thickness,color)
        local line=b:CreateLine(nil,"OVERLAY");line:SetThickness(thickness)
        line:SetStartPoint("TOP",b,x1,y1-21);line:SetEndPoint("TOP",b,x2,y2-21)
        line:SetColorTexture(unpack(color))
    end
    local function ring(radius,segments,thickness,color)
        for i=0,segments-1 do
            local a,c=i*2*math.pi/segments,(i+1)*2*math.pi/segments
            stroke(math.cos(a)*radius,math.sin(a)*radius,math.cos(c)*radius,math.sin(c)*radius,thickness,color)
        end
    end
    -- Geometry is the icon: native lines retain their detail at nameplate
    -- scale, without stretching a portrait or replacing a raid target icon.
    ring(16,20,4,{.085,.02,.01,.95})
    ring(16,20,1.3,{.86,.63,.29,1})
    ring(12,24,2.8,{.82,.055,.025,1})
    for _,p in ipairs({{-21,0,-9,0},{9,0,21,0},{0,-21,0,-9},{0,9,0,21}})do
        stroke(p[1],p[2],p[3],p[4],4,{.075,.015,.005,.95})
        stroke(p[1],p[2],p[3],p[4],2,{.93,.72,.37,1})
    end
    local dot=b:CreateTexture(nil,"OVERLAY");dot:SetSize(4,4);dot:SetPoint("TOP",b,"TOP",0,-19)
    dot:SetColorTexture(.95,.12,.04,1)
    local caption=W.Frame(b,0,42,106,27);caption:EnableMouse(false)
    W.Surface(caption,"thumb",106);caption.selected=true;W.Paint(caption)
    b.title=W.Text(caption,"RECHERCHÉ",2,1,102,10,W.gold,false,12);b.title:SetJustifyH("CENTER")
    b.reward=W.Text(caption,"",2,13,102,10,{1,.87,.61},false,12);b.reward:SetJustifyH("CENTER")
    return b
end
local function prepare(plate)
    local badge=M.badges[plate]
    if badge then return badge end
    if M.failed[plate]then return nil,"marker_creation_unavailable" end
    if M.count>=M.limit then return nil,"marker_pool_full" end
    if read(InCombatLockdown)~=false then return nil,"creation_deferred_combat" end
    M.count=M.count+1
    local ok,result=pcall(M.Badge,plate)
    if not ok or not result then M.failed[plate]=true;return nil,"marker_creation_unavailable" end
    M.badges[plate]=result
    return result
end
local function plateFor(unit)
    local plate,reason=read(C_NamePlate and C_NamePlate.GetNamePlateForUnit,unit,false)
    if not plate then return nil,reason or "plate_absent" end
    if not allowed(plate,false) then return nil,"plate_forbidden_or_unavailable" end
    if read(plate.GetUnit,plate)~=unit then return nil,"plate_unit_mismatch" end
    if read(plate.IsVisible,plate)~=true then return nil,"plate_hidden" end
    return plate
end
function M.Update(unit)
    if not ns.Access.Allowed()then M.HideAll();return end
    if not token(unit) or not M.units[unit] then return end
    hide(M.assigned[unit]);M.assigned[unit]=nil
    if not M.enabled or M.behind[unit] then return end
    local plate,reason=plateFor(unit)
    if not plate then M.lastReason=reason;return end
    local badge;badge,reason=prepare(plate)
    if not badge then M.lastReason=reason;return end
    hide(badge)
    -- A pooled base can be rebound even when a removal event was missed.
    for other,assigned in pairs(M.assigned)do if assigned==badge then M.assigned[other]=nil end end
    local actor;actor,reason=M.Actor(unit)
    if not actor then M.lastReason=reason;return end
    local item=M.index[actor.id]
    local isTest=false
    if M.testActor and ns.GuildNative.testMode and M.clock<M.testUntil then
        local channel=ns.GuildNative.channel
        if actor.id==M.testActor.id and channel and channel.context.test and C.Member(M.testActor,channel.context) then
            item={actor=actor,reward=3};isTest=true
        end
    end
    if not item then return end
    if not allowed(badge,true) then M.lastReason="marker_protected";return end
    local ok=pcall(function()
        badge.title:SetText(isTest and "TEST RECHERCHÉ" or "RECHERCHÉ")
        badge.reward:SetText(item.reward..(isTest and " réputation (test)" or " réputation"))
        badge:Show()
    end)
    if ok then M.assigned[unit]=badge;M.lastReason="public_identity_matched" else M.lastReason="marker_display_unavailable" end
end
function M.Refresh()
    if not ns.Access.Allowed()then M.HideAll();return end
    if not M.runtime then return end
    if WOW_PROJECT_CAMELOT==nil or WOW_PROJECT_ID~=WOW_PROJECT_CAMELOT then M.HideAll();M.lastReason="client_forever_required";return end
    if not M.enabled then M.HideAll();return end
    if M.testActor and (not ns.GuildNative.testMode or M.clock>=M.testUntil)then M.testActor=nil end
    M.Rebuild()
    for unit in pairs(M.units)do M.Update(unit)end
end
function M.Add(unit)
    if not token(unit) then return end
    M.Remove(unit)
    if V.Count(M.units)>=M.limit then M.lastReason="unit_limit";return end
    M.units[unit]=true;M.Update(unit)
end
function M.Scan()
    if not M.enabled then return end
    if WOW_PROJECT_CAMELOT==nil or WOW_PROJECT_ID~=WOW_PROJECT_CAMELOT then return end
    local plates=read(C_NamePlate and C_NamePlate.GetNamePlates)
    if type(plates)~="table" then M.lastReason="nameplates_api_unavailable";return end
    local count=0
    for _,plate in pairs(plates)do
        count=count+1;if count>M.limit then break end
        if allowed(plate,false)then
            local unit=read(plate.GetUnit,plate)
            if token(unit)then if M.units[unit]then M.Update(unit)else M.Add(unit)end end
        end
    end
end
function M.Preview()
    if M.preview and M.preview:IsShown()then M.preview:Hide();return true end
    if not M.preview then
        if read(InCombatLockdown)~=false then return false,"aperçu à ouvrir hors combat." end
        local p=CreateFrame("Frame",nil,UIParent);p:Hide();p:SetSize(210,32);p:SetPoint("CENTER",UIParent,"CENTER",0,100);p:EnableMouse(false)
        local name=W.Text(p,"Mornecroc — aperçu",0,2,210,14,W.gold,false,20);name:SetJustifyH("CENTER")
        W.Fill(W.Frame(p,10,23,190,8),{.38,.045,.02,1})
        local note=W.Text(p,"APERÇU LOCAL · aucune prime créée",-45,43,300,11,W.gold,false,20);note:SetJustifyH("CENTER")
        local badge=M.Badge(p);if not badge then return false,"aperçu indisponible." end
        badge.reward:SetText("3 réputation");badge:Show();M.preview=p
    end
    M.preview:Show();M.previewUntil=M.clock+20
    say("aperçu local du marqueur pendant 20 secondes. Aucune cible réelle ni prime ajoutée.");return true
end
function M.TryPlayer(name)
    local channel=ns.GuildNative.channel
    if not ns.GuildNative.testMode or not channel or not channel.context.test then return false,"utilise d’abord /srtest debut ; essai réservé au registre de test." end
    local actor=C.Sender(name,channel.context)
    if not actor or actor.id==channel.context.owner.id or not C.Member(actor,channel.context) then return false,"nom complet d’un autre membre vérifié requis." end
    M.testActor=actor;M.testUntil=M.clock+60;M.Refresh();M.Scan()
    say("essai local TEST de 60 secondes sur la plaque du membre. Aucune prime ni réputation attribuée.");return true
end
function M.Tick(elapsed)
    M.clock=M.clock+elapsed
    if M.preview and M.clock>=(M.previewUntil or 0)then M.preview:Hide()end
    if M.clock<(M.nextRefresh or 0)then return end
    M.nextRefresh=M.clock+.5;M.Refresh()
end
function M.Initialize(runtime)
    M.runtime=runtime
    M.enabled=not(type(runtime.root)=="table" and runtime.root.wantedMarkers==false)
    if M.events then return end
    local f=CreateFrame("Frame");M.events=f
    for _,event in ipairs({"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED","UNIT_NAME_UPDATE","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"})do
        local ok=pcall(f.RegisterEvent,f,event);if not ok then M.lastReason="event_subscription_unavailable" end
    end
    f:SetScript("OnEvent",function(_,event,unit,behind)
        if event=="NAME_PLATE_UNIT_REMOVED"then M.Remove(unit)
        elseif event=="NAME_PLATE_UNIT_ADDED"then M.Add(unit)
        elseif event=="UNIT_NAME_UPDATE"then if token(unit) and M.units[unit]then M.Update(unit)end
        elseif event=="NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED"then
            if token(unit) and M.units[unit]then M.behind[unit]=not C.Public(behind) or behind~=false;M.Update(unit)end
        elseif event=="PLAYER_ENTERING_WORLD"then M.HideAll();M.units={};M.behind={};M.Refresh();M.Scan()
        else M.Refresh();M.Scan() end
    end)
    f:SetScript("OnUpdate",function(_,elapsed)M.Tick(elapsed)end)
    SLASH_SYNDICATROUGEMARKERS1="/srmarque"
    SlashCmdList.SYNDICATROUGEMARKERS=function(command)
        if not ns.Access.Require()then return end
        local runtime=M.runtime
        local action,arg=command:match("^%s*(%S*)%s*(.-)%s*$");action=action:lower()
        if action=="activer" or action=="arreter" then
            M.enabled=action=="activer"
            if runtime.writable then runtime.root.wantedMarkers=M.enabled end
            M.HideAll();if not M.enabled then M.testActor=nil end;M.Refresh();if M.enabled then M.Scan()end
            say("marqueurs "..(M.enabled and "activés" or "arrêtés")..(runtime.writable and "." or " pour cette session uniquement."))
        elseif action=="apercu" then local ok,reason=M.Preview();if not ok then say(reason)end
        elseif action=="essai" then local ok,reason=M.TryPlayer(arg);if not ok then say(reason)end
        else say("marqueurs : "..(M.enabled and "activés" or "arrêtés").." ; primes ouvertes="..V.Count(M.index).." ; plaques suivies="..V.Count(M.units).." ; affichés="..V.Count(M.assigned).." ; dernier état="..(M.lastReason or "ready")..". /srmarque activer | arreter | apercu | essai Nom complet (mode test).")end
    end
    M.Refresh();M.Scan()
end
