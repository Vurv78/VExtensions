-- This runs all of the files in the vex library.
-- We actually don't need to include the serverside and clientside libraries, init_sh will handle that

AddCSLuaFile("vex_library/init_sh.lua")
include("vex_library/init_sh.lua")