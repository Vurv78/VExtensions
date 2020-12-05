local table_remove = table.remove
local table_insert = table.insert
local luaTableToE2, getE2UDF = vex.luaTableToE2, vex.getE2UDF

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

-- opcosts don't really matter in e2, especially for this function since it uses it's own compiler, so it runs just as if it was actually called
__e2setcost(5)

-- Literally like pcall()
-- Returns table, first argument is a number stating whether the function executed successfully, rest are varargs.
-- TODO: vararg input
e2function table try(string try)
    -- TODO: We probably wanna scrap using type inferrence for functions like try(), since it'd just be super inconvenient..
    -- Currently, it returns a table if you wanna return anything like an array or vector in a tried function
    local tryfun = getE2UDF(self,try)
    if not tryfun then return luaTableToE2{false,"Try was called with undefined function ["..try.."]"} end
    local success,errstr,args = runE2InstanceSafe(self,tryfun)
    if success then
        table_insert(args,1,true)
        return luaTableToE2(args)
    end
    return luaTableToE2{false,errstr}
end