

SF.AddHook("postload", function()
    print("Vurv's SF Functions initialized.")
    -- Starfall library functions
    local checkluatype = SF.CheckLuaType
    local checkpermission = instance.player ~= NULL and SF.Permissions.check or function() end
    local registerprivilege = SF.Permissions.registerPrivilege

    -- Starfall types to Lua types
    local aunwrap = instance.Types.Angle.Unwrap
    -- Starfall types to Lua types

    -- Register clientside permissions.
    -- 1 = Only you, 2 = Friends Only, 3 = Anyone, 4 = No one 
    registerprivilege("entities.setEyeAngles", "Get a file object", "Allows the user to use a file object", { client = { default = 1 } })


    function player_methods:setEyeAngles(ang)
        local ply = getply(self)
        checkpermission(instance, ply)
        getply(ply):SetEyeAngles(aunwrap(ang))
    end
end)