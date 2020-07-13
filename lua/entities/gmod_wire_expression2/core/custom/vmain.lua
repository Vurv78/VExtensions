-- Lib functions

local E2Table = function() return {n={},ntypes={},s={},stypes={},size=0} end

local function luaTablToE2(T)
    local Strt = E2Table()
    local Sz = 0
    for Key,Value in pairs(T) do
        local TypeV = type(Value)
        local WriteV = Strt.n
        local WriteType = Strt.ntypes
        if type(Key)=="string" then WriteV = Strt.s WriteType=Strt.stypes end
        local Clean = Value
        if TypeV=="bool" then Clean = Value and 1 or 0 elseif
        TypeV=="table" then Clean = luaTablToE2(Value) end
        Sz = Sz + 1
        WriteV[Key] = Clean
        WriteType[Key] = TypeV[1]
    end
    Strt.size = Sz
    return Strt
end

local function printGlobalFormatting(T)
    local Ind = 1
    local Do = true
    while Do do
        local Current = T[Ind]
        if not Current then break end
        if type(Current)=="table" then
            if type(T[Ind+1])=="table" then table.remove(T,Ind) else Ind = Ind + 1 end
        elseif type(Current)=="string" then
            local Next = T[Ind+1]
            if type(Next) ~= "string" then
                Ind = Ind + 1
            else
                T[Ind] = Current..Next
                table.remove(T,Ind+1)
            end
        else
            Ind = Ind + 1
        end
    end
    if type(T[#T]) == "table" then table.remove(T,#T) end
    if type(T[1]) ~= "table" then table.insert(T,1,{100,100,255}) end
    return T
end

-- Lib functions

__e2setcost(10)
e2function table rangerOffsetManual(vector pos,vector endpos, array filt)
    local Start = Vector(pos[1],pos[2],pos[3])
    local End = Vector(endpos[1],endpos[2],endpos[3])
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
	if not tr then return E2Table() end
	return luaTablToE2(tr)
end

__e2setcost(5)
e2function number rangerSetFilter(array filter)
    if #filter == 0 then self.data.rangerfilter = {} return 1 end
    if #filter > 3000 then return 0 end
	local fixed = {}
    for _,V in pairs(filter) do
        
		if type(V)~="Entity" or type(V)~="Player" then
            table.insert(fixed,V)
        end
	end
    self.data.rangerfilter = filter
    return 1
end

-- Hide Chat 7/3/2020 by Vurv
local chatsHidden = {}

__e2setcost(3)
e2function number canHideChatPly(entity ply)
    if not ply:IsValid() then return end
    return ply:GetInfoNum("vurve2_canhidechat_cl",0)==0 and 0 or 1
end

__e2setcost(20)
e2function void hideChatPly(entity ply, hide)
    if not ply:IsValid() then return end
    if hide==0 then chatsHidden[ply] = false return end
    if self.player ~= ply then
        if ply:GetInfoNum("vurve2_canhidechat_cl",0)==0 then return end
        ply:PrintMessage(HUD_PRINTCONSOLE, string.format("Your chat was hidden by %s's expression 2 chip.",self.player:GetName())) -- Notify the user that their chat was hidden by X
        print(string.format("%s's chat was hidden by %s's expression 2 chip.",ply:GetName(),self.player:GetName())) -- Log to server console
    end
    chatsHidden[ply] = true -- Disregard the convar if you're the owner of the chip.
end

hook.Add("PlayerSay","vurve2_canhidechat_hide",function(sender)
    if sender:GetInfoNum("vurve2_canhidechat_cl",0)~=0 and chatsHidden[sender] then
        chatsHidden[sender] = false
        -- Only hide chat once
        return ""
    end
end)

-- Hide Chat 7/3/2020 by Vurv

local PrintGCharLimit = CreateConVar("vurve2_printglobal_charmax","350",FCVAR_NONE,"The amount of chars that can be sent with the e2function printGlobal()",0,2000)
local PrintGArgLimit = CreateConVar("vurve2_printglobal_argmax","50",FCVAR_NONE,"The amount of arguments that can be sent with the e2function printGlobal()",0,255)
local PrintGBurstLimit = CreateConVar("vurve2_printglobal_burst","4",FCVAR_NONE,"How many times printGlobal can be used in a second.")
local PrintGBurstCount = {}
local PrintGCache = { recent = {NULL,{},""} }
local PrintGAlert = {}

util.AddNetworkString("VurvE2_PrintGlobal_Net")

timer.Create("VurvE2_PrintGlobal",1,0,function()
    PrintGBurstCount = {}
end)

local function printGlobal(T,Sender,Plys)
    local currentBurst = PrintGBurstCount[Sender] or 0
    if currentBurst >= PrintGBurstLimit:GetInt() then return end
    local argLimit = PrintGArgLimit:GetInt()
    if #T > PrintGArgLimit:GetInt() then
        local error = string.format("printGlobal() silently failed due to arg count [%d] exceeding max args [%d]",#T,argLimit)
        Sender:PrintMessage(HUD_PRINTCONSOLE,error)
        return
    end
    local printStringTable = {}
    for K,V in pairs(T) do
        if type(V)=="string" then
            table.insert(printStringTable,V)
        elseif type(V)~="table" then
            table.remove(T,K)
        end
    end
    local printString = table.concat(printStringTable,"")
    local charLimit = PrintGCharLimit:GetInt()
    if #printString > charLimit then
        local error = string.format("printGlobal() silently failed due to arg count [%d] exceeding max chars [%d]",#printString,charLimit)
        Sender:PrintMessage(HUD_PRINTCONSOLE,error)
        return
    end
    local NewT = printGlobalFormatting(T)
    local ArgCount = (#NewT)/2
    if ArgCount <= 100 then
        -- Make sure there aren't more args than max convar setting (somehow)
        net.Start("VurvE2_PrintGlobal_Net") 
            net.WriteInt(ArgCount,9)
            for I = 1,ArgCount do
                local Col = T[I*2-1] -- Do not worry, all text is stitched together and is only separated by colors
                net.WriteColor(Color(Col[1],Col[2],Col[3]))
                local Text = T[I*2] -- this means that it will 100% always be text,color,text
                net.WriteString(Text)
            end
        if not Plys then Plys = player.GetHumans() end
        for K,Ply in pairs(Plys) do -- Remove players from the send list who don't have globalchat enabled.
            if Ply:GetInfoNum("vurve2_printglobalenabled_cl",0)==0 then Plys[K] = nil end
        end
        net.Send(Plys)
        local alertData = {sender = Sender,raw = NewT, text = printString}
        PrintGCache.recent = alertData
        PrintGCache[Sender] = alertData
        for Chip,_ in pairs(PrintGAlert) do
            if IsValid(Chip) then
                local context = Chip.context
                if context.player ~= Sender then -- Don't send runOnGPrint to the initial sender.
                    context.data.runByPrintGClk = alertData
                    Chip:Execute()
                    context.data.runByPrintGClk = nil
                end
            else
                PrintGAlert[Chip] = nil
            end
        end
        PrintGBurstCount[Sender] = currentBurst + 1
    end
end

__e2setcost(3)
e2function number canPrintGlobal()
    return ((PrintGBurstCount[self.player] or 0) >= PrintGBurstLimit:GetInt()) and 0 or 1
end

__e2setcost(150)
e2function void printGlobal(...) -- Print to everyone
    printGlobal({...},self.player,player.GetHumans())
end

__e2setcost(150)
e2function void printGlobal(array a) -- Print to everyone
    if #a<1 then return end
    printGlobal(a,self.player,player.GetHumans())
end

__e2setcost(100)
e2function void printGlobal(array a,...) -- Give an array of which players to broadcast to.
    if #a<1 then return end
    for K,Ply in pairs(a) do -- Sanitizing non-players
        if type(Ply) ~= "Player" then a[K] = nil end
        if not IsValid(Ply) or not Ply:IsPlayer() then a[K] = nil end
    end
    printGlobal({...},self.player,a)
end

-- Print Chat by Vurv

-- Global Print Chat Clk by Vurv

registerCallback("destruct",function(self) -- Pretty sure this is when the chip is undone
    PrintGAlert[self.entity] = nil
end)

__e2setcost(3)
e2function number printGlobalClk()
    return self.data.runByPrintGClk and 1 or 0
end

e2function void runOnPrintGlobal(on)
    PrintGAlert[self.entity] = on~=0 and true or nil
end

__e2setcost(5)
e2function array lastGPrintRaw() -- Pls give better name
    return PrintGCache.recent.raw or {}
end

e2function array lastGPrintRaw(entity e) -- Pls give better name
    return PrintGCache[e].raw or {}
end

e2function entity lastGPrintSender() -- Pls give better name
    return PrintGCache.recent.sender or NULL
end

e2function string lastGPrintText() -- Pls give better name
    return PrintGCache.recent.text or ""
end

e2function string lastGPrintText(entity e) -- Pls give better name
    return PrintGCache[e].text or ""
end

-- Global Print Chat Clk by Vurv

-- Texture Stuff by Vurv

e2function vector getPixelPNG(x,y,string pngPath)
    if not string.match(pngPath,".png$") then return {0,0,0} end
    local C = Material(pngPath):GetColor(x,y)
    return {C.r,C.g,C.b}
end

-- EGP Testing by Vurv


e2function void wirelink:egpDrawRect(x,y,sx,sy)
    --if !EGP:ValidEGP(this) then return end
    if !EGP:IsAllowed(self,this) then return end
end