local _, demo = ...
demo.MapCatalog = {}

function demo.MapCatalog.Collect()
    local report = { roots = {}, maps = {}, errors = {}, truncated = false }
    if not C_Map or not C_Map.GetMapInfo or not C_Map.GetMapChildrenInfo or not C_Map.GetFallbackWorldMapID then
        report.errors[1] = "map_api_unavailable"; return report
    end
    local queue, queued, zones, roots = {}, {}, {}, {}
    local function enqueue(id)
        if type(id) == "number" and id > 0 and not queued[id] then
            queued[id] = true; queue[#queue+1] = id
        end
    end
    local function rootFrom(id)
        local chain = {}
        for _ = 1, 32 do
            if not id or id <= 0 then return end
            if chain[id] then report.errors[#report.errors+1] = "parent_cycle"; return end
            chain[id] = true; enqueue(id)
            local ok, info = pcall(C_Map.GetMapInfo, id)
            if not ok then report.errors[#report.errors+1] = "map_info_failed"; return end
            if not info then report.errors[#report.errors+1] = "root_info_missing"; return end
            if not info.parentMapID or info.parentMapID == 0 then
                if not roots[id] then roots[id] = true; report.roots[#report.roots+1] = id end
                return
            end
            id = info.parentMapID
        end
        report.truncated = true
    end
    local ok, fallback = pcall(C_Map.GetFallbackWorldMapID)
    if ok then rootFrom(fallback) else report.errors[#report.errors+1] = "fallback_failed" end
    if C_Map.GetBestMapForUnit then
        local success, current = pcall(C_Map.GetBestMapForUnit, "player")
        if success and current then rootFrom(current) end
    end
    local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone
    if not zoneType then report.errors[#report.errors+1] = "zone_enum_unavailable"; return report end
    local function consider(info)
        if not info or not info.mapID then return end
        enqueue(info.mapID)
        if info.mapType == zoneType and not zones[info.mapID] then
            zones[info.mapID] = true
            report.maps[#report.maps+1] = { mapID = info.mapID, name = info.name, technical = "pending", visual = "not_checked" }
        end
    end
    local index = 1
    while index <= #queue and index <= 4096 do
        local id = queue[index]; index = index + 1
        local valid, info = pcall(C_Map.GetMapInfo, id)
        if valid then consider(info) else report.errors[#report.errors+1] = "map_info_failed" end
        -- Recursive results supplement direct children on clients with special map hierarchies.
        for _, descendants in ipairs(roots[id] and {false, true} or {false}) do
            local success, children = pcall(C_Map.GetMapChildrenInfo, id, nil, descendants)
            if success then
                for _, child in ipairs(children or {}) do consider(child) end
            else report.errors[#report.errors+1] = "map_children_failed" end
        end
    end
    if index <= #queue then report.truncated = true end
    report.visited = index - 1
    table.sort(report.roots)
    table.sort(report.maps, function(a,b) if a.name ~= b.name then return a.name < b.name end return a.mapID < b.mapID end)
    return report
end
