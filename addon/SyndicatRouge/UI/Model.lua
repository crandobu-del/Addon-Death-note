local _, ns = ...
ns.UI = ns.UI or {}
local M = {}
ns.UI.Model = M

function M.Text(value)
    return (tostring(value or ""):gsub("|", "||"))
end
function M.Filter(rows, query, name)
    local result = {}
    query = string.lower(query or "")
    for _, row in ipairs(rows or {}) do
        if string.find(string.lower(name(row)), query, 1, true) then result[#result + 1] = row end
    end
    return result
end
function M.Selected(rows, id, key)
    for _, row in ipairs(rows) do if key(row) == id then return row end end
    return rows[1]
end
function M.Date(timestamp)
    if type(date) == "function" then return date("%d/%m/%Y  %H:%M", timestamp) end
    return tostring(timestamp)
end
function M.Actor(actor)
    return (actor.race or "Race inconnue") .. " · " .. (actor.class or "Classe inconnue")
        .. " · Niv. " .. tostring(actor.level or "?")
end
