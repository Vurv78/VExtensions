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

-- RunOn*
local EventData = WireLib.RegisterPlayerTable{ recent = {NULL, {}, ""} }
local ChipsSubscribed = {}

local format,table_concat,table_insert,table_remove = string.format,table.concat,table.insert,table.remove
local isvector,isstring,istable,isnumber = isvector,isstring,istable,isnumber
local throw,isE2Array = vex.throw,vex.isE2Array
local net_WriteUInt, net_WriteString = net.WriteUInt, net.WriteString

local PrintGBurst = vex.burstManager(4) -- 4 uses per second
local function canPrintToPly(ply)
    return ply:GetInfoNum("vex_printglobal_enable_cl",0)==1
end

-- Returns whether a value would be fine to use as an rgb color.
local function validColor(val)
    if isvector(val) then return true end
    if not istable(val) then return end
    if #val>3 then return end
    for I=1,3 do if not isnumber(val[I]) then return end end
    return true
end

-- Will prepend a color to it if it's missing, etc.
-- Then it will connect strings and discard trailing colors to get to a
-- [color, string] pattern.
local function fix_args( args )
    local starts_col = validColor(args[1])
    local ind,status,len = starts_col and 2 or 1,"",starts_col and 0 or 1
    local fixed = { not starts_col and {15, 123, 255} or nil }
    local current = args[ind]
    local strings,str_count = {},0 -- Each individual string put in a table.
    repeat
        local current = args[ind]
        local next = args[ind]
        if current==nil then goto destroy end
        ::redo::
        if validColor(current) then
            if status == "color" then
                goto skip
            end
            status = "color"
        elseif isstring(current) then
            str_count = str_count + 1
            strings[str_count] = current
            if status == "string" then
                fixed[len] = fixed[len] .. current
                goto skip
            end
            status = "string"
        else
            current = tostring(current)
            goto redo
        end

        len = len + 1 -- Len is the index of the fixed table that will be used next.
        fixed[len] = current
        ::skip::
        ind = ind + 1 -- Ind is the index of the args table that is being scanned.
        ::destroy::
    until current == nil
    -- If the last arg is a color, get rid of it.
    if validColor(fixed[len]) then fixed[len] = nil end
    return fixed, strings
end

-- Just removes players that don't have printglobal enabled.
local function fix_target( target )
    if isentity(target) then return target end
    for k,ply in pairs(target) do
        if not canPrintToPly(ply) then target[k] = nil end
    end
    return target
end

-- This function assumes a lot:
-- The target is a table of valid players that have printGlobal enabled with the convar.
-- Sender is the entity player sender.
-- Args is a table (Not organized with fix_args yet.)
local function printGlobal(sender,target,args)
    if #args > ArgMax:GetInt() then throw( "Too many arguments in printGlobal call. [%d]", #args) end

    -- Makes sure args are in a [color, string] pattern.
    local fixed_args,strings = fix_args( args )
    local total_str = table_concat(strings)
    local total_str_len = #total_str
    if total_str_len > CharMax:GetInt() then throw("Too many characters in printGlobal call! [%d]", total_str_len) end
    local nargs = #fixed_args
    vex.net_Start("printglobal")
        net.WriteEntity(Sender)
        net_WriteUInt(nargs,9)
        for ind = 1,nargs, 2 do
            local Col = fixed_args[ind] -- Do not worry, all text is stitched together and is only separated by colors
            net_WriteUInt(Col[1],8)
            net_WriteUInt(Col[2],8)
            net_WriteUInt(Col[3],8)
            net_WriteString( fixed_args[ind+1] )
        end
    net.Send( fix_target( target ) ) -- Make sure to not send the net message to people with printglobal disabled.
    local event_data = {sender = sender,raw = NewT, text = printString}
    EventData.recent = event_data
    EventData[sender] = event_data
    for Chip,_ in pairs(ChipsSubscribed) do
        local context = Chip.context
        if context.player ~= sender then -- Don't send runOnGPrint to the initial sender.
            context.data.runByPrintGClk = event_data
            Chip:Execute()
            context.data.runByPrintGClk = nil
        end
    end
end

-- PrintGlobal, but it works for varargs by allowing the first argument to be either:
-- A table of players
-- A single player.
local function printGlobalSort( ply, args )
    -- Checks whether the first argument given is either a Player or an e2 array (lua table) of Players.
    if ( isentity(args[1]) and args[1]:IsPlayer() ) or isE2Array(args[1],150,"Player") then
        printGlobal( ply,  table_remove(args,1) , args )
    else
        printGlobal( ply, player.GetHumans(), args )
    end
end

__e2setcost(3)
e2function number canPrintGlobal()
    return PrintGBurst:available( self.player )
end

-- Doesn't return 0 if you can't print due to burst reasons though.
e2function number canPrintTo(entity ply)
    return canPrintToPly(ply) and 1 or 0
end

__e2setcost(100)
e2function void printGlobal(...)
    if not PrintGBurst:use( self.player ) then throw("You have hit the printGlobal burst of 4 per second!") end
    printGlobalSort( self.player, {...} )
end

__e2setcost(150)
e2function void printGlobal(array args) -- Print to everyone with an array of arguments
    if not PrintGBurst:use( self.player ) then throw("You have hit the printGlobal burst of 4 per second!") end
    printGlobalSort( self.player, args )
end

e2function void printGlobal(array plys,array args)
    if not PrintGBurst:use( self.player ) then throw("You have hit the printGlobal burst of 4 per second!") end
    printGlobal( self.player, fix_target( plys ), args)
end

-- RunOnGChat / Run on global prints
registerCallback("destruct",function(self)
    ChipsSubscribed[self.entity] = nil
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
