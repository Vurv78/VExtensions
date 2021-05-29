-- This will keep track of webmaterials on the clientside.

-- Rules / How I want to go about this
--[[
Web Materials will have separate objects on the server and clientside.
SHARED --  string: url, player: owner
SERVER --  bool: wm (to distinguish webmaterials from any table for e2 chips)
CLIENT --  IMaterial: vertex, IMaterial: unlit, ITexture: rt

If a player creates a webmaterial with url cool.com/img
And then another player creates a webmaterial with that url, they will not be able to destroy it's clientside material. They will be able to :destroy() it in e2,
but outside of the abstraction, it will only delete the serverside object.

This is where the 'owner' value comes in and how we will distinguish whether to delete them.
All of the clientside properties will be set to nil if we do end up cleaning the object on the client

Webmaterials will automatically be destroyed on player leave / chip destruction.
]]

CreateConVar("vex_webmaterials_enabled_cl","1",FCVAR_USERINFO,"Whether to allow net messages from the server to change the material of props to a webmaterial.")

--[[vex.addConsoleCommand("vex_webmaterials_purge_cl",function()

end,nil,"Purges all of the currently shown webmaterials.")]]

local WebMaterials = {
    chips = {}, -- Every webmaterial registered to a chip entity
    plys = {} -- Every webmaterial registered to player ply.
}

local ErrorMaterial = Material("error")

-- Let's make a webmaterial struct for the client so we can keep track of all of the vertexlitgeneric materials and the owners of the materials.
local WebMaterial = {
    owner = NULL,
    url = "",
    destroy = function(self)
        self.unlit = nil
        self.rt = nil
        self.vertex = nil
    end
}
WebMaterial.__index = WebMaterial

local function webMaterial(url,material)
    local obj = setmetatable({url = url, unlit = material},WebMaterial)
    WebMaterials[url] = obj
    return obj
end

local function webMaterialSetOwner(url,ply)
    WebMaterials.plys[ply] = WebMaterials.plys[ply] or {}
    WebMaterials.plys[ply][url] = true
end

local function webMaterialSetChip(url,chipid)
    WebMaterials.chips[chipid] = WebMaterials.chips[chipid] or {}
    WebMaterials.chips[chipid][url] = true
end

local printf = vex.printf

local function getURLMaterialEx(url,w,h,success,fail)
    -- Returns IMaterial material, string url, number width, number height in success args
    -- Returns string url in failure args
    if not url or not w or not h then return ErrorMaterial end
    if WebMaterials[url] then return WebMaterials[url].unlit end
    local WebPanel = vgui.Create("DHTML")
    WebPanel:SetAlpha(0)
    WebPanel:SetSize(w,h)
    -- Todo: Use img.onload and get the material from there.. Trying it rn and it just bugs out..
    WebPanel:AddFunction("vurv","imageloaded",function(w,h)
        -- We will wait for a second for the image to load, because for some reason javascript calls onload when the image hasn't fully loaded for the client..
        timer.Simple(1,function()
            WebPanel.Paint = function()
                if WebMaterials[url] then WebPanel:Remove() return end
                local Mat = WebPanel:GetHTMLMaterial()
                if not Mat then return end
                local wm = webMaterial(url,Mat)
                success(Mat,url,w,h,wm)
            end
        end)
    end)
    if fail and isfunction(fail) then WebPanel:AddFunction("vurv","imagefail",fail) end
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
    return WebMaterials[url] and WebMaterials[url].unlit or ErrorMaterial
end

local function failure_callback(url)
    printf("[VExtensions E2] Image failed to load w/ url of \n%s",url)
end

local function toVertexLit(material)
    -- I tried using one render target then copying the data from that to the vertexlitgeneric material, but that isn't working.
    -- Am I misinterpreting how gmod textures work? Afaik this is how it'd work in starfall.
    local id = material:GetName()
    local vertexlitmat = CreateMaterial("vex_tvl_"..id,"VertexLitGeneric")
    local rt = GetRenderTarget("vex_tv1_rt_"..id,1024,1024)
    render.ClearRenderTarget(rt,Color(0,0,0,255))
    render.PushRenderTarget(rt)
        cam.Start2D()
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(material)
            surface.DrawTexturedRect(0,0,1024,1024)
        cam.End2D()
        vertexlitmat:SetTexture("$basetexture", rt)
    render.PopRenderTarget()
    return vertexlitmat,rt
end

local function applyWebMat(url,prop)
    if not IsValid(prop) then return end
    local WebMat = WebMaterials[url]
    if WebMat then
        if WebMat.vertex then
            prop:SetMaterial("!"..WebMat.vertex:GetName())
        else
            local vertexlit,rt = toVertexLit(WebMat.unlit)
            WebMat.vertex = vertexlit
            WebMat.rt = rt
            prop:SetMaterial("!" .. vertexlit:GetName())
        end
    else
        timer.Simple(1,function()
            applyWebMat(url,prop)
        end)
    end
end

vex.createWebMaterial = webMaterial
vex.getURLMaterialEx = getURLMaterialEx
vex.getWebMaterial = function(url)
    return WebMaterials[url]
end

vex.net_Receive("webmaterial_create",function()
    -- On webmaterial creation.
    local url = net.ReadString()
    local ply = net.ReadEntity()
    -- We read the UInt instead of directly doing net.ReadEntity, because net.ReadEntity might return NULL, which wouldn't let us keep track of which chip's items to cleanup..
    local chipid = net.ReadUInt(16)

    -- By default, web materials will be 512x512, todo: make a resizing method
    getURLMaterialEx(url,512,512,function(mat,url,w,h,webmaterial)
        webMaterialSetOwner(url,ply)
        webMaterialSetChip(url,chipid)
        printf("[VExtensions E2] Player %s (%s) loaded %dx%d webmaterial w/ url of \n%s",ply:GetName(),ply:SteamID(),512,512,url)
    end)
end)


-- Modes:
-- 0 -- Destroy single web material, provide player and string url
-- 1 -- Destroy all web materials of a player's chip, provide chip
-- 2 -- Destroy all web materials of a player, but only because they requested to. Send player
-- 3 -- Destroy a player's web material setup as a whole, because they just left the server, provide player.

-- The server is handling webmaterial ownership. We assume that it will always be correct (cuz it will)
local handleDestroy = {
    [0] = function()
        -- Destroying a single web material
        local url = net.ReadString()
        if not WebMaterials[url] then return end
        WebMaterials[url]:destroy()
        WebMaterials[url] = nil
        --print("Destroyed wm: " .. url)
    end,
    [1] = function()
        -- Destroying all of the webmaterials registered to a chip.
        local chipid = net.ReadUInt(16)
        local webmaterials = WebMaterials.chips[chipid]
        if webmaterials then
            for url in next,webmaterials do
                local mat = WebMaterials[url]
                if not mat then continue end
                mat:destroy()
                WebMaterials[url] = nil
                --print("Destroyed webmaterial " .. url)
            end
        else
            --print("No webmaterials found for that chip.")
        end
        WebMaterials.chips[chipid] = nil
    end,
    [2] = function()
        -- Destroying all of the webmaterials registered to a player.
        local ply = net.ReadEntity()
        if not WebMaterials.plys[ply] then return end -- None registered.
        for url in next,WebMaterials.plys[ply] do
            --print("Destroying wm: " .. url)
            WebMaterials[url]:destroy()
            WebMaterials[url] = nil
        end
    end,
    [3] = function()
        -- Destroy all of the webmaterials registered to a player + deleting the player. Kinda unnecessary.
        local ply = net.ReadEntity()
        --print("Destroying a player.")
        if not WebMaterials.plys[ply] then return end -- None registered.
        for url in next,WebMaterials.plys[ply] do
            --print("Destroying wm: " .. url)
            WebMaterials[url]:destroy()
            WebMaterials[url] = nil
        end
        WebMaterials.plys[ply] = nil
    end
}

vex.net_Receive("webmaterial_destroy",function()
    local mode = net.ReadUInt(2)
    handleDestroy[mode]()
end)

local last_applied = NULL

vex.net_Receive("webmaterial_apply",function()
    local url = net.ReadString()
    local prop = net.ReadEntity()
    if not IsValid(prop) then return end
    if last_applied == prop then return end -- Avoid some spam
    last_applied = prop
    applyWebMat(url,prop)
end)