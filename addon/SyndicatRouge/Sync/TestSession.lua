local _,ns=...
local T={};ns.SyncTest=T
local N,C,V=ns.GuildNative,ns.GuildContext,ns.Validation
local function say(text)print("Tableau des primes [TEST] : "..text)end
local function show()
    if SyndicatRouge and SyndicatRouge.ResetView then SyndicatRouge.ResetView() end
    if ns.UI and ns.UI.Create then ns.UI.Create():Show() end
end
local function ready()
    if not N.testMode or not N.channel or not N.channel.context.test then return nil,"active d’abord /srtest debut sur les deux clients." end
    return N.channel
end
local function now()
    if type(GetServerTime)~="function" then return nil end
    local ok,value=pcall(GetServerTime)
    if ok and C.Public(value) and V.Integer(value,1000) then return value end
end
function T.Enter()
    if N.testMode then say("mode test déjà actif. /srtest aide");show();return true end
    local real=T.realRuntime
    if not real or not real.writable then return false,"profil en lecture seule." end
    local context,reason=C.Current()
    if not context then return false,reason end
    local saved=real.root.guildTest
    if saved~=nil and (type(saved)~="table" or saved.version~=1 or type(saved.guilds)~="table" or type(saved.guildDelivery)~="table") then
        return false,"ancien profil de test conservé : format non reconnu."
    end
    local root=V.Copy(saved or {version=1,guilds={},guildDelivery={}})
    root.syncEnabled=true
    T.resumeReal=N.channel~=nil
    N.testMode=true;N.runtime={writable=true,root=root}
    local ok,errorCode=N.Start()
    if not ok then
        N.testMode=false;N.runtime=real
        if T.resumeReal then N.Start() else N.Suspend() end
        return false,errorCode
    end
    real.root.guildTest=root
    say("mode TEST PARTAGÉ actif ; le partage normal est suspendu. Aucun événement ni point réel modifié. Ton ami doit aussi faire /srtest debut.")
    show();return true
end
function T.Leave()
    if not N.testMode then say("mode test déjà arrêté.");return true end
    N.testMode=false;N.runtime=T.realRuntime;N.prefix="SRGuild2"
    local ok,reason=true
    if T.resumeReal or N.runtime.root.syncEnabled==true then ok,reason=N.Start() else N.Suspend() end
    say("mode test arrêté ; données fictives conservées séparément."..(ok and " Registre normal rétabli." or " Reprise normale en attente : "..tostring(reason).."."))
    show();return ok,reason
end
local enemies={
    mornecroc={name="TEST Mornecroc",race="Orc",class="Guerrier",raceID=2,classID=1,sex="male"},
    selenombre={name="TEST Sélénombre",race="Elfe de la nuit",class="Mage",raceID=4,classID=8,sex="female"},
    brisecroc={name="TEST Brisecroc",race="Nain",class="Paladin",raceID=3,classID=2,sex="male"},
    noctis={name="TEST Noctis",race="Humain",class="Voleur",raceID=1,classID=4,sex="male"},
}
T.targets={mornecroc={"test:v1:morne:1","test:v1:morne:2"},selenombre={"test:v1:selene:1"},brisecroc={"test:v1:brise:1"},noctis={"test:v1:noctis:1"}}
function T.Build(guildId,victim,friend,time)
    local out={}
    local function row(id,target,who,age,mapId,zone,x,y)
        local attrs=enemies[target];local enemy=assert(C.Named(attrs.name,"forever-test"))
        for key,value in pairs(attrs)do enemy[key]=value end;enemy.level=60
        out[#out+1]={id=id,guildId=guildId,enemy=enemy,victim=V.Copy(who),occurredAt=time-age,source="demo",
            location={mapId=mapId,zone=zone,x=x,y=y}}
    end
    row("test:v1:morne:1","mornecroc",victim,600,1434,"Vallée de Strangleronce",.32,.29)
    row("test:v1:morne:2","mornecroc",victim,500,1434,"Vallée de Strangleronce",.40,.35)
    row("test:v1:selene:1","selenombre",victim,400,1434,"Vallée de Strangleronce",.45,.50)
    row("test:v1:brise:1","brisecroc",victim,300,1417,"Hautes-terres d’Arathi",.50,.50)
    row("test:v1:noctis:1","noctis",friend,200,1417,"Hautes-terres d’Arathi",.60,.40)
    return out
