local _,ns=...
local Y={clock=0,queue={},seen={},rates={},offers={},serving={},sessions={},status="inactive",counter=0};ns.ReportSync=Y
local V,R,S=ns.Validation,ns.ReportSchema,ns.ReportStore
local function hash(s)local n=0;for i=1,#s do n=(n*33+s:byte(i))%65521 end;return n end
local function active()
    local n=ns.GuildNative
    return S.writable and S.Settings().sharing and n.channel and not n.testMode and ns.Access.Allowed()
end
local function id()
    Y.counter=Y.counter+1
    return "r"..math.floor(Y.clock*10).."-"..Y.counter.."-"..math.random(10000,99999)
end
local function send(kind,data,target,priority)
    if not active()then return false,"sharing_inactive"end
    if #Y.queue>=32 then Y.status="queue_full";return false,"report_queue_limit"end
    local c=ns.GuildNative.channel
    local out=ns.Channel.Envelope(c,"report",id(),target)
    out.report={v=1,kind=kind,data=data}
    Y.queue[#Y.queue+1]={envelope=out,expires=Y.clock+30,priority=priority or 2}
    return true
end
function Y.Reset()
    Y.queue={};Y.offers={};Y.serving={};Y.sessions={};Y.context=nil;Y.request=nil;Y.status="inactive";Y.seen={};Y.rates={};Y.confirmations={};Y.autoAttempts=0;Y.lastRequest=nil
end
function Y.Request()
    if not active()then return false,"sharing_inactive"end
    if Y.lastRequest and Y.clock-Y.lastRequest<30 then return false,"sync_cooldown"end
    Y.lastRequest=Y.clock;local request=id()
    local ok,reason=send("seek",{request=request})
    if ok then Y.request={id=request,untilAt=Y.clock+45,attempt=1,sources=0};Y.offers={};Y.sessions={};Y.status="seeking"end
    return ok,reason
end
function Y.Start(context)
    Y.Reset();Y.context=context.guildId;Y.beginAt=Y.clock+2+(hash(context.owner.id)%30)/10;Y.lastRequest=nil
    Y.confirmKeys={};Y.confirmIndex=1
    if S.writable then for id,e in pairs(S.data.shared)do if e.trust=="relay" and e.row.guildId==context.guildId then Y.confirmKeys[#Y.confirmKeys+1]=id end end end
end
function Y.Publish(row)
    if not active() or row.victim.id~=ns.GuildNative.channel.context.owner.id or row.guildId~=ns.GuildNative.channel.context.guildId then return false,"author_required"end
    return send("direct",{row=row},nil,1)
end
function Y.UserFlush()
    if not active()then return end
    if #Y.queue>0 then
        table.sort(Y.queue,function(a,b)return a.priority<b.priority end)
        local item=Y.queue[1]
        if item.expires>=Y.clock and ns.GuildNative.Enqueue(item.envelope,false)then table.remove(Y.queue,1)end
    end
    ns.GuildNative.UserSend()
end
local function knownShape(t,keys,limit)return R.Keys(t,keys,limit)end
local function requestId(v)return R.Text(v,40) and v:match("^[%w%-]+$")end
function Y.Receive(envelope,sender)
    if not active()then return false,"reports_inactive"end
    local now=ns.EnemyObserver.Now();if not now then return false,"time_unavailable"end
    local c=ns.GuildNative.channel
    if type(envelope)~="table" or envelope.kind~="report" or envelope.guildId~=c.context.guildId or envelope.senderId~=sender.id
        or (envelope.target and envelope.target~=c.context.owner.id)then return false,"invalid_report_envelope"end
    local m=envelope.report
    if not knownShape(m,{v=true,kind=true,data=true},3) or m.v~=1 or type(m.data)~="table"then return false,"report_protocol"end
    local key=sender.id..":"..envelope.id
    if Y.seen[key]then return false,"duplicate"end
    local rate=Y.rates[sender.id]
    if not rate or Y.clock-rate.at>=10 then rate={at=Y.clock,n=0};Y.rates[sender.id]=rate end
    rate.n=rate.n+1;if rate.n>12 then return false,"report_rate_limit"end
    if V.Count(Y.rates)>128 then return false,"sender_limit"end
    if V.Count(Y.seen)>=512 then Y.seen={}end;Y.seen[key]=Y.clock
    local d=m.data
    if m.kind=="seek"then
        if not knownShape(d,{request=true},1) or not requestId(d.request)then return false,"invalid_seek"end
        if Y.serving[sender.id] and Y.clock-Y.serving[sender.id].started<30 then return false,"seek_cooldown"end
        if V.Count(Y.serving)>=8 then return false,"source_capacity"end
        Y.serving[sender.id]={request=d.request,started=Y.clock,expires=Y.clock+600,offerAt=Y.clock+1+(hash(sender.id..c.context.owner.id)%40)/10,pages=0}
    elseif m.kind=="offer"then
        if not knownShape(d,{request=true,count=true},2) or not requestId(d.request) or not V.Integer(d.count,0,5000)then return false,"invalid_offer"end
        if not Y.request or d.request~=Y.request.id or Y.clock>Y.request.untilAt or V.Count(Y.offers)>=16 then return false,"unsolicited_offer"end
        Y.offers[sender.id]={id=sender.id,count=d.count}
    elseif m.kind=="legacy"then
        if not knownShape(d,{request=true},1) or not requestId(d.request)then return false,"invalid_legacy_request"end
        local serving=Y.serving[sender.id]
        if not serving or serving.request~=d.request or serving.expires<Y.clock or serving.legacy then return false,"expired_request"end
        serving.legacy=true;return ns.GuildNative.SendLegacyState(sender.id)
    elseif m.kind=="get"then
        if not knownShape(d,{request=true,cursor=true},2) or not requestId(d.request) or type(d.cursor)~="string" or #d.cursor>240 then return false,"invalid_get"end
        local serving=Y.serving[sender.id]
        if not serving or serving.request~=d.request or serving.expires<Y.clock or serving.pages>=8 then return false,"expired_request"end
        -- Replayed cursor requests are allowed, but still consume the finite page budget.
        local list=S.Index(c.context.guildId);local rows={};local cursor=d.cursor;local more=false
        for _,e in ipairs(list)do
            if e.row.id>cursor then
                if #rows>=4 then more=true;break end
                -- Only author-confirmed originals may be forwarded, once and for 120 seconds.
                if e.trust=="author"then rows[#rows+1]={row=e.row,hop=e.row.victim.id==c.context.owner.id and 0 or 1,expires=now+120};cursor=e.row.id end
            end
        end
        serving.pages=serving.pages+1
        return send("page",{request=d.request,after=d.cursor,cursor=cursor,more=more,rows=rows},sender.id,3)
    elseif m.kind=="page"then
        if not knownShape(d,{request=true,after=true,cursor=true,more=true,rows=true},5) or not requestId(d.request) or type(d.after)~="string" or #d.after>240
            or type(d.cursor)~="string" or #d.cursor>240 or type(d.more)~="boolean" or type(d.rows)~="table" or V.Count(d.rows)>4 then return false,"invalid_page"end
        local session=Y.sessions[sender.id]
        if not session or session.request~=d.request or session.cursor~=d.after or session.expires<Y.clock then return false,"unsolicited_page"end
        local normalized={};local previous=d.after
        for i,item in ipairs(d.rows)do
            if not knownShape(item,{row=true,hop=true,expires=true},3) or not V.Integer(item.hop,0,1) or not V.Integer(item.expires,now,now+120)then return false,"invalid_relay"end
            local row,why=R.Normalize(item.row,now,S.Settings().days)
            if not row or row.guildId~=c.context.guildId or row.id<=previous then return false,why or "page_order"end
            if (item.hop==0)~=(row.victim.id==sender.id)then return false,"invalid_origin"end
            if not ns.GuildContext.Member(row.victim,c.context)then return false,"victim_not_member"end
            previous=row.id;normalized[i]={row=row,trust=item.hop==0 and "author" or "relay"}
        end
        if #normalized~=V.Count(d.rows) or d.cursor~=previous or (d.more and d.cursor==d.after)then return false,"invalid_cursor"end
        for _,e in ipairs(normalized)do
            local ok,why=S.Put(e.row,e.trust,now,false)
            if e.trust=="author" and (ok or why=="duplicate")then ns.ReportsRuntime.Project(S.data.shared[e.row.id].row)end
            if e.trust=="relay" and (ok or why=="duplicate")then Y.Confirm(e.row)end
        end
        session.pages=session.pages+1;session.cursor=d.cursor;session.attempt=1
        local cursorKey=c.context.guildId..":"..sender.id
        if V.Count(S.data.cursors)>=32 and not S.data.cursors[cursorKey]then S.data.cursors={}end
        S.data.cursors[cursorKey]=d.more and d.cursor or nil
        if d.more and session.pages<8 then session.nextAt=Y.clock+1;session.expires=Y.clock+90
        else session.done=true;session.more=d.more end
        Y.status="syncing";ns.ReportsRuntime.Changed()
    elseif m.kind=="direct"then
        if not knownShape(d,{row=true},1)then return false,"invalid_direct"end
        local row,reason=R.Normalize(d.row,now,S.Settings().days)
        if not row or row.guildId~=c.context.guildId then return false,reason or "guild_mismatch"end
        if row.victim.id~=sender.id or row.victim.name~=sender.name or row.victim.realm~=sender.realm then return false,"direct_victim_mismatch"end
        local ok,why=S.Put(row,"author",now,false)
        if not ok and why~="duplicate"then return false,why end
        Y.confirmations[row.id]=nil
        ns.ReportsRuntime.Project(S.data.shared[row.id].row);ns.ReportsRuntime.Changed()
    elseif m.kind=="confirm"then
        if not knownShape(d,{id=true},1) or not R.Text(d.id,240)then return false,"invalid_confirmation"end
        local e=S.data.personal[d.id]
        if not e or e.row.victim.id~=c.context.owner.id then return false,"not_author"end
        return send("direct",{row=e.row},sender.id,1)
    else return false,"unknown_report_kind"end
    return true
end
function Y.Confirm(row)
    -- Target only the original victim; relays never vote for their own content.
    Y.confirmations=Y.confirmations or {}
    if Y.confirmations[row.id] or V.Count(Y.confirmations)>=64 then return end
    Y.confirmations[row.id]={author=row.victim.id,attempt=0,nextAt=Y.clock,expires=Y.clock+600}
end
function Y.Tick(dt)
    Y.clock=Y.clock+dt
    if not active()then if Y.context then Y.Reset()end;return end
    local c=ns.GuildNative.channel
    if Y.context~=c.context.guildId then Y.Start(c.context)end
    if Y.beginAt and Y.clock>=Y.beginAt then Y.beginAt=nil;Y.Request()end
    if Y.clock>=(Y.nextConfirm or 0)then
        Y.nextConfirm=Y.clock+2
        if Y.confirmKeys and Y.confirmIndex<=#Y.confirmKeys and V.Count(Y.confirmations)<64 then
            for _=1,8 do
                local key=Y.confirmKeys[Y.confirmIndex];if not key then break end;Y.confirmIndex=Y.confirmIndex+1
                local e=S.data.shared[key];if e and e.trust=="relay"then Y.Confirm(e.row)end
            end
        end
        local sent=false
        for key,job in pairs(Y.confirmations)do
            local e=S.data.shared[key]
            if not e or e.trust=="author" or job.expires<Y.clock then Y.confirmations[key]=nil
            elseif not sent and job.attempt<3 and job.nextAt<=Y.clock then
                if send("confirm",{id=key},job.author,1)then job.attempt=job.attempt+1;job.nextAt=Y.clock+45*job.attempt;sent=true end
            end
        end
    end
    for peer,s in pairs(Y.serving)do
        if s.expires<Y.clock then Y.serving[peer]=nil
        elseif s.offerAt and Y.clock>=s.offerAt then
            s.offerAt=nil;send("offer",{request=s.request,count=#S.Index(c.context.guildId)},peer,2)
        end
    end
    if Y.request and not Y.request.selected and Y.clock>=Y.request.untilAt then
        Y.request.selected=true
        local offers={};for _,o in pairs(Y.offers)do offers[#offers+1]=o end
        table.sort(offers,function(a,b)if a.count~=b.count then return a.count>b.count end;return a.id<b.id end)
        for i=1,math.min(2,#offers)do
            local o=offers[i];local cursor=S.data.cursors[c.context.guildId..":"..o.id]or ""
            Y.sessions[o.id]={request=Y.request.id,cursor=cursor,pages=0,attempt=1,nextAt=Y.clock,expires=Y.clock+90}
            Y.request.sources=Y.request.sources+1
            send("legacy",{request=Y.request.id},o.id,2)
        end
        if #offers==0 then
            Y.status="no_source"
            if (Y.autoAttempts or 0)<2 then Y.autoAttempts=(Y.autoAttempts or 0)+1;Y.beginAt=Y.clock+30*Y.autoAttempts end
        end
    end
    local work=0
    for peer,s in pairs(Y.sessions)do
        if not s.done then
            if Y.clock>=s.expires then
                if s.attempt>=3 then s.done=true;s.failed=true;Y.status="timeout"
                else s.attempt=s.attempt+1;s.nextAt=Y.clock+2*s.attempt;s.expires=s.nextAt+90 end
            end
            if s.nextAt and Y.clock>=s.nextAt and work<2 then
                local ok=send("get",{request=s.request,cursor=s.cursor},peer,2)
                if ok then s.nextAt=nil;work=work+1 else s.nextAt=Y.clock+3 end
            end
        end
    end
    if Y.request and Y.request.selected and Y.request.sources>0 and not Y.request.finished then
        local done,more,failed=true,false,false
        for _,s in pairs(Y.sessions)do if not s.done then done=false end;if s.more then more=true end;if s.failed then failed=true end end
        if done then
            Y.request.finished=true;Y.status=failed and "partial_timeout" or "complete"
            if more then Y.beginAt=Y.clock+30 elseif failed and (Y.autoAttempts or 0)<2 then Y.autoAttempts=(Y.autoAttempts or 0)+1;Y.beginAt=Y.clock+60 end
            ns.ReportsRuntime.Changed()
        end
    end
    if #Y.queue>0 and Y.clock>=(Y.nextSend or 0)then
        Y.nextSend=Y.clock+.5
        table.sort(Y.queue,function(a,b)return a.priority<b.priority end)
        local item=Y.queue[1]
        if item.expires<Y.clock then table.remove(Y.queue,1);Y.status="queue_expired"
        elseif #ns.GuildNative.queue<100 then
            local ok=ns.GuildNative.Enqueue(item.envelope,false)
            if ok then table.remove(Y.queue,1)else Y.status="queue_backpressure"end
        end
    end
    if Y.clock>=(Y.nextSweep or 0)then
        Y.nextSweep=Y.clock+30
        for key,at in pairs(Y.seen)do if Y.clock-at>120 then Y.seen[key]=nil end end
        for peer,r in pairs(Y.rates)do if Y.clock-r.at>30 then Y.rates[peer]=nil end end
        S.Cleanup(ns.EnemyObserver.Now() or 0)
    end
end
