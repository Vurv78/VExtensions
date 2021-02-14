--[[
    _________      ______            __   ______
   / ____/__ \    /_  __/___  ____  / /  / ____/___  ________
  / __/  __/ /     / / / __ \/ __ \/ /  / /   / __ \/ ___/ _ \
 / /___ / __/     / / / /_/ / /_/ / /  / /___/ /_/ / /  /  __/
/_____//____/    /_/  \____/\____/_/   \____/\____/_/   \___/
    This is a tool that will be able to be used on an e2 chip, and that chip will be able
        to run based on actions you make with the tool.
]]

--[[
    To keep track of all of the data we'll use here.
chip.context.data:: = {
    E2CConnectedPLy
    E2CRightMouseClk
    E2CLeftMouseClk
    E2CReloadClk
    E2CUser
}
]]

-- Rules: All functions must have E2C in them.

__e2setcost(10)

e2function void setE2CSelected(number enable)
    vex.setE2ControllerChip(self.player,enable~=0 and self.entity or nil)
    --self.player:ChatPrint("Note that this function is currently pretty bad.. for some reason it executes e2's 'first' twice..")
end

__e2setcost(5)

e2function void runOnE2CSelected(number enable)
    vex.listenE2Hook(self,"e2CSelectedClk",enable~=0)
end

-- The player that selected the e2 with the e2 controller.
e2function entity e2CSelectedClk()
    return self.data.E2CConnectedPly
end

-- Left Click

e2function void runOnE2CLeftClick(number enable)
    vex.listenE2Hook(self,"E2CLeftMouseClk",enable~=0)
end

e2function number e2CLeftMouseClk()
    return self.data.E2CLeftMouseClk and 1 or 0
end

-- Right Click

e2function void runOnE2CRightClick(number enable)
    vex.listenE2Hook(self,"E2CRightMouseClk",enable~=0)
end

e2function number e2CRightMouseClk()
    return self.data.E2CRightMouseClk and 1 or 0
end

-- Reload

e2function void runOnE2CReload(number enable)
    vex.listenE2Hook(self,"E2CReloadClk",enable~=0)
end

e2function number e2CReloadClk()
    return self.data.E2CReloadClk and 1 or 0
end

-- Whenever an e2c event is fired, will pass the user of the tool.
-- This actually persists, so it is fine to call it lastE2CUser
e2function entity lastE2CUser()
    return self.data.E2CUser
end

e2function ranger lastE2CRangerInfo()
    return self.data.E2CRangerInfo
end