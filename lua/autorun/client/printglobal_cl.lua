-- PrintGlobal by Vurv (363590853140152321)
if SERVER then AddCSLuaFile() return end -- tbh Idk what this does sorry man

-- These are replicated from the server, so you cannot edit them but you can access their values.
CreateConVar("printglobal_charmax_sv","350",FCVAR_REPLICATED,"The amount of chars that can be sent with the e2function printGlobal()",0,2000)
CreateConVar("printglobal_argmax_sv","50",FCVAR_REPLICATED,"The amount of arguments that can be sent with the e2function printGlobal()",0,255)
CreateConVar("printglobal_burst_sv","4",FCVAR_REPLICATED,"How many times printGlobal can be used in a second.")

local CV_GlobalChat = CreateClientConVar("printglobal_enable_cl","1",true,true,"Allows players to send messages to your chat with expression2 or starfallex.")
local format = string.format

local function warnClient(sender)
    print(format("%s is printing to your chat with printGlobal.\nTo disable printGlobal for yourself, use the convar printglobal_enable_cl and set it to 0",sender and sender:GetName() or "Unknown Player"))
end

net.Receive("PrintGlobal_Net", function()
    local sender = net.ReadEntity()
    warnClient(sender)
	local args = net.ReadInt(9)
    local result = {}
    for I = 1,args do
        table.insert(result,net.ReadColor()) -- TODO: Don't use net.ReadColor, instead read UInts so that this uses less bits
		table.insert(result,net.ReadString())
    end
	chat.AddText( unpack( result ) )
end)