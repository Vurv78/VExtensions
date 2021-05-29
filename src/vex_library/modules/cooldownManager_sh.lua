local CooldownManager = {
    timer = 0.25, -- Global cooldown
    timerply = 1, -- Player cooldown
    lastg = 0
}

CooldownManager.__index = CooldownManager

function CooldownManager:available(ply)
    local ct = CurTime()
    if IsValid(ply) and ply:IsPlayer() then
        if ct<((self.lasts[ply] or 0)+self.timerply) then return false end
    end
    return ct>self.lastg+self.timer
end

function CooldownManager:use(ply)
    if not self:available(ply) then return false end
    local ct = CurTime()
    if IsValid(ply) and ply:IsPlayer() then
        self.lasts[ply] = ct
    end
    self.lastg = ct
    return true
end

-- Todo: Investigate whether this could actually lag the server if an e2 ends up spamming it. Simple test with while(perf()) and destroying a webmaterial didn't seem to cause any lag.

-- Function to run a function when the cooldown manager is available.
function CooldownManager:queue(ply,func)
    if not self:use(ply) then
        timer.Simple(self.timerply+0.1,function()
            self:queue(ply,func)
        end)
        return
    end
    func()
end


vex.cooldownManager = function(n)
    return setmetatable({timerply = n, lasts = {}},CooldownManager)
end