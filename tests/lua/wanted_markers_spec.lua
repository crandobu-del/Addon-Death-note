local ns=...
-- Marker unit contracts are isolated; access lifecycle has its own fresh-VM suite.
ns.Access.Allowed=function()return true end
local M,C,V,N=ns.WantedMarkers,ns.GuildContext,ns.Validation,ns.GuildNative
local passed=0
local function test(name,fn)local ok,reason=pcall(fn);assert(ok,name..": "..tostring(reason));passed=passed+1 end
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local secret={};issecretvalue=function(v)return v==secret end
WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18
local units,plates,combat,nameReads={}, {},false,0
local own={id="Lyra Aube-Rouge-forever-regional",name="Lyra Aube-Rouge",realm="forever-regional"}
local friend={id="Kaelan Ombrelune-forever-regional",name="Kaelan Ombrelune",realm="forever-regional"}
RegionalUniqueNamesEnabled=function()return true end
UnitIsPlayer=function(unit)return units[unit] and units[unit].player or false end
UnitNameUnmodified=function(unit)
    nameReads=nameReads+1
    local data=units[unit];return data and data.name,data and data.second
end
UnitFullName=UnitNameUnmodified
GetNormalizedRealmName=function()return "Forever"end
InCombatLockdown=function()return combat end
C_GuildInfo={MemberExistsByName=function(name)return name==friend.name end}
C_NamePlate={
    GetNamePlateForUnit=function(unit,includeForbidden)eq(includeForbidden,false);return plates[unit]end,
    GetNamePlates=function(...)eq(select("#",...),0);local out={};for _,p in pairs(plates)do out[#out+1]=p end;return out end,
}
local runtime={writable=true,root={},db=assert(ns.Store.New("local:forever"))}
ns.Runtime=runtime
M.Initialize(runtime)
local function reset()
    M.HideAll();M.units={};M.badges={};M.failed={};M.behind={};M.count=0;M.index={};M.clock=0;M.nextRefresh=0;M.testActor=nil;M.enabled=true
    units={};plates={};combat=false;nameReads=0;N.channel=nil;N.testMode=false
    runtime.db=assert(ns.Store.New("local:forever"));runtime.root={};runtime.writable=true
end
local function player(unit,name,second)
    units[unit]={name=name,second=second,player=true}
    local p=CreateFrame("Frame",nil,UIParent);p.unitToken=unit;plates[unit]=p;return p
end
local function incident(name,second,id,source,realm)
    local actor=C.Named(name.." "..second,realm or C.regionalRealm)
    local ok,reason=ns.Incidents.Add(runtime.db,{id=id or "i",guildId=runtime.db.guildId,enemy=actor,victim=own,occurredAt=100,source=source or "observed",location={zone="Elwynn"}})
    assert(ok,reason);return actor
end
local function shown(unit)return M.assigned[unit]~=nil and M.assigned[unit]:IsShown()end
test("exact regional full identity and reward from open real incidents",function()
    reset();incident("Mornecroc","Sangrouge");incident("Mornecroc","Sangrouge","i2")
    player("nameplate1","Mornecroc","Sangrouge");M.Refresh();M.Add("nameplate1")
    assert(shown("nameplate1"));eq(M.assigned.nameplate1.reward.text,"2 réputation")
    eq(M.assigned.nameplate1.title.text,"RECHERCHÉ")
    local before=#SR_TEST_FRAMES;M.Refresh();M.Refresh();eq(#SR_TEST_FRAMES,before)
end)
test("full surname mismatch does not mark a namesake",function()
    reset();incident("Mornecroc","Sangrouge");player("nameplate1","Mornecroc","Autre");M.Refresh();M.Add("nameplate1");assert(not shown("nameplate1"))
end)
test("NPC is never resolved or marked",function()
    reset();incident("Mornecroc","Sangrouge");player("nameplate1","Mornecroc","Sangrouge");units.nameplate1.player=false
    M.Refresh();M.Add("nameplate1");eq(nameReads,0);assert(not shown("nameplate1"))
end)
test("protected name removes an existing marker without fallback query",function()
    reset();incident("Mornecroc","Sangrouge");player("nameplate1","Mornecroc","Sangrouge");M.Refresh();M.Add("nameplate1");local b=M.assigned.nameplate1
    local original=UnitFullName;UnitFullName=function()error("must not use another identity source")end
    units.nameplate1.name=secret;M.Refresh();assert(not b:IsShown());eq(M.assigned.nameplate1,nil)
    UnitFullName=original
end)
test("removed or silently rebound base never keeps the old mark",function()
    reset();incident("Mornecroc","Sangrouge");local p=player("nameplate1","Mornecroc","Sangrouge");M.Refresh();M.Add("nameplate1");local b=M.assigned.nameplate1
    M.Remove("nameplate1");assert(not b:IsShown());eq(M.units.nameplate1,nil)
    M.Add("nameplate1");assert(b:IsShown())
    units.nameplate2={name="Innocent",second="Passant",player=true};plates.nameplate1=nil;plates.nameplate2=p;p.unitToken="nameplate2"
    M.Add("nameplate2");assert(not b:IsShown());eq(M.assigned.nameplate1,nil);eq(M.assigned.nameplate2,nil)
end)
test("closing the incidents removes the wanted mark",function()
    reset();local enemy=incident("Mornecroc","Sangrouge");player("nameplate1","Mornecroc","Sangrouge");M.Refresh();M.Add("nameplate1");local b=M.assigned.nameplate1
    assert(ns.Vengeance.Resolve(runtime.db,{id="v",guildId=runtime.db.guildId,enemyId=enemy.id,avenger=friend,occurredAt=200,incidentIds={"i"}}))
    M.Refresh();assert(not b:IsShown());eq(M.assigned.nameplate1,nil)
end)
test("forbidden roots are never inspected beyond their access check",function()
    reset();incident("Mornecroc","Sangrouge");local p=player("nameplate1","Mornecroc","Sangrouge");p.forbidden=true
    p.GetUnit=function()error("forbidden root must not be read")end
    M.Refresh();M.Add("nameplate1");M.Scan();eq(M.count,0);eq(nameReads,0)
end)
test("combat reuses safe prepared badge but never creates a new attachment",function()
    reset();incident("Mornecroc","Sangrouge");player("nameplate1","Mornecroc","Sangrouge");M.Refresh();M.Add("nameplate1");local count=M.count
    combat=true;M.Refresh();assert(shown("nameplate1"))
    player("nameplate2","Mornecroc","Sangrouge");M.Add("nameplate2");eq(M.count,count);assert(not shown("nameplate2"))
    combat=false;M.Refresh();assert(shown("nameplate2"))
end)
test("protected unit metadata and player flag never trigger a name lookup",function()
    reset();incident("Mornecroc","Sangrouge");local p=player("nameplate1","Mornecroc","Sangrouge")
    p.GetUnit=function()return secret end;M.Refresh();M.Add("nameplate1");eq(nameReads,0);eq(M.count,0)
    p.GetUnit=function()return "nameplate1" end;units.nameplate1.player=secret
    M.Refresh();eq(nameReads,0);assert(not shown("nameplate1"))
end)
test("protected owned badge cannot be shown or allocated repeatedly",function()
    reset();incident("Mornecroc","Sangrouge");player("nameplate1","Mornecroc","Sangrouge")
    local original=M.Badge;local calls=0
    M.Badge=function(parent)calls=calls+1;local b=CreateFrame("Frame",nil,parent);b:Hide();b.protected=true;return b end
    M.Refresh();M.Add("nameplate1");M.Refresh();assert(not shown("nameplate1"));eq(calls,1)
    M.Badge=original
end)
test("camera hiding survives rescans until a public front-facing event",function()
    reset();incident("Mornecroc","Sangrouge");player("nameplate1","Mornecroc","Sangrouge");M.Refresh();M.Add("nameplate1");local b=M.assigned.nameplate1
    M.events.scripts.OnEvent(nil,"NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED","nameplate1",true);assert(not b:IsShown())
    M.Scan();assert(not b:IsShown())
    M.events.scripts.OnEvent(nil,"NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED","nameplate1",false);assert(shown("nameplate1"))
    M.events.scripts.OnEvent(nil,"NAME_PLATE_UNIT_BEHIND_CAMERA_CHANGED","nameplate1",secret);assert(not b:IsShown())
end)
test("demo and shared-test records never become automatic world marks",function()
    reset();incident("Mornecroc","Sangrouge","demo:i","demo");player("nameplate1","Mornecroc","Sangrouge");M.Refresh();M.Add("nameplate1");assert(not shown("nameplate1"))
    runtime.db.incidents["demo:i"].source="observed";N.testMode=true;M.Refresh();assert(not shown("nameplate1"));N.testMode=false
end)
test("test member mark is explicit temporary and never changes the ledger",function()
    reset();player("nameplate1","Kaelan","Ombrelune");M.Add("nameplate1");local before=V.Copy(runtime.root)
    eq(M.TryPlayer(friend.name),false)
    N.testMode=true;N.channel={context={test=true,nameMode="regional",owner=own},session={db=runtime.db}}
    assert(M.TryPlayer(friend.name));assert(shown("nameplate1"));eq(M.assigned.nameplate1.title.text,"TEST RECHERCHÉ")
    assert(V.Same(before,runtime.root));eq(V.Count(runtime.db.incidents),0)
    M.Tick(61);assert(not shown("nameplate1"));eq(M.testActor,nil)
    N.testMode=false;N.channel=nil
end)
test("classic realm format is exact and a protected mode refuses reads",function()
    reset();RegionalUniqueNamesEnabled=function()return false end
    local actor=C.Named("Mornecroc","OtherRealm")
    assert(ns.Incidents.Add(runtime.db,{id="i",guildId=runtime.db.guildId,enemy=actor,victim=own,occurredAt=100,source="observed",location={zone="Elwynn"}}))
    player("nameplate1","Mornecroc","OtherRealm");M.Refresh();M.Add("nameplate1");assert(shown("nameplate1"))
    RegionalUniqueNamesEnabled=function()return secret end;local before=nameReads;M.Refresh();eq(nameReads,before);assert(not shown("nameplate1"))
    RegionalUniqueNamesEnabled=function()return true end
end)
test("disabled preference persists while a read-only profile is untouched",function()
    reset();SlashCmdList.SYNDICATROUGEMARKERS("arreter");eq(runtime.root.wantedMarkers,false);eq(M.enabled,false)
    runtime.writable=false;local before=V.Copy(runtime.root);SlashCmdList.SYNDICATROUGEMARKERS("activer")
    eq(M.enabled,true);assert(V.Same(before,runtime.root));runtime.writable=true
end)
test("preview expires without creating incidents and pools stay bounded",function()
    reset();assert(M.Preview());eq(V.Count(runtime.db.incidents),0);M.Tick(21);assert(not M.preview:IsShown())
    for i=1,100 do player("nameplate"..i,"Innocent","Passant");M.Add("nameplate"..i)end
    assert(V.Count(M.units)<=80);assert(M.count<=80);eq(V.Count(M.assigned),0)
end)
return {passed=passed}
