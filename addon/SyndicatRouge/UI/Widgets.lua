local _, ns = ...
local W = {}
ns.UI.Widgets = W
W.media = "Interface\\AddOns\\SyndicatRouge\\Media\\"
W.ink = {0.19, 0.09, 0.035}
W.red = {0.50, 0.045, 0.025}
W.gold = {0.96, 0.79, 0.46}

function W.Frame(parent, x, y, width, height, kind)
    local f = CreateFrame(kind or "Frame", nil, parent)
    f:SetSize(width, height); f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    return f
end
function W.Fill(parent, color)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(parent); t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return t
end
function W.Text(parent, text, x, y, width, size, color, hand, height)
    local t = parent:CreateFontString(nil, "OVERLAY")
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y); t:SetSize(width, height or size * 2.5)
    t:SetFont(hand and (W.media .. "Fonts\\Handlee-Regular.ttf") or "Fonts\\FRIZQT__.TTF", size, "")
    t:SetTextColor(unpack(color or W.ink)); t:SetJustifyH("LEFT"); t:SetJustifyV("TOP")
    t:SetWordWrap(true); t:SetText(ns.UI.Model.Text(text))
    return t
end
function W.Button(parent, text, x, y, width, height, action, selected)
    local b = W.Frame(parent, x, y, width, height, "Button")
    local fill = W.Fill(b, selected and {0.44, 0.035, 0.02, 0.95} or {0.22, 0.09, 0.035, 0.9})
    b.label = W.Text(b, text, 10, 9, width - 20, 15, W.gold, false, height - 10)
    b:SetScript("OnClick", action)
    b:SetScript("OnEnter", function() fill:SetColorTexture(0.48, 0.14, 0.055, 1) end)
    b:SetScript("OnLeave", function()
        if selected then fill:SetColorTexture(0.44, 0.035, 0.02, 0.95)
        else fill:SetColorTexture(0.22, 0.09, 0.035, 0.9) end
    end)
    return b
end
function W.Scroll(parent, x, y, width, height)
    local scroll = W.Frame(parent, x, y, width, height, "ScrollFrame")
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width - 18, height); scroll:SetScrollChild(child)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 48)))
    end)
    W.Button(parent, "^", x + width - 17, y, 17, 30, function()
        scroll:SetVerticalScroll(math.max(0, scroll:GetVerticalScroll() - 160))
    end)
    W.Button(parent, "v", x + width - 17, y + height - 30, 17, 30, function()
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScrollRange(), scroll:GetVerticalScroll() + 160))
    end)
    return child, scroll
end
function W.Rule(parent, x, y, width)
    return W.Fill(W.Frame(parent, x, y, width, 1), {0.33, 0.13, 0.035, 0.45})
end
