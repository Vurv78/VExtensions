-- Starfall library functions
local checkluatype = SF.CheckLuaType
local registerPrivilege = SF.Permissions.registerPrivilege or SF.Permissions.registerprivilege -- wtf Starfall

-- Register clientside permissions.
-- 1 = Only you, 2 = Friends Only, 3 = Anyone, 4 = No one 
--registerPrivilege("entities.setEyeAngles", "Set your EyeAngles", "Allows the user to set your eye angles", { client = { default = 1 } })

return function(instance)
    -- Local to each chip call

    -- SF Library functions
    local checkpermission = instance.player ~= NULL and SF.Permissions.check or function() end
    -- Starfall types to Lua types
    local aunwrap = instance.Types.Angle.Unwrap
    local player_methods, player_meta, wrap, unwrap = instance.Types.Player.Methods, instance.Types.Player, instance.Types.Player.Wrap, instance.Types.Player.Unwrap
    local vec_meta, vwrap, vunwrap = instance.Types.Vector, instance.Types.Vector.Wrap, instance.Types.Vector.Unwrap
    -- Starfall types to Lua types
    
    local SFUser = instance.player

    local function getply(self)
        local ent = unwrap(self)
        if ent:IsValid() then
            return ent
        else
            SF.Throw("Entity is not valid.", 3)
        end
    end

    --- Sets the angle of the player's view (may rotate body too if angular difference is large) [Exclusive]
    -- @param Angle angle
    -- @shared
    function player_methods:setEyeAngles(ang)
        local ply = getply(self)
        if CLIENT then checkpermission(instance,nil,"entities.setEyeAngles") elseif ply~=SFUser then return end
        ply:SetEyeAngles(aunwrap(ang))
    end
end