-- Minimal widget/event contract double, NOT an emulator or visual proof.
SR_TEST_FRAMES = {}
SlashCmdList = {}; UISpecialFrames = {}
RegionalUniqueNamesEnabled = function() return false end
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
function methods:CreateLine()return new("Line",nil,self)end
function methods:SetStartPoint(...)self.startPoint={...}end
function methods:SetEndPoint(...)self.endPoint={...}end
function methods:SetThickness(value)self.thickness=value end
function methods:CreateFontString() return new("FontString",nil,self) end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:RegisterEvent(name) self.event=name;self.events=self.events or {};self.events[name]=true;return true end
function methods:UnregisterEvent(name) if self.events then self.events[name]=nil end;if self.event==name then self.event=nil end end
function methods:SetText(text)
    self.text=text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return self.text end
function methods:Show() self.shown=true end
function methods:Hide() local shown=self.shown;self.shown=false;if shown and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
function methods:IsVisible()return self.shown and (not self.parent or self.parent:IsVisible())end
function methods:IsForbidden()return self.forbidden==true end
function methods:IsProtected()return self.protected==true end
function methods:GetUnit()return self.unitToken end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(self.point or {}) end
function methods:SetTexture(texture) self.texture=texture end
function methods:IsObjectLoaded() return SR_TEST_TEXTURES_READY~=false end
function methods:SetAtlas(name,useAtlasSize) assert(type(useAtlasSize)=="boolean"); self.atlas=name end
function methods:SetTexCoord(...) self.uv={...} end
function methods:SetHeight(h) self.height=h end
function methods:SetWidth(w)self.width=w end
function methods:GetWidth()return self.width or 0 end
function methods:GetHeight()return self.height or 0 end
function methods:SetAlpha(value)self.alpha=value end
function methods:SetRotation(value)self.rotation=value end
function methods:SetOrientation(value)self.orientation=value end
function methods:SetValueStep(value)self.step=value end
function methods:SetObeyStepOnDrag(value)self.obeyStep=value end
function methods:SetMinMaxValues(lo,hi)self.minimum=lo;self.maximum=hi end
function methods:SetThumbTexture(value)self.thumbTexture=value end
function methods:SetValue(value)
    self.value=value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
end
function methods:SetEnabled(value)if value then self:Enable()else self:Disable()end end
function methods:SetScrollChild(child) self.child=child end
function methods:UpdateScrollChildRect()end
function methods:SetVerticalScroll(value)
    self.scroll=value
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self,value)end
end
function methods:GetVerticalScroll() return self.scroll end
function methods:GetVerticalScrollRange() return math.max(0,(self.child and self.child.height or 0)-self.height) end
function methods:Enable() self.disabled=false;if self.scripts.OnEnable then self.scripts.OnEnable(self)end end
function methods:Disable() self.disabled=true;if self.scripts.OnDisable then self.scripts.OnDisable(self)end end
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
Minimap = new("Minimap","Minimap",UIParent)
Enum={UIMapType={Zone=3}}
C_Map = {
    GetMapInfo=function(id) if id==101 then return {mapID=id,name="Strangleronce"} end end,
    GetFallbackWorldMapID=function() return 1 end,
    GetMapChildrenInfo=function() return {{mapID=101,name="Strangleronce"}} end,
    GetMapArtLayers=function() return {{layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}} end,
    GetMapArtLayerTextures=function() return {11,12,13,14,15,16,17,18,19,20,21,22} end,
}
C_Texture={GetAtlasInfo=function(name)
    if name=="raceicon128-orc-male" or name=="raceicon128-orc-female" or name=="classicon-warrior" then return {} end
end}
C_CreatureInfo={
    GetRaceInfo=function(id) if id==2 then return {clientFileString="Orc",raceID=2} end end,
    GetClassInfo=function(id) if id==1 then return {classFile="WARRIOR",classID=1} end end,
}
