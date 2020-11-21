# VExtensions
![](https://img.shields.io/badge/epic%3F-yes-blue)

A compilation of mini-addons for Expression2 and StarfallEx development

Note that this will be unstable outside of releases

This is comparable to addons like Antagonise-Core / AntCore or E2Power, except, not filled with bugs and backdoors (E2Power)

### An overview of what's added:

## PrintGlobal
![](https://img.shields.io/badge/StarfallEx-no-red)
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to print to other players chats with Expression 2, behaves like chat.AddText

## CoroutineCore
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to make use of lua's coroutines in expression2, by turning udfs into coroutines, you can xco:wait(n) and xco:yield(), and retrieve results from xco:resume().
https://github.com/Vurv78/E2-CoroutineCore

## WebMaterials
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to interact with images pulled off of the web that can be applied as a material to props and egp image boxes.

Whitelisted by default, see the whitelist @ https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_webmaterials.lua#L25

ConVars:
vex_webmaterials_whitelist_sv

vex_webmaterials_max_sv

vex_webmaterials_enabled_cl 1 .. etc

## Tool Core
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to make use of a custom tool in the wiremod tab, the 'E2 Controller'

By right clicking a chip with the tool, you can take control of it and handle things inside of it with runOn* events when the tool clicks, that receive ranger data of the click.. etc

## VRMod Functions
![](https://img.shields.io/badge/StarfallEx-yes-green)
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to use VRMod's SHARED functions and hooks if vrmod is installed on your server

This includes functions to get the vr player's headset position, hand position, whether they just dropped a prop and more


## Selfaware Extended
![](https://img.shields.io/badge/Expression-yes-green)

Adds more functions that are more 'selfaware' just like e2's general selfaware.lua core

Two currently added are getFunctionPath(s) to get the file path of an e2function, and ifdef(s) to basically be able to use #ifdef, just in runtime.

## Other Misc. Functions:
E2: rangerSetFilter(array filter), sets the filter of your e2 rangers.
E2: hideChatPly(entity ply,number yes), hides the chat of a player selected (by default enabled, but warns you when it is hidden and you can disable it with canhidechatply_cl

SF: player:setEyeAngles(angle ang)
