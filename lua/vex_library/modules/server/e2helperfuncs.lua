-- E2HelperFuncs.lua in vex_library server modules.
-- This originally used to be the entire vex_library.. oh how far we've come :o

local printf = vex.printf
local isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction, getmetatable, pcall = isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction, getmetatable, pcall
local table_copy, table_IsEmpty, table_IsSequential = table.Copy, table.IsEmpty, table.IsSequential

-- Horrible hack
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
local Default_E2Tbl = vex.newE2Table()

-- Could technically make an 'expensive' arg that looks into the types of the keys, but if a table has these
-- specific keys, then they are malicious at this point.
vex.isE2Table = function(tbl)
    if not istable(tbl) then return false end
    for k in next,Default_E2Tbl do
        if not tbl[k] then return false end
    end
    return true
    -- Do a for loop in case the table structure changes in the future i guess
    -- Hardcoded version: if tbl.s and tbl.size and tbl.stypes and tbl.n and tbl.ntypes then return true end
end

-- Hardcoded e2 type guessing
vex.guessE2Type = function(var)
    if isnumber(var) or isbool(var) then return "n" end
    if istable(var) then
        -- E2 Tables will never be sequential.
        if table.IsEmpty(var) then return "r" end -- Potentially faster than depending on sequential doing a for loop that never executes?
        if table.IsSequential(var) then return "r" end -- Works for empty tables too
        if vex.isE2Table(var) then return "t" end
    end
end

-- This is a breaking change in terms of the lua code, getE2Type will now return the type id, like xco for the COROUTINE type.
-- Will need to change printGlobal and all other code that depends on it.
vex.getE2Type = function(val)
    local exactType = vex.guessE2Type(val)
    if exactType then return exactType end -- Has to be 100% sure.
    for TypeName,TypeData in pairs(wire_expression_types) do
        -- Every e2 registered type has a type-validating function, which is [6] in the typedata. It returns whether the object isn't type x.
        -- It isn't perfect, it just tells the compiler whether it is valid for functions of type x to use the object.
        local success,is_not_type = pcall(TypeData[6],val)
        -- We have to pcall it because some methods do things like :isValid which would error on numbers and strings.. etc :/
        if success and not is_not_type then
            return TypeData[1] -- Returns the type id.
        end
    end
end

-- Some variables need to be sanitized before we give them to e2. Like booleans will be turned to 1 or 0
-- We don't need to sanitize anything else like vectors or angles.
vex.sanitizeLuaVar = function(v)
    if isbool(v) then return v and 1 or 0 end
    return v
end


-- arrayOptimization detects if a lua table would fit as an e2 array (is sequential, and if so, returns the table untouched as an array type)
vex.luaTableToE2 = function(tbl,arrayOptimization)
    local output = vex.newE2Table()
    local n,ntypes = output.n,output.ntypes
    local s,stypes = output.s,output.stypes
    local size = 0
    for K,V in pairs(tbl) do
        local t,t_types
        if isnumber(K) then
            t,t_types = n,ntypes
        elseif isstring(K) then
            t,t_types = s,stypes
        else continue end -- Don't do non-string/number keys
        size = size + 1
        if istable(V) then
            t_types[K] = "t"
            if V == tbl then
                t[K] = output
            elseif arrayOptimization and table.IsSequential(V) then
                t[K],t_types[K] = V,"r"
            else
                t[K] = vex.luaTableToE2(V)
            end
        else
            t[K],t_types[K] = vex.sanitizeLuaVar(V),vex.getE2Type(V)
        end
    end
    output.size = size
    return output
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
