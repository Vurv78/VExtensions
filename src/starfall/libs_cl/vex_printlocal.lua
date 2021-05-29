-- Starfall library functions
local checkluatype = SF.CheckLuaType
local registerPrivilege = SF.Permissions.registerPrivilege

local SFLib = vex.SFLib
local SF_PERMS = SFLib.PermLevels

registerPrivilege("vextensions.printLocal", "Print to your chat", "Allows the user to print to your chat with printLocal.", { client = { default = SF_PERMS.ANYONE } })

local MAX_ARGS = CreateConVar("vex_printlocal_argmax", "150") -- We don't have to network this so we can be a lot more lenient.
local MAX_CHARS = CreateConVar("vex_printlocal_charmax", "500")
local DBG_GETMETATABLE = debug.getmetatable

local PRINT_BURST = vex.burstManager(4) -- Can print 4 times per second.

-- Checks if a string will exceed the max amount of characters you can print max with printLocal.
-- @tparam string str The string to check the length of.
-- @tparam number current_chars Number of current characters counted in this printLocal call.
-- @tparam number max_chars Maximum number of chars in a printLocal call.
-- @treturn string?, number Nullable string and number of characters after the string is parsed. First string is returned only if the string exceeds the max char limit. So you should break if it is returned.
local function checkCharCount(str, current_chars, max_chars)
    local n_chars_f = current_chars + #str
    if n_chars_f > max_chars then
        -- String goes past or is at the limit. Cut the string short and print.
        return str:sub(0, max_chars-current_chars), n_chars_f
    end
    return false, n_chars_f
end

return function(instance)
    local SFUser = instance.player
    local checkpermission = SFUser ~= SF.Superuser and SF.Permissions.check or function() end

    local builtins_library = instance.env
    -- This needs to exactly be named "builtins_library" to correspond with the docs.

    local ply_unwrap = instance.Types.Player.Unwrap
    local awrap, aunwrap = instance.Types.Angle.Wrap, instance.Types.Angle.Unwrap
    local vwrap, vunwrap = instance.Types.Vector.Wrap, instance.Types.Vector.Unwrap

    local col_meta = instance.Types.Color

    --- Returns whether a table is an sf color.
    -- @tparam table tbl The table to check the metatable of
    -- @treturn boolean Whether the table is an SF Color.
    local function isSFColor(tbl)
        return DBG_GETMETATABLE(tbl) == col_meta
    end

    --- If the LocalPlayer has vextensions.printLocal enabled, prints to their chat.
    -- This uses chat.AddText.
    -- [VExtensions]
    -- @param ... args Varargs of any type, use colors before variables to change the color of those variables as strings.
    -- @return boolean Whether player trusts player "ply".
    function builtins_library.printLocal(...)
        checkpermission(instance, nil, "vextensions.printLocal")

        local target = LocalPlayer()
        local could_use = PRINT_BURST:use( target ) -- Local to the chip.
        if not could_use then SF.Throw("Hit the printLocal burst limit!") end

        local args, out = {...}, {}
        local n_args, n_chars = #args, 0

        if n_args > MAX_ARGS:GetInt() then SF.Throw("Too many arguments in printLocal.") end
        local max_chars = MAX_CHARS:GetInt()

        -- Skip the first argument since we've already verified that it's either an SF Color or a color we inserted.
        for k = 1, n_args do
            local v = args[k]
            if isstring(v) then
                local cut_string, new_charcount = checkCharCount(v, n_chars, max_chars)
                if cut_string then
                    -- String exceeds max char count. Cut it and break.
                    out[k] = cut_string
                    break
                else
                    -- Haven't reached char limit yet.
                    out[k] = v
                    n_chars = new_charcount
                end
            elseif isSFColor(v) then
                -- Colors don't need to be modified.
                out[k] = v
            else
                -- Turn every other type into a string.
                local str = tostring(v)
                local cut_string, new_charcount = checkCharCount(str, n_chars, max_chars)
                if cut_string then
                    -- tostring return exceeds max char count. Cut it and break.
                    out[k] = cut_string
                    break
                else
                    out[k] = str
                    n_chars = new_charcount
                end
            end
        end
        if target ~= instance.player then
            -- Warn the client that they are being printed to using SF.
            -- Also gives how to disable the function.
            target:PrintMessage(HUD_PRINTCONSOLE,
                string.format("%s(%s) is printing to your chat using printLocal. Disable this in your SF permissions screen or with sf_permission_cl.\n", instance.player:GetName(), instance.player:SteamID())
            )
        end

        -- Default color is orange
        chat.AddText( Color(247, 179, 62), unpack(out) )
    end
    --- Returns the max amount of characters and arguments you can use in a printLocal call.
    -- Internally looks at the convars vex_printlocal_argmax and vex_printlocal_charmax.
    -- [VExtensions]
    -- @return number Max amount of characters in total you can use in a printLocal call.
    -- @return number Max amount of arguments you can use in a printLocal call.
    function builtins_library.printLocalLimits()
        return MAX_CHARS:GetInt(), MAX_ARGS:GetInt()
    end
    --- Returns whether you can printLocal.
    -- This only returns the burst limit and not whether the user has printLocal enabled.
    -- If you want to check if they have it enabled, see hasPermission and the vextensions.printLocal permission.
    -- [VExtensions]
    -- @return boolean Whether you can call printLocal.
    function builtins_library.canPrintLocal()
        return PRINT_BURST:available( LocalPlayer() )
    end
end
