--[[
    __  ___        _
   /  |/  /____ _ (_)____
  / /|_/ // __ `// // __ \
 / /  / // /_/ // // / / /
/_/  /_/ \__,_//_//_/ /_/
 Random Misc. Functions that are cool like hiding other people's chat (probably doesn't work) and setting the ranger Filter.
]]

local table_insert, util_TraceLine, string_format = table.insert, util.TraceLine, string.format -- Gonna be using this a lot

-- Lib functions

__e2setcost(4)
e2function ranger rangerOffsetManual(vector pos,vector endpos)
    return util_TraceLine {
        start = Vector(pos[1],pos[2],pos[3]),
        endpos = Vector(endpos[1],endpos[2],endpos[3])
    }
end

__e2setcost(6)
e2function ranger rangerOffsetManual(vector pos, vector endpos, array filt)
    return util_TraceLine {
        start = Vector(pos[1], pos[2], pos[3]),
        endpos = Vector(endpos[1],endpos[2],endpos[3]),
        filter = filt
    }
end

__e2setcost(6)
e2function ranger rangerOffsetManual(vector pos, vector endpos, array filt, number mask)
    return util_TraceLine {
        start = Vector(pos[1], pos[2], pos[3]),
        endpos = Vector(endpos[1],endpos[2],endpos[3]),
        filter = filt,
        mask = mask
    }
end

__e2setcost(4)
e2function ranger rangerOffsetManual(vector pos, vector endpos, number mask)
    return util_TraceLine {
        start = Vector(pos[1], pos[2], pos[3]),
        endpos = Vector(endpos[1],endpos[2],endpos[3]),
        mask = mask
    }
end

__e2setcost(2)
e2function ranger rangerOffsetBlazing(vector pos, vector endpos)
    return util_TraceLine {
        start = pos,
        endpos = endpos
    }
end

__e2setcost(3)
e2function ranger rangerOffsetBlazing(vector pos, vector endpos, array filter)
    return util_TraceLine {
        start = pos,
        endpos = endpos,
        filter = filter
    }
end

__e2setcost(2)
e2function ranger rangerOffsetBlazing(vector pos, vector endpos, number mask)
    return util_TraceLine {
        start = pos,
        endpos = endpos,
        mask = mask
    }
end

__e2setcost(3)
e2function ranger rangerOffsetBlazing(vector pos, vector endpos, array filter, number mask)
    return util_TraceLine {
        start = pos,
        endpos = endpos,
        filter = filter,
        mask = mask
    }
end

__e2setcost(5)
e2function number rangerSetFilter(array filter)
    if #filter == 0 then self.data.rangerfilter = {} return 1 end
    if #filter > 3000 then return 0 end
    self.prf = self.prf + #filter*1.5
    self.data.rangerfilter = cleanupTable(filter)
    return 1
end

-- Hide Chat 7/3/2020 by Vurv
local chatsHidden = {}

__e2setcost(3)
e2function number canHideChatPly(entity ply)
    if not ply:IsValid() then return end
    return ply:GetInfoNum("canhidechatply_cl",0)==0 and 0 or 1
end

__e2setcost(20)
e2function void hideChatPly(entity ply, hide)
    if not ply:IsValid() then return end
    if hide==0 then chatsHidden[ply] = nil return end
    if self.player ~= ply then
        if ply:GetInfoNum("canhidechatply_cl",0)==0 then return end
        ply:PrintMessage(HUD_PRINTCONSOLE, string_format("Your chat was hidden by %s's expression 2 chip. See canhidechatply_cl to disable this.",self.player:GetName())) -- Notify the user that their chat was hidden by X
        print(string_format("%s's chat was hidden by %s's expression 2 chip.",ply:GetName(),self.player:GetName())) -- Log to server console
    end
    chatsHidden[ply] = true -- Disregard the convar if you're the owner of the chip.
end

local WireReceiver = hook.GetTable().PlayerSay.Exp2TextReceiving

hook.GetTable().PlayerSay.Exp2TextReceiving = function(sender,...)
    local ret = WireReceiver(sender,...)
    if chatsHidden[sender] then
        chatsHidden[sender] = nil
        return ""
    end
    return ret
end
