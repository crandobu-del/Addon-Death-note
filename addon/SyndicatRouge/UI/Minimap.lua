local _,ns=...
local M={};ns.UI.Minimap=M
local W=ns.UI.Widgets
function M.Create()
    if M.button then return M.button end
    if not Minimap or not M.toggle then return nil end
    local b=CreateFrame("Button","SyndicatRougeMinimapButton",Minimap)
    b:SetSize(34,34);b:SetPoint("RIGHT",Minimap,"LEFT",-3,-28)
    local background=b:CreateTexture(nil,"BACKGROUND");background:SetAllPoints(b)
    local border=b:CreateTexture(nil,"OVERLAY");border:SetAllPoints(b)
    local function atlas(texture,name)
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then texture:SetAtlas(name,false);return true end
    end
    if not atlas(background,"UI-HUD-Minimap-Frame-Circle") then background:SetColorTexture(.24,.07,.035,1) end
    if not atlas(border,"UI-HUD-Minimap-Frame-Cycle") then border:SetColorTexture(.5,.22,.06,.3) end
    b.label=W.Text(b,"TP",7,8,26,14,W.gold,false,20)
    b:SetScript("OnClick",function(_,button)
        if button=="LeftButton" or button==nil then M.toggle() end
    end)
    b:SetScript("OnEnter",function(self)
        b.label:SetTextColor(1,1,.7)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_LEFT")
            GameTooltip:SetText("Tableau des primes",1,.82,.46)
            GameTooltip:AddLine("Clic gauche : ouvrir ou fermer le tableau.",1,1,1)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function()
        b.label:SetTextColor(unpack(W.gold))
        if GameTooltip then GameTooltip:Hide() end
    end)
    b:Show();M.button=b;return b
end
function M.Initialize(toggle)
    M.toggle=toggle
    if M.Create() then return end
    if M.events then return end
    local f=CreateFrame("Frame");M.events=f
    f:RegisterEvent("PLAYER_LOGIN");f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent",function()
        if M.Create() then
            f:UnregisterEvent("PLAYER_LOGIN");f:UnregisterEvent("ADDON_LOADED");f:SetScript("OnEvent",nil)
        end
    end)
end
