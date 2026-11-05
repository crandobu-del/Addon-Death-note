local _, ns = ...
local UI, W, M = ns.UI, ns.UI.Widgets, ns.UI.Model
local function set(label, text) label:SetText(M.Text(text)) end
local function rowAt(panel, index)
    local row = panel.rows[index]
    if not row then
        row = W.Frame(panel.list, 0, (index - 1) * 76, 300, 72, "Button")
        row.fill = W.Fill(row, {0.38, 0.14, 0.04, 0.12})
        row.title = W.Text(row, "", 12, 9, 276, 21, W.ink, true, 28)
        row.sub = W.Text(row, "", 12, 40, 276, 12, W.ink, false, 26)
        row:SetScript("OnClick", function()
            UI.window.selection[UI.window.tab] = row.key; UI.Refresh()
        end)
        panel.rows[index] = row
    end
    row:Show(); return row
end
local function detailLine(panel, index, text, color)
    local label = panel.lines[index]
    if not label then label = W.Text(panel.detail, "", 14, 244 + (index - 1) * 40, 600, 14, color, false, 38); panel.lines[index] = label end
    label:SetTextColor(unpack(color or W.ink)); set(label, text); label:Show()
end
local function makePanel(f)
    local p = W.Frame(f.content, 0, 0, 996, 450)
    p.list, p.listScroll = W.Scroll(p, 0, 0, 325, 445)
    W.Rule(p, 340, 0, 1)
    W.Fill(W.Frame(p, 340, 0, 1, 445), {0.33, 0.13, 0.035, 0.5})
    p.detail, p.detailScroll = W.Scroll(p, 357, 0, 639, 445)
    p.rows, p.lines = {}, {}
    p.title = W.Text(p.detail, "", 14, 6, 600, 34, W.red, true, 45)
    p.meta = W.Text(p.detail, "", 14, 54, 590, 14)
    p.portrait = UI.Portraits.Create(p.detail)
    p.summary = W.Text(p.detail, "", 170, 94, 430, 23, W.red, true, 95)
    p.status = W.Text(p.detail, "", 170, 170, 430, 20, W.red, false, 28)
    p.map = UI.Maps.Create(p.detail)
    p.mapNote = W.Text(p.detail, "", 390, 260, 190, 14, W.red, false, 170)
    p.read = W.Button(p.detail, "Marquer comme lu", 14, 150, 205, 38, function()
        if p.current then UI.provider:Read(p.current.id); UI.Refresh() end
    end)
    p.thank = W.Button(p.detail, "Remercier", 235, 150, 205, 38, function()
        if p.current then UI.provider:Thank(p.current.id); UI.Refresh() end
    end)
    return p
end
local key = function(row) return row.id or row.enemy and row.enemy.id or row.member.id end
local function searchable(row)
    if row.incident then return row.incident.enemy.name .. " " .. row.incident.victim.name .. " " .. row.incident.location.zone end
    if row.vengeance then return row.enemy.name .. " " .. row.vengeance.avenger.name end
    if row.avenger then return row.enemy.name .. " " .. row.avenger.name .. " " .. row.victim.name end
    return row.enemy and row.enemy.name or row.member.name
end

function UI.Render(f)
    if not f.panels then f.panels = {} end
    for _, panel in pairs(f.panels) do panel:Hide() end
    local p = f.panels[f.tab]
    if not p then p = makePanel(f); f.panels[f.tab] = p end
    p:Show()
    for _, row in ipairs(p.rows) do row:Hide() end
    for _, line in ipairs(p.lines) do line:Hide() end
    p.map:Hide(); p.mapNote:Hide(); p.portrait:Hide(); p.read:Hide(); p.thank:Hide()
    local data = ({f.view.wanted, f.view.ranking, f.view.journal, f.view.notifications})[f.tab]
    local rows = M.Filter(data, f.query, searchable)
    local current = M.Selected(rows, f.selection[f.tab], key)
    f.selection[f.tab] = current and key(current) or nil
    if not current or not p.current or key(p.current) ~= key(current) then p.detailScroll:SetVerticalScroll(0) end
    p.current = current
    for i, item in ipairs(rows) do
        local row = rowAt(p, i); row.key = key(item)
        row.fill:SetColorTexture(0.45, 0.11, 0.025, current == item and 0.28 or 0.10)
        if f.tab == 1 then
            set(row.title, item.enemy.name)
            set(row.sub, item.openCount > 0 and (item.openCount .. " à venger · " .. item.reward .. " réputation") or "VENGÉ · dossier archivé")
        elseif f.tab == 2 then
            local rank = i
            for position, ranked in ipairs(data) do if ranked.member.id == item.member.id then rank = position; break end end
            set(row.title, rank .. ". " .. item.member.name); set(row.sub, item.reputation .. " réputation · " .. item.victimsAvenged .. " membres vengés")
        elseif f.tab == 3 then
            set(row.title, item.kind == "incident" and item.incident.enemy.name or (item.vengeance.avenger.name .. " · vengeance"))
            set(row.sub, M.Date(item.occurredAt))
        elseif item.kind=="thanks" then
            set(row.title,item.victim.name.." · merci")
            set(row.sub,item.read and "Lu" or "Nouveau · remerciement reçu")
        else
            set(row.title, item.enemy.name .. " · VENGÉ")
            set(row.sub,item.deliveryStatus=="delivered" and "Remerciement reçu" or item.deliveryStatus=="pending" and "Merci en attente de livraison" or item.thanked and "Remerciement enregistré" or item.read and "Lu" or "Nouveau · vous avez été vengé")
        end
    end
    p.list:SetHeight(math.max(445, #rows * 76))
    set(f.footer, #rows .. " résultat(s)  ·  /syndicat ou /sr  ·  " .. (UI.provider.demo and "Aucune donnée réelle modifiée" or UI.provider.shared and "Registre partagé · sauvegarde activée" or "Registre personnel · sauvegarde activée"))
    if not current then
        set(p.title, "Le registre est silencieux")
        set(p.meta, f.query ~= "" and "Aucun résultat pour cette recherche." or "Aucune entrée disponible dans cet onglet.")
        set(p.summary, ""); set(p.status, ""); p.detail:SetHeight(445); return
    end
    if f.tab == 1 then
        local enemy, incident = current.enemy, current.lastIncident
        set(p.title, enemy.name); set(p.meta, M.Actor(enemy))
        set(p.summary, "Prime : " .. current.bounty .. " incident(s)\nRécompense : " .. current.reward .. " réputation")
        set(p.status, current.openCount == 0 and "[ VENGÉ ]" or current.openCount .. " dette(s) à régler")
        UI.Portraits.Display(p.portrait, enemy)
        detailLine(p, 1, "Dernier meurtre connu : " .. incident.location.zone)
        detailLine(p, 2, incident.victim.name .. " · " .. M.Date(incident.occurredAt))
        p.lines[1]:ClearAllPoints(); p.lines[1]:SetPoint("TOPLEFT", p.detail, "TOPLEFT", 14, -200)
        p.lines[2]:ClearAllPoints(); p.lines[2]:SetPoint("TOPLEFT", p.detail, "TOPLEFT", 14, -224)
        local offset = 5
        local available, marked, mapName = UI.Maps.Display(p.map, incident.location)
        local note = available and (mapName .. "\n\nDernier incident enregistré") or "Lieu : zone connue uniquement"
        if marked then note = note .. string.format("\n\n%.1f%% · %.1f%%", incident.location.x * 100, incident.location.y * 100)
        elseif available then note = note .. "\n\nPosition précise inconnue" end
        if UI.provider.demo then note = note .. "\n\nIncident fictif" end
        set(p.mapNote, note); p.mapNote:Show()
        for i, entry in ipairs(current.incidents) do
            detailLine(p, offset + i, entry.victim.name .. " · " .. entry.location.zone .. "\n" .. M.Date(entry.occurredAt) .. (entry.vengeanceId and " · vengé" or " · à venger"))
        end
        p.detail:SetHeight(math.max(445, 244 + (offset + #current.incidents) * 40))
    elseif f.tab == 2 then
        UI.Portraits.Display(p.portrait, current.member)
        set(p.title, current.member.name); set(p.meta, M.Actor(current.member))
        set(p.summary, current.reputation .. " réputation\n" .. current.victimsAvenged .. " membres vengés")
        set(p.status, "Le Syndicat se souvient.")
        for i, claim in ipairs(current.vengeances) do detailLine(p, i, M.Date(claim.occurredAt) .. " · " .. #claim.incidentIds .. " incident(s) vengé(s)") end
        p.detail:SetHeight(math.max(445, 244 + #current.vengeances * 40))
    elseif f.tab == 3 then
        local incident, claim = current.incident, current.vengeance
        set(p.title, incident and "Une dette de sang" or "La dette est réglée")
        set(p.meta, M.Date(current.occurredAt))
        set(p.summary, incident and (incident.enemy.name .. " a tué " .. incident.victim.name) or (claim.avenger.name .. " a vengé le Syndicat"))
        set(p.status, incident and (incident.vengeanceId and "[ VENGÉ ]" or "À VENGER") or "[ VENGÉ ]")
        detailLine(p, 1, incident and incident.location.zone or ("Cible : " .. current.enemy.name))
        detailLine(p, 2, incident and M.Actor(incident.enemy) or ("Réputation attribuée : " .. claim.reward))
        p.detail:SetHeight(445)
    elseif current.kind=="thanks" then
        set(p.title,"Le Syndicat te remercie")
        set(p.meta,M.Date(current.occurredAt).." · vengeance concernée")
        set(p.summary,current.victim.name.." te remercie pour "..current.enemy.name..".")
        p.summary:ClearAllPoints();p.summary:SetPoint("TOPLEFT",p.detail,"TOPLEFT",14,-94)
        set(p.status,"");p.read:Show()
        if current.read then p.read:Disable() else p.read:Enable() end
        detailLine(p,1,"Remerciement volontaire reçu et sauvegardé. Aucun point supplémentaire attribué.")
        p.detail:SetHeight(445)
    else
        set(p.title, "Vous avez été vengé !"); set(p.meta, M.Date(current.occurredAt))
        set(p.summary, current.avenger.name .. " a éliminé " .. current.enemy.name)
        p.summary:ClearAllPoints(); p.summary:SetPoint("TOPLEFT", p.detail, "TOPLEFT", 14, -94)
        set(p.status, "")
        p.read:Show(); p.thank:Show()
        p.thank.label:SetText(current.deliveryStatus=="delivered" and "Merci reçu" or current.deliveryStatus=="pending" and "En attente" or current.deliveryStatus=="local" and "Envoyer le merci" or current.thanked and "Remerciement enregistré" or "Remercier")
        if current.canThank==false or (current.thanked and current.deliveryStatus~="local") then p.thank:Disable() else p.thank:Enable() end
        if current.read then p.read:Disable() else p.read:Enable() end
        detailLine(p,1,UI.provider.demo and "Démonstration : le remerciement reste local." or current.deliveryStatus=="delivered" and "Le vengeur a confirmé la réception du remerciement." or current.deliveryStatus=="pending" and "Merci sauvegardé. Livraison à la prochaine connexion simultanée avec le vengeur." or UI.provider.shared and "Remercier envoie un message au vengeur via le partage de guilde." or "Active le partage de guilde pour livrer les remerciements.")
        detailLine(p, 3, "Discord : non configuré. Aucun message envoyé.")
        p.detail:SetHeight(445)
    end
end
