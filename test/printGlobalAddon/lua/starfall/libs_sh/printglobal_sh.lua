-- PrintGlobal functions added to StarfallEx by Vurv
-- Vurv#6428 (363590853140152321)

local CharMax = GetConVar("printglobal_charmax_sv")
local ArgMax = GetConVar("printglobal_argmax_sv")
local BurstMax = GetConVar("printglobal_burst_sv")
local PrintGBurstCount = {}

local format = string.format

timer.Create("VurvSF_PrintGlobal",1,0,function()
    -- Not sure if this would be cheaper than checking manually with curtime.
    PrintGBurstCount = {}
end)

local function canPrintToPly(ply)
    return ply:GetInfoNum("printglobalenabled_cl",0)==1
end

local function warnClient(sender)
    print(format("%s is printing to your chat with printGlobal and StarfallEx.\nTo disable printGlobal across expression 2 and starfallex for yourself, use the convar printglobalenabled_cl",sender and sender:GetName() or "Unknown Player"))
end

local function printGlobalFormatting(T)
    local Ind = 1
    while true do -- looks very scary
        local Current = T[Ind]
        if not Current then break end
        if type(Current)=="table" then
            T[Ind] = Color(Current[1],Current[2],Current[3]) -- StarfallEx colors aren't actual colors that work with chat.AddText
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
            T[Ind] = tostring(Current) -- Turns it to a string and stays on the same index to retry calculations
        end
    end
    if type(T[#T]) == "table" then table.remove(T,#T) end
    if type(T[1]) ~= "table" then table.insert(T,1,Color(100,100,255)) end
    return T
end

local function printGlobal(T,Sender,Plys)
    local currentBurst = PrintGBurstCount[Sender] or 0
    if currentBurst >= BurstMax:GetInt() then return end
    local argLimit = ArgMax:GetInt()
    if #T > argLimit then
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
    local charLimit = CharMax:GetInt()
    if #printString > charLimit then
        local error = format("printGlobal() silently failed due to arg count [%d] exceeding max chars [%d]",#printString,charLimit)
        Sender:PrintMessage(HUD_PRINTCONSOLE,error)
        return
    end
    local NewT = printGlobalFormatting(T)
    local ArgCount = (#NewT)/2
    if ArgCount <= 100 then
        -- Make sure there aren't more args than max convar setting (somehow)
        if CLIENT then
            chat.AddText(unpack(NewT))
            return
        end
        net.Start("PrintGlobal_Net") 
            net.WriteEntity(Sender)
            net.WriteUInt(ArgCount,9)
            for I = 1,ArgCount do
                local Col = T[I*2-1] -- Do not worry, all text is stitched together and is only separated by colors
                net.WriteColor(Col) -- Since we now cleaned the color in the formatting function, we can use this correctly.
                local Text = T[I*2] -- this means that it will 100% always be text,color,text
                net.WriteString(Text)
            end
        if not Plys then Plys = player.GetHumans() end
        for K,Ply in pairs(Plys) do -- Remove players from the send list who don't have globalchat enabled.
            if not canPrintToPly(Ply) then Plys[K] = nil end
        end
        net.Send(Plys)
        PrintGBurstCount[Sender] = currentBurst + 1
    end
end

-- General PrintGlobal (Only args, sends to all)
local function printGlobalArrayFunc(args,sender,plys)
    print("hello")
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

-- Starfall library functions
local checkluatype = SF.CheckLuaType
local registerPrivilege = SF.Permissions.registerPrivilege or SF.Permissions.registerprivilege -- wtf Starfall

local Error = SF.Throw
local Alert = function(user,msg)
    if CLIENT then print(msg) else user:PrintMessage(HUD_PRINTCONSOLE,msg) end
end

return function(instance)
    local builtins = instance.env
    local user = instance.player
    local color_meta = instance.Types.Color
    local iscolor = function(obj)
        return checktype(obj, color_meta, 2)
    end

    --- On SERVER, Print to everyone on the server or if the first argument is a table, to certain players.
    --- Behaves similarly to chat.addText so you may add colors as you wish. (Entities and other types are currently not supported)
    --- On CLIENT, Prints to the current client and also behaves similarly to chat.addText.
    -- @name builtins_library.printGlobal
    -- @class function
    -- @param ... arguments given to print to everyone, behaves like chat.AddText.
    -- @return Returns true or false for whether it successfully printed.
    -- @shared
    function builtins.printGlobal(...)
        local args = {...}
        if #args<1 then return end
        print("test")
        if type(args[1])=="table" then -- In place of printGlobal(array arr, ...) (wouldn't work because printGlobal(...) exists.)
            print(args[1],iscolor(args[1]))
            local plys = table.remove(args,1)
            print(plys)
            printGlobalArrayFunc(args,user,plys)
            return
        end
        printGlobal(args,user,player.GetHumans())
    end
end