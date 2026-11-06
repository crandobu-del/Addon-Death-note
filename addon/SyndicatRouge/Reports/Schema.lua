local _,ns=...
local R={version=1};ns.ReportSchema=R
local V,C=ns.Validation,ns.GuildContext
function R.Text(v,n)return V.String(v,n) and not v:find("|",1,true)end
function R.Keys(t,keys,limit)
    if type(t)~="table" then return false end
    local n=0;for k in pairs(t)do n=n+1;if n>(limit or 32) or not keys[k]then return false end end
    return true
end
local actorKeys={id=true,name=true,realm=true,guid=true,level=true,class=true,classID=true,race=true,raceID=true,sex=true,faction=true,guild=true}
function R.Actor(t,identity)
    if not R.Keys(t,actorKeys,12)then return nil end
    local out={}
    for k,v in pairs(t)do
        if k=="level" or k=="classID" or k=="raceID" then
            if not V.Integer(v,1,k=="level" and 100 or 1000)then return nil end
        elseif k=="sex" then if v~="male" and v~="female"then return nil end
        elseif not R.Text(v,k=="guid" and 100 or k=="id" and 180 or 100)then return nil end
        out[k]=v
    end
    if out.guid and not out.guid:match("^[%w%-]+$")then return nil end
    if out.id then
        local a=C.Named(out.name,out.realm)
        if not a or a.id~=out.id then return nil end
    elseif out.realm then return nil end
    if identity and not out.id then return nil end
    if not out.id and not out.guid then return nil end
    return out
end
local keys={version=true,id=true,at=true,guildId=true,victim=true,killer=true,attackers=true,location=true,source=true,confidence=true,finish=true,instanceType=true,pvp=true,revision=true}
local locKeys={mapId=true,x=true,y=true,zone=true,layer=true}
function R.Normalize(t,now,days)
    if not R.Keys(t,keys,16) or t.version~=1 or not R.Text(t.id,240) or not R.Text(t.guildId,100)
        or not V.Integer(now,1000) or not V.Integer(t.at,now-(days or 30)*86400,now+30)
        or not V.Integer(t.revision,1,100000) or t.pvp~=true then return nil,"invalid_report"end
    if t.source~="death_recap" and t.source~="combat_log"then return nil,"invalid_source"end
    if t.confidence~="confirmed" and t.confidence~="estimated" and t.confidence~="unknown"then return nil,"invalid_confidence"end
    if t.finish~="player" and t.finish~="pve" and t.finish~="environment" and t.finish~="unknown"then return nil,"invalid_finish"end
    if not t.instanceType or not ns.PvpScope.Validate(t.instanceType)then return nil,"excluded_scope"end
    local victim=R.Actor(t.victim,true);if not victim then return nil,"invalid_victim"end
    if t.id:sub(1,#victim.id+1)~=victim.id..":"then return nil,"invalid_report_id"end
    local killer=t.killer and R.Actor(t.killer)
    if t.killer and not killer then return nil,"invalid_killer"end
    if killer and (killer.id==victim.id or (victim.guid and killer.guid==victim.guid))then return nil,"self_kill"end
    if t.confidence=="confirmed" and (not killer or not killer.guid or not killer.guid:match("^Player%-") or t.finish~="player")then return nil,"unproved_attribution"end
    local attackers,seen={},{}
    if type(t.attackers)~="table"then return nil,"invalid_attackers"end
    for k,a in pairs(t.attackers)do
        if not V.Integer(k,1,16)then return nil,"too_many_attackers"end
        a=R.Actor(a);if not a or not a.guid or seen[a.guid]then return nil,"invalid_attackers"end
        seen[a.guid]=true;attackers[k]=a
    end
    for i=1,V.Count(attackers)do if not attackers[i]then return nil,"invalid_attackers"end end
    if #attackers==0 then return nil,"no_pvp_evidence"end
    local location={}
    if not R.Keys(t.location,locKeys,5)then return nil,"invalid_location"end
    for k,v in pairs(t.location)do
        if k=="mapId"then if not V.Integer(v,1)then return nil,"invalid_map"end
        elseif k=="x" or k=="y"then if type(v)~="number" or v~=v or v<0 or v>1 then return nil,"invalid_position"end
        elseif not R.Text(v,160)then return nil,"invalid_location"end
        location[k]=v
    end
    if (location.x==nil)~=(location.y==nil) or (location.x and not location.mapId)then return nil,"invalid_position"end
    return {version=1,id=t.id,at=t.at,guildId=t.guildId,victim=victim,killer=killer,attackers=attackers,location=location,
        source=t.source,confidence=t.confidence,finish=t.finish,instanceType=t.instanceType,pvp=true,revision=t.revision}
end
function R.Facts(t)
    local a={};for _,v in ipairs(t.attackers)do a[#a+1]=v.guid end;table.sort(a)
    return {id=t.id,at=t.at,guildId=t.guildId,victim=t.victim.id,killer=t.killer and t.killer.guid,attackers=a,
        source=t.source,confidence=t.confidence,finish=t.finish,instanceType=t.instanceType,location=t.location}
end
