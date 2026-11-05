local _,ns=...
local C={};ns.GuildContext=C
function C.Public(value)
    return type(issecretvalue)=="function" and not issecretvalue(value)
end
local function text(value)
    return C.Public(value) and type(value)=="string" and #value>0 and #value<=120
        and not value:find("[|%c]")
end
function C.Actor(full,realm)
    if not text(full) then return nil end
    local name,server=full:match("^([^%-]+)%-(.+)$")
    name=name or full;server=server or realm
    if not text(server) then return nil end
    server=server:gsub("%s","")
    if server=="" then return nil end
    return {id=name.."-"..server,name=name,realm=server}
end
function C.Member(actor,context)
    if type(actor)~="table" then return false end
    local canonical=C.Actor(actor.name,actor.realm)
    if not canonical or canonical.id~=actor.id then return false end
    local ok,result=pcall(C_GuildInfo.MemberExistsByName,canonical.id)
    return ok and C.Public(result) and result==true
end
function C.Current()
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
    local name,realm=UnitFullName("player")
    local owner=C.Actor(name,realm)
    if not owner or not C.Member(owner) then return nil,"player_identity_unavailable" end
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
            local enemy=type(row.enemy)=="table" and C.Actor(row.enemy.name,row.enemy.realm)
            if not enemy or enemy.id~=row.enemy.id then return nil,"enemy_identity_unavailable" end
        end
        for _,row in pairs(source.claims or {}) do if type(row)~="table" or not add(row.avenger) then return nil,"avenger_not_member" end end
    end
    return map
end
