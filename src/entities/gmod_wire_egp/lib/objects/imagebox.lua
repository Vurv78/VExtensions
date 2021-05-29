--[[
    ____                              ____                      
   /  _/___ ___  ____ _____ ____     / __ )____  _  _____  _____
   / // __ `__ \/ __ `/ __ `/ _ \   / __  / __ \| |/_/ _ \/ ___/
 _/ // / / / / / /_/ / /_/ /  __/  / /_/ / /_/ />  </  __(__  ) 
/___/_/ /_/ /_/\__,_/\__, /\___/  /_____/\____/_/|_|\___/____/  
                    /____/                                      
    Allow players to create boxes with their textures set to a URL.
]]

local DrawQueue = {}

local Obj = EGP:NewObject("ImageBox")
Obj.angle = 0
Obj.url = ""
Obj.ply = NULL
Obj.CanTopLeft = true

function Obj:Transmit()
    net.WriteInt((self.angle%360)*20, 16)
    net.WriteString(self.url)
    net.WriteEntity(self.ply)
	self.BaseClass.Transmit( self )
end

function Obj:Receive()
	local tbl = {}
    tbl.angle = net.ReadInt(16)/20
    tbl.url = net.ReadString()
    tbl.ply = net.ReadEntity()
	table.Merge( tbl, self.BaseClass.Receive( self ) )
	return tbl
end

function Obj:DataStreamInfo()
	local tbl = {}
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	table.Merge( tbl, { angle = self.angle, url = self.url, ply = self.ply } )
	return tbl
end

function Obj:Contains(point)
	point = EGP.ScreenSpaceToObjectSpace(self, point)
	local w, h = self.w / 2, self.h / 2
	return -w <= point.x and point.x <= w and
	       -h <= point.y and point.y <= h
end

if SERVER then return end

local printf = vex.printf

function Obj:Draw( egp, matrix )
    if (self.a>0) then
        local ply = self.ply
        local url = self.url
        if not vex.getWebMaterial(url) then
            -- If the web material hasn't already been loaded, queue it to reload the current egp frame when the material is available
            DrawQueue[url] = DrawQueue[url] or {}
            DrawQueue[url][egp] = true
        end
        local m = vex.getURLMaterialEx(self.url,self.w, self.h ,function(mat,url,w,h,webmaterial)
            printf("[VExtensions E2] Player %s (%s) loaded %dx%d EGP Image w/ url of \n%s",ply:GetName(),ply:SteamID(),self.w,self.h,url)
            if DrawQueue[url] then
                timer.Simple(0.1,function()
                    for EGP in next,DrawQueue[url] do
                        if not IsValid(EGP) then
                            DrawQueue[url][EGP] = nil
                            continue
                        end
                        EGP:_EGP_Update()
                        EGP.GPU:Render()
                    end
                end)
            end
        end,failure_callback)
        surface.SetMaterial(m)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectRotated(self.x, self.y, self.w, self.h, self.angle)
	end
end