end
function T.Load(friendName)
    local c,reason=ready();if not c then return false,reason end
    if next(c.session.incidents)~=nil or next(c.session.claims)~=nil then return false,"registre de test déjà rempli ; /srtest fin puis /srtest effacer sur les deux clients pour recommencer." end
    local friend
    if friendName and friendName~="" then friend=C.Sender(friendName,c.context)
    else
        for id in pairs(c.peers)do
            local member=c.session.members[id]
            if member and id~=c.context.owner.id then
                if friend then return false,"plusieurs membres : /srtest charger Nom complet de ton ami" end
                friend=member
            end
        end
    end
    if not friend or friend.id==c.context.owner.id or not C.Member(friend,c.context) then return false,"ami non reconnu ; attendez le partage, ou /srtest charger Nom complet de ton ami." end
    local time=now();if not time then return false,"heure publique du client indisponible." end
    local rows=T.Build(c.context.guildId,c.context.owner,friend,time)
    local roster,errorCode=C.Roster(c.context,ns.Guild.Snapshot(c.session),{incidents=rows})
    if not roster then return false,errorCode end
    local session;session,errorCode=ns.Guild.Restore(ns.Guild.Snapshot(c.session),c.context.guildId,c.context.owner.id,roster)
    if not session then return false,errorCode end
    for _,row in ipairs(rows)do
        local ok,result=ns.Guild.AddIncident(session,row);if not ok then return false,result end
    end
    local ok;ok,errorCode=ns.Channel.Commit(c,session)
    if not ok then return false,errorCode end
    local queued,queueError=N.Publish()
    say("5 incidents fictifs chargés, 4 recherchés ; "..(queued and "diffusion de test en file." or "sauvegardés mais diffusion en attente : "..tostring(queueError).."."))
    show();return true
end
local function gankIds()local ids={};for i=1,6 do ids[i]="test:gank:v1:"..i end;return ids end
function T.LoadGank()
    local c,reason=ready();if not c then return false,reason end
    local ids=gankIds()
    if c.session.incidents[ids[1]]then return false,"scénario gank déjà chargé dans ce registre de test."end
    if V.Count(c.session.incidents)+6>ns.Protocol.maxRecords then return false,"registre de test plein."end
    local time=now();if not time then return false,"heure publique indisponible."end
    local enemy=C.Named("TEST Traqueur",c.context.owner.realm)
    for i,id in ipairs(ids)do
        local ok,errorCode=N.Change("incident",{id=id,guildId=c.context.guildId,enemy=enemy,victim=V.Copy(c.context.owner),
            occurredAt=time-600+i*60,source="demo",location={zone="Strangleronce",mapId=1434,x=.32,y=.29}})
        if not ok then return false,errorCode end
    end
    say("TEST GANK : 6 morts fictives, bonus ×4, récompense 24 réputation de test. L’ami : /srtest venger traqueur.");show();return true
end
function T.Avenge(target)
    local c,reason=ready();if not c then return false,reason end
    local ids=target=="traqueur" and gankIds() or T.targets[target]
    if not ids then return false,"cible : mornecroc, selenombre, brisecroc ou noctis." end
    local incident=c.session.incidents[ids[1]]
    if not incident then return false,"données non reçues ; le premier joueur fait /srtest charger." end
    if incident.victim.id==c.context.owner.id then return false,"pour ce scénario, c’est à ton ami de simuler cette vengeance." end
    local time=now();if not time then return false,"heure publique du client indisponible." end
    local ok,result=N.Change("claim",{id="test:v1:vengeance:"..target,guildId=c.context.guildId,enemyId=incident.enemy.id,
        avenger=V.Copy(c.context.owner),occurredAt=time,incidentIds=V.Copy(ids)})
    if ok then
        local reward=N.channel.session.db.vengeances["test:v1:vengeance:"..target].reward
        say("vengeance SIMULÉE : "..target..", "..reward.." point(s) de test ; aucune preuve de kill réel.");show()
    end
    return ok,result
end
function T.Bind(runtime)
    T.realRuntime=runtime
    SLASH_SYNDICATROUGETEST1="/srtest"
    SlashCmdList.SYNDICATROUGETEST=function(command)
        if not ns.Access.Require()then return end
        local action,arg=command:match("^%s*(%S*)%s*(.-)%s*$");action=action:lower()
        local ok,reason
        if action=="debut" then ok,reason=T.Enter()
        elseif action=="fin" then ok,reason=T.Leave()
        elseif action=="charger" then ok,reason=T.Load(arg)
        elseif action=="gank" then ok,reason=T.LoadGank()
        elseif action=="venger" then ok,reason=T.Avenge(arg:lower())
        elseif action=="effacer" then
            if N.testMode then say("arrête d’abord le test avec /srtest fin.");return end
            if not runtime.writable then say("profil en lecture seule.");return end
            runtime.root.guildTest=nil;say("données de test effacées sur ce personnage uniquement. L’ami doit aussi arrêter/effacer son test pour recommencer.");return
        else
            say("/srtest debut | charger [Nom complet de l’ami] | gank | venger traqueur | venger mornecroc | fin | effacer. Les deux joueurs entrent en test ; un seul charge les données.");return
        end
        if not ok then say("action refusée : "..tostring(reason)) end
    end
end
