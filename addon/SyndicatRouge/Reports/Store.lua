local _,ns=...
local S={};ns.ReportStore=S
local V,R=ns.Validation,ns.ReportSchema
local defaults={enabled=true,sharing=true,mixed="ignore",days=30,maxShared=5000,maxPersonal=1000,diagnostic=false}
function S.Open(root,now)
    S.root=root;S.writable=false;S.status="read_only"
    if not ns.Runtime or not ns.Runtime.writable or type(root)~="table"then return false end
    local saved=root.pvpReports
    if saved==nil then saved={version=1,settings=V.Copy(defaults),personal={},shared={},serial=0};root.pvpReports=saved end
    if type(saved)~="table" or saved.version~=1 or type(saved.personal)~="table" or type(saved.shared)~="table" or type(saved.settings)~="table"then S.status="unsupported_report_store";return false end
    local cfg=V.Copy(defaults)
    for k,v in pairs(saved.settings)do
        if (k=="enabled" or k=="sharing" or k=="diagnostic") and type(v)=="boolean"then cfg[k]=v
        elseif k=="mixed" and (v=="ignore" or v=="estimate")then cfg[k]=v
        elseif k=="days" and V.Integer(v,1,90)then cfg[k]=v
        elseif k=="maxShared" and V.Integer(v,50,5000)then cfg[k]=v
        elseif k=="maxPersonal" and V.Integer(v,50,5000)then cfg[k]=v end
    end
    -- Validate a detached candidate before touching any existing report data.
    local candidate={version=1,settings=cfg,personal={},shared={},serial=V.Integer(saved.serial,0,9007199254740990) and saved.serial or 0}
    for _,bucket in ipairs({"personal","shared"})do
        if V.Count(saved[bucket])>5000 then S.status="report_store_limit";return false end
        for id,entry in pairs(saved[bucket])do
            if type(entry)~="table" or type(entry.row)~="table" or id~=entry.row.id then S.status="invalid_report_store";return false end
            -- Expired rows are intentionally pruned, invalid current rows preserve the original store read-only.
            if V.Integer(entry.row.at,0,now-cfg.days*86400-1)then
            else
                local row=R.Normalize(entry.row,now,cfg.days)
                if not row or (entry.trust~="author" and entry.trust~="relay")then S.status="invalid_report_store";return false end
                candidate[bucket][id]={row=row,trust=entry.trust}
            end
        end
    end
    candidate.cursors={}
    if type(saved.lastRecapStamp)=="number" and saved.lastRecapStamp==saved.lastRecapStamp and saved.lastRecapStamp>=1000 and saved.lastRecapStamp<=now+1 then candidate.lastRecapStamp=saved.lastRecapStamp end
    if type(saved.cursors)=="table" and V.Count(saved.cursors)<=32 then
        for k,v in pairs(saved.cursors)do if R.Text(k,300) and type(v)=="string" and #v<=240 then candidate.cursors[k]=v end end
    end
    root.pvpReports=candidate;S.data=candidate;S.generation=(S.generation or 0)+1;S.writable=true;S.status="ready";S.Cleanup(now);return true
end
function S.Settings()return S.writable and S.data.settings or defaults end
function S.Cleanup(now)
    if not S.writable then return end
    local changed=false
    for _,bucket in ipairs({"personal","shared"})do
        local map=S.data[bucket];local list={}
        for id,e in pairs(map)do if e.row.at<now-S.data.settings.days*86400 then map[id]=nil;changed=true else list[#list+1]=e.row end end
        table.sort(list,function(a,b)if a.at~=b.at then return a.at>b.at end;return a.id<b.id end)
        local limit=bucket=="personal" and S.data.settings.maxPersonal or S.data.settings.maxShared
        for i=limit+1,#list do map[list[i].id]=nil;changed=true end
    end
    if changed then S.generation=(S.generation or 0)+1 end
end
local function actorMerge(old,new)
    if not old or not new then return old end
    if old.guid and old.guid~=new.guid then return old end
    local out=V.Copy(old)
    for k,v in pairs(new)do
        if out[k]~=nil and out[k]~=v and not (k=="name" and not old.id and new.id)then return nil end
        out[k]=v
    end
    return out
end
function S.Put(input,trust,now,personal)
    if not S.writable then return false,"report_store_read_only"end
    if trust~="author" and trust~="relay"then return false,"invalid_trust"end
    local row,reason=R.Normalize(input,now,S.data.settings.days);if not row then return false,reason end
    local encoded=ns.Wire.Encode(row);if not encoded or #encoded>8192 then return false,"report_size"end
    local bucket=personal and S.data.personal or S.data.shared
    local old=bucket[row.id]
    if old then
        if old.trust=="relay" and trust=="author"then
            -- Confirmation authenticates only the author's actual payload, never relay-only identity fields.
        elseif not V.Same(R.Facts(old.row),R.Facts(row))then
            if trust~="author" or old.trust=="author"then return false,"report_conflict"end
            -- The author may correct a forged relay, never another author's record.
        else
            local merged=V.Copy(old.row)
            merged.victim=actorMerge(old.row.victim,row.victim)
            merged.killer=actorMerge(old.row.killer,row.killer)
            if not merged.victim or (old.row.killer and not merged.killer)then
                if not (trust=="author" and old.trust=="relay")then return false,"identity_conflict"end
            else
                for i,a in ipairs(merged.attackers)do
                    for _,b in ipairs(row.attackers)do if a.guid==b.guid then local m=actorMerge(a,b);if not m then return false,"identity_conflict"end;merged.attackers[i]=m end end
                end
                merged.revision=math.max(merged.revision,row.revision);row=merged
            end
            if V.Same(old.row,row) and (old.trust=="author" or trust=="relay")then return false,"duplicate"end
        end
        if old.trust=="author" and trust=="relay"then return false,"relay_cannot_update_author"end
    end
    bucket[row.id]={row=row,trust=trust}
    S.generation=(S.generation or 0)+1
    local limit=personal and S.data.settings.maxPersonal or S.data.settings.maxShared
    if not old and V.Count(bucket)>limit then
        local oldest,key
        for id,e in pairs(bucket)do if not oldest or e.row.at<oldest then oldest=e.row.at;key=id end end
        if key then bucket[key]=nil end
    end
    if not bucket[row.id]then return false,"capacity_evicted"end
    return true,row
end
function S.List(personal,guildId)
    local rows={};if not S.writable then return rows end
    for _,e in pairs(personal and S.data.personal or S.data.shared)do if not guildId or e.row.guildId==guildId then rows[#rows+1]=V.Copy(e)end end
    table.sort(rows,function(a,b)if a.row.at~=b.row.at then return a.row.at>b.row.at end;return a.row.id<b.row.id end)
    return rows
end
function S.Index(guildId)
    if S.index and S.indexGeneration==S.generation and S.indexGuild==guildId then return S.index end
    local out={}
    if S.writable then for _,entry in pairs(S.data.shared)do if entry.trust=="author" and entry.row.guildId==guildId then out[#out+1]=entry end end end
    table.sort(out,function(a,b)return a.row.id<b.row.id end)
    S.index=out;S.indexGuild=guildId;S.indexGeneration=S.generation;return out
end
function S.NextId(victim,now)
    if not S.writable then return nil end
    S.data.serial=S.data.serial+1
    return victim.id..":"..now..":"..S.data.serial
end
function S.Enrich(guid,actor,now,ownerId)
    if not S.writable then return end
    local changed={}
    -- Enrich only reports authored locally. A relay cannot amend someone else's identity.
    for id,e in pairs(S.data.personal)do
        if e.row.victim.id==ownerId then
            local matches=e.row.killer and e.row.killer.guid==guid
            for _,a in ipairs(e.row.attackers)do if a.guid==guid then matches=true;break end end
            local row=matches and V.Copy(e.row);local hit=false
            if row then
            for _,a in ipairs(row.attackers)do if a.guid==guid then local m=actorMerge(a,actor);if m and not V.Same(m,a)then for k,v in pairs(m)do a[k]=v end;hit=true end end end
            if row.killer and row.killer.guid==guid then local m=actorMerge(row.killer,actor);if m and not V.Same(m,row.killer)then row.killer=m;hit=true end end
            if hit then row.revision=row.revision+1;changed[#changed+1]=row end
            if #changed>=8 then break end
            end
        end
    end
    for _,row in ipairs(changed)do S.Put(row,"author",now,true);S.Put(row,"author",now,false)end
    return changed
end
