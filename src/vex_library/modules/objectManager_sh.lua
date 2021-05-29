local Pool = {
    counter = 0,
    objects = {}
}
Pool.__index = Pool

-- Object Handler struct, useful for doing stuff like limiting the amount of materials you can make
local Handler = {
    max = 80, -- Global number of objects max.
    maxply = 10,
    counter = 0, -- This is the total count, for all players combined
    checkpool = function(self,ply)
        if not self[ply] then self[ply] = setmetatable({},Pool) return self[ply],true end
        return self[ply]
    end,
    inc = function(self,ply,inc)
        -- Incrementing function to avoid repetitiveness, assumes there is a pool
        self.counter = self.counter + inc
        self[ply].counter = self[ply].counter + inc
    end,
    -- Returns false if it didn't push.
    set = function(self,ply,key,obj)
        local Pool = self:checkpool(ply)
        if Pool.objects[key] == nil then
            -- There is nothing at this key.
            if Pool.counter+1 > self.maxply then return false end
            if self.counter+1 > self.max then return false end
            self:inc(ply,1)
        end
        Pool.objects[key] = obj
        return true
    end,
    push = function(self,ply,obj)
        --if not IsValid(ply) or not ply:IsPlayer() then return end
        local Pool = self:checkpool(ply)
        if Pool.counter+1 > self.maxply then return false end
        if self.counter+1 > self.max then return false end
        table.insert(Pool.objects,obj)
        self:inc(ply,1)
        return true
    end,
    grab = function(self,ply,ind)
        -- Returns an object from a player's pool
        local Pool,DidNExist = self:checkpool(ply)
        if DidNExist then return end
        return Pool.objects[ind]
    end,
    -- Returns false if it did not remove.
    release = function(self,ply,keyOrObject)
        local Pool,DidNExist = self:checkpool(ply)
        if DidNExist then return false end
        local Objs = Pool.objects
        local Keyval = Objs[keyOrObject]
        if Keyval then
            if self.gc then self:gc(Objs,keyOrObject,Keyval) else Objs[keyOrObject] = nil end
            self:inc(ply,-1)
            return true
        else
            for key,val in pairs(Objs) do
                if val == keyOrObject then
                    -- Todo: Think of a better way to handle gc because this is fuckin terrible (maybe we don't even need it? probably not)
                    if self.gc then self:gc(Objs,keyOrObject,Keyval) else Objs[keyOrObject] = nil end
                    self:inc(ply,-1)
                    return true
                end
            end
        end
        return false
    end,
    count = function(self,ply)
        local Pool,DidNExist = self:checkpool(ply)
        if DidNExist then return 0 end
        return Pool.counter
    end,
    clear = function(self,ply)
        local Pool,DidNExist = self:checkpool(ply)
        local Objs = Pool.objects
        for K,V in pairs(Objs) do
            Objs[K] = nil
            self:inc(ply,-1)
        end
    end,
    kill = function(self,ply)
        -- Releases every object of a player's at once. Kills the pool.
        local Pool,DidNExist = self:checkpool(ply)
        if DidNExist then self[ply] = nil return end
        self.counter = self.counter - Pool.counter
        self[ply] = nil -- Delete the pool
    end,
    pop = function(self,ply)
        local Pool,DidNExist = self:checkpool(ply)
        if DidNExist then return end
        return Pool.objects[#Pool.objects]
    end,
    --gc = function(objects,key,val) objects[key] = nil end If we used this by default it'd be way slower..
}
Handler.__index = Handler

vex.objectManager = function(MaxGlobal,MaxPly,DeleteObject)
    if isstring(MaxPly) then
        -- If the max count is dependent on a convar, then put the convar name as the maxply variable.
        local o = setmetatable({max = MaxGlobal, maxply = GetConVar(MaxPly):GetInt(), gc = DeleteObject},Handler)
        vex.addChangeCallback(MaxPly,"vex_objectM_"..MaxPly,function(a,b,new)
            o.maxply = tonumber(new)
        end)
        return o
    else
        return setmetatable({max = MaxGlobal, maxply = MaxPly, gc = DeleteObject},Handler)
    end
end