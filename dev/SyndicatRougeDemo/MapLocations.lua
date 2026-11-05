local _, demo = ...
-- Resolve only these fictional fixtures by localized names, never guess a real incident's map.
local english = {
    ["Strangleronce"] = "Stranglethorn Vale", ["Bois de la Pénombre"] = "Duskwood",
    ["Les Paluns"] = "Wetlands", ["Hautes-terres d’Arathi"] = "Arathi Highlands",
}
function demo.MapLocations(incidents)
    local maps = {}
    if C_Map and C_Map.GetFallbackWorldMapID and C_Map.GetMapChildrenInfo then
        maps = C_Map.GetMapChildrenInfo(C_Map.GetFallbackWorldMapID(), nil, true) or {}
    end
    for _, incident in ipairs(incidents) do
        local location = incident.location
        local zone = location.zone:match("^(.-)%s*·") or location.zone
        location.mapId = nil
        local found
        for _, info in ipairs(maps) do
            if info.name == zone or info.name == english[zone] then
                if found and found ~= info.mapID then found = nil; break end
                found = info.mapID
            end
        end
        location.mapId = found
        if not found then location.x = nil; location.y = nil end
    end
    return incidents
end
