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
local coroutine_running, coroutine_create, coroutine_resume, coroutine_yield, coroutine_status, coroutine_wait = coroutine.running, coroutine.create, coroutine.resume, coroutine.yield, coroutine.status, coroutine.wait
local table_copy, string_match, string_replace = table.Copy, string.match, string.Replace
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
    self.coroutines = {
        stack_level = 0
    }
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

-- Resumes a coroutine created with E2.
local function e2coroutine_resume(self, thread, data)
    self.coroutines.running = thread
    local co_success, result_or_error = coroutine_resume(thread, data)
    self.coroutines.running = nil
    if co_success then
        -- Could be done, could've successfully yielded.
        return result_or_error
    end
    -- "Error" handling for E2 coroutine runtime.
    local err = result_or_error
    if err == "exit" then return end -- exit() or reset()
    if err == "perf" then return throw("tick quota exceeded") end
    err = string_match(err, "entities/gmod_wire_expression2/core/core.lua:%d+: (.*)") or err
    -- Anti-recursion StartsWith check to see if the prefix was already applied inside another coroutine scope's error.
    err = (not err:StartWith("Coroutine Error: ")) and ("Coroutine Error: "..err) or err
    return throw(string_replace(err, "%", "%%"))
end

-- Returns the currently running E2 coroutine. (Doesn't return if a coroutine outside of E2 is running.)
local function e2coroutine_running(self)
    return self.coroutines.running
end

-- Returns a new coroutine that behaves just the same as when the given coroutine was created.
local function e2coroutine_reboot(self, thread, args)
    local udf = self.coroutines[thread]
    if udf then
        return createCoroutine(self, udf, args)
    end
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

local function parentTable(t, parent)
    local stockpile = table_copy(parent)
    return setmetatable(t, {
        __index = function(_, k)
            local ret = stockpile[k]
            return ret~=nil and ret or parent[k]
        end,
        __newindex = function(_, k, v)
            stockpile[k] = v
            parent[k] = v
        end
    })
end

local function createCoroutine(self, e2_udf, arg_table)
    -- Anti-coroutine creation infinite loop.
    local active_thread = e2coroutine_running(self)
    if active_thread then
        self.coroutines.stack_level = self.coroutines.stack_level + 1
        -- Anything higher than 15 starts to lag servers. 30+ Seems to already crash.
        -- Maybe this new system is just a whole lot more intensive. Then again recurring 15 times is already useless.
        if self.coroutines.stack_level >= 15 then return throw("Coroutine stack overflow") end
    else
        self.coroutines.stack_level = 0
    end

    local instance = setmetatable(table_copy(self), {
        __index = self,
        __newindex = self
    })

    rawset(instance, "GlobalScope", parentTable({}, self.GlobalScope))
    rawset(instance, "Scopes", parentTable({}, self.Scopes))

    rawset(instance, "coroutines", nil)
    rawset(instance, "prf", nil)

    local thread = coroutine_create(function()
        local ret = e2_udf(instance, arg_table and buildBody({["t"]=arg_table}) or nil)
        self.coroutines[coroutine_running()] = nil
        return ret
    end)
    self.coroutines[thread] = e2_udf
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
    return coroutine_yield(self) or newE2Table()
end

e2function table coroutineYield(table data)
    assertRunning(self, true)
    return coroutine_yield(self, data) or newE2Table()
end

e2function table coroutine:yield()
    if not this then return newE2Table() end
    assertRunning(self, true)
    return coroutine_yield(self) or newE2Table()
end

e2function table coroutine:yield(table data)
    if not this then return newE2Table() end
    assertRunning(self, true)
    return coroutine_yield(self, data) or newE2Table()
end

e2function void coroutine:wait(seconds)
    if not this then return end
    assertRunning(self)
    coroutine_wait(seconds)
end

e2function void coroutineWait(seconds)
    assertRunning(self)
    coroutine_wait(seconds)
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
