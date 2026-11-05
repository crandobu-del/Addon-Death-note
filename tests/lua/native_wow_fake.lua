-- Minimal widget/event contract double, NOT an emulator or visual proof.
SR_TEST_FRAMES = {}
SlashCmdList = {}; UISpecialFrames = {}
unpack = table.unpack or unpack
local methods = {}
local function new(kind, name, parent)
    local f = setmetatable({kind=kind,name=name,parent=parent,scripts={},shown=true,text="",height=0,scroll=0}, {__index=methods})
    SR_TEST_FRAMES[#SR_TEST_FRAMES+1]=f
    if name then _G[name]=f end
    return f
end
function CreateFrame(kind,name,parent) return new(kind,name,parent) end
function methods:CreateTexture() return new("Texture",nil,self) end
function methods:CreateFontString() return new("FontString",nil,self) end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:RegisterEvent(name) self.event=name end
function methods:UnregisterEvent() self.event=nil end
function methods:SetText(text)
    self.text=text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return self.text end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetHeight(h) self.height=h end
function methods:SetScrollChild(child) self.child=child end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:GetVerticalScroll() return self.scroll end
function methods:GetVerticalScrollRange() return math.max(0,(self.child and self.child.height or 0)-self.height) end
function methods:Enable() self.disabled=false end
function methods:Disable() self.disabled=true end
for _,method in ipairs({"SetPoint","SetAllPoints","ClearAllPoints","SetFont","SetTextColor","SetJustifyH","SetJustifyV","SetWordWrap","SetTexture","SetTexCoord","SetColorTexture","EnableMouseWheel","EnableMouse","SetFrameStrata","SetClampedToScreen","SetMovable","RegisterForDrag","StartMoving","StopMovingOrSizing","SetAutoFocus","SetMaxLetters","ClearFocus"}) do
    methods[method]=function() end
end
UIParent = new("Frame","UIParent")
