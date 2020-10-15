--[[
   ______                            __   _                   
  / ____/____   _____ ____   __  __ / /_ (_)____   ___   _____
 / /    / __ \ / ___// __ \ / / / // __// // __ \ / _ \ / ___/
/ /___ / /_/ // /   / /_/ // /_/ // /_ / // / / //  __/(__  ) 
\____/ \____//_/    \____/ \__,_/ \__//_//_/ /_/ \___//____/  
 Gives Access to lua's coroutines to e2, can do everything lua coroutines can do,
    Can't halt lua's coroutines so it is safe.
]]

local running = coroutine.running

local table_remove = table.remove
local table_copy = table.Copy
local table_insert = table.insert
local table_add = table.Add

local coroutine_yield = coroutine.yield

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

local function e2err(msg) -- Just an alias so that we only error the lowest scope (e2's scope) so that we don't actually break lua
    error(msg,0)
end

local function createCoroutine(compiler,runtime,e2func)
    local thread = coroutine.create(runtime)
    compiler.coroutines[thread] = e2func -- Just so we know if a coroutine was created by e2.
    return thread
end

local function runningCo(compiler) -- Don't return if a glua coroutine is running
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

-- Will return Success,ErrorMsg,VarargsTbl Always. Coroutines don't need this because they handle their own errors
local function runE2InstanceSafe(compiler,run,body)
    local args = {pcall(run,compiler,body)}
    local success = table_remove(args,1)
    if not success then return false,args[1] end
    return true,"",args
end

__e2setcost(20)

e2function coroutine coroutine(string FuncName)
    if not FuncName then return end
    local e2func = getE2FuncFromStr(self,FuncName)
    if not e2func then return end
    local runtime = function()
        return e2func(self)
    end
    return createCoroutine(self,runtime,e2func)
end

__e2setcost(5)

e2function void coroutineYield()
    if not runningCo(self) then e2err("Attempted to yield an e2 coroutine without one running.") return end
    coroutine_yield()
end

e2function void coroutine:yield()
    if not this then return end
    if not runningCo(self) then e2err("Attempted to yield an e2 coroutine without one running.") return end
    coroutine_yield()
end

e2function void coroutineWait(n)
    if not runningCo(self) then e2err("Attempted to yield an e2 coroutine without one running.") return end
    coroutine.wait(n)
end

e2function void coroutine:wait(n)
    if not this then return end
    if not runningCo(self) then e2err("Attempted to make an e2 coroutine 'wait' without one running.") return end
    coroutine.wait(n)
end

-- No longer returns anything
e2function void coroutine:resume()
    if not this then return end
    local co_success,vararg = coroutine.resume(this)
    if not co_success then
        if vararg == "exit" then return end -- Literally running exit(). Idk why you'd do this but I mean i guess you wanna kill the coroutine bro..
        if vararg == "perf" then vararg = "tick quota exceeded" end
        e2err("COROUTINE ERROR: "..vararg)
    end
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

__e2setcost(10)

e2function array try(string try)
    local tryfnc = getE2FuncFromStr(self,try)
    if not tryfnc then e2err("Try called without an existing try function ["..try.."]") end
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

e2function array catch(string try,string catch)
    local tryfnc,catchfnc = getE2FuncFromStr(self,try),getE2FuncFromStr(self,catch)
    if not tryfnc then e2err("Catch(ss) called without an existing try function ["..try.."]") end
    if not catchfnc then e2err("Catch(ss) called without an existing catch function ["..catch.."]") end
    
    local success,errstr,args = runE2InstanceSafe(self,tryfnc)
    if success then
        table_insert(args,1,1)
        return args
    else
        runE2InstanceSafe(self,catchfnc,buildBody{
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
        return e2func(self)
    end
    return createCoroutine(self,runtime,e2func)
end