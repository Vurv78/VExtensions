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
e2function void rangerSetFilter(array filter)
	local fixed = {}
	for _,V in pairs(filter) do
		if type(V)~="Entity" and type(V)~="Player" then goto cont end
		table.insert(fixed,V)
		::cont::
	end
	self.data.rangerfilter = filter
end