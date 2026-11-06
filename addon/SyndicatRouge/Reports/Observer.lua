local _,ns=...
local O={cache={},owners={},clock=0,limit=200};ns.EnemyObserver=O
local C,R,V=ns.GuildContext,ns.ReportSchema,ns.Validation
function O.Read(fn,...)
    if type(fn)~="function"then return nil end
    local ok,a,b,c=pcall(fn,...)
    if not ok or not C.Public(a) or not C.Public(b) or not C.Public(c)then return nil end
    return a,b,c
end
function O.Now()local t=O.Read(GetServerTime);if V.Integer(t,1000)then return t end end
function O.ByGUID(guid)
    local e=O.cache[guid];if e and O.clock-e.seen<=300 then return V.Copy(e.actor)end
end
function O.Owner(guid)
    local e=O.owners[guid];if e and O.clock-e.seen<=60 then return O.ByGUID(e.guid)end
end
function O.LinkOwner(ownerGUID,ownerName,petGUID)
    if not C.Public(ownerGUID) or not C.Public(ownerName) or not C.Public(petGUID)then return false end
    if not R.Text(ownerGUID,100) or not ownerGUID:match("^Player%-") or not R.Text(petGUID,100)
        or not (petGUID:match("^Pet%-") or petGUID:match("^Creature%-"))then return false end
    if not O.cache[ownerGUID]then
        O.Prune();O.cache[ownerGUID]={actor={guid=ownerGUID,name=R.Text(ownerName,100) and ownerName or nil},seen=O.clock}
    end
    if V.Count(O.owners)>=200 and not O.owners[petGUID]then O.owners={}end
    O.owners[petGUID]={guid=ownerGUID,seen=O.clock};return true
end
function O.Reset()O.cache={};O.owners={}end
function O.Prune()
    local count=0;local oldest,key
    for id,e in pairs(O.cache)do
        if O.clock-e.seen>300 then O.cache[id]=nil
        else count=count+1;if not oldest or e.seen<oldest then oldest=e.seen;key=id end end
    end
    if count>=O.limit and key then O.cache[key]=nil end
    for id,e in pairs(O.owners)do if O.clock-e.seen>60 then O.owners[id]=nil end end
end
local function validUnit(unit)
    return C.Public(unit) and type(unit)=="string" and #unit<=24 and
        (unit=="player" or unit=="target" or unit=="focus" or unit=="mouseover" or unit:match("^nameplate%d+$") or unit:match("^party%d+$") or unit:match("^raid%d+$"))
end
function O.Observe(unit)
    if not validUnit(unit) or not ns.Access.Allowed() or ns.GuildNative.testMode or not ns.ReportStore.Settings().enabled then return end
    if O.Read(UnitIsPlayer,unit)~=true then return end
    local guid=O.Read(UnitGUID,unit)
    if not R.Text(guid,100) or not guid:match("^Player%-[%w%-]+$")then return end
    local actor=O.ByGUID(guid) or {guid=guid};local before=V.Copy(actor)
    local mode=C.NameMode();local name,second=O.Read(mode=="regional" and UnitNameUnmodified or UnitFullName,unit)
    if mode and R.Text(name,80) and (second==nil or second=="" or R.Text(second,80))then
        local realm=mode=="regional" and C.regionalRealm or (second and second~="" and second or C.LocalRealm())
        local full=mode=="regional" and name..((second and second~="") and " "..second or "") or name
        local canonical=C.Named(full,realm)
        if canonical then for k,v in pairs(canonical)do actor[k]=v end end
    end
    local level=O.Read(UnitLevel,unit);if V.Integer(level,1,100)then actor.level=level end
    local class,_,classID=O.Read(UnitClass,unit);if R.Text(class,40)then actor.class=class end;if V.Integer(classID,1,1000)then actor.classID=classID end
    local race,_,raceID=O.Read(UnitRace,unit);if R.Text(race,40)then actor.race=race end;if V.Integer(raceID,1,1000)then actor.raceID=raceID end
    local sex=O.Read(UnitSex,unit);if sex==2 then actor.sex="male"elseif sex==3 then actor.sex="female"end
    local faction=O.Read(UnitFactionGroup,unit);if R.Text(faction,40)then actor.faction=faction end
    local guild=O.Read(GetGuildInfo,unit);if R.Text(guild,100)then actor.guild=guild end
    if not O.cache[guid]then O.Prune()end
    O.cache[guid]={actor=actor,seen=O.clock}
    -- Ownership is established by the game's unit relationship, never proximity/class guessing.
    local petGUID=O.Read(UnitGUID,unit.."pet")
    if R.Text(petGUID,100) and (petGUID:match("^Pet%-") or petGUID:match("^Creature%-"))then
        if V.Count(O.owners)>=200 then O.owners={}end
        O.owners[petGUID]={guid=guid,seen=O.clock}
    end
    if not V.Same(before,actor) and ns.ReportsRuntime then ns.ReportsRuntime.QueueIdentity(guid,actor)end
    return V.Copy(actor)
end
function O.Location()
    local out={};local map=O.Read(C_Map and C_Map.GetBestMapForUnit,"player")
    if V.Integer(map,1)then
        out.mapId=map
        local info=O.Read(C_Map and C_Map.GetMapInfo,map)
        if type(info)=="table" and C.Public(info.name) and R.Text(info.name,160)then out.zone=info.name end
        local pos=O.Read(C_Map and C_Map.GetPlayerMapPosition,map,"player")
        if pos and (type(pos)=="table" or type(pos)=="userdata")then
            local x,y=O.Read(pos.GetXY,pos)
            if type(x)=="number" and type(y)=="number" and x==x and y==y and x>=0 and x<=1 and y>=0 and y<=1 then out.x=x;out.y=y end
        end
    end
    -- No supported layer API has been verified for this client; leave it absent.
    return out
end
