--[[
    ____                 _________
   / __ \__  ______     / ____/__ \
  / /_/ / / / / __ \   / __/  __/ /
 / _, _/ /_/ / / / /  / /___ / __/
/_/ |_|\__,_/_/ /_/  /_____//____/

 Allows for calling user-defined functions dynamically at runtime (similar to callable strings),
    with ability to check for success - to know whether an error occurred (like Lua pcall),
        and also allows to pass arguments (via table overload) and retrieve the return value.
]]

-- Function localization (local lookup is faster).
local table_remove = table.remove
local luaTableToE2, getE2UDF, buildBody, throw = vex.luaTableToE2, vex.getE2UDF, vex.buildBody, vex.throw
local PreProcessor, Tokenizer,Parser,Optimizer,Compiler = E2Lib.PreProcessor, E2Lib.Tokenizer, E2Lib.Parser, E2Lib.Optimizer, E2Lib.Compiler

-- We use this for `try` E2 functions
local function runE2InstanceSafe(compiler,func,returnType,body)
    local args = {pcall(func,compiler,body)}
    if table_remove(args,1) then -- We don't even use the success var anyway
        return true,nil,args[1]
    end
    -- If unsuccessful, don't return args, that would be a waste
    local errmsg = table_remove(args,1)
    if errmsg == "exit" then return true,nil,wire_expression_types2[returnType][2] end -- nice exit()
    if errmsg == "perf" then errmsg = "tick quota exceeded" end
    return false,errmsg
end

local function specializedPassBackToE2(result, returnType)
    -- E2 is going to enforce type-safety for us, so we know *exactly* which type we are dealing with :D
    -- This is 100% reliable; PERFECTION! (Do not touch this code!)
    return (returnType == "" or result == nil)
       and {n={[1]=1},ntypes={[1]="n"},s={},stypes={},size=1} -- Special case for void
       or  {n={[1]=1,[2]=result},ntypes={[1]="n",[2]=returnType},s={},stypes={},size=2}
end

-- opcosts don't really matter in e2, especially for this function since it uses it's own compiler, so it runs just as if it was actually called
__e2setcost(3)

-- Literally like pcall()
-- Returns table, 1st field is a number stating whether the function executed successfully, 2nd field is the return value of the given function.
e2function table try(string funcName)
    local tryFunc,_,returnType = getE2UDF(self,funcName,nil,"") -- "" is to enforce UDF has no arguments.
    if not tryFunc then return luaTableToE2{false,"Try was called with undefined function ["..funcName.."]"} end
    local success,errstr,result = runE2InstanceSafe(self,tryFunc,returnType)
    if success then
        return specializedPassBackToE2(result,returnType)
    end
    return luaTableToE2{false,errstr}
end

e2function table try(string funcName, table args)
    local tryFunc,_,returnType = getE2UDF(self,funcName,nil,"t") -- "t" is to enforce UDF has only 1 argument (of type table).
    if not tryFunc then return luaTableToE2{false,"Try was called with undefined function ["..funcName.."]"} end
    local success,errstr,result = runE2InstanceSafe(self,tryFunc,returnType,buildBody{["t"]=args}) -- Pass the captured args table.
    if success then
        return specializedPassBackToE2(result,returnType)
    end
    return luaTableToE2{false,errstr}
end

-- Runs E2 Code given from a string.
-- Safemode will make it behave as if it were pcalled.
-- Will use the inputs / outputs / persists of the instance's chip.
-- (These differences are why it's separate from vex_library/server/tests.lua )
local function runE2String( self, code, safeMode )
    local chip = self.entity
    local throw = safeMode and string.format or throw
    self:PushScope()
    local status, directives, code = PreProcessor.Execute(code,nil,self)
    if not status then return throw("runString: %s", directives) end
    local status, tokens = Tokenizer.Execute(code)
    if not status then return throw("runString: %s", tokens) end
    local status, tree, dvars = Parser.Execute(tokens)
    if not status then return throw("runString: %s", tree) end
    status,tree = Optimizer.Execute(tree)
    if not status then return throw("runString: %s", tree) end

    local status, script, inst = Compiler.Execute(tree, chip.inports[3], chip.outports[3], chip.persists and chip.persists[3] or {}, dvars, chip.includes)
    if not status then return throw("runString: %s", script) end
    if safeMode then
        local success,why = pcall( script[1], self, script )
        self:PopScope()
        return success and "" or ( vex.properE2Error( why ) or "" )
    else
        script[1](self,script)
        self:PopScope()
        return ""
    end
end

-- DOES NOT run in safe mode by default. Pass a number that isn't 0 into safeMode to make it behave like if it were pcalled.
e2function string runString(string code, safeMode)
    return runE2String( self, code, safeMode~=0 )
end

e2function void runString(string code)
    runE2String( self, code, false )
end