local _, ns = ...
local V = {}
ns.Validation = V

function V.String(value, limit)
    return type(value) == "string" and #value > 0 and #value <= (limit or 120)
        and not value:find("[%z\1-\31\127]")
end
function V.Integer(value, minimum, maximum)
    return type(value) == "number" and value == value and value ~= math.huge
        and value ~= -math.huge and value % 1 == 0
        and value >= (minimum or 0) and value <= (maximum or 9007199254740991)
end
function V.Actor(value)
    if type(value) ~= "table" or not V.String(value.id) or not V.String(value.name, 80)
        or not V.String(value.realm, 80) then return nil end
    if value.level ~= nil and not V.Integer(value.level, 1, 100) then return nil end
    if value.race ~= nil and not V.String(value.race, 40) then return nil end
    if value.class ~= nil and not V.String(value.class, 40) then return nil end
    return { id = value.id, name = value.name, realm = value.realm,
        race = value.race, class = value.class, level = value.level }
end
function V.Location(value)
    if type(value) ~= "table" or not V.String(value.zone, 160) then return nil end
    if value.mapId ~= nil and not V.Integer(value.mapId, 1) then return nil end
    if (value.x == nil) ~= (value.y == nil) then return nil end
    for _, key in ipairs({"x", "y"}) do
        local coordinate = value[key]
        if coordinate ~= nil and (type(coordinate) ~= "number" or coordinate ~= coordinate
            or coordinate < 0 or coordinate > 1) then return nil end
    end
    if value.x ~= nil and value.mapId == nil then return nil end
    return { zone = value.zone, mapId = value.mapId, x = value.x, y = value.y }
end
function V.Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = V.Copy(item) end
    return result
end
function V.Same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, item in pairs(a) do if not V.Same(item, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
function V.Count(items)
    local total = 0
    for _ in pairs(items) do total = total + 1 end
    return total
end
function V.Newest(a, b)
    if a.occurredAt ~= b.occurredAt then return a.occurredAt > b.occurredAt end
    return a.id < b.id
end
