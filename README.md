# legacy-tdm
# [![LSvT](https://cdn.discordapp.com/icons/436723381182922757/29476e2b2615a330d21ade0b331f5550.webp?size=128)](https://h2omultiplayer.com)

[![sampctl](https://img.shields.io/badge/sampctl-legacy--tdm-2f2f2f.svg?style=for-the-badge)](https://github.com/h2o-deuteron/legacy-tdm)

[![Build Status](https://travis-ci.com/h2o-deuteron/legacy-tdm.svg?token=6B8jM3CjuvitdkpFCPzK&branch=master)](https://travis-ci.com/h2o-deuteron/legacy-tdm)

Legacy SWAT vs Terrorists - TDM Game Project for San Andreas: Multiplayer (>=0.3.7)
Copyright (C) 2020 A.S. "H2O" Ahmed <https://h2omultiplayer.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Installation

```bash
sampctl package install h2o-deuteron/legacy-tdm
sampctl package ensure
mv gamemodes/SvT-conf.example.inc gamemodes/SvT-conf.inc
```

## Configuration

I use old libraries (includes) that are not supported by sampctl, however, they're included within the repository. Old libraries are included within the 'legacy' folder inside the repository's root directory.

You have to rename gamemodes/SvT-conf.example.inc to gamemodes/SvT-conf.inc (and edit it!)


## Usage

This is a gamemode. Using it is fairly simple, you have some files in `scriptfiles`;
- SWAT, Terrorists: These are team files, read with 'CreateTeam' inside the gamemode, and follow the pattern of `example_team.txt`
- Other files in scriptfiles are named according to what they're used for, and mostly read from the gamemode script using functions.

Once you're aware of the external files, you should be aware that there are some arrays that are 'constants' and aren't reading any data from external files, and that means, if you don't find such systems available in an external file, you can work on doing that, I'm not stopping you!

Please note that you have to configure the script according to your needs, such as:
- There are 3 privilege profiles only: CMD_MEMBER, CMD_OPERATOR and CMD_OWNER, each of them is a separate admin level (max. 3).
- There are some static configuration rules, you can edit them under `OnGameModeInit`. They're following the 'svtconf' pattern.

Please make sure you follow the same pattern as the gamemode, and don't commit bad code. You are free to clone this repository and start working on cool things. If you add quality content, we will definitely accept your pull request. We will not accept things that can affect the production server: Things have to remain backwards compatible, or instructions to upgrade should be documented.

Most of the environment-related information can be accessed inside `pawn.json` within the repository's root directory.

## Running

To test, simply run the package:

```bash
sampctl package run
```

However, this may not be enough.

You first need to run:
```bash
sampctl package ensure
```

'ensure', by it's name, ensures that all the dependencies in pawn.json are met, and that you have all the necessary dependencies for running the package - this gamemode.

Once you have all the dependencies, you can run the package using the first command in 'Running' section.

Note: Make sure you edit pawn.json with any necessary changes, such as RCON password. You shouldn't modify server.cfg manually at all.

## Contributors

- SA-MP Team
- H2O
- Y_Less
- Slice
- Pottus
- Crayder
- Southclaws
- SyS
- maddinat0r
- BlueG
- RougeDrifter
- Lorenc_
- d0
- Yashas
- Incognito
- YourShadow
- pawn-lang
- Zeex
- SKAY
- Revan
- spitfire
- RedFusion
- Gammix
- DarkZero
- RyDeR`

Some of the contributors might have not directly contributed to the repository, but their mapping or code snippets were used to build this gamemode, and credits for such tools, libraries or map design go to their respective owners - even those who weren't mentioned here (but are mostly mentioned within the gamemode, where their code is in use).

If your work was used and you weren't mentioned, please open an issue, or simply edit this file and add your name. However, it will only be accepted in case there's proof of ownership of such code snippet.
 
