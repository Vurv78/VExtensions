--[[
    ____         _         __   ______ __        __            __
   / __ \ _____ (_)____   / /_ / ____// /____   / /_   ____ _ / /
  / /_/ // ___// // __ \ / __// / __ / // __ \ / __ \ / __ `// / 
 / ____// /   / // / / // /_ / /_/ // // /_/ // /_/ // /_/ // /  
/_/    /_/   /_//_/ /_/ \__/ \____//_/ \____//_.___/ \__,_//_/   
 Allows for people to print to other's consoles, with warnings and options to disable.

]]

-- Disabled by default
E2Lib.RegisterExtension("printGlobal", false, "Allows E2s to use printGlobal and printGlobalClk functions, to print to other people's chats with color securely")

local CharMax = GetConVar("printglobal_charmax_sv")
local ArgMax = GetConVar("printglobal_argmax_sv")
local BurstMax = GetConVar("printglobal_burst_sv")
local PrintGBurstCount = {}
local PrintGCache = { recent = {NULL,{},""} }
local PrintGAlert = {}
local format = string.format

timer.Create("VurvE2_PrintGlobal",1,0,function()
    -- Not sure if this would be cheaper than checking manually with curtime.
    PrintGBurstCount = {}
end)

local function canPrintToPly(ply)
    return ply:GetInfoNum("printglobal_enable_cl",0)==1
end

local function printGlobalFormatting(T)
    local Ind = 1
    while true do -- oooh scary
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

local function printGlobal(T,Sender,Plys)
    local currentBurst = PrintGBurstCount[Sender] or 0
    if currentBurst >= BurstMax:GetInt() then return end
    if #T > ArgMax:GetInt() then
        local error = format("printGlobal() silently failed due to arg count [%d] exceeding max args [%d]",#T,argLimit)
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
    if #printString > CharMax:GetInt() then
        local error = format("printGlobal() silently failed due to arg count [%d] exceeding max chars [%d]",#printString,charLimit)
        Sender:PrintMessage(HUD_PRINTCONSOLE,error)
        return
    end
    local NewT = printGlobalFormatting(T)
    local ArgCount = (#NewT)/2
    if ArgCount <= 100 then
        -- Make sure there aren't more args than max convar setting (somehow)
        net.Start("PrintGlobal_Net")
            net.WriteEntity(Sender)
            net.WriteInt(ArgCount,9)
            for I = 1,ArgCount do
                local Col = T[I*2-1] -- Do not worry, all text is stitched together and is only separated by colors
                net.WriteColor(Color(Col[1],Col[2],Col[3]))
                local Text = T[I*2] -- this means that it will 100% always be text,color,text
                net.WriteString(Text)
            end
        if not Plys then Plys = player.GetHumans() end
        for K,Ply in pairs(Plys) do -- Remove players from the send list who don't have globalchat enabled.
            if not canPrintToPly(Ply) then Plys[K] = nil end
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

-- General PrintGlobal (Only args, sends to all)
local function printGlobalArrayFunc(args,sender,plys)
    if #plys<1 or #args<1 then return end
    local sanitized = {}
    for K,Ply in pairs(plys) do
        if Ply and Ply:IsValid() and Ply:IsPlayer() then table.insert(sanitized,Ply) end
    end
    if #sanitized<1 then
        local error = format("printGlobal() silently failed due to no valid players being given")
        sender:PrintMessage(HUD_PRINTCONSOLE,error)
        return
    end
    printGlobal(args,sender,sanitized)
end

__e2setcost(3)
e2function number canPrintGlobal()
    return ((PrintGBurstCount[self.player] or 0) >= BurstMax:GetInt()) and 0 or 1
end

e2function number canPrintTo(entity ply)
    return canPrintToPly(ply) and 1 or 0
end

__e2setcost(100)
e2function void printGlobal(...)
    local args = {...}
    if #args<1 then return end
    local sender = self.player
    if type(args[1])=="table" then -- In place of printGlobal(array arr, ...) (wouldn't work because printGlobal(...) exists.)
        local plys = table.remove(args,1)
        printGlobalArrayFunc(args,sender,plys)
        return
    end
    printGlobal(args,sender,player.GetHumans())
end

__e2setcost(150)
e2function void printGlobal(array args) -- Print to everyone with an array of arguments
    if #args<1 then return end
    printGlobal(args,self.player,player.GetHumans())
end

e2function void printGlobal(array plys,array args)
    printGlobalArrayFunc(args,self.player,plys)
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
