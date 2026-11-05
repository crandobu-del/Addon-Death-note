local _, ns = ...
local W = { limit = 131072, chunk = 180 }
ns.Wire = W

-- Length-prefixed data, never Lua source. Bounds also apply before allocation.
function W.Encode(value)
    local nodes, active = 0, {}
    local function encode(v, depth)
        nodes = nodes + 1
        assert(nodes <= 30000 and depth <= 12, "wire_complexity")
        local kind = type(v)
        if kind == "boolean" then return v and "y" or "n" end
        if kind == "string" then
            assert(#v <= 4096 and not v:find("%z"), "wire_string")
            return "s" .. #v .. ":" .. v
        end
        if kind == "number" then
            assert(v == v and math.abs(v) <= 9007199254740991, "wire_number")
            local s = tostring(v); return "d" .. #s .. ":" .. s
        end
        assert(kind == "table" and not active[v], "wire_type")
        active[v] = true
        local keys, out = {}, {}
        for k in pairs(v) do
            assert(type(k) == "string" or (type(k) == "number" and k >= 1 and k % 1 == 0), "wire_key")
            keys[#keys+1] = k
        end
        table.sort(keys, function(a,b) if type(a) ~= type(b) then return type(a) < type(b) end return a < b end)
        out[1] = "t" .. #keys .. ":"
        for _, k in ipairs(keys) do out[#out+1] = encode(k,depth+1);out[#out+1] = encode(v[k],depth+1) end
        active[v] = nil
        local result = table.concat(out);assert(#result <= W.limit, "wire_limit");return result
    end
    local ok, result = pcall(encode,value,0)
    if not ok then return nil,"invalid_wire_data" end
    return result
end

function W.Decode(text)
    if type(text) ~= "string" or #text > W.limit then return nil,"wire_limit" end
    local pos, nodes = 1, 0
    local function length(max)
        local stop = text:find(":",pos,true)
        assert(stop and stop-pos <= 6, "length")
        local digits = text:sub(pos,stop-1);assert(digits:match("^%d+$"),"length")
        local n = tonumber(digits);assert(n and n <= max,"length");pos=stop+1;return n
    end
    local function decode(depth)
        nodes=nodes+1;assert(nodes<=30000 and depth<=12,"complexity")
        local tag=text:sub(pos,pos);pos=pos+1
        if tag=="y" then return true elseif tag=="n" then return false end
        if tag=="s" or tag=="d" then
            local n=length(4096);assert(pos+n-1<=#text,"truncated")
            local s=text:sub(pos,pos+n-1);pos=pos+n
            if tag=="s" then assert(not s:find("%z"),"nul");return s end
            assert(s:match("^[%d%.%+%-%eE]+$"),"number")
            local v=tonumber(s);assert(v and v==v and math.abs(v)<=9007199254740991,"number");return v
        end
        assert(tag=="t","tag")
        local count=length(10000);local out={}
        for i=1,count do
            local k=decode(depth+1)
            assert(type(k)=="string" or (type(k)=="number" and k>=1 and k%1==0),"key")
            assert(out[k]==nil,"duplicate_key");out[k]=decode(depth+1)
        end
        return out
    end
    local ok,result=pcall(decode,0)
    if not ok or pos~=#text+1 then return nil,"invalid_wire_data" end
    return result
end

function W.Packets(value, id)
    local text,reason=W.Encode(value)
    if not text then return nil,reason end
    if type(id)~="string" or not id:match("^[%w%-]+$") or #id>32 then return nil,"invalid_transfer" end
    local total=math.ceil(#text/W.chunk);local packets={}
    for i=1,total do packets[i]="1;"..id..";"..i..";"..total..";"..text:sub((i-1)*W.chunk+1,i*W.chunk) end
    return packets
end

function W.Receive(pool,sender,packet,now)
    for key,t in pairs(pool) do if now-t.started>300 then pool[key]=nil end end
    if type(packet)~="string" or #packet>240 then return nil,"invalid_packet" end
    local id,index,total,body=packet:match("^1;([%w%-]+);(%d+);(%d+);(.*)$")
    index,total=tonumber(index),tonumber(total)
    if not id or #id>32 or not index or not total or total<1 or total>729 or index<1 or index>total or #body>W.chunk then return nil,"invalid_packet" end
    local key=sender..":"..id;local transfer=pool[key]
    if not transfer then
        local count,own=0,0
        for _,t in pairs(pool) do count=count+1;if t.sender==sender then own=own+1 end end
        if count>=4 or own>=2 then return nil,"transfer_limit" end
        transfer={sender=sender,started=now,total=total,parts={},count=0,bytes=0};pool[key]=transfer
    end
    if transfer.total~=total or (transfer.parts[index] and transfer.parts[index]~=body) then pool[key]=nil;return nil,"packet_conflict" end
    if not transfer.parts[index] then
        transfer.parts[index]=body;transfer.count=transfer.count+1;transfer.bytes=transfer.bytes+#body
    end
    if transfer.bytes>W.limit then pool[key]=nil;return nil,"wire_limit" end
    if transfer.count~=total then return nil,"pending" end
    pool[key]=nil;return W.Decode(table.concat(transfer.parts))
end
