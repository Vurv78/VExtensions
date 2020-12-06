local table_remove = table.remove
local table_insert = table.insert
local luaTableToE2, getE2UDF, buildBody = vex.luaTableToE2, vex.getE2UDF, vex.buildBody

-- We use this for try and catch
local function runE2InstanceSafe(compiler,func,body,...)
    local args = {pcall(func,compiler,body,...)}
    if table_remove(args,1) then -- We don't even use the success var anyway
        return true,nil,args
    end
    -- If unsuccessful, don't return args, that would be a waste
    local errmsg = table_remove(args,1)
    if errmsg == "exit" then return true,nil,{} end -- nice exit()
    if errmsg == "perf" then errmsg = "tick quota exceeded" end
    return false,errmsg
end

-- Specialized by: Cheatoid <3
local function specializedLuaValueToE2(result, returnType)
    -- E2 is going to enforce type-safety for us, so we know *exactly* which type are we dealing with :D
    -- This is 100% reliable; PERFECTION! (Do not touch this code!)
    --print("[specializedLuaValueToE2] Gotcha!", result, "Return type: " .. returnType)
    --if istable(result) then PrintTable(result, 1) end -- Quick debugging...
    return {n={[1]=1,[2]=result},ntypes={[1]="n",[2]=returnType},s={},stypes={},size=2} -- Funny, how simple it is.
end

-- opcosts don't really matter in e2, especially for this function since it uses it's own compiler, so it runs just as if it was actually called
__e2setcost(3)

-- Literally like pcall()
-- Returns table, first argument is a number stating whether the function executed successfully, rest are varargs.
e2function table try(string funcName)
    -- TODO: We probably wanna scrap using type inferrence for functions like try(), since it'd just be super inconvenient..
    -- Currently, it returns a table if you wanna return anything like an array or vector in a tried function
    local tryFunc,_,returnType = getE2UDF(self,funcName)
    if not tryFunc then return luaTableToE2{false,"Try was called with undefined function ["..funcName.."]"} end
    local success,errstr,result = runE2InstanceSafe(self,tryFunc)
    if success then
        return specializedLuaValueToE2(result[1],returnType) -- Finally. Fu**ing. Done. The right way.
    end
    return luaTableToE2{false,errstr}
end

e2function table try(string funcName, table args)
    local tryFunc = getE2UDF(self,funcName,"t") -- "t" is to make sure UDF's return type is a table.
    if not tryFunc then return luaTableToE2{false,"Try was called with undefined function ["..funcName.."]"} end
    local success,errstr,result = runE2InstanceSafe(self,tryFunc,buildBody{["t"]=args})
    if success then
        return specializedLuaValueToE2(result[1],"t") -- We wouldn't be here if UDF wasn't returning a table.
    end
    return luaTableToE2{false,errstr}
end
