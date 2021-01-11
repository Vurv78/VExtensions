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
-- Currently it only saves the E2's scope as it is going into the coroutine and syncs CPU data with the main thread as they're resumed.

-- Function localization (local lookup is faster).
local coroutine_running, coroutine_create, coroutine_resume, coroutine_yield, coroutine_status = coroutine.running, coroutine.create, coroutine.resume, coroutine.yield, coroutine.status
local table_copy = table.Copy
local string_match, string_replace = string.match, string.Replace
local newE2Table, buildBody, throw, getE2UDF = vex.newE2Table, vex.buildBody, vex.throw, vex.getE2UDF

vex.registerExtension("coroutines", false, "Allows E2s to use coroutines.")

-- Coroutine Object handling

registerType("coroutine", "xco", nil,
    nil,
    nil,
    function(ret)
        if not (ret==nil or type(ret)=="thread") then throw("Return value is neither nil nor a coroutine, but a %s!", type(ret)) end
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
registerCallback("destruct", function(self)
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

local function loadPrfData(self, data)
    -- Performs a shallow-copy of the data table into the 'self'.
    for k, v in next, data do self[k] = v end
end

-- Yields the coroutine, but also sends PrfData for coroutines to update the E2 with.
local function e2coroutine_yield(self, data)
    local prfData, result = coroutine_yield(popPrfData(self), data)
    loadPrfData(self, prfData)
    return result or newE2Table()
end

-- Makes the E2 coroutine wait for the given amount of seconds. (The coroutine can't be resumed during this period.)
local function e2coroutine_wait(self, seconds)
    local endtime = CurTime() + seconds
    while endtime > CurTime() do
        e2coroutine_yield(self)
    end
end

-- "Error" handling for E2 coroutines.
local function e2coroutine_error(err)
    if err == "exit" then return end -- exit() or reset()
    if err == "perf" then return throw("tick quota exceeded") end
    err = string_match(err, "entities/gmod_wire_expression2/core/core.lua:%d+: (.*)") or err
    err = (not err:StartWith("Coroutine Error: ")) and ("Coroutine Error: "..err) or err
    return throw(string_replace(err, "%", "%%"))
end

-- Resumes a coroutine made with E2. Loads PrfData that the coroutine gives since we don't run coroutines in safe mode.
local function e2coroutine_resume(self, thread, data)
    local bench = SysTime()
    local co_success, prfDataOrDone, result = coroutine_resume(thread, popPrfData(self), data)
    -- Has to check 'true' explicitly. prfDataOrDone either returns a table or bool true.
    if prfDataOrDone == true then return result end
    if co_success then
        -- Coroutine yielded or has finished
        prfDataOrDone.time = prfDataOrDone.time + (SysTime() - bench)
        loadPrfData(self, prfDataOrDone)
        self.entity:UpdateOverlay()
        return result
    end
    -- Coroutine has errored.
    e2coroutine_error(prfDataOrDone)
end

-- Returns the currently running E2 coroutine. (Doesn't return if a coroutine outside of E2 is running.)
local function e2coroutine_running(self)
    local thread = coroutine_running()
    if thread and self.coroutines[thread] then return thread end
end

-- Returns a new coroutine that behaves just the same as when the given coroutine was created.
local function e2coroutine_reboot(self, thread, args)
    local thread_info = self.coroutines[thread]
    if not thread_info then return end
    local e2func = thread_info[1]
    return createCoroutine(self, e2func, args)
end

local function getCoroutineUDF(self, func_name, has_args)
    local e2func, _, return_type = getE2UDF(self, func_name, nil, has_args and "t" or "")
    if not e2func then
        throw("Coroutine was called with undefined function [%s(%s)]", func_name, has_args and "table" or "")
    end
    if not (return_type == "" or return_type == "t") then
        throw("Coroutine's UDF [%s] must return either void or table", func_name)
    end
    return e2func
end

local function assertRunning(self, yielding)
    -- Attempt to yield across C-call boundary. (Keyword is either 'yield' or 'wait'.)
    if not e2coroutine_running(self) then
        throw("Attempted to %s coroutine without an active E2 coroutine running", yielding and "yield a" or "wait")
    end
end

local function createCoroutine(self, e2func, arg_table)
    -- Anti-coroutine creation infinite loop. As seen in Starfall :v
    local active_thread = e2coroutine_running(self)
    local stack_level = 0
    if active_thread then
        local thread_info = self.coroutines[active_thread]
        stack_level = thread_info[2]
        if stack_level >= 40 then return throw("Coroutine stack overflow") end
    end
    local thread = coroutine_create(function()
        return true, e2func(table_copy(self), arg_table and buildBody{["t"]=arg_table} or nil)
    end)
    -- Data that we keep so we know whether a coroutine was created by E2 or not.
    self.coroutines[thread] = {e2func, stack_level+1}
    return thread
end

__e2setcost(20)

e2function coroutine coroutine(string func_name)
    -- Coroutines may only return a table of data in order to keep type-safety.
    return createCoroutine(self, getCoroutineUDF(self, func_name))
end

e2function coroutine coroutine(string func_name, table args)
    return createCoroutine(self, getCoroutineUDF(self, func_name, true), args)
end

__e2setcost(5)

e2function table coroutineYield()
    assertRunning(self, true)
    return e2coroutine_yield(self)
end

e2function table coroutineYield(table data)
    assertRunning(self, true)
    return e2coroutine_yield(self, data)
end

e2function table coroutine:yield()
    if not this then return newE2Table() end
    assertRunning(self, true)
    return e2coroutine_yield(self)
end

e2function table coroutine:yield(table data)
    if not this then return newE2Table() end
    assertRunning(self, true)
    return e2coroutine_yield(self, data)
end

e2function void coroutine:wait(seconds)
    if not this then return end
    assertRunning(self)
    e2coroutine_wait(self, seconds)
end

e2function void coroutineWait(seconds)
    assertRunning(self)
    e2coroutine_wait(self, seconds)
end

e2function table coroutine:resume()
    if not this then return newE2Table() end
    return e2coroutine_resume(self, this) or newE2Table()
end

e2function table coroutine:resume(table data)
    if not this then return newE2Table() end
    return e2coroutine_resume(self, this, data) or newE2Table()
end

__e2setcost(3)

-- Returns the status of the coroutine (either "suspended", "running" or "dead").
e2function string coroutine:status()
    if not this then return "" end
    return coroutine_status(this)
end

-- Returns the currently active E2 coroutine/thread (or nil if running on the main thread).
e2function coroutine coroutineRunning()
    return e2coroutine_running(self)
end

__e2setcost(15)

-- Returns the coroutine as if it was just created, 'reboot'ing it.
e2function coroutine coroutine:reboot()
    if not this then return end
    return e2coroutine_reboot(self, this)
end

e2function coroutine coroutine:reboot(table args)
    if not this then return end
    return e2coroutine_reboot(self, this, args)
end

__e2setcost(1)

-- Returns an "invalid" coroutine value.
e2function coroutine nocoroutine()
    return nil
end
