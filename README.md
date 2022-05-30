# G64
A Garry's Mod addon that uses [libsm64](https://github.com/libsm64/libsm64/) to put a playable Mario in the game.

## Installation
- Download G64 from the workshop. It is this the same addon as this repo, just on the workshop for ease of use.
- Download the latest release from the [releases page](https://github.com/ckosmic/g64/releases/latest). This contains the G64 binary module and libsm64.
- Obtain a copy of the US version of the Super Mario 64 ROM in `.z64` format. No, I will not tell you how or where to get this, nor will I send it to you.
- Now that you have every file you need, extract the release you downloaded from here into your GarrysMod folder: `steamapps\common\GarrysMod`.
- To check if you did this correctly, check that both `GarrysMod\bin\win64\sm64.dll` and `GarrysMod\garrysmod\lua\bin\gmcl_g64_win64.dll` exist.
- Open Gmod and load a map. Open the spawn menu and under Utilities > G64, set the path to the ROM you obtained.

You're now all set! Spawn Mario from Entities > G64 and if you did everything right, Mario will spawn. Enjoy!

## See More
Source to my gmod fork of libsm64 can be found here: https://github.com/ckosmic/libsm64/tree/gmod
Source to the G64 binary module can be found here: https://github.com/ckosmic/libsm64-gmod

## Credits
Many features of this addon (like sound and multiplayer) would not be possible without @dylanpdx's [Retro64Mod fork of libsm64](https://github.com/Retro64Mod/libsm64-retro64/). \
[SysTimeTimers](https://github.com/SnisnotAl/SysTimeTimers) by @SnisnotAI \
[gmod-luabsp](https://github.com/h3xcat/gmod-luabsp/blob/master/luabsp.lua) by @h3xcat