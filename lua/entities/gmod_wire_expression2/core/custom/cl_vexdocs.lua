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

desc("rangerOffsetManual(vvr)","Returns a ranger, direct result from the util.TraceLine call with startpos, endpos and filter")
desc("rangerSetFilter(r)","Sets the current filter to be used for rangers. Returns 1 or 0 for success")
desc("canHideChatPly(e)","Returns whether you can hide a chats player, checking their convar")
desc("hideChatPly(en)","Hides the chat of the player given [e] with n as 1 or 0 for whether it should")

--[[
    ____                         ___
   / __ \ __  __ ____   ___     |__ \
  / /_/ // / / // __ \ / _ \    __/ /
 / _, _// /_/ // / / //  __/   / __/
/_/ |_| \__,_//_/ /_/ \___/   /____/

 Allows for calling user-defined functions dynamically at runtime (similar to callable strings),
    with ability to check for success - to know whether an error occurred (like Lua pcall),
        and also allows to pass arguments (via table overload) and retrieve the return value.
]]
desc("try(s)","Tries to run the given string as UDF. Returns a table with the first element being a number 1 or 0 stating whether it ran successfully, and the second element being either the error message or the return value of the given UDF function. Does not throw error if UDF is undefined. Like pcall")
desc("try(st)","Works like the try(s) function, but also allows to pass arguments to the function in the form of table, make sure UDF's first argument is of type table")

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

desc("printGlobal(...)","Prints to everyone's chat, similarly to how chat.addText does, with colors and text that can be organized in any way. First argument can be an array of players, or a single player to send to this player.")
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
   _____        __ ____   ___                                  ___
  / ___/ ___   / // __/  /   | _      __ ____ _ _____ ___     |__ \
  \__ \ / _ \ / // /_   / /| || | /| / // __ `// ___// _ \    __/ /
 ___/ //  __// // __/  / ___ || |/ |/ // /_/ // /   /  __/   / __/
/____/ \___//_//_/    /_/  |_||__/|__/ \__,_//_/    \___/   /____/

 Adds functions similarly to regular-e2's self-aware core.
]]

desc("defined(s)","Returns 0 if the function is not defined or couldn't be found, 1 if the function is an E2 builtin function, 2 if the function is a user-defined function")
desc("getFunctionPath(s)","Returns the path where the e2function was defined (not a user defined function), useful for finding whether something was added with an addon")
desc("getExtensionsInfo()","Returns a table of arrays containing information about E2 extensions (status and description)")
desc("getConstants()","Returns a table containing all registered E2 constants (constant name is used as the table key and constant value [number] as the table value)")
desc("getUserFunctionInfo(n)","Returns a table containing useful information about all user-defined functions. This function can operate differently, the `mode` argument controls how the output table will be structured. Use _UDF_* constant as `mode` argument")
desc("getBuiltinFuncInfo(s)","Returns a table containing information about the builtin (non-UDF) E2 functions. Either use \"*\" as a `funcName` to get infos for all, or specify a function name/signature (e.g. \"selfDestruct\")")
desc("getTypeInfo()","Returns a table containing E2 types information (type ID is used as table key, and type name as the table value)")
desc("deleteUserFunction(s)","Attempts to delete a user-defined function from this E2's context. You must specify a full signature (i.e. \"myFunc(e:av)\").")

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

-- RunOn*

-- Enter
desc("runOnVREnter(n)","Sets the chip to run on players entering VR")
desc("vrPickupClk()","Returns whether the chip was ran by someone entering VR")
desc("vrEnterPly()","Returns the last player to enter VR")

-- Exit
desc("runOnVRExit(n)","Sets the chip to run on players exiting VR")
desc("vrExitClk()","Returns whether the chip was ran by someone leaving VR")
desc("vrExitPly()","Returns the last player to leave VR")

-- Pickup
desc("runOnVRPickup(n)","Sets the chip to run on players picking up a prop in VR")
desc("vrPickupClk()","Returns whether the chip was ran by someone picking up a prop in VR")
desc("vrPickupPly()","Returns the last player to pick up a prop in VR")
desc("vrPickupEnt()","Returns the last prop to be picked up by a player in VR")

-- Drop
desc("runOnVRDrop(n)","Sets the chip to run on players letting go of a prop in VR")
desc("vrDropClk()","Returns whether the chip was ran by someone dropping a prop in VR")
desc("vrDropPly()","Returns the last player to drop a prop VR")
desc("vrDropEnt()","Returns the last prop to be dropped by a player in VR")

--[[
   ______                            __   _
  / ____/____   _____ ____   __  __ / /_ (_)____   ___   _____
 / /    / __ \ / ___// __ \ / / / // __// // __ \ / _ \ / ___/
/ /___ / /_/ // /   / /_/ // /_/ // /_ / // / / //  __/(__  )
\____/ \____//_/    \____/ \__,_/ \__//_//_/ /_/ \___//____/

 Gives access to Lua's coroutines to E2, can do everything Lua coroutines can do,
    Can't halt Lua's coroutines, so it is safe.
]]

desc("coroutine(s)","Creates a coroutine object to be run with xco:resume(). The given UDF's return type must be void and must have no arguments")
desc("coroutine(st)","Creates a coroutine object to be run with xco:resume(t). The given UDF's return type must be void/table and must have a single argument of type table. This overload allows to pass initial data to the UDF by using a table argument")
desc("coroutineRunning()","Returns the current running coroutine for this E2, else nothing")
desc("coroutineYield()","Makes the coroutine pause until it is resumed again. It will remember everything that is happening")
desc("coroutineYield(t)","Makes the coroutine pause until it is resumed again. It will remember everything that is happening. Use this overload if you need to pass data back to the caller (main thread)")
desc("coroutineWait(n)","Makes a coroutine wait for the given amount of seconds, in this time, it is yielded and cannot be resumed")

-- Metamethods
desc("resume(xco:)","Resumes the coroutine (if it is suspended), or starts the coroutine if it hasn't been started yet")
desc("resume(xco:t)","Resumes the coroutine (if it is suspended), or starts the coroutine if it hasn't been started yet. Use this overload if you need to pass data to the coroutine thread using the table argument")
desc("status(xco:)","Returns a string of the status of the coroutine, 'dead' for finished, 'suspended' for yielded/unstarted, and 'running' for obvious reasons")
desc("wait(xco:n)","Makes a coroutine wait for the given amount of seconds, in this time, it is yielded and cannot be resumed")
desc("yield(xco:)","Makes the coroutine pause until it is resumed again. It will remember everything that is happening")
desc("yield(xco:t)","Makes the coroutine pause until it is resumed again. It will remember everything that is happening. Use this overload if you need to pass data back to the caller (main thread)")
desc("reboot(xco:)","Returns a coroutine object that behaves as if the coroutine given was never started or was reset, 'rebooting' it")

--[[
    _________      ______            __   ______
   / ____/__ \    /_  __/___  ____  / /  / ____/___  ________
  / __/  __/ /     / / / __ \/ __ \/ /  / /   / __ \/ ___/ _ \
 / /___ / __/     / / / /_/ / /_/ / /  / /___/ /_/ / /  /  __/
/_____//____/    /_/  \____/\____/_/   \____/\____/_/   \___/

    This is an expression2 core that adds functionality with the e2 controller tool.
        It adds runOn* events for when any player selecting the e2 with the e2 controller clicks or presses reload.
            You can use functions to forcefully set your own selected chip. (Keyword: Your own. This behaves like starfall's setHUDActive.)
]]

-- Selecting
desc("setE2CSelected(n)","Sets your own current e2 controller's selected chip to the chip running the code so you can use runOnE2C events")
desc("runOnE2CSelected(n)","Makes your e2 chip run when someone selects the chip with the e2 controller")
desc("e2CSelectedClk()","Returns the person who just triggered the e2c select event, triggering your chip") -- This is confusing to put in words

-- Left Mouse Button
desc("runOnE2CLeftClick(n)","Makes your e2 chip run when any selected player's e2 controller left clicks")
desc("e2CLeftMouseClk()","Returns 1 or 0 for whether the e2 chip was ran by someone with your chip selected with the e2 controller left clicking")

-- Right Mouse Button
desc("runOnE2CRightClick(n)","Makes your e2 chip run when any selected player's e2 controller right clicks")
desc("e2CRightMouseClk()","Returns 1 or 0 for whether the e2 chip was ran by someone with your chip selected with the e2 controller right clicking")

-- Reload Event
desc("runOnE2CReload(n)","Makes your e2 chip run when any selected player's e2 controller presses their reload key")
desc("e2CReloadClk()","Returns 1 or 0 for whether the e2 chip was ran by someone with your chip selected with the e2 controller right clicking")

-- Information, like the trace info for when any reload/click/selected event is triggered.

desc("lastE2CUser()","Returns the last user to trigger an e2c event. By clicking their mouse or by selecting your e2")
desc("lastE2CRangerInfo()","Returns the ranger information of the last e2c event, so you can get the position of a left click event for example")

--[[
 _       __     __    __  ___      __            _       __
| |     / /__  / /_  /  |/  /___ _/ /____  _____(_)___ _/ /____
| | /| / / _ \/ __ \/ /|_/ / __ `/ __/ _ \/ ___/ / __ `/ / ___/
| |/ |/ /  __/ /_/ / /  / / /_/ / /_/  __/ /  / / /_/ / (__  )
|__/|__/\___/_.___/_/  /_/\__,_/\__/\___/_/  /_/\__,_/_/____/

    Allow players to interact with materials fetched from the web
]]

-- webMaterial*
desc("webMaterialCanCreate()","Returns 1 or 0 for whether you can create a webmaterial, depending on how many you've made and whether you are abiding by the webMaterial creation cooldown")
desc("webMaterial(s)","Creates a webmaterial from an image at a (whitelisted by default) url. You can use these in egpImageBox(es) and in setting the material of a prop to a web image")

desc("webMaterialClear()","Clears all of the web materials you've made as a player, so you can use other ones. (Not just from your chip)")

desc("webMaterialCount()","Returns the number of webmaterials remaining for you to use")
desc("webMaterialMax()","Returns the maximum number of webmaterials you can make")

-- webMaterial metamethods
desc("url(xwm:)","Returns the url of the webmaterial")
desc("creator(xwm:)","Returns the original creator of the webmaterial. Bloat function, might be removed")
desc("cached(xwm:)","Returns whether this is a cached webmaterial (Cached webmaterials can be created infinitely since they are cached on the client). Bloat function, might be removed")
desc("destroyed(xwm:)","Returns whether this webmaterial was destroyed by you calling webmaterial:destroy()")
desc("destroy(xwm:)","Destroys a webmaterial, therefore freeing another slot to make a web material")

-- webMaterial application on props
desc("setMaterial(e:xwm)","Sets the material of a prop to a web material. You need to own the prop")

-- EGP Functions

-- wirelink:egpImageBox(vector2,vector2,string)
desc("egpImageBox(xwl:nxv2xv2s)","Creates an egp box with its material set to a URL, whitelisted by default. If this url has not already been used, will create and use one of your webmaterials, returns this webmaterial")

-- wirelink:egpImageBox(vector2,vector2,webmaterial)
desc("egpImageBox(xwl:nxv2xv2xwm)","Creates an egp box with its material set to a webmaterial, Returns the webmaterial used")
