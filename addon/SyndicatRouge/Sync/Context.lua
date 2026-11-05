local _,ns=...
local C={};ns.GuildContext=C
function C.Public(value)
    if type(issecretvalue)~="function" then return false end
    local ok,secret=pcall(issecretvalue,value)
    return ok and not secret
end
local function text(value)
    return C.Public(value) and type(value)=="string" and #value>0 and #value<=120
        and not value:find("[|%c]")
end
function C.Named(name,server)
    if not text(name) or not text(server) then return nil end
    server=server:gsub("%s","")
    if server=="" then return nil end
    return {id=name.."-"..server,name=name,realm=server}
end
function C.Actor(full,realm)
    if not text(full) then return nil end
    if text(realm) then
        local suffix="-"..realm:gsub("%s","")
        if full:sub(-#suffix)==suffix then return C.Named(full:sub(1,-#suffix-1),realm) end
    end
    local name,server=full:match("^([^%-]+)%-(.+)$")
    return C.Named(name or full,server or realm)
end
function C.LocalRealm()
    if type(GetNormalizedRealmName)~="function" then return nil end
    local ok,realm=pcall(GetNormalizedRealmName)
    if ok and text(realm) then return realm:gsub("%s","") end
end
function C.Member(actor,context)
    if type(actor)~="table" then return false end
    local canonical=C.Named(actor.name,actor.realm)
    if not canonical or canonical.id~=actor.id then return false end
    if context and context.owner and canonical.id==context.owner.id
        and canonical.name==context.owner.name and canonical.realm==context.owner.realm then return true end
    local ok,result=pcall(C_GuildInfo.MemberExistsByName,canonical.id)
    if not ok or not C.Public(result) then return false end
    if result==true then return true end
    if result~=false then return false end
    if canonical.name:find("-",1,true) then return false end
    -- Some guild name lookups use the unqualified name on the local realm.
    -- Never apply this to a foreign realm or after a protected lookup.
    local localRealm=C.LocalRealm()
    if not localRealm or canonical.realm~=localRealm then return false end
    ok,result=pcall(C_GuildInfo.MemberExistsByName,canonical.name)
    return ok and C.Public(result) and result==true
end
function C.Current()
    C.lastCheck={name="not_checked",realm="not_checked",member="not_checked"}
    if WOW_PROJECT_CAMELOT==nil or WOW_PROJECT_ID~=WOW_PROJECT_CAMELOT then return nil,"client_forever_required" end
    if not C_Club or not C_Club.GetGuildClubId or not C_Club.GetClubInfo
        or not C_GuildInfo or not C_GuildInfo.MemberExistsByName or not UnitFullName then return nil,"guild_api_unavailable" end
    local ok,id=pcall(C_Club.GetGuildClubId)
    if not ok or not C.Public(id) then return nil,"guild_identity_unavailable" end
    if type(id)~="string" and type(id)~="number" then return nil,"not_in_guild" end
    if type(id)=="number" and (id~=id or id<1 or id%1~=0) then return nil,"invalid_guild_id" end
    local clubId=id
    id=tostring(id)
    if not id:match("^%d+$") or #id>30 then return nil,"invalid_guild_id" end
    local infoOK,info=pcall(C_Club.GetClubInfo,clubId)
    if not infoOK or not C.Public(info) or type(info)~="table" or not text(info.name) then return nil,"guild_name_unavailable" end
    if info.name~=ns.Config.guildName then return nil,"different_guild" end
    local nameOK,name,realm=pcall(UnitFullName,"player")
    if not nameOK then return nil,"player_name_query_failed" end
    if not C.Public(name) or not C.Public(realm) then
        C.lastCheck.name=C.Public(name) and "public" or "protected"
        C.lastCheck.realm=C.Public(realm) and "public" or "protected"
        return nil,"player_identity_protected"
    end
    if not text(name) then C.lastCheck.name="missing_or_invalid";return nil,"player_name_unavailable" end
    C.lastCheck.name="public"
    if realm==nil or realm=="" then
        C.lastCheck.realm="missing"
        realm=C.LocalRealm()
        if not realm then return nil,"player_realm_unavailable" end
        C.lastCheck.realm="normalized_local"
    else C.lastCheck.realm="provided" end
    local owner=C.Named(name,realm)
    if not owner then return nil,"player_identity_invalid" end
    -- GetGuildClubId identifies the local player's own guild, already checked
    -- above. A roster name lookup can omit self or be uninitialized; it is not
    -- needed to establish this local membership. Remote actors remain checked.
    C.lastCheck.member="own_guild_club"
    return {guildId="guild:"..id,owner=owner}
end
function C.Roster(context,snapshot,message,sender)
    local map={[context.owner.id]=context.owner}
    local function add(actor)
        if not C.Member(actor,context) then return false end
        map[actor.id]=actor;return true
    end
    if sender and not add(sender) then return nil,"sender_not_member" end
    for _,source in ipairs({snapshot or {},message or {}}) do
        if type(source)~="table" or (source.incidents~=nil and type(source.incidents)~="table")
            or (source.claims~=nil and type(source.claims)~="table") then return nil,"invalid_records" end
        for _,row in pairs(source.incidents or {}) do
            if type(row)~="table" or not add(row.victim) then return nil,"victim_not_member" end
            local enemy=type(row.enemy)=="table" and C.Named(row.enemy.name,row.enemy.realm)
            if not enemy or enemy.id~=row.enemy.id then return nil,"enemy_identity_unavailable" end
        end
        for _,row in pairs(source.claims or {}) do if type(row)~="table" or not add(row.avenger) then return nil,"avenger_not_member" end end
    end
    return map
end
