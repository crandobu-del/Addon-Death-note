local ns = ...
local Maps = ns.UI.Maps
local passed=0
local function check(value,message) assert(value,message); passed=passed+1 end
local map=Maps.Create(UIParent)
local location={mapId=101,x=0.32,y=0.29}
local ok,marked=Maps.Display(map,location)
check(ok and marked,"real map uses recorded normalized coordinates")
check(#map.tiles==12 and map.tiles[5].texture==15,"tiles use row-major order")
check(map.tiles[4].uv[2]==234/256 and map.tiles[12].uv[4]==156/256,"edge tiles crop padding")
check(math.abs(map.tiles[1].width/map.tiles[1].height-1)<0.001,"map preserves aspect ratio")
check(math.abs(map.pin.point[4]-(45+270*0.32))<0.001 and math.abs(map.pin.point[5]+180*0.29)<0.001,"pin shares exact map transform")
local count=#SR_TEST_FRAMES
Maps.Display(map,location)
check(#SR_TEST_FRAMES==count,"map refresh reuses native textures")
ok,marked=Maps.Display(map,{mapId=101})
check(ok and not marked,"zone without coordinates never gets a fake pin")
ok=Maps.Display(map,{mapId=999})
check(not ok and not map.tiles[1]:IsShown() and not map.pin:IsShown(),"unknown map clears old art and marker")
check(not Maps.Display(map,{zone="Unmapped"}),"missing map identity is explicit")
local old=C_Map;C_Map=nil
check(not Maps.Display(map,location),"missing C_Map is handled without crashing")
C_Map=old
local textures=C_Map.GetMapArtLayerTextures
C_Map.GetMapArtLayerTextures=function() return {11} end
check(not Maps.Display(map,location) and not map.tiles[1]:IsShown(),"incomplete textures never reuse previous map")
C_Map.GetMapArtLayerTextures=textures
local source={{location={zone="Strangleronce · Grom’gol",mapId=1434,x=0.32,y=0.29}},{location={zone="Unknown",mapId=1434,x=0.5,y=0.5}}}
ns.MapLocations(source)
check(source[1].location.mapId==101,"demo resolves client map rather than historical guessed ID")
check(source[2].location.mapId==nil and source[2].location.x==nil,"unresolved demo map clears incompatible coordinates")
local children=C_Map.GetMapChildrenInfo
C_Map.GetMapChildrenInfo=function()return {{mapID=101,name="Strangleronce"},{mapID=102,name="Strangleronce"}}end
source[1].location.mapId=nil
ns.MapLocations(source)
check(source[1].location.mapId==nil,"ambiguous zone names never select a guessed map")
C_Map.GetMapChildrenInfo=children
local getInfo, getBest=C_Map.GetMapInfo,C_Map.GetBestMapForUnit
C_Map.GetBestMapForUnit=function()return 500 end
C_Map.GetMapInfo=function(id)
    if id==500 then return {mapID=500,name="Elwynn",parentMapID=501} end
    if id==501 then return {mapID=501,name="World",parentMapID=0} end
end
C_Map.GetMapChildrenInfo=function(id,_,all)
    if id==501 and not all then return {{mapID=502,name="Vallée de Strangleronce"}} end
    return {}
end
local nested={{location={zone="Strangleronce · Grom’gol"}}}
ns.MapLocations(nested)
check(nested[1].location.mapId==502,"demo finds localized alias through player's world and direct descendants")
C_Map.GetMapInfo=getInfo;C_Map.GetBestMapForUnit=getBest;C_Map.GetMapChildrenInfo=children
return {passed=passed}
