# G64
A Garry's Mod addon that uses [libsm64](https://github.com/libsm64/libsm64/) to put a playable Mario in the game.

## Installation
There are four parts to this addon: the SM64 ROM, the addon itself, libsm64, and the binary module.
- This repo contains the addon files. You can either place these files in a folder called `g64` in your gmod `addons` folder, or just download it from the workshop.
- sm64.dll (libsm64) needs to go in `GarrysMod\bin\win64`.
- gmcl_libsm64-gmod_win64.dll (the binary module) needs to go in `GarrysMod\garrysmod\lua\bin`.
- You must have a US copy of the Super Mario 64 ROM. No, I will not tell you where or how to get it. Rename it to `baserom.us.z64` and it doesn't matter where you put this.  You will have to choose the location for it in the G64 settings in the spawn menu once in-game.

## Credits
Many features of this addon (like sound and multiplayer) would not be possible without @dylanpdx's [Retro64Mod fork of libsm64](https://github.com/Retro64Mod/libsm64-retro64/). \
[SysTimeTimers](https://github.com/SnisnotAl/SysTimeTimers) by @SnisnotAI \
[gmod-luabsp](https://github.com/h3xcat/gmod-luabsp/blob/master/luabsp.lua) by @h3xcat