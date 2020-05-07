local DEFAULT_TABLE = {n={},ntypes={},s={},stypes={},size=0}

local ids = { -- Helper table for toTable() used here for rangerOffsetFilter as it is standalone from regular rangers.
	["FractionLeftSolid"] = "n",
	["HitNonWorld"] = "n",
	["Fraction"] = "n",
	["Entity"] = "e",
	["HitNoDraw"] = "n",
	["HitSky"] = "n",
	["HitPos"] = "v",
	["StartSolid"] = "n",
	["HitWorld"] = "n",
	["HitGroup"] = "n",
	["HitNormal"] = "v",
	["HitBox"] = "n",
	["Normal"] = "v",
	["Hit"] = "n",
	["MatType"] = "n",
	["StartPos"] = "v",
	["PhysicsBone"] = "n",
	["WorldToLocal"] = "v",
	["RealStartPos"] = "v",
	["HitTexture"] = "s",
	["HitBoxBone"] = "n"
}

__e2setcost(10)
e2function table rangerOffsetFilter(range,vector pos,vector dir, array filt)
    local Start = Vector(pos[1],pos[2],pos[3])
    local End = Start + Vector(dir[1],dir[2],dir[3]) * range
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
	if not tr then return {} end
	local ret = table.Copy(DEFAULT_TABLE)
	local size = 0
	for k,v in pairs( tr ) do
		if (ids[k]) then
			if isbool(v) then v = v and 1 or 0 end
			ret.s[k] = v
			ret.stypes[k] = ids[k]
			size = size + 1
		end
	end
	ret.size = size
	return ret
end