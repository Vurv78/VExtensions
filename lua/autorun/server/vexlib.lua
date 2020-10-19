-- VEX Library.
-- We will store our global functions here to help us with extension creation
-- Some examples of things that could be made are functions to return the e2 type of a variable, etc.


local function init()
    vex = {}
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
    print("VEx loaded, thanks for installing!")
    print("All of the e2 modules are disabled by default, enable them with wire_expression2_extension_enable <printGlobal/coroutinecore>")
end

concommand.Add("vex_reload",init)

init()
