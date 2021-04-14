### Special files

There are special files for specific systems that are used to read data and process them as needed within the script.

### Team Files

Team files can be created with `Team_Create` within the gamemode, the filename specified as a paramter is then loaded from the `scriptfiles` directory, if exists.

You can also add more than one team in the same file, by adding the relevant data as a new line.

The data are stored in one line per team, and you can find what data is stored within `scriptfiles/example_team.txt`. Some data are stored, but are no longer needed within the game script itself, might be needed later, so they're kept for now.

### Classes

Classes are loaded with one function within the gamemode, and are loaded from the `classes.txt` file, this file stores the following data, in-line:
```
team, skin, weapon, X, Y, Z, A, ability_profile, advanced, type
```
`team`: the team that this class is created for
`skin`: the skin that this class will use
`weapon`: the weapon that is assigned to this class
`X, Y, Z, A`: the spawn details/coordinates
`ability_profile`: the ability that is associated with this class (i.e. Spy, Pyroman, etc.)
`advanced`: set whether this class uses the 'advanced' ability profile or not
`type`: Type of the class (0: Interior (base), 1: Exterior (areas))

You can find the ability profiles within the game script at `gamemodes/new/class.inc`

### PUBG

This is fairly simple. A text file is present in `scriptfiles/pubg_loot.txt` and it only stores X, Y, Z, rotation coordinates for objects created when the PUBG event starts, nothing more.

`RankInfo` is the array where those data are permanently stored in, and you can already determine what data are being stored at this point. However, if you don't know, Rank_Coins are the VIP coins to give on ranking up, and Rank_Stars are the amount of stars to show on the UI whenever the player reaches this rank.

### Skin Files

`scriptfiles/clanskins.txt` stores skins that are displayed for clan owners who wish to create clan skins.

### Toys

`scriptfiles/toys.txt` stores the allowed body toys that are allowed for members who wish to attach one to their body.