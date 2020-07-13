-- Starfall library functions
local checkluatype = SF.CheckLuaType
local registerPrivilege = SF.Permissions.registerPrivilege or SF.Permissions.registerprivilege -- wtf Starfall

-- Register clientside permissions.
-- 1 = Only you, 2 = Friends Only, 3 = Anyone, 4 = No one 
registerPrivilege("entities.setEyeAngles", "Set your EyeAngles", "Allows the user to set your eye angles", { client = { default = 1 } })

--- Functions for the VRMod addon.
-- @name vrmod
-- @shared
-- @class library
-- @libtbl vrmod_lib
SF.RegisterLibrary("vrmod")

return function(instance)
    -- Local to each chip call

    -- SF Library functions
    local checkpermission = instance.player ~= NULL and SF.Permissions.check or function() end
    -- Starfall types to Lua types
    local aunwrap = instance.Types.Angle.Unwrap
    local player_methods, pwrap, punwrap = instance.Types.Player.Methods, instance.Types.Player.Wrap, instance.Types.Player.Unwrap
    local vwrap, vunwrap = instance.Types.Vector.Wrap, instance.Types.Vector.Unwrap
    local awrap, aunwrap = instance.Types.Angle.Wrap, instance.Types.Angle.Unwrap
    -- Starfall types to Lua types

    local vrmod_lib = instance.Libraries.vrmod
    print(vrmod_lib)

    local SFUser = instance.player

    local function getply(self)
        local ent = punwrap(self)
        if ent:IsValid() then
            return ent
        else
            SF.Throw("Entity is not valid.", 3)
        end
    end

    --- Returns if the player is in VR.
    -- @param Player player
    -- @shared
    -- @return True if player is in VR
    function vrmod_lib.isPlayerInVR(ply)
        return vrmod.IsPlayerInVR(getply(ply))
    end

    --- Returns if the player is using empty hands
    -- @param Player player
    -- @shared
    -- @return True if player is using empty hands
    function vrmod_lib.usingEmptyHands(ply)
        return vrmod.UsingEmptyHands(getply(ply))
    end

    --- Returns vector HMD pos
    -- @param Player player
    -- @shared
    -- @return Vector HMD Pos
    function vrmod_lib.getHMDPos(ply)
        return vwrap(vrmod.GetHMDPos(getply(ply)))
    end

    --- Returns angle HMD angle
    -- @param Player player
    -- @shared
    -- @return Angle HMD Angle
    function vrmod_lib.getHMDAng(ply)
        return awrap(vrmod.GetHMDAng(getply(ply)))
    end

    --- Returns vector and angle HMD pose.
    -- @param Player player
    -- @shared
    -- @return Vector, Angle
    function vrmod_lib.getHMDPose(ply)
        local v,a = vrmod.GetHMDPose(getply(ply))
        return vwrap(v),awrap(a)
    end
    --- Returns player's left hand pos.
    -- @param Player player
    -- @shared
    -- @return Vector left hand pos
    function vrmod_lib.getLeftHandPos(ply)
        return vwrap(vrmod.GetLeftHandPos(getply(ply)))
    end
    --- Returns player's left hand ang.
    -- @param Player player
    -- @shared
    -- @return Angle left hand pos
    function vrmod_lib.getLeftHandAng(ply)
        return awrap(vrmod.GetLeftHandAng(getply(ply)))
    end
    --- Returns vector and angle left hand pose.
    -- @param Player player
    -- @shared
    -- @return Vector, Angle
    function vrmod_lib.getLeftHandPose(ply)
        local v,a = vrmod.GetLeftHandPose(getply(ply))
        return vwrap(v),awrap(a)
    end
    --- Returns vector ply's right hand pos.
    -- @param Player player
    -- @shared
    -- @return Vector right hand pos
    function vrmod_lib.getRightHandPos(ply)
        return vwrap(vrmod.GetHMDPose(getply(ply)))
    end
    --- Returns ply's right hand angle.
    -- @param Player player
    -- @shared
    -- @return Angle right hand angle
    function vrmod_lib.getRightHandAng(ply)
        return awrap(vrmod.GetRightHandAng(getply(ply)))
    end
    --- Returns vector and angle HMD pose.
    -- @param Player player
    -- @shared
    -- @return Vector, Angle ply's right hand pose.
    function vrmod_lib.getRightHandPose(ply)
        local v,a = vrmod.GetRightHandPose(getply(ply))
        return vwrap(v),awrap(a)
    end
end