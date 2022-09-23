# G64
A Garry's Mod addon that uses [libsm64](https://github.com/libsm64/libsm64/) to put a playable Mario in the game. \
Note: This requires Windows and 64-bit Garry's Mod.

## Installation
- Download G64 [from the workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2814638140). Alternatively, clone this repo in your `GarrysMod\garrysmod\addons` folder.
- Download and run the [G64 Installer](https://github.com/ckosmic/G64Installer/releases/latest) to install the files needed for the addon to interact with libsm64.
- Obtain a copy of the US version of the Super Mario 64 ROM (MD5: `20b854b239203baf6c961b850a4a51a2`, SHA1: `9bef1128717f958171a4afac3ed78ee2bb4e86ce`). No, I will not tell you how or where to get this, nor will I send it to you.
- Make sure you're on the 64-bit version of the game **OR THIS WILL NOT WORK AT ALL.** To do this, right click on Garry's Mod in your Steam library and click `Properties...`.  Then click `BETAS` and select `x86-64 - Chromium + 64-bit binaries` from the dropdown.
- Now that Gmod is in 64-bit mode, open it and load a map. Open the spawn menu and under Utilities > G64 > Settings, set the path to the ROM you obtained.

You're now all set! Spawn Mario from the G64 tab and if you did everything right, Mario will spawn. Enjoy!

## See More
Source to my gmod fork of libsm64 can be found here: https://github.com/ckosmic/libsm64/tree/gmod \
Source to the G64 binary module can be found here: https://github.com/ckosmic/libsm64-gmod \
Source to the G64 installer can be found here: https://github.com/ckosmic/G64Installer \
Source to the G64 auto updater module can be found here: https://github.com/ckosmic/g64_autoupdater

## Credits
Many features of this addon (like sound and multiplayer) would not be possible without @dylanpdx's [Retro64Mod fork of libsm64](https://github.com/Retro64Mod/libsm64-retro64/). \
[SysTimeTimers](https://github.com/SnisnotAl/SysTimeTimers) by @SnisnotAI \
[gmod-luabsp](https://github.com/h3xcat/gmod-luabsp/blob/master/luabsp.lua) by @h3xcat