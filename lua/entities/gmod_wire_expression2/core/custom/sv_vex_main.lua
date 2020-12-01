--[[
    __  ___        _      
   /  |/  /____ _ (_)____ 
  / /|_/ // __ `// // __ \
 / /  / // /_/ // // / / /
/_/  /_/ \__,_//_//_/ /_/ 
 Random Misc. Functions that are cool like hiding other people's chat (probably doesn't work) and setting the ranger Filter.                    
]]

local newE2Table, luaTableToE2 = vex.newE2Table, vex.luaTableToE2

-- Lib functions

__e2setcost(10)
e2function table rangerOffsetManual(vector pos,vector endpos, array filt)
    local tr = util.TraceLine( {
        start = Vector(pos[1],pos[2],pos[3]),
        endpos = Vector(endpos[1],endpos[2],endpos[3]),
        filter = filt
    } )
    return tr and luaTableToE2(tr) or newE2Table()
end

__e2setcost(5)
e2function number rangerSetFilter(array filter)
    if #filter == 0 then self.data.rangerfilter = {} return 1 end
    if #filter > 3000 then return 0 end
    self.prf = self.prf + #filter*1.5
    local fixed = {}
    for _,V in pairs(filter) do
        -- TODO: What about NPC, Vehicle, Weapon... these return different type string. Perhaps use isentity function?
        if type(V)~="Entity" or type(V)~="Player" then
            table.insert(fixed,V)
        end
    end
    self.data.rangerfilter = filter
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
    if hide==0 then chatsHidden[ply] = false return end -- TODO: This may be abusable and would make it so people
    if self.player ~= ply then
        if ply:GetInfoNum("canhidechatply_cl",0)==0 then return end
        ply:PrintMessage(HUD_PRINTCONSOLE, string.format("Your chat was hidden by %s's expression 2 chip. See canhidechatply_cl to disable this.",self.player:GetName())) -- Notify the user that their chat was hidden by X
        print(string.format("%s's chat was hidden by %s's expression 2 chip.",ply:GetName(),self.player:GetName())) -- Log to server console
    end
    chatsHidden[ply] = true -- Disregard the convar if you're the owner of the chip.
end

hook.Add("PlayerSay","vurve2_canhidechat_hide",function(sender)
    if chatsHidden[sender] then
        chatsHidden[sender] = false
        -- Only hide chat once
        return ""
    end
end)