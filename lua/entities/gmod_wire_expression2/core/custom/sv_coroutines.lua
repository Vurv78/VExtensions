--[[
   ______                            __   _
  / ____/____   _____ ____   __  __ / /_ (_)____   ___   _____
 / /    / __ \ / ___// __ \ / / / // __// // __ \ / _ \ / ___/
/ /___ / /_/ // /   / /_/ // /_/ // /_ / // / / //  __/(__  )
\____/ \____//_/    \____/ \__,_/ \__//_//_/ /_/ \___//____/

 Gives access to Lua's coroutines to E2, can do everything Lua coroutines can do,
    Can't halt Lua's coroutines, so it is safe.
]]

-- Shouldn't be hacky anymore. Behaves just like regular e2, and 'local' variables are useful as they are the only ones that persist in a thread now.

-- Function localization (local lookup is faster).
local coroutine_running, coroutine_create, coroutine_resume, coroutine_yield, coroutine_status, coroutine_wait = coroutine.running, coroutine.create, coroutine.resume, coroutine.yield, coroutine.status, coroutine.wait
local string_match, string_replace = string.match, string.Replace -- String Library
local table_copy = table.Copy -- Table Library
local newE2Table, buildBody, throw, getE2UDF = vex.newE2Table, vex.buildBody, vex.throw, vex.getE2UDF -- VExtensions Library

vex.registerExtension("coroutines", false, "Allows E2s to use coroutines.")

-- Coroutine Object handling
registerType("coroutine", "xco", nil,
    nil,
    nil,
    function(ret)
        -- For some reason we don't throw an error here.
        -- See https://github.com/wiremod/wire/blob/501dd9875ab1f6db37a795e1f9a946d382db4f1f/lua/entities/gmod_wire_expression2/core/entity.lua#L10

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

-- Resumes a coroutine made with expression2.
local function e2coroutine_resume( self, thread, data )
    self.coroutines.running = thread
    local co_success, result_or_error = coroutine_resume(thread, data)
    self.coroutines.running = nil
    if co_success then
        -- Could be done, could've successfully yielded.
        return result_or_error
    else
        -- Error in coroutine runtime. Prefixes with "Coroutine Error: "
        local err = result_or_error
        if err == "exit" then return end -- exit() or reset()
        if err == "perf" then return throw("tick quota exceeded") end
        err = string_match(err, "^entities/gmod_wire_expression2/core/core.lua:%d+: (.*)$") or err
        -- Anti-recursion StartsWith check to see if the prefix was already applied inside another coroutine scope's error.
        err = (not err:StartWith("Coroutine Error: ")) and ("Coroutine Error: "..err) or err
        return throw( string_replace(err, "%", "%%") ) -- People could error with an % in it and break patterns
    end
end
-- Returns the currently running e2 coroutine. (Doesn't return if a coroutine outside of e2 is running)
local function e2coroutine_running(self)
    return self.coroutines.running
end

-- Returns a new coroutine that behaves just the same as when the given coroutine was created.
local function e2coroutine_reboot(self,thread,args)
    local udf = self.coroutines[thread]
    if not udf then return end
    return createCoroutine(self,udf,args)
end

local function getCoroutineUDF( self, func_name, has_args )
    local e2func, _, returnType = getE2UDF(self, func_name, nil, has_args and "t" or "")
    if not e2func then throw("Coroutine was called with undefined function [%s(%s)]", func_name, has_args and "table" or "") end
    if not (returnType == "" or returnType == "t") then throw("Coroutine's UDF [%s] must return either void or table", func_name) end
    return e2func
end

local function assertRunning(self, yielding)
    -- Attempt to yield across C-call boundary. Keyword is either 'yield' or 'wait'
    if not e2coroutine_running(self) then
        throw("Attempted to %s coroutine without an e2 coroutine running.", yielding and "yield a" or "wait")
    end
end

local function createCoroutine(self, e2_udf, arg_table)
    -- Anti-coroutine creation infinite loop.
    local active_thread = e2coroutine_running(self)

    local stack_level = 0
    local thread_data = self.coroutines[active_thread]
    if active_thread then
        thread_data[2] = thread_data[2] + 1
        stack_level = thread_data[2]
        -- Ok, we are back if not at a better level of cpu time with coroutines.
        -- Still going to set it at 50 because e2 should be pretty slow in comparison to lua.
        if stack_level >= 50 then return throw("Coroutine stack overflow") end
    end

    local instance = table_copy(self)
    instance.GlobalScope = self.GlobalScope
    instance.Scopes = self.Scopes
    instance.coroutines = self.coroutines
    instance.prf = nil

    instance = setmetatable(instance, {
        __index = function(_,k)
            return self[k] or 0 -- This is fucking stupid, prf sometimes returns nil?
            -- Breaks here: wire/lua/entities/gmod_wire_expression2/init.lua L175 ``if self.context.prfcount + self.context.prf - e2_softquota > e2_hardquota then ``
        end,
        __newindex = self
    })

    local thread = coroutine_create(function()
        local ret = e2_udf(instance, arg_table and buildBody({["t"]=arg_table}) or nil)
        self.coroutines[coroutine_running()] = nil
        return ret
    end)
    self.coroutines[thread] = {e2_udf, stack_level}
    return thread
end

__e2setcost(20)

e2function coroutine coroutine(string func_name)
    -- Coroutines can only return a table of data in order to keep type-safety.
    local e2func = getCoroutineUDF(self, func_name)
    return createCoroutine(self, e2func)
end

e2function coroutine coroutine(string func_name, table args)
    local e2func = getCoroutineUDF(self, func_name, true)
    return createCoroutine(self, e2func, args)
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

e2function string coroutine:status()
    if not this then return "" end
    return coroutine_status(this)
end

-- Returns the currently active E2 coroutine/thread (or nil if this is running on the main thread).
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

e2function coroutine nocoroutine()
    return nil
end