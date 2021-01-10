-- Helper functions for use in e2 modules / mini-extensions.
-- Helps you create e2 hooks, tables, etc

local printf = vex.printf
local isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction = isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction
local getmetatable, pcall, IsValid = getmetatable, pcall, IsValid
local error = error
local string, string_format = string, string.format

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

-- Throws an error to the currently running e2 chip.
vex.throw = function(...)
    error( string_format(...), 0)
end

vex.newE2Table = function() return {n={},ntypes={},s={},stypes={},size=0} end
local Default_E2Tbl = vex.newE2Table()

-- Screw this anyways.
--[[local function better_validArray(tbl)
    if not istable(tbl) then return false end
    for k,v in pairs(tbl) do
        if not isnumber(k) then return false end -- E2 array cannot have non-number index.
        if istable(v) then
            if IsColor(v) then tbl[k] = {v.r,v.g,v.b,v.a} -- Color as Vector4/array
            elseif v.HitPos then -- Ranger/Trace data
                -- Do nothing.
            else
                return false -- Anything else is a no-no
            end
        end
    end
    return true
end]]

-- Returns whether a table is numerically indexed and if it doesn't contain any other tables inside of it.
-- Taxing, this is why we will have the arrayOptimization / checkForArrays arg
-- typeOf makes sure all elements in an array will be of lua type _.
local function validArray(tbl,max,typeOf)
    if not istable(tbl) then return false end
    local i,max,type_check = 1,max or 5000, isstring(typeOf)
    for K,V in pairs(tbl) do
        -- Check if there's any tables in the table
        if istable(V) then return false end
        if type_check and type(V) ~= typeOf then return false end
        -- IsSequential Check
        if tbl[i] == nil then return false end
        if i >= max then return false end
        i = i + 1
    end
    return true
end
vex.isE2Array = validArray -- more like "can be E2 Array"

-- Allows to very accurately determine whether the given argument has a valid E2 table structure (presence of table fields/keys).
-- However, it does not validate inner contents (it is assumed to not be malformed inside).
vex.isE2Table = function(tbl,accurateCheck)
    if not istable(tbl) then return false end
    if accurateCheck then
        -- We perform very accurate checks. (Do not change this code!)
        -- This can't be made any faster *and* accurate than it is.
        if getmetatable(tbl) then return false end -- E2 table shouldn't have metatable attached to it.
        -- This loop does 6 iterations at most, at 6th it will stop too.
        for k in next,tbl do
            if not Default_E2Tbl[k] then return false end -- < Therefore performance is not an issue.
        end
        return true
    end
    -- We perform less reliable (this is just a tiny bit faster than the accurate check, saving 1 table lookup):
    return tbl.s and tbl.size and tbl.stypes and tbl.n and tbl.ntypes and true or false
end

-- For now, we'll wrap everything that needs to be sanitized by default i guess?
local function getVarTypeAndSanitize(v,checkForArrays)
    -- If we're gonna sanitize userdata like angles and vectors, should we clone tables found?
    if isnumber(v) then return "n" end
    if isbool(v) then return "n", v and 1 or 0 end
    if isstring(v) then return "s" end
    if isentity(v) then return "e" end
    if isangle(v) then return "a",{v[1],v[2],v[3]} end
    if isvector(v) then return "v",{v[1],v[2],v[3]} end
    if type(v)=="PhysObj" then return "b" end -- No IsValid check because that would index userdata. This caused lua errors when sanitizing something like a coroutine
    if istable(v) then
        if IsColor(v) then return "xv4",{v.r,v.g,v.b,v.a} end -- This should be either Vector4 or Array (or Matrix2); any is fine.
        if v.HitPos then return "xrd" end -- Ranger/Trace data
        if getmetatable(v) then return end -- Most likely we don't want this to be passed to the E2.
        if checkForArrays and validArray(v) then return "r" end
        return "t" -- Just return it as a table type (we are not going to validate contents)
    end
    -- Unsupported; Returning no value. Use the `vex.getE2Type` function if you need to check for official/3rd-party types.
end

local wire_types = wire_expression_types
vex.getE2Type = function(val,checkForArrays)
    local inferred_type, sanitizedVar = getVarTypeAndSanitize(val,checkForArrays)
    if inferred_type then return inferred_type, sanitizedVar end -- Has to be 100% sure.
    -- This is mostly for custom-types that are added by addons like for effect core, coroutine core..
    for TypeName,TypeData in pairs(wire_types) do
        local validator = TypeData[index]
        if validator then
            local success,is_not_type = pcall(validator,value)
            if success and not is_not_type then
                return TypeData[1]
            end
        end
    end
end


-- Should avoid checking for arrays, since it might lead to inconsistencies with tables being inferred as arrays or tables depending on their contents.
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
            else
                -- So we can see if the table is actually xrd or an array.
                local inferred_type,sanitized = vex.getE2Type(V,checkForArrays)
                if inferred_type then
                    t[K],t_types[K] = sanitized or V, inferred_type
                else
                    t[K] = vex.luaTableToE2(V,checkForArrays)
                end
            end
        else
            local v_type,sanitized = vex.getE2Type(V)
            if v_type then
                t[K],t_types[K] = sanitized or V,v_type
            else continue end -- Skip! We surely don't want this value in E2 table, filter it out. (Not in 'whitelist')
        end
        size = size + 1
    end
    output.size = size
    return output
end

-- Moved from rune2
-- Builds a body to run an e2 udf and pass args to it.
-- TODO: Probably want to use type inferrence with this so we don't have to provide types in the table (and could turn this into a vararg function)
local table_insert = table.insert
vex.buildBody = function(args)
    local body = {
        false -- No idea what this does, but it is necessary
    }
    local types = {}
    for Type,Value in pairs(args) do
        table_insert(body,{
            [1] = function() return Value end,
            ["TraceName"] = "LITERAL"
        })
        table_insert(types,Type)
    end
    table_insert(body,types)
    return body
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
local E2SignaturePattern = E2FuncNamePattern .. "(.*)%)$"
local string_match = string.match
vex.getE2UDF = function(compiler, funcName, expectedReturnType, expectedArgTypes)
    local funcs, funcs_ret = compiler.funcs, compiler.funcs_ret
    local e2func = funcs[funcName]
    if e2func then
        local returnType = funcs_ret[funcName]
        -- Optionally, validate the return type is of the expected type (ID).
        if expectedReturnType and returnType ~= expectedReturnType then
            -- Since this is direct match, we exit here because UDF can't have overloaded a return type on this signature.
            --[[ In other words, E2 does not allow this:
                function number myFunc() { return 1 }
                function string myFunc() { return "" }
            ]]
            return -- Stop here because the return type didn't match.
        end
        -- Optionally, validate whether argument types matches the expectation.
        if expectedArgTypes then
            local _, argTypes = string_match(funcName, E2SignaturePattern)
            if argTypes ~= expectedArgTypes then
                return
            end
        end
        return e2func, true, returnType -- Direct/Full match.
    end
    -- Look for any UDF that has the same name (before the parenthesis).
    funcName = string_match(funcName, E2FuncNamePattern) or funcName
    for signature, fn in pairs(funcs) do
        local name, argTypes = string_match(signature, E2SignaturePattern)
        if name == funcName then
            local returnType = funcs_ret[signature]
            if expectedReturnType and returnType ~= expectedReturnType then
                --[[ In this case, since we are doing name-only matching we just skip it. Because E2 does allow this:
                    function number myFunc(N) { return N }
                    function string myFunc(S:string) { return S }
                ]]
                continue
            end
            if expectedArgTypes and argTypes ~= expectedArgTypes then
                continue -- Skip this overload, doesn't match the expected argument types.
            end
            return fn, false, returnType -- Name-only match.
        end
    end
end

local string_sub = string.sub
vex.getE2Func = function(funcName, returnTable, skipOperatorFunctions)
    local funcs = wire_expression2_funcs
    local e2func = funcs[funcName]
    if e2func then
        return returnTable and e2func or e2func[3], true -- Direct/Full match.
    end
    -- Look for any builtin function that has the same name (before the parenthesis).
    funcName = string_match(funcName, E2FuncNamePattern) or funcName
    if skipOperatorFunctions then -- For faster execution time, checked once, instead of all the time within loop.
        for signature, data in pairs(funcs) do
            if string_sub(signature, 1, 3) == "op:" then
                continue -- Skip operator functions.
            end
            local proper = string_match(signature, E2FuncNamePattern)
            if proper == funcName then
                return returnTable and data or data[3], false -- Name-only match.
            end
        end
    else
        for signature, data in pairs(funcs) do
            local proper = string_match(signature, E2FuncNamePattern)
            if proper == funcName then
                return returnTable and data or data[3], false -- Name-only match.
            end
        end
    end
end