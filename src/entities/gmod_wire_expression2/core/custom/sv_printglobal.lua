--[[
    ____         _         __   ______ __        __            __
   / __ \ _____ (_)____   / /_ / ____// /____   / /_   ____ _ / /
  / /_/ // ___// // __ \ / __// / __ / // __ \ / __ \ / __ `// /
 / ____// /   / // / / // /_ / /_/ // // /_/ // /_/ // /_/ // /
/_/    /_/   /_//_/ /_/ \__/ \____//_/ \____//_.___/ \__,_//_/
 Allows for people to print to other's consoles, with warnings and options to disable.
    No RGBA support (for now?)
]]

-- As of 0.3.1, printGlobal will be more private and efficient.
-- I now realise that all printGlobal messages were being saved to the lastGPrint* functions, meaning even if you sent private messages using that,
-- Anyone could read your messages.
-- This is a bad idea to send PMs over this stuff, but still, now there will be a "verify" table which is a lookup table of who the message was sent to, to see who can access this data.

vex.registerExtension("printGlobal", true, "Allows E2s to use printGlobal and printGlobalClk functions, to print to other player's chats with color, with configurable char, argument and burst limits. vex_printglobal_enable_cl")

vex.addNetString("printglobal")

local CharMax = CreateConVar("vex_printglobal_charmax_sv","500",FCVAR_REPLICATED,"The amount of chars that can be sent with the e2function printGlobal(). Max 2000, default 500",0,2000)
local ArgMax = CreateConVar("vex_printglobal_argmax_sv","100",FCVAR_REPLICATED,"The amount of arguments that can be sent with the e2function printGlobal(). Max 255, default 100",0,255)

-- RunOn*
local EventData = WireLib.RegisterPlayerTable{ recent = {sender = NULL, raw = {}, text = "", verify = {}} }
local ChipsSubscribed = {}

local table_concat, table_insert, table_remove = table.concat, table.insert, table.remove
local isvector, istable, isnumber, type = isvector, istable, isnumber, type
local throw, isE2Array, validPlayer = vex.throw, vex.isE2Array, vex.validPlayer
local net_WriteUInt, net_WriteString = net.WriteUInt, net.WriteString

local PrintGBurst = vex.burstManager(4) -- 4 uses per second
local function can_print_to_ply(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return ply:GetInfoNum("vex_printglobal_enable_cl",0)==1
end

-- Returns whether a value would be fine to use as an rgb color.
local function valid_color(val)
    if not istable(val) then return end
    if isvector(val) then return true end
    if #val>3 then return end
    for I=1,3 do
        -- If it isn't a Glua vector struct, check if it can qualify as a vector by seeing if the first 3 arguments are numbers.
        -- Will have conflicts with angles, or any e2 array with (only) 3 numbers
        if not isnumber(val[I]) then return end
    end
    return true
end

local function can_access_data(ply, data)
    local hash = data.verify
    if not hash then return end
    return hash[ply]
end

-- Will prepend a color to it if it's missing, etc.
-- Then it will connect strings and discard trailing colors to get to a
-- [color, string] pattern.
-- If the number of characters collected goes over the limit, vex_printglobal_charmax_sv, then it will cut off there.
local function fix_arguments(args)
    local max_len = CharMax:GetInt()
    local ret, ret_pos = {}, 0
    local str_list, str_count = {}, 0 -- Keep a list of all of the strings to be stitched together.
    local str_len = 0
    -- Make sure the list starts with a number.
    if not valid_color(args[1]) then
        ret, ret_pos = { {62, 172, 247} }, 1
    end
    local current_type, stop_routine
    for k,v in ipairs(args) do
        local past_type = current_type
        current_type = valid_color(v) and "color" or type(v)
        if current_type == "color" then -- Is color
            if past_type ~= "color" then
                ret_pos = ret_pos + 1
            end
            ret[ret_pos] = v
        else
            -- Turn everything else into a string
            if current_type ~= "string" then
                v = tostring(v)
                current_type = "string" -- We need this so past_type gets overwritten in the next iteration
            end

            -- Cut off the routine if the total string length is greater than the
            -- max set value.
            local future_len = str_len + #v
            if future_len > max_len then
                local cut_size = max_len - str_len
                v = v:sub(1, cut_size)
                stop_routine = true
                str_len = str_len + cut_size
            else
                str_len = future_len
            end

            if past_type == "string" then
                -- Stitch together trailing strings.
                v = (ret[ret_pos] .. v)
            else
                ret_pos = ret_pos + 1
                str_count = str_count + 1
            end
            str_list[str_count] = v
            ret[ret_pos] = v
            if stop_routine then break end
        end
    end
    if type(ret[ret_pos]) ~= "string" then ret[ret_pos] = nil end
    -- Returns the ordered list, Ordered list count/size/length, list of the strings, string length of the list of strings.
    return ret, str_list, str_len
end

-- Just removes players that don't have printglobal enabled.
-- We know this is already either a Player or an E2 Array filled with players.
local function fix_target(target)
    local t = type(target)
    if t=="Player" then
        return (can_print_to_ply(target) and target or nil), { [target] = true }
    else
        -- This should always be a table.
        -- If this returns a non-table, it is most likely a fault in vex.isE2Array
        local hash = {}
        local ret, nret = {}, 0
        for k,ply in ipairs(target) do
            if validPlayer(ply) and not hash[ply] then
                if not can_print_to_ply(ply) then target[k] = nil end
                hash[ply] = true
                nret = nret + 1
                ret[nret] = ply
            end
        end
        return ret, hash
    end
end

-- Organizes random arguments given by E2 to a [color, string] pattern then sends the net message
-- to the client to print the message.
local function printGlobal(self,target,args)
    if #args > ArgMax:GetInt() then throw( "Too many arguments in printGlobal call. [%d]", #args) end
    local sender = self.player

    -- Makes sure that the target(s) have printGlobal enabled on their client.
    local target, lookup = fix_target( target )
    if not target or (istable(target) and #target==0) then return end -- No targets found.

    -- Makes sure args are in a [color, string] pattern.
    local fixed_args,strings = fix_arguments( args )
    local total_str = table_concat(strings)
    -- Each newline in the printed str is +1k OPS to prevent abuse.
    self.prf = self.prf + select( 2, string.gsub(total_str,"\n","") )*1000
    local nargs = #fixed_args
    vex.net_Start("printglobal")
        net_WriteUInt(sender:EntIndex(), 16)
        net_WriteUInt(nargs,9)
        -- Fixed args is in [color, string] format. So we loop through every other argument. 1, 3, 5..
        for ind = 1, nargs, 2 do
            local Col = fixed_args[ind] -- Do not worry, all text is stitched together and is only separated by colors
            net_WriteUInt(Col[1],8)
            net_WriteUInt(Col[2],8)
            net_WriteUInt(Col[3],8)
            net_WriteString( fixed_args[ind+1] )
        end
        self.prf = self.prf + (net.BytesWritten() * 20) -- Add 20 ops per byte written.
    net.Send( target ) -- Make sure to not send the net message to people with printglobal disabled.

    local event_data = {
        sender = sender,
        raw = fixed_args,
        text = total_str,
        verify = lookup -- To make sure whether a chip can access this data. See L10
    }
    EventData.recent = event_data
    EventData[sender] = event_data
    for chip in pairs(ChipsSubscribed) do
        local instance = chip.context
        local ply = instance.player
        if ply ~= sender and lookup[ply] then
            -- Only send the message to players that will receive the message in the first place. (For privacy)
            -- Also don't send it to the sender of the printGlobal message.
            instance.data.runByPrintGClk = event_data
            chip:Execute()
            instance.data.runByPrintGClk = nil
        end
    end
end

-- PrintGlobal, but it works for varargs by allowing the first argument to be either:
-- A table of players
-- A single player.
local function printGlobalSort( self, args )
    -- Checks whether the first argument given is either a Player or an e2 array (lua table) of Players.
    if isentity(args[1]) and args[1]:IsPlayer() then
        local target = table_remove(args, 1)
        printGlobal( self, target, args )
    elseif isE2Array(args[1],150,"Player") then
        local target = table_remove(args, 1)
        printGlobal( self, target, args )
    else
        printGlobal( self, player.GetHumans(), args )
    end
end

__e2setcost(3)
-- Returns 1 or 0 for whether you can use printGlobal in terms of the burst limit.
-- Does not check who you can print to.
e2function number canPrintGlobal()
    return PrintGBurst:available( self.player ) and 1 or 0
end

-- Doesn't return 0 if you can't print due to burst reasons though.
e2function number canPrintTo(entity ply)
    return canPrintToPly(ply) and 1 or 0
end

__e2setcost(100)
e2function void printGlobal(...)
    if not PrintGBurst:use( self.player ) then throw("You can only printGlobal 4 times per second!") end
    printGlobalSort( self, {...} )
end

__e2setcost(150)
e2function void printGlobal(array args) -- Print to everyone with an array of arguments
    if not PrintGBurst:use( self.player ) then throw("You can only printGlobal 4 times per second!") end
    printGlobalSort( self, args )
end

e2function void printGlobal(array plys, array args)
    if not PrintGBurst:use( self.player ) then throw("You can only printGlobal 4 times per second!") end
    printGlobal( self, fix_target( plys ), args)
end

-- RunOnGChat / Run on global prints
registerCallback("destruct",function(self)
    ChipsSubscribed[self.entity] = nil
end)

__e2setcost(3)
e2function number printGlobalClk()
    return self.data.runByPrintGClk and 1 or 0
end

e2function void runOnPrintGlobal(on)
    ChipsSubscribed[self.entity] = (on~=0 and true or nil)
end

__e2setcost(5)

-- With the addition of security to make sure if you didn't receive the message you won't be able to track the message in the lastG* functions,
-- The problem arises with using the functions outside of the clk calls, which will not let you get the value of the last message sent if the last one is hidden from you.

-- Returns the all of the raw arguments (string, color, ...) of a printGlobal statement.
-- Example: printGlobal(vec(255,0,0),"hello","world",vec(0),"black") will return array( vec(255,0,0), "hello", "world", vec(0), "black" )
e2function array lastGPrintRaw()
    if not can_access_data(self.player, EventData.recent) then return {} end
    return EventData.recent.raw
end

e2function array lastGPrintRaw(entity e)
    if not validPlayer(e) then return {} end
    if not can_access_data(self.player, EventData[e]) then return {} end
    return EventData[e].raw or {}
end

-- Returns the last person to send a printGlobal message.
e2function entity lastGPrintSender()
    if not can_access_data(self.player, EventData.recent) then return NULL end
    return EventData.recent.sender
end

-- Returns the last stitched together text of a printGlobal message.
-- Example: printGlobal(vec(255,0,0),"hello","world",vec(0),"black") will return "helloworldblack" in lastGPrintText.
e2function string lastGPrintText()
    if not can_access_data(self.player, EventData.recent) then return "" end
    return EventData.recent.text
end

e2function string lastGPrintText(entity e)
    if not validPlayer(e) then return "" end
    if not can_access_data(self.player, EventData[e]) then return "" end
    return EventData[e].text or ""
end
