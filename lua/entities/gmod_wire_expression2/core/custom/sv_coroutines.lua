--[[
   ______                            __   _
  / ____/____   _____ ____   __  __ / /_ (_)____   ___   _____
 / /    / __ \ / ___// __ \ / / / // __// // __ \ / _ \ / ___/
/ /___ / /_/ // /   / /_/ // /_/ // /_ / // / / //  __/(__  )
\____/ \____//_/    \____/ \__,_/ \__//_//_/ /_/ \___//____/

 Gives access to Lua's coroutines to E2, can do everything Lua coroutines can do,
    Can't halt Lua's coroutines, so it is safe.
]]

-- Function localization (local lookup is faster).
local coroutine_running, coroutine_create, coroutine_resume, coroutine_yield, coroutine_status = coroutine.running, coroutine.create, coroutine.resume, coroutine.yield, coroutine.status
local table_copy = table.Copy
local newE2Table, buildBody = vex.newE2Table, vex.buildBody

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
        if type(ret)~="thread" then error("Return value is neither nil nor a coroutine, but a "..type(ret).."!",0) end
    end,
    function(v)
        return type(v)~="thread"
    end
)

registerCallback("construct", function(self) -- On e2 placed, initialize coroutines. gives compiler to function
    self.coroutines = {}
end)


registerCallback("destruct",function(self) -- On e2 deleted, deletes all coroutines. gives compiler to function
    self.coroutines = nil
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

e2function number operator!=(coroutine lhs, coroutine rhs) -- if(coroutineRunning()!=Co)
    return lhs ~= rhs
end

e2function number operator_is(coroutine co) -- if(coroutineRunning())
    return co and 1 or 0
end

local function popPrfData(instance)
    return {
        prf = instance.prf,
        prfcount = instance.prfcount,
        prfbench = instance.prf,
        timebench = instance.timebench,
        time = instance.time,
    }
end

local function loadPrfData(instance,data)
    for K,V in pairs(data) do
        instance[K] = V
    end
end

local function createCoroutine(compiler,runtime,e2func)
    local thread = coroutine_create(runtime)
    -- Data that we keep so we know whether a coroutine was created by e2 or not.
    compiler.coroutines[thread] = e2func
    return thread
end

local function runningCo(compiler) -- Don't return if a glua coroutine is running
    local thread = coroutine_running()
    if not thread then return end
    if compiler.coroutines[thread] then return thread end
end

local getE2UDF = vex.getE2UDF

__e2setcost(20)

e2function coroutine coroutine(string funcName)
    local e2func = getE2UDF(self,funcName,"","") -- first "" is to enforce UDF's return type is void.
                                                 -- second "" is to enforce UDF has no arguments.
    if not e2func then e2err("Coroutine was called with undefined function [void "..funcName.."]") end
    local runtime = function()
        return true,e2func(table_copy(self))
    end
    return createCoroutine(self,runtime,e2func)
end

e2function coroutine coroutine(string funcName,table args)
    local e2func,_,returnType = getE2UDF(self,funcName,nil,"t") -- "t" is to enforce UDF has only 1 argument (of type table).
    if not e2func then e2err("Coroutine was called with undefined function ["..funcName.."]") end
    if not (returnType == "" or returnType == "t") then e2err("Coroutine's UDF ["..funcName.."] must return either void or table") end
    local runtime = function()
        return true,e2func(table_copy(self),buildBody{["t"]=args}) -- Pass the captured args table.
    end
    return createCoroutine(self,runtime,e2func)
end

__e2setcost(5)

local function customWait(instance,n)
    local endtime = CurTime() + n
    while endtime > CurTime() do
        coroutine_yield(popPrfData(instance))
    end
end

e2function void coroutineYield()
    if not runningCo(self) then e2err("Attempted to yield a coroutine without an e2 coroutine running.") end
    loadPrfData(self, coroutine_yield(popPrfData(self)))
end

e2function table coroutineYield(table data)
    if not runningCo(self) then e2err("Attempted to yield a coroutine without an e2 coroutine running.") end
    local prfData, result = coroutine_yield(popPrfData(self), data)
    loadPrfData(self, prfData)
    return result or newE2Table()
end

e2function void coroutine:yield()
    if not this then return end
    if not runningCo(self) then e2err("Attempted to yield a coroutine without an e2 coroutine running.") end
    loadPrfData(self, coroutine_yield(popPrfData(self)))
end

e2function table coroutine:yield(table data)
    if not this then return newE2Table() end
    if not runningCo(self) then e2err("Attempted to yield a coroutine without an e2 coroutine running.") end
    local prfData, result = coroutine_yield(popPrfData(self), data)
    loadPrfData(self, prfData)
    return result or newE2Table()
end

e2function void coroutine:wait(n)
    if not this then return end
    if not runningCo(self) then e2err("Attempted to wait outside of the coroutine given.") end
    customWait(self,n)
end

e2function void coroutineWait(n)
    if not runningCo(self) then e2err("Attempted to wait outside of an e2 coroutine.") end
    customWait(self,n)
end

e2function void coroutine:resume()
    if not this then return end
    local bench = SysTime()
    local co_success,prfDataOrDone = coroutine_resume(this,popPrfData(self))
    -- If this isn't true, then the coroutine has not finished.
    if prfDataOrDone == true then return end
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

e2function table coroutine:resume(table data)
    if not this then return newE2Table() end
    local bench = SysTime()
    local co_success,prfDataOrDone,result = coroutine_resume(this,popPrfData(self),data)
    -- If this isn't true, then the coroutine has not finished.
    if prfDataOrDone == true then return result or newE2Table() end
    if not co_success then
        local err = prfDataOrDone
        if err == "exit" then return newE2Table() end
        if err == "perf" then err = "tick quota exceeded" end
        err = string.match(err,"entities/gmod_wire_expression2/core/core.lua:%d+:(.*)") or err -- ( in e2 code ) error("hello world")
        e2err("COROUTINE ERROR: " .. err)
    end
    prfDataOrDone.time = prfDataOrDone.time + (SysTime() - bench)
    loadPrfData(self,prfDataOrDone)
    self.entity:UpdateOverlay()
    return result or newE2Table()
end

__e2setcost(3)

e2function string coroutine:status()
    if not this then return "" end
    return coroutine_status(this)
end

-- Returns the actual thread being run. No need to return a number before since we added the if operator on coroutines.
e2function coroutine coroutineRunning()
    return runningCo(self)
end

__e2setcost(15)

-- Returns the coroutine as if it was just created, 'reboot'ing it.
e2function coroutine coroutine:reboot()
    if not this then return end
    local e2func = self.coroutines[this]
    if not e2func then return end
    local runtime = function()
        return true,e2func(table_copy(self))
    end
    return createCoroutine(self,runtime,e2func)
end

e2function coroutine coroutine:reboot(table args)
    if not this then return end
    local e2func = self.coroutines[this]
    if not e2func then return end
    local runtime = function()
        return true,e2func(table_copy(self),buildBody{["t"]=args})
    end
    return createCoroutine(self,runtime,e2func)
end
