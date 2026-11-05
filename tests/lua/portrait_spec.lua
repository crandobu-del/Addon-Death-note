local ns = ...
local P,V=ns.UI.Portraits,ns.Validation
local passed=0
local function check(ok,message)assert(ok,message);passed=passed+1 end
local p=P.Create(UIParent)
local actor={id="a",name="Orc",realm="Forever",raceID=2,classID=1,sex="male"}
local race,class=P.Display(p,actor)
check(race and class and p.race.atlas=="raceicon128-orc-male","male race and class use client atlases")
actor.sex="female";P.Display(p,actor)
check(p.race.atlas=="raceicon128-orc-female","female uses different client race art")
actor.sex=nil;race,class=P.Display(p,actor)
check(not race and class and not p.race:IsShown() and p.class.width==100,"unknown sex does not default to male")
local count=#SR_TEST_FRAMES;P.Display(p,actor)
check(count==#SR_TEST_FRAMES,"portraits reuse native texture regions")
P.Display(p,{})
check(not p.class:IsShown() and not p.race:IsShown() and p.unknown:IsShown(),"unknown actor clears prior portrait")
local texture=C_Texture;C_Texture=nil;P.Display(p,actor)
check(p.unknown:IsShown(),"missing client resources never load AI artwork")
C_Texture=texture
actor.sex="female"
local saved=V.Actor(actor)
check(saved.raceID==2 and saved.classID==1 and saved.sex=="female","actor preserves optional appearance metadata")
actor.sex="guessed";check(V.Actor(actor)==nil,"invalid sex rejected")
actor.sex=nil;actor.raceID=-1;check(V.Actor(actor)==nil,"invalid race identifier rejected")
actor.raceID=nil;actor.classID=0;check(V.Actor(actor)==nil,"invalid class identifier rejected")
local old={id="old",name="Old",realm="Forever",class="Mage"}
check(V.Actor(old)~=nil,"old ledgers remain readable without new attributes")
local db=ns.Core.New("portrait-test")
local enemy={id="a",name="A",realm="Forever",raceID=2,classID=1,sex="female"}
assert(ns.Incidents.Add(db,{id="portrait:1",guildId=db.guildId,enemy=enemy,victim=old,occurredAt=10,location={zone="Elwynn"},source="manual"}))
local restored=assert(ns.Store.Restore(ns.Store.Snapshot(db),db.guildId))
check(restored.incidents["portrait:1"].enemy.sex=="female" and restored.incidents["portrait:1"].enemy.raceID==2,"appearance survives ledger restore")
return {passed=passed}
