# new-ideas

This topic will include documentation for future plans and ideas that we have in mind for the future releases:


### Requirements

[DONE] - Remove class system and all the class abilities
[DONE] - Remove any special ability granted by score or ranking up
[DONE] - Remove items that provide any special ability
[DONE] - Prepare the team system to work with those ideas


### Team System (FileSystem)

We have a new approach, that is called 'free branching', or in detail:
[DONE] - A team will include two branches, that is: Interior (Base) and Exterior (Zone) where players will be called centeral units, and exterior units.
[DONE] - Bases and zones will include a separate series of classes (skins), where each class has one special ability and one weapon
[DONE] - Players will be told what classes do, and what they get from it.
[DONE] - Interior units will spawn at the main base
- Exterior units will spawn at areas close to the base
[DONE] - Interior units will use the briefcase at the team base normally
- Exterior units will display the shop before spawn, as a compensation

Radio Antenna:
[ALREADY-DONE] - Radio antenna will allow team members to use /tr (team chat)
[SKIPPED] - Radio antenna will allow team members to view enemies on the map
[SKIPPED] - Radio antenna will allow team members to view each other on the map
[SKIPPED] - Abilities are lost on destruction, recovery is automatic and takes 3 minutes

Prototype:
[SKIPPED] - Prototype will exist at hidden areas, and completely random, but will belong to the team yet
[DONE] - Prototypes will not cause loss for the team, but someone who manages to kill the enemy and take it back to the base will win
[SKIPPED] - So this is more of 'capture the flag', or 'return your flag to your base'.

Team Shop:
[SKIPPED] - Interior units only can use this
[SKIPPED] - Exterior units will be compensated by the shop-before spawn
[DONE] - Team shop will include permanent weapons, and not temporary (until ammo is out)
[DONE] - Items will be the same as stated above


### Weapon System

[DONE] - All weapons will cost a cash value: (weapon damage) * (weapon ammo/quantity)
    Example:
        IF: Weapon X inflects 10.0 damage per hit and the player wants to acquire 100 of it
        THEN: Weapon X will cost (10.0) * (100), sums up to: $1000 (in game currency)
[DONE] - Player will be able to specify the quantity they need for the said weapon or melee


### Achievements (MySQL based system)

To be added


### Things to remove

[DONE] - Automatic bounties
[DONE] - Portable briefcase
[DONE] - Score or cash loss on failure to defend/protect anything
[DONE] - Cash loss will be present on death only
[DONE] - Custom weapons
[DONE] - Last bed standing event and player-managed events (derby, etc.)
[DONE] - Minigames and minigame maps/abilities
[DONE] - /sendmoney command


### Economy

Currency will work as follows:
[DONE] - For individual tasks: 1 score and $1000
[SKIPPED] - For group tasks, or anything that benefits the team as a whole: 1 score and $1000 for the whole team
[DONE-EXCEPT-FOR-DEATH-STATE] - For any loss, we will not charge the player for it and instead, the player can try again without worrying

Trading:
[DONE] - Players will be able to trade a permanent weapon or a permanent item purchased from the shop for how much $ they like.


### KDR

[ALREADY] - K/D will be affected only by kills in the battlefield


### Rank System

[DONE] - There'll be a maximum of 1000 ranks a player can reach
[DONE] - Each rank will be 100 score higher than the other
[DONE] - Player will receive only $1000 per rank up
[DONE] - Higher ranks will be allowing the player to perform bigger tasks


### Things to look after

[DONE] - Take care of score farming for zones
[DONE] - Fix confusing chat messages
[NOT-NEEDED] - Display /top in a dialog instead
[NO-FIX-YET] - Submarines still throw players in the air
[DONE] - Time should stick to the morning and allow players to set it manually
- Do not 'randomize' VIP abilities
[DONE] - Fix skin bugs and white color that happens out of nowhere
[DONE] - Lower the requirements (and mostly remove them) to do stuff
[DONE] - Remove /everify from /cmds (obsolete)
[CANT-REPRODUCE] - Fix messed up K/D calculation for new players
[DONE] - Reduce the radius for mapicons (i.e. zone flags)
[DONE] - Class abilities used stat to be according to the new system
[CANT-REPRODUCE] - Improve matchfacts for dogfight

### After v1.1.0

- Add timecycle
- Add missing classes and their profiles