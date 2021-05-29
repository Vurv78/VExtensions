-- Note that this file has a v_ appended to the filename so it runs after player.lua, since this tries to overwrite setEyeAngles that SF implements.

-- Starfall library functions
local checkluatype = SF.CheckLuaType
local registerPrivilege = SF.Permissions.registerPrivilege or SF.Permissions.registerprivilege -- wtf Starfall

-- Register clientside permissions. TODO: Make this a part of the vex library.
-- 1 = Only you, 2 = Friends Only, 3 = Anyone, 4 = No one
local SF_PERMS = {
    OWNER = 1,
    FRIEND = 2,
    ANYONE = 3,
    NO_ONE = 4
}

registerPrivilege("vextensions.setEyeAngles", "Set your EyeAngles", "Allows the user to set your eye angles", { client = { default = SF_PERMS.OWNER } })

local HAS_PROP_PROTECTION = FindMetaTable("Player").CPPIGetFriends ~= nil
local function does_ply_trust(ply, who)
    if ply == who then return true end
    if not HAS_PROP_PROTECTION then return false end -- If no prop protection is found, just don't trust anyone.
    for _, friend in next, ply:CPPIGetFriends() do
        if who == friend then return true end
    end
    return false
end

return function(instance)
    -- Local to each chip
    local SFUser = instance.player

    -- SF Library functions
    local checkpermission = SFUser ~= SF.Superuser and SF.Permissions.check or function() end
    -- Starfall types to Lua types
    local player_methods = instance.Types.Player.Methods

    local awrap, aunwrap = instance.Types.Angle.Wrap, instance.Types.Angle.Unwrap
    local vwrap, vunwrap = instance.Types.Vector.Wrap, instance.Types.Vector.Unwrap
    -- Starfall types to Lua types

    local SFUser = instance.player

    local getply
    instance:AddHook("initialize", function()
        getply = instance.Types.Player.GetPlayer
    end)

    --- Sets the angle of the player's view (may rotate body too if angular difference is large)
    -- [VExtensions]
    -- @shared
    -- @param Angle ang Angle to set player's eye angles to.
    function player_methods:setEyeAngles(ang)
        local ply = getply(self)
        if CLIENT then
            checkpermission(instance, nil, "entities.setEyeAngles")
        elseif ply~=SFUser then
            return SF.Throw("You cannot set another player's eye angles on the SERVER realm!",3)
        end
        ply:SetEyeAngles(aunwrap(ang))
    end

    --- Returns whether the player trusts player ply.
    -- Behaves like prior wiremod before Sparky nerfed it so you couldn't get the friends of people you weren't friends with.
    -- [VExtensions]
    -- @shared
    -- @param Player ply Player to check if 'self' trusts.
    -- @return boolean Whether player trusts player "ply".
    function player_methods:trusts(ply)
        return does_ply_trust( getply(self), getply(ply) )
    end
end
