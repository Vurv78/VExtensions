-- Init for e2 / starfallex.

util.AddNetworkString("PrintGlobal_Net")

local CharMax = CreateConVar("printglobal_charmax_sv","350",FCVAR_REPLICATED,"The amount of chars that can be sent with the e2function printGlobal()",0,2000)
local ArgMax = CreateConVar("printglobal_argmax_sv","50",FCVAR_REPLICATED,"The amount of arguments that can be sent with the e2function printGlobal()",0,255)
local BurstMax = CreateConVar("printglobal_burst_sv","4",FCVAR_REPLICATED,"How many times printGlobal can be used in a second.")

-- TODO:

-- Can't decide whether to allow clientside to network to here then back to clients to be able to network
-- to more than the current client.

-- Would be pretty insecure and would probably have to bring the print functions here.