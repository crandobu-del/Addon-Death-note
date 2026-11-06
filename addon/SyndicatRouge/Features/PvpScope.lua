local _, ns = ...
local S = {}; ns.PvpScope = S
local allowed = {none=true, party=true, raid=true, scenario=true}

-- Records are validated independently of the receiving player's location.
-- Legacy records have no scope; retain them rather than guessing their origin.
function S.Validate(value)
    if value == nil then return true end
    if value == "pvp" or value == "arena" then return false, "pvp_instance_excluded" end
    if not allowed[value] then return false, "instance_context_unavailable" end
    return true
end

function S.Current()
    if type(IsInInstance) ~= "function" or type(issecretvalue) ~= "function" then
        return nil, "instance_context_unavailable"
    end
    local ok, inside, kind = pcall(IsInInstance)
    if not ok then return nil, "instance_context_unavailable" end
    for _, value in ipairs({inside, kind}) do
        local checked, secret = pcall(issecretvalue, value)
        if not checked or secret then return nil, "instance_context_unavailable" end
    end
    if type(inside) ~= "boolean" or type(kind) ~= "string" then return nil, "instance_context_unavailable" end
    local valid, reason = S.Validate(kind)
    if not valid then return nil, reason end
    if (kind == "none") ~= (inside == false) then return nil, "instance_context_unavailable" end
    return kind
end

-- Call at local event ingestion, before storing or sharing an incident/claim.
function S.Prepare(input)
    local kind, reason = S.Current()
    if not kind then return nil, reason end
    if type(input) ~= "table" then return nil, "invalid_event" end
    local valid; valid, reason = S.Validate(input.instanceType)
    if not valid then return nil, reason end
    local record = ns.Validation.Copy(input)
    record.instanceType = kind
    return record
end
