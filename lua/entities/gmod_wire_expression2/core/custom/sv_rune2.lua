local table_remove = table.remove
local table_insert = table.insert
local luaTableToE2, getE2UDF, getE2Func = vex.luaTableToE2, vex.getE2UDF, vex.getE2Func


-- Builds a body to run an e2 udf and pass args to it.
local function buildBody(args) -- Why does the wireteam do this
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

-- We use this for try and catch
local function runE2InstanceSafe(compiler,func,body,...)
    -- Always return pcallerror,errstr first even if it didn't error.
    local args = {pcall(func,compiler,body,...)}
    local success = table_remove(args,1)
    if success then
        return true,nil,args
    end
    -- If unsuccessful, don't return args, that would be a waste
    local errmsg = table_remove(args,1)
    if errmsg == "exit" then return true,nil,{} end -- nice exit()
    if errmsg == "perf" then errmsg = "tick quota exceeded" end
    return false,errmsg
end

-- TODO: Set E2 costs ( __e2setcost(N) ).


-- Literally like pcall()
-- Returns table, first argument is a number stating whether the function executed successfully, rest are varargs.
-- TODO: variadic/varargs support [see array(...) / table(...) / select(N...) E2 functions for reference]
e2function table try(string try)
    local tryfun = getE2UDF(self,try) --or getE2Func(self,try) -- Keeping it at UDF only?
    -- Do *not* throw error from this function!! ಠ_ಠ (¬_¬)
    if not tryfun then return luaTableToE2{false,"Try was called with undefined function ["..try.."]"} end
    local success,errstr,args = runE2InstanceSafe(self,tryfun)
    if success then
        table_insert(args,1,true)
        return luaTableToE2(args)
    end
    return luaTableToE2{false,errstr}
end


-- Literally like xpcall() ... Actually, not really, no it is not; If you get/make an error in your E2 catch callback, it will stop executing...
-- Behaves exactly like try(string try) except it also calls a catch function given.
-- The catch function will only run if it errored ... Which is something you can already do using try function and check if it was unsuccessful.
-- Why does this exist if it doesn't work "Literally like xpcall"?
--e2function table catch(string try,string catch,...)
--    local tryfun,catchfnc = getE2UDF(self,try) or getE2Func(self,try),getE2UDF(self,catch) or getE2Func(self,catch)
--    if not tryfun then return luaTableToE2{false,"Catch was called with undefined try function ["..try.."]"} end
--    if not tryfun then return luaTableToE2{false,"Catch was called with undefined catch function ["..catch.."]"} end
--    local success,errstr,args = runE2InstanceSafe(self,tryfun,nil,...)
--    if success then
--        table_insert(args,1,true)
--        return luaTableToE2(args)
--    end
--    runE2InstanceSafe(self,catchfnc,buildBody{
--        ["s"] = errstr
--    })
--    return luaTableToE2{false,errstr}
--end