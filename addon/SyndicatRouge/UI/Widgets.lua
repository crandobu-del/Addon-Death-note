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
local function plate(parent, layer, inset, color, sublevel)
    local t=parent:CreateTexture(nil,layer,nil,sublevel or 0)
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",inset,-inset)
    t:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-inset,inset)
    if color then t:SetColorTexture(unpack(color)) end
    return t
end
local function strip(parent,point,inset,height,color)
    local t=parent:CreateTexture(nil,"ARTWORK")
    t:SetPoint(point.."LEFT",parent,point.."LEFT",inset,point=="TOP" and -inset or inset)
    t:SetPoint(point.."RIGHT",parent,point.."RIGHT",-inset,point=="TOP" and -inset or inset)
    t:SetHeight(height);t:SetColorTexture(unpack(color));return t
end
function W.Surface(b,style,width)
    b.style=style or "action"
    local s={};b.skin=s
    s.edge=plate(b,"BACKGROUND",0,{.09,.035,.015,1},-7)
    s.rim=plate(b,"BACKGROUND",1,{.48,.30,.13,1},-6)
    s.grain=plate(b,"BACKGROUND",2,nil,-5)
    s.grain:SetTexture(W.media.."Textures\\Register.tga")
    if style=="paper" then s.grain:SetTexCoord(.26,.72,.36,.63)
    else s.grain:SetTexCoord(.24,.75,.915,.963) end
    s.wash=plate(b,"ARTWORK",2,{0,0,0,.12},-2)
    s.light=strip(b,"TOP",2,1,{.98,.76,.43,.32})
    s.shadow=strip(b,"BOTTOM",2,2,{.04,.01,0,.65})
    s.accent=strip(b,"BOTTOM",4,2,{.67,.09,.035,1})
    if style~="paper" and style~="thumb" and width>=100 then
        for x=9,width-9,12 do
            for _,point in ipairs({"TOPLEFT","BOTTOMLEFT"})do
                local stitch=b:CreateTexture(nil,"ARTWORK")
                stitch:SetSize(4,1);stitch:SetPoint(point,b,point,x,point=="TOPLEFT" and -5 or 5)
                stitch:SetColorTexture(.81,.57,.29,.22)
            end
        end
    end
    if style=="paper" then
        s.marker=b:CreateTexture(nil,"ARTWORK")
        s.marker:SetPoint("TOPLEFT",b,"TOPLEFT",0,-2);s.marker:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,2)
        s.marker:SetWidth(3);s.marker:SetColorTexture(unpack(W.red))
    end
    return s
end
function W.Paint(b)
    local s=b.skin;if not s then return end
    local disabled=b.disabledStyle
    local hover=b.hovered and not disabled
    local pressed=b.pressed and not disabled
    local active=b.selected and not disabled
    if b.style=="paper" then
        s.edge:SetColorTexture(.30,.13,.04,hover and .35 or .10)
        s.rim:SetColorTexture(.82,.56,.27,0)
        s.grain:SetAlpha(active and .50 or .15)
        s.wash:SetColorTexture(.40,.07,.02,active and .16 or hover and .08 or .015)
        s.light:SetAlpha(.2);s.shadow:SetAlpha(.12);s.accent:Hide()
        if active then s.marker:Show() else s.marker:Hide() end
        if b.title then b.title:SetTextColor(unpack(active and W.red or W.ink)) end
    else
        local primary=b.style=="primary" or b.style=="close" or active
        s.edge:SetColorTexture(.08,.025,.012,1)
        s.rim:SetColorTexture(hover and .81 or disabled and .32 or .57,hover and .59 or disabled and .23 or .38,hover and .28 or .17,1)
        s.grain:SetAlpha(disabled and .45 or 1)
        if pressed then s.wash:SetColorTexture(.025,.006,.003,.56)
        elseif disabled then s.wash:SetColorTexture(.10,.07,.045,.58)
        elseif primary then s.wash:SetColorTexture(.48,.018,.009,hover and .65 or .46)
        else s.wash:SetColorTexture(hover and .40 or .07,hover and .19 or .035,.012,hover and .30 or .15) end
        s.light:SetAlpha(pressed and .10 or hover and .85 or .45)
        s.shadow:SetAlpha(pressed and .12 or .85)
        if active or hover or b.style=="primary" then s.accent:Show() else s.accent:Hide() end
    end
    if b.label then
        b.label:SetTextColor(unpack(disabled and {.52,.44,.32} or hover and {1,.90,.66} or W.gold))
        b.label:ClearAllPoints();b.label:SetPoint("TOPLEFT",b,"TOPLEFT",12+(pressed and 1 or 0),-2-(pressed and 1 or 0))
    end
    for _,glyph in ipairs(b.glyph or {})do glyph:SetColorTexture(unpack(disabled and {.38,.27,.15,1} or hover and {1,.89,.60,1} or {.87,.65,.32,1})) end
end
function W.SetSelected(b,value)b.selected=value==true;W.Paint(b)end
function W.Skin(b,style,width)
    W.Surface(b,style,width)
    b:SetScript("OnEnter",function(self)self.hovered=true;W.Paint(self)end)
    b:SetScript("OnLeave",function(self)self.hovered=false;self.pressed=false;W.Paint(self)end)
    b:SetScript("OnMouseDown",function(self)self.pressed=true;W.Paint(self)end)
    b:SetScript("OnMouseUp",function(self)self.pressed=false;W.Paint(self)end)
    b:SetScript("OnEnable",function(self)self.disabledStyle=false;W.Paint(self)end)
    b:SetScript("OnDisable",function(self)self.disabledStyle=true;self.pressed=false;W.Paint(self)end)
    W.Paint(b)
end
local function glyph(b,style)
    b.glyph={}
    for i=1,2 do
        local t=b:CreateLine(nil,"OVERLAY");t:SetThickness(2)
        local x1,y1,x2,y2
        if style=="close" then x1,y1,x2,y2=-5,i==1 and -5 or 5,5,i==1 and 5 or -5
        else
            local direction=style=="down" and -1 or 1
            x1,y1,x2,y2=i==1 and -4 or 0,i==1 and -2*direction or 2*direction,i==1 and 0 or 4,i==1 and 2*direction or -2*direction
        end
        t:SetStartPoint("CENTER",b,x1,y1);t:SetEndPoint("CENTER",b,x2,y2);b.glyph[i]=t
    end
end
function W.Button(parent, text, x, y, width, height, action, selected, style)
    local b = W.Frame(parent, x, y, width, height, "Button")
    W.Skin(b,style or "action",width)
    if style=="up" or style=="down" or style=="close" then glyph(b,style)
    else
        b.label=W.Text(b,text,12,2,math.max(1,width-24),14,W.gold,false,height-4)
        b.label:SetJustifyH("CENTER");b.label:SetJustifyV("MIDDLE");b.label:SetWordWrap(false)
    end
    b.selected=selected==true;W.Paint(b);b:SetScript("OnClick",action)
    return b
end
function W.Scroll(parent, x, y, width, height)
    local scroll = W.Frame(parent, x, y, width-24, height, "ScrollFrame")
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width-24,height); scroll:SetScrollChild(child)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 48)))
    end)
    local up=W.Button(parent, "", x+width-20,y,20,22,function()
        scroll:SetVerticalScroll(math.max(0, scroll:GetVerticalScroll() - 160))
    end,false,"up")
    local down=W.Button(parent, "", x+width-20,y+height-22,20,22,function()
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScrollRange(), scroll:GetVerticalScroll() + 160))
    end,false,"down")
    local slider=W.Frame(parent,x+width-20,y+25,20,height-50,"Slider")
    slider:SetOrientation("VERTICAL");slider:SetValueStep(1);slider:SetObeyStepOnDrag(false)
    W.Fill(slider,{.19,.075,.025,.24})
    local rail=slider:CreateTexture(nil,"BACKGROUND")
    rail:SetPoint("TOP",slider,"TOP",0,0);rail:SetPoint("BOTTOM",slider,"BOTTOM",0,0)
    rail:SetWidth(6);rail:SetColorTexture(.14,.055,.025,.70)
    local thumb=slider:CreateTexture(nil,"ARTWORK")
    thumb:SetSize(18,32);thumb:SetColorTexture(.55,.30,.10,1);slider:SetThumbTexture(thumb)
    local grip=CreateFrame("Frame",nil,slider);grip:SetAllPoints(thumb);grip:EnableMouse(false)
    W.Surface(grip,"thumb",18);W.Paint(grip)
    for i=-1,1 do
        local line=grip:CreateTexture(nil,"OVERLAY");line:SetSize(8,1);line:SetPoint("CENTER",grip,"CENTER",0,i*4)
        line:SetColorTexture(.82,.56,.26,.75)
    end
    local syncing=false
    local function update()
        if syncing then return end
        syncing=true
        local range=math.max(0,scroll:GetVerticalScrollRange())
        local value=math.max(0,math.min(range,scroll:GetVerticalScroll()))
        if value~=scroll:GetVerticalScroll() then scroll:SetVerticalScroll(value) end
        slider:SetMinMaxValues(0,math.max(1,range));slider:SetValue(value)
        thumb:SetHeight(math.max(28,math.min(height-50,(height-50)*height/(height+range))))
        slider:SetEnabled(range>0)
        if range>0 then thumb:Show();grip:Show() else thumb:Hide();grip:Hide() end
        grip.disabledStyle=range<=0;W.Paint(grip)
        if value<=0 then up:Disable() else up:Enable() end
        if value>=range then down:Disable() else down:Enable() end
        syncing=false
    end
    slider:SetScript("OnValueChanged",function(_,value)
        if not syncing then scroll:SetVerticalScroll(math.max(0,math.min(scroll:GetVerticalScrollRange(),value)));update() end
    end)
    slider:SetScript("OnEnter",function()grip.hovered=true;W.Paint(grip)end)
    slider:SetScript("OnLeave",function()grip.hovered=false;W.Paint(grip)end)
    scroll:SetScript("OnVerticalScroll",update)
    scroll:SetScript("OnScrollRangeChanged",update)
    child:SetScript("OnSizeChanged",update)
    scroll.UpdateBar=update;scroll.slider=slider;scroll.up=up;scroll.down=down;scroll.thumb=thumb
    update()
    return child, scroll
end
function W.Rule(parent, x, y, width)
    return W.Fill(W.Frame(parent, x, y, width, 1), {0.33, 0.13, 0.035, 0.45})
end
