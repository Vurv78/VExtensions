-- E2HelperFuncs.lua in vex_library server modules.
-- This originally used to be the entire vex_library.. oh how far we've come :o


local printf = vex.printf

-- Fucking horrible hack
if not vex.persists.runs_on then
    vex.persists.runs_on = {}
end
local runs_on = vex.persists.runs_on
vex.tensions = {} -- E2 Extensions

vex.registerExtension = function(name,enabled,helpstr,...)
    vex.tensions[name] = {enabled,helpstr}
    E2Lib.RegisterExtension(name,enabled,helpstr,...)
end

vex.registerConstant = function(name, value, ...)
    -- This exists because E2Lib doesn't return a passed value, which can be handy (see selfaware2).
    E2Lib.registerConstant(string.upper(name), value)
    return value
end

vex.newE2Table = function() return {n={},ntypes={},s={},stypes={},size=0} end

local EMPTY_TABLE = vex.newE2Table()
local istable, type = istable, type
vex.isE2Table = function(tbl)
    if not istable(tbl) then return false end
    --if getmetatable(tbl) then return false end -- E2 table never has metatable attached. (Commented out for now.)
    for k,v in pairs(tbl) do
        local def = EMPTY_TABLE[k]
        if not def then return false end
        if type(v) ~= type(def) then return false end
    end
    return true
end

local isnumber, isstring, string_lower, table_IsSequential = isnumber, isstring, string.lower, table.IsSequential
vex.luaTableToE2 = function(tbl,arrayOptimization) -- TODO: Fix cyclic/infinite Lo0oP (see GMod's PrintTable code for reference).
    -- Note: Be very careful in this function. Some of the E2 functions are now relying on this to work like so.
    -- Let's try our best...
    local Strt = vex.newE2Table()
    local Sz = 0
    for Key,Value in pairs(tbl) do
        local TypeV = string_lower(type(Value))
        local WriteV
        local WriteType
        if isnumber(Key) then
            WriteV = Strt.n
            WriteType = Strt.ntypes
        elseif isstring(Key) then
            WriteV = Strt.s
            WriteType = Strt.stypes
        else -- Nope.
            continue
        end
        local Clean = Value
        if     isbool  (Value) then Clean = Value and 1 or 0          TypeV = "n"
        elseif isangle (Value) then Clean = {Value.p,Value.y,Value.r}
        elseif isvector(Value) then Clean = {Value.x,Value.y,Value.z}
        -- TODO: Color, Vector2/Vector4, Matrix*...
        elseif isentity(Value) then TypeV = "e" -- isentity includes every type of Entity (Player, NPC, Vehicle, Weapon, etc.)
        elseif TypeV=="thread" then Clean = "xco" -- MYTODO: Verify this, probably not the right way... check the type's [6] as in getE2Type?
        elseif istable (Value) then
            if getmetatable(Value) then continue end -- Nope.
            if not vex.isE2Table(Value) then -- Important: Only do this stuff if it is not an E2 table.
                if arrayOptimization and table_IsSequential(Value) then
                    TypeV = "r"
                else
                    Clean = vex.luaTableToE2(Value,arrayOptimization)
                end
            end
        elseif isnumber(Value) or isstring(Value) then
            -- This check is needed to allow number and string to pass. (Just do nothing here.)
        else -- If it is none of the above, then it is probably unsupported.
            continue -- So we skip this value (probably a function, userdata, etc...)
        end
        Sz = Sz + 1
        WriteV[Key] = Clean
        local TypeFirstChar = TypeV:sub(1, 1)
        WriteType[Key] = TypeFirstChar == "x" and TypeV:sub(1, 3) or TypeFirstChar
    end
    Strt.size = Sz
    return Strt
end

-- Note: This is terrible
vex.getE2Type = function(val)
    local e2types = wire_expression_types
    for TypeName,TypeData in pairs(e2types) do
        if istable(val) then
            -- These are incredibly hacky but they work
            if vex.isE2Table(val) then return "TABLE" end -- At least this one is more accurate now.
            if #val == 3 and isnumber(val[1]) and isnumber(val[2]) and isnumber(val[3]) then return "VECTOR" end -- It could also be an Angle (or an array with 3 numbers).
            return "ARRAY"
        end
        local success,isnottype = pcall(TypeData[6],val) -- We have to pcall it because some methods do things like :isValid which would error on numbers and strings.. etc
        if success and not isnottype then return TypeName end
    end
    return "UNKNOWN"
end

vex.listenE2Hook = function(context,id,dorun)
    if not runs_on[id] then runs_on[id] = {} end
    if not context or not IsValid(context.entity) then return end
    runs_on[id][context.entity] = dorun and true or nil
end

vex.e2DoesRunOn = function(context,id)
    if not runs_on[id] then return end -- VEx hooks didn't save? Shouldn't happen anymore
    if not context or not IsValid(context.entity) then return end
    return runs_on[id][context.entity]
end


vex.callE2Hook = function(id,callback,...)
    -- Executes all of the chips in the e2 hook.
    local runs = runs_on[id]
    for chip in pairs(runs) do
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

vex.didE2RunOn = function(context,id)
    return context.data["vex_ran_by_" .. id] and 1 or 0
end

vex.createE2Hook = function(hookname,id,callback)
    runs_on[id] = {}
    hook.Add(hookname,id,function(...)
        local runs = runs_on[id]
        if not runs then return end
        local arg = {...}
        vex.callE2Hook(id,function(chip,before)
            callback(chip,before,unpack(arg))
            chip.context.data["vex_ran_by_"..id] = before or nil
        end)
    end)
end


local E2FuncNamePattern = "^([a-z][a-zA-Z0-9_]*)%("
local string_match = string.match
vex.getE2UDF = function(compiler, funcname)
    local funcs = compiler.funcs
    local e2func = funcs[funcname]
    if e2func then
        return e2func, true -- Direct/Full match.
    end
    -- Look for any UDF that has the same name (before the parenthesis).
    funcname = string_match(funcname, E2FuncNamePattern) or funcname
    for name, fn in pairs(funcs) do
        local proper = string_match(name, E2FuncNamePattern)
        if proper == funcname then
            return fn, false -- Name only match.
        end
    end
end

vex.getE2Func = function(compiler, funcname, returnTable)
    local funcs = wire_expression2_funcs
    local e2func = funcs[funcname]
    if e2func then
        return returnTable and e2func or e2func[3], true -- Direct/Full match.
    end
    -- Look for any builtin function that has the same name (before the parenthesis).
    funcname = string_match(funcname, E2FuncNamePattern) or funcname
    for name, data in pairs(funcs) do
        local proper = string_match(name, E2FuncNamePattern)
        if proper == funcname then
            return returnTable and data or data[3], false -- Name only match.
        end
    end
end