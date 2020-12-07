--[[
    ____         _         __   ______ __        __            __
   / __ \ _____ (_)____   / /_ / ____// /____   / /_   ____ _ / /
  / /_/ // ___// // __ \ / __// / __ / // __ \ / __ \ / __ `// / 
 / ____// /   / // / / // /_ / /_/ // // /_/ // /_/ // /_/ // /  
/_/    /_/   /_//_/ /_/ \__/ \____//_/ \____//_.___/ \__,_//_/   
 Allows for people to print to other's consoles, with warnings and options to disable.
    No RGBA support (for now?)
]]


-- TODO: Rework this

vex.registerExtension("printGlobal", true, "Allows E2s to use printGlobal and printGlobalClk functions, to print to other player's chats with color, with configurable char, argument and burst limits. vex_printglobal_enable_cl")

vex.addNetString("printglobal")

local CharMax = CreateConVar("vex_printglobal_charmax_sv","450",FCVAR_REPLICATED,"The amount of chars that can be sent with the e2function printGlobal(). Max 2000, default 450",0,2000)
local ArgMax = CreateConVar("vex_printglobal_argmax_sv","100",FCVAR_REPLICATED,"The amount of arguments that can be sent with the e2function printGlobal(). Max 255, default 100",0,255)
local BurstMax = CreateConVar("vex_printglobal_burst_sv","4",FCVAR_REPLICATED,"How many times printGlobal can be used in a second. Default 4 times per second, same as default print")

local PrintGBurstCount = {}
local PrintGCache = { recent = {NULL,{},""} }
local PrintGAlert = {}
local isE2Array = vex.isE2Array
local format,table_concat,table_insert,table_remove = string.format,table.concat,table.insert,table.remove
local isvector,isstring,istable,isnumber = isvector,isstring,istable,isnumber


-- TODO: Make the cooldownManager compatible for bursts or make a burstManager or something :/
timer.Create("VurvE2_PrintGlobal",1,0,function()
    -- Doing this feels terrible
    PrintGBurstCount = {}
end)

local function canPrintToPly(ply)
    return ply:GetInfoNum("vex_printglobal_enable_cl",0)==1
end

-- Returns whether a value would be fine to use as a vector.
local function validVector(val)
    if isvector(val) then return true end
    if not istable(val) then return false end
    if #val>3 then return end
    for I=1,3 do if not isnumber(val[I]) then return false end end
    return true
end

-- TODO: Make this more efficient
local function printGlobalFormatting(T)
    local Ind = 1
    while true do
        local Current = T[Ind]
        local Next = T[Ind+1]
        if not Current then break end
        if validVector(Current) then
            if validVector(Next) then
                table_remove(T,Ind) -- Make sure we don't have trailing vectors
                continue
            end
        elseif isstring(Current) then -- Stitch together trailing strings, so we always get a vector, then a string, repeat
            if isstring(Next) then
                T[Ind] = Current..Next
                table_remove(T,Ind+1)
                continue
            end
        end
        Ind = Ind + 1
    end
    if not isstring(T[#T]) then T[#T] = nil end
    if not validVector(T[1]) then table_insert(T,1,{100,100,255}) end
    return T
end

local function printGlobal(T,Sender,Plys)
    local currentBurst = PrintGBurstCount[Sender] or 0
    if currentBurst >= BurstMax:GetInt() then return end

    local argLimit = ArgMax:GetInt()
    local argCount = #T
    if argCount > argLimit then
        Sender:PrintMessage(HUD_PRINTCONSOLE, format( "printGlobal() silently failed due to arg count [%d] exceeding max args [%d]",argCount,argLimit ) )
        return
    end
    
    -- Compile all of the string inputs.
    local printStringTable = {}
    for K,V in pairs(T) do
        if isstring(V) then
            table_insert(printStringTable,V)
        elseif not validVector(V) then
            T[K] = tostring(V)
        end
    end
    
    local charLimit = CharMax:GetInt()
    local printString = table_concat(printStringTable)
    if #printString > charLimit then
        Sender:PrintMessage(HUD_PRINTCONSOLE, format("printGlobal() silently failed due to the given # of characters [%d] exceeding the maximum amount of characters [%d]",#printString,charLimit) )
        return
    end

    local NewT = printGlobalFormatting(T)
    local ArgCount = (#NewT)/2
    if ArgCount <= 100 then
        -- Make sure there aren't more args than max convar setting (somehow)
        vex.net_Start("printglobal")
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
        if Ply and Ply:IsValid() and Ply:IsPlayer() then table_insert(sanitized,Ply) end
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
    if #args==0 then return end
    local sender,first_arg = self.player,args[1]
    if isentity(first_arg) and IsValid(first_arg) and first_arg:IsPlayer() then -- printGlobal(entity owner(),varargs) to specific entity
        local ply = table_remove(args,1)
        return printGlobalArrayFunc(args,sender,{ply})
    elseif isE2Array(first_arg,150,"Player") then -- printGlobal(array plys, varargs) to array of players
        local plys = table_remove(args,1)
        return printGlobalArrayFunc(args,sender,plys)
    end
    printGlobal(args,sender,player.GetHumans()) -- printGlobal(varargs) to everyone
end

__e2setcost(150)
e2function void printGlobal(array args) -- Print to everyone with an array of arguments
    if #args<1 then return end
    printGlobal(args,self.player,player.GetHumans())
end

e2function void printGlobal(array plys,array args)
    printGlobalArrayFunc(args,self.player,plys)
end

-- RunOnGChat / Run on global prints -- Vurv

registerCallback("destruct",function(self)
    PrintGAlert[self.entity] = nil
end)

__e2setcost(3)
e2function number printGlobalClk()
    return self.data.runByPrintGClk and 1 or 0
end

-- TODO: Replace with vex e2helperfuncs runOn* system.
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
