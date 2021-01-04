# VExtensions
![Release Shield](https://img.shields.io/github/v/release/Vurv78/VExtensions?style=flat-square)
![Size Shield](https://img.shields.io/github/repo-size/Vurv78/VExtensions?color=red&style=flat-square)
![Contributors](https://img.shields.io/github/contributors/Vurv78/VExtensions?style=flat-square)
![Activity](https://img.shields.io/github/commit-activity/m/Vurv78/VExtensions?color=yellow&style=flat-square)
[![Featured Server](https://img.shields.io/badge/Featured%20Server-E2%20Beyond%20Infinity-lightgrey?style=flat-square)](steam://connect/69.140.244.127:27015)

A compilation of mini-addons for [Expression2](https://github.com/wiremod/wire) and [StarfallEx](https://github.com/thegrb93/StarfallEx) development as well as a library to assist developers make more of them.

Note that this will be unstable outside of releases.
This is comparable to addons like [AntCore](https://github.com/tockno/E2-AntCore) or E2Power except, unlike E2Power, not filled with bugs and backdoors.

## Additions

### [PrintGlobal - Expression2](https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_printglobal.lua)
Allows you to print to other players chats with Expression 2, behaves like chat.AddText
This is similar to the ChatPrint E2 extension, except it is more lenient, supports trailing strings and colors, and is much safer for the server with net size restriction.

### [CoroutineCore - Expression2](https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_coroutines.lua)
Allows you to make use of lua's coroutines in expression2, by turning udfs into coroutines, you can xco:wait(n) and xco:yield(), and retrieve results from xco:resume().
https://github.com/Vurv78/E2-CoroutineCore

### [WebMaterials - Expression2](https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_webmaterials.lua)
Allows you to interact with images pulled off of the web that can be applied as a material to props and egp image boxes.

Whitelisted by default, see the whitelist @ https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_webmaterials.lua#L25

ConVars:
```
vex_webmaterials_whitelist_sv
vex_webmaterials_max_sv
vex_webmaterials_enabled_cl 1
```

### [Tool Core - Expression2](https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_e2controller.lua)

Allows you to make use of a custom tool in the wiremod tab, the 'E2 Controller'

By right clicking a chip with the tool, you can take control of it and handle things inside of it with runOn* events when the tool clicks, that receive ranger data of the click.. etc

### [VRMod Functions - Expression2](https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_vrmod.lua)

Allows you to use VRMod's SHARED functions and hooks if vrmod is installed on your server
StarfallEx already has these builtin now, so they have been removed from VExtensions. See https://github.com/thegrb93/StarfallEx/commit/111d81e8c97f01d3b290909c333b675f901bfa77

This includes functions to get the vr player's headset position, hand position, whether they just dropped a prop and more


### [Selfaware Extended - Expression2](https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_selfaware2.lua)

Adds more functions that are more 'selfaware' just like e2's general selfaware.lua core
Examples are ``defined(string funcname)`` and ``getFunctionPath(string funcname)`` to use the useful #ifdef


### Other General Functions:

E2:
```
rangerSetFilter(array filter), sets the filter of your e2 rangers.
hideChatPly(entity ply,number yes), hides the chat of a player selected (by default enabled, but warns you when it is hidden and you can disable it with canhidechatply_cl
```

StarfallEx:
```
player:setEyeAngles(angle ang)
```

## More Info
More info can be found at the WIP Wiki here: https://github.com/Vurv78/VExtensions/wiki
