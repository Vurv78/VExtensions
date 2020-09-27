local running = coroutine.running

local table_remove = table.remove
local table_copy = table.Copy
local table_insert = table.insert
local table_add = table.Add

E2Lib.RegisterExtension("coroutines", false, "Allows E2s to use coroutines.")

-- Coroutine Object handling

registerType("coroutine", "xco", nil,
	nil,
	nil,
	function(ret)
		if not ret then return end
		if type(ret)~="thread" then return end
		error("Return value is neither nil nor a coroutine, but a "..type(ret).."!",0)
	end,
	function(v)
		return type(v)~="thread"
	end
)

registerCallback("construct", function(self) -- On e2 placed, initialize coroutines. gives compiler to function
	self.coroutines = {}
end)


registerCallback("destruct",function(self) -- On e2 deleted, deletes all coroutines. gives compiler to function
    self.coroutines = {}
end)

__e2setcost(2)

registerOperator("ass", "xco", "xco", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local rhs = op2[1](self, op2)

	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

registerOperator("is", "xco", "n", function(self, args) -- if(coroutine("print()"))
    -- What the actual fuck is this wire team ?????
    local op1 = args[2]
	local coro = op1[1](self, op1)
	return coro and 1 or 0
end)

registerOperator("eq", "xcoxco", "n", function(self, args) -- if(coroutineRunning() == CoroutineSaved)
    -- What the actual fuck is this wire team ?????
    local op1, op2 = args[2], args[3]
	local co1, co2 = op1[1](self, op1), op2[1](self, op2)
    return (co1==co2) and 1 or 0
end)

-- Locals

local function createCoroutine(compiler,runtime,e2func)
    local thread = coroutine.create(runtime)
    compiler.coroutines[thread] = e2func -- Just so we know if a coroutine was created by e2.
    return thread
end

local runningCo = function(compiler) -- Don't return if a glua coroutine is running
    local thread = coroutine.running()
    if not thread then return end
    if compiler.coroutines[thread] then return thread end
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

local function buildBody(args) -- WHY WIRETEAM WHY??? ( We need this to pass args into udfs )
    local body = {
        false -- No idea what this does, but it is necessary
    }
    local types = {}
    for Type,Value in pairs(args) do
        table_insert(body,{
            [1] = function() return Value end,
            ["TraceName"] = "LITERAL" -- yup
        })
        table_insert(types,Type)
    end
    table_insert(body,types)
    return body
end -- We need to build a body in order to pass args to an e2 function.

local function runE2Instance(compiler,func,body) -- Varargs to pass to the e2 function
    -- Will always return pcallerror,errstr first even if it didn't error.
    local args = {pcall(func,compiler,body)}
    local success = table_remove(args,1)
    if success then
        return true,"none",args
    else
        -- Don't return args, that would be a waste
        local errmsg = table_remove(args,1)
        if errmsg == "perf" then errmsg = "tick quota exceeded" end
        return false,errmsg
    end
end

--[[__e2setcost(19) -- This is a function I used for debug, feel free to use it idk
e2function void executeFunction(string FuncName)
    local e2fnc = getE2FuncFromStr(self,FuncName)
    if not e2fnc then error("This function does not exist ["..FuncName.."]",0) end
end]]

__e2setcost(20)

e2function coroutine coroutine(string FuncName)
    if not FuncName then return end
    local e2func = getE2FuncFromStr(self,FuncName)
    if not e2func then return end
    local runtime = function()
        return runE2Instance(table_copy(self),e2func)
    end
    return createCoroutine(self,runtime,e2func)
end

__e2setcost(5)

e2function void coroutine:yield()
    if not this then return end
    if not runningCo(self) then error("Attempted to yield a coroutine without an e2 coroutine running.",0) return end
    coroutine.yield()
end

e2function void coroutine:wait(n)
    if not this then return end
    if runningCo(self)==this then
        local endtime = CurTime() + n
        while true do
            if endtime < CurTime() then return end
            coroutine.yield()
        end
    else
        error("Attempted to wait outside of the coroutine given.",0)
    end
end

e2function array coroutine:resume()
    if not this then return {} end
    local co_success,xp_success,xp_error,args = coroutine.resume(this)
    if co_success and xp_success==nil then
        -- If the coroutine was yielded.
    else
        if not xp_success then
            if xp_error == "exit" then
            else
                error("COROUTINE ERROR: "..xp_error,0)
            end
        else
            return args
        end
    end
    return {}
end

__e2setcost(3)

e2function string coroutine:status()
    if not this then return end
    return coroutine.status(this)
end

e2function coroutine coroutineRunning() -- Returns {running, thread} with running being whether an e2 coroutine is running, thread being the coroutine running.
    local thread = runningCo(self)
    if not thread then return end
    return thread
end

-- Literally like pcall()
-- Returns array, first argument is a number stating whether the function executed successfully, rest are varargs.

e2function array try(string try) -- If you *really* want to pass arguments to the function then just make another function that calls that function.
    local tryfnc = getE2FuncFromStr(self,try)
    if not tryfnc then error("Try called without an existing try function ["..try.."]",0) end
    local success,errstr,args = runE2Instance(table_copy(self),tryfnc)
    if success then
        table_insert(args,1,1)
        return args
    else
        return {0,errstr}
    end
end


-- Literally like xpcall()
-- Behaves exactly like try(string try) except it also calls a catch function given.

e2function array try(string try,string catch) -- If you *really* want to pass arguments to the function then just make another function that calls that function.
    local tryfnc,catchfnc = getE2FuncFromStr(self,try),getE2FuncFromStr(self,catch)
    if not tryfnc then error("Try called without an existing try function ["..try.."]",0) end
    if not catchfnc then error("Try called without an existing catch function ["..catch.."]",0) end
    
    local success,errstr,args = runE2Instance(table_copy(self),tryfnc)
    if success then
        table_insert(args,1,1)
        return args
    else
        runE2Instance(self,catchfnc,buildBody{
            ["r"] = {0,errstr}
        })
        return {0,errstr}
    end
end

__e2setcost(15)

e2function coroutine coroutine:reboot() -- Returns the coroutine as if it was just created, 'reboot'ing it.
    if not this then return end
    local e2func = self.coroutines[this]
    if not e2func then return end
    local runtime = function()
        return runE2Instance(table_copy(self),e2func)
    end
    return createCoroutine(self,runtime,e2func)
end