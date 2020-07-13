-- Author Vurv
-- The main purpose of this file is to make interfacing and creating new EGP
-- functions as easy as possible.

local EGP = EGP

-- EGP Library Functions

local function Update(self,this)
	self.data.EGP.UpdatesNeeded[this] = true
end


e2function void wirelink:egpImage( number index, vector2 pos, vector2 size)
    print("starting")
    if !EGP:IsAllowed( self, this ) then return end
    print("nigga")
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["EGPImage"], { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, self.player )
    if bool then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end