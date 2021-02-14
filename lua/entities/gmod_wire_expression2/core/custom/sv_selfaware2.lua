--[[
   _____        __ ____   ___                                  ___
  / ___/ ___   / // __/  /   | _      __ ____ _ _____ ___     |__ \
  \__ \ / _ \ / // /_   / /| || | /| / // __ `// ___// _ \    __/ /
 ___/ //  __// // __/  / ___ || |/ |/ // /_/ // /   /  __/   / __/
/____/ \___//_//_/    /_/  |_||__/|__/ \__,_//_/    \___/   /____/

 Adds functions similarly to regular-e2's self-aware core.
]]

-- Localization of global functions
local newE2Table, getE2UDF, getE2Func = vex.newE2Table, vex.getE2UDF, vex.getE2Func

local luaTableToE2
do
    -- Localized and tailored towards just for SelfAware2's needs (for best CPU speed).
    -- Therefore this is not guaranteed to work outside from here (do not copy/paste this code).
    -- This could have been written in 12 lines of code, but I really prefer best CPU speed here instead of readability.
    -- Besides we know what this function is supposed to do, and it does just that -- but faster.
    local next, type, isnumber, isstring, istable = next, type, isnumber, isstring, istable
    luaTableToE2 = function(tbl,arrayOptim)
        local out,key,value = newE2Table(),next(tbl)
        if not key then return out end
        local size,values,types,vType = 0
        if     isnumber(key) then values,types = out.n,out.ntypes
        elseif isstring(key) then values,types = out.s,out.stypes
        end
        while key do
            if istable(value) then
                if arrayOptim>0 and isnumber(next(value)) then vType = "r"
                else value = luaTableToE2(value,arrayOptim+1) vType = "t"
                end
            else
                vType = type(value)[1] -- This will be either "n" or "s" (they are the only types we care about in SA2)
            end
            values[key],types[key],size,key,value = value,vType,size+1,next(tbl,key)
        end
        out.size = size
        return out
    end
end

-- OPS management |
local BaseCost    = 3     -- The amount of OPS to be added for all E2 functions in here.
local BaseMulCost = 1     -- The amount which is to be multiplied with the assigned OPS cost.
local OpCost      = 1 / 5 -- Cost of looping through table multiplier. Might need to adjust this later (add 1 per 5 for now).
local __e2setcost = __e2setcost
local function e2cost(cost) __e2setcost((cost * BaseMulCost) + BaseCost) end
--[[ The OPS was measured approximately:
    +5  : If the function looks up builtins.
    +4  : If the function looks up builtins, while skipping operator functions.
    +3  : If the function looks up UDFs.
    Note: Some of the functions will dynamically bump up OPS as required.
]]

--===========================================================================================================================

e2cost(8)

-- Ex: print(defined("print(...)")) or print(defined("health(e:)"))
-- Returns number; 0 being not defined, 1 being defined as a builtin E2 function, 2 being a user-defined function.
-- Note: If you are checking for availability of the UDF function, you should look into the getUserFunctionInfo function,
--       because this function becomes unreliable if you only provide it with UDF name to it.
--       If you are checking for availability of the builtin function and if you know the signature ahead of time,
--       then it is preferred to use #ifdef pre-processor statement; this function exists for dynamic/runtime kind of checks.
e2function number defined(string funcName)
    -- Check/Prefer builtin first.
    local isFunc, funcDirect = getE2Func(funcName) -- (Not skipping operator functions.)
    if funcDirect then return 1 end -- Builtin perfect match.
    local isUDF, udfDirect = getE2UDF(self, funcName)
    if udfDirect then return 2 end -- UDF perfect match.
    -- Name-only match after this point, still prefer the builtin.
    if isFunc --[[and not isUDF]] then return 1 end -- Found named builtin match.
    if isUDF --[[and not isFunc]] then return 2 end -- Found named UDF match.
    return 0
end

--===========================================================================================================================

e2cost(5)

local isfunction, debug_getinfo, string_sub = isfunction, debug.getinfo, string.sub
-- Ex: print(getFunctionPath("print(...)")) would print the path to .../core/debug.lua file.
-- Returns the path where the function was defined, useful for finding whether something was added with an addon.
e2function string getFunctionPath(string funcName)
    local func = getE2Func(funcName) -- (Not skipping operator functions.)
    -- source is better than short_src, because it can help identify custom addon/core more easily (without path trim).
    return isfunction(func) and string_sub(debug_getinfo(func, "S").source, 2) or ""
end

--===========================================================================================================================

e2cost(4)

-- Returns a table of arrays containing information about E2 extensions (status and description).
-- This function exists for dynamic/runtime kind of checks. (You should cache the result in your E2 for performance.)
e2function table getExtensionsInfo()
    local ret = {}
    for _, name in pairs(E2Lib.GetExtensions()) do
        ret[name] = { -- A table of extension info (will be converted into an E2 array),
            -- Boolean, indicating whether the extension is enabled (will be converted to 0 or 1)
            [1] = E2Lib.GetExtensionStatus(name) and 1 or 0,
            -- String, short description about the extension
            [2] = E2Lib.GetExtensionDocumentation(name).Description or ""
        }
    end
    return luaTableToE2(ret, 1) -- This will take care of converting the Lua table into an E2 compatible table.
end

--===========================================================================================================================

e2cost(2)

-- Returns a table containing all registered E2 constants. This function exists for dynamic/runtime kind of lookups.
-- (You should cache the result in your E2 for performance.)
e2function table getConstants()
    -- Must return a copy table to prevent reference modifications; luaTableToE2 takes care of this at the same time.
    -- Table structure: constant name is used as the table key and constant value (number) as the table value.
    return luaTableToE2(wire_expression2_constants, 0)
end

--===========================================================================================================================

--[[-------------------------------------------------------------------------------------------------------------------------
    Returns a table containing useful information about all User-Defined Functions.
    This function can operate differently, the `mode` argument controls how the output table will be structured:
        Mode 0 (aka Flat): [See below].
        Mode 1 (aka D&C) : [See below].
    This design is used specifically to avoid making an additional E2 functions (additional modes can be added later).
    For example, if you define the following UDFs in your E2:
        function void foo(Num, Text:string)
        function string entity:myFunc(Col:vector4, Ar:array)
        function table entity:myFunc(Rot:angle, Pos:vector)
    You would get the following table in Mode 0 (aka Flat):
        { -- table
            ["foo(ns)"       ] = { [1]="",  [2]="Num,Text", [3]="myfuncs.txt:1" }, -- array
            ["myFunc(e:xv4r)"] = { [1]="s", [2]="Col,Ar",   [3]="myfuncs.txt:4" }, -- array
            ["myFunc(e:av)"  ] = { [1]="t", [2]="Rot,Pos",  [3]="myfuncs.txt:7" }  -- array
        }
    You would get the following table in Mode 1 (aka D&C):
        { -- table
            ["foo"] =
            { -- table
                { [1]="ns", [2]="", [3]="Num,Text", [4]="myfuncs.txt:1" } -- array
            },
            ["myFunc"] =
            { -- table
                { [1]="e:xv4r", [2]="s", [3]="Col,Ar",  [4]="myfuncs.txt:4" }, -- array
                { [1]="e:av",   [2]="t", [3]="Rot,Pos", [4]="myfuncs.txt:7" }  -- array
            }
        }
---------------------------------------------------------------------------------------------------------------------------]]
e2cost(2) -- Note: The cost is dynamically increased here.
local string_find = string.find
local GET_UDF_MODE = {
    [vex.registerConstant("UDF_FLAT", 0)] =
        function(self)
            --[[--
            Table key is the same string as in the funcs_ret table (name + signature).
            Table value is an array:
                [1] = Return type (ID) string as reported by funcs_ret  (empty string if void)
                [2] = Comma-separated string containing names of arguments
                [3] = Filename and line number specifying where the UDF is defined at (within the current E2)
            --]]--
            local res, size = {}, 0
            for fullsig, returnType in pairs(self.funcs_ret) do
                -- TODO (Patch #3): entries [2] and [3] in the table (not sure yet how to obtain these)
                res[fullsig] = { [1] = returnType or "" }
                size = size + 1
            end
            -- Dynamically bump up OPS based on the size of the output table. (Keep this after the loop.)
            self.prf = self.prf + size * OpCost
            return luaTableToE2(res, 1) -- Convert to E2 table with array optimization enabled.
        end;
    [vex.registerConstant("UDF_DNC", 1)] =
        function(self)
            --[[--
            Table key is made of just the name of the UDF.
            Table value is a table of tables containing:
                [1] = Function signature (extracted portion between parentheses of the funcs_ret key)
                [2] = Return type (ID) string as reported by funcs_ret  (empty string if void)
                [3] = Comma-separated string containing names of arguments
                [4] = Filename and line number specifying where the UDF is defined at (within the current E2)
            --]]--
            local res, size = {}, 0
            for sig, returnType in pairs(self.funcs_ret) do
                -- This should never return a nil. Not using patterns due performance.
                -- Starting at the index 2, since the index 1 is always a letter.
                local idx = string_find(sig, "(", 2, true)
                local name = string_sub(sig, 1, idx - 1) -- This will contain only the function name.
                -- Extract the portion between parentheses (function signature; data-types of args).
                -- Again not using patterns, since we already know the index.
                sig = string_sub(sig, idx + 1, -2) -- -2 in order to drop the ')' at the end.
                local collection = res[name] or {}
                res[name] = collection
                -- TODO (Patch #3): entries [3] and [4] in the table (not sure yet how to obtain these)
                collection[#collection + 1] = { [1] = sig, [2] = returnType or "" }
                size = size + 1
            end
            -- Dynamically bump up OPS based on the size of the output table. (Keep this after the loop.)
            self.prf = self.prf + size * OpCost
            return luaTableToE2(res, 0) -- Convert to E2 table with array optimization disabled (initially).
        end;
}
e2function table getUserFunctionInfo(mode)
    mode = GET_UDF_MODE[mode]
    return mode and mode(self) or newE2Table()
end

--===========================================================================================================================

e2cost(4) -- Note: The cost is dynamically increased here.
-- A small helper function to help with creation of the builtin function info table.
local function createBuiltinFuncInfoTable(tbl)
    return {
        -- String, full function signature
        [1] = tbl[1] or "",
        -- String, return type (ID)
        [2] = tbl[2] or "",
        -- Number, function cost (OPS)
        [3] = tbl[4] or 0,
        -- Table of strings, holding arguments' names (will be converted into an array)
        --[4] = tbl.argnames or {} -- FIXME (Patch #3): Something breaks out when using this...
    }
end
-- Returns a table containing information about the builtin (non-UDF) E2 functions.
-- Either use "*" as a `funcName` to get infos for all, or specify a function name/signature (e.g. "selfDestruct").
e2function table getBuiltinFuncInfo(string funcName)
    if funcName == "*" then
        -- Loop over all builtin functions and populate the table.
        local ret, size = {}, 0 -- We need to count entries manually. (Used for bumping up OPS.)
        for sig, tbl in pairs(wire_expression2_funcs) do
            if string_sub(sig, 1, 3) ~= "op:" then
                -- Make sure we aren't passing any metamethods / operators (adding, subtracting)
                ret[sig] = createBuiltinFuncInfoTable(tbl)
                size = size + 1
            end
        end
        -- Dynamically bump up OPS based on the size of the output table. (Keep this after the loop.)
        self.prf = self.prf + size * OpCost
        -- Convert the result table into E2 compatible table, with array optimization enabled.
        return luaTableToE2(ret, 1)
    end
    -- Otherwise, search for the specified function and only return its information.
    local tbl = getE2Func(funcName, true, true) -- Skip operator functions.
    return tbl
        and
        -- If the function is found, create a Lua table and convert into a compatible E2 table,
            luaTableToE2(
                createBuiltinFuncInfoTable(tbl), -- This is just an array, but this function must return a table.
                0 -- With array optimization disabled, because we just want to wrap an array as a table.
            )
        -- If the function is not found, return an empty E2 table.
        or newE2Table()
end

--===========================================================================================================================

e2cost(3)
local string_lower = string.lower
-- Returns a table containing E2 types information (type ID is used as table key, and type name as the table value).
-- If you need it other way around, just use invert function. (You should cache the result in your E2 for performance.)
e2function table getTypeInfo()
    local ret = {}
    for typeName, tbl in pairs(wire_expression_types) do
        ret[tbl[1]] = typeName == "NORMAL" and "number" or string_lower(typeName) -- E1 normal -> E2 number type alias
    end
    return luaTableToE2(ret, 0) -- Convert into a compatible E2 table without array optimization.
end

--===========================================================================================================================

e2cost(3)

-- Attempts to delete a user-defined function from this E2's context. You must specify a full signature (i.e. "myFunc(e:av)").
e2function number deleteUserFunction(string funcName)
    local exists = self.funcs[funcName]
    if exists then
        self.funcs[funcName] = nil
        return 1
    end
    return 0
end
