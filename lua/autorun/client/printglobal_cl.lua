-- These are replicated from the server, so you cannot edit them but you can access their values.
CreateConVar("vex_printglobal_charmax_sv","350",FCVAR_REPLICATED,"The amount of chars that can be sent with the e2function printGlobal()",0,2000)
CreateConVar("vex_printglobal_argmax_sv","50",FCVAR_REPLICATED,"The amount of arguments that can be sent with the e2function printGlobal()",0,255)
CreateConVar("vex_printglobal_burst_sv","4",FCVAR_REPLICATED,"How many times printGlobal can be used in a second.")
CreateClientConVar("vex_printglobal_enable_cl","1",true,true,"Allows players to print messages to your chat with expression2")

local function warnClient(sender)
    print(string.format("%s is printing to your chat with printGlobal.\nTo disable printGlobal for yourself, use the convar vex_printglobal_enable_cl and set it to 0",IsValid(sender) and sender:GetName() or "Unknown Player"))
end

local readUInt = net.ReadUInt

vex.net_Receive("printglobal", function()
    -- We don't check the convar here, the server won't send requests if
    local sender = net.ReadEntity()
    if sender ~= LocalPlayer() then warnClient(sender) end
    local result = {}
    for I = 1,readUInt(9), 2 do
        result[I] = Color( readUInt(8), readUInt(8), readUInt(8) )
        result[I+1] = net.ReadString()
    end
    chat.AddText( unpack( result ) )
end)