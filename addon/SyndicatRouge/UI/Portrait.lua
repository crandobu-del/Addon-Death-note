local _, ns = ...
local P, W = {}, ns.UI.Widgets
ns.UI.Portraits = P

function P.Create(parent)
    local frame = W.Frame(parent, 14, 92, 100, 100)
    frame.race = frame:CreateTexture(nil, "ARTWORK")
    frame.race:SetAllPoints(frame)
    frame.class = frame:CreateTexture(nil, "OVERLAY")
    frame.class:SetSize(34, 34); frame.class:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.unknown = W.Text(frame, "Image\ninconnue", 5, 25, 90, 14, W.ink, false, 65)
    return frame
end

local function atlas(texture, name)
    if not C_Texture or type(C_Texture.GetAtlasInfo) ~= "function" or not C_Texture.GetAtlasInfo(name) then return false end
    texture:SetTexCoord(0, 1, 0, 1)
    texture:SetAtlas(name, false); texture:Show()
    return true
end

function P.Display(frame, actor)
    frame.race:Hide(); frame.class:Hide(); frame.unknown:Hide(); frame:Show()
    local race, class
    if C_CreatureInfo then
        if actor.raceID and C_CreatureInfo.GetRaceInfo then race = C_CreatureInfo.GetRaceInfo(actor.raceID) end
        if actor.classID and C_CreatureInfo.GetClassInfo then class = C_CreatureInfo.GetClassInfo(actor.classID) end
    end
    local raceShown = false
    if race and actor.sex then
        local token = string.lower(race.clientFileString)
        for _, prefix in ipairs({"raceicon128-", "raceicon-"}) do
            if atlas(frame.race, prefix .. token .. "-" .. actor.sex) then raceShown = true; break end
        end
    end
    frame.class:ClearAllPoints()
    if raceShown then
        frame.class:SetSize(34, 34); frame.class:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    else frame.class:SetSize(100, 100); frame.class:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0) end
    local classShown = class and atlas(frame.class, "classicon-" .. string.lower(class.classFile)) or false
    if not classShown and class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class.classFile] then
        frame.class:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        frame.class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class.classFile])); frame.class:Show(); classShown = true
    end
    if not raceShown and not classShown then frame.unknown:Show() end
    return raceShown, classShown
end
