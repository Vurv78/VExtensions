

local function Update(self,this)
	self.data.EGP.UpdatesNeeded[this] = true
end

e2function void wirelink:egpVBox( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["VBox"], { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end