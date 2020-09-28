-- Author: Vurv, define runtime functions

--[[
   _____        __ ____   ___                                        ___ 
  / ___/ ___   / // __/  /   | _      __ ____ _ _____ _____ ___     |__ \
  \__ \ / _ \ / // /_   / /| || | /| / // __ `// ___// ___// _ \    __/ /
 ___/ //  __// // __/  / ___ || |/ |/ // /_/ // /   / /   /  __/   / __/ 
/____/ \___//_//_/    /_/  |_||__/|__/ \__,_//_/   /_/    \___/   /____/ 

 Adds functions similarly to regular-e2's self-aware core.
]]

-- Reused from coroutine-core
local function getE2UDF(compiler,funcname)
    local funcs = compiler.funcs
    local e2func = funcs[funcname]
    if not e2func then -- We will look for any udfs that have the name before the parenthesis.
        local fncnameproper = funcname:match("(%w*)%(") or funcname
        for Name,Runtime in pairs(funcs) do
            local proper = Name:match("(%w*)%(")
            if proper and proper==fncnameproper then return Runtime end
        end
    else
        return e2func
    end
end

local function getE2Func(compiler,funcname) 
    local funcs = wire_expression2_funcs
	local e2func = funcs[funcname]
    if not e2func then -- We will look for any udfs that have the name before the parenthesis.
        local fncnameproper = funcname:match("(%w*)%(") or funcname
		for Name,Data in pairs(funcs) do
            local proper = Name:match("(%w*)%(")
            if proper and proper==fncnameproper then return Data[3] end -- Return function runtime
        end
    else
        return e2func[3]
    end
end

-- Ex: print(ifdef(print(...))) or print(ifdef("e:health()"))
-- Returns number, 0 being not defined, 1 being defined as an official e2 function, 2 being a user-defined function
e2function number ifdef(string funcname)
	return getE2Func(self,funcname) and 1 or (getE2UDF(self,funcname) and 2 or 0)
end

-- Ex: print(getFunctionPath("print(...)")) Will return builtins or something, idr where print is actually
-- Returns the path where the function was defined, useful for finding whether something was added with an addon.
e2function string getFunctionPath(string funcname)
	local func = getE2Func(self,funcname)
	if not func then return "" end
	return debug.getinfo(func,"S").short_src
end