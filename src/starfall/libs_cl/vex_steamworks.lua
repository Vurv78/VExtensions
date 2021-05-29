-- Starfall library functions
local checkluatype = SF.CheckLuaType
local registerPrivilege = SF.Permissions.registerPrivilege

local SFLib = vex.SFLib
local SF_PERMS = SFLib.PermLevels

registerPrivilege("steamworks.fileInfo", "steamworks.FileInfo", "Allows the user to get info about an addon.", { client = { default = SF_PERMS.OWNER } })
registerPrivilege("steamworks.getList", "steamworks.GetList", "Allows the user to find a list of addons from the workshop.", { client = { default = SF_PERMS.OWNER } })

local DBG_GETMETATABLE = debug.getmetatable

--- Steamworks library https://wiki.facepunch.com/gmod/steamworks
-- [VExtensions]
-- @name steamworks
-- @class library
-- @libtbl steamworks_library
SF.RegisterLibrary("steamworks")

return function(instance)
    local SFUser = instance.player
    local checkpermission = SFUser ~= SF.Superuser and SF.Permissions.check or function() end

    local steamworks_library = instance.Libraries.steamworks

    --- Retrieves info about supplied Steam Workshop addon.
    -- [VExtensions]
    -- @param number workshopItemID The workshop ID of the addon to get info from.
    -- @param function callback The function to call when the information is fetched. Passes a https://wiki.facepunch.com/gmod/Structures/UGCFileInfo struct.
    function steamworks_library.fileInfo( workshopItemID, callback )
        checkpermission( instance, nil, "steamworks.fileInfo" )

        checkluatype( workshopItemID, TYPE_NUMBER )
        checkluatype( callback, TYPE_FUNCTION )

        steamworks.FileInfo( workshopItemID, function(ugcfileinfo)
            instance:runFunction(callback, ugcfileinfo)
        end)
    end

    --- Retrieves info about supplied Steam Workshop addon.
    -- [VExtensions]
    -- @param string type The type of items to retrieve. Possible values are [popular, trending, latest, friends, followed, friends_fav, favorite].
    -- @param table? tags Table of tags to match. Default nil.
    -- @param number? offset How many results to skip from the first one. Default 0.
    -- @param number? numRetrieve How many items to retrieve. Default 10. (0-50).
    -- @param number? days Time period in the last n days. Default 7. (Most popular addons for the past week)
    -- @param string? userID "0" to retrieve all addons, "1" for only addons made by you, and a valid SteamID64 for only their addons. Default "0".
    -- @param function? callback The function to call when the information is fetched. Passes a table or nil in case of error.
    function steamworks_library.getList( type, tags, offset, numRetrieve, days, userID, resultCallback  )
        checkpermission( instance, nil, "steamworks.getList" )

        checkluatype( type, TYPE_STRING )
        if tags ~= nil then
            if not istable(tags) and not isfunction(tags) then SF.ThrowTypeError("table or function", SF.GetType(tags), 2) end
        end

        offset = offset or 0
        numRetrieve = numRetrieve or 10
        days = days or 7
        userID = userID or "0"

        checkluatype( offset, TYPE_NUMBER )
        checkluatype( numRetrieve, TYPE_NUMBER )
        checkluatype( days, TYPE_NUMBER )
        checkluatype( userID, TYPE_STRING )


        steamworks.GetList( type, tags, offset, numRetrieve, days, userID, function(results)
            instance:runFunction( resultCallback, results )
        end)
    end
end
