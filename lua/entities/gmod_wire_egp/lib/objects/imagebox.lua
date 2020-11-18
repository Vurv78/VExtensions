--[[
    ____                              ____                      
   /  _/___ ___  ____ _____ ____     / __ )____  _  _____  _____
   / // __ `__ \/ __ `/ __ `/ _ \   / __  / __ \| |/_/ _ \/ ___/
 _/ // / / / / / /_/ / /_/ /  __/  / /_/ / /_/ />  </  __(__  ) 
/___/_/ /_/ /_/\__,_/\__, /\___/  /_____/\____/_/|_|\___/____/  
                    /____/                                      
    Allow players to create boxes with their textures set to a URL.
]]


local Obj = EGP:NewObject( "ImageBox" )
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

local WebMaterials = {}
local PlyWebMaterials = {} -- A table storing all of the web materials owned by each player, holding the str url.
local DrawQueue = {}

local ErrorMaterial = Material("error")

local function printf(...)
    print(string.format(...))
end

local function getURLMaterial(url,w,h,wait)
    if not url or not w or not h then return Material("error") end
    if WebMaterials[url] then return WebMaterials[url] end
    local WebPanel = vgui.Create( "DHTML" )
    WebPanel:SetAlpha( 0 )
    WebPanel:SetSize( w,h )
    -- Todo: Use img.onload and get the material from there.. Trying it rn and it just bugs out..
    WebPanel:AddFunction("vurv","imageloaded",function(w,h)
        printf("[VExtensions E2] Loaded %dx%d EGP Image w/ url of \n%s",w,h,url)
        -- 'wait' is a value for how long we should wait for the image to load. For some reason javascript calls onload when the image hasn't fully loaded for the client..
        timer.Simple(wait or 1,function()
            WebPanel.Paint = function()
                if WebMaterials[url] then WebPanel:Remove() return end
                local Mat = WebPanel:GetHTMLMaterial()
                if not Mat then return end
                WebMaterials[url] = Mat
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
            end
        end)
    end)

    WebPanel:AddFunction("vurv","imagefail",function(url)
        printf("[VExtensions E2] Image failed to load w/ url of \n%s",url)
    end)
    
    WebPanel:SetHTML([[
        <html style="overflow:hidden"><body><script>
            var img = new Image();
            img.style.position="absolute";
            img.width = ]] .. tostring(w) .. [[;
            img.height = ]] .. tostring(h) .. [[;
            img.style.left = "0px";
            img.style.top = "0px";
            let src = "]] .. string.JavascriptSafe( url ) .. [[";
            img.onload = function() { vurv.imageloaded(img.width,img.height) };
            img.onerror = function() { vurv.imagefail(src) };
            img.src=src;
            document.body.appendChild(img);
        </script></body></html>
    ]])
    return WebMaterials[url] or ErrorMaterial
end

function Obj:Draw( egp, matrix )
    if (self.a>0) then
        local url = self.url
        if not WebMaterials[url] then
            -- If the web material hasn't already been loaded, queue it to reload the current egp frame when the material is available
            DrawQueue[url] = DrawQueue[url] or {}
            local ply = self.ply
            PlyWebMaterials[ply] = PlyWebMaterials[ply] or {}
            table.insert(PlyWebMaterials[ply],url)
            DrawQueue[url][egp] = true
        end
        surface.SetMaterial(  getURLMaterial(self.url,512,512) )
        surface.SetDrawColor( 255, 255, 255, 255 )
        surface.DrawTexturedRectRotated( self.x, self.y, self.w, self.h, self.angle )
	end
end

net.Receive("VEx_Net_imageboxes",function()
    local clearall = net.ReadBool()
    local ply = net.ReadEntity()
    if clearall then
        -- For now, players will only be able to clear ALL of their url images.
        if not PlyWebMaterials[ply] or #PlyWebMaterials[ply] == 0 then return end
        for _,url in pairs(PlyWebMaterials[ply]) do
            WebMaterials[url] = nil
        end
        PlyWebMaterials[ply] = {}
    end
end)