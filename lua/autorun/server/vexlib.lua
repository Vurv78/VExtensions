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

local function printf(...)
    print(string.format(...))
end

local function init()
    local toconstruct
    if vex then
        -- Garbage collecting / Hook removal
        print("Deleting VEX hooks!")
        for eventName,identifier in pairs(vex.collecthooks) do
            --print("Deleted hook .. " .. identifier)
            hook.Remove(eventName,identifier)
        end
        toconstruct = vex.to_construct
    end

    vex = {
        collecthooks = {},
        runs_on = {},
        to_construct = toconstruct or {}
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
        return "unknown"
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
        vex.to_construct[#vex.to_construct+1] = construct
        construct()
    end

    print("Loading constructors")
    local C = #toconstruct
    for K,Func in pairs(toconstruct) do
        printf("Loading VEx Constructor (%d/%d)",K,C)
        Func()
    end
end

concommand.Add("vex_reload",function()
    init()
    print("Reloaded the VExtensions library and the e2 library!")
    wire_expression2_reload()
end,nil,"Reloads the vextensions library and runs wire_expression2_reload.")

init()

print("VExtensions loaded!")
print("Most of the e2 modules are disabled by default, enable them with wire_expression2_extension_enable <printGlobal/coroutinecore>")