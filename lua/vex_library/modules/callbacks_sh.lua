-- Just a more centralized hook system for VEx (that also gets deconstructed)
local registeredCallbacks = vex.persists.registeredCallbacks or {}
vex.persists.registeredCallbacks = registeredCallbacks

-- Only call this in the modules
vex.registerCallback = function(hookname,id)
    registeredCallbacks[id] = {}
    hook.Add(hookname,id,function(...)
        for _,callback in pairs(registeredCallbacks[id]) do
            callback(...)
        end
    end)
    vex.destructor(function()
        hook.Remove(hookname,id)
    end)
    return function(callback)
        table.insert(registeredCallbacks[id],callback)
    end
end

if SERVER then
    vex.onPlayerLeave = vex.registerCallback("PlayerDisconnected","VEx_PlayerDisconnected_Callback")
end