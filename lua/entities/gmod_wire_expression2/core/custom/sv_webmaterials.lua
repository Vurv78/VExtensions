--[[
 _       __     __    __  ___      __            _       __    
| |     / /__  / /_  /  |/  /___ _/ /____  _____(_)___ _/ /____
| | /| / / _ \/ __ \/ /|_/ / __ `/ __/ _ \/ ___/ / __ `/ / ___/
| |/ |/ /  __/ /_/ / /  / / /_/ / /_/  __/ /  / / /_/ / (__  ) 
|__/|__/\___/_.___/_/  /_/\__,_/\__/\___/_/  /_/\__,_/_/____/  
    Allow players to interact with materials fetched from the web
]]

local URLWhitelist = CreateConVar("vex_webmaterials_whitelist_sv","1",FCVAR_REPLICATED,"Whether webmaterials should be restricted by the whitelist or not.")
local MaxMaterials = CreateConVar("vex_webmaterials_max_sv","5",FCVAR_REPLICATED,"How many webmaterials each player is allowed to have at once before needing to clear them.")

vex.registerExtension("webMaterials", true, "Allows E2s to use webmaterials in egp, with functions like egpImageBox, to see whitelisted links.")
vex.addNetString("webmaterial_destroy")
vex.addNetString("webmaterial_create")
vex.addNetString("webmaterial_apply")

-- This is the whitelist of all urls that will be available. We do this so people can't theoretically just
-- ip log by sending you to a url that is hosted by grabify or something
-- These are lua patterns.

-- ^ = beginning of str, $ is the end
-- omit the https:// or http:// part of it.
-- Todo: Turn this into a .txt file and just split at newlines.
local URLMatches = {
    -- Discord Avatars
    "^cdn%.discordapp%.com/avatars/.*$",

    -- Discord-Hosted Images
    "^cdn%.discordapp%.com/attachments/.*$",

    -- Imgur as a whole
    "^i%.imgur%.com/.*$",

    -- Youtube Thumbnails
    "^i%.ytimg%.com/vi/.*$",

    -- Youtube ?Avatars?
    "^yt3.ggpht%.com/a/.*$",

    -- Spotify API Images for something like a music player :v)
    "^i%.scdn%.co/image/.*$",
	
    -- Reddit
    "^i%.redd%.it/.*$"
}

local function isGoodURL(url)
    if URLWhitelist:GetInt() == 0 then return true end
    local snipped_url = string.match(url,"^https?://(.*)")
    if not snipped_url then return false end
    for K,Pattern in pairs(URLMatches) do
        if string.find(snipped_url,Pattern) then return true end
    end
    return false
end

-- EGP Helper function
local function Update(self,this)
	self.data.EGP.UpdatesNeeded[this] = true
end

local printf = vex.printf
local material_manager = vex.objectManager(80,"vex_webmaterials_max_sv")

-- Webmaterial e2 type
local WebMaterial = {
    wm = true,
    url = "",
    creator = NULL
}
WebMaterial.__index = WebMaterial

local function iswm(wm)
    return wm and istable(wm) and wm.wm
end

registerType("webmaterial", "xwm", nil,
	nil,
	nil,
	function(ret)
		if not ret then return end
        	if not iswm(ret) then error("Return value is neither nil nor a webmaterial, but a "..type(ret).."!",0) end
	end,
	function(v)
		return type(v)~="table" and not v.wm
	end
)

e2function webmaterial operator=(webmaterial lhs, webmaterial rhs) -- Co = coroutine("bruh(e:)")
	local scope = self.Scopes[ args[4] ]
	scope[lhs] = rhs
	scope.vclk[lhs] = true
	return rhs
end

e2function number operator==(webmaterial lhs, webmaterial rhs) -- if(coroutineRunning()==Co)
    return lhs == rhs
end

e2function number operator_is(webmaterial wm) -- if(coroutineRunning())
    return iswm and 1 or 0
end

-- todo: Replace this with a proper system with the objectManager.
local webmaterials_cache = {}
local function webMaterial(url,owner)
    local creator = webmaterials_cache[url] or owner
    return setmetatable({url = url, creator = creator, cached = webmaterials_cache[url]~=nil},WebMaterial)
end

-- Restrict the amount of times you can call net-related functions to avoid client-crashers / net spam.

local webmat_net = vex.cooldownManager(0.75) -- Webmaterial creation
local webmat_net_destroy = vex.cooldownManager(0.5) -- Webmaterial clearing / destruction
local webmat_net_apply = vex.cooldownManager(0.25) -- Webmaterial applying on props
local webmat_net_spam = vex.cooldownManager(0.25) -- We will use this alongside queues.

-- Modes:
-- 0 -- Destroy single web material, provide player and string url
-- 1 -- Destroy all web materials of a player's chip, provide chip
-- 2 -- Destroy all web materials of a player, but only because they requested to. Send player
-- 3 -- Destroy a player's web material setup as a whole, because they just left the server, provide player.

-- This (only) destroys web materials on the clientside. You have to destroy them on the server separately
local function destroyWebMaterials(ply,mode,ply_or_chip,url)
    if not webmat_net_spam:use(ply) then return end
    webmat_net_destroy:queue(ply,function()
        vex.net_Start("webmaterial_destroy")
            net.WriteUInt(mode,2)
            if mode == 1 then
                net.WriteUInt(ply_or_chip,16)
            else
                net.WriteEntity(ply_or_chip)
            end
            if url and mode == 0 then
                net.WriteString(url)
            end
        net.Broadcast()
    end)
end

-- Returns a table of players who have vex_webmaterials_enabled_cl set to 1
-- Could replace with something like cvars.AddChangeCallback but for clientside cvars?
local function getNetPlayerList()
    local list = {}
    for K,Ply in pairs(player.GetAll()) do
        if Ply:GetInfoNum("vex_webmaterials_enabled_cl",1) == 1 then
            table.insert(list,Ply)
        end
    end
    return list
end

registerCallback("construct",function(self)
    self.data.webmaterials = {} -- Keep track of all of the webmaterials created by this context.
end)

registerCallback("destruct",function(self)
    local ply = self.player
    -- Release serverside objects
    for webmat_object in next,self.data.webmaterials do
        material_manager:release(ply,webmat_object.url)
    end
    -- Release clientside materials
    destroyWebMaterials(ply,1,self.entity:EntIndex())
end)

vex.onPlayerLeave(function(ply)
    -- Kill serverside object pool of player ply
    material_manager:clear(ply)
    -- Kill clientside materials
    destroyWebMaterials(ply,3,ply) -- weird
end)

__e2setcost(30)

e2function number webMaterialClear()
    local ply = self.player
    if not material_manager[ply] then return 0 end
    if material_manager[ply].counter == 0 then return 0 end
    if not webmat_net_spam:use(ply) then return end
    webmat_net_destroy:queue(ply,function()
        vex.net_Start("webmaterial_destroy")
            net.WriteBool(true) -- Tell the client to delete ALL of this player's materials.
            net.WriteEntity(ply)
        net.Send(getNetPlayerList())
        material_manager:clear(ply)
    end)
    return 1
end

__e2setcost(3)

e2function number webMaterialMax()
    return material_manager.maxply
end

e2function number webMaterialCount()
    return material_manager:checkpool(self.player).counter
end

e2function string webmaterial:url()
    if not this then return "" end
    return this.url or ""
end

-- Bloat function. Might be deleted.
-- Returns whether this is a cached webmaterial or not. Idk why you'd need this. Why not I guess.
e2function number webmaterial:cached()
    return this.cached and 1 or 0
end

-- Bloat function. Might be deleted.
-- Would return the original person to create the webmaterial if you make another one that ends up caching it. Idk why you'd need this. Why not I guess.
e2function entity webmaterial:creator()
    return this.creator or NULL
end

e2function number webmaterial:destroyed()
    if not this then return 0 end
    if this.destroyed then return 1 end
    return 0
end

__e2setcost(30)
e2function number webmaterial:destroy()
    if not this then return 0 end
    local ply = self.player
    if not material_manager:grab(ply,this.url) then return 0 end -- Material doesn't exist??
    material_manager:release(ply,this.url)
    this.destroyed = true
    if this.creator ~= ply then return 1 end -- Will destroy the serverside object, but not the clientside one if this one was created from a cache.
    if not webmat_net_spam:use(ply) then return 0 end
    webmat_net_destroy:queue(ply,function()
        vex.net_Start("webmaterial_destroy")
            net.WriteBool(false)
            net.WriteString(this.url)
        net.Send(getNetPlayerList())
    end)
    return 1
end

__e2setcost(5)

e2function number webMaterialCanCreate()
    local ply = self.player
    if not webmat_net:available(ply) then return 0 end
    if material_manager.counter >= material_manager.maxply then return 0 end
    if not material_manager[ply] then return 1 end
    return (material_manager[ply].counter < material_manager.maxply) and 1 or 0
end

__e2setcost(100)

e2function webmaterial webMaterial(string url)
    local ply = self.player
    if not webmat_net:use(ply) then return end
    if #url > 2000 then
        error("This url is too long!",0)
    end
    if not isGoodURL(url) then
        ply:ChatPrint("For the full list of whitelisted domains for urls, check here: [https://github.com/Vurv78/VExtensions/blob/33501e91c7b09c4f4ed0ace16b62c702251bb132/lua/entities/gmod_wire_expression2/core/custom/sv_imagebox.lua#L21]")
        error("This is not a whitelisted url! See your chat box for more details",0)
    end
    local wm = webMaterial(url,ply)
    if not material_manager:set(ply,url,wm) then
        printf("%s (%s) just hit the max # of webmaterials (%d)!",ply:GetName(),ply:SteamID(),material_manager.maxply)
        error("You have reached the max amount of webmaterials!",0)
    end
    self.data.webmaterials[wm] = true -- Keep in chip's storage to destroy on chip deletion
    vex.net_Start("webmaterial_create")
        net.WriteString(url)
        net.WriteEntity(ply)
        net.WriteUInt(self.entity:EntIndex(),16)
    net.Send(getNetPlayerList())
    return wm
end

__e2setcost(150)
-- If you are wondering, gifs do not work
-- Creates a webmaterial for you automatically.
e2function webmaterial wirelink:egpImageBox( number index, vector2 pos, vector2 size , string url )
    if (!EGP:IsAllowed( self, this )) then return end
    local ply = self.player
    if not webmat_net:use(ply) then return end
    if #url > 2000 then
        error("This url is too long!",0)
    end
    if not isGoodURL(url) then
        self.player:ChatPrint("For the full list of whitelisted domains for urls, check here: [https://github.com/Vurv78/VExtensions/blob/33501e91c7b09c4f4ed0ace16b62c702251bb132/lua/entities/gmod_wire_expression2/core/custom/sv_imagebox.lua#L21]")
        error("This is not a whitelisted url! See your chat box for more details",0)
    end
    local wm = webMaterial(url,ply)
    if not material_manager:set(ply,url,wm) then
        printf("%s (%s) just hit the max # of webmaterials (%d)!",ply:GetName(),ply:SteamID(),material_manager.maxply)
        error("You have reached the max amount of webmaterials!",0)
    end
    self.data.webmaterials[wm] = true -- Keep in chip's storage to destroy on chip deletion
    printf("Someone (%s) is creating an image url.. %s",ply:SteamID(),url)
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["ImageBox"], { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2], url = url, ply = ply}, self.player )
    if bool then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
    return wm
end

__e2setcost(80)
e2function webmaterial wirelink:egpImageBox(number index, vector2 pos, vector2 size, webmaterial wm)
    if (!EGP:IsAllowed( self, this )) then return end
    local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["ImageBox"], { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2], url = wm.url, ply = wm.owner}, self.player )
    if bool then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
    return wm
end

local function isOwner(self,ent)
    if not self then return false end
    if not IsValid(ent:GetOwner()) then return true end
    return ent:GetOwner() == self.player
end

e2function number entity:setMaterial(webmaterial wm)
    if not iswm(wm) then return 0 end
    if not IsValid(this) then return 0 end
    if not isOwner(self, this) then return 0 end
    local ply = self.player
    if not webmat_net_spam:use(ply) then return 0 end
    webmat_net_apply:queue(ply,function()
        vex.net_Start("webmaterial_apply")
            net.WriteString(wm.url)
            net.WriteEntity(this)
        net.Send(getNetPlayerList())
    end)
    return 1
end
