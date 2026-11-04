local _, ns = ...
ns.DiscordOutbox = {}

function ns.DiscordOutbox.Build(session)
    local shared, reason = ns.Protocol.Export(session)
    if not shared then return nil, reason end
    -- This exporter is for the offline workshop. A live-client adapter is not
    -- implemented, so its output cannot silently become a real Discord feed.
    return { version = 1, target = "forever", mode = "demo", guildId = session.guildId,
        guildName = ns.Config.guildName, incidents = shared.incidents, claims = shared.claims }
end

function ns.DiscordOutbox.FromSnapshot(snapshot, guildId, ownerId, roster)
    local session, reason = ns.Guild.Restore(snapshot, guildId, ownerId, roster)
    if not session then return nil, reason end
    return ns.DiscordOutbox.Build(session)
end
