local _, demo = ...
local C = {}
demo.ChatDeathProbe = C
local events={"CHAT_MSG_SYSTEM","CHAT_MSG_COMBAT_MISC_INFO","PLAYER_DEAD"}

function C.Parse(value)
    if type(issecretvalue)~="function" then return nil,"guard_missing" end
    local ok,secret=pcall(issecretvalue,value)
    if not ok then return nil,"guard_failed" end
    if secret then return nil,"secret" end
    if type(value)~="string" then return nil,"not_text" end
    if value:find("|K",1,true) or value:find("|k",1,true) then return nil,"protected_text" end
    if #value>512 then return nil,"too_long" end
    local text=value:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local name=text:match("^Vous avez été tué par (.-)%s*[%.!]?$" )
    if not name then return nil,"no_match" end
    name=name:match('^"(.-)"$') or name:match("^«%s*(.-)%s*»$") or name
    local linked=false
    if name:find("|",1,true) then
        local header,display=name:match("^|Hplayer:([^|]+)|h%[([^%[%]|]+)%]|h$")
        if not header then return nil,"unsupported_markup" end
        local target=header:match("^([^:]+)")
        if target~=display and (not target or target:match("^([^-]+)%-")~=display) then return nil,"link_mismatch" end
        name=target;linked=true
    end
    if #name==0 or #name>160 or name:find('[%z\1-\32\127|%[%]"<>:%.!]') then return nil,"invalid_name" end
    return {name=name,playerLink=linked},"matched"
end
function C.Stop()
    if C.frame then
        for _,event in ipairs(events) do C.frame:UnregisterEvent(event) end
        C.frame:SetScript("OnEvent",nil)
    end
    if C.report then C.report.running=false end
    C.pending={}
end
local function correlate(candidate)
    if C.matchedDeath==C.report.deaths then
        if C.lastName~=candidate.name then C.lastName=nil;C.report.lastResult="multiple_candidates" end
        return
    end
    C.matchedDeath=C.report.deaths;C.lastName=candidate.name
    C.report.correlated=C.report.correlated+1
    C.report.lastResult=candidate.playerLink and "player_link_candidate" or "plain_name_candidate"
    C.report.lastSource=candidate.event
    print("Tableau des primes : message personnel de mort reconnu. Consulte /srchat bilan avant de recharger.")
end
function C.Receive(event,value)
    if not C.report or not C.report.running then return end
    local now=GetTime()
    if event=="PLAYER_DEAD" then
        C.report.deaths=C.report.deaths+1;C.deathAt=now
        for _,candidate in ipairs(C.pending) do if now-candidate.at<=5 then correlate(candidate) end end
        C.pending={};return
    end
    local row=C.report.events[event]
    if not row or row.subscription~="registered" then return end
    row.received=math.min(row.received+1,10000)
    local candidate,status=C.Parse(value)
    row.status[status]=math.min((row.status[status] or 0)+1,10000)
    if not candidate then return end
    candidate.at=now;candidate.event=event
    if C.deathAt and now-C.deathAt<=5 then correlate(candidate)
    else
        C.pending[#C.pending+1]=candidate
        if #C.pending>4 then table.remove(C.pending,1) end
    end
end
function C.Start()
    C.Stop();C.pending={};C.lastName=nil;C.deathAt=nil;C.matchedDeath=nil
    C.report={running=false,events={},deaths=0,correlated=0,lastResult="not_observed"}
    if type(WOW_PROJECT_CAMELOT)~="number" or WOW_PROJECT_ID~=WOW_PROJECT_CAMELOT then C.report.lastResult="wrong_client";return end
    if type(GetTime)~="function" then C.report.lastResult="clock_missing";return end
    if not C.frame then C.frame=CreateFrame("Frame") end
    for _,event in ipairs(events) do
        local row={received=0,status={}};C.report.events[event]=row
        local ok,registered=pcall(C.frame.RegisterEvent,C.frame,event)
        row.subscription=ok and registered==true and "registered" or "failed"
    end
    if C.report.events.PLAYER_DEAD.subscription~="registered" then C.report.lastResult="death_subscription_failed";C.Stop();return end
    C.report.running=true
    C.frame:SetScript("OnEvent",function(_,event,message)C.Receive(event,message)end)
end
function C.Show()
    local r=C.report
    if not r then print("Tableau des primes : test inactif. Tape /srchat debut ; après rechargement, il faut le réactiver.");return end
    print("Tableau des primes — test du message : "..(r.running and "actif" or "arrêté").." ; morts observées="..r.deaths..", candidats associés="..r.correlated)
    for _,event in ipairs({"CHAT_MSG_SYSTEM","CHAT_MSG_COMBAT_MISC_INFO"}) do
        local row=r.events[event]
        if row then print(event.." : "..row.subscription..", reçus="..row.received..", reconnus="..(row.status.matched or 0)..", protégés="..((row.status.secret or 0)+(row.status.protected_text or 0))) end
    end
    print("Dernier résultat : "..r.lastResult)
    if C.lastName then print("Nom candidat lisible : "..C.lastName.." ; source="..(r.lastSource or "inconnue")) end
    print("Diagnostic temporaire, aucun texte brut sauvegardé, aucun incident ni point créé.")
end
SLASH_SYNDICATROUGECHATDEATH1="/srchat"
SlashCmdList.SYNDICATROUGECHATDEATH=function(command)
    command=(command or ""):lower():gsub("é","e"):match("^%s*(.-)%s*$")
    if command=="debut" then C.Start();C.Show()
    elseif command=="fin" then C.Stop();C.Show()
    elseif command=="" or command=="bilan" then C.Show()
    else print("Tableau des primes : commande inconnue. Utilise /srchat debut, /srchat bilan ou /srchat fin.") end
end
