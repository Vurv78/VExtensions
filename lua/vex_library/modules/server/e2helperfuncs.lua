-- Helper functions for use in e2 modules / mini-extensions.
-- Helps you create e2 hooks, tables, etc

local printf = vex.printf
local isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction = isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction
local getmetatable, pcall, IsValid = getmetatable, pcall, IsValid

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

vex.registerConstant = function(name, value)
    -- This exists because E2Lib doesn't return a passed value, which can be handy (see selfaware2).
    E2Lib.registerConstant(string.upper(name), value) -- Upper shouldn't be used a lot
    return value
end

vex.newE2Table = function() return {n={},ntypes={},s={},stypes={},size=0} end
local Default_E2Tbl = vex.newE2Table()

-- Returns whether a table is numerically indexed and if it doesn't contain any other tables inside of it.
-- Taxing, this is why we will have the arrayOptimization / checkForArrays arg
local function validArray(tbl,max)
    local i = 1
    max = max or 5000 -- Is this a good limit to the size of a table to infer of being an array?
    for K,V in pairs(tbl) do
        -- Check if there's any tables in the table
        if istable(V) then return false end
        -- IsSequential Check
        if tbl[i] == nil then return false end
        if i >= max then return false end
        i = i + 1
    end
    return true
end
vex.isE2Array = validArray

-- Allows to very accurately determine whether the given argument has a valid E2 table structure (presence of table fields/keys).
-- However, it does not validate inner contents (it is assumed to not be malformed inside).
vex.isE2Table = function(tbl,accurateCheck)
    if not istable(tbl) then return false end
    if accurateCheck then
        -- We perform very accurate checks. (Do not change this code!)
        -- This can't be made any faster *and* accurate than it is.
        if getmetatable(tbl) then return false end -- E2 table shouldn't have metatable attached to it.
        -- This loop does 6 iterations at most, at 6th it will stop too.
        for k in next,tbl do -- We have to be sure, so we loop over the given tbl -- not over the default E2 tbl.
            -- We still stop the loop as soon as possible (if the key doesn't exist in default).
            if not Default_E2Tbl[k] then return false end -- < Therefore performance is not an issue.
        end
        return true
    end
    -- We perform less reliable (this is just a tiny bit faster than the accurate check, saving 1 table lookup):
    return tbl.s and tbl.size and tbl.stypes and tbl.n and tbl.ntypes and true or false
end

-- For now, we'll wrap everything that needs to be sanitized by default i guess?
-- We will sanitize everything inside of here to avoid the cancer what was in sanitizeLuaVar before.
local function getVarTypeAndSanitize(v,checkForArrays)
    -- If we're gonna sanitize userdata like angles and vectors, should we clone tables found?
    if isnumber(v) then return "n" end
    if isbool(v) then return "n", true end -- Returning an additional true, to indicate it must be sanitized (using `vex.sanitizeLuaVar`).
    if isstring(v) then return "s" end
    if isentity(v) then return "e" end
    if isangle(v) then return "a",{v[1],v[2],v[3]} end -- By default, requires wrapping to prevent reference modification.
    if isvector(v) then return "v",{v[1],v[2],v[3]} end
    if IsValid(v) and type(v)=="PhysObj" then return "b" end -- Optimize into E2 `bone`.
    if istable(v) then
        if IsColor(v) then return "t",{v.r,v.g,v.b,v.a} end -- Should this be vector4 or array or table..
        if getmetatable(v) then return end -- Most likely we don't want this to be passed to the E2.
        if checkForArrays and validArray(v) then return "r" end
        return "t" -- Just return it as a table type (we are not going to validate contents)
    end
    -- Unsupported; Returning no value. Use the `vex.getE2Type` function if you need to check for official/3rd-party types.
end

-- Ret: typeid, typename
vex.getE2Type = function(val,checkForArrays)
    local inferred_type, sanitizedVar = getVarTypeAndSanitize(val,checkForArrays)
    if inferred_type then return inferred_type, sanitizedVar end -- Has to be 100% sure.

    -- This is mostly for custom-types that are added by addons like for effect core, coroutine core..
    for TypeName,TypeData in pairs(wire_expression_types) do
        -- Every e2 registered type has a type-validating function, which is [6] in the typedata. It returns whether the object isn't type x.
        -- It isn't perfect, it just tells the compiler whether it is valid for functions of type x to use the object.
        local success,is_not_type = pcall(TypeData[6],val)
        -- We have to pcall it because some methods do things like :isValid which would error on numbers and strings.. etc :/
        if success and not is_not_type then
            TypeName = wire_expression_types2[TypeData[1]][1]
            -- Returns TypeID. If you want the type name, do "TypeName = wire_expression_types2[TypeID][1]"
            return TypeData[1]
        end
    end
end

-- arrayOptimization detects if a lua table would fit as an e2 array (if sequential, returns the table untouched as an array type)
-- if we checkForArrays, we will check if a lua table is valid to fit as an e2 array.
-- This would lead to some inconsistencies if we deal with a table that may or may not contain a non-numeric index / a table.
-- Therefore, we DO need to keep the arrayOptimization variable, in order to make sure that the end e2 user can consistently index a table correctly.
vex.luaTableToE2 = function(tbl,checkForArrays)
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
        if istable(V) then
            t_types[K] = "t"
            if V == tbl then
                t[K] = output
            elseif checkForArrays and validArray(V) then
                t[K],t_types[K] = V,"r"
            else
                t[K] = vex.luaTableToE2(V,checkForArrays)
            end
        else
            local v_type,sanitized = vex.getE2Type(V)
            if v_type then
                -- We could do sanitized or V, but then if V was 'false' it wouldn't work
                t[K],t_types[K] = Either(sanitized,sanitized,V),v_type
            else continue end -- Skip! We surely don't want this value in E2 table, filter it out. (Not in 'whitelist')
        end
        size = size + 1
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

-- TODO: Get rid of the compiler arg in the second pr, we don't use it here
-- Maybe the compiler stores it's functions in runtime though? I doubt e2 has support for some e2's having (builtin) functions that others don't.

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
