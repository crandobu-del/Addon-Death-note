local ns=...
local A,C=ns.MapAudit,ns.MapCatalog
local passed=0
local function check(ok,message)assert(ok,message);passed=passed+1 end
local original=C_Map
local nodes={
    [100]={mapID=100,name="World",mapType=1,parentMapID=0},
    [200]={mapID=200,name="Continent",mapType=2,parentMapID=100},
    [201]={mapID=201,name="Zone A",mapType=3,parentMapID=200},
    [202]={mapID=202,name="Zone B",mapType=3,parentMapID=200},
    [203]={mapID=203,name="Dungeon",mapType=4,parentMapID=200},
}
C_Map={
    GetFallbackWorldMapID=function()return 100 end,
    GetBestMapForUnit=function()return 201 end,
    GetMapInfo=function(id)return nodes[id]end,
    GetMapChildrenInfo=function(id,_,all)
        if id==100 then return all and {nodes[200],nodes[201],nodes[202],nodes[203]} or {nodes[200]} end
        if id==200 then return {nodes[201],nodes[202],nodes[203]} end
        return {}
    end,
    GetMapArtLayers=original.GetMapArtLayers,
    GetMapArtLayerTextures=function(id,layer)if id~=202 then return original.GetMapArtLayerTextures(id,layer)end end,
}
local catalog=C.Collect()
check(#catalog.maps==2,"catalog covers all discovered zones and excludes continents/dungeons")
check(#catalog.roots==1 and catalog.roots[1]==100,"roots are deduplicated")
check(not catalog.truncated and #catalog.errors==0,"discovery records clean completion")
check(catalog.maps[1].technical=="pending" and catalog.maps[1].visual=="not_checked","discovery alone never marks a map passed")
A.Start()
for i=1,30 do A.Tick(0.2) end
check(A.report.completed and not A.running,"automatic run terminates")
check(A.report.maps[1].technical=="textures_loaded","loaded native textures recorded")
check(A.report.maps[2].technical=="map_unavailable","bad map is retained as failure")
check(A.Count(A.report).visual==0,"automatic loading never claims visual validation")
A.ShowIndex(1);A.Mark("passed")
check(A.report.maps[1].visual=="passed" and A.Count(A.report).visual==1,"visual validation requires explicit action")
check(SyndicatRougeMapAudit==A.report,"local report is persisted separately from guild data")
A.Start();A.Tick(0.2);A.Stop()
check(not A.report.completed and A.report.interrupted,"interrupted audit is not complete")
local preview=A.window.preview
SR_TEST_TEXTURES_READY=false
check(A.Readiness(preview)=="waiting","not-yet-loaded texture never passes")
SR_TEST_TEXTURES_READY=true
A.Start()
SR_TEST_TEXTURES_READY=false
for i=1,30 do A.Tick(0.25) end
check(A.report.completed and A.report.maps[1].technical=="texture_timeout","unloaded textures time out instead of passing")
SR_TEST_TEXTURES_READY=true
check(A.report.maps[2].technical=="map_unavailable","one timeout does not prevent remaining maps from being checked")
local savedDisplay=SyndicatRouge.MapPreview.Display
SyndicatRouge.MapPreview.Display=function()error("renderer failure")end
A.Start()
for i=1,10 do A.Tick(0.2) end
check(A.report.completed and A.report.maps[1].technical=="render_error","renderer failures are isolated per map")
SyndicatRouge.MapPreview.Display=savedDisplay
local children=C_Map.GetMapChildrenInfo
C_Map.GetMapChildrenInfo=function()error("unavailable")end
check(#C.Collect().errors>0,"discovery errors remain visible")
C_Map.GetMapChildrenInfo=children
C_Map.GetMapInfo=function(id)return {mapID=id,name="cycle",mapType=1,parentMapID=id}end
check(#C.Collect().errors>0,"parent cycles do not loop indefinitely")
C_Map=nil
check(C.Collect().errors[1]=="map_api_unavailable","missing API is explicit")
C_Map=original
return {passed=passed}
