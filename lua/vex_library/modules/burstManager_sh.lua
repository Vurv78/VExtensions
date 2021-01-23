

-- Should be ratios of uses in a second.
local BurstManager = {
    ups = 1 -- 1 use per second per player by default
}

BurstManager.__index = BurstManager
setmetatable(BurstManager,{
    __call = function( _, uses_per_second )
        return setmetatable({
            ups = uses_per_second,
            plys = {}
        },BurstManager)
    end
})

function BurstManager:getdata( ply )
    local pdata = self[ply]
    if not pdata then
        self[ply] = { last_used = 0, uleft = self.ups }
        return self[ply]
    end
    return pdata
end

function BurstManager:uses_left( ply )
    return self:getdata( ply ).uleft
end

function BurstManager:available( ply )
    return self:getdata( ply ).uleft ~= 0
end

function BurstManager:use( ply )
    local now,pdata = CurTime(),self:getdata( ply )
    if now - pdata.last_used > 1 then
        pdata.uleft = self.ups-1
        pdata.last_used = now
        return true
    else
        if pdata.uleft > 0 then
            pdata.uleft = pdata.uleft - 1
            pdata.last_used = now
            return true
        else
            return false
        end
    end
end

vex.burstManager = BurstManager