### After 1.1.0

- Remove 'permanent skin' option
- Remove SetSpawnDetails and custom player skin options
- Add /cmyskin to change skin to clan skin
- Add /cweap (missing command) to /cmds
- New TEAM API
- Automatically add the player to the most suitable team (lowest count)
- Remove custom spawns
- Change selection location
- New CLASS API
- Remove hit sound on spawn
- Documentation for special files
- Create class profiles to be used for classes
- Utilize the class API to adapt the script to the new class system
- Use y_groups and y_classes to create a powerful team system
- Adapt the selection progress to the new team/class systems
- Remove obsolete code from older systems
- Remove automatic cash bounties
- Remove moneybag given for cash bounties
- Fix admin privileges
- Reset world time and set default weather to 0
- Reduce stream distance for zone flags to 300 meters
- Improve global messages, fix repeated messages and PMs
- Remove obsolete commands: /everify and /echange
- Fix the private messages logging query
- NEW RANKS API
- Rank reward is $1000 and there's a total of 1000 ranks in an overall

Second Phase

- Remove pilot license
- Remove pyrokit
- Remove old inventory UI
- Create /inv to display player items in dialog
- Fix helmet issues on headshot
- Remove spy kit and toolkit
- Remove minigames
- Remove portable briefcases
- Remove jetpack from items
- Sawn-off skill will now be increased based on sawn-off kills
- Add proper thousand separator for cash values
- Remove unused translation messages
- Remove custom weapons
- Allow player to drop item through /inv
- Use marker mode "PLAYER_MARKERS_MODE_STREAMED"
- Use weapon-config's anti-cbug
- Update admin panel
- Add new commands for CMD_MEMBER: setskin, setinterior, setworld, setcolor
- Improve the TEAM API
- Create a new WEAPONS API
- Improve other modules and systems

Third Phase

- Code fixes and a little housekeeping
- An entire new zones API with the zones component idea taken in mind
- Bug fixes and improvements
- Move Terrorists to Fort Carson
- Holding FIRE will emulate /fire
- Corrected rewards for multiple features (now following the same pattern)
- Use of nuclear requires anthrax ownership plus nukemaster class
- Nuke cooldown is now 600 seconds (i.e. 10 minutes)
- Removed kill-streak bonus (stat is yet counted)
- Trade implementation; players can trade items and weapons
- Economy balance
- Event cash bonus limit to $1-0000, score bonus 1-10
- Use projectile.inc to improve airstrike and nuke
- Create system classes (interior, exterior)
- Add zone peace period
- Change shop actor location
- Requiring anthrax skull for airstrike
- Separate airstrike (and projectile code) from the main file
- Missile launcher implementation