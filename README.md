# VExtensions
![](https://img.shields.io/badge/epic%3F-yes-blue)

A compilation of mini-addons for Expression2 and StarfallEx development

Note that this will be unstable outside of releases (I KNOW THERE ARENT ANY RIGHT NOW) >:v

This is comparable to addons like Antagonise-Core / AntCore or E2Power, except, not filled with bugs and backdoors (E2Power)

### An overview of what's added:

## PrintGlobal
![](https://img.shields.io/badge/StarfallEx-no-red)
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to print to other players chats with Expression 2, behaves like chat.AddText

## VRMod Functions
![](https://img.shields.io/badge/StarfallEx-yes-green)
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to use VRMod's SHARED functions and hooks if vrmod is installed on your server

This includes functions to get the vr player's headset position, hand position, whether they just dropped a prop and more

## E2 CoroutineCore
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to make use of lua's coroutines in expression2, by turning udfs into coroutines, you can xco:wait(n) and xco:yield(), and retrieve results from xco:resume().
https://github.com/Vurv78/E2-CoroutineCore

## EGP Image Boxes
![](https://img.shields.io/badge/Expression-yes-green)

Allows you to make EGP boxes with their material set to an image hosted on a url.

Whitelisted by default, see the whitelist @ ...
vex_url_whitelist_sv

## E2 Selfaware Extended
![](https://img.shields.io/badge/Expression-yes-green)

Adds more functions that are more 'selfaware' just like e2's general selfaware.lua core

Two currently added are getFunctionPath(s) to get the file path of an e2function, and ifdef(s) to basically be able to use #ifdef, just in runtime.

## Other Misc. Functions:
E2: rangerSetFilter(array filter), sets the filter of your e2 rangers.
E2: hideChatPly(entity ply,number yes), hides the chat of a player selected (by default enabled, but warns you when it is hidden and you can disable it with canhidechatply_cl

SF: player:setEyeAngles(angle ang)
