--[[
 _    ________        __    _ __                         
| |  / / ____/  __   / /   (_) /_  _________ ________  __
| | / / __/ | |/_/  / /   / / __ \/ ___/ __ `/ ___/ / / /
| |/ / /____>  <   / /___/ / /_/ / /  / /_/ / /  / /_/ / 
|___/_____/_/|_|  /_____/_/_.___/_/   \__,_/_/   \__, /  
                                                /____/   
]]
-- We will store our global functions here to help us with extension creation
-- Some examples of things that could be made are functions to return the e2 type of a variable, etc.
-- E2 Hook creators, E2 limiters / resource handlers just like how SF uses them.

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
        if not Pool.objects[key] then
            -- There is nothing at this key.
            if Pool.counter+1 > self.maxply then return false end
            if self.counter+1 > self.max then return false end
            self:inc(ply,1)
            Pool.objects[key] = obj
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
    releaseply = function(self,ply)
        -- Releases every object of a player's at once. Does not call the garbage collector
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

local CooldownManager = {
    timer = 1,
    last = 0
}
CooldownManager.__index = CooldownManager

function CooldownManager:available()
    return CurTime()>(self.last+self.timer)
end

function CooldownManager:use()
    if not self:available() then return end
    self.last = CurTime()
    return true
end

local function printf(...)
    print(string.format(...))
end

local function init()
    local toconstruct
    local todestruct
    if vex then
        -- Destructors
        print("Calling vex destructors")
        for callback in next,vex.to_destruct do
            callback()
        end
        for eventName,identifier in pairs(vex.collecthooks) do
            --print("Deleted hook .. " .. identifier)
            hook.Remove(eventName,identifier)
        end
        toconstruct = vex.to_construct
        todestruct = vex.to_destruct
    end

    vex = {
        collecthooks = {},
        runs_on = {},
        to_construct = toconstruct or {},
        to_destruct = to_destruct or {},
        tensions = {} -- vex.tensions
    }

    -- Note: This is terrible
    vex.getE2Type = function(val)
        local e2types = wire_expression_types
        for TypeName,TypeData in pairs(e2types) do
            if type(val) == "table" then
                -- Yeah fuck addons like tracesystem returning redundant tables that literally only check the type..
                -- These are incredibly hacky but they work
                if val.size then return "TABLE" end
                if #val == 3 and isnumber(val[1]) and isnumber(val[2]) and isnumber(val[3]) then return "VECTOR" end
                return "ARRAY"
            end
            local success,isnottype = pcall(TypeData[6],val) -- We have to pcall it because some methods do things like :isValid which would error on numbers and strings.. etc
            if success and not isnottype then return TypeName end
        end
        return "UNKNOWN"
    end

    vex.listenE2Hook = function(context,id,dorun)
        if not vex.runs_on[id] then vex.runs_on[id] = {} end
        vex.runs_on[id][context.entity] = dorun and true or nil
    end

    vex.e2DoesRunOn = function(context,id)
        return vex.runs_on[id][context.entity]
    end

    vex.callE2Hook = function(id,callback,...)
        -- Executes all of the chips in the e2 hook.
        local runs = vex.runs_on[id]
        for chip,_ in pairs(runs) do
            if not chip or not IsValid(chip) then
                runs[chip] = nil
            else
                if not callback or not isfunction(callback) then return end
                callback(chip,true,...)
                chip:Execute()
                callback(chip,false,...)
            end
        end
    end

    -- Callback is called before and after the e2 chip is executed.
    -- function callback(chip,ranBefore)
    vex.createE2Hook = function(hookname,id,callback)
        vex.runs_on[id] = {}
        vex.collecthooks[hookname] = id -- TODO: Turn this into a table so we can have more than one hook for whatever reason anyone would need that.
        hook.Add(hookname,id,function(...)
            local runs = vex.runs_on[id]
            if not runs then return end
            local arg = {...}
            vex.callE2Hook(id,function(chip,before)
                callback(chip,before,unpack(arg))
                chip.context.data["vex_ran_by_"..id] = before or nil
            end)
        end)
    end

    -- Use this to return whether an e2 chip was run by vex [id]
    vex.didE2RunOn = function(context,id)
        return context.data["vex_ran_by_" .. id] and 1 or 0
    end

    -- So we can have external VEX functions reload properly with vex_reload.
    vex.constructor = function(construct)
        vex[construct] = true
        construct()
    end

    vex.destructor = function(destruct)
        vex[destruct] = true
    end

    vex.addNetString = function(str)
        -- Todo: Put these in a list and add a convar to list them, or something.
        local name = "VEx_Net_"..str
        util.AddNetworkString(name)
    end

    vex.netReceive = function(str,callback)
        local name = "VEx_Net_"..str
        net.Receive(name,callback)
        vex.destructor(function()
            net.Receive(name)
        end)
    end

    vex.netStart = function(str)
        net.Start("VEx_Net_"..str)
    end

    vex.registerExtension = function(name,enabled,helpstr,...)
        vex.tensions[name] = {enabled,helpstr}
        E2Lib.RegisterExtension(name,enabled,helpstr,...)
    end

    vex.addConsoleCommand = function(name,callback,a,b,c,d,e,f,g)
        -- Will prefix every vex concmd with vex_, so you can easily just 'find vex_'
        -- The suffix should also be _sv
        local extended_name = "vex_"..name.."_sv"
        --vex.concmds[extended_name] = callback
        concommand.Add(extended_name,callback,a,b,c,d,e,f,g)
    end

    -- Like the regular function, but automatically cleans up when vex is reloaded.
    vex.addChangeCallback = function(name,callback)
        cvars.AddChangeCallback(name,callback,"vex_objectmanager")
        vex.destructor(function()
            cvars.RemoveChangeCallback(name,"vex_objectmanager")
        end)
    end

    -- Cool idea from starfallex
    vex.objectManager = function(MaxGlobal,MaxPly,DeleteObject)
        if isstring(MaxPly) then
            -- If the max count is dependent on a convar, then put the convar name as the maxply variable.
            local o = setmetatable({max = MaxGlobal, maxply = GetConVar(MaxPly):GetInt(), gc = DeleteObject},Handler)
            vex.addChangeCallback(MaxPly,function(a,b,new)
                o.maxply = tonumber(new)
            end)
        else
            return setmetatable({max = MaxGlobal, maxply = MaxPly, gc = DeleteObject},Handler)
        end
    end

    vex.cooldownManager = function()
        return setmetatable({timer = n},CooldownManager)
    end

    print("Calling vex constructors")
    for callback in next,toconstruct do
        Func()
    end
end

init()

vex.addConsoleCommand("reload",function()
    init()
    print("Reloaded the VExtensions library and the e2 library!")
    wire_expression2_reload()
end,nil,"Reloads the vextensions library and runs wire_expression2_reload.")

print("VExtensions loaded!")
print("Most of the e2 modules are disabled by default, enable them with wire_expression2_extension_enable <printGlobal/coroutinecore>")
