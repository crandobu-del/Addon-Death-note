local _, ns = ...
local UI, W, M = ns.UI, ns.UI.Widgets, ns.UI.Model
local names = {"Recherchés", "Vengeurs", "Journal", "Notifications"}

function UI.Refresh()
    local f = UI.window
    if not f then return end
    f.view = UI.provider:View()
    f.mode:SetText(UI.provider.demo and "DÉMONSTRATION · données fictives" or UI.provider.readOnly and "Sauvegarde à vérifier · lecture seule" or UI.provider.shared and "Registre de guilde · partage activé" or "Registre personnel · sauvegarde activée")
    for i, button in ipairs(f.tabs) do
        button.label:SetText((i == f.tab and "• " or "") .. names[i])
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
    W.Text(f, "DEATH NOTE", 180, 24, 450, 38, W.ink)
    W.Text(f, "Le Syndicat Rouge", 640, 28, 320, 28, W.red, true)
    f.mode = W.Text(f, "", 180, 65, 700, 12)
    W.Button(f, "X", 1010, 25, 36, 34, function() f:Hide() end)
    f.tabs, f.tab, f.selection, f.query = {}, ns.Persistence.UI(UI.preferences).tab, {}, ""
    for i, name in ipairs(names) do
        f.tabs[i] = W.Button(f, name, 43 + (i - 1) * 249, 86, 238, 38, function()
            f.tab = i; f.query = ""; f.search:SetText(""); UI.Refresh(); changed()
        end)
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
    W.Text(f, "Molette : faire défiler", 800, 146, 230, 12)
    f.content = W.Frame(f, 42, 185, 996, 450)
    f.footer = W.Text(f, "", 46, 668, 970, 13, W.gold)
    if UISpecialFrames then table.insert(UISpecialFrames, "SyndicatRougeWindow") end
    UI.ApplyPreferences(UI.preferences)
    f:SetScript("OnHide",changed)
    f:Hide()
    return f
end

function UI.Toggle()
    if not UI.provider then return end
    local f = UI.Create()
    if f:IsShown() then f:Hide() else UI.Refresh(); f:Show() end
end
