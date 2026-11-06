local _, ns = ...
local UI, W, M = ns.UI, ns.UI.Widgets, ns.UI.Model
local names = {"Recherchés", "Vengeurs", "Journal", "Notifications"}

function UI.Refresh()
    if ns.Access and not ns.Access.Allowed()then if UI.window then UI.window:Hide()end;return end
    local f = UI.window
    if not f then return end
    f.view = UI.provider:View()
    if f.reportStatus then f.reportStatus:SetText((UI.provider.demo or UI.provider.test) and "Simulation · aucun rapport réel diffusé" or ns.ReportsRuntime.Status())end
    if f.reportSettings and f.reportSettings:IsShown()then f.reportSettings.Update()end
    f.mode:SetText(UI.provider.test and "TEST PARTAGÉ · événements fictifs · réputation de test" or UI.provider.demo and "DÉMONSTRATION · données fictives" or UI.provider.readOnly and "Sauvegarde à vérifier · lecture seule" or UI.provider.shared and "Registre de guilde · partage activé" or "Registre personnel · sauvegarde activée")
    for i, button in ipairs(f.tabs) do
        local unread=0
        if i==4 then for _,note in ipairs(f.view.notifications) do if not note.read then unread=unread+1 end end end
        button.label:SetText(names[i] .. (unread>0 and " ("..unread..")" or ""))
        W.SetSelected(button,i==f.tab)
    end
    -- Each view owns a bounded pool and only updates existing widgets on refresh.
    UI.Render(f)
end

function UI.SetProvider(provider)
    UI.provider = provider
    if UI.window then UI.window.selection = {}; UI.window.query = ""; UI.window.search:SetText(""); UI.Refresh() end
end

function UI.CapturePreferences()
    local f=UI.window
    if not f then return ns.Persistence.UI(UI.preferences) end
    local result={tab=f.tab}
    local point,parent,relativePoint,x,y=f:GetPoint(1)
    local function ordinary(value) return not (type(issecretvalue)=="function" and issecretvalue(value)) end
    if ordinary(point) and ordinary(parent) and ordinary(relativePoint) and ordinary(x) and ordinary(y)
        and (parent==nil or parent==UIParent) then
        result.position={point=point,relativePoint=relativePoint or point,x=x or 0,y=y or 0}
    end
    return ns.Persistence.UI(result)
end
function UI.ApplyPreferences(preferences)
    UI.preferences=ns.Persistence.UI(preferences)
    local f=UI.window
    if not f then return end
    f.tab=UI.preferences.tab
    local p=UI.preferences.position
    f:ClearAllPoints()
    if p then f:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y) else f:SetPoint("CENTER") end
end
local function changed()
    if UI.OnPreferencesChanged then UI.OnPreferencesChanged() end
end

