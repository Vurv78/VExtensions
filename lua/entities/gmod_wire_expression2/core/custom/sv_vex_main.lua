--[[
    __  ___        _      
   /  |/  /____ _ (_)____ 
  / /|_/ // __ `// // __ \
 / /  / // /_/ // // / / /
/_/  /_/ \__,_//_//_/ /_/ 
 Random Misc. Functions that are cool like hiding other people's chat (probably doesn't work) and setting the ranger Filter.                    
]]

local E2Table = function() return {n={},ntypes={},s={},stypes={},size=0} end

local function luaTablToE2(T)
    local Strt = E2Table()
    local Sz = 0
    for Key,Value in pairs(T) do
        local TypeV = type(Value)
        local WriteV = Strt.n
        local WriteType = Strt.ntypes
        if type(Key)=="string" then WriteV = Strt.s WriteType=Strt.stypes end
        local Clean = Value
        if TypeV=="bool" then Clean = Value and 1 or 0 elseif
        TypeV=="table" then Clean = luaTablToE2(Value) end
        Sz = Sz + 1
        WriteV[Key] = Clean
        WriteType[Key] = TypeV[1]
    end
    Strt.size = Sz
    return Strt
end

-- Lib functions

__e2setcost(10)
e2function table rangerOffsetManual(vector pos,vector endpos, array filt)
    local Start = Vector(pos[1],pos[2],pos[3])
    local End = Vector(endpos[1],endpos[2],endpos[3])
	local tr = util.TraceLine( {
		start = Start,
		endpos = End,
		filter = function( ent )
			for I in pairs(filt) do
				if(I == ent) then return true end
			end
			return false
		end
    } )
	if not tr then return E2Table() end
	return luaTablToE2(tr)
end

__e2setcost(5)
e2function number rangerSetFilter(array filter)
    if #filter == 0 then self.data.rangerfilter = {} return 1 end
    if #filter > 3000 then return 0 end
	local fixed = {}
    for _,V in pairs(filter) do
        
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
    return ply:GetInfoNum("vurve2_canhidechat_cl",0)==0 and 0 or 1
end

__e2setcost(20)
e2function void hideChatPly(entity ply, hide)
    if not ply:IsValid() then return end
    if hide==0 then chatsHidden[ply] = false return end
    if self.player ~= ply then
        if ply:GetInfoNum("vurve2_canhidechat_cl",0)==0 then return end
        ply:PrintMessage(HUD_PRINTCONSOLE, string.format("Your chat was hidden by %s's expression 2 chip.",self.player:GetName())) -- Notify the user that their chat was hidden by X
        print(string.format("%s's chat was hidden by %s's expression 2 chip.",ply:GetName(),self.player:GetName())) -- Log to server console
    end
    chatsHidden[ply] = true -- Disregard the convar if you're the owner of the chip.
end

hook.Add("PlayerSay","vurve2_canhidechat_hide",function(sender)
    if sender:GetInfoNum("vurve2_canhidechat_cl",0)~=0 and chatsHidden[sender] then
        chatsHidden[sender] = false
        -- Only hide chat once
        return ""
    end
end)

-- Hide Chat 7/3/2020 by Vurv