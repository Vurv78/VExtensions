
--[[
 _    __ ____   __  ___            __   ______                                 __   _  __     _  __ _  __        
| |  / // __ \ /  |/  /____   ____/ /  / ____/____   ____ ___   ____   ____ _ / /_ (_)/ /_   (_)/ /(_)/ /_ __  __
| | / // /_/ // /|_/ // __ \ / __  /  / /    / __ \ / __ `__ \ / __ \ / __ `// __// // __ \ / // // // __// / / /
| |/ // _, _// /  / // /_/ // /_/ /  / /___ / /_/ // / / / / // /_/ // /_/ // /_ / // /_/ // // // // /_ / /_/ / 
|___//_/ |_|/_/  /_/ \____/ \__,_/   \____/ \____//_/ /_/ /_// .___/ \__,_/ \__//_//_.___//_//_//_/ \__/ \__, /  
                                                            /_/                                         /____/   
 Gives access to SHARED VRMod functions in e2.
 Will at some point have access to the hooks as well.
]]

-- VRMod Shared Functions ported to E2 by Vurv.
-- Vurv#6428 (363590853140152321)

if not vrmod then print("VRMod was not detected! Please install VRMod to use the vrmod e2 extension.") end

-- Enabled by default, since this is super tame
E2Lib.RegisterExtension("vrmod", true, "Allows E2s to use vrmod functions that let you see where people's hands and vr headsets are for interactive chips!")

-- Rules:
-- All functions must have a VR suffix if they do not already contain one in the name.

__e2setcost(5)
-- Bools

e2function number entity:isPlayerInVR()
    return vrmod.IsPlayerInVR(this) and 1 or 0
end

e2function number entity:usingEmptyHandsVR()
    return vrmod.UsingEmptyHands(this) and 1 or 0
end

__e2setcost(10)
-- Positions and stuff
e2function vector entity:getHMDPosVR()
    return vrmod.GetHMDPos(this)
end

e2function angle entity:getHMDAngVR()
    return vrmod.GetHMDAng(this)
end

e2function vector entity:getLeftHandPosVR()
    return vrmod.GetLeftHandPos(this)
end

e2function angle entity:getLeftHandAngVR()
    return vrmod.GetLeftHandAng(this)
end

e2function vector entity:getRightHandPosVR()
    return vrmod.GetRightHandPos(this)
end

e2function angle entity:getRightHandAngVR()
    return vrmod.GetRightHandAng(this)
end

-- TODO: Make runOnVREnter and runOnVRExit one single runOn that returns 1 if entered, 0 if exit.

__e2setcost(5)

registerCallback("construct", function(self) -- On e2 placed, initalize our vrmod data.
	self.data.vrdata = {}
end)

-- Enter
vex.createE2Hook("VRMod_Start","vrmodenter",function(chip,before,ent)
    if not before then return end
    chip.context.data.vrdata["entity"] = ent
end)

e2function void runOnVREnter(bool)
    vex.listenE2Hook(self,"VRMod_Start",bool == 1)
end

e2function number vrEnterClk()
    return vex.didE2RunOn(self,"vrmodenter")
end

e2function entity vrEnterEntity()
    return self.data.vrdata["entity"]
end

-- Exit
vex.createE2Hook("VRMod_Exit","vrmod_exit")

e2function void runOnVRExit(bool)
    vex.listenE2Hook(self,"VRMod_Start",bool == 1)
end

e2function number vrExitClk()
    return vex.didE2RunOn(self,"vrmod_exit")
end

-- Pickup
vex.createE2Hook("VRMod_Pickup","vrmod_pickup")

e2function void runOnVRPickup(bool)
    vex.listenE2Hook(self,"VRMod_Pickup",bool == 1)
end

e2function number vrPickupClk()
    return vex.didE2RunOn(self,"vrmod_pickup")
end

--Drop
vex.createE2Hook("VRMod_Drop","vrmod_drop")

e2function void runOnVRDrop(bool)
    vex.listenE2Hook(self,"VRMod_Drop",bool == 1)
end

e2function number vrDropClk()
    return vex.didE2RunOn(self,"vrmod_drop")
end