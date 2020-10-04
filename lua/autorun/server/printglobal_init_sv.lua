-- Init for e2 / starfallex.

util.AddNetworkString("PrintGlobal_Net")

CreateConVar("printglobal_charmax_sv","450",FCVAR_REPLICATED,"The amount of chars that can be sent with the e2function printGlobal()",0,2000)
CreateConVar("printglobal_argmax_sv","100",FCVAR_REPLICATED,"The amount of arguments that can be sent with the e2function printGlobal()",0,255)
CreateConVar("printglobal_burst_sv","4",FCVAR_REPLICATED,"How many times printGlobal can be used in a second.")