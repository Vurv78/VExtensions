-- Author: Vurv
local themat = Material("models/wireframe")
local Obj = EGP:NewObject("EGPImage")
Obj.url = "https://i.redd.it/7au96kl43rm01.png"
Obj.Draw = function( self )
    surface.SetDrawColor( self.r, self.g, self.b, self.a )
    surface.SetMaterial(themat)
    surface.DrawTexturedRect( self.x, self.y, self.w, self.h)
end
Obj.Transmit = function( self )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self )
	return self.BaseClass.Receive( self )
end
Obj.DataStreamInfo = function( self )
    return self.BaseClass.DataStreamInfo( self )
end
