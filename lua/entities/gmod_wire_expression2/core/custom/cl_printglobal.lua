local E2D = E2Helper.Descriptions
local format = string.format
local function desc(Name,Descript)
    E2D[Name] = format("%s. [VExtensions]",Descript)
end

-- Main
desc("canPrintGlobal()","Returns 1 or 0 for whether you can call printGlobal()")
desc("canPrintTo(e)","Returns 1 or 0 for whether you can printGlobal to player e")

desc("printGlobal(...)","Prints to everyone's chat, similarly to how chat.addText does, with colors and text that can be organized in any way")
desc("printGlobal(r,...)","Prints to an array of people's chats, similarly to how chat.addText does, with colors and text that can be organized in any way")
-- ^^^Does not actually exist as a function, but printGlobal(...) does implement it.^^^
desc("printGlobal(r)","Prints to everyone's chat using an array of arguments instead of ..., behaves similarly to chat.addText")
desc("printGlobal(r,r)","Prints to an array of people's chats using an array of arguments instead of ..., behaves similarly to chat.addText")

-- PrintGlobalClks
desc("runOnPrintGlobal(n)","Sets the e2 to run on people using the printGlobal function with e2, n being 1 to run and 0 to not run")
desc("printGlobalClk()","Returns 1 or 0 for whether the e2 chip was triggered by someone using printGlobal on e2")
desc("lastGPrintRaw()","Returns an array of the last printGlobalClk information retrieved")
desc("lastGPrintRaw(e)","Returns an array of the last printGlobalClk information retrieved on player e")
desc("lastGPrintSender()","Returns the last player to use printGlobal with e2")
desc("lastGPrintText()","Returns the last text to be sent with printGlobal with e2")
desc("lastGPrintText(e)","Returns the last text to be sent by player e with printGlobal with e2")