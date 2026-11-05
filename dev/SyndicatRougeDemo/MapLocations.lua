local _, demo = ...
-- Resolve only these fictional fixtures by localized names, never guess a real incident's map.
local names = {
    ["Strangleronce"] = {"Strangleronce", "Vallée de Strangleronce", "Stranglethorn Vale"},
    ["Bois de la Pénombre"] = {"Bois de la Pénombre", "Duskwood"},
    ["Les Paluns"] = {"Les Paluns", "Wetlands"},
    ["Hautes-terres d’Arathi"] = {"Hautes-terres d’Arathi", "Hautes-terres Arathi", "Arathi Highlands"},
}
local function matches(name, zone)
    for _, alias in ipairs(names[zone] or {zone}) do if name == alias then return true end end
    return false
end
function demo.MapLocations(incidents)
    local maps, seen, queue = {}, {}, {}
    local function add(info)
        if info and info.mapID and not seen[info.mapID] then
            seen[info.mapID] = true; maps[#maps+1] = info; queue[#queue+1] = info.mapID
        end
    end
    if C_Map then
        local root = C_Map.GetFallbackWorldMapID and C_Map.GetFallbackWorldMapID()
        if root then queue[#queue+1] = root end
        local current = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        for _ = 1, 16 do
            if not current or not C_Map.GetMapInfo then break end
            local info = C_Map.GetMapInfo(current); if not info then break end
            add(info)
            if not info.parentMapID or info.parentMapID == 0 or info.parentMapID == current then break end
            current = info.parentMapID
        end
        if root and C_Map.GetMapChildrenInfo then
            for _, info in ipairs(C_Map.GetMapChildrenInfo(root, nil, true) or {}) do add(info) end
        end
        local index, expanded = 1, {}
        while C_Map.GetMapChildrenInfo and index <= #queue and index <= 2048 do
            local id = queue[index]; index = index + 1
            if not expanded[id] then
                expanded[id] = true
                for _, info in ipairs(C_Map.GetMapChildrenInfo(id, nil, false) or {}) do add(info) end
            end
        end
    end
    for _, incident in ipairs(incidents) do
        local location = incident.location
        local zone = location.zone:match("^(.-)%s*·") or location.zone
        local candidate = C_Map and C_Map.GetMapInfo and location.mapId and C_Map.GetMapInfo(location.mapId)
        local found = candidate and matches(candidate.name, zone) and candidate.mapID or nil
        if not found then
            for _, info in ipairs(maps) do
                if matches(info.name, zone) then
                    if found and found ~= info.mapID then found = nil; break end
                    found = info.mapID
                end
            end
        end
        location.mapId = found
        if not found then location.x = nil; location.y = nil end
    end
    return incidents
end
