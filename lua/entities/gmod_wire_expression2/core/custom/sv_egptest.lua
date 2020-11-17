--[[
    ____                              ____                      
   /  _/___ ___  ____ _____ ____     / __ )____  _  _____  _____
   / // __ `__ \/ __ `/ __ `/ _ \   / __  / __ \| |/_/ _ \/ ___/
 _/ // / / / / / /_/ / /_/ /  __/  / /_/ / /_/ />  </  __(__  ) 
/___/_/ /_/ /_/\__,_/\__, /\___/  /_____/\____/_/|_|\___/____/  
                    /____/                                      
    Allow players to create boxes with their textures set to a URL.
]]


local URLWhitelist = CreateConVar("vex_url_whitelist_sv","1",FCVAR_REPLICATED,"Whether EGP Image boxes should be restricted by the whitelist or not.")

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

-- If you are wondering, gifs do not work
e2function void wirelink:egpImageBox( number index, vector2 pos, vector2 size , string url )
    if (!EGP:IsAllowed( self, this )) then return end
    if not isGoodURL(url) then
        self.player:ChatPrint("For the full list of whitelisted domains for urls, check here: [placeholder]")
        error("This is not a whitelisted url! See your chat box for more details",0)
    end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["ImageBox"], { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2], url = url}, self.player )
    if bool then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end