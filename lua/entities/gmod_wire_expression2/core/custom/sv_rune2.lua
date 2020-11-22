local table_remove = table.remove
local table_insert = table.insert


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
local function runE2InstanceSafe(compiler,func,body) -- Varargs to pass to the e2 function
    -- Will always return pcallerror,errstr first even if it didn't error.
    local args = {pcall(func,compiler,body)}
    local success = table_remove(args,1)
    if success then
        return true,"none",args
    else
        -- Don't return args, that would be a waste
        local errmsg = table_remove(args,1)
        if errmsg == "exit" then return true,"none",{} end -- nice exit()
        if errmsg == "perf" then errmsg = "tick quota exceeded" end
        return false,errmsg
    end
end

local function getE2FuncFromStr(compiler,funcname)
    local funcs = compiler.funcs
    local e2func = funcs[funcname]
    if not e2func then -- We will look for any udfs that have the name before the parenthesis.
        local fncnameproper = funcname:match("(%w*)%(") or funcname
        for K,V in pairs(funcs) do
            local proper = K:match("(%w*)%(")
            if proper and string.find(proper,fncnameproper) then return V end
        end
    else
        return e2func
    end
end


-- Literally like pcall()
-- Returns array, first argument is a number stating whether the function executed successfully, rest are varargs.

e2function array try(string try) -- If you *really* want to pass arguments to the function then just make another function that calls that function.
    local tryfnc = getE2FuncFromStr(self,try)
    if not tryfnc then error("Try called without an existing try function ["..try.."]",0) end
    local success,errstr,args = runE2InstanceSafe(self,tryfnc)
    if success then
        table_insert(args,1,1)
        return args
    else
        return {0,errstr}
    end
end


-- Literally like xpcall()
-- Behaves exactly like try(string try) except it also calls a catch function given.
-- The catch function will only run if it errored.

e2function array catch(string try,string catch) -- If you *really* want to pass arguments to the function then just make another function that calls that function.
    local tryfnc,catchfnc = getE2FuncFromStr(self,try),getE2FuncFromStr(self,catch)
    if not tryfnc then error("Try called without an existing try function ["..try.."]",0) end
    if not catchfnc then error("Try called without an existing catch function ["..catch.."]",0) end
    
    local success,errstr,args = runE2InstanceSafe(self,tryfnc)
    if success then
        table_insert(args,1,1)
        return args
    else
        runE2InstanceSafe(self,catchfnc,buildBody{
            ["s"] = errstr
        })
        return {0,errstr}
    end
end