local _, ns = ...
local P, V = {}, ns.Validation
ns.Persistence = P
P.scope = "local:forever"
local anchors = {CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
local function offset(value)
    return type(value)=="number" and value==value and value>=-20000 and value<=20000
end
function P.UI(input)
    local result={tab=1}
    if type(input)~="table" then return result end
    if V.Integer(input.tab,1,4) then result.tab=input.tab end
    local p=input.position
    if type(p)=="table" and anchors[p.point] and anchors[p.relativePoint] and offset(p.x) and offset(p.y) then
        result.position={point=p.point,relativePoint=p.relativePoint,x=p.x,y=p.y}
    end
    return result
end
local function restore(snapshot)
    local ok,db,reason=pcall(ns.Store.Restore,snapshot,P.scope)
    if not ok then return nil,"restore_failed" end
    return db,reason
end
function P.Open(saved)
    local state={db=assert(ns.Store.New(P.scope)),writable=false,root=saved,status="invalid_profile"}
    if saved==nil then
        state.root={formatVersion=1,scope="character-local",ledger=ns.Store.Snapshot(state.db),ui={tab=1},revision=0}
        state.writable=true;state.status="new";return state
    end
    if type(saved)~="table" then return state end
    if saved.formatVersion~=1 then state.status="unsupported_profile_version";return state end
    if saved.scope~="character-local" then state.status="scope_mismatch";return state end
    local db,reason=restore(saved.ledger)
    if not db then state.status=reason;return state end
    state.db=db;state.writable=true;state.status="restored"
    return state
end
function P.Checkpoint(state,preferences)
    if not state.writable then return false,"read_only" end
    local ok,db,reason=pcall(function() return ns.Store.Restore(ns.Store.Snapshot(state.db),P.scope) end)
    if not ok then return false,"snapshot_failed" end
    if not db then return false,reason end
    -- Replace only after full validation. Invalid runtime data cannot overwrite the last valid ledger.
    local snapshot=ns.Store.Snapshot(db)
    local ui=P.UI(preferences or state.root.ui)
    local revision=V.Integer(state.root.revision,0,9007199254740990) and state.root.revision or 0
    state.root.ledger=snapshot;state.root.ui=ui;state.root.revision=revision+1
    return true
end
