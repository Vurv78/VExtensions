--[[
 _    ________        __    _ __                         
| |  / / ____/  __   / /   (_) /_  _________ ________  __
| | / / __/ | |/_/  / /   / / __ \/ ___/ __ `/ ___/ / / /
| |/ / /____>  <   / /___/ / /_/ / /  / /_/ / /  / /_/ / 
|___/_____/_/|_|  /_____/_/_.___/_/   \__,_/_/   \__, /  
                                                /____/   
]]
-- We will store our global functions here to help us with extension creation
-- Some examples of things that could be made are functions to return the e2 type of a variable, etc.
-- E2 Hook creators, E2 limiters / resource handlers just like how SF u

-- When we reload, we want to first destroy everything that can't be overwritten then run the files once again
-- Additionally, we might add some custom vex functions in other places than this library, like in an e2 core, so we want to save those.

-- Persistent variables 
local VEx_toconstruct = nil
local VEx_todestruct = nil

local REALM = SERVER and "SERVER" or "CLIENT"
local RLM = SERVER and "sv" or "cl"

local format = string.format
local function printf(...)
    print(format(...))
end

local function registerConcommand(name,callback)
    VEx_Destruction.concommands[name] = callback
end

local function buildVEx()
    if not VEx_toconstruct then return end -- If this is the first time VEx is being loaded.
    for Name,Constructor in pairs(VEx_toconstruct) do
        --print("Constructor .. " .. Name)
        Constructor()
    end
    VEx_toconstruct = nil
end

local function destroyVEx()
    -- We have to manually remove the concommands ourselves, cuz
    if VEx_todestruct then
        for Name,Callback in pairs(VEx_todestruct) do
            --print("Calling vex destructor " .. Name)
            Callback()
        end
    end
end

if vex then
    VEx_toconstruct = vex.constructors
    VEx_todestruct = vex.destructors
    VEx_topersist = vex.persists
end

vex = {
    persists = VEx_topersist or {},
    constructors = VEx_toconstruct or {},
    destructors = VEx_todestruct or {},
}

-- If we ever want to define a vex function in something that won't be reloaded alongside VEx, ie: an e2 core, a tool or something stored in autorun
vex.constructor = function(name,callback)
    vex.constructors[name] = callback
    callback()
end

-- Same reasoning as the constructor.
vex.destructor = function(name,callback)
    vex.destructors[name] = callback
end

-- Adds a callback that will be destroyed alongside VEx. Same reasoning as the constructor / destructor
vex.addChangeCallback = function(name,id,callback)
    local full_id = "vex_addChangeCallback(" .. id .. ")"
    cvars.AddChangeCallback(name,callback,full_id)
    vex.destructor(full_id,function()
        cvars.RemoveChangeCallback(name,full_id)
    end)
end

-- Todo: pcall the modules, so if they go wrong then don't call the destructors
-- fileName : foo_sh.lua
vex.reloadModule = function(fileName)
    local base_path = "vex_library/modules/"
    local shared_path = base_path .. fileName
    local realm_path = base_path .. string.lower(REALM) .. "/" .. fileName
    if file.Exists(shared_path,"LUA") then
        print("Reloaded SHARED module .. " .. fileName)
        include(shared_path)
    elseif file.Exists(realm_path,"LUA") then
        printf("Reloaded %s module .. %s",REALM,fileName)
        include(realm_path)
    else
        printf("[VEx] This is not a valid module! %s",fileName)
    end
end

-- Loads all of the modules in a directory
-- ie: vex_library/modules/*_sh.lua as the folder to reload all of the shared modules.
vex.loadModules = function(folder,doRun,type)
    local files = file.Find(folder,"LUA")
    for _,FileName in pairs(files) do
        local full_path = string.GetPathFromFilename(folder) .. FileName
        AddCSLuaFile(full_path)
        if doRun then
            include(full_path)
            print("Loaded " .. type .. " module .. " .. full_path)
        end
    end
end

vex.help = function()
    -- Prints information about VExtensions.
    print([[
=============================================================

This is the VExtensions addon's help command. Here you will find info about the addon.

This is an addon that adds several extensions and functions to expression2 and starfal
lex... (more info here)

=============================================================
    ]])
end

vex.printf = printf

vex.loadModules("vex_library/modules/*_sh.lua",true,"SHARED")
vex.loadModules("vex_library/modules/server/*.lua",SERVER,"SERVER")
vex.loadModules("vex_library/modules/client/*.lua",CLIENT,"CLIENT")

vex.addConsoleCommandShared("vex_reload",function()
    printf("Reloaded the %s vex library!", REALM)
    destroyVEx()
    include("vex_library/init_sh.lua")
    buildVEx()
end)

vex.addConsoleCommand("vex_help",vex.help)
vex.addConsoleCommand("vex_info",vex.help)