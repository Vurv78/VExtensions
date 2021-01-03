# VExtensions
![Release Shield](https://img.shields.io/github/v/release/Vurv78/VExtensions?style=flat-square)
![Size Shield](https://img.shields.io/github/repo-size/Vurv78/VExtensions?color=red&style=flat-square)
![Contributors](https://img.shields.io/github/contributors/Vurv78/VExtensions?style=flat-square)
![Activity](https://img.shields.io/github/commit-activity/m/Vurv78/VExtensions?color=yellow&style=flat-square)
[![Featured Server](https://img.shields.io/badge/Featured%20Server-E2%20Beyond%20Infinity-lightgrey?style=flat-square)](steam://connect/69.140.244.127:27015)

A compilation of mini-addons for Expression2 and StarfallEx development

Note that this will be unstable outside of releases

This is comparable to addons like Antagonise-Core / AntCore or E2Power, except, not filled with bugs and backdoors (E2Power)

### An overview of what's added:

## PrintGlobal - Expression2
Allows you to print to other players chats with Expression 2, behaves like chat.AddText
This is similar to the ChatPrint E2 extension, except it is more lenient, supports trailing strings and colors, and is much safer for the server with net size restriction.

## CoroutineCore - Expression2
Allows you to make use of lua's coroutines in expression2, by turning udfs into coroutines, you can xco:wait(n) and xco:yield(), and retrieve results from xco:resume().
https://github.com/Vurv78/E2-CoroutineCore

## WebMaterials - Expression2
Allows you to interact with images pulled off of the web that can be applied as a material to props and egp image boxes.

Whitelisted by default, see the whitelist @ https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_webmaterials.lua#L25

ConVars:
```
vex_webmaterials_whitelist_sv
vex_webmaterials_max_sv
vex_webmaterials_enabled_cl 1
```

## Tool Core - Expression2

Allows you to make use of a custom tool in the wiremod tab, the 'E2 Controller'

By right clicking a chip with the tool, you can take control of it and handle things inside of it with runOn* events when the tool clicks, that receive ranger data of the click.. etc

## VRMod Functions - Expression2

Allows you to use VRMod's SHARED functions and hooks if vrmod is installed on your server
StarfallEx already has these builtin now, so they have been removed from VExtensions. See https://github.com/thegrb93/StarfallEx/commit/111d81e8c97f01d3b290909c333b675f901bfa77

This includes functions to get the vr player's headset position, hand position, whether they just dropped a prop and more


## Selfaware Extended - Expression2

Adds more functions that are more 'selfaware' just like e2's general selfaware.lua core

Two currently added are getFunctionPath(s) to get the file path of an e2function, and ifdef(s) to basically be able to use #ifdef, just in runtime.

## Other General Functions:

E2:
```
rangerSetFilter(array filter), sets the filter of your e2 rangers.
hideChatPly(entity ply,number yes), hides the chat of a player selected (by default enabled, but warns you when it is hidden and you can disable it with canhidechatply_cl
```

SF:
```
player:setEyeAngles(angle ang)
```
