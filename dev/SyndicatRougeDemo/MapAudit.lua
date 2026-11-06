local _, demo = ...
local Audit = {}
demo.MapAudit = Audit

local function text(parent, x, y, width, height, value)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y); label:SetSize(width, height)
    label:SetJustifyH("LEFT"); label:SetJustifyV("TOP"); label:SetTextColor(1, 0.86, 0.56, 1)
    label:SetText(value or ""); return label
end
local function safe(value) return (tostring(value or ""):gsub("|", "||")) end
local function button(parent, x, y, width, label, action)
    local b = CreateFrame("Button", nil, parent)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y); b:SetSize(width, 34)
    local fill = b:CreateTexture(nil,"BACKGROUND"); fill:SetAllPoints(b); fill:SetColorTexture(0.38,0.07,0.035,1)
    text(b, 8, 9, width-16, 25, label); b:SetScript("OnClick", action); return b
end
function Audit.Count(report)
    local counts = { loaded=0, failed=0, pending=0, visual=0 }
    for _, row in ipairs(report.maps) do
        if row.technical=="textures_loaded" then counts.loaded=counts.loaded+1
        elseif row.technical=="pending" then counts.pending=counts.pending+1
        else counts.failed=counts.failed+1 end
        if row.visual=="passed" then counts.visual=counts.visual+1 end
    end
    return counts
end
function Audit.Readiness(map)
    local total, ready = 0, 0
    for _, tile in ipairs(map.tiles) do
        if tile:IsShown() then
            total=total+1
            if type(tile.IsObjectLoaded)~="function" then return "unknown",total end
            if tile:IsObjectLoaded() then ready=ready+1 end
        end
    end
    if total==0 then return "empty",0 end
    return ready==total and "loaded" or "waiting",total
end
function Audit.Mark(value)
    if Audit.running or not Audit.report then return end
    local row=Audit.report.maps[Audit.index]
    if row then row.visual=value; Audit.ShowIndex(Audit.index) end
end
function Audit.ShowIndex(index)
    if not Audit.report or #Audit.report.maps==0 then return end
    Audit.index=math.max(1,math.min(#Audit.report.maps,index))
    local row=Audit.report.maps[Audit.index]
    local ok, shown=pcall(SyndicatRouge.MapPreview.Display,Audit.window.preview,{mapId=row.mapID})
    Audit.window.title:SetText(safe(Audit.index.." / "..#Audit.report.maps.." — "..row.name.." (#"..row.mapID..")"))
    Audit.window.details:SetText(safe("Contrôle technique : "..row.technical.."\nContrôle visuel : "..row.visual))
    if not ok or not shown then Audit.window.details:SetText("Fond indisponible ou erreur de rendu ; à examiner.") end
    local count=Audit.Count(Audit.report)
    Audit.window.summary:SetText(string.format("%d cartes · %d fonds chargés · %d anomalies · %d en attente\n%d affichages validés manuellement · découverte %s",#Audit.report.maps,count.loaded,count.failed,count.pending,count.visual,
        Audit.report.truncated and "limitée" or #Audit.report.errors>0 and "avec erreurs" or "terminée dans les racines accessibles"))
end
function Audit.Open()
    if not Audit.window then
        local f=CreateFrame("Frame","SyndicatRougeMapAuditWindow",UIParent)
        Audit.window=f; f:SetSize(650,620); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:EnableMouse(true)
        f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart",function(self)self:StartMoving()end)
        f:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
        local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(f);bg:SetColorTexture(0.08,0.045,0.025,0.98)
        text(f,20,18,580,30,"Tableau des primes — Contrôle de toutes les cartes de zones")
        f.title=text(f,20,65,610,50,"Lancer le contrôle pour inventorier les cartes du client.")
        f.summary=text(f,20,125,610,65,"")
        f.details=text(f,20,200,610,45,"")
        f.preview=SyndicatRouge.MapPreview.Create(f)
        text(f,400,270,220,145,"Même encart que les dossiers.\n\nUn fond chargé ne prouve pas que son apparence est correcte.")
        button(f,20,455,190,"Contrôler toutes",function()Audit.Start()end)
        button(f,225,455,160,"Arrêter",function()Audit.Stop()end)
        button(f,400,455,210,"Fermer",function()Audit.Stop();f:Hide()end)
        button(f,20,503,180,"Précédente",function()if not Audit.running then Audit.ShowIndex((Audit.index or 1)-1) end end)
        button(f,215,503,180,"Suivante",function()if not Audit.running then Audit.ShowIndex((Audit.index or 1)+1) end end)
        button(f,20,551,270,"Affichage correct",function()Audit.Mark("passed")end)
        button(f,305,551,305,"Problème visuel",function()Audit.Mark("failed")end)
    end
    if not Audit.report and type(SyndicatRougeMapAudit)=="table" and SyndicatRougeMapAudit.version==1
        and type(SyndicatRougeMapAudit.maps)=="table" and type(SyndicatRougeMapAudit.errors)=="table" then Audit.report=SyndicatRougeMapAudit end
    Audit.window:Show()
    if Audit.report then Audit.ShowIndex(Audit.index or 1) end
end
function Audit.Stop()
    Audit.running=false
    if Audit.window then Audit.window:SetScript("OnUpdate",nil) end
    if Audit.report and not Audit.report.completed then Audit.report.interrupted=true end
end
local function finishRow(status)
    local row=Audit.report.maps[Audit.index]
    row.technical=status
    Audit.nextIndex=Audit.index+1; Audit.waiting=false
end
function Audit.Tick(elapsed)
    if not Audit.running then return end
    if not Audit.waiting then
        if Audit.nextIndex>#Audit.report.maps then
            Audit.report.completed=true; Audit.Stop(); Audit.ShowIndex(1); return
        end
        Audit.index=Audit.nextIndex; Audit.ShowIndex(Audit.index)
        local row=Audit.report.maps[Audit.index]
        local ok,rendered=pcall(SyndicatRouge.MapPreview.Display,Audit.window.preview,{mapId=row.mapID})
        if not ok then finishRow("render_error");return end
        if not rendered then finishRow("map_unavailable");return end
        Audit.waiting=true;Audit.elapsed=0
        return
    end
    Audit.elapsed=Audit.elapsed+elapsed
    if Audit.elapsed<0.15 then return end
    local ok,state,count=pcall(Audit.Readiness,Audit.window.preview)
    local row=Audit.report.maps[Audit.index];row.tileCount=count or 0
    if not ok then finishRow("texture_check_error")
    elseif state=="loaded" then finishRow("textures_loaded")
    elseif state=="unknown" then finishRow("texture_status_unavailable")
    elseif state=="empty" then finishRow("no_tiles")
    elseif Audit.elapsed>=3 then finishRow("texture_timeout") end
end
function Audit.Start()
    Audit.Open();Audit.Stop()
    local catalog=demo.MapCatalog.Collect()
    local report={version=1,target="forever",roots=catalog.roots,maps=catalog.maps,errors=catalog.errors,
        truncated=catalog.truncated,visited=catalog.visited,completed=false,interrupted=false}
    if type(GetBuildInfo)=="function" then report.clientVersion,report.build,report.buildDate,report.interface=GetBuildInfo() end
    Audit.report=report;SyndicatRougeMapAudit=report
    if #report.maps==0 then Audit.window.title:SetText("Aucune carte de zone identifiée ; vérifier les API du client.");return end
    Audit.running=true;Audit.waiting=false;Audit.nextIndex=1
    Audit.window:SetScript("OnUpdate",function(_,elapsed)Audit.Tick(elapsed)end)
end
SLASH_SYNDICATROUGEMAPAUDIT1="/sraudit"
SlashCmdList.SYNDICATROUGEMAPAUDIT=function(command)
    if SyndicatRouge and SyndicatRouge.RequireAccess and not SyndicatRouge.RequireAccess()then return end
    if command=="lancer" then Audit.Start() else Audit.Open() end
end

if SyndicatRouge and SyndicatRouge.OnAccessRevoked then SyndicatRouge.OnAccessRevoked(Audit.Stop)end
