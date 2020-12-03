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
    if not istable(tbl) or getmetatable(tbl) then return false end
    for k in next,Default_E2Tbl do
        if not tbl[k] then return false end
    end
    return true
    -- Do a for loop in case the table structure changes in the future i guess
    -- Hardcoded version: if tbl.s and tbl.size and tbl.stypes and tbl.n and tbl.ntypes then return true end
end

-- Hardcoded e2 type guessing. (Not sure why are these made out as global functions now?)
vex.guessE2Type = function(v)
    if isnumber(v) or isbool(v) then return "n" end
    if isstring(v) then return "s" end
    if isentity(v) then return "e" end
    if isangle(v) then return "a" end -- But must be sanitized.
    if isvector(v) then return "v" end -- But must be sanitized.
    if IsColor(v) then return "xv4" end -- But must be sanitized.
    if istable(v) then
        if getmetatable(v) then return end -- Most likely we don't want this to be passed to the E2.
        -- E2 Tables will never be sequential.
        if table_IsEmpty(v) then return "r" end -- Potentially faster than depending on sequential doing a for loop that never executes?
                                                -- Huh, not sure about that. Well if the table is empty, it will never go into the loop at all.
                                                -- So, is this extra call+branch worth the performance? I doubt it is.
                                                -- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/table.lua#L180
        if table_IsSequential(v) then return "r" end -- Works for empty tables too
        if vex.isE2Table(tbl) then return "t" end -- Why not just directly return "t" at this point tho?
    elseif type(v)=="thread" then return "xco" end -- Assuming coroutine core is enabled.
end

vex.getE2Type = function(val)
    local guessedType = vex.guessE2Type(val)
    if guessedType then return guessedType end -- Has to be 100% sure.
    for TypeName,TypeData in pairs(wire_expression_types) do
        -- Every e2 registered type has a type-validating function, which is [6] in the typedata. It returns whether the object isn't type x.
        -- It isn't perfect, it just tells the compiler whether it is valid for functions of type x to use the object.
        local success,is_not_type = pcall(TypeData[6],val)
        -- We have to pcall it because some methods do things like :isValid which would error on numbers and strings.. etc :/
        if success and not is_not_type then
            return wire_expression_types2[TypeData[1]][1] -- Returns the type name (uppercased).
        end
    end
end

-- Some variables need to be sanitized before we give them to e2. Like booleans will be turned to 1 or 0
-- ~~We don't need to sanitize anything else like vectors or angles.~~
-- But we actually do need to, because they are sequential array in the E2. And also because this is a global function.
-- Also why not make this return type ID along with the value, instead of having functions split apart (guessE2Type)?
vex.sanitizeLuaVar = function(v)
    if isnumber(v) or isstring(v) then return v end -- These are fine, pass them as is.
    if isbool(v) then return v and 1 or 0 end -- Convert a boolean into either 1 or 0.
    if isangle(v) then return {v.p,v.y,v.r} end -- GLua Angle in the E2 is implemented as sequential array with 3 numbers,
    if isvector(v) then return {v.x,v.y,v.z} end -- Same for GLua Vector.
    if IsColor(v) then return {v.r,v.g,v.b,v.a} end -- Optimize out into Vector4 (for use with entity:setColor(xv4) function)
    if type(v)=="thread" then return v end -- Assuming coroutine core is enabled.
    --if isfunction(v) then return end -- Nope.
    -- It is a bad idea to return v; This shouldn't be returning v unless it is ok with E2!
    -- This function should work as *whitelist* rather than *blacklist*. Therefore we return nothing here, that is a nil value.
end


-- arrayOptimization detects if a lua table would fit as an e2 array (if sequential, returns the table untouched as an array type)
vex.luaTableToE2 = function(tbl,arrayOptimization)
    if vex.isE2Table(tbl) then return tbl end
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
            elseif arrayOptimization and table_IsSequential(V) then
                t[K],t_types[K] = V,"r"
            else
                t[K] = vex.luaTableToE2(V,arrayOptimization)
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