function UI.Create()
    if UI.window then return UI.window end
    local f = CreateFrame("Frame", "SyndicatRougeWindow", UIParent)
    UI.window = f
    f:SetSize(1080, 720); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); changed() end)
    local art = f:CreateTexture(nil, "BACKGROUND"); art:SetAllPoints(f); art:SetTexture(W.media .. "Textures\\Register.tga")
    W.Text(f, "Tableau des primes", 180, 24, 450, 38, W.ink)
    W.Text(f, "Le Syndicat Rouge", 640, 28, 320, 28, W.red, true)
    f.mode = W.Text(f, "", 180, 65, 700, 12)
    W.Button(f, "", 1010, 25, 36, 34, function() f:Hide() end,false,"close")
    f.tabs, f.tab, f.selection, f.query = {}, ns.Persistence.UI(UI.preferences).tab, {}, ""
    for i, name in ipairs(names) do
        f.tabs[i] = W.Button(f, name, 43 + (i - 1) * 249, 86, 238, 38, function()
            f.tab = i; f.query = ""; f.search:SetText(""); UI.Refresh(); changed()
        end,false,"tab")
    end
    W.Text(f, "Rechercher", 44, 145, 130, 15)
    local edit = W.Frame(f, 170, 139, 470, 30, "EditBox")
    W.Fill(edit, {0.32, 0.13, 0.04, 0.13}); edit:SetFont("Fonts\\FRIZQT__.TTF", 15, "")
    edit:SetTextColor(unpack(W.ink)); edit:SetAutoFocus(false); edit:SetMaxLetters(80)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        f.query = self:GetText() or ""
        local panel = f.panels and f.panels[f.tab]
        if panel then panel.listScroll:SetVerticalScroll(0) end
        UI.Refresh()
    end)
    f.search = edit
    W.Button(f,"Rapports",710,139,135,32,function()
        local p=f.reportSettings
        if not p then
            p=W.Frame(f,42,181,996,450);f.reportSettings=p
            W.Fill(p,{.84,.65,.37,1});W.Skin(p,"paper",996)
            p:SetFrameLevel(f:GetFrameLevel()+20);p:EnableMouse(true)
            W.Text(p,"Rapports PvP",16,14,420,25,W.red,true)
            W.Text(p,"Partage GUILDE uniquement · aucune diffusion universelle",480,17,490,12)
            local actions={
                {"enabled",function(c)return "Collecte : "..(c.enabled and "active" or "arrêtée")end},
                {"sharing",function(c)return "Partage des rapports : "..(c.sharing and "activé" or "arrêté")end},
                {"mixed",function(c)return "Fin PvE / chute : "..(c.mixed=="ignore" and "ignorer" or "estimation seule")end},
                {"days",function(c)return "Conservation : "..c.days.." jours"end},
                {"limit",function(c)return "Plafond partagé : "..c.maxShared end},
                {"personalLimit",function(c)return "Plafond personnel : "..c.maxPersonal end},
                {"diagnostic",function(c)return "Diagnostic : "..(c.diagnostic and "visible" or "masqué")end},
            }
            p.controls={}
            for i,item in ipairs(actions)do
                local action,label=item[1],item[2]
                local b=W.Button(p,"",16,70+(i-1)*43,430,36,function()ns.ReportsRuntime.Control(action);UI.Refresh()end)
                p.controls[i]={button=b,label=label}
            end
            p.note=W.Text(p,"",480,70,490,14,W.ink,false,160)
            W.Button(p,"Fermer",825,398,145,32,function()p:Hide()end)
            p.Update=function()
                local c=ns.ReportStore.Settings()
                for _,item in ipairs(p.controls)do item.button.label:SetText(item.label(c));if ns.ReportStore.writable and not UI.provider.demo and not UI.provider.test then item.button:Enable()else item.button:Disable()end end
                p.note:SetText(c.diagnostic and ("Détection : "..ns.DeathDetector.status.."\nTransport : "..ns.GuildNative.status.." · Rapports : "..ns.ReportSync.status.."\n"..ns.ReportsRuntime.status) or "Les relais attendent la confirmation de la victime. Une estimation ne crée aucune prime. Données accessibles au client, sans preuve serveur.")
            end
            p:Hide()
        end
        p:SetShown(not p:IsShown());if p:IsShown()then p.Update()end
    end)
    W.Button(f,"Synchroniser",855,139,180,32,function()ns.ReportsRuntime.Control("sync");UI.Refresh()end,false,"primary")
    f.content = W.Frame(f, 42, 185, 996, 450)
    f.reportStatus=W.Text(f,"",46,643,820,12,W.gold)
    f.footer = W.Text(f, "", 46, 679, 820, 12, W.gold)
    f.pages={}
    f.previous=W.Button(f,"Préc.",894,651,68,32,function()f.pages[f.tab]=math.max(1,(f.pages[f.tab]or 1)-1);f.selection[f.tab]=nil;UI.Refresh()end)
    f.next=W.Button(f,"Suiv.",970,651,68,32,function()f.pages[f.tab]=(f.pages[f.tab]or 1)+1;f.selection[f.tab]=nil;UI.Refresh()end)
    if UISpecialFrames then table.insert(UISpecialFrames, "SyndicatRougeWindow") end
    UI.ApplyPreferences(UI.preferences)
    f:SetScript("OnHide",changed)
    f:Hide()
    return f
end

function UI.Toggle()
    if not ns.Access.Require()then return end
    if not UI.provider then return end
    local f = UI.Create()
    if f:IsShown() then f:Hide() else UI.Refresh(); f:Show() end
end
