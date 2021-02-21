-- Starfall library functions
local checkluatype = SF.CheckLuaType
local registerPrivilege = SF.Permissions.registerPrivilege or SF.Permissions.registerprivilege -- wtf Starfall

-- Register clientside permissions.
-- 1 = Only you, 2 = Friends Only, 3 = Anyone, 4 = No one
local SF_PERMS = {
    OWNER = 1,
    FRIEND = 2,
    ANYONE = 3,
    NO_ONE = 4
}

registerPrivilege("vextensions.printLocal", "Print to your chat", "Allows the user to print to your chat with printLocal.", { client = { default = SF_PERMS.ANYONE } })

local MAX_ARGS = CreateConVar("vex_printlocal_argmax", "150") -- We don't have to network this so we can be a lot more lenient.
local MAX_CHARS = CreateConVar("vex_printlocal_charmax", "500")
local DBG_GETMETATABLE = debug.getmetatable

local PRINT_BURST = vex.burstManager(4) -- Can print 4 times per second.

return function(instance)
    local SFUser = instance.player
    local checkpermission = SFUser ~= SF.Superuser and SF.Permissions.check or function() end

    local builtins_library = instance.env
    -- Fun fact, I spent literally hours trying to figure out why docs weren't working for this.
    -- turns out this needs to exactly be named "builtins_library" to correspond with the docs, which makes sense..
    -- but ... hours...

    local ply_unwrap = instance.Types.Player.Unwrap
    local awrap, aunwrap = instance.Types.Angle.Wrap, instance.Types.Angle.Unwrap
    local vwrap, vunwrap = instance.Types.Vector.Wrap, instance.Types.Vector.Unwrap

    local col_meta = instance.Types.Color

    --- If the LocalPlayer has vextensions.printLocal enabled, prints to their chat.
    -- This uses chat.AddText.
    -- [VExtensions]
    -- @param ... Varargs of any type, use colors before variables to change the color of those variables as strings.
    -- @return bool Whether player trusts player "ply".
    function builtins_library.printLocal(...)
        checkpermission(instance, nil, "vextensions.printLocal")

        local target = LocalPlayer()
        local could_use = PRINT_BURST:use( target ) -- Local to the chip.
        if not could_use then SF.Throw("Hit the printLocal burst limit!") end

        local args, out = {...}, {}
        local n_args, n_chars = #args, 0
        if n_args > MAX_ARGS:GetInt() then SF.Throw("Too many arguments in printLocal.") end
        local max_chars = MAX_CHARS:GetInt()
        for k = 1, n_args do
            local v = args[k]
            if isstring(v) then
                local n_chars_f = n_chars + #v
                if n_chars_f > max_chars then
                    out[k] = v:sub(0, max_chars-n_chars)
                    -- If the total strings given goes over the max amount of characters you can print, break the sequence and print.
                    break
                end
                out[k] = v
                n_chars = n_chars_f
            elseif col_meta ~= DBG_GETMETATABLE(v) then
                out[k] = tostring(v)
            else
                out[k] = v
            end
        end
        if target ~= instance.player then
            -- Warn the client that they are being printed to using SF.
            -- Also gives how to disable the function.
            target:PrintMessage(HUD_PRINTCONSOLE,
                string.format("%s(%s) is printing to your chat using printLocal. Disable this in your SF permissions screen or with sf_permission_cl.\n", instance.player:GetName(), instance.player:SteamID())
            )
        end
        chat.AddText(unpack(out))
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
    -- @return bool Whether you can call printLocal.
    function builtins_library.canPrintLocal()
        return PRINT_BURST:available( LocalPlayer() )
    end
end
