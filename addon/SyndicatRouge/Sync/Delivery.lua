local _,ns=...
local V=ns.Validation
local D={limit=256};ns.Delivery=D
function D.Validate(input,context)
    if type(input)~="table" or input.version~=1 or input.guildId~=context.guildId
        or input.ownerId~=context.owner.id then return nil,"invalid_delivery_cache" end
    local out={version=1,guildId=input.guildId,ownerId=input.ownerId,outbox={},inbox={},alerts={}}
    for _,key in ipairs({"outbox","inbox","alerts"}) do
        if type(input[key])~="table" or V.Count(input[key])>D.limit then return nil,"delivery_limit" end
        for id,row in pairs(input[key]) do
            if not V.String(id,300) then return nil,"invalid_delivery_id" end
            if key=="alerts" then
                if row~=true then return nil,"invalid_alert" end
                out.alerts[id]=true
            else
                if type(row)~="table" or row.notificationId~=id or not V.String(row.claimId)
                    or not V.String(row.fromId) or not V.String(row.toId) or row.fromId==row.toId
                    or (key=="outbox" and row.fromId~=input.ownerId)
                    or (key=="inbox" and row.toId~=input.ownerId) then return nil,"invalid_thank" end
                local clean={notificationId=id,claimId=row.claimId,fromId=row.fromId,toId=row.toId}
                if key=="outbox" then
                    if row.status~="pending" and row.status~="delivered" then return nil,"invalid_delivery_status" end
                    clean.status=row.status
                else
                    if type(row.read)~="boolean" or type(row.announced)~="boolean" then return nil,"invalid_inbox_state" end
                    clean.read=row.read;clean.announced=row.announced
                end
                out[key][id]=clean
            end
        end
    end
    return out
end
function D.Open(root,context)
    if root.guildDelivery~=nil and type(root.guildDelivery)~="table" then return nil,"invalid_delivery_cache" end
    local saved=root.guildDelivery and root.guildDelivery[context.guildId]
    return D.Validate(saved or {version=1,guildId=context.guildId,ownerId=context.owner.id,outbox={},inbox={},alerts={}},context)
end
local function matches(row,note)
    return note and row.claimId==note.claimId and row.fromId==note.victimId and row.toId==note.avenger.id
end
function D.Queue(delivery,session,id)
    local note=ns.Notifications.All(session.db)[id]
    if not note or note.victimId~=session.ownerId then return nil,"unknown_notification" end
    if note.avenger.id==session.ownerId then return nil,"self_thanks" end
    if delivery.outbox[id] then return nil,"duplicate" end
    if V.Count(delivery.outbox)>=D.limit then return nil,"delivery_limit" end
    local copy=V.Copy(delivery)
    copy.outbox[id]={notificationId=id,claimId=note.claimId,fromId=note.victimId,toId=note.avenger.id,status="pending"}
    return copy
end
function D.Receive(delivery,session,envelope,sender)
    local id=envelope.notificationId
    if not V.String(id,300) or envelope.target~=session.ownerId then return nil,"invalid_thank_target" end
    local note=ns.Notifications.All(session.db)[id]
    if not note or note.victimId~=sender or note.avenger.id~=session.ownerId or sender==session.ownerId
        or envelope.claimId~=note.claimId then return nil,"invalid_thank_author" end
    local copy=V.Copy(delivery)
    if not copy.inbox[id] then
        if V.Count(copy.inbox)>=D.limit then return nil,"delivery_limit" end
        copy.inbox[id]={notificationId=id,claimId=note.claimId,fromId=sender,toId=session.ownerId,read=false,announced=false}
    end
    return copy
end
function D.Acknowledge(delivery,session,envelope,sender)
    local id=envelope.notificationId
    if not V.String(id,300) or envelope.target~=session.ownerId then return nil,"invalid_thank_ack" end
    local row=delivery.outbox[id]
    if not row or row.toId~=sender or row.fromId~=session.ownerId or envelope.claimId~=row.claimId then return nil,"invalid_thank_ack" end
    local copy=V.Copy(delivery);copy.outbox[id].status="delivered";return copy
end
function D.Pending(delivery,session)
    local all=ns.Notifications.All(session.db);local rows={}
    for id,row in pairs(delivery.outbox) do
        if row.status=="pending" and matches(row,all[id]) then rows[#rows+1]=V.Copy(row) end
    end
    table.sort(rows,function(a,b)return a.notificationId<b.notificationId end);return rows
end
function D.View(delivery,session)
    local view=ns.Guild.View(session)
    for _,note in ipairs(view.notifications) do
        local row=delivery.outbox[note.id]
        note.deliveryStatus=row and matches(row,note) and row.status or (note.thanked and "local" or nil)
        note.canThank=note.avenger.id~=session.ownerId
    end
    local all=ns.Notifications.All(session.db)
    for id,row in pairs(delivery.inbox) do
        if matches(row,all[id]) then
            local note=V.Copy(all[id]);note.id="thanks:"..id;note.kind="thanks";note.read=row.read
            view.notifications[#view.notifications+1]=note
        end
    end
    table.sort(view.notifications,V.Newest);return view
end
function D.Read(delivery,id)
    if type(id)~="string" or id:sub(1,7)~="thanks:" then return nil,"unknown_thanks" end
    local row=delivery.inbox[id:sub(8)]
    if not row then return nil,"unknown_thanks" end
    local copy=V.Copy(delivery);copy.inbox[id:sub(8)].read=true;return copy
end
function D.Alerts(delivery,session)
    local copy=V.Copy(delivery);local vengeance,thanks={},{}
    local all=ns.Notifications.All(session.db)
    for id,note in pairs(all) do
        if note.victimId==session.ownerId and not copy.alerts[id] then
            if V.Count(copy.alerts)>=D.limit then return nil,"delivery_limit" end
            copy.alerts[id]=true
            if not note.read then vengeance[#vengeance+1]=note end
        end
    end
    for id,row in pairs(copy.inbox) do
        if not row.announced and matches(row,all[id]) then
            row.announced=true
            if not row.read then thanks[#thanks+1]=all[id] end
        end
    end
    table.sort(vengeance,V.Newest);table.sort(thanks,V.Newest)
    return copy,vengeance,thanks
end
