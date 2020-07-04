if SERVER then AddCSLuaFile() return end

local CV_HideChat = CreateClientConVar("vurve2_canhidechat_cl","1",true,true,"Allows players to hide your chat with expression 2.")
local CV_GlobalChat = CreateClientConVar("vurve2_printglobalenabled_cl","1",true,true,"Allows players to send messages to your chat with e2.")

net.Receive("VurvE2_PrintGlobal_Net", function()
	local args = net.ReadInt(9)
    local result = {}
    for I = 1,args do
        table.insert(result,net.ReadColor())
		table.insert(result,net.ReadString())
    end
	chat.AddText( unpack( result ) )
end)