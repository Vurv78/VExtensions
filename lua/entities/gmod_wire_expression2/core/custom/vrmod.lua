

-- VRMod Shared Functions ported to E2 by Vurv.
-- Vurv#6428 (363590853140152321)

if not vrmod then print("VRMod was not detected! Please install VRMod to use the vrmod e2 extension.") end

-- Rules:
-- All functions must have a VR suffix if they do not already contain one in the name.

__e2setcost(5)
-- Bools

e2function number isPlayerInVR(entity ply)
    return vrmod.IsPlayerInVR(ply) and 1 or 0
end

e2function number usingEmptyHandsVR(entity ply)
    return vrmod.UsingEmptyHands(ply) and 1 or 0
end

__e2setcost(10)
-- Positions and stuff
e2function vector getHMDPosVR(entity ply)
    return vrmod.GetHMDPos(ply)
end

e2function angle getHMDAngVR(entity ply)
    return vrmod.GetHMDAng(ply)
end

e2function vector getLeftHandPosVR(entity ply)
    return vrmod.GetLeftHandPos(ply)
end

e2function angle getLeftHandAngVR(entity ply)
    return vrmod.GetLeftHandAng(ply)
end

e2function vector getRightHandPosVR(entity ply)
    return vrmod.GetRightHandPos(ply)
end

e2function angle getRightHandAngVR(entity ply)
    return vrmod.GetRightHandAng(ply)
end