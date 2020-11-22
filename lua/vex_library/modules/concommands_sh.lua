
local REALM = SERVER and "SERVER" or "CLIENT"
local RLM = SERVER and "sv" or "cl"

local concommands = {}

local function registerConcommand(storeIt,name,callback,...)
    if storeIt then concommands[name] = callback end
    concommand.Add(name,callback,...)
end

vex.addConsoleCommand = function(name,callback,...)
    registerConcommand(true,name,callback,...)
end

vex.addConsoleCommandShared = function(name,callback,...)
    registerConcommand(true,name .. "_" .. RLM,callback,...)
end

-- Reload a specific module
vex.addConsoleCommand("vex_reload",function(ply,cmd,args)
    if not args[1] then print("Use vex_reload_" .. RLM .. " if you want to reload all modules.") return end
    vex.reloadModule(args[1])
end,function(cmd,argStr)
    if not argStr then return end
    -- Autocorrect
    local arg = argStr:match("%s([%w%.]*)") -- cringe
    local results = {}
    local potential = file.Find("vex_library/modules/" .. string.lower(REALM) .. "/*.lua","LUA")
    table.Add(potential,file.Find("vex_library/modules/*_sh.lua","LUA"))
    if not potential then return results end
    if not arg then return potential end
    for _,FileName in pairs(potential) do
        if string.find(FileName,arg) then table.insert(results,FileName) end
    end
    return results
end,"Reloads a specific VExtensions module.")

vex.destructor("concommands_sh",function()
    -- Remove all of the concommands when VEx is reloading.
    for Name,Callback in pairs(concommands) do
        --print("Removing concommand ... " .. Name)
        concommand.Remove(Name)
    end
end)