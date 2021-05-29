-- It's literally just a net library to prepend VEx_Net_ to net messages. Yep.

local function getNetName(s)
    -- Returns a net name, but with VEx_Net_ prepended (Easier to manage net strings)
    return "VEx_Net_" .. s
end

vex.net_Receive = function(net_name,callback,dopersist)
    local nm = getNetName(net_name)
    net.Receive(nm,callback)
    if not dopersist then
        -- If we don't specify, we will assume that we use this function in a vex module (therefore it will already overwrite itself, so we just need to delete it.)
        vex.destructor(function()
            net.Receive(nm)
        end)
    end
end

vex.net_Start = function(net_name,unreliable)
    net.Start(getNetName(net_name),unreliable)
end

if SERVER then
    vex.addNetString = function(net_name)
        -- Todo: Put these in a list and add a convar to list them, or something.
        util.AddNetworkString( getNetName(net_name) )
    end
end