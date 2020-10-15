-- OK, We're putting all of the docs into here so this fucking addon doesn't turn into a shitshow of 50 cl files just for 5 lines of definitions.
-- Dev: Vurv 9/27/2020

local E2D = E2Helper.Descriptions
local format = string.format

local function desc(Name,Descript)
    E2D[Name] = format("%s. [VExtensions]",Descript)
end

-- Sick ascii font generator @ http://patorjk.com/software/taag/f=Slant thanks whoever made this

--[[
    __  ___        _      
   /  |/  /____ _ (_)____ 
  / /|_/ // __ `// // __ \
 / /  / // /_/ // // / / /
/_/  /_/ \__,_//_//_/ /_/ 
 Random Misc. Functions that are cool like hiding other people's chat (probably doesn't work) and setting the ranger Filter.                    
]]

desc("rangerOffsetManual(vvr)","Returns direct table result from a util.traceLine call with startpos, endpos and filter")
desc("rangerSetFilter(r)","Sets the current filter to be used for rangers. Returns 1 or 0 for success")
desc("canHideChatPly(e)","Returns whether you can hide a chats player, checking their convar")
desc("hideChatPly(en)","Hides the chat of the player given [e] with n as 1 or 0 for whether it should")

--- These two actually come from sv_coroutine.lua but don't really fit with the addon.
desc("try(s)","Tries to run the first function, and returns an array with the first element being a number 1 or 0 for whether it successfully ran, and the next either being the error message or the return value of the 'try' function.")
-- With catching
desc("catch(ss)","Tries to run the first function, returns the same as try(s) but also calls a second callback function with the same results.")    

--[[
    ____         _         __   ______ __        __            __
   / __ \ _____ (_)____   / /_ / ____// /____   / /_   ____ _ / /
  / /_/ // ___// // __ \ / __// / __ / // __ \ / __ \ / __ `// / 
 / ____// /   / // / / // /_ / /_/ // // /_/ // /_/ // /_/ // /  
/_/    /_/   /_//_/ /_/ \__/ \____//_/ \____//_.___/ \__,_//_/   
 Allows for people to print to other's consoles, with warnings and options to disable.

]]
desc("canPrintGlobal()","Returns 1 or 0 for whether you can call printGlobal()")
desc("canPrintTo(e)","Returns 1 or 0 for whether you can printGlobal to player e")

desc("printGlobal(...)","Prints to everyone's chat, similarly to how chat.addText does, with colors and text that can be organized in any way. First argument can be an array of players")
-- ^^^Does not actually exist as a function, but printGlobal(...) does implement it.^^^
desc("printGlobal(r)","Prints to everyone's chat using an array of arguments instead of ..., behaves similarly to chat.addText")
desc("printGlobal(rr)","Prints to an array of people's chats using an array of arguments instead of ..., behaves similarly to chat.addText")

-- PrintGlobalClks
desc("runOnPrintGlobal(n)","Sets the e2 to run on people using the printGlobal function with e2, n being 1 to run and 0 to not run")
desc("printGlobalClk()","Returns 1 or 0 for whether the e2 chip was triggered by someone using printGlobal on e2")
desc("lastGPrintRaw()","Returns an array of the last printGlobalClk information retrieved")
desc("lastGPrintRaw(e)","Returns an array of the last printGlobalClk information retrieved on player e")
desc("lastGPrintSender()","Returns the last player to use printGlobal with e2")
desc("lastGPrintText()","Returns the last text to be sent with printGlobal with e2")
desc("lastGPrintText(e)","Returns the last text to be sent by player e with printGlobal with e2")

--[[
   _____        __ ____   ___                                        ___ 
  / ___/ ___   / // __/  /   | _      __ ____ _ _____ _____ ___     |__ \
  \__ \ / _ \ / // /_   / /| || | /| / // __ `// ___// ___// _ \    __/ /
 ___/ //  __// // __/  / ___ || |/ |/ // /_/ // /   / /   /  __/   / __/ 
/____/ \___//_//_/    /_/  |_||__/|__/ \__,_//_/   /_/    \___/   /____/ 

 Adds functions similarly to regular-e2's self-aware core.
]]

desc("ifdef(s)","Returns 0 if the function is not defined or couldn't be found, 1 if the function is an e2 function, 2 if the function is a user-defined function and exists")
desc("getFunctionPath(s)","Returns the path where the e2function was defined (not a user defined function), useful for finding whether something was added with an addon.")

--[[
 _    __ ____   __  ___            __   ______                                 __   _  __     _  __ _  __        
| |  / // __ \ /  |/  /____   ____/ /  / ____/____   ____ ___   ____   ____ _ / /_ (_)/ /_   (_)/ /(_)/ /_ __  __
| | / // /_/ // /|_/ // __ \ / __  /  / /    / __ \ / __ `__ \ / __ \ / __ `// __// // __ \ / // // // __// / / /
| |/ // _, _// /  / // /_/ // /_/ /  / /___ / /_/ // / / / / // /_/ // /_/ // /_ / // /_/ // // // // /_ / /_/ / 
|___//_/ |_|/_/  /_/ \____/ \__,_/   \____/ \____//_/ /_/ /_// .___/ \__,_/ \__//_//_.___//_//_//_/ \__/ \__, /  
                                                            /_/                                         /____/   
 Gives access to SHARED VRMod functions in e2.
    Will at some point have access to the hooks as well.
]]

-- All metamethods
desc("isPlayerInVR(e:)","Returns 1 or 0 for if ply is in VR")
desc("usingEmptyHandsVR(e:)","Returns 1 or 0 for if ply is using empty hands in VR")

desc("getHMDPosVR(e:)","Gives vector position of HMD(head mounted display) of player in VR")
desc("getHMDAngVR(e:)","Gives angle of HMD(head mounted display) of player in VR")

desc("getLeftHandPosVR(e:)","Returns vector position of player in VR's left hand")
desc("getLeftHandAngVR(e:)","Returns angle of player in VR's left hand")

desc("getRightHandPosVR(e:)","Returns vector position of player in VR's right hand")
desc("getRightHandAngVR(e:)","Returns angle of player in VR's right hand")

--[[
   ______                            __   _                   
  / ____/____   _____ ____   __  __ / /_ (_)____   ___   _____
 / /    / __ \ / ___// __ \ / / / // __// // __ \ / _ \ / ___/
/ /___ / /_/ // /   / /_/ // /_/ // /_ / // / / //  __/(__  ) 
\____/ \____//_/    \____/ \__,_/ \__//_//_/ /_/ \___//____/  
 Gives Access to lua's coroutines to e2, can do everything lua coroutines can do,
    Can't halt lua's coroutines so it is safe.
]]

desc("coroutine(s)","Creates a coroutine object to be run with xco:resume()")
desc("coroutineRunning()","Returns the current e2 coroutine running, if any")
desc("coroutineYield()","Yields the current e2 coroutine running, if any, else errors")
desc("coroutineWait(n)","Yields the current coroutine for n seconds. Will not be able to be resumed until the time passes")

-- Metamethods
desc("status(xco:)","Returns a string of the status of the coroutine, 'dead' for finished, 'suspended' for yielded, and 'running' for obvious reasons")
desc("wait(xco:n)","Makes a coroutine wait for n amount of seconds, in this time, it is yielded and cannot be resumed")
desc("yield(xco:)","Makes the coroutine pause until it is resumed again. It will remember everything that is happening")
desc("reboot(xco:)","Returns a coroutine object that behaves as if the coroutine given was never started or was reset, 'rebooting' it")
desc("resume(xco:)","Resumes a coroutine from where it was last 'yield'ed/'wait'ed. Returns nothing")