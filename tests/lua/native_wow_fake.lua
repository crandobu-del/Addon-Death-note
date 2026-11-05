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
function methods:SetPoint(...) self.point={...} end
function methods:SetTexture(texture) self.texture=texture end
function methods:SetTexCoord(...) self.uv={...} end
function methods:SetHeight(h) self.height=h end
function methods:SetScrollChild(child) self.child=child end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:GetVerticalScroll() return self.scroll end
function methods:GetVerticalScrollRange() return math.max(0,(self.child and self.child.height or 0)-self.height) end
function methods:Enable() self.disabled=false end
function methods:Disable() self.disabled=true end
function methods:SetFont(fontFile, height, flags)
    assert(type(fontFile)=="string" and type(height)=="number", "invalid font arguments")
    if self.kind=="EditBox" then assert(type(flags)=="string", "EditBox:SetFont requires flags (Forever runtime)") end
    self.font = {file=fontFile,height=height,flags=flags}
    return true
end
for _,method in ipairs({"SetAllPoints","ClearAllPoints","SetTextColor","SetJustifyH","SetJustifyV","SetWordWrap","SetColorTexture","EnableMouseWheel","EnableMouse","SetFrameStrata","SetClampedToScreen","SetMovable","RegisterForDrag","StartMoving","StopMovingOrSizing","SetAutoFocus","SetMaxLetters","ClearFocus"}) do
    methods[method]=function() end
end
UIParent = new("Frame","UIParent")
C_Map = {
    GetMapInfo=function(id) if id==101 then return {mapID=id,name="Strangleronce"} end end,
    GetFallbackWorldMapID=function() return 1 end,
    GetMapChildrenInfo=function() return {{mapID=101,name="Strangleronce"}} end,
    GetMapArtLayers=function() return {{layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}} end,
    GetMapArtLayerTextures=function() return {11,12,13,14,15,16,17,18,19,20,21,22} end,
}
