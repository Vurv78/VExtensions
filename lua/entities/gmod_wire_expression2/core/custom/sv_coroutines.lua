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

local function e2err(msg)
    error(msg,0)
end

vex.registerExtension("coroutines", false, "Allows E2s to use coroutines.")

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

e2function coroutine operator=(coroutine lhs, coroutine rhs) -- Co = coroutine("bruh(e:)")
	local scope = self.Scopes[ args[4] ]
	scope[lhs] = rhs
	scope.vclk[lhs] = true
	return rhs
end

e2function number operator==(coroutine lhs, coroutine rhs) -- if(coroutineRunning()==Co)
    return lhs == rhs
end

e2function number operator_is(coroutine co) -- if(coroutineRunning())
    return co and 1 or 0
end

-- Locals

-- Save External Data

-- Start Coroutine
-- Load coroutine data
-- coroutine.resume

-- Save Coroutine Data -- coroutine.yield
-- Load External Data -- coroutine.resume result

local save = nil

local function popPrfData(instance)
    local Data = {
        prf = instance.prf,
        prfcount = instance.prfcount,
        prfbench = instance.prf,
        timebench = instance.timebench,
        time = instance.time,
    }
    return Data
end

local function loadPrfData(instance,data)
    for K,V in pairs(data) do
        instance[K] = V
    end
end

local function createCoroutine(compiler,runtime,e2func)
    local thread = coroutine.create(runtime)
    -- Data that we keep so we know whether a coroutine was created by e2 or not.
    compiler.coroutines[thread] = e2func
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
        if errmsg == "perf" then errmsg = "tick quota exceeded" end
        return false,errmsg
    end
end

__e2setcost(20)

e2function coroutine coroutine(string FuncName)
    if not FuncName then return end
    local e2func = getE2FuncFromStr(self,FuncName)
    if not e2func then return end
    local runtime = function()
        return true,e2func(table_copy(self))
    end
    return createCoroutine(self,runtime,e2func)
end

__e2setcost(5)

local function customWait(instance,n)
	local endtime = CurTime() + n
	while endtime > CurTime() do
		coroutine.yield(popPrfData(instance))
	end
end

e2function void coroutineYield()
    if not runningCo(self) then e2err("Attempted to yield a coroutine without an e2 coroutine running.") return end
    loadPrfData(self, coroutine.yield( popPrfData(self) ) )
end

e2function void coroutine:yield()
    if not this then return end
    if not runningCo(self) then e2err("Attempted to yield a coroutine without an e2 coroutine running.") return end
    loadPrfData(self, coroutine.yield( popPrfData(self) ) )
end

e2function void coroutine:wait(n)
    if not this then return end
    if not runningCo(self) then e2err("Attempted to wait outside of the coroutine given.") end
    customWait(self,n)
end

e2function void coroutineWait(n)
    if not runningCo(self) then e2err("Attempted to wait outside of an e2 coroutine.") return end
    customWait(self,n)
end

e2function void coroutine:resume()
    if not this then return end
    local bench = SysTime()
    local co_success,prfDataOrDone,vararg = coroutine.resume(this,popPrfData(self))
    -- If this isn't true, then the coroutine has not finished.
    if prfDataOrDone ~= true then
        if not co_success then
            local err = prfDataOrDone
            if err == "exit" then return end
            if err == "perf" then err = "tick quota exceeded" end
            err = string.match(err,"entities/gmod_wire_expression2/core/core.lua:%d+:(.*)") or err -- ( in e2 code ) error("hello world")
            e2err("COROUTINE ERROR: " .. err)
        end
        prfDataOrDone.time = prfDataOrDone.time + (SysTime() - bench)
        loadPrfData(self,prfDataOrDone)
        self.entity:UpdateOverlay()
    end
end

__e2setcost(3)

e2function string coroutine:status()
    if not this then return end
    return coroutine.status(this)
end

e2function coroutine coroutineRunning() -- Returns the actual thread being run. No need to return a number before since we added the if operator on coroutines.
    local thread = runningCo(self)
    if not thread then return end
    return thread
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

__e2setcost(15)

e2function coroutine coroutine:reboot() -- Returns the coroutine as if it was just created, 'reboot'ing it.
    if not this then return end
    local e2func = self.coroutines[this]
    if not e2func then return end
    local runtime = function()
        return true,e2func(table_copy(self))
    end
    return createCoroutine(self,runtime,e2func)
end