--[[
 _       __     __    __  ___      __            _       __    
| |     / /__  / /_  /  |/  /___ _/ /____  _____(_)___ _/ /____
| | /| / / _ \/ __ \/ /|_/ / __ `/ __/ _ \/ ___/ / __ `/ / ___/
| |/ |/ /  __/ /_/ / /  / / /_/ / /_/  __/ /  / / /_/ / (__  ) 
|__/|__/\___/_.___/_/  /_/\__,_/\__/\___/_/  /_/\__,_/_/____/  
    Allow players to interact with materials fetched from the web
]]

local URLWhitelist = CreateConVar("vex_webmaterials_whitelist_sv","1",FCVAR_REPLICATED,"Whether EGP Image boxes should be restricted by the whitelist or not.")
local MaxMaterials = CreateConVar("vex_webmaterials_max_sv","3",FCVAR_REPLICATED,"How many webmaterials each player is allowed to have at once before overwriting materials with others.")

vex.registerExtension("webMaterials", true, "Allows E2s to use webmaterials in egp, with functions like egpImageBox, to see whitelisted links.")
vex.addNetString("imageboxes")

-- This is the whitelist of all urls that will be available. We do this so people can't theoretically just
-- ip log by sending you to a url that is hosted by grabify or something
-- These are lua patterns.

-- ^ = beginning of str, $ is the end
-- omit the https:// or http:// part of it.
-- Todo: Turn this into a .txt file and just split at newlines.
local URLMatches = {
    -- Discord Avatars
    "^cdn.discordapp.com/avatars/.*$",

    -- Discord-Hosted Images
    "^cdn.discordapp.com/attachments/.*$",

    -- Imgur as a whole
    "^i.imgur.com/.*$",

    -- Youtube Thumbnails
    "^i.ytimg.com/vi/.*$",

    -- Youtube ?Avatars?
    "yt3.ggpht.com/a/.*$",

    -- Spotify API Images for something like a music player :v)
    "i.scdn.co/image/.*$"
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

local function printf(...)
    print(string.format(...))
end

local material_manager = vex.objectManager(80,"vex_webmaterials_max_sv")

e2function number webMaterialMax()
    return material_manager.maxply
end

-- Restrict the amount of times you can call webMaterialClear to 1 second, to avoid net spam / client crashers.
local webmat_cooldown = vex.cooldownManager(1)

__e2setcost(30)
e2function number webMaterialClear()
    -- Web material clear cooldown
    if not webmat_cooldown:use() then return 0 end
    -- There are no materials loaded.
    if not material_manager[ply] then return 0 end
    if material_manager[ply].counter == 0 then return 0 end
    vex.netStart("imageboxes")
        net.WriteBool(true)
        net.WriteEntity(self.player)
    net.Broadcast()
    return 1
end

__e2setcost(3)

e2function number webMaterialCanClear()
    return webmat_cooldown:available() and 1 or 0
end

e2function number webMaterialCount()
    return material_manager:checkpool(self.player).counter
end

__e2setcost(5)

e2function number webMaterialCanCreate()
    if material_manager.counter >= material_manager.maxply then return 0 end
    local ply = self.player
    if not material_manager[ply] then return 1 end
    return material_manager[ply].counter < material_manager.maxply
end

__e2setcost(150)
-- If you are wondering, gifs do not work
e2function void wirelink:egpImageBox( number index, vector2 pos, vector2 size , string url )
    if (!EGP:IsAllowed( self, this )) then return end
    if #url > 2000 then
        error("This url is too long!",0)
    end
    if not isGoodURL(url) then
        self.player:ChatPrint("For the full list of whitelisted domains for urls, check here: [https://github.com/Vurv78/VExtensions/blob/33501e91c7b09c4f4ed0ace16b62c702251bb132/lua/entities/gmod_wire_expression2/core/custom/sv_imagebox.lua#L21]")
        error("This is not a whitelisted url! See your chat box for more details",0)
    end
    local ply = self.player
    if not material_manager:set(ply,url,true) then
        printf("Someone (%s) just hit the max egp image materials!",ply:SteamID())
        error("You have reached the max amount of egp image materials!",0)
    end
    PrintTable(material_manager[ply])
    printf("Someone (%s) is creating an image url.. %s",ply:SteamID(),url)
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["ImageBox"], { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2], url = url, ply = ply}, self.player )
    if bool then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end