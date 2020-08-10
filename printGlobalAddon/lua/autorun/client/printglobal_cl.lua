-- PrintGlobal by Vurv (363590853140152321)
if SERVER then AddCSLuaFile() return end

-- These are replicated from the server, so you cannot edit them but you can access their values.
CreateConVar("printglobal_charmax_sv","350",FCVAR_REPLICATED,"The amount of chars that can be sent with the e2function printGlobal()",0,2000)
CreateConVar("printglobal_argmax_sv","50",FCVAR_REPLICATED,"The amount of arguments that can be sent with the e2function printGlobal()",0,255)
CreateConVar("printglobal_burst_sv","4",FCVAR_REPLICATED,"How many times printGlobal can be used in a second.")

local CV_GlobalChat = CreateClientConVar("printglobalenabled_cl","1",true,true,"Allows players to send messages to your chat with e2.")
local format = string.format

local function warnClient(sender)
    print(format("%s is printing to your chat with printGlobal and StarfallEx.\nTo disable printGlobal across expression 2 and starfallex for yourself, use the convar printglobalenabled_cl",sender and sender:GetName() or "Unknown Player"))
end

net.Receive("PrintGlobal_Net", function()
    local sender = net.ReadEntity()
    warnClient(sender)
	local args = net.ReadInt(9)
    local result = {}
    for I = 1,args do
        table.insert(result,net.ReadColor())
		table.insert(result,net.ReadString())
    end
	chat.AddText( unpack( result ) )
end)