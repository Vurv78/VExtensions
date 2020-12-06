local table_remove = table.remove
local table_insert = table.insert
local luaTableToE2, getE2UDF, buildBody = vex.luaTableToE2, vex.getE2UDF, vex.buildBody

-- We use this for `try` E2 functions
local function runE2InstanceSafe(compiler,func,returnType,body)
    local args = {pcall(func,compiler,body)}
    if table_remove(args,1) then -- We don't even use the success var anyway
        return true,nil,args[1]
    end
    -- If unsuccessful, don't return args, that would be a waste
    local errmsg = table_remove(args,1)
    if errmsg == "exit" then return true,nil,wire_expression_types2[returnType][2] end -- nice exit()
    if errmsg == "perf" then errmsg = "tick quota exceeded" end
    return false,errmsg
end

-- Specialized by: Cheatoid <3
local function specializedPassBackToE2(result, returnType)
    -- E2 is going to enforce type-safety for us, so we know *exactly* which type are we dealing with :D
    -- This is 100% reliable; PERFECTION! (Do not touch this code!)
    return {n={[1]=1,[2]=result},ntypes={[1]="n",[2]=returnType},s={},stypes={},size=2}
end

-- opcosts don't really matter in e2, especially for this function since it uses it's own compiler, so it runs just as if it was actually called
__e2setcost(3)

-- Literally like pcall()
-- Returns table, 1st field is a number stating whether the function executed successfully, 2nd field is the return value of the given function.
e2function table try(string funcName)
    local tryFunc,_,returnType = getE2UDF(self,funcName,nil,"") -- "" is to enforce UDF has no arguments.
    if not tryFunc then return luaTableToE2{false,"Try was called with undefined function ["..funcName.."]"} end
    local success,errstr,result = runE2InstanceSafe(self,tryFunc,returnType)
    if success then
        return specializedPassBackToE2(result,returnType)
    end
    return luaTableToE2{false,errstr}
end

e2function table try(string funcName, table args)
    local tryFunc,_,returnType = getE2UDF(self,funcName,nil,"t") -- "t" is to enforce UDF has only 1 argument (of type table).
    if not tryFunc then return luaTableToE2{false,"Try was called with undefined function ["..funcName.."]"} end
    local success,errstr,result = runE2InstanceSafe(self,tryFunc,returnType,buildBody{["t"]=args}) -- Pass the captured args table.
    if success then
        return specializedPassBackToE2(result,returnType)
    end
    return luaTableToE2{false,errstr}
end
