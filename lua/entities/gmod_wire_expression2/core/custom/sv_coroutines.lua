--[[
   ______                            __   _
  / ____/____   _____ ____   __  __ / /_ (_)____   ___   _____
 / /    / __ \ / ___// __ \ / / / // __// // __ \ / _ \ / ___/
/ /___ / /_/ // /   / /_/ // /_/ // /_ / // / / //  __/(__  )
\____/ \____//_/    \____/ \__,_/ \__//_//_/ /_/ \___//____/

 Gives access to Lua's coroutines to E2, can do everything Lua coroutines can do,
    Can't halt Lua's coroutines, so it is safe.
]]

-- Note that this code is really hacky.
-- Currently it only saves the e2's scope as it is going into the coroutine and syncs cpu data with the main thread as they're resumed.

-- Function localization (local lookup is faster).
local coroutine_running, coroutine_create, coroutine_resume, coroutine_yield, coroutine_status = coroutine.running, coroutine.create, coroutine.resume, coroutine.yield, coroutine.status
local table_copy = table.Copy
local string_match = string.match
local newE2Table, buildBody, throw, getE2UDF = vex.newE2Table, vex.buildBody, vex.throw, vex.getE2UDF

vex.registerExtension("coroutines", false, "Allows E2s to use coroutines.")

-- Coroutine Object handling

registerType("coroutine", "xco", nil,
    nil,
    nil,
    function(ret)
        if not ret then return end
        if type(ret)~="thread" then throw("Return value is neither nil nor a coroutine, but a %s!",type(ret)) end
    end,
    function(v)
        return type(v)~="thread"
    end
)

-- Initialize coroutines
registerCallback("construct", function(self)
    self.coroutines = {}
end)


