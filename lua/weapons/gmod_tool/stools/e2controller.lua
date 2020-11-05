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

local selectedChip = nil -- CLIENT
local selectedChips = {} -- SERVER


local function hint(s,n)
    notification.AddLegacy(s,NOTIFY_HINT,n)
end

local function toolEvent(context,ply,info)
    context.data.E2CUser = ply
    if info then context.data.E2CRangerInfo = info end
end

if SERVER then
    -- Add custom e2controller funcs to vex.
    vex.constructor(function()
        function vex.getE2ControllerChip(ply)
            return selectedChips[ply]
        end
        function vex.setE2ControllerChip(ply,chip)
            -- Only when
            if chip ~= selectedChips[ply] and IsValid(chip) and chip.context then
                selectedChips[ply] = chip
                local context = chip.context
                if vex.e2DoesRunOn(context,"e2CSelectedClk") then
                    context.data.E2CConnectedPly = ply
                    toolEvent(context,ply)
                    chip:Execute()
                    context.data.E2CConnectedPly = nil
                end
            end
            selectedChips[ply] = chip
        end
    end)
end

function TOOL:LeftClick(trace)
    local ply = self:GetOwner()
    local plychip = CLIENT and selectedChip or selectedChips[ply]
    if CLIENT then
        if selectedChip then return true end
        if not IsFirstTimePredicted() then return end
        hint("You don't have an e2 chip selected!",1.5)
    elseif IsValid(plychip) then
        local context = plychip.context
        if vex.e2DoesRunOn(context,"E2CLeftMouseClk") then
            context.data.E2CLeftMouseClk = true
            toolEvent(context,ply,trace)
            plychip:Execute()
            context.data.E2CLeftMouseClk = nil
        end
    end
end

function TOOL:Reload(trace)
    local ply = self:GetOwner()
    local plychip = CLIENT and selectedChip or selectedChips[ply]
    if CLIENT then
        if selectedChip then return true end
        if not IsFirstTimePredicted() then return end
        hint("You don't have an e2 chip selected!",1.5)
    elseif IsValid(plychip) then
        local context = plychip.context
        if vex.e2DoesRunOn(context,"E2CReloadClk") then
            context.data.E2CReloadClk = true
            toolEvent(context,ply,trace)
            plychip:Execute()
            context.data.E2CReloadClk = nil
        end
    end
end
 
-- If you are looking at an e2 chip, will change e2 chip owner to this.
function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    local chip = trace.Entity
    if IsValid(chip) and chip:GetClass()=="gmod_wire_expression2" then
        -- Set the selected chip
        if CLIENT then
            if not IsFirstTimePredicted() then return true end
            notification.AddLegacy( "Selected E2 Chip", NOTIFY_HINT, 2 )
            selectedChip = chip
        else
            print("rcset")
            vex.setE2ControllerChip(ply,chip)
        end
    else
        local plychip = CLIENT and selectedChip or selectedChips[ply]
        if IsValid(plychip) then
            if CLIENT then return true end
            local context = plychip.context
            if vex.e2DoesRunOn(context,"E2CRightMouseClk") then
                context.data.E2CRightMouseClk = true
                toolEvent(context,ply,trace)
                plychip:Execute()
                context.data.E2CRightMouseClk = nil
            end
            return true
        end
    end
end