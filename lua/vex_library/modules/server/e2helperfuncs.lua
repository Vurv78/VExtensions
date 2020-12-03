-- E2HelperFuncs.lua in vex_library server modules.
-- This originally used to be the entire vex_library.. oh how far we've come :o

local printf = vex.printf
local isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction, getmetatable, pcall, IsValid = isbool, isnumber, isstring, isentity, isangle, isvector, istable, IsColor, isfunction, getmetatable, pcall, IsValid
local string_upper, table_copy, table_IsEmpty, table_IsSequential = string.upper, table.Copy, table.IsEmpty, table.IsSequential

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
    E2Lib.registerConstant(string_upper(name), value)
    return value
end

vex.newE2Table = function() return {n={},ntypes={},s={},stypes={},size=0} end
local Default_E2Tbl = vex.newE2Table()

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
    -- Do a for loop in case the table structure changes in the future i guess
    -- ^> E2 table structure is not going to change.. if it does, then it will break a SH*T TON of addons (including their own/Wire code)
    -- We perform less reliable (this is just a tiny bit faster than the accurate check, saving 1 table lookup):
    return tbl.s and tbl.size and tbl.stypes and tbl.n and tbl.ntypes and true or false
end

-- Hardcoded e2 type guessing. (Not sure why are these made out as global functions now?)
vex.guessE2Type = function(v,donotWrapClassReference,typeGuessAheadOfTime)
    if isnumber(v) then return "n" end
    if isbool(v) then return "n", true end -- Returning an additional true, to indicate it must be sanitized (using `vex.sanitizeLuaVar`).
    if isstring(v) then return "s" end
    if isentity(v) then return "e" end
    if isangle(v) then return "a", not donotWrapClassReference end -- Requires serialization to prevent reference modification.
    if isvector(v) then
        return v.z == 0 and "xv2" or "v",  -- Optimize into Vector2.
               not donotWrapClassReference -- Requires serialization to prevent reference modification.
    end
    if IsValid(v) and type(v)=="PhysObj" then return "b" end -- Optimize into E2 `bone`.
    --[[
    if typeGuessAheadOfTime then
        --if type(v)=="thread" then return "xco" end
        -- This is left blank for now (to be filled in future).
    end
    ]]
    if istable(v) then
        if IsColor(v) then return "xv4", true end -- Returning an additional true, to indicate it must be sanitized (using `vex.sanitizeLuaVar`).
        if getmetatable(v) then return end -- Most likely we don't want this to be passed to the E2.
        -- E2 Tables will never be sequential.
        if table_IsEmpty(v) then return "r" end -- Potentially faster than depending on sequential doing a for loop that never executes?
                                                -- Huh, not sure about that. Well if the table is empty, it will never go into the loop at all.
                                                -- So, is this extra call+branch worth the performance? I doubt it is.
                                                -- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/table.lua#L180
        if table_IsSequential(v) then return "r" end -- Works for empty tables too (of course it does)
        return "t" -- Just return it as a table type (we are not going to validate contents)
    end
    -- Unsupported; Returning no value. Use the `vex.getE2Type` function if you need to check for official/3rd-party types.
end

vex.getE2Type = function(val,skipTypeGuessing)
    if not skipTypeGuessing then
        local guessedType, mustBeSanitized = vex.guessE2Type(val)
        if guessedType then return guessedType, mustBeSanitized end -- Has to be 100% sure.
    end
    for TypeName,TypeData in pairs(wire_expression_types) do
        -- Every e2 registered type has a type-validating function, which is [6] in the typedata. It returns whether the object isn't type x.
        -- It isn't perfect, it just tells the compiler whether it is valid for functions of type x to use the object.
        local success,is_not_type = pcall(TypeData[6],val)
        -- We have to pcall it because some methods do things like :isValid which would error on numbers and strings.. etc :/
        if success and not is_not_type then
            TypeName = wire_expression_types2[TypeData[1]][1]
            -- Returns the type name (uppercased).
            return TypeName == "NORMAL" and "NUMBER" or TypeName -- E1 normal -> E2 number type alias fixup.
        end
    end
end

-- Some variables need to be sanitized before we give them to e2. Like booleans will be turned to 1 or 0
-- ~~We don't need to sanitize anything else like vectors or angles.~~
-- ^> But we actually do need to, because they are sequential array in the E2, we have to prevent value change by modying a reference!
-- And also because this is a global function, which means it can now be used by other addons, so it must be able to work on its own.
-- Also why not make this return type ID along with the value, instead of having functions split apart (vex.guessE2Type)??
-- Now we have to make sure to mimic if-statements inside here, to match with the `vex.guessE2Type` function :(
vex.sanitizeLuaVar = function(v,aggressiveTypeGuessing,arrayOptimization,donotWrapClassReference)
    if isbool(v) then return v and 1 or 0 end -- Convert a boolean into either 1 or 0.
    -- With aggressive type guessing disabled, just pass it over (and hope you don't crash the E2 type system)
    if not aggressiveTypeGuessing
    -- With aggressive type guessing enabled, we process more checks (merged into single if-statement):
    or isnumber(v) or isstring(v) or isentity(v) -- These are fine, pass them as is.
    or (IsValid(v) and type(v)=="PhysObj") -- Let physics object go through (this translates to E2 `bone` data-type)
    then
        return v
    end
    if isangle(v) then return donotWrapClassReference and v or {v[1],v[2],v[3]} end -- Required wrap (because Angle is GLua class); to prevent reference modification!
    if isvector(v) then
        if v.z == 0 then return donotWrapClassReference and v or {v[1],v[2]} end -- Optimize into Vector2.
        return donotWrapClassReference and v or {v[1],v[2],v[3]} -- Required wrap (because Vector is GLua class); to prevent reference modification!
    end
    if istable(v) then
        if IsColor(v) then return {v.r,v.g,v.b,v.a} end -- Convert into Vector4 (for use with entity:setColor(xv4) function)
        --[==[
        -- Commented this out, because it might be an E2 array/table.
        if arrayOptimization and table_IsSequential(v) then
            if #v == 16 -- Optimization type guess: Matrix4
            or #v == 9  -- Optimization type guess: Matrix
            or #v == 4  -- Optimization type guess: Vector4/Quaternion/Matrix2
            or #v == 3  -- Optimization type guess: Vector/Angle
            or #v == 2  -- Optimization type guess: Vector2/Complex
            then
                -- Check to make sure they are all numbers.
                --[[for i=1,#v do
                    if not isnumber(v[i]) then return end -- Stop and return no value, it is not of type we expected to find.
                end]]
                return v
            end
        end
        ]==]
        return vex.luaTableToE2(v,arrayOptimization)
    end
    --if type(v)=="thread" then return v end -- Use the `vex.getE2Type` function if you need to check for "3rd-party" types.
    --if isfunction(v) or type(v)=="userdata" then return end -- Discard Lua function and C userdata from being passed to the E2.
    -- It is a bad idea to return v; This shouldn't be returning v unless it is ok with E2!
    -- This function should work as *whitelist* rather than *blacklist*. Therefore we return no value at this point.
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
        if istable(V) then
            t_types[K] = "t" -- How certain is this?
            if V == tbl then
                t[K] = output
            elseif arrayOptimization and table_IsSequential(V) then
                t[K],t_types[K] = V,"r"
            else
                t[K] = vex.luaTableToE2(V,arrayOptimization)
            end
        else
            -- Reasons unknown, why was this split apart and made into globals?
            -- But it is your decision. Expect this to run quite slower now because of many global lookups...
            local VType = vex.getE2Type(V) -- Determine the E2 type before calling the sanitizer.
            V = vex.sanitizeLuaVar(V,true,arrayOptimization,false) -- Sanitize a Lua value for safe use by E2.
            if V and VType then -- Only set value and type when this actually returned a value
                t[K],t_types[K] = V,VType
            else continue end -- Skip! We surely don't want this value in E2 table, filter it out.
        end
        size = size + 1 -- Increment the size at the end of this loop, because we are using `continue` above.
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
