local _,ns=...
local R={version=2,window=3600};ns.BountyRules=R
-- Compute only from the immutable incident set selected by a claim. Arrival order
-- and later observations cannot change a historical reward.
function R.Calculate(incidents)
    local victims={}
    for _,row in ipairs(incidents)do
        local key=row.enemy.id.."\0"..row.victim.id
        victims[key]=victims[key] or {};table.insert(victims[key],row.occurredAt)
    end
    local reward,largest=0,1
    for _,times in pairs(victims)do
        table.sort(times);local first,peak=1,0
        for last,time in ipairs(times)do
            while time-times[first]>=R.window do first=first+1 end
            peak=math.max(peak,last-first+1)
        end
        local multiplier=math.floor(2^math.floor(peak/3))
        local amount=#times*ns.Config.reputationPerIncident*multiplier
        if amount>9007199254740991-reward then return nil,nil,"reward_limit" end
        reward=reward+amount;largest=math.max(largest,multiplier)
    end
    return reward,largest
end
