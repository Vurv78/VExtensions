--[[
    _________      ______            __   ______              
   / ____/__ \    /_  __/___  ____  / /  / ____/___  ________ 
  / __/  __/ /     / / / __ \/ __ \/ /  / /   / __ \/ ___/ _ \
 / /___ / __/     / / / /_/ / /_/ / /  / /___/ /_/ / /  /  __/
/_____//____/    /_/  \____/\____/_/   \____/\____/_/   \___/ 
    This is a tool that will be able to be used on an e2 chip, and that chip will be able
        to run based on actions you make with the tool.
]]
 
TOOL.Category		= "VExtensions"
TOOL.Name			= "E2 Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if CLIENT then
	language.Add( "Tool.e2controller.name", "E2 Controller")
	language.Add( "Tool.e2controller.desc", "Allows the selected e2 to execute on controls used from the tool.")
	language.Add( "Tool.e2controller.left", "Left Click Action")
	language.Add( "Tool.e2controller.right", "Right Click Action, or Select Chip")
	language.Add( "Tool.e2controller.reload", "Reload Action")
	TOOL.Information = { "left", "right", "reload" }
end

local selectedChips = {}

function TOOL:LeftClick(trace)
    if CLIENT then return end
    local ply = self:GetOwner()
    return true
end
 
-- If you are looking at an e2 chip, will change e2 chip owner to this.
function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    local chip = trace.Entity
    if chip then
        if chip:GetClass()=="gmod_wire_expression2" then
            selectedChips[ply] = chip
            if CLIENT then
                notification.AddLegacy( "Selected E2 Chip", NOTIFY_HINT, 2 )
            end
        end
    end
    return true
end