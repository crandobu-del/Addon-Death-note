local _, ns = ...
local Maps, W = {}, ns.UI.Widgets
ns.UI.Maps = Maps

function Maps.Create(parent)
    local map = W.Frame(parent, 14, 250, 360, 180)
    W.Fill(map, {0.19, 0.10, 0.04, 0.3})
    map.tiles = {}
    map.message = W.Text(map, "", 12, 65, 336, 14, W.ink, false, 70)
    map.pin = W.Frame(map, 0, 0, 16, 16)
    W.Fill(map.pin, {0.65, 0.025, 0.015, 1})
    W.Fill(W.Frame(map.pin, 5, 5, 6, 6), {1, 0.84, 0.46, 1})
    map.pin:Hide()
    return map
end

function Maps.Clear(map)
    for _, tile in ipairs(map.tiles) do tile:Hide() end
    map.pin:Hide(); map.message:Hide()
end

function Maps.Display(map, location)
    Maps.Clear(map); map:Show()
    local function unavailable(message)
        map.message:SetText(message); map.message:Show()
        return false
    end
    if not C_Map or type(C_Map.GetMapInfo) ~= "function" or type(C_Map.GetMapArtLayers) ~= "function"
        or type(C_Map.GetMapArtLayerTextures) ~= "function" then
        return unavailable("Carte du jeu indisponible.")
    end
    if not location or not ns.Validation.Integer(location.mapId, 1) then
        return unavailable("Zone connue uniquement.\nCarte non identifiée.")
    end
    local info = C_Map.GetMapInfo(location.mapId)
    if not info then return unavailable("Carte inconnue de ce client.") end
    local layers = C_Map.GetMapArtLayers(location.mapId)
    local layer = layers and layers[1]
    if not layer or not layer.layerWidth or not layer.layerHeight or not layer.tileWidth or not layer.tileHeight
        or layer.layerWidth <= 0 or layer.layerHeight <= 0 or layer.tileWidth <= 0 or layer.tileHeight <= 0 then
        return unavailable("Fond de carte indisponible.")
    end
    local columns, rows = math.ceil(layer.layerWidth / layer.tileWidth), math.ceil(layer.layerHeight / layer.tileHeight)
    if columns * rows > 64 then return unavailable("Fond de carte trop détaillé pour cet encart.") end
    local textures = C_Map.GetMapArtLayerTextures(location.mapId, 1)
    if not textures then return unavailable("Textures de carte indisponibles.") end
    for i = 1, columns * rows do
        if not textures[i] then return unavailable("Textures de carte incomplètes.") end
    end
    local scale = math.min(360 / layer.layerWidth, 180 / layer.layerHeight)
    local width, height = layer.layerWidth * scale, layer.layerHeight * scale
    local left, top = (360 - width) / 2, (180 - height) / 2
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local index = row * columns + column + 1
            local tile = map.tiles[index]
            if not tile then tile = map:CreateTexture(nil, "ARTWORK"); map.tiles[index] = tile end
            local w = math.min(layer.tileWidth, layer.layerWidth - column * layer.tileWidth)
            local h = math.min(layer.tileHeight, layer.layerHeight - row * layer.tileHeight)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", map, "TOPLEFT", left + column * layer.tileWidth * scale, -top - row * layer.tileHeight * scale)
            tile:SetSize(w * scale, h * scale)
            tile:SetTexCoord(0, w / layer.tileWidth, 0, h / layer.tileHeight)
            tile:SetTexture(textures[index]); tile:Show()
        end
    end
    local x, y = location.x, location.y
    if type(x) == "number" and type(y) == "number" and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
        map.pin:ClearAllPoints()
        map.pin:SetPoint("CENTER", map, "TOPLEFT", left + x * width, -top - y * height)
        map.pin:Show()
    end
    return true, map.pin:IsShown(), info.name
end
