# VExtensions
![](https://img.shields.io/badge/epic%3F-yes-blue)

A compilation of mini-addons for Expression2 and StarfallEx development
Note that this will be unstable outside of releases (I KNOW THERE ARENT ANY RIGHT NOW) >:v

An overview of what's added for e2:

## PrintGlobal
![](https://img.shields.io/badge/StarfallEx-no-red)
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to print to other players chats with Expression 2 and StarfallEx, behaves like chat.AddText
(Repo deleted, so there wouldn't be complications with parity)

## CoroutineCore
![](https://img.shields.io/badge/StarfallEx-no-red)
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to make use of lua's coroutines in expression2, by turning udfs into coroutines, you can xco:wait(n) and xco:yield(), and retrieve results from xco:resume().
https://github.com/Vurv78/E2-CoroutineCore

## VRMod Functions
![](https://img.shields.io/badge/StarfallEx-yes-green)
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to use VRMod's SHARED functions if VRMod is installed on your server.
This gives you access to anyone in VR's head placement, angle and hand placement, etc.

## Selfaware 2
![](https://img.shields.io/badge/StarfallEx-no-red)
![](https://img.shields.io/badge/Expression-yes-green)

Adds more functions that are more 'selfaware' just like e2's general selfaware.lua core
Two currently added are getFunctionPath(s) to get the file path of an e2function, and ifdef(s) to basically be able to use #ifdef, just in runtime.

## Other Misc. Functions:
rangerSetFilter(r), sets the filter of your e2 rangers.
hideChatPly(e,n), hides the chat of a player selected (by default enabled, but warns you when it is hidden and you can disable it with canhidechatply_cl

No docs for starfallex (on here) atm, check the sf helper

Adds vrmod functions, setEyeAngles
