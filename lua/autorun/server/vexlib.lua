-- VEX Library.
-- We will store our global functions here to help us with extension creation
-- Some examples of things that could be made are functions to return the e2 type of a variable, etc.


local function init()
    if vex then
        -- Garbage collecting / Hook removal
        print("Deleting VEX hooks!")
        for eventName,identifier in pairs(vex.collecthooks) do
            --print("Deleted hook .. " .. identifier)
            hook.Remove(eventName,identifier)
        end
    end

    vex = {
        collecthooks = {},
        runs_on = {}
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
<<<<<<< HEAD

    vex.listenE2Hook = function(context,id,dorun)
        if not vex.runs_on[id] then vex.runs_on[id] = {} end
        vex.runs_on[id][context.entity] = dorun and true or nil
    end

    -- Callback is called before and after the e2 chip is executed.
    -- function callback(chip,ranBefore)
    vex.createE2Hook = function(hookname,id,callback)
        vex.runs_on[id] = {}
        vex.collecthooks[hookname] = id -- TODO: Turn this into a table so we can have more than one hook for whatever reason anyone would need that.
        hook.Add(hookname,id,function(...)
            local runs = vex.runs_on[id]
            if not runs then return end
            for chip,_ in pairs(runs) do
                if not chip or not IsValid(chip) then
                    runs[chip] = nil
                else
                    if callback then callback(chip,true,...) end
                    chip.context.data["vex_ran_by_" .. id] = true
                    chip:Execute()
                    chip.context.data["vex_ran_by_" .. id] = nil
                    if callback then callback(chip,false,...) end
                end
            end
        end)
    end

    -- Use this to return whether an e2 chip was run by vex [id]
    vex.didE2RunOn = function(context,id)
        return context.data["vex_ran_by_" .. id] and 1 or 0
    end

    print("VEx loaded, thanks for installing!")
    print("All of the e2 modules are disabled by default, enable them with wire_expression2_extension_enable <printGlobal/coroutinecore>")
end

concommand.Add("vex_reload",function()
    init()
    print("Reloaded the VExtensions library, you may need to wire_expression2_reload for hooks to reload properly.")
end)

init()
