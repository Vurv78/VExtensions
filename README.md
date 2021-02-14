# VExtensions
[![Release Shield](https://img.shields.io/github/v/release/Vurv78/VExtensions?style=flat-square)](https://github.com/Vurv78/VExtensions/releases/latest)
[![Size Shield](https://img.shields.io/github/repo-size/Vurv78/VExtensions?color=red&style=flat-square)](https://github.com/Vurv78/VExtensions/tree/master/lua)
[![Contributors](https://img.shields.io/github/contributors/Vurv78/VExtensions?style=flat-square)](https://github.com/Vurv78/VExtensions/contributors)
[![Activity](https://img.shields.io/github/commit-activity/m/Vurv78/VExtensions?color=yellow&style=flat-square)](https://github.com/Vurv78/VExtensions/pulse)
[![Featured Server](https://img.shields.io/badge/Featured%20Server-E2%20Beyond%20Infinity-lightgrey?style=flat-square)](steam://connect/69.140.244.127:27015)
[![Wiki](https://img.shields.io/badge/Wiki-here-purple.svg?style=flat-square)](https://github.com/Vurv78/VExtensions/wiki)

A compilation of mini-addons for [Expression2](https://github.com/wiremod/wire) and [StarfallEx](https://github.com/thegrb93/StarfallEx) development as well as a library to assist developers make more of them.

Note that this will be unstable outside of releases.  
This is comparable to addons like [AntCore](https://github.com/tockno/E2-AntCore) or E2Power except, unlike E2Power, not filled with bugs and backdoors.


See and share some more examples here: https://github.com/Vurv78/VExtensions/discussions/categories/show-and-tell

## Modules

### [PrintGlobal - Expression2](https://github.com/Vurv78/VExtensions/wiki/PrintGlobal)
Allows you to print to other players chats with Expression 2, behaves like chat.AddText  
This is similar to the ChatPrint E2 extension, except it is more lenient, supports trailing strings and colors, and is much safer for the server with net size restriction.
<details><summary>PrintGlobal Example Code</summary>

```ruby
@name Chat Colorer
@persist Owner:entity

# This chip hides your chat and prints instead,
# Turning your name blue and text gray.

if(first()){
    runOnChat(1)
    Owner = owner()
}elseif(chatClk(Owner)){
    hideChat(1)
    local Text = lastSaid()
    printGlobal(vec(50,50,200), Owner:name(), vec(255), ": ", vec(220), Text)
}
```
</details><br>

### [CoroutineCore - Expression2](https://github.com/Vurv78/VExtensions/wiki/CoroutineCore)
Allows you to make use of lua's coroutines in expression2, by turning udfs into coroutines, you can use functions like ``coroutineWait(number seconds)`` and ``coroutineYield()``, and retrieve results from ``coroutine:resume()``.
<details><summary>Coroutine Example Code</summary>

```ruby
@name CoroutineCore Example
@persist Co:coroutine
if(first()){
    function thread(){
        while(1){
            coroutineWait(5)
            print("5 seconds have passed")
        }
    }
    Co = coroutine("thread")
    runOnTick(1)
}elseif(tickClk()){
    if(Co:status()!="dead"){
        Co:resume()
    }
}

```
</details><br>


### [WebMaterials - Expression2](https://github.com/Vurv78/VExtensions/wiki/WebMaterials)
Allows you to interact with images pulled off of the web that can be applied as a material to props and egp image boxes.  
Whitelisted by default, see the whitelist @ https://github.com/Vurv78/VExtensions/blob/master/lua/entities/gmod_wire_expression2/core/custom/sv_webmaterials.lua#L25

ConVars:
```
vex_webmaterials_whitelist_sv
vex_webmaterials_max_sv
vex_webmaterials_enabled_cl 1
```

<details><summary>Webmaterials Example Code</summary>

```ruby
@name Webmaterials Prop Example
@persist P:entity M:webmaterial
# Spawns box with some beautiful rust evangelism on it
if(first()){
    P = propSpawn("models/hunter/blocks/cube075x075x075.mdl",entity():pos(),ang(),0)
    M = webMaterial("https://i.imgur.com/lfBBhiE.png")
    interval(100)
}else{
    P:setMaterial( M )
}
```
</details><br>

### [Tool Core - Expression2](https://github.com/Vurv78/VExtensions/wiki/Tool-Core)
Allows you to make use of a custom tool in the wiremod tab, the 'E2 Controller'
By right clicking a chip with the tool, you can take control of it and handle things inside of it with runOn* events when the tool clicks, that receive ranger data of the click.. etc
<details><summary>Tool Core Example Code</summary>

```ruby
@name Hologram Placer Example
@persist HoloInd ColorInd Colors:array SelectedColor:vector
# Example of how to use the E2 Controller from VExtensions.

if(first()){
    runOnE2CLeftClick(1)
    runOnE2CReload(1)
    runOnE2CRightClick(1)

    # These are the colors that will be cycled through when we right click.
    Colors = array(
        vec(255,0,0), # Red
        vec(255,69,0), # Orange
        vec(255,255,0), # Yellow
        vec(0,255,0), # Green
        vec(0,255,200), # Aqua
        vec(0,0,255), # Blue
        vec(180,0,255), # Purple
        vec(255,0,255) # Pink
    )
    ColorInd = 1
    SelectedColor = Colors[1,vector]
}elseif(e2CLeftMouseClk()){
    local RData = lastE2CRangerInfo()
    local Pos = RData:pos()
    local Normal = RData:hitNormal()
    holoCreate(HoloInd,Pos,vec(1,5,5),Normal:toAngle(),SelectedColor)
    HoloInd = (HoloInd+1)%holoMaxAmount()
}elseif(e2CReloadClk()){
    print("Deleted all holos!")
    HoloInd = 0
    holoDeleteAll(1)
}elseif(e2CRightMouseClk()){
    ColorInd = (ColorInd+1)%Colors:count()
    SelectedColor = Colors[ColorInd+1,vector]
    printColor(SelectedColor,"Changed Color!")
}

```
</details><br>

### [VRMod Functions - Expression2](https://github.com/Vurv78/VExtensions/wiki/VRMod)

Allows you to use VRMod's SHARED functions and hooks if vrmod is installed on your server  
StarfallEx already has these builtin now, so they have been removed from VExtensions. See https://github.com/thegrb93/StarfallEx/commit/111d81e8c97f01d3b290909c333b675f901bfa77

This includes functions to get the vr player's headset position, hand position, whether they just dropped a prop and more


### [Selfaware Extended - Expression2](https://github.com/Vurv78/VExtensions/wiki/SelfAware-Extended)

Adds more functions that are more 'selfaware' just like e2's general selfaware.lua core  
Examples are ``defined(string funcname)`` and ``getFunctionPath(string funcname)`` to use the useful #ifdef
<details><summary>Selfaware Extended Example</summary>

```ruby
@name SelfAware Extended Example
# Say a function name in chat, and the chip will print the OPS cost of the function.

if(first()){
    runOnChat(1)
}elseif(chatClk()){
    local YELLOW = vec(255,255,50)
    local WHITE = vec(255)
    local RED = vec(200,70,70)

    local FuncName = lastSaid():explode(" ")[1,string]
    local FuncData = getBuiltinFuncInfo(FuncName)
    if(FuncData){
        local OPSCost = FuncData[3,number]
        printGlobal(RED, "Function", WHITE, ": ", YELLOW, FuncName, RED, "\nCosts", WHITE, ": ", YELLOW, OPSCost, " ops")
    }else{
        printGlobal(RED, "No function data found for: ", YELLOW, FuncName)
    }
}

```
</details><br>

### [RunE2 - Expression2](https://github.com/Vurv78/VExtensions/wiki/RunE2)

Adds functions that allow you to run E2 code, either through udfs and pcall with ``try(s)`` and ``try(st)``, or  
with runString(s) to run actual code inside of a chip.
<details><summary>RunE2 Example Code</summary>

```ruby
@name RunE2 Example
print( runString("error(\"test\")", 1) ) #--> "test"
```
</details><br>

### Other General Functions can be found here:
https://github.com/Vurv78/VExtensions/wiki