-- When the E2 is being cleaned up, delete all of the coroutines.
registerCallback("destruct",function(self)
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

local function popPrfData(self)
    return {
        prf = self.prf,
        prfcount = self.prfcount,
        prfbench = self.prf,
        timebench = self.timebench,
        time = self.time,
    }
end

local function loadPrfData(self,data)
    for K,V in pairs(data) do
        self[K] = V
    end
end

-- Yields the coroutine, but also sends prf data for coroutines to update the parent e2 with.
local function e2coroutine_yield(self,data)
    local prfData, result = coroutine_yield(popPrfData(self), data)
    loadPrfData(self, prfData)
    return result or newE2Table()
end

-- Makes the e2 coroutine wait for n amount of seconds. Custom to use the e2coroutine_yield function
local function e2coroutine_wait(self,n)
    local endtime = CurTime() + n
    while endtime > CurTime() do
        e2coroutine_yield(self)
    end
end

-- Errors with the prefix "Coroutine Error: ". Safe from coroutine creation recursion
local function e2coroutine_error(err)
    if err == "exit" then return end -- exit() or reset()
    if err == "perf" then return throw("tick quota exceeded") end
    err = string_match(err,"entities/gmod_wire_expression2/core/core.lua:%d+: (.*)") or err
    err = (not err:StartWith("Coroutine Error: ")) and "Coroutine Error: "..err or err
    return throw(err)
end

-- Resumes a coroutine made with expression2. Loads prfdata that the coroutine gives since we don't run coroutines in safe mode.
local function e2coroutine_resume( self, thread, data )
    local bench = SysTime()
    local co_success,prfDataOrDone,result = coroutine_resume(thread,popPrfData(self),data)
    -- Has to check 'true' explicitly. prfDataOrDone either returns a table or bool true.
    if prfDataOrDone == true then return result end
    if co_success then
        -- Coroutine yielded or has finished
        prfDataOrDone.time = prfDataOrDone.time + (SysTime() - bench)
        loadPrfData(self,prfDataOrDone)
        self.entity:UpdateOverlay()
        return result
    else
        -- Coroutine errored.
        e2coroutine_error(prfDataOrDone)
    end
end

-- Returns the currently running e2 coroutine. (Doesn't return if a coroutine outside of e2 is running)
local function e2coroutine_running(self)
    local thread = coroutine_running()
    if thread and self.coroutines[thread] then return thread end
end

-- Returns a new coroutine that behaves just the same as when the given coroutine was created.
local function e2coroutine_reboot(self,thread,args)
    local thread_info = self.coroutines[thread]
    if not thread_info then return end
    local e2func = thread_info[1]
    return createCoroutine(self,e2func,args)
end

local function getCoroutineUDF( self, func_name, has_args )
    local e2func,_,returnType = getE2UDF(self,func_name,nil,has_args and "t" or "")
    if not e2func then throw("Coroutine was called with undefined function [%s%s]",func_name,has_args and "(table)" or "(void)") end
    if not (returnType == "" or returnType == "t") then throw("Coroutine's UDF [%s] must return either void or table",func_name) end
    return e2func
end

local function assertRunning(self,co_yield)
    -- Attempt to yield across C-call boundary. Keyword is either 'yield' or 'wait'
    if not e2coroutine_running(self) then
        throw("Attempted to %s coroutine without an e2 coroutine running.",yielding and "yield a" or "wait")
    end
end

local function createCoroutine(self,e2func,argTable)
    -- Anti-coroutine creation infinite loop. As seen in Starfall :v
    local activeThread = e2coroutine_running(self)
    local stackLevel = 1
    if activeThread then
        local threadInfo = self.coroutines[activeThread]
        stackLevel = threadInfo[2]
        if stackLevel >= 40 then return throw("Coroutine stack overflow") end
    end
    local thread = coroutine_create(function()
        return true,e2func(table_copy(self), e2func and buildBody{["t"]=argTable} or nil )
    end)
    -- Data that we keep so we know whether a coroutine was created by e2 or not.
    self.coroutines[thread] = {e2func,stackLevel+1}
    return thread
end

__e2setcost(20)

e2function coroutine coroutine(string func_name)
    -- Coroutines can only return a table of data in order to keep type-safety.
    local e2func = getCoroutineUDF(self,func_name)
    return createCoroutine(self,e2func)
end

e2function coroutine coroutine(string func_name,table args)
    local e2func = getCoroutineUDF(self,func_name,true)
    return createCoroutine(self,e2func,args)
end

__e2setcost(5)

e2function table coroutineYield()
    assertRunning(self,true)
    return e2coroutine_yield(self)
end

e2function table coroutineYield(table data)
    assertRunning(self,true)
    return e2coroutine_yield(self,data)
end

e2function table coroutine:yield()
    if not this then return end
    assertRunning(self,true)
    return e2coroutine_yield(self)
end

e2function table coroutine:yield(table data)
    if not this then return newE2Table() end
    assertRunning(self,true)
    return e2coroutine_yield(self,data)
end

e2function void coroutine:wait(n)
    if not this then return end
    assertRunning(self)
    e2coroutine_wait(self,n)
end

e2function void coroutineWait(n)
    assertRunning(self)
    e2coroutine_wait(self,n)
end

e2function table coroutine:resume()
    if not this then return end
    return e2coroutine_resume(self,this) or newE2Table()
end

e2function table coroutine:resume(table data)
    if not this then return newE2Table() end
    return e2coroutine_resume(self,this,data) or newE2Table()
end

__e2setcost(3)

e2function string coroutine:status()
    if not this then return "" end
    return coroutine_status(this)
end

-- Returns the actual thread being run. No need to return a number before since we added the if operator on coroutines.
e2function coroutine coroutineRunning()
    return e2coroutine_running(self)
end

__e2setcost(15)

-- Returns the coroutine as if it was just created, 'reboot'ing it.
e2function coroutine coroutine:reboot()
    if not this then return end
    return e2coroutine_reboot(self,this)
end

e2function coroutine coroutine:reboot(table args)
    if not this then return end
    return e2coroutine_reboot(self,this,args)
end
