/*
    Legacy SWAT vs Terrorists - TDM Game Project for San Andreas: Multiplayer (0.3.7>=)
    Copyright (C) 2020 A.S. "H2O" Ahmed <https://www.h2omultiplayer.com>

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
*/

#if !defined _LEGACY_TDM
	#define _LEGACY_TDM
#else
	#endinput
#endif

#include <a_samp>

//Localization
#include "SvT-en-translation.inc"
#include "../legacy_tdm_version.inc"
#include "SvT-conf.inc"

#if !defined _SVT_CONF
	#error "Couldn't find SvT-conf.inc in the gamemode directory, please rename SvT-conf.example.inc to SvT-conf.inc"
#endif

//Debug
#include <crashdetect> //Zeex

//Password encryption
#include <samp_bcrypt>

//MySQL Plugin
#include <a_mysql> //BlueG & maddinat0r
new MySQL: Database;

//Miscellaneous
#include <sscanf2> //Y_Less
#include <streamer> //Incognito

/////////////////////////////////////////////////////////

//YSI
#define YSI_NO_MODE_CACHE
#define YSI_NO_OPTIMISATION_MESSAGE
//Useless //#define MODE_NAME "svtsamp"
#define YSI_NO_HEAP_MALLOC
//#define CGEN_MEMORY 22512
#include <YSI_Data\y_iterate> //Y_Less
#define X11_WINE 0x722F37FF
#define WINE "{722F37}"
#define X11_SERV_INFO 0x2d6da4FF
#define X11_SERV_WARN 0xa46d2dFF
#define X11_SERV_ERR 0xa4312dFF
#define X11_SERV_OK 0x2da499FF
#define X11_SERV_SUCCESS 0x2da453FF
#include <YSI_Players\y_groups> //Y_Less
#include <YSI_Visual\y_classes> //Y_Less
#include <YSI_Server\y_colors> //Y_Less
#include <YSI_Visual\y_dialog> //Y_Less
#include <YSI_Data\y_playerset> //Y_Less
#include <YSI_Coding\y_timers> //Y_Less
#include <YSI_Coding\y_stringhash> //Y_Less

//First Tier Anti Cheat
#include <antilag> //Pottus & Southclaws
#include <antispoof> //Pottus & Southclaws
#include <OPBA> //RogueDrifter
#include <rAsc> //RogueDrifter

//Anti Aimbot
#define BUSTAIM_MAX_PL_PERCENTAGE           30.0
#define BUSTAIM_PROAIM_TELEPORT_PROBES      1
#define BUSTAIM_RANDOM_AIM_PROBES           3
#define BUSTAIM_MAX_CONTINOUS_SHOTS         10
#define BUSTAIM_MAX_PING                    450
#define BUSTAIM_SKIP_WEAPON_IDS             38
#include <BustAim> //Yashas

//Damage System
#include <weapon-config> //Slice

//Anti cheat
#include <anti-weapon> //Lorenc_
#include <anti-fly> //Lorenc_

//urShadow
#include <Pawn.CMD> //urShadow
#include <Pawn.Regex> //urShadow
#include <Pawn.RakNet> //urShadow

//Collisions
#include <colandreas> //Pottus & Crayder

//UI
#include <mSelection> //d0

//Gangzones
#include <gz_shapes> // R2D

//Progress bars
#include <progress2> //Southclaws

//Timestamp
#include <timestamp> //Crayder

//Projectile
#include <projectile> //Gammix and PeppeAC

//-----------

#define GetDistanceBetweenPoints3D(%1,%2,%3,%4,%5,%6)			VectorSize((%1)-(%4),(%2)-(%5),(%3)-(%6))
#define SendGameMessage(%0,%1,%2) PSF:_SendGameMessage(%0,%1,%2)

//Check whether a key was pressed
#define PRESSED(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))

//Check whether a player is yet holding the key
#define HOLDING(%0) \
	((newkeys & (%0)) == (%0))

//Check if the player released the key
#define RELEASED(%0) \
	(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))

//Define gpci function
#if !defined gpci
	native gpci(playerid, serial[], len);
#endif

//Pagination definition
#define PAGES(%0,%1) (((%0) - 1) / (%1) + 1)

//Check if a message is null
#if !defined isnull
	#define isnull(%1) \
				((!(%1[0])) || (((%1[0]) == '\1') && (!(%1[1]))))
#endif

//Check if a vehicle is valid (add definition)
#if !defined IsValidVehicle
	native IsValidVehicle(vehicleid);
#endif

//Get vehicle boot
#define GetVehicleBoot(%0,%1,%2,%3) \
	(GetVehicleOffset((%0), VEHICLE_OFFSET_BOOT, %1, %2, %3))

//Lighten colors, reduce opcaity
#define ALPHA(%2,%1) ((%2 & ~0xFF) | (clamp(%1,0x00,0xFF)))

//Convert uppercase chars to lowercase ones
#define LOWERCASE(%1) \
		for (new strpos; strpos < strlen(%1); strpos ++) \
			if ( %1[strpos]> 64 && %1[strpos] < 91 ) %1[strpos] += 32


//Define command types
enum (<<=1) {
	CMD_MEMBER,
	CMD_OPERATOR,
	CMD_OWNER
}

#define ComparePrivileges(%0,%1) \
								(pPrivileges[%0] & %1)

#define CheckPrivileges(%0,%1) \
								(pPrivileges[%0] > pPrivileges[%1])

#define ForwardPlayerMessageToAll(%0,%1) \
								( \
									SendGameMessage(@pVerified,-1,FORWARDED_MESSAGE_ALL,GetPlayerColor(%0) >>> 8,PlayerInfo[%0][PlayerName],%0,%1) \
									&& LogPublicMessage(%0,%1,gettime()) \
								)

#define ForwardPlayerMessageToTarget(%0,%1,%2) \
								( \
									SendGameMessage(%1,-1,FORWARDED_MESSAGE,GetPlayerColor(%0) >>> 8,PlayerInfo[%0][PlayerName],%0,%2) \
									&& SendGameMessage(%0,-1,FORWARDED_MESSAGE_TO,GetPlayerColor(%1) >>> 8,PlayerInfo[%1][PlayerName],%1,%2) \
									&& LogPrivateMessage(%0,%1,%2,gettime()) \
								)

//Success Bonus
#define SuccessAlert(%0) \
								( \
									GivePlayerCash(%0, 1000) \
									&& GivePlayerScore(%0, 1) \
									&& GameTextForPlayer(%0, "~g~MISSION PASSED~n~~w~+1 SCORE & $1,000", 3000, 3) \
									&& PlaySuccessSound(%0) \
								)

//Limits

#define MAX_TEAMS             		(5) //Maximum no. of teams to load
#define MAX_ZONES					(1000) //Max no. of zones to load
#define MIN_ZONE_VALUE				(1000000) //Minimum cash value needed to own a zone
#define MAX_TRANSACTIONS			(100000) //Maximum transactions to accept or load
#define MIN_TRANSC_VALUE			(10000) //Minimum value a player can invest in a zone
#define MAX_TRANSC_VALUE			(100000) //Maximum value a player can invest in a zone at a time
#define ZONE_VALUE_PERIOD			(86400 * 7) //Time before the cash value is no longer 'considered', 7days
#define ZONE_PEACE_PERIOD			(900) //15 minutes peace period between each zone investment
#define MAX_CHECKPOINTS             (150) //Maximum no. of race checkpoints (may be used for spawn points too)
#define MAX_SLOTS 	      		    (500) //Maximum no. of dynamic slots for various server features
#define MAX_ITEMS    		        (6) //Maximum no. of items a player can have
#define MAX_REPORTS 			    (10) //Maximum reports to display in /reports
#define MAX_MESSAGES                (10) //Spammy messages limit
#define SPAM_TIMELIMIT              (4) //Spam cooldown time limit in seconds
#define MAX_MENU_TEXTDRAWS 		    (100) //Inventory maximum no. of textdraws
#define MAX_MENU_PLAYER_TEXTDRAWS   (100) //Inventory maximum no. of per player textdraws
#define MAX_RIGHT_MENU_COLUMNS 	    (5) //Inventory right menu colums limit
#define MAX_RIGHT_MENU_ROWS 	    (3) //Inventory right menu rows limit
#define MAX_LEFT_MENU_ROWS 		    (7) //Invetory left menu limit
#define MAX_ITEM_NAME 			    (64) //Maximum length of item names
#define MAX_FORBIDS 				(100) //Maximum no. of forbidden words and names
#define MAX_ROPES 					(50) //Rope rappelling maximum no. of ropes
#define MAX_CLANS 					(1000) //Maximum no. of clans that can be loaded at one time
//#define MAX_ACMDS 					(216) //Maximum no. of admin commands that can be loaded at one time
#define MAX_IP_LEN 					(25) //Default text length for IPs
#define MAX_PASS_LEN 				(65) //Default text length for passwords
#define SMALL_STRING_LEN 			(128) //Default text length for small strings
#define MEDIUM_STRING_LEN 			(256) //Default text length for medium strings
#define LARGE_STRING_LEN 			(1024) //Default text length for large strings
#define MAX_KEY_LENGTH 				(10) //Default text length for keys
#define MAX_GPCI_LEN				(41)
#define BCRYPT_COST 				(12) //Bcrypt work factor
#define MAX_ADMIN_RANKS				(3)
#define MAX_RACES					(100)
#define MAX_GT_COLORS 				(10) //If you want to add ~h~ for example - GT is gametext
#define MAX_RANKS					(1000)
#define MAX_SUB_CLASSES				(100)
#define MAX_WEAPONS     			(47)
#define MAX_TRADES					(10000)
#define MIN_TRADE_PRICE				(1)
#define MAX_TRADE_PRICE				(100000)
#define MAX_SM						(5000) //Max send money value at a time
#define MAX_AIRSTRIKES				(100)
#define MAX_PPROJECTILES			(100)
#define EXTRAID_TYPE_PLAYER			(0)

//Trade definitions

#define ITEM_TYPE_WEAP (0)
#define ITEM_TYPE_ITEM (1)

//Class definitions

enum {
	GROUNDUNIT,
	SNIPER,
	MECHANIC,
	JETTROOPER,
	MEDIC,
	SPY,
	DEMOLISHER,
	SCOUT,
	SUICIDER,
	PILOT,
	RECON,
	CUSTODIAN,
	KAMIKAZE,
	SUPPORT,
	NUKEMASTER
};

//Useful macros
#define p_ClassAbilities(%0,%1) \
								(Class_GetAbilities(Class_GetPlayerClass(%0)) == %1)

#define p_ClassAdvanced(%0) \
								(Class_IsAdvanced(Class_GetPlayerClass(%0)))

#define PlaySuccessSound(%0) \
								PlayerPlaySound(%0, RPSS(), 0.0, 0.0, 0.0)

RPSS() {
	new i = random(3);
	return (i == 0 ? 5462 : (i == 1 ? 5448 : (i == 2 ? 5449 : 5450)));
}

#define PlayReadySound(%0) \
								PlayerPlaySound(%0, 1056, 0.0, 0.0, 0.0)

#define PlayGoSound(%0) \
								PlayerPlaySound(%0, 1057, 0.0, 0.0, 0.0)

//Iterator
new Iterator: classes_loaded<MAX_SUB_CLASSES>;

//Inventory definitions

#define HELMET    		 			(0)
#define MASK      				 	(1)
#define MK        	 	 			(2)
#define AK        	     			(3)
#define LANDMINES        			(4)
#define DYNAMITE         			(5)

//System color definitions

#define COLOR_TOMATO 				0xFF6347FF
#define COL_TOMATO 		 			"{FF6347}"

#define COLOR_DEFAULT 	 			0xA9C4E4FF
#define COL_DEFAULT 	 			"{A9C4E4}"

//Admin spectator mode types
#define ADMIN_SPEC_TYPE_NONE      	(0)
#define ADMIN_SPEC_TYPE_PLAYER    	(1)
#define ADMIN_SPEC_TYPE_VEHICLE   	(2)

//Event spawn types
#define EVENT_SPAWN_INVALID    		(-1)
#define EVENT_SPAWN_RANDOM          (0)
#define EVENT_SPAWN_ADMIN           (1)

//Quicksort Pairs
#define PAIR_FIST 					(0)
#define PAIR_SECOND 				(1)

//Virtual Worlds
#define BF_WORLD					(0)
#define LONE_WORLD					(100)
#define DM_WORLD					(201)
#define CW_WORLD					(202)
#define DUEL_WORLD					(203)
#define JAIL_WORLD					(420)
#define PUBG_WORLD					(666)
#define SPECIAL_WORLD				(999)
#define RACE_ALT_WORLD				(2000) //formula=2000+raceid

//Worlds

#define MODE_BATTLEFIELD 			(0)
#define MODE_DEATHMATCH 			(1)
#define MODE_DUEL 					(2)
#define MODE_DOGFIGHT 				(3)
#define MODE_EVENT 					(4)
#define MODE_PUBG 					(5)
#define MODE_DISABLED 				(6)
#define MODE_CLANWAR 				(7)
#define MODE_RACE	 				(8)

//ClanWar

#define CW_8v8 						(1) //Round 16
#define CW_4v4 						(2) //Quarterfinals
#define CW_2v2 						(3) //Semifinals
#define CW_1v1 						(4) //Final Round

//Include the map modules

#include "maps/server-maps.pwn" //Create server map in a separate module
#include "maps/bunker-map.pwn" //Create bunker map in a separate module

//Config

enum e_svtconf {
	kick_bad_nicknames,
	anti_spam,
	anti_swear,
	anti_caps,
	server_open,
	disable_chat,
	anti_adv,
	max_ping,
	max_ping_kick,
	max_warns,
	max_duel_bets,
	safe_restart
};
new svtconf[e_svtconf]; //Doesn't work? Now it does

//Declarations

//Return Admin Rank
new _staff_roles[MAX_ADMIN_RANKS][25] = {
	"Project Member", "Operator", "Server Owner"
};

//Forbiddens System

new ForbiddenWords[MAX_FORBIDS][25];
new ForbiddenNames[MAX_FORBIDS][25];

//General textdraws

new Text: Stats_TD[6];
new Text: CarInfoTD[4];
new Text: Site_TD;
new Text: SvTTD[3];
new Text: WarTD;
new Text: DMBox;
new Text: DMText;
new Text: DMText2[4];
new Text: CAdv_TD[2];
new Text: WarStatusTD[7]; //War Activity
new WarStatusStr[8][128];
new Text: BoxTD[2];

//Spec UI
new Text: aSpecTD[12];

//PUBG UI

new Text: PUBGAreaTD;
new Text: PUBGKillsTD;
new Text: PUBGAliveTD;
new Text: PUBGKillTD;
new Text: PUBGWinnerTD[5];

//Clan War
new Text:CWTD_0;
new Text:CWTD_1;
new Text:CWTD_2;
new Text:CWTD_3;
new Text:clanwar_0;
new Text:clanwar_1;
new Text:clanwar_2;
new Text:standing[8];

//stats
new Text: StatsDotTD;

//Team System
new Iterator: teams_loaded<MAX_TEAMS>;

//Selection
new Text:selectdraw_0;
new Text:selectdraw_1;

//Create the team war array
enum WarData {
	War_Team1,
	War_Team2,
	War_Time,
	War_Started,

	Team1_Score,
	Team2_Score,

	War_Score,
	War_Target
};

new WarInfo[WarData];

new const WarTargets[][100] = {
	{"Kill most enemies"},
	{"Deagle kills only"},
	{"Headshot kills only"},
	{"Far kills only (>=100 meters)"},
	{"Close kills only (<20 meters)"}
};

//Team war time counter
new war_time = 0;

//===========================
//Shopping
//===========================

enum ShopData {
	Float: Shop_Pos[3],
	Float: Shop_aPos[4],
	Zone_Id,
	Shop_Id,
	Text3D: Shop_Label,
	Shop_Area
};

new ShopInfo[MAX_TEAMS][ShopData];

//===========================
//Antenna
//===========================

enum AntennaData {
	Float: Antenna_Pos[4],
	Antenna_Id,
	Antenna_Exists,
	Antenna_Hits,
	Antenna_Kill_Time,
	Text3D: Antenna_Label
};

new AntennaInfo[MAX_TEAMS][AntennaData];

//===========================
//Prototype
//===========================

enum PrototypeData {
	Float: Prototype_Pos[4],
	Prototype_Attacker,
	Prototype_Id,
	Text3D: Prototype_Text,
	Prototype_Cooldown
};

new PrototypeInfo[MAX_TEAMS][PrototypeData];

//---------------------------------------------------------
//Max Velocities (Constants)

new const s_TopSpeed[212] = {
    157, 147, 186, 110, 133, 164, 110, 148, 100, 158, 129, 221, 168, 110, 105, 192, 154, 270,
    115, 149, 145, 154, 140, 99, 135, 270, 173, 165, 157, 201, 190, 130, 94, 110, 167, 0, 149,
    158, 142, 168, 136, 145, 139, 126, 110, 164, 270, 270, 111, 0, 0, 193, 270, 60, 135, 157,
    106, 95, 157, 136, 270, 160, 111, 142, 145, 145, 147, 140, 144, 270, 157, 110, 190, 190,
    149, 173, 270, 186, 117, 140, 184, 73, 156, 122, 190, 99, 64, 270, 270, 139, 157, 149, 140,
    270, 214, 176, 162, 270, 108, 123, 140, 145, 216, 216, 173, 140, 179, 166, 108, 79, 101, 270,
    270, 270, 120, 142, 157, 157, 164, 270, 270, 160, 176, 151, 130, 160, 158, 149, 176, 149, 60,
    70, 110, 167, 168, 158, 173, 0, 0, 270, 149, 203, 164, 151, 150, 147, 149, 142, 270, 153, 145,
    157, 121, 270, 144, 158, 113, 113, 156, 178, 169, 154, 178, 270, 145, 165, 160, 173, 146, 0, 0,
    93, 60, 110, 60, 158, 158, 270, 130, 158, 153, 151, 136, 85, 0, 153, 142, 165, 108, 162, 0, 0,
    270, 270, 130, 190, 175, 175, 175, 158, 151, 110, 169, 171, 148, 152, 0, 0, 0, 108, 0, 0
};

//-------------
//Loot system

new gLootObj[MAX_SLOTS];
new gLootItem[MAX_SLOTS];
new gLootAmt[MAX_SLOTS];
new gLootExists[MAX_SLOTS];
new gLootPickable[MAX_SLOTS];
new gLootTimer[MAX_SLOTS];
new gLootArea[MAX_SLOTS];
new gLootPUBG[MAX_SLOTS];

//-----------------
//PUBG Event

new PUBGCircle, bool: PUBGOpened, bool: PUBGStarted, PUBGTimer, PUBGKills, PUBGKillTick;
new Float:Multiplier, Float: PUBGRadius;
new PUBGVehicles[5];
new Float: PUBGMeters;

new Float: PUBGArray[MAX_OBJECTS][4];
new _loaded_pubg_items = 0;

//-------------------
//Vehicles

new VehicleNames[212][] =
{
	"Landstalker", "Bravura", "Buffalo", "Linerunner", "Pereniel", "Sentinel", "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
	"Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Mr Whoopee", "BF Injection",
	"Hunter", "Premier", "Enforcer", "Securicar", "Banshee", "Elite MG", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie",
	"Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder",
	"Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair", "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider",
	"Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR3 50", "Walton", "Regina",
	"Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "new stocks Chopper", "Rancher", "SWAT Rancher", "Virgo", "Greenwood",
	"Jetmax", "Hotring", "Sandking", "Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin", "Hotring Racer A", "Hotring Racer B",
	"Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropdust", "Stunt", "Tanker", "RoadTrain",
	"Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune", "Cadrona", "SWAT Truck",
	"Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent", "Bullet", "Clover",
	"Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster A",
	"Monster B", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito", "Freight", "Trailer",
	"Kart", "Mower", "Duneride", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "new stocksvan", "Tug", "Trailer A", "Emperor",
	"Wayfarer", "Euros", "Hotdog", "Club", "Trailer B", "Trailer C", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car (LSPD)", "Police Car (SFPD)",
	"Police Car (LVPD)", "Police Ranger", "Picador", "SWAT. Van", "Alpha", "Phoenix", "Glendale", "Sadler", "Luggage Trailer A", "Luggage Trailer B",
	"Stair Trailer", "Boxville", "Farm Plow", "Utility Trailer"
};

//Legal modifications

//Modifications
new legalmods[48][22] = {
		{400, 1024,1021,1020,1019,1018,1013,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{401, 1145,1144,1143,1142,1020,1019,1017,1013,1007,1006,1005,1004,1003,1001,0000,0000,0000,0000},
		{404, 1021,1020,1019,1017,1016,1013,1007,1002,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{405, 1023,1021,1020,1019,1018,1014,1001,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{410, 1024,1023,1021,1020,1019,1017,1013,1007,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000},
		{415, 1023,1019,1018,1017,1007,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{418, 1021,1020,1016,1006,1002,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{420, 1021,1019,1005,1004,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{421, 1023,1021,1020,1019,1018,1016,1014,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{422, 1021,1020,1019,1017,1013,1007,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{426, 1021,1019,1006,1005,1004,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{436, 1022,1021,1020,1019,1017,1013,1007,1006,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000},
		{439, 1145,1144,1143,1142,1023,1017,1013,1007,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000},
		{477, 1021,1020,1019,1018,1017,1007,1006,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{478, 1024,1022,1021,1020,1013,1012,1005,1004,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{489, 1024,1020,1019,1018,1016,1013,1006,1005,1004,1002,1000,0000,0000,0000,0000,0000,0000,0000},
		{491, 1145,1144,1143,1142,1023,1021,1020,1019,1018,1017,1014,1007,1003,0000,0000,0000,0000,0000},
		{492, 1016,1006,1005,1004,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{496, 1143,1142,1023,1020,1019,1017,1011,1007,1006,1003,1002,1001,0000,0000,0000,0000,0000,0000},
		{500, 1024,1021,1020,1019,1013,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{516, 1021,1020,1019,1018,1017,1016,1015,1007,1004,1002,1000,0000,0000,0000,0000,0000,0000,0000},
		{517, 1145,1144,1143,1142,1023,1020,1019,1018,1017,1016,1007,1003,1002,0000,0000,0000,0000,0000},
		{518, 1145,1144,1143,1142,1023,1020,1018,1017,1013,1007,1006,1005,1003,1001,0000,0000,0000,0000},
		{527, 1021,1020,1018,1017,1015,1014,1007,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{529, 1023,1020,1019,1018,1017,1012,1011,1007,1006,1003,1001,0000,0000,0000,0000,0000,0000,0000},
		{534, 1185,1180,1179,1178,1127,1126,1125,1124,1123,1122,1106,1101,1100,0000,0000,0000,0000,0000},
		{535, 1121,1120,1119,1118,1117,1116,1115,1114,1113,1110,1109,0000,0000,0000,0000,0000,0000,0000},
		{536, 1184,1183,1182,1181,1128,1108,1107,1105,1104,1103,0000,0000,0000,0000,0000,0000,0000,0000},
		{540, 1145,1144,1143,1142,1024,1023,1020,1019,1018,1017,1007,1006,1004,1001,0000,0000,0000,0000},
		{542, 1145,1144,1021,1020,1019,1018,1015,1014,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{546, 1145,1144,1143,1142,1024,1023,1019,1018,1017,1007,1006,1004,1002,1001,0000,0000,0000,0000},
		{547, 1143,1142,1021,1020,1019,1018,1016,1003,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{549, 1145,1144,1143,1142,1023,1020,1019,1018,1017,1012,1011,1007,1003,1001,0000,0000,0000,0000},
		{550, 1145,1144,1143,1142,1023,1020,1019,1018,1006,1005,1004,1003,1001,0000,0000,0000,0000,0000},
		{551, 1023,1021,1020,1019,1018,1016,1006,1005,1003,1002,0000,0000,0000,0000,0000,0000,0000,0000},
		{558, 1168,1167,1166,1165,1164,1163,1095,1094,1093,1092,1091,1090,1089,1088,0000,0000,0000,0000},
		{559, 1173,1162,1161,1160,1159,1158,1072,1071,1070,1069,1068,1067,1066,1065,0000,0000,0000,0000},
		{560, 1170,1169,1141,1140,1139,1138,1033,1032,1031,1030,1029,1028,1027,1026,0000,0000,0000,0000},
		{561, 1157,1156,1155,1154,1064,1063,1062,1061,1060,1059,1058,1057,1056,1055,1031,1030,1027,1026},
		{562, 1172,1171,1149,1148,1147,1146,1041,1040,1039,1038,1037,1036,1035,1034,0000,0000,0000,0000},
		{565, 1153,1152,1151,1150,1054,1053,1052,1051,1050,1049,1048,1047,1046,1045,0000,0000,0000,0000},
		{567, 1189,1188,1187,1186,1133,1132,1131,1130,1129,1102,0000,0000,0000,0000,0000,0000,0000,0000},
		{575, 1177,1176,1175,1174,1099,1044,1043,1042,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{576, 1193,1192,1191,1190,1137,1136,1135,1134,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{580, 1023,1020,1018,1017,1007,1006,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{589, 1145,1144,1024,1020,1018,1017,1016,1013,1007,1006,1005,1004,1000,0000,0000,0000,0000,0000},
		{600, 1022,1020,1018,1017,1013,1007,1006,1005,1004,0000,0000,0000,0000,0000,0000,0000,0000,0000},
		{603, 1145,1144,1143,1142,1024,1023,1020,1019,1018,1017,1007,1006,1001,0000,0000,0000,0000,0000}
};

//Nuke

new nukeIsLaunched;
new nukeCooldown;

new Nuke_Area;
new nukePlayerId;
new Nuke_Priority;

//Weapon shop actors
new ShopActors[MAX_TEAMS];

//Skins list
new clanskinlist;

//Toys list
new toyslist;

new KillCar[MAX_VEHICLES];
new Rustler_Rockets[MAX_VEHICLES][4];

//Labels
new Text3D: nukeRemoteLabel;

//Countdown
new counterOn = 0, counterValue = -1, counterTimer;

//Pickups array
new g_pickups[7];

//Server timers

//Landmines
new gLandmineObj[MAX_SLOTS];
new gLandmineExists[MAX_SLOTS];
new Float: gLandminePos[MAX_SLOTS][3];
new gLandminePlacer[MAX_SLOTS];
new gLandmineTimer[MAX_SLOTS];
new gLandmineArea[MAX_SLOTS];

//Dynamite
new gDynamiteObj[MAX_SLOTS];
new gDynamiteExists[MAX_SLOTS];
new Float: gDynamitePos[MAX_SLOTS][3];
new gDynamitePlacer[MAX_SLOTS];
new gDynamiteTimer[MAX_SLOTS];
new gDynamiteArea[MAX_SLOTS];
new gDynamiteCD[MAX_SLOTS];

//Weapon drop
new gWeaponObj[MAX_SLOTS];
new Text3D: gWeapon3DLabel[MAX_SLOTS];
new gWeaponID[MAX_SLOTS];
new gWeaponAmmo[MAX_SLOTS];
new gWeaponExists[MAX_SLOTS];
new gWeaponPickable[MAX_SLOTS];
new gWeaponTimer[MAX_SLOTS];
new gWeaponArea[MAX_SLOTS];
new gWeaponPUBG[MAX_SLOTS];

//Carepack
new gCarepackObj[MAX_SLOTS];
new Float: gCarepackPos[MAX_SLOTS][3];
new gCarepackExists[MAX_SLOTS];
new gCarepackUsable[MAX_SLOTS];
new gCarepackArea[MAX_SLOTS];
new Text3D: gCarepack3DLabel[MAX_SLOTS];
new gCarepackTimer[MAX_SLOTS];
new gCarepackCaller[MAX_SLOTS][MAX_PLAYER_NAME];

//Anthrax
new Anthrax_Area;
new gAnthraxOwner = -1;
new gAnthraxCooldown;

//Anthrax planes
enum AnthraxData {
	Text3D: Anthrax_Label,
	Anthrax_Cooldown,
	Anthrax_Rockets
};

new CropAnthrax[MAX_VEHICLES][AnthraxData];
///////////////////////////////////////////

//Anti Aircraft

enum E_AAC_DATA {
	AAC_Model,
	Float: AAC_Pos[4],
	AAC_Id,
	Text3D: AAC_Text,
	AAC_Rockets,
	AAC_Regen_Timer,
	AAC_Samsite,
	AAC_Target,
	AAC_Driver,
	AAC_RocketId
};

//Anti air vehicle models: 515, 422
new const AACInfo[][E_AAC_DATA] = {
	{515, {260.9089,1832.2035,18.6603,359.8263}},
	{515, {163.8836,1908.2328,19.5910,270.5557}},
	{422, {-448.1489,2255.1614,51.2067,269.3884}},
	{422, {-447.7226,2194.1311,51.2030,0.5733}}
};

//Balloon

new ballonObjectId, Text3D: Balloon_Label, ballonDestination, bRouteCoords, Balloon_Timer, Balloontimer;
new const Float: ballonRouteArray[][3] = {
	{-358.4772, 2235.1655, 52.6379},
	{-342.6397, 2233.2332, 127.5192},
	{-240.2876, 2049.5674, 127.5192},
	{-112.6949, 1954.8041, 127.5192},
	{-1.4347, 1997.8418, 127.5192},
	{211.9493, 1976.5756, 127.5192},
	{199.3438, 1943.7891, 15.2031}
};

//Deathmatch

enum DeathmatchData {
	Float: DM_HP,
	Float: DM_AR,
	DM_NAME[32],
	DM_WEAP_1[2],
	DM_WEAP_2[2],
	DM_WEAP_3[2],
	DM_WEAP_4[2],
	Float: DM_SPAWN_1[4],
	Float: DM_SPAWN_2[4],
	Float: DM_SPAWN_3[4],
	DM_INT
};

new const DMInfo[][DeathmatchData] = {
	{{100.0}, {100.0}, "Warehouse", {24, 5000}, {25, 5000}, {16, 1}, {10, 1}, {1249.8789,-45.7439,1001.0295,357.8067}, {1287.7396,-52.8278,1002.5090,357.4934}, {1305.4907,4.0674,1001.0273,179.2284}, 18},
	{{100.0}, {100.0}, "Dust Town", {0, 0}, {26, 5000}, {32, 5000}, {0, 0}, {-3126.1147,1780.8942,20.0274,268.8700}, {-3152.1655,1758.8895,20.0109,272.3166}, {-3054.5188,1728.0973,20.0274,93.4250}, 1},
	{{100.0}, {0.0}, "RPG Arena", {35, 1000}, {0, 0}, {0, 0}, {0, 0}, {366.5641,213.0788,1008.3828,178.7679}, {369.8232,186.4829,1008.3893,182.2146}, {383.4497,173.7858,1008.3828,89.4904}, 3},
	{{100.0}, {0.0}, "Minigun Arena", {38, 70000}, {0, 0}, {0, 0}, {0, 0}, {2229.2783,1575.8412,999.9708,359.5631}, {2205.1995,1609.7264,999.9728,359.5864}, {2176.0613,1578.7721,999.9686,1.1531}, 1},
	{{25.0}, {0.0}, "Burning Sector", {18, 400}, {37, 9000}, {42, 9000}, {0, 0}, {238.9707,142.0773,1003.0234,357.2343}, {238.7806,194.0478,1008.1719,181.1065}, {288.7460,169.3510,1007.1719,0.0000}, 3},
	{{100.0}, {0.0}, "Remote Battlefield", {0, 0}, {0, 0}, {0, 0}, {0, 0}, {-974.5394,1061.1886,1344.9669,90.5630}, {-1130.9128,1057.7189,1345.7155,270.3982}, {-1130.9128,1057.7189,1345.7155,270.3982}, 10},
	{{100.0}, {0.0}, "Sniper Rifle", {34, 950}, {0, 0}, {0, 0}, {0, 0}, {-2637.69,1404.24,906.46,0.0}, {-2637.69,1404.24,906.46,0.0}, {-2637.69,1404.24,906.46,0.0}, 3},
	{{100.0}, {0.0}, "Restricted Area", {0, 0}, {0, 0}, {0, 0}, {0, 0}, {302.9792,2032.7242,17.7537,179.2502}, {206.6381,1914.5846,17.6490,269.3657}, {238.7171,1819.5065,17.6524,270.9355}, 0},
	{{100.0}, {0.0}, "LS Hidden Bunker", {24, 500}, {31, 520}, {16, 7}, {38, 10}, {-1580.6182,-2554.4697,28.8284,31.7445}, {-1596.8790,-2567.3677,-5.9774,300.1802}, {-1596.3083,-2713.4727,2.0524,270.4133}, 0}
};

//Anti bot declarations
new g_LastIp[30], g_Connections = 0, g_Tick = 0;

//Camera object
new gCameraId = INVALID_OBJECT_ID;
new gWatchRoom;

//Weapon System

new Iterator: allowed_weapons<MAX_WEAPONS>;

//Vehicle offsets
enum e_OffsetTypes {
	VEHICLE_OFFSET_BOOT,
	VEHICLE_OFFSET_HOOD,
	VEHICLE_OFFSET_ROOF
};

//----------------
//Clans

new clans;

enum L_ClanData {
	C_LevelName[30],
	C_LevelXP
};

new const ClanRanks[][L_ClanData] = {
	{"Unranked", 0},
	{"Bronze", 1000},
	{"Silver", 5000},
	{"Gold", 25000},
	{"Platinum", 40000},
	{"Diamond", 80000},
	{"Conqueror", 124000},
	{"Crown", 150000},
	{"Legendary", 300000},
	{"Godlike", 600000},
	{"Ultimate", 1200000}
};

//--------------------------------------------------------//

//Rustler rockets variable
new Text3D: gRustlerLabel[MAX_VEHICLES];
new gRustlerRockets[MAX_VEHICLES];

//Nevada rockets variable
new Text3D: gNevadaLabel[MAX_VEHICLES];
new gNevadaRockets[MAX_VEHICLES];

//---------------------------------------------------------
//Submarines

enum SubData {
	Float: Sub_Pos[4],
	Sub_Id,
	Text3D: Sub_Label,
	Sub_VID
};

new SubInfo[][SubData] = {
	{{2359.7698,518.5786,0.0653,269.3787}},
	{{-923.4133,2650.9199,40.8446,135.7052}},
	{{-1864.8335,2125.1816,0.2410,43.7085}},
	{{-2324.6838,2300.4482,0.1644,179.1869}},
	{{350.4997,205.7276,0.2127,128.4050}},
	{{89.7057,256.7176,0.2673,68.4656}},
	{{-12.2844,336.0608,0.2693,65.0117}},
	{{-501.0495,1134.8297,0.1871,8.1159}},
	{{-577.3995,1245.0864,0.1892,22.3024}},
	{{-562.5742,1390.8442,0.2110,357.0938}},
	{{-529.9067,1582.6030,0.1923,32.6477}},
	{{-613.4544,1645.5481,0.1936,43.1881}}
};

//---------------------------------------------------------
//Interiors

enum IntData {
	IntIco,
	IntName[25],
	Float:IntEnterPos[4],
	Float:IntExitPos[4],
	IntId,
	IntEnterPickup,
	IntExitPickup,
	Text3D:IntEnterLabel,
	Text3D:IntExitLabel
};

new const Interiors[][IntData] = {
	{25, "Casino", {2194.5601,1677.0518,12.3672}, {2233.8896,1714.1279,1012.3506}, 1},
	{17, "Ranch Shack", {693.7056,1964.3248,5.5391}, {1211.5396,-26.1660,1000.9531}, 3},
	{-1, "LV Gymnasium", {1968.8049,2294.8923,16.4559}, {773.5827,-77.0281,1000.6550}, 7},
	{-1, "North Tower", {704.0296,2778.8835,87.1859}, {719.7679,2775.7905,87.1859}, 0},
	{-1, "Data Center", {-543.7177,2591.4177,54.4992}, {468.3531,-2397.0544,20.9015}, 0},
	{-1, "Security Center", {-184.8809,1552.9513,38.5665}, {-240.0724,1529.7758,29.3609}, 0}
};

//Events

enum E_DATA_ENUM {
	E_NAME[30],

	E_WEAP1[2],
	E_WEAP2[2],
	E_WEAP3[2],
	E_WEAP4[2],

	E_SCORE,
	E_CASH,

	E_TYPE,
	E_SPAWN_TYPE,

	E_SPAWNS,

	E_OPENED,
	E_STARTED,

	E_FREEZE,
	E_INTERIOR,
	E_WORLD,

	E_CHECKPOINTS,
	E_ALLOWLEAVECARS,
	E_MAX_PLAYERS,

	E_AUTO
};

new EventInfo[E_DATA_ENUM];

///////////////////////////////

new RaceName[MAX_RACES][25];
new RaceStarted[MAX_RACES];
new RaceCar[MAX_RACES];
new RaceOpened[MAX_RACES];
new RaceTotalSpawns[MAX_RACES];
new RaceTotalCheckpoints[MAX_RACES];
new RaceInterior[MAX_RACES];
new Float: RaceSpawns[MAX_RACES][MAX_CHECKPOINTS][4];
new Float: RaceCheckpoints[MAX_RACES][MAX_CHECKPOINTS][3];
new RaceCheckpointType[MAX_RACES][MAX_CHECKPOINTS];
new pRaceId[MAX_PLAYERS];
new RaceTimer[MAX_RACES];
new RaceEndTime[MAX_RACES];

enum E_SPAWN_ENUM {
	Float: S_COORDS[4]
};

new SpawnInfo[MAX_CHECKPOINTS][E_SPAWN_ENUM];

//---------------------------------------------------------
//Reports system

enum E_REPORT {
	bool:R_VALID,
	R_AGAINST_ID,
	R_AGAINST_NAME[MAX_PLAYER_NAME],
	R_FROM_ID,
	R_FROM_NAME[MAX_PLAYER_NAME],
	R_TIMESTAMP,
	R_REASON[65],
	bool:R_CHECKED,
	R_READ
};

new ReportInfo[MAX_REPORTS][E_REPORT];

/*
 *
 *
//Player definitions
 *
 *
 */

//An enumerator that contains all player's account data
enum PlayerData {
	PlayerName[MAX_PLAYER_NAME],
	pAccountId,
	pIP[MAX_IP_LEN],
	pSaltKey[11],
	Cache: pCacheId,
	pLoggedIn,
	pAdminLevel,
	pDonorLevel,
	pMuted,
	pCapsDisabled,
	pJailed,
	pJailTime,
	pFrozen,
	pFreezeTime,
	pKills,
	pDeaths,
	pCoins,
	pSessionDays,
	pSessionHours,
	pSessionMins,
	pTimePlayed,
	pPlayTick,
	pTempWarnings,
	pDoorsLocked,
	pSpamCount,
	pSpamTick,
	pCMDSpamCount,
	pCMDSpamTick,
	pCar,
	pSpecId,
	pSpecMode,
	pFailedLogins,
	pRegDate,
	pLastVisit,
	pGunFires,
	pHeadshots,
	pNutshots,
	pSessionKills,
	pSessionDeaths,
	pSessionGunFires,
	pLastKiller,
	pDeathmatchId,
	pLastHitTick,
	pIsAFK,
	pAFKTick,
	pLastSync,
	pBackup,
	pLimit,
	pLimit2,
	pZonesCaptured,
	pCaptureStreak,
	pPickedWeap,
	pAcceptedWeap,
	pDuelsWon,
	pDuelsLost,
	pTimesLoggedIn,
	pMedkitsUsed,
	pArmourkitsUsed,
	pSupportAttempts,
	pIsInvitedToClan,
	pInvitedToClan[35],
	pIsSpying,
	pUsedReport,
	pKnifeKills,
	pAnthrax,
	pAnthraxEffects[17],
	pAnthraxTimer,
	pAnthraxTimes,
	pDoNotDisturb,
	pNoDuel,
	pNoDogfight,
	pGUIEnabled,
	pSpawnKillTime,
	pAllowWatch,
	pQuestionAsked,
	pHeadshotStreak,
	pSpyTeam,
	pRevengeTakes,
	pClanTag,
	pEXPEarned,
	pKillAssists,
	pCaptureAssists,
	pHighestKillStreak,
	pSawnKills,
	sKnives,
	sRevenges,
	sDisguisedKills,
	sSpiesKilled,
	sAssistkills,
	sGasKills,
	pAdjustedHelmet,
	pAdjustedMask,
	pAdjustedDynamite,
	pAirRocketsFired,
	pAntiAirRocketsFired,
	Carepacks,
	sEvents,
	sRaces,
	sDMKills,
	pLeavetime,
	pIsSafe,
	pDisableCapslock,
	pKnifer,
	pKnifeTarget,
	AntiAirAlerts,
	pPreviousMessage[SMALL_STRING_LEN],
	pCarInfoDisplayed,
	pSelecting,
	pSpamWarnings,
	pCrates,
	pDeathmatchKills,
	pRustlerRocketsFired,
	pRustlerRocketsHit,
	acWarnings,
	acTotalWarnings,
	acCooldown,
	Float: pHealthLost,
	Float: pDamageRate,
	pSMGKills,
	pShotgunKills,
	pPistolKills,
	pMeleeKills,
	pHeavyKills,
	pFistKills,
	pCloseKills,
	pDriversStabbed,
	pSpiesEliminated,
	pKillsAsSpy,
	pLongDistanceKills,
	pWeaponsDropped,
	pWeaponsPicked,
	pEventsWon,
	pRacesWon,
	pItemsUsed,
	pFavSkin,
	pFavTeam,
	pSuicideAttempts,
	pPlayersHealed,
	pCommandsUsed,
	pCommandsFailed,
	pUnauthorizedActions,
	pRCONLogins,
	pRCONFailedAttempts,
	pClassAbilitiesUsed,
	pDronesExploded,
	Float: pHealthGained,
	pInteriorsEntered,
	pInteriorsExitted,
	pPickupsPicked,
	pQuestionsAsked,
	pQuestionsAnswered,
	pCrashTimes,
	pSAMPClient[10],
	pBackupAttempts,
	pBackupsResponded,
	pBaseRapeAttempts,
	pChatMessagesSent,
	pMoneySent,
	pMoneyReceived,
	pHighestBet,
	pDuelRequests,
	pDuelsAccepted,
	pDuelsRefusedByPlayer,
	pDuelsRefusedByOthers,
	pBountyAmount,
	pBountyCashSpent,
	pCoinsSpent,
	pPaymentsAccepted,
	pClanKills,
	pClanDeaths,
	pHighestCaptures,
	pKicksByAdmin,
	Float: pLongestKillDistance,
	Float: pNearestKillDistance,
	pHighestCaptureAssists,
	pHighestKillAssists,
	pBountyPlayersKilled,
	pPrototypesStolen,
	pAntennasDestroyed,
	pCratesOpened,
	pLastPing,
	Float: pLastPacketLoss,
	pHighestPing,
	pLowestPing,
	pNukesLaunched,
	pAirstrikesCalled,
	pAnthraxIntoxications,
	pPUBGEventsWon,
	pRopeRappels,
	pAreasEntered,
	pLastAreaId,
	Float: pLastPosX,
	Float: pLastPosY,
	Float: pLastPosZ,
	Float: pLastHealth,
	Float: pLastArmour,
	pTimeSpentOnFoot,
	pTimeSpentInCar,
	pTimeSpentAsPassenger,
	pTimeSpentInSelection,
	pTimeSpentAFK,
	pDriveByKills,
	pCashAdded,
	pCashReduced,
	pLastInterior,
	pLastVirtualWorld,
	pAccountWarnings,
	pAntiCheatWarnings,
	pPlayerReports,
	pSpamAttempts,
	pAdvAttempts,
	pAntiSwearBlocks,
	pTagPermitted,
	pReportAttempts,
	pBannedTimes,
	pWrapWarnings,
	pFlashBangedPlayers,
	pACWarnings,
	pACCooldown,
	pLastMove,
	pFixTGGlitch,
	bool: pNoTutor,
	pGPCI[MAX_GPCI_LEN]
};

//Checks...
new bool: pVerified[MAX_PLAYERS];

//The player's data array
new PlayerInfo[MAX_PLAYERS][PlayerData];
new bool: wasspectating[MAX_PLAYERS];

new pPrivileges[MAX_PLAYERS] = 0;

//spawn stuff
new bool: GotClanWeap[MAX_PLAYERS];

//WP
new pWaypoint[MAX_PLAYERS];

//Store player's money
new pMoney[MAX_PLAYERS];

//Stores the player's last vehicle ID
new LastVehicleID[MAX_PLAYERS];

//Streaming
new pStreamedLink[MAX_PLAYERS];
new pPreviousStreamdLink[MAX_PLAYERS][512];

/*
 *
 *
//Per-player timers
 *
 *
 */

new ExplodeTimer[MAX_PLAYERS];
new RepairTimer[MAX_PLAYERS];
new DelayerTimer[MAX_PLAYERS];
new RecoverTimer[MAX_PLAYERS];
new AKTimer[MAX_PLAYERS];
new CrateTimer[MAX_PLAYERS];
new KillerTimer[MAX_PLAYERS];
new JailTimer[MAX_PLAYERS];
new FreezeTimer[MAX_PLAYERS];
new DMTimer[MAX_PLAYERS];
new RespawnTimer[MAX_PLAYERS];
new InviteTimer[MAX_PLAYERS];
new ac_InformTimer[MAX_PLAYERS];
new SpawnTimer[MAX_PLAYERS];
new LoadingTimer[MAX_PLAYERS];
new TutoTimer[MAX_PLAYERS];
new NotifierTimer[MAX_PLAYERS];
new CarInfoTimer[MAX_PLAYERS];
new pTeamSTimer[MAX_PLAYERS];
new gBackupTimer[MAX_PLAYERS];
new DamageTimer[MAX_PLAYERS];
//new ParadropTimer[MAX_PLAYERS];
new FirstSpawn_Timer[MAX_PLAYERS];
new pAACTargetTimer[MAX_PLAYERS];
new NukeTimer[MAX_PLAYERS];

/*
 *
 *
//Sync
 *
 *
 */

new gOldWeaps[MAX_PLAYERS][13], gOldAmmo[MAX_PLAYERS][13], gOldSkin[MAX_PLAYERS],
	gOldCol[MAX_PLAYERS], gOldInt[MAX_PLAYERS], gOldWorld[MAX_PLAYERS], Float: gOldPos[MAX_PLAYERS][4],
	gOldSpree[MAX_PLAYERS], gOldVID[MAX_PLAYERS], ForceSync[MAX_PLAYERS]
;

//Weapon/ammo data
new pWeaponData[MAX_PLAYERS][13];
new pAmmoData[MAX_PLAYERS][13];

/*
 *
 *
//Per-player textdraw definitions
 *
 *
 */

new sequenceProgress, reverseProgress;

new gametextColors[][3 * MAX_GT_COLORS] = {
	"~h~~r~", "~r~", "~g~", "~b~", "~p~", "~y~", "~w~", "~y~~h~~h~"
};

//Selection
new PlayerText:selectdraw_3[MAX_PLAYERS];
new PlayerText:selectdraw_4[MAX_PLAYERS];
new PlayerText:selectdraw_5[MAX_PLAYERS];
new PlayerText:selectdraw_6[MAX_PLAYERS];
new PlayerBar: Player_SelectionBar[MAX_PLAYERS];

//Flashbang
new PlayerText: FlashTD[MAX_PLAYERS];

//PUBG textdraws
new PlayerText: PUBGBonusTD[MAX_PLAYERS];

//Used to show a player the details of a certain vehicle
new PlayerText: CarInfoPTD[MAX_PLAYERS][3];

//Player textdraws
new PlayerBar: CW_PBAR[MAX_PLAYERS][2];
new PlayerText: killedby[MAX_PLAYERS];
new PlayerText: deathbox[MAX_PLAYERS];
new PlayerText: killedtext[MAX_PLAYERS];
new PlayerText: killedbox[MAX_PLAYERS];
new PlayerText:	Notifier_PTD[MAX_PLAYERS];
new PlayerText: aSpecPTD[MAX_PLAYERS][3];
new PlayerText: Stats_PTD[MAX_PLAYERS][3];
new PlayerText: ProgressTD[MAX_PLAYERS];
new PlayerText: Stats_UIPTD[MAX_PLAYERS];
new PlayerText:CW_PTD[MAX_PLAYERS][2]; //Clan War

new PlayerText: pRankStats[MAX_PLAYERS];
/*
 *
 *
//Player's rank system
 *
 *
 */

new Text3D: RankLabel[MAX_PLAYERS];

//VIP label text
new Text3D: VipLabel[MAX_PLAYERS];

/*
 *
 *
//Rope-rappelling system
 *
 *
 */

enum RopeData {
	RopeID[MAX_ROPES],
	Float: RRX,
	Float: RRY,
	Float: RRZ
};

new pRope[MAX_PLAYERS][RopeData], gRappelling[MAX_PLAYERS];

/*
 *
 *
//Player duel system
 *
 *
 */

enum playerDuelData {
	pDWeapon,
	pDAmmo,

	pDWeapon2,
	pDAmmo2,

	pDBetAmount,
	pDInMatch,
	pDLocked,

	pDMapId,
	pDRematchOpt,
	pDMatchesPlayed,
	pDCountDown,
	pDRCDuel,
	pDInvitePeriod
};

new pDuelInfo[MAX_PLAYERS][playerDuelData], TargetOf[MAX_PLAYERS];
new pDogfightTarget[MAX_PLAYERS], pDogfightBet[MAX_PLAYERS], pDogfightInviter[MAX_PLAYERS],
	pDogfightTime[MAX_PLAYERS], pDogfightTimer[MAX_PLAYERS], pDogfightCD[MAX_PLAYERS],
	pDogfightModel[MAX_PLAYERS];

//TABLE DATA: First Opponent ID, Second Opponent ID, Winner ID, VHP of First Opponent, VHP of Second Opponent, Dogfight Vehicle, Dogfight Time Left
/*
 *
 *
//Player bullet statistcs
 *
 *
 */

enum BulletData {
	Bullets_Hit,
	Bullets_Miss,
	Miss_Ratio,
	Last_Shot_MS,
	MS_Between_Shots,
	Group_Misses,
	Group_Hits,
	Last_Hit_MS,
	Float: Last_Hit_Distance,
	Float: Longest_Hit_Distance,
	Float: Shortest_Hit_Distance,
	Hits_Per_Miss,
	Misses_Per_Hit,
	Longest_Distance_Weapon,
	Aim_SameHMRate,
	Hits_Without_Aiming,
	Float: Bullet_Vectors[3],
	Highest_Hits,
	Highest_Misses
};

new BulletStats[MAX_PLAYERS][BulletData];

/*
 *
 *
//Per-player event sync
 *
 *
 */

enum E_PLAYER_ENUM {
	P_TEAM,
	P_CP,
	P_RACETIME,
	P_CARTIMER
};

new pEventInfo[MAX_PLAYERS][E_PLAYER_ENUM];

/*
 *
 *
//Player selection systems system
 *
 *
 */

//Modified dependencies
//#include <Knife> //By AbyssMorgan, synced with players/teams.pwn

/*
 *
 *
//Player body toys sync and attached objects
 *
 *
 */

///////////////////////////////////////////
//Attached Objects

enum attached_object_data {
	Float:ao_x,
	Float:ao_y,
	Float:ao_z,
	Float:ao_rx,
	Float:ao_ry,
	Float:ao_rz,
	Float:ao_sx,
	Float:ao_sy,
	Float:ao_sz
};

new ao[MAX_PLAYERS][MAX_PLAYER_ATTACHED_OBJECTS][attached_object_data];

///////////////////////////////////////////

new gEditSlot[MAX_PLAYERS];
new gEditModel[MAX_PLAYERS];
new gModelsObj[MAX_PLAYERS][4];
new gModelsSlot[MAX_PLAYERS][4];
new gModelsPart[MAX_PLAYERS][4];
new gEditList[MAX_PLAYERS];

/*
 *
 *
//Miscellaneous
 *
 *
 */

//Interiors
new gIntCD[MAX_PLAYERS];

//Anti Rapid Fire
new stock
	pRapidFireTick			[MAX_PLAYERS],
	pRapidFireBullets		[MAX_PLAYERS char];

//Flashbang
new pFlashLvl[MAX_PLAYERS];

//Miscellaneous
new pClickedID[MAX_PLAYERS];
new gLastWeap[MAX_PLAYERS];
new pPickupCD[MAX_PLAYERS];
new gMedicTick[MAX_PLAYERS];
new pKillerCam[MAX_PLAYERS];
new pBackupRequested[MAX_PLAYERS];
new pBackupResponded[MAX_PLAYERS];
new gBackupHighlight[MAX_PLAYERS];
new pVehId[MAX_PLAYERS];
new Anti_Warn[MAX_PLAYERS];
new pHelmetAttached[MAX_PLAYERS];
new pMaskAttached[MAX_PLAYERS];
new pRaceCheck[MAX_PLAYERS];
new pStreak[MAX_PLAYERS];
new pIsDamaged[MAX_PLAYERS];
new AntiSK[MAX_PLAYERS];
new AntiSKStart[MAX_PLAYERS];
new rconAttempts[MAX_PLAYERS];
new pLastMessager[MAX_PLAYERS];
new IsPlayerUsingAnims[MAX_PLAYERS];
new IsPlayerAnimsPreloaded[MAX_PLAYERS];
new pCooldown[MAX_PLAYERS][43];
new pMinigunFires[MAX_PLAYERS];
new pFirstSpawn[MAX_PLAYERS];
new pStats[MAX_PLAYERS];
new pStatsID[MAX_PLAYERS];
new pShopDelay[MAX_PLAYERS];
new LastDamager[MAX_PLAYERS];
new LastTarget[MAX_PLAYERS];
new LastKilled[MAX_PLAYERS];

//Drone
new bool: InDrone[MAX_PLAYERS];
new Float: gDroneLastPos[MAX_PLAYERS][3];

//Pickup cooldown
new Last_Pickup[MAX_PLAYERS];
new Last_Pickup_Tick[MAX_PLAYERS];

//Check if a player isn't moving
new StaticPlayer[MAX_PLAYERS];

//Medkit
new Float: gMedicKitHP[MAX_PLAYERS];
new bool: gMedicKitStarted[MAX_PLAYERS];

//Clan
new pClan[MAX_PLAYERS] = -1;
new pClanRank[MAX_PLAYERS] = 0;

//Minigun Overheat
new gMGOverheat[MAX_PLAYERS] = 0;

//Katana Insta-kill
new pKatanaEnhancement[MAX_PLAYERS];

//Clear object check
new bool: pIsWorldObjectsRemoved[MAX_PLAYERS] = false;

//Clan logger page
new cLoggerList[MAX_PLAYERS];

//Invisibility handling
new bool: gInvisible[MAX_PLAYERS] = false;
new gInvisibleTime[MAX_PLAYERS];

//Map Icons
new gModMapIcon[MAX_PLAYERS];

//Player session DM kills counter
new pDMKills[MAX_PLAYERS][sizeof(DMInfo)];

//Check whether player is using the watchroom feature
new bool: pWatching[MAX_PLAYERS];

//Check whether a player's report was checked or not
new bool: PlayerReportChecked[MAX_PLAYERS][MAX_REPORTS];

//Return the player's selected race from the list of races
new pRaceListItem[MAX_PLAYERS][20];

/*
 *
 *
//Iterators
 *
 *
 */

//PUBG event global iterator
new Iterator: PUBGPlayers<MAX_PLAYERS>;

//Clan war global iterators
new Iterator:CWCLAN1<MAX_PLAYERS>, Iterator:CWCLAN2<MAX_PLAYERS>;
enum CWData {
	CWStarted,
	CWId1,
	CWId2,
	CWMode,
	CWWeaps[5],
	CWAmmo[5],
	Float: CWPos1[4],
	Float: CWPos2[4],
	CWInt,
	CWWorld,
	CWParties1,
	CWParties2
}
new CWInfo[CWData];
new CWTimer, CWCD;

//Events global iterator
new Iterator:ePlayers<MAX_PLAYERS>;

//Votekick requests
new pVotesKick[MAX_PLAYERS];
new bool: pVotedKick[MAX_PLAYERS][MAX_PLAYERS];
new pVoteKickCD[MAX_PLAYERS];

//Weather system
new fine_weather_ids[] = {1,2,3,4,5,6,7,12,13,14,15,17,18};
new stock foggy_weather_ids[] = {9,19,20,31,32};
new stock wet_weather_ids[] = {8};

/////////////////////////////////////////////
//Global Messages

new UpdateMessages[][256] = {
	"Did you know? Our community has a discord server! Join: https://discord.gg/MVZezzQ",
	"Donate for our server to get access to cool game features & help us in the same time!",
	"Visit our website for latest news! "WEBSITE"",
	"Fun fact: We have been around since 2018!",
	"Invite your friends to the server and spread the fun!",
	"You can suggest cool features for us to implement on our discord server! Join: https://discord.gg/MVZezzQ",
	"Spotted a cheater? Use /report or alert us on discord: https://discord.gg/MVZezzQ",
	"Did you know? you can change your current mode using /mode!",
	"Bring at least 4 players and start the PUBG event from /mode!",
	"Have a friend and wanna have some fun out of the battlefield? Start a /race now!",
	"There are some features that are exclusive for SWAT/Terrorists teams, figure them out.",
	"Use /help /cmds /rules to know everything you wanna know about the server.",
	"Keep track of your game /stats and /matchfacts for dogfights!",
	"Getting annoyed from a specific feature? Toggle it off from /settings.",
	"Please report any bugs on our discord server: https://discord.gg/MVZezzQ",
	"More features are coming soon, stay tuned!",
	"You can drop guns using /dropgun in PUBG mode!",
	"Did you know? You can actually use /pickup to get any nearby items/weapons!",
	"Use /fire to drop rustler/nevada bombs, fire AAC/Submarine rockets and throw anthrax from a cropduster!",
	"Your team base shop is where you can get all the interesting items, find it on the map!",
	"You can request /backup and /respond to backup requests!",
	"You can /watch players if they allow it with /togwatch!",
	"You can talk privately with your teammates using /tr.",
	"Getting help messages too often? You can disable them through /settings.",
	"We hope you continue to enjoy your gameplay on SvT. Please add us to your favorites <3 (IP: agent.ducky.rocks:7778)",
	"Did you know? You can use our /music player to play custom music through a link!",
	"You can use /exit anytime to return back to the battlefield if you're stuck or so.",
	"You can disable duels using /noduel and disable dogfights using /nodogfight.",
	"Create your very own clan now using /ccreate!",
	"Wanna unlock interesting VIP features? Read /vip for details and join our discord for info: https://discord.gg/MVZezzQ",
	"We wish you stay safe from all of us at H2O Multiplayer!",
	"For more information, contact our staff or use /ask!",
	"Earn more score to unlock classes and have more abilities!",
	"Did you know? You can get items, weapons and special weapon abilities at your team base shop.",
	"Capture zones, eliminate enemies and unlock /achievements to progress faster!",
	"Kill more players in a row to make a killing /spree (read /sprees!).",
	"Did you know? You earn more score by killing someone who killed you before.",
	"Some classes and team shop items can give you invisibility off the radar for some time.",
	"Use /mk (medkits) to heal yourself and /ak (Armourkit) to patch your Armour!",
	"Steal enemy prototypes from their team base to earn special rewards!",
	"Earn more EXP (that is another type of score) to unlock advanced classes!",
	"You can earn EXP by killing players once you rank up (read /ranks)!",
	"You can also earn EXP by different ways, try to achieve something and check if you received any!",
	"Fire less bullets using minigun to avoid getting to an overheat!",
	"Participate in team wars for more rewards on winning! (read /war to know more)",
	"You can change your team wih /st, class with /sc and spawn place with /sp!",
	"Read /rank to know more about the special features you've unlocked.",
	"Use /inv to manage your inventory and drop/consume/pickup items.",
	"You can join our death-match arenas now using /dm.",
	"Battlefield isn't small at all, enemy bases have a red border, figure them out!",
	"Did you know? Gang zone numbers on the map represent the base/zone internal ID.",
	"Fun fact: Team zone numbers begin from 1, while zones begin from 0 (can be noticed on the map).",
	"You can use /local to speak to nearby players.",
	"Use /pb to plant dynamite and /suicide to explode yourself.",
	"Unlock the Veteran Supporter class to be able to use anti aircraft vehicles.",
	"Use anti aircraft vehicles to destroy vehicles in the air.",
	"You can know more about bounty players using /bounties or set a bounty using /setbounty!",
	"If you have a moneybag on your back, you have a cash bounty on your head!",
	"Server will automatically pick a player for bounty every now and then.",
	"Use /pm to have a private discussion with a player!",
	"You can use /mstop to stop streaming audio (i.e. if it got stuck).",
	"You can use /dogfight to fight other players in air!",
	"You can use /duel to duel other players PvP with custom options.",
	"We may host a clan tournament or a special event from time to time, stay tuned on discord: https://discord.gg/MVZezzQ",
	"Start a clan, have some fun with your members, buy a weapon and a skin or even plan a clan tournament!",
	"For any discussions, queries, help or if you just wanna have fun, join our discord: https://discord.gg/MVZezzQ",
	"Please don't abuse any bug if you find any and head off to our discord server: https://discord.gg/MVZezzQ"
};

//Miscellaneous Functions

//Tagged Functions

//Teams
forward Float: Team_GetMapArea(team, point);

//3DTryg

Float:GetPlayerSpeed(playerid){
	static Float:x,Float:y,Float:z;
	GetPlayerVelocity(playerid,x,y,z);
	return floatmul(VectorSize(x,y,z),1.0);
}

stock Float:GetVehicleSpeed(vehicleid){
	static Float:x,Float:y,Float:z;
	GetVehicleVelocity(vehicleid,x,y,z);
	return floatmul(VectorSize(x,y,z),170.0);
}

Float:GetCameraTargetDistance(Float:CamX,Float:CamY,Float:CamZ,Float:ObjX,Float:ObjY,Float:ObjZ,Float:FrX,Float:FrY,Float:FrZ){
	new Float: dist = GetDistanceBetweenPoints3D(CamX,CamY,CamZ,ObjX,ObjY,ObjZ);
	return GetDistanceBetweenPoints3D(ObjX,ObjY,ObjZ,(FrX * dist + CamX),(FrY * dist + CamY),(FrZ * dist + CamZ));
}

//Get distance from a point to another
Float:GetPointDistanceToPoint(Float:x1, Float:y1, Float:x2, Float:y2) {
	new Float:x, Float:y;
	x = x1-x2;
	y = y1-y2;
	return floatsqroot(x*x+y*y);
}

//Random float number
Float:frandom(Float:max, Float:min = 0.0, dp = 4) {
	new
		Float:mul = floatpower(10.0, dp),
		imin = floatround(min * mul),
		imax = floatround(max * mul);
	return float(random(imax - imin) + imin) / mul;
}

//Check whether a player is aiming at the target
bool:IsPlayerAimingAtPlayer(playerid, target) {
	new Float:x, Float:y, Float:z;
	GetPlayerPos(target, x, y, z);
	if (IsPlayerAimingAt(playerid, x, y, z-0.75, 0.25)) return true;
	if (IsPlayerAimingAt(playerid, x, y, z-0.25, 0.25)) return true;
	if (IsPlayerAimingAt(playerid, x, y, z+0.25, 0.25)) return true;
	if (IsPlayerAimingAt(playerid, x, y, z+0.75, 0.25)) return true;
	return false;
}

//3DTryg Implementation
IsPlayerAimingAt(playerid,Float:x,Float:y,Float:z,Float:radius){
	static Float:cx,Float:cy,Float:cz,Float:fx,Float:fy,Float:fz;
	GetPlayerCameraPos(playerid,cx,cy,cz);
	GetPlayerCameraFrontVector(playerid,fx,fy,fz);
	return (radius >= GetCameraTargetDistance(cx,cy,cz,x,y,z,fx,fy,fz));
}

SetPlayerPosition(playerid, const Place_Name[], World, Int, Float: X, Float: Y, Float: Z, Float: R = 0.0, bool:loadmap=false) {
	if (loadmap) {
		TogglePlayerControllable(playerid, false);
		SetTimerEx("LoadMap", 500 + GetPlayerPing(playerid), false, "i", playerid);
	}
	Streamer_UpdateEx(playerid, X, Y, Z);

	SetPlayerInterior(playerid, Int);
	SetPlayerVirtualWorld(playerid, World);

	SetPlayerPos(playerid, X, Y, Z);
	SetPlayerFacingAngle(playerid, R);

	if (!isnull(Place_Name)) {
		new string[50];
		format(string, sizeof(string), "%s", Place_Name);
		GameTextForPlayer(playerid, string, 5000, 1);
	}
	return 1;
}

//Illegal vehicle models

iswheelmodel(modelid) {
	new wheelmodels[17] = {1025,1073,1074,1075,1076,1077,1078,1079,1080,1081,1082,1083,1084,1085,1096,1097,1098};
	for(new i = 0, b = sizeof(wheelmodels); i != b; i++) {
		if (modelid == wheelmodels[i])
			return true;

	}
	return false;
}

IllegalCarNitroIde(carmodel) {
	new illegalvehs[29] = { 581, 523, 462, 521, 463, 522, 461, 448, 468, 586, 509, 481, 510, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454, 590, 569, 537, 538, 570, 449 };
	for (new i = 0, b = sizeof(illegalvehs); i != b; i++) {
		if (carmodel == illegalvehs[i])
			return true;
	}
	return false;
}

stock illegal_nos_vehicle(PlayerID) {
	new carid = GetPlayerVehicleID(PlayerID);
	new playercarmodel = GetVehicleModel(carid);
	return IllegalCarNitroIde(playercarmodel);

}

islegalcarmod(vehicleide, componentid) {
	new modok = false;

	if ((iswheelmodel(componentid)) || (componentid == 1086) || (componentid == 1087) || ((componentid >= 1008) && (componentid <= 1010))) {
		new nosblocker = IllegalCarNitroIde(vehicleide);
		if (!nosblocker) {
			modok = true;
		}
	} else {
		for (new i = 0, b = sizeof(legalmods); i != b; i++) {
			if (legalmods[i][0] == vehicleide) {
				for (new j = 1; j < 22; j++) {
					if (legalmods[i][j] == componentid) {
						modok = true;
						break;
					}
				}
			}
		}
	}
	return modok;
}

//Quicksort

QuickSort_Pair(array[][2], bool:desc, left, right) {
	new
		tempLeft = left,
		tempRight = right,
		pivot = array[(left + right) / 2][PAIR_FIST],
		tempVar
	;
	while (tempLeft <= tempRight) {
		if (desc) {
			while (array[tempLeft][PAIR_FIST] > pivot) {
				tempLeft++;
			}
			while (array[tempRight][PAIR_FIST] < pivot) {
				tempRight--;
			}
		}
		else
		{
			while (array[tempLeft][PAIR_FIST] < pivot) {
				tempLeft++;
			}
			while (array[tempRight][PAIR_FIST] > pivot) {
				tempRight--;
			}
		}

		if (tempLeft <= tempRight) {
			tempVar = array[tempLeft][PAIR_FIST];
			array[tempLeft][PAIR_FIST] = array[tempRight][PAIR_FIST];
			array[tempRight][PAIR_FIST] = tempVar;

			tempVar = array[tempLeft][PAIR_SECOND];
			array[tempLeft][PAIR_SECOND] = array[tempRight][PAIR_SECOND];
			array[tempRight][PAIR_SECOND] = tempVar;

			tempLeft++;
			tempRight--;
		}
	}
	if (left < tempRight) {
		QuickSort_Pair(array, desc, left, tempRight);
	}
	if (tempLeft < right) {
		QuickSort_Pair(array, desc, tempLeft, right);
	}
}

//Health

ReturnHealth(playerid) {
	new Float: HP;
	GetPlayerHealth(playerid, HP);

	new floatr;
	floatr = floatround(HP, floatround_ceil);
	return floatr;
}

//XYZ

stock GetXYZInfrontOfCar(vehicleid, &Float:x, &Float:y, Float:distance) {
	if (IsValidVehicle(vehicleid)) {
		new Float:a;

		GetVehiclePos(vehicleid, x, y, a);
		GetVehicleZAngle(vehicleid, a);

		x += (distance * floatsin(-a, degrees));
		y += (distance * floatcos(-a, degrees));
	}
}

GetXYZInfrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance) {
	new Float:a;

	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);

	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

GetXYZInfrontOfAAC(AAC, &Float:x, &Float:y, Float:distance) {
	if (IsValidVehicle(AACInfo[AAC][AAC_Id])) {
		new Float:a;

		GetVehiclePos(AACInfo[AAC][AAC_Id], x, y, a);
		GetVehicleZAngle(AACInfo[AAC][AAC_Id], a);

		x += (distance * floatsin(-a, degrees));
		y += (distance * floatcos(-a, degrees));
	}
}

//Tune cars

Tuneacar(VehicleID) {
	AddVehicleComponent(VehicleID, 1010);
	AddVehicleComponent(VehicleID, 1087);
	AddVehicleComponent(VehicleID, 1057);
	AddVehicleComponent(VehicleID, 1086);

	ChangeVehicleColor(VehicleID, 0, 0);
	return 1;
}

CarSpawner(playerid, model) {
	if (IsPlayerInAnyVehicle(playerid)) return 1;

	new Float:x, Float:y, Float:z, Float:angle;
	GetPlayerPos(playerid, x, y, z);

	GetPlayerFacingAngle(playerid, angle);

	if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
	PlayerInfo[playerid][pCar] = -1;
	new vehicleid = CreateVehicle(model, x, y, z, angle, -1, -1, -1);

	if (PlayerInfo[playerid][pDeathmatchId] == -1) {
		SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
		LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
		ChangeVehicleColor(vehicleid, 0, 0);
	} else {
		SetVehicleVirtualWorld(vehicleid, DM_WORLD);
		LinkVehicleToInterior(vehicleid, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_INT]);
	}

	if (model == 411 && PlayerInfo[playerid][pDonorLevel]) {
		SetVehicleNumberPlate(vehicleid, "V.I.P");
	}

	pVehId[playerid] = PlayerInfo[playerid][pCar] = vehicleid;
	PutPlayerInVehicle(playerid, vehicleid, 0);

	LogActivity(playerid, "Spawned vehicle [id: %d, model: %d]", gettime(), vehicleid, model);
	return 1;
}

CarDeleter(vehicleid) {
	if (!IsValidVehicle(vehicleid)) return 0;

	foreach (new i: Player) {
		new Float:X,Float:Y,Float:Z;
		if (IsPlayerInVehicle(i, vehicleid)) {
			GetPlayerPos(i, X, Y, Z);
			SetPlayerPos(i, X, Y + 3, Z);
			if (PlayerInfo[i][pCar] == vehicleid) {
				PlayerInfo[i][pCar] = -1;
			}
		}
		SetVehicleParamsForPlayer(vehicleid, i, 0, 1);
	}

	KillTimer(KillCar[vehicleid]);
	KillCar[vehicleid] = SetTimerEx("EraseCar", 2500, false, "i", vehicleid);
	return 1;
}

//Money related

GivePlayerCash(playerid, amount) {
	pMoney[playerid] += amount;
	GivePlayerMoney(playerid, amount);

	if (GetPlayerMoney(playerid) > pMoney[playerid]) {
		new difference = GetPlayerMoney(playerid) - pMoney[playerid];
		GivePlayerMoney(playerid, -difference);
	}

	if (pMoney[playerid] < 0) {
		pMoney[playerid] = 0;
	}

	if (amount > 0) {
		PlayerInfo[playerid][pCashAdded] += amount;
	} else {
		PlayerInfo[playerid][pCashReduced] += -amount;
	}
	return 1;
}

ResetPlayerCash(playerid) {
	pMoney[playerid] = 0;
	ResetPlayerMoney(playerid);
	return 1;
}

GetPlayerCash(playerid) {
	return pMoney[playerid];
}

//Toys

AttachHelmet(playerid) {
	switch (Items_GetPlayer(playerid, HELMET)) {
		case 0: {
			if (IsPlayerAttachedObjectSlotUsed(playerid, 2)) {
				RemovePlayerAttachedObject(playerid, 2);
			}
		}
		default: {
			if (!PlayerInfo[playerid][pAdjustedHelmet]) {
				SetPlayerAttachedObject(playerid, 2, 19102, 2, 0.15, 0.00, 0.00, 0.00, 0.00, 0.00, 1.00, 1.00, 1.00);
			} else {
				SetPlayerAttachedObject(playerid, 2, 19102, 2, ao[playerid][2][ao_x], ao[playerid][2][ao_y], ao[playerid][2][ao_z], ao[playerid][2][ao_rx], ao[playerid][2][ao_ry], ao[playerid][2][ao_rz], ao[playerid][2][ao_sx], ao[playerid][2][ao_sy], ao[playerid][2][ao_sz]);
			}
		}
	}
	return 1;
}

AttachMask(playerid) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, 3)) {
		RemovePlayerAttachedObject(playerid, 3);
	}
	if (Items_GetPlayer(playerid, MASK)) {
		if (!PlayerInfo[playerid][pAdjustedMask]) {
			SetPlayerAttachedObject(playerid, 3, 19472, 2, 0.00, 0.14, 0.01, 0.00, 88.60, 94.49, 1.04, 1.09, 1.05);
		} else {
			SetPlayerAttachedObject(playerid, 3, 19472, 2, ao[playerid][3][ao_x], ao[playerid][3][ao_y], ao[playerid][3][ao_z], ao[playerid][3][ao_rx], ao[playerid][3][ao_ry], ao[playerid][3][ao_rz], ao[playerid][3][ao_sx], ao[playerid][3][ao_sy], ao[playerid][3][ao_sz]);
		}
	}
	return 1;
}

AttachDynamite(playerid) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, 5)) {
		RemovePlayerAttachedObject(playerid, 5);
	}

	if (Items_GetPlayer(playerid, DYNAMITE)) {
		if (!PlayerInfo[playerid][pAdjustedDynamite]) {
			SetPlayerAttachedObject(playerid, 5, 1654, 1, 0.11, -0.11, 0.00, 0.00, -59.70, 0.00, 1.00, 1.00, 1.00);
		} else {
			SetPlayerAttachedObject(playerid, 5, 1654, 1, ao[playerid][5][ao_x], ao[playerid][5][ao_y], ao[playerid][5][ao_z], ao[playerid][5][ao_rx], ao[playerid][5][ao_ry], ao[playerid][5][ao_rz], ao[playerid][5][ao_sx], ao[playerid][5][ao_sy], ao[playerid][5][ao_sz]);
		}
	}
	return 1;
}

ResetToysData(playerid) {
	new clear_ao[attached_object_data];
	for (new i = 0; i < MAX_PLAYER_ATTACHED_OBJECTS; i++) {
		ao[playerid][i] = clear_ao;
	}
	return 1;
}

//API

TOYS_OnPlayerStateChange(playerid, newstate, oldstate) {
	if ((newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) && oldstate == PLAYER_STATE_ONFOOT) {
		if (IsPlayerAttachedObjectSlotUsed(playerid, 2) && GetPlayerWeapon(playerid) == 34) {
			RemovePlayerAttachedObject(playerid, 2);
			pHelmetAttached[playerid] = 1;
		}
		if (IsPlayerAttachedObjectSlotUsed(playerid, 3) && GetPlayerWeapon(playerid) == 34)
		{
			RemovePlayerAttachedObject(playerid, 3);
			pMaskAttached[playerid] = 1;
		}
	} else if (newstate == PLAYER_STATE_ONFOOT && (oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)) {
		if (pHelmetAttached[playerid]) {
			AttachHelmet(playerid);
			pHelmetAttached[playerid] = 0;
		}
		if (pMaskAttached[playerid]) {
			AttachMask(playerid);
			pMaskAttached[playerid] = 0;
		}
	}
	return 1;
}

TOYS_OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
	//Sync
	if (HOLDING(KEY_HANDBRAKE)) {
		if (IsPlayerAttachedObjectSlotUsed(playerid, 2)  && GetPlayerWeapon(playerid) == 34) {
			RemovePlayerAttachedObject(playerid, 2);
			pHelmetAttached[playerid] = 1;
		}
		if (IsPlayerAttachedObjectSlotUsed(playerid, 3) && GetPlayerWeapon(playerid) == 34)
		{
			RemovePlayerAttachedObject(playerid, 3);
			pMaskAttached[playerid] = 1;
		}
	} else if (RELEASED(KEY_HANDBRAKE)) {
		if (pHelmetAttached[playerid]) {
			AttachHelmet(playerid);
			pHelmetAttached[playerid] = 0;
		}
		if (pMaskAttached[playerid]) {
			AttachMask(playerid);
			pMaskAttached[playerid] = 0;
		}
	}
	return 1;
}

//UI Functions

CreateUI() {
	//War Log
	static Float: WarStatusPos = 381.000000;
	for (new i = 0; i < sizeof(WarStatusTD); i++) {
		WarStatusTD[i] = TextDrawCreate(482.000000, WarStatusPos, "_");
		TextDrawFont(WarStatusTD[i], 1);
		TextDrawLetterSize(WarStatusTD[i], 0.141667, 1.050000);
		TextDrawTextSize(WarStatusTD[i], 665.000000, 282.000000);
		TextDrawSetOutline(WarStatusTD[i], 0);
		TextDrawSetShadow(WarStatusTD[i], 0);
		TextDrawAlignment(WarStatusTD[i], 1);
		TextDrawColor(WarStatusTD[i], -1);
		TextDrawBackgroundColor(WarStatusTD[i], 255);
		TextDrawBoxColor(WarStatusTD[i], 50);
		TextDrawUseBox(WarStatusTD[i], 0);
		TextDrawSetProportional(WarStatusTD[i], 1);
		TextDrawSetSelectable(WarStatusTD[i], 0);
		WarStatusPos += 9;
	}

	//UIBox

	BoxTD[0] = TextDrawCreate(479.000000, 379.000000, "_");
	TextDrawFont(BoxTD[0], 1);
	TextDrawLetterSize(BoxTD[0], 0.600000, 10.300003);
	TextDrawTextSize(BoxTD[0], 681.500000, 75.000000);
	TextDrawSetOutline(BoxTD[0], 1);
	TextDrawSetShadow(BoxTD[0], 0);
	TextDrawAlignment(BoxTD[0], 1);
	TextDrawColor(BoxTD[0], -1);
	TextDrawBackgroundColor(BoxTD[0], 255);
	TextDrawBoxColor(BoxTD[0], 135);
	TextDrawUseBox(BoxTD[0], 1);
	TextDrawSetProportional(BoxTD[0], 1);
	TextDrawSetSelectable(BoxTD[0], 0);

	BoxTD[1] = TextDrawCreate(479.000000, 365.000000, "_");
	TextDrawFont(BoxTD[1], 1);
	TextDrawLetterSize(BoxTD[1], 0.600000, 1.350004);
	TextDrawTextSize(BoxTD[1], 681.500000, 75.000000);
	TextDrawSetOutline(BoxTD[1], 1);
	TextDrawSetShadow(BoxTD[1], 0);
	TextDrawAlignment(BoxTD[1], 1);
	TextDrawColor(BoxTD[1], -1);
	TextDrawBackgroundColor(BoxTD[1], 255);
	TextDrawBoxColor(BoxTD[1], 255);
	TextDrawUseBox(BoxTD[1], 1);
	TextDrawSetProportional(BoxTD[1], 1);
	TextDrawSetSelectable(BoxTD[1], 0);

	//===============================================================
	//Intro

	SvTTD[0] = TextDrawCreate(250.000000, 141.000000, "Preview_Model");
	TextDrawFont(SvTTD[0], 5);
	TextDrawLetterSize(SvTTD[0], 0.600000, 2.000000);
	TextDrawTextSize(SvTTD[0], 112.500000, 150.000000);
	TextDrawSetOutline(SvTTD[0], 0);
	TextDrawSetShadow(SvTTD[0], 0);
	TextDrawAlignment(SvTTD[0], 1);
	TextDrawColor(SvTTD[0], -1);
	TextDrawBackgroundColor(SvTTD[0], 0);
	TextDrawBoxColor(SvTTD[0], 255);
	TextDrawUseBox(SvTTD[0], 0);
	TextDrawSetProportional(SvTTD[0], 1);
	TextDrawSetSelectable(SvTTD[0], 0);
	TextDrawSetPreviewModel(SvTTD[0], 19306);
	TextDrawSetPreviewRot(SvTTD[0], 0.000000, 20.000000, -20.000000, 1.979999);
	TextDrawSetPreviewVehCol(SvTTD[0], 1, 1);

	SvTTD[1] = TextDrawCreate(247.000000, 141.000000, "Preview_Model");
	TextDrawFont(SvTTD[1], 5);
	TextDrawLetterSize(SvTTD[1], 0.600000, 2.000000);
	TextDrawTextSize(SvTTD[1], 112.500000, 150.000000);
	TextDrawSetOutline(SvTTD[1], 0);
	TextDrawSetShadow(SvTTD[1], 0);
	TextDrawAlignment(SvTTD[1], 1);
	TextDrawColor(SvTTD[1], -1);
	TextDrawBackgroundColor(SvTTD[1], 0);
	TextDrawBoxColor(SvTTD[1], 255);
	TextDrawUseBox(SvTTD[1], 0);
	TextDrawSetProportional(SvTTD[1], 1);
	TextDrawSetSelectable(SvTTD[1], 0);
	TextDrawSetPreviewModel(SvTTD[1], 19307);
	TextDrawSetPreviewRot(SvTTD[1], 0.000000, -20.000000, -200.000000, 2.269998);
	TextDrawSetPreviewVehCol(SvTTD[1], 1, 1);

	SvTTD[2] = TextDrawCreate(320.000000, 227.000000, "H2O-SvT");
	TextDrawFont(SvTTD[2], 2);
	TextDrawLetterSize(SvTTD[2], 0.404166, 1.600000);
	TextDrawTextSize(SvTTD[2], 400.000000, 17.000000);
	TextDrawSetOutline(SvTTD[2], 0);
	TextDrawSetShadow(SvTTD[2], 0);
	TextDrawAlignment(SvTTD[2], 2);
	TextDrawColor(SvTTD[2], -1);
	TextDrawBackgroundColor(SvTTD[2], 255);
	TextDrawBoxColor(SvTTD[2], 50);
	TextDrawUseBox(SvTTD[2], 0);
	TextDrawSetProportional(SvTTD[2], 1);
	TextDrawSetSelectable(SvTTD[2], 0);

	//Selection

	selectdraw_0 = TextDrawCreate(506.000000, 169.000000, "_");
	TextDrawFont(selectdraw_0, 1);
	TextDrawLetterSize(selectdraw_0, 0.600000, 17.800003);
	TextDrawTextSize(selectdraw_0, 298.500000, 155.500000);
	TextDrawSetOutline(selectdraw_0, 1);
	TextDrawSetShadow(selectdraw_0, 0);
	TextDrawAlignment(selectdraw_0, 2);
	TextDrawColor(selectdraw_0, -1);
	TextDrawBackgroundColor(selectdraw_0, 255);
	TextDrawBoxColor(selectdraw_0, 215);
	TextDrawUseBox(selectdraw_0, 1);
	TextDrawSetProportional(selectdraw_0, 1);
	TextDrawSetSelectable(selectdraw_0, 0);

	selectdraw_1 = TextDrawCreate(506.000000, 172.000000, "Your Selection Progress");
	TextDrawFont(selectdraw_1, 2);
	TextDrawLetterSize(selectdraw_1, 0.220833, 1.250000);
	TextDrawTextSize(selectdraw_1, 591.500000, 172.500000);
	TextDrawSetOutline(selectdraw_1, 1);
	TextDrawSetShadow(selectdraw_1, 0);
	TextDrawAlignment(selectdraw_1, 2);
	TextDrawColor(selectdraw_1, -1);
	TextDrawBackgroundColor(selectdraw_1, 255);
	TextDrawBoxColor(selectdraw_1, 50);
	TextDrawUseBox(selectdraw_1, 0);
	TextDrawSetProportional(selectdraw_1, 1);
	TextDrawSetSelectable(selectdraw_1, 0);

	//Clan War

	//Clan War
	CWTD_0 = TextDrawCreate(528.000000, 234.000000, "_");
	TextDrawFont(CWTD_0, 1);
	TextDrawLetterSize(CWTD_0, 0.600000, 10.300003);
	TextDrawTextSize(CWTD_0, 639.500000, 78.500000);
	TextDrawSetOutline(CWTD_0, 1);
	TextDrawSetShadow(CWTD_0, 0);
	TextDrawAlignment(CWTD_0, 1);
	TextDrawColor(CWTD_0, -1);
	TextDrawBackgroundColor(CWTD_0, 255);
	TextDrawBoxColor(CWTD_0, 231);
	TextDrawUseBox(CWTD_0, 1);
	TextDrawSetProportional(CWTD_0, 1);
	TextDrawSetSelectable(CWTD_0, 0);

	CWTD_1 = TextDrawCreate(554.000000, 235.000000, "Clan War Statistics");
	TextDrawFont(CWTD_1, 0);
	TextDrawLetterSize(CWTD_1, 0.233333, 1.100000);
	TextDrawTextSize(CWTD_1, 678.500000, 272.000000);
	TextDrawSetOutline(CWTD_1, 1);
	TextDrawSetShadow(CWTD_1, 0);
	TextDrawAlignment(CWTD_1, 1);
	TextDrawColor(CWTD_1, -1);
	TextDrawBackgroundColor(CWTD_1, 255);
	TextDrawBoxColor(CWTD_1, 50);
	TextDrawUseBox(CWTD_1, 0);
	TextDrawSetProportional(CWTD_1, 1);
	TextDrawSetSelectable(CWTD_1, 0);

	CWTD_2 = TextDrawCreate(530.000000, 260.000000, "FIRST_CLAN");
	TextDrawFont(CWTD_2, 2);
	TextDrawLetterSize(CWTD_2, 0.233333, 1.100000);
	TextDrawTextSize(CWTD_2, 678.500000, 272.000000);
	TextDrawSetOutline(CWTD_2, 1);
	TextDrawSetShadow(CWTD_2, 0);
	TextDrawAlignment(CWTD_2, 1);
	TextDrawColor(CWTD_2, -1);
	TextDrawBackgroundColor(CWTD_2, 255);
	TextDrawBoxColor(CWTD_2, 50);
	TextDrawUseBox(CWTD_2, 0);
	TextDrawSetProportional(CWTD_2, 1);
	TextDrawSetSelectable(CWTD_2, 0);

	CWTD_3 = TextDrawCreate(530.000000, 291.000000, "SECOND_CLAN");
	TextDrawFont(CWTD_3, 2);
	TextDrawLetterSize(CWTD_3, 0.233333, 1.100000);
	TextDrawTextSize(CWTD_3, 678.500000, 272.000000);
	TextDrawSetOutline(CWTD_3, 1);
	TextDrawSetShadow(CWTD_3, 0);
	TextDrawAlignment(CWTD_3, 1);
	TextDrawColor(CWTD_3, -1);
	TextDrawBackgroundColor(CWTD_3, 255);
	TextDrawBoxColor(CWTD_3, 50);
	TextDrawUseBox(CWTD_3, 0);
	TextDrawSetProportional(CWTD_3, 1);
	TextDrawSetSelectable(CWTD_3, 0);

	clanwar_0 = TextDrawCreate(325.000000, 169.000000, "_");
	TextDrawFont(clanwar_0, 1);
	TextDrawLetterSize(clanwar_0, 0.600000, 21.849990);
	TextDrawTextSize(clanwar_0, 298.500000, 300.000000);
	TextDrawSetOutline(clanwar_0, 1);
	TextDrawSetShadow(clanwar_0, 0);
	TextDrawAlignment(clanwar_0, 2);
	TextDrawColor(clanwar_0, -1);
	TextDrawBackgroundColor(clanwar_0, 255);
	TextDrawBoxColor(clanwar_0, 135);
	TextDrawUseBox(clanwar_0, 1);
	TextDrawSetProportional(clanwar_0, 1);
	TextDrawSetSelectable(clanwar_0, 0);

	clanwar_1 = TextDrawCreate(185.000000, 168.000000, "Clan tournament ~g~is starting...");
	TextDrawFont(clanwar_1, 3);
	TextDrawLetterSize(clanwar_1, 0.475000, 2.449999);
	TextDrawTextSize(clanwar_1, 670.000000, 278.000000);
	TextDrawSetOutline(clanwar_1, 1);
	TextDrawSetShadow(clanwar_1, 0);
	TextDrawAlignment(clanwar_1, 1);
	TextDrawColor(clanwar_1, -1);
	TextDrawBackgroundColor(clanwar_1, 255);
	TextDrawBoxColor(clanwar_1, 50);
	TextDrawUseBox(clanwar_1, 0);
	TextDrawSetProportional(clanwar_1, 1);
	TextDrawSetSelectable(clanwar_1, 0);

	clanwar_2 = TextDrawCreate(325.000000, 192.000000, "THEBIGGESTCLANEVER ~r~VS ~w~THEWORSTCLANEVER");
	TextDrawFont(clanwar_2, 1);
	TextDrawLetterSize(clanwar_2, 0.270833, 1.700000);
	TextDrawTextSize(clanwar_2, 670.000000, 278.000000);
	TextDrawSetOutline(clanwar_2, 1);
	TextDrawSetShadow(clanwar_2, 0);
	TextDrawAlignment(clanwar_2, 2);
	TextDrawColor(clanwar_2, 255);
	TextDrawBackgroundColor(clanwar_2, 1296911871);
	TextDrawBoxColor(clanwar_2, 194);
	TextDrawUseBox(clanwar_2, 1);
	TextDrawSetProportional(clanwar_2, 1);
	TextDrawSetSelectable(clanwar_2, 0);

	standing[0] = TextDrawCreate(325.000000, 213.000000, "_");
	TextDrawFont(standing[0], 1);
	TextDrawLetterSize(standing[0], 0.270833, 1.700000);
	TextDrawTextSize(standing[0], 670.000000, 278.000000);
	TextDrawSetOutline(standing[0], 1);
	TextDrawSetShadow(standing[0], 0);
	TextDrawAlignment(standing[0], 2);
	TextDrawColor(standing[0], -1);
	TextDrawBackgroundColor(standing[0], 255);
	TextDrawBoxColor(standing[0], 50);
	TextDrawUseBox(standing[0], 1);
	TextDrawSetProportional(standing[0], 1);
	TextDrawSetSelectable(standing[0], 0);

	standing[1] = TextDrawCreate(325.000000, 231.000000, "_");
	TextDrawFont(standing[1], 1);
	TextDrawLetterSize(standing[1], 0.270833, 1.700000);
	TextDrawTextSize(standing[1], 670.000000, 278.000000);
	TextDrawSetOutline(standing[1], 1);
	TextDrawSetShadow(standing[1], 0);
	TextDrawAlignment(standing[1], 2);
	TextDrawColor(standing[1], -1);
	TextDrawBackgroundColor(standing[1], 255);
	TextDrawBoxColor(standing[1], 50);
	TextDrawUseBox(standing[1], 1);
	TextDrawSetProportional(standing[1], 1);
	TextDrawSetSelectable(standing[1], 0);

	standing[2] = TextDrawCreate(325.000000, 249.000000, "_");
	TextDrawFont(standing[2], 1);
	TextDrawLetterSize(standing[2], 0.270833, 1.700000);
	TextDrawTextSize(standing[2], 670.000000, 278.000000);
	TextDrawSetOutline(standing[2], 1);
	TextDrawSetShadow(standing[2], 0);
	TextDrawAlignment(standing[2], 2);
	TextDrawColor(standing[2], -1);
	TextDrawBackgroundColor(standing[2], 255);
	TextDrawBoxColor(standing[2], 50);
	TextDrawUseBox(standing[2], 1);
	TextDrawSetProportional(standing[2], 1);
	TextDrawSetSelectable(standing[2], 0);

	standing[3] = TextDrawCreate(325.000000, 267.000000, "_");
	TextDrawFont(standing[3], 1);
	TextDrawLetterSize(standing[3], 0.270833, 1.700000);
	TextDrawTextSize(standing[3], 670.000000, 278.000000);
	TextDrawSetOutline(standing[3], 1);
	TextDrawSetShadow(standing[3], 0);
	TextDrawAlignment(standing[3], 2);
	TextDrawColor(standing[3], -1);
	TextDrawBackgroundColor(standing[3], 255);
	TextDrawBoxColor(standing[3], 50);
	TextDrawUseBox(standing[3], 1);
	TextDrawSetProportional(standing[3], 1);
	TextDrawSetSelectable(standing[3], 0);

	standing[4] = TextDrawCreate(325.000000, 284.000000, "_");
	TextDrawFont(standing[4], 1);
	TextDrawLetterSize(standing[4], 0.270833, 1.700000);
	TextDrawTextSize(standing[4], 670.000000, 278.000000);
	TextDrawSetOutline(standing[4], 1);
	TextDrawSetShadow(standing[4], 0);
	TextDrawAlignment(standing[4], 2);
	TextDrawColor(standing[4], -1);
	TextDrawBackgroundColor(standing[4], 255);
	TextDrawBoxColor(standing[4], 50);
	TextDrawUseBox(standing[4], 1);
	TextDrawSetProportional(standing[4], 1);
	TextDrawSetSelectable(standing[4], 0);

	standing[5] = TextDrawCreate(325.000000, 301.000000, "_");
	TextDrawFont(standing[5], 1);
	TextDrawLetterSize(standing[5], 0.270833, 1.700000);
	TextDrawTextSize(standing[5], 670.000000, 278.000000);
	TextDrawSetOutline(standing[5], 1);
	TextDrawSetShadow(standing[5], 0);
	TextDrawAlignment(standing[5], 2);
	TextDrawColor(standing[5], -1);
	TextDrawBackgroundColor(standing[5], 255);
	TextDrawBoxColor(standing[5], 50);
	TextDrawUseBox(standing[5], 1);
	TextDrawSetProportional(standing[5], 1);
	TextDrawSetSelectable(standing[5], 0);

	standing[6] = TextDrawCreate(325.000000, 319.000000, "_");
	TextDrawFont(standing[6], 1);
	TextDrawLetterSize(standing[6], 0.270833, 1.700000);
	TextDrawTextSize(standing[6], 670.000000, 278.000000);
	TextDrawSetOutline(standing[6], 1);
	TextDrawSetShadow(standing[6], 0);
	TextDrawAlignment(standing[6], 2);
	TextDrawColor(standing[6], -1);
	TextDrawBackgroundColor(standing[6], 255);
	TextDrawBoxColor(standing[6], 50);
	TextDrawUseBox(standing[6], 1);
	TextDrawSetProportional(standing[6], 1);
	TextDrawSetSelectable(standing[6], 0);

	standing[7] = TextDrawCreate(325.000000, 337.000000, "_");
	TextDrawFont(standing[7], 1);
	TextDrawLetterSize(standing[7], 0.270833, 1.700000);
	TextDrawTextSize(standing[7], 670.000000, 278.000000);
	TextDrawSetOutline(standing[7], 1);
	TextDrawSetShadow(standing[7], 0);
	TextDrawAlignment(standing[7], 2);
	TextDrawColor(standing[7], -1);
	TextDrawBackgroundColor(standing[7], 255);
	TextDrawBoxColor(standing[7], 50);
	TextDrawUseBox(standing[7], 1);
	TextDrawSetProportional(standing[7], 1);
	TextDrawSetSelectable(standing[7], 0);

	//Clan adv

	CAdv_TD[0] = TextDrawCreate(114.799980, 129.380035, "box");
	TextDrawLetterSize(CAdv_TD[0], 0.000000, 2.880000);
	TextDrawTextSize(CAdv_TD[0], 514.799743, 0.000000);
	TextDrawAlignment(CAdv_TD[0], 1);
	TextDrawColor(CAdv_TD[0], -1);
	TextDrawUseBox(CAdv_TD[0], 1);
	TextDrawBoxColor(CAdv_TD[0], 50);
	TextDrawSetShadow(CAdv_TD[0], 0);
	TextDrawSetOutline(CAdv_TD[0], 0);
	TextDrawBackgroundColor(CAdv_TD[0], 100);
	TextDrawFont(CAdv_TD[0], 1);
	TextDrawSetProportional(CAdv_TD[0], 1);
	TextDrawSetShadow(CAdv_TD[0], 0);

	CAdv_TD[1] = TextDrawCreate(169.050872, 133.743164, "_");
	TextDrawLetterSize(CAdv_TD[1], 0.231199, 0.875733);
	TextDrawAlignment(CAdv_TD[1], 1);
	TextDrawColor(CAdv_TD[1], -1);
	TextDrawSetShadow(CAdv_TD[1], 0);
	TextDrawSetOutline(CAdv_TD[1], 0);
	TextDrawBackgroundColor(CAdv_TD[1], 255);
	TextDrawFont(CAdv_TD[1], 2);
	TextDrawSetProportional(CAdv_TD[1], 1);
	TextDrawSetShadow(CAdv_TD[1], 0);

	//===============================================================
	//PUBG TDs

	PUBGWinnerTD[0] = TextDrawCreate(-3.000000, -1.000000, "_");
	TextDrawFont(PUBGWinnerTD[0], 1);
	TextDrawLetterSize(PUBGWinnerTD[0], 0.600000, 50.300003);
	TextDrawTextSize(PUBGWinnerTD[0], 654.500000, 127.000000);
	TextDrawSetOutline(PUBGWinnerTD[0], 1);
	TextDrawSetShadow(PUBGWinnerTD[0], 0);
	TextDrawAlignment(PUBGWinnerTD[0], 1);
	TextDrawColor(PUBGWinnerTD[0], -1);
	TextDrawBackgroundColor(PUBGWinnerTD[0], 255);
	TextDrawBoxColor(PUBGWinnerTD[0], 135);
	TextDrawUseBox(PUBGWinnerTD[0], 1);
	TextDrawSetProportional(PUBGWinnerTD[0], 1);
	TextDrawSetSelectable(PUBGWinnerTD[0], 0);

	PUBGWinnerTD[1] = TextDrawCreate(33.000000, 124.000000, "H2O");
	TextDrawFont(PUBGWinnerTD[1], 2);
	TextDrawLetterSize(PUBGWinnerTD[1], 0.600000, 2.000000);
	TextDrawTextSize(PUBGWinnerTD[1], 400.000000, 17.000000);
	TextDrawSetOutline(PUBGWinnerTD[1], 0);
	TextDrawSetShadow(PUBGWinnerTD[1], 0);
	TextDrawAlignment(PUBGWinnerTD[1], 1);
	TextDrawColor(PUBGWinnerTD[1], -1);
	TextDrawBackgroundColor(PUBGWinnerTD[1], 255);
	TextDrawBoxColor(PUBGWinnerTD[1], 50);
	TextDrawUseBox(PUBGWinnerTD[1], 0);
	TextDrawSetProportional(PUBGWinnerTD[1], 1);
	TextDrawSetSelectable(PUBGWinnerTD[1], 0);

	PUBGWinnerTD[2] = TextDrawCreate(33.000000, 144.000000, "WINNER WINNER CHICKEN DINNER!");
	TextDrawFont(PUBGWinnerTD[2], 2);
	TextDrawLetterSize(PUBGWinnerTD[2], 0.600000, 2.000000);
	TextDrawTextSize(PUBGWinnerTD[2], 435.000000, 132.500000);
	TextDrawSetOutline(PUBGWinnerTD[2], 0);
	TextDrawSetShadow(PUBGWinnerTD[2], 0);
	TextDrawAlignment(PUBGWinnerTD[2], 1);
	TextDrawColor(PUBGWinnerTD[2], -294256385);
	TextDrawBackgroundColor(PUBGWinnerTD[2], 255);
	TextDrawBoxColor(PUBGWinnerTD[2], 50);
	TextDrawUseBox(PUBGWinnerTD[2], 0);
	TextDrawSetProportional(PUBGWinnerTD[2], 1);
	TextDrawSetSelectable(PUBGWinnerTD[2], 0);

	PUBGWinnerTD[3] = TextDrawCreate(33.000000, 164.000000, "~w~Kills: ~g~5000            ~w~REWARD: ~g~$500,000 & 100 Score");
	TextDrawFont(PUBGWinnerTD[3], 2);
	TextDrawLetterSize(PUBGWinnerTD[3], 0.420833, 2.000000);
	TextDrawTextSize(PUBGWinnerTD[3], 685.000000, 329.500000);
	TextDrawSetOutline(PUBGWinnerTD[3], 0);
	TextDrawSetShadow(PUBGWinnerTD[3], 0);
	TextDrawAlignment(PUBGWinnerTD[3], 1);
	TextDrawColor(PUBGWinnerTD[3], -294256385);
	TextDrawBackgroundColor(PUBGWinnerTD[3], 255);
	TextDrawBoxColor(PUBGWinnerTD[3], 50);
	TextDrawUseBox(PUBGWinnerTD[3], 0);
	TextDrawSetProportional(PUBGWinnerTD[3], 1);
	TextDrawSetSelectable(PUBGWinnerTD[3], 0);

	PUBGWinnerTD[4] = TextDrawCreate(26.000000, 186.000000, "o");
	TextDrawFont(PUBGWinnerTD[4], 1);
	TextDrawLetterSize(PUBGWinnerTD[4], 20.733312, 0.200000);
	TextDrawTextSize(PUBGWinnerTD[4], 400.000000, 17.000000);
	TextDrawSetOutline(PUBGWinnerTD[4], 0);
	TextDrawSetShadow(PUBGWinnerTD[4], 0);
	TextDrawAlignment(PUBGWinnerTD[4], 1);
	TextDrawColor(PUBGWinnerTD[4], -1);
	TextDrawBackgroundColor(PUBGWinnerTD[4], 255);
	TextDrawBoxColor(PUBGWinnerTD[4], 50);
	TextDrawUseBox(PUBGWinnerTD[4], 0);
	TextDrawSetProportional(PUBGWinnerTD[4], 1);
	TextDrawSetSelectable(PUBGWinnerTD[4], 0);

	PUBGAreaTD = TextDrawCreate(88.000000, 322.000000, "Restricting area in 4 minutes");
	TextDrawFont(PUBGAreaTD, 1);
	TextDrawLetterSize(PUBGAreaTD, 0.191667, 0.899999);
	TextDrawTextSize(PUBGAreaTD, 127.500000, 104.000000);
	TextDrawSetOutline(PUBGAreaTD, 1);
	TextDrawSetShadow(PUBGAreaTD, 0);
	TextDrawAlignment(PUBGAreaTD, 2);
	TextDrawColor(PUBGAreaTD, -1);
	TextDrawBackgroundColor(PUBGAreaTD, 255);
	TextDrawBoxColor(PUBGAreaTD, 50);
	TextDrawUseBox(PUBGAreaTD, 1);
	TextDrawSetProportional(PUBGAreaTD, 1);
	TextDrawSetSelectable(PUBGAreaTD, 0);

	PUBGKillsTD = TextDrawCreate(52.000000, 250.000000, "50 KILLED");
	TextDrawFont(PUBGKillsTD, 2);
	TextDrawLetterSize(PUBGKillsTD, 0.262499, 1.750000);
	TextDrawTextSize(PUBGKillsTD, 123.000000, 55.000000);
	TextDrawSetOutline(PUBGKillsTD, 0);
	TextDrawSetShadow(PUBGKillsTD, 0);
	TextDrawAlignment(PUBGKillsTD, 2);
	TextDrawColor(PUBGKillsTD, -1);
	TextDrawBackgroundColor(PUBGKillsTD, 255);
	TextDrawBoxColor(PUBGKillsTD, 145);
	TextDrawUseBox(PUBGKillsTD, 1);
	TextDrawSetProportional(PUBGKillsTD, 1);
	TextDrawSetSelectable(PUBGKillsTD, 0);

	PUBGAliveTD = TextDrawCreate(123.000000, 250.000000, "50 ALIVE");
	TextDrawFont(PUBGAliveTD, 2);
	TextDrawLetterSize(PUBGAliveTD, 0.262499, 1.750000);
	TextDrawTextSize(PUBGAliveTD, 123.000000, 55.000000);
	TextDrawSetOutline(PUBGAliveTD, 0);
	TextDrawSetShadow(PUBGAliveTD, 0);
	TextDrawAlignment(PUBGAliveTD, 2);
	TextDrawColor(PUBGAliveTD, -1);
	TextDrawBackgroundColor(PUBGAliveTD, 255);
	TextDrawBoxColor(PUBGAliveTD, 145);
	TextDrawUseBox(PUBGAliveTD, 1);
	TextDrawSetProportional(PUBGAliveTD, 1);
	TextDrawSetSelectable(PUBGAliveTD, 0);

	PUBGKillTD = TextDrawCreate(321.000000, 178.000000, "~r~H2O ~w~killed ~r~Broman ~w~with an MP5");
	TextDrawFont(PUBGKillTD, 2);
	TextDrawLetterSize(PUBGKillTD, 0.266667, 1.450000);
	TextDrawTextSize(PUBGKillTD, 400.000000, 387.000000);
	TextDrawSetOutline(PUBGKillTD, 0);
	TextDrawSetShadow(PUBGKillTD, 0);
	TextDrawAlignment(PUBGKillTD, 2);
	TextDrawColor(PUBGKillTD, -1);
	TextDrawBackgroundColor(PUBGKillTD, 255);
	TextDrawBoxColor(PUBGKillTD, 50);
	TextDrawUseBox(PUBGKillTD, 0);
	TextDrawSetProportional(PUBGKillTD, 1);
	TextDrawSetSelectable(PUBGKillTD, 0);

	//===============================================================
	//Car Information TDs

	CarInfoTD[0] = TextDrawCreate(311.000000, 142.000000, "_");
	TextDrawFont(CarInfoTD[0], 1);
	TextDrawLetterSize(CarInfoTD[0], 0.600000, 3.650000);
	TextDrawTextSize(CarInfoTD[0], 298.500000, 174.500000);
	TextDrawSetOutline(CarInfoTD[0], 1);
	TextDrawSetShadow(CarInfoTD[0], 0);
	TextDrawAlignment(CarInfoTD[0], 2);
	TextDrawColor(CarInfoTD[0], -1);
	TextDrawBackgroundColor(CarInfoTD[0], 255);
	TextDrawBoxColor(CarInfoTD[0], 255);
	TextDrawUseBox(CarInfoTD[0], 1);
	TextDrawSetProportional(CarInfoTD[0], 1);
	TextDrawSetSelectable(CarInfoTD[0], 0);

	CarInfoTD[1] = TextDrawCreate(311.000000, 144.000000, "_");
	TextDrawFont(CarInfoTD[1], 1);
	TextDrawLetterSize(CarInfoTD[1], 0.600000, 3.250000);
	TextDrawTextSize(CarInfoTD[1], 298.500000, 174.500000);
	TextDrawSetOutline(CarInfoTD[1], 1);
	TextDrawSetShadow(CarInfoTD[1], 0);
	TextDrawAlignment(CarInfoTD[1], 2);
	TextDrawColor(CarInfoTD[1], -1);
	TextDrawBackgroundColor(CarInfoTD[1], 255);
	TextDrawBoxColor(CarInfoTD[1], 1296911791);
	TextDrawUseBox(CarInfoTD[1], 1);
	TextDrawSetProportional(CarInfoTD[1], 1);
	TextDrawSetSelectable(CarInfoTD[1], 0);

	CarInfoTD[2] = TextDrawCreate(389.000000, 135.000000, "ld_chat:badchat");
	TextDrawFont(CarInfoTD[2], 4);
	TextDrawLetterSize(CarInfoTD[2], 0.600000, 2.000000);
	TextDrawTextSize(CarInfoTD[2], 17.000000, 17.000000);
	TextDrawSetOutline(CarInfoTD[2], 1);
	TextDrawSetShadow(CarInfoTD[2], 0);
	TextDrawAlignment(CarInfoTD[2], 1);
	TextDrawColor(CarInfoTD[2], -1);
	TextDrawBackgroundColor(CarInfoTD[2], 255);
	TextDrawBoxColor(CarInfoTD[2], 50);
	TextDrawUseBox(CarInfoTD[2], 1);
	TextDrawSetProportional(CarInfoTD[2], 1);
	TextDrawSetSelectable(CarInfoTD[2], 0);

	CarInfoTD[3] = TextDrawCreate(242.000000, 153.000000, "\\");
	TextDrawFont(CarInfoTD[3], 1);
	TextDrawLetterSize(CarInfoTD[3], 0.195832, 0.899999);
	TextDrawTextSize(CarInfoTD[3], 400.000000, 180.500000);
	TextDrawSetOutline(CarInfoTD[3], 1);
	TextDrawSetShadow(CarInfoTD[3], 0);
	TextDrawAlignment(CarInfoTD[3], 2);
	TextDrawColor(CarInfoTD[3], -1523963137);
	TextDrawBackgroundColor(CarInfoTD[3], 255);
	TextDrawBoxColor(CarInfoTD[3], 1097457995);
	TextDrawUseBox(CarInfoTD[3], 0);
	TextDrawSetProportional(CarInfoTD[3], 1);
	TextDrawSetSelectable(CarInfoTD[3], 0);

	//===============================================================
	//Spec TDs

	aSpecTD[0] = TextDrawCreate(319.000000, 360.000000, "_");
	TextDrawFont(aSpecTD[0], 1);
	TextDrawLetterSize(aSpecTD[0], 0.600000, 4.699991);
	TextDrawTextSize(aSpecTD[0], 302.500000, 117.500000);
	TextDrawSetOutline(aSpecTD[0], 1);
	TextDrawSetShadow(aSpecTD[0], 0);
	TextDrawAlignment(aSpecTD[0], 2);
	TextDrawColor(aSpecTD[0], -1);
	TextDrawBackgroundColor(aSpecTD[0], 255);
	TextDrawBoxColor(aSpecTD[0], -1094795596);
	TextDrawUseBox(aSpecTD[0], 1);
	TextDrawSetProportional(aSpecTD[0], 1);
	TextDrawSetSelectable(aSpecTD[0], 0);

	aSpecTD[1] = TextDrawCreate(370.000000, 358.000000, "LD_Beat:cross");
	TextDrawFont(aSpecTD[1], 4);
	TextDrawLetterSize(aSpecTD[1], 0.600000, 2.000000);
	TextDrawTextSize(aSpecTD[1], 10.500000, 11.000000);
	TextDrawSetOutline(aSpecTD[1], 1);
	TextDrawSetShadow(aSpecTD[1], 0);
	TextDrawAlignment(aSpecTD[1], 1);
	TextDrawColor(aSpecTD[1], -1);
	TextDrawBackgroundColor(aSpecTD[1], 255);
	TextDrawBoxColor(aSpecTD[1], 50);
	TextDrawUseBox(aSpecTD[1], 1);
	TextDrawSetProportional(aSpecTD[1], 1);
	TextDrawSetSelectable(aSpecTD[1], 1);

	aSpecTD[2] = TextDrawCreate(246.000000, 360.000000, "_");
	TextDrawFont(aSpecTD[2], 1);
	TextDrawLetterSize(aSpecTD[2], 0.600000, 4.699991);
	TextDrawTextSize(aSpecTD[2], 302.500000, 14.000000);
	TextDrawSetOutline(aSpecTD[2], 1);
	TextDrawSetShadow(aSpecTD[2], 0);
	TextDrawAlignment(aSpecTD[2], 2);
	TextDrawColor(aSpecTD[2], -1);
	TextDrawBackgroundColor(aSpecTD[2], 255);
	TextDrawBoxColor(aSpecTD[2], -1094795596);
	TextDrawUseBox(aSpecTD[2], 1);
	TextDrawSetProportional(aSpecTD[2], 1);
	TextDrawSetSelectable(aSpecTD[2], 0);

	aSpecTD[3] = TextDrawCreate(392.000000, 360.000000, "_");
	TextDrawFont(aSpecTD[3], 1);
	TextDrawLetterSize(aSpecTD[3], 0.600000, 4.699991);
	TextDrawTextSize(aSpecTD[3], 302.500000, 14.000000);
	TextDrawSetOutline(aSpecTD[3], 1);
	TextDrawSetShadow(aSpecTD[3], 0);
	TextDrawAlignment(aSpecTD[3], 2);
	TextDrawColor(aSpecTD[3], -1);
	TextDrawBackgroundColor(aSpecTD[3], 255);
	TextDrawBoxColor(aSpecTD[3], -1094795596);
	TextDrawUseBox(aSpecTD[3], 1);
	TextDrawSetProportional(aSpecTD[3], 1);
	TextDrawSetSelectable(aSpecTD[3], 0);

	aSpecTD[4] = TextDrawCreate(239.000000, 372.000000, "LD_BEAT:left");
	TextDrawFont(aSpecTD[4], 4);
	TextDrawLetterSize(aSpecTD[4], 0.600000, 2.000000);
	TextDrawTextSize(aSpecTD[4], 13.500000, 18.500000);
	TextDrawSetOutline(aSpecTD[4], 1);
	TextDrawSetShadow(aSpecTD[4], 0);
	TextDrawAlignment(aSpecTD[4], 1);
	TextDrawColor(aSpecTD[4], -1);
	TextDrawBackgroundColor(aSpecTD[4], 255);
	TextDrawBoxColor(aSpecTD[4], 50);
	TextDrawUseBox(aSpecTD[4], 1);
	TextDrawSetProportional(aSpecTD[4], 1);
	TextDrawSetSelectable(aSpecTD[4], 1);

	aSpecTD[5] = TextDrawCreate(386.000000, 372.000000, "LD_BEAT:right");
	TextDrawFont(aSpecTD[5], 4);
	TextDrawLetterSize(aSpecTD[5], 0.600000, 2.000000);
	TextDrawTextSize(aSpecTD[5], 13.500000, 18.500000);
	TextDrawSetOutline(aSpecTD[5], 1);
	TextDrawSetShadow(aSpecTD[5], 0);
	TextDrawAlignment(aSpecTD[5], 1);
	TextDrawColor(aSpecTD[5], -1);
	TextDrawBackgroundColor(aSpecTD[5], 255);
	TextDrawBoxColor(aSpecTD[5], 50);
	TextDrawUseBox(aSpecTD[5], 1);
	TextDrawSetProportional(aSpecTD[5], 1);
	TextDrawSetSelectable(aSpecTD[5], 1);

	aSpecTD[6] = TextDrawCreate(319.000000, 409.000000, "_");
	TextDrawFont(aSpecTD[6], 1);
	TextDrawLetterSize(aSpecTD[6], 0.550000, 1.449991);
	TextDrawTextSize(aSpecTD[6], 302.500000, 160.000000);
	TextDrawSetOutline(aSpecTD[6], 1);
	TextDrawSetShadow(aSpecTD[6], 0);
	TextDrawAlignment(aSpecTD[6], 2);
	TextDrawColor(aSpecTD[6], -1);
	TextDrawBackgroundColor(aSpecTD[6], 255);
	TextDrawBoxColor(aSpecTD[6], -1094795596);
	TextDrawUseBox(aSpecTD[6], 1);
	TextDrawSetProportional(aSpecTD[6], 1);
	TextDrawSetSelectable(aSpecTD[6], 0);

	aSpecTD[7] = TextDrawCreate(240.000000, 411.000000, "WEAPS");
	TextDrawFont(aSpecTD[7], 2);
	TextDrawLetterSize(aSpecTD[7], 0.183333, 0.900000);
	TextDrawTextSize(aSpecTD[7], 266.000000, 17.000000);
	TextDrawSetOutline(aSpecTD[7], 1);
	TextDrawSetShadow(aSpecTD[7], 0);
	TextDrawAlignment(aSpecTD[7], 1);
	TextDrawColor(aSpecTD[7], -1);
	TextDrawBackgroundColor(aSpecTD[7], 255);
	TextDrawBoxColor(aSpecTD[7], 50);
	TextDrawUseBox(aSpecTD[7], 0);
	TextDrawSetProportional(aSpecTD[7], 1);
	TextDrawSetSelectable(aSpecTD[7], 1);

	aSpecTD[8] = TextDrawCreate(273.000000, 411.000000, "Items");
	TextDrawFont(aSpecTD[8], 2);
	TextDrawLetterSize(aSpecTD[8], 0.183333, 0.900000);
	TextDrawTextSize(aSpecTD[8], 295.000000, 17.000000);
	TextDrawSetOutline(aSpecTD[8], 1);
	TextDrawSetShadow(aSpecTD[8], 0);
	TextDrawAlignment(aSpecTD[8], 1);
	TextDrawColor(aSpecTD[8], -1);
	TextDrawBackgroundColor(aSpecTD[8], 255);
	TextDrawBoxColor(aSpecTD[8], 50);
	TextDrawUseBox(aSpecTD[8], 0);
	TextDrawSetProportional(aSpecTD[8], 1);
	TextDrawSetSelectable(aSpecTD[8], 1);

	aSpecTD[9] = TextDrawCreate(302.000000, 411.000000, "BSTATS");
	TextDrawFont(aSpecTD[9], 2);
	TextDrawLetterSize(aSpecTD[9], 0.183333, 0.900000);
	TextDrawTextSize(aSpecTD[9], 331.000000, 17.000000);
	TextDrawSetOutline(aSpecTD[9], 1);
	TextDrawSetShadow(aSpecTD[9], 0);
	TextDrawAlignment(aSpecTD[9], 1);
	TextDrawColor(aSpecTD[9], -1);
	TextDrawBackgroundColor(aSpecTD[9], 255);
	TextDrawBoxColor(aSpecTD[9], 50);
	TextDrawUseBox(aSpecTD[9], 0);
	TextDrawSetProportional(aSpecTD[9], 1);
	TextDrawSetSelectable(aSpecTD[9], 1);

	aSpecTD[10] = TextDrawCreate(338.000000, 411.000000, "Info");
	TextDrawFont(aSpecTD[10], 2);
	TextDrawLetterSize(aSpecTD[10], 0.183333, 0.900000);
	TextDrawTextSize(aSpecTD[10], 355.000000, 17.000000);
	TextDrawSetOutline(aSpecTD[10], 1);
	TextDrawSetShadow(aSpecTD[10], 0);
	TextDrawAlignment(aSpecTD[10], 1);
	TextDrawColor(aSpecTD[10], -1);
	TextDrawBackgroundColor(aSpecTD[10], 255);
	TextDrawBoxColor(aSpecTD[10], 50);
	TextDrawUseBox(aSpecTD[10], 0);
	TextDrawSetProportional(aSpecTD[10], 1);
	TextDrawSetSelectable(aSpecTD[10], 1);

	aSpecTD[11] = TextDrawCreate(362.000000, 411.000000, "Panel");
	TextDrawFont(aSpecTD[11], 2);
	TextDrawLetterSize(aSpecTD[11], 0.183333, 0.900000);
	TextDrawTextSize(aSpecTD[11], 387.000000, 17.000000);
	TextDrawSetOutline(aSpecTD[11], 1);
	TextDrawSetShadow(aSpecTD[11], 0);
	TextDrawAlignment(aSpecTD[11], 1);
	TextDrawColor(aSpecTD[11], -1);
	TextDrawBackgroundColor(aSpecTD[11], 255);
	TextDrawBoxColor(aSpecTD[11], 50);
	TextDrawUseBox(aSpecTD[11], 0);
	TextDrawSetProportional(aSpecTD[11], 1);
	TextDrawSetSelectable(aSpecTD[11], 1);

	//===============================================================
	//Stats TDs

	Stats_TD[0] = TextDrawCreate(320.399902, 187.013320, "box");
	TextDrawLetterSize(Stats_TD[0], 0.000000, 11.999999);
	TextDrawTextSize(Stats_TD[0], 0.000000, 315.000000);
	TextDrawAlignment(Stats_TD[0], 2);
	TextDrawColor(Stats_TD[0], -1);
	TextDrawUseBox(Stats_TD[0], 1);
	TextDrawBoxColor(Stats_TD[0], 255);
	TextDrawSetShadow(Stats_TD[0], 0);
	TextDrawBackgroundColor(Stats_TD[0], 255);
	TextDrawFont(Stats_TD[0], 1);
	TextDrawSetProportional(Stats_TD[0], 1);

	Stats_TD[1] = TextDrawCreate(162.799942, 187.760025, "box");
	TextDrawLetterSize(Stats_TD[1], 0.000000, 11.759998);
	TextDrawTextSize(Stats_TD[1], 478.000000, 0.000000);
	TextDrawAlignment(Stats_TD[1], 1);
	TextDrawColor(Stats_TD[1], -1);
	TextDrawUseBox(Stats_TD[1], 1);
	TextDrawBoxColor(Stats_TD[1], -2109750253);
	TextDrawSetShadow(Stats_TD[1], 0);
	TextDrawBackgroundColor(Stats_TD[1], 255);
	TextDrawFont(Stats_TD[1], 1);
	TextDrawSetProportional(Stats_TD[1], 1);

	Stats_TD[2] = TextDrawCreate(438.599914, 274.466735, "LD_BEAT:left");
	TextDrawTextSize(Stats_TD[2], 16.000000, 20.000000);
	TextDrawAlignment(Stats_TD[2], 1);
	TextDrawColor(Stats_TD[2], -1);
	TextDrawSetShadow(Stats_TD[2], 0);
	TextDrawBackgroundColor(Stats_TD[2], 255);
	TextDrawFont(Stats_TD[2], 4);
	TextDrawSetProportional(Stats_TD[2], 0);
	TextDrawSetSelectable(Stats_TD[2], true);

	Stats_TD[3] = TextDrawCreate(460.999938, 274.466735, "LD_BEAT:right");
	TextDrawTextSize(Stats_TD[3], 16.000000, 20.000000);
	TextDrawAlignment(Stats_TD[3], 1);
	TextDrawColor(Stats_TD[3], -1);
	TextDrawSetShadow(Stats_TD[3], 0);
	TextDrawBackgroundColor(Stats_TD[3], 255);
	TextDrawFont(Stats_TD[3], 4);
	TextDrawSetProportional(Stats_TD[3], 0);
	TextDrawSetSelectable(Stats_TD[3], true);

	Stats_TD[4] = TextDrawCreate(463.399963, 188.600143, "LD_BEAT:cross");
	TextDrawTextSize(Stats_TD[4], 15.000000, 17.000000);
	TextDrawAlignment(Stats_TD[4], 1);
	TextDrawColor(Stats_TD[4], -1);
	TextDrawSetShadow(Stats_TD[4], 0);
	TextDrawBackgroundColor(Stats_TD[4], 255);
	TextDrawFont(Stats_TD[4], 4);
	TextDrawSetProportional(Stats_TD[4], 0);
	TextDrawSetSelectable(Stats_TD[4], true);

	Stats_TD[5] = TextDrawCreate(245.200012, 205.680038, "o");
	TextDrawLetterSize(Stats_TD[5], 7.507999, 0.248533);
	TextDrawTextSize(Stats_TD[5], 34.000000, 0.000000);
	TextDrawAlignment(Stats_TD[5], 1);
	TextDrawColor(Stats_TD[5], -1);
	TextDrawSetShadow(Stats_TD[5], 0);
	TextDrawBackgroundColor(Stats_TD[5], 255);
	TextDrawFont(Stats_TD[5], 1);
	TextDrawSetProportional(Stats_TD[5], 1);

	//===============================================================
	//Site TD

	Site_TD = TextDrawCreate(547.000000, 32.000000, "h2omultiplayer.com");
	TextDrawFont(Site_TD, 1);
	TextDrawLetterSize(Site_TD, 0.154167, 0.800000);
	TextDrawTextSize(Site_TD, 600.000000, 17.000000);
	TextDrawSetOutline(Site_TD, 1);
	TextDrawSetShadow(Site_TD, 0);
	TextDrawAlignment(Site_TD, 1);
	TextDrawColor(Site_TD, -1);
	TextDrawBackgroundColor(Site_TD, 255);
	TextDrawBoxColor(Site_TD, 50);
	TextDrawUseBox(Site_TD, 0);
	TextDrawSetProportional(Site_TD, 1);
	TextDrawSetSelectable(Site_TD, 0);

	//TWTD

	WarTD = TextDrawCreate(318.000000, 435.000000, "Team War: ~p~~h~x ~w~vs ~y~y");
	TextDrawFont(WarTD, 1);
	TextDrawLetterSize(WarTD, 0.258333, 1.250000);
	TextDrawTextSize(WarTD, 595.000000, 156.000000);
	TextDrawSetOutline(WarTD, 1);
	TextDrawSetShadow(WarTD, 0);
	TextDrawAlignment(WarTD, 2);
	TextDrawColor(WarTD, -1);
	TextDrawBackgroundColor(WarTD, 255);
	TextDrawBoxColor(WarTD, 50);
	TextDrawUseBox(WarTD, 1);
	TextDrawSetProportional(WarTD, 1);
	TextDrawSetSelectable(WarTD, 0);

	//Stats
	StatsDotTD = TextDrawCreate(565.000000, 115.000000, ".");
	TextDrawFont(StatsDotTD, 1);
	TextDrawLetterSize(StatsDotTD, 9.308331, 0.449999);
	TextDrawTextSize(StatsDotTD, 400.000000, 17.000000);
	TextDrawSetOutline(StatsDotTD, 0);
	TextDrawSetShadow(StatsDotTD, 0);
	TextDrawAlignment(StatsDotTD, 2);
	TextDrawColor(StatsDotTD, X11_ORANGE);
	TextDrawBackgroundColor(StatsDotTD, 255);
	TextDrawBoxColor(StatsDotTD, 50);
	TextDrawUseBox(StatsDotTD, 0);
	TextDrawSetProportional(StatsDotTD, 1);
	TextDrawSetSelectable(StatsDotTD, 0);

	//===============================================================
	//DM Textdraws

	DMBox = TextDrawCreate(424.137634, 47.583335, "usebox");
	TextDrawLetterSize(DMBox, 0.000000, 1.692592);
	TextDrawTextSize(DMBox, 227.575408, 0.000000);
	TextDrawAlignment(DMBox, 1);
	TextDrawColor(DMBox, 0);
	TextDrawUseBox(DMBox, true);
	TextDrawBoxColor(DMBox, 102);
	TextDrawSetShadow(DMBox, 0);
	TextDrawSetOutline(DMBox, 0);
	TextDrawFont(DMBox, 0);

	DMText = TextDrawCreate(236.603118, 47.249961, "ELIMINATE ALL ENEMIES");
	TextDrawLetterSize(DMText, 0.449999, 1.600000);
	TextDrawAlignment(DMText, 1);
	TextDrawColor(DMText, -1);
	TextDrawSetShadow(DMText, 0);
	TextDrawSetOutline(DMText, 1);
	TextDrawBackgroundColor(DMText, 51);
	TextDrawFont(DMText, 1);
	TextDrawSetProportional(DMText, 1);

	DMText2[0] = TextDrawCreate(96.000000, 171.000000, "_");
	TextDrawFont(DMText2[0], 1);
	TextDrawLetterSize(DMText2[0], 0.600000, 10.300003);
	TextDrawTextSize(DMText2[0], 410.500000, 116.000000);
	TextDrawSetOutline(DMText2[0], 1);
	TextDrawSetShadow(DMText2[0], 0);
	TextDrawAlignment(DMText2[0], 2);
	TextDrawColor(DMText2[0], -1);
	TextDrawBackgroundColor(DMText2[0], 255);
	TextDrawBoxColor(DMText2[0], 135);
	TextDrawUseBox(DMText2[0], 1);
	TextDrawSetProportional(DMText2[0], 1);
	TextDrawSetSelectable(DMText2[0], 0);

	DMText2[1] = TextDrawCreate(107.000000, 182.000000, ".");
	TextDrawFont(DMText2[1], 1);
	TextDrawLetterSize(DMText2[1], 13.116702, 0.350001);
	TextDrawTextSize(DMText2[1], 400.000000, 17.000000);
	TextDrawSetOutline(DMText2[1], 0);
	TextDrawSetShadow(DMText2[1], 0);
	TextDrawAlignment(DMText2[1], 2);
	TextDrawColor(DMText2[1], -1);
	TextDrawBackgroundColor(DMText2[1], 255);
	TextDrawBoxColor(DMText2[1], 50);
	TextDrawUseBox(DMText2[1], 0);
	TextDrawSetProportional(DMText2[1], 1);
	TextDrawSetSelectable(DMText2[1], 0);

	DMText2[2] = TextDrawCreate(38.000000, 166.000000, "Top Deathmatchers");
	TextDrawFont(DMText2[2], 2);
	TextDrawLetterSize(DMText2[2], 0.254167, 2.000000);
	TextDrawTextSize(DMText2[2], 400.000000, 17.000000);
	TextDrawSetOutline(DMText2[2], 1);
	TextDrawSetShadow(DMText2[2], 0);
	TextDrawAlignment(DMText2[2], 1);
	TextDrawColor(DMText2[2], -1);
	TextDrawBackgroundColor(DMText2[2], 255);
	TextDrawBoxColor(DMText2[2], 50);
	TextDrawUseBox(DMText2[2], 0);
	TextDrawSetProportional(DMText2[2], 1);
	TextDrawSetSelectable(DMText2[2], 0);

	DMText2[3] = TextDrawCreate(38.000000, 185.000000, "_");
	TextDrawFont(DMText2[3], 1);
	TextDrawLetterSize(DMText2[3], 0.220833, 1.600000);
	TextDrawTextSize(DMText2[3], 400.000000, 17.000000);
	TextDrawSetOutline(DMText2[3], 1);
	TextDrawSetShadow(DMText2[3], 0);
	TextDrawAlignment(DMText2[3], 1);
	TextDrawColor(DMText2[3], -1);
	TextDrawBackgroundColor(DMText2[3], 255);
	TextDrawBoxColor(DMText2[3], 50);
	TextDrawUseBox(DMText2[3], 0);
	TextDrawSetProportional(DMText2[3], 1);
	TextDrawSetSelectable(DMText2[3], 0);
	return 1;
}

RemoveUI() {
	for (new i = 0; i < sizeof(SvTTD); i++) {
		TextDrawDestroy(SvTTD[i]);
	}

	for (new i = 0; i < sizeof(Stats_TD); i++) {
		TextDrawDestroy(Stats_TD[i]);
	}
	for (new i = 0; i < sizeof(aSpecTD); i++) {
		TextDrawDestroy(aSpecTD[i]);
	}
	for (new i = 0; i < sizeof(PUBGWinnerTD); i++) {
		TextDrawDestroy(PUBGWinnerTD[i]);
	}

	TextDrawDestroy(PUBGAreaTD);
	TextDrawDestroy(PUBGKillsTD);
	TextDrawDestroy(PUBGAliveTD);
	TextDrawDestroy(PUBGKillTD);
	TextDrawDestroy(CarInfoTD[0]);
	TextDrawDestroy(CarInfoTD[1]);
	TextDrawDestroy(CarInfoTD[2]);
	TextDrawDestroy(CarInfoTD[3]);
	TextDrawDestroy(Site_TD);
	TextDrawDestroy(DMText);
	TextDrawDestroy(DMText2[0]);
	TextDrawDestroy(DMText2[1]);
	TextDrawDestroy(DMText2[2]);
	TextDrawDestroy(DMText2[3]);
	TextDrawDestroy(DMBox);

	TextDrawDestroy(CAdv_TD[0]);
	TextDrawDestroy(CAdv_TD[1]);

	TextDrawDestroy(CWTD_1);
	TextDrawDestroy(CWTD_2);
	TextDrawDestroy(CWTD_3);

	TextDrawDestroy(selectdraw_0);
	TextDrawDestroy(selectdraw_1);

	for (new i = 0; i < sizeof(WarStatusTD); i++) {
		TextDrawDestroy(WarStatusTD[i]);
	}

	for (new i = 0; i < sizeof(BoxTD); i++) {
		TextDrawDestroy(BoxTD[i]);
	}

	TextDrawDestroy(WarTD);

	TextDrawDestroy(clanwar_0);
	TextDrawDestroy(clanwar_1);
	TextDrawDestroy(clanwar_2);
	TextDrawDestroy(standing[0]);
	TextDrawDestroy(standing[1]);
	TextDrawDestroy(standing[2]);
	TextDrawDestroy(standing[3]);
	TextDrawDestroy(standing[4]);
	TextDrawDestroy(standing[5]);
	TextDrawDestroy(standing[6]);
	TextDrawDestroy(standing[7]);

	TextDrawDestroy(StatsDotTD);
	return 1;
}

CreatePlayerUI(playerid) {
	//RankStats
	pRankStats[playerid] = CreatePlayerTextDraw(playerid, 560.000000, 103.000000, "_");
	PlayerTextDrawFont(playerid, pRankStats[playerid], 2);
	PlayerTextDrawLetterSize(playerid, pRankStats[playerid], 0.183333, 1.100000);
	PlayerTextDrawTextSize(playerid, pRankStats[playerid], 535.000000, 153.000000);
	PlayerTextDrawSetOutline(playerid, pRankStats[playerid], 0);
	PlayerTextDrawSetShadow(playerid, pRankStats[playerid], 0);
	PlayerTextDrawAlignment(playerid, pRankStats[playerid], 2);
	PlayerTextDrawColor(playerid, pRankStats[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, pRankStats[playerid], 255);
	PlayerTextDrawBoxColor(playerid, pRankStats[playerid], 50);
	PlayerTextDrawUseBox(playerid, pRankStats[playerid], 0);
	PlayerTextDrawSetProportional(playerid, pRankStats[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, pRankStats[playerid], 0);

	//Selection
	selectdraw_3[playerid] = CreatePlayerTextDraw(playerid, 506.000000, 203.000000, "~r~Terrorists");
	PlayerTextDrawFont(playerid, selectdraw_3[playerid], 2);
	PlayerTextDrawLetterSize(playerid, selectdraw_3[playerid], 0.145833, 1.000000);
	PlayerTextDrawTextSize(playerid, selectdraw_3[playerid], 591.500000, 172.500000);
	PlayerTextDrawSetOutline(playerid, selectdraw_3[playerid], 1);
	PlayerTextDrawSetShadow(playerid, selectdraw_3[playerid], 0);
	PlayerTextDrawAlignment(playerid, selectdraw_3[playerid], 2);
	PlayerTextDrawColor(playerid, selectdraw_3[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, selectdraw_3[playerid], 255);
	PlayerTextDrawBoxColor(playerid, selectdraw_3[playerid], 50);
	PlayerTextDrawUseBox(playerid, selectdraw_3[playerid], 0);
	PlayerTextDrawSetProportional(playerid, selectdraw_3[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, selectdraw_3[playerid], 0);

	selectdraw_4[playerid] = CreatePlayerTextDraw(playerid, 506.000000, 209.000000, "Sniper Class");
	PlayerTextDrawFont(playerid, selectdraw_4[playerid], 0);
	PlayerTextDrawLetterSize(playerid, selectdraw_4[playerid], 0.195833, 1.000000);
	PlayerTextDrawTextSize(playerid, selectdraw_4[playerid], 591.500000, 172.500000);
	PlayerTextDrawSetOutline(playerid, selectdraw_4[playerid], 1);
	PlayerTextDrawSetShadow(playerid, selectdraw_4[playerid], 0);
	PlayerTextDrawAlignment(playerid, selectdraw_4[playerid], 2);
	PlayerTextDrawColor(playerid, selectdraw_4[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, selectdraw_4[playerid], 255);
	PlayerTextDrawBoxColor(playerid, selectdraw_4[playerid], 50);
	PlayerTextDrawUseBox(playerid, selectdraw_4[playerid], 0);
	PlayerTextDrawSetProportional(playerid, selectdraw_4[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, selectdraw_4[playerid], 0);

	selectdraw_5[playerid] = CreatePlayerTextDraw(playerid, 506.000000, 225.000000, "Desert Eagle[24], AK-47[240], Sniper[24], Tear Gas[1]");
	PlayerTextDrawFont(playerid, selectdraw_5[playerid], 1);
	PlayerTextDrawLetterSize(playerid, selectdraw_5[playerid], 0.120833, 0.900000);
	PlayerTextDrawTextSize(playerid, selectdraw_5[playerid], 591.500000, 172.500000);
	PlayerTextDrawSetOutline(playerid, selectdraw_5[playerid], 1);
	PlayerTextDrawSetShadow(playerid, selectdraw_5[playerid], 0);
	PlayerTextDrawAlignment(playerid, selectdraw_5[playerid], 2);
	PlayerTextDrawColor(playerid, selectdraw_5[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, selectdraw_5[playerid], 255);
	PlayerTextDrawBoxColor(playerid, selectdraw_5[playerid], 50);
	PlayerTextDrawUseBox(playerid, selectdraw_5[playerid], 0);
	PlayerTextDrawSetProportional(playerid, selectdraw_5[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, selectdraw_5[playerid], 0);

	selectdraw_6[playerid] = CreatePlayerTextDraw(playerid, 442.000000, 265.000000, "You are able to use this command and this ability so be it.");
	PlayerTextDrawFont(playerid, selectdraw_6[playerid], 1);
	PlayerTextDrawLetterSize(playerid, selectdraw_6[playerid], 0.120833, 0.900000);
	PlayerTextDrawTextSize(playerid, selectdraw_6[playerid], 591.500000, 172.500000);
	PlayerTextDrawSetOutline(playerid, selectdraw_6[playerid], 1);
	PlayerTextDrawSetShadow(playerid, selectdraw_6[playerid], 0);
	PlayerTextDrawAlignment(playerid, selectdraw_6[playerid], 1);
	PlayerTextDrawColor(playerid, selectdraw_6[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, selectdraw_6[playerid], 255);
	PlayerTextDrawBoxColor(playerid, selectdraw_6[playerid], 50);
	PlayerTextDrawUseBox(playerid, selectdraw_6[playerid], 0);
	PlayerTextDrawSetProportional(playerid, selectdraw_6[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, selectdraw_6[playerid], 0);

	//Selection bar
	Player_SelectionBar[playerid] = CreatePlayerProgressBar(playerid, 442.000000, 187.000000, 127.5, 8.5, 0xB9C9BFFF, 100.0, BAR_DIRECTION_RIGHT);

	//CW Progress Bars
	CW_PBAR[playerid][0] = CreatePlayerProgressBar(playerid, 533.000000, 272.000000, 100.0, 8.5, 0xB9C9BFFF, 100.0, BAR_DIRECTION_RIGHT);
	CW_PBAR[playerid][1] = CreatePlayerProgressBar(playerid, 533.000000, 303.000000, 100.0, 8.5, 0xB9C9BFFF, 100.0, BAR_DIRECTION_RIGHT);
	CW_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 582.000000, 270.000000, "100%");
	PlayerTextDrawFont(playerid, CW_PTD[playerid][0], 1);
	PlayerTextDrawLetterSize(playerid, CW_PTD[playerid][0], 0.233333, 1.100000);
	PlayerTextDrawTextSize(playerid, CW_PTD[playerid][0], 678.500000, 272.000000);
	PlayerTextDrawSetOutline(playerid, CW_PTD[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, CW_PTD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, CW_PTD[playerid][0], 2);
	PlayerTextDrawColor(playerid, CW_PTD[playerid][0], -1);
	PlayerTextDrawBackgroundColor(playerid, CW_PTD[playerid][0], 255);
	PlayerTextDrawBoxColor(playerid, CW_PTD[playerid][0], 50);
	PlayerTextDrawUseBox(playerid, CW_PTD[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid, CW_PTD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, CW_PTD[playerid][0], 0);

	CW_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 582.000000, 301.000000, "100%");
	PlayerTextDrawFont(playerid, CW_PTD[playerid][1], 1);
	PlayerTextDrawLetterSize(playerid, CW_PTD[playerid][1], 0.233333, 1.100000);
	PlayerTextDrawTextSize(playerid, CW_PTD[playerid][1], 678.500000, 272.000000);
	PlayerTextDrawSetOutline(playerid, CW_PTD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, CW_PTD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, CW_PTD[playerid][1], 2);
	PlayerTextDrawColor(playerid, CW_PTD[playerid][1], -1);
	PlayerTextDrawBackgroundColor(playerid, CW_PTD[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, CW_PTD[playerid][1], 50);
	PlayerTextDrawUseBox(playerid, CW_PTD[playerid][1], 0);
	PlayerTextDrawSetProportional(playerid, CW_PTD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, CW_PTD[playerid][1], 0);

	//Stats textdraws
	Stats_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 320.399597, 187.012878, "_");
	PlayerTextDrawLetterSize(playerid, Stats_PTD[playerid][0], 0.501599, 1.883733);
	PlayerTextDrawTextSize(playerid, Stats_PTD[playerid][0], 0.000000, 230.000000);
	PlayerTextDrawAlignment(playerid, Stats_PTD[playerid][0], 2);
	PlayerTextDrawColor(playerid, Stats_PTD[playerid][0], -1);
	PlayerTextDrawSetShadow(playerid, Stats_PTD[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, Stats_PTD[playerid][0], 1);
	PlayerTextDrawBackgroundColor(playerid, Stats_PTD[playerid][0], 255);
	PlayerTextDrawFont(playerid, Stats_PTD[playerid][0], 3);
	PlayerTextDrawSetProportional(playerid, Stats_PTD[playerid][0], 1);

	Stats_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 165.999984, 215.386611, "_");
	PlayerTextDrawLetterSize(playerid, Stats_PTD[playerid][1], 0.232799, 0.927999);
	PlayerTextDrawTextSize(playerid, Stats_PTD[playerid][1], 331.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, Stats_PTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, Stats_PTD[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, Stats_PTD[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, Stats_PTD[playerid][1], -1);
	PlayerTextDrawBackgroundColor(playerid, Stats_PTD[playerid][1], 255);
	PlayerTextDrawFont(playerid, Stats_PTD[playerid][1], 2);
	PlayerTextDrawSetProportional(playerid, Stats_PTD[playerid][1], 1);

	Stats_PTD[playerid][2] = CreatePlayerTextDraw(playerid, 285.199737, 215.386688, "_");
	PlayerTextDrawLetterSize(playerid, Stats_PTD[playerid][2], 0.232799, 0.927999);
	PlayerTextDrawTextSize(playerid, Stats_PTD[playerid][2], 519.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, Stats_PTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, Stats_PTD[playerid][2], -1);
	PlayerTextDrawSetShadow(playerid, Stats_PTD[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, Stats_PTD[playerid][2], -1);
	PlayerTextDrawBackgroundColor(playerid, Stats_PTD[playerid][2], 255);
	PlayerTextDrawFont(playerid, Stats_PTD[playerid][2], 2);
	PlayerTextDrawSetProportional(playerid, Stats_PTD[playerid][2], 1);

	//Car information system
	CarInfoPTD[playerid][0] = CreatePlayerTextDraw(playerid, 309.000000, 144.000000, "~y~Model~w~: Anti-Aircraft");
	PlayerTextDrawFont(playerid, CarInfoPTD[playerid][0], 1);
	PlayerTextDrawLetterSize(playerid, CarInfoPTD[playerid][0], 0.195832, 0.899999);
	PlayerTextDrawTextSize(playerid, CarInfoPTD[playerid][0], 400.000000, 180.500000);
	PlayerTextDrawSetOutline(playerid, CarInfoPTD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, CarInfoPTD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, CarInfoPTD[playerid][0], 2);
	PlayerTextDrawColor(playerid, CarInfoPTD[playerid][0], -1);
	PlayerTextDrawBackgroundColor(playerid, CarInfoPTD[playerid][0], 255);
	PlayerTextDrawBoxColor(playerid, CarInfoPTD[playerid][0], 1097457995);
	PlayerTextDrawUseBox(playerid, CarInfoPTD[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid, CarInfoPTD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, CarInfoPTD[playerid][0], 0);

	CarInfoPTD[playerid][1] = CreatePlayerTextDraw(playerid, 312.000000, 155.000000, "~y~Abilities~w~: Can fire rockets");
	PlayerTextDrawFont(playerid, CarInfoPTD[playerid][1], 1);
	PlayerTextDrawLetterSize(playerid, CarInfoPTD[playerid][1], 0.195832, 0.899999);
	PlayerTextDrawTextSize(playerid, CarInfoPTD[playerid][1], 400.000000, 180.500000);
	PlayerTextDrawSetOutline(playerid, CarInfoPTD[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, CarInfoPTD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, CarInfoPTD[playerid][1], 2);
	PlayerTextDrawColor(playerid, CarInfoPTD[playerid][1], -1);
	PlayerTextDrawBackgroundColor(playerid, CarInfoPTD[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, CarInfoPTD[playerid][1], 1097457995);
	PlayerTextDrawUseBox(playerid, CarInfoPTD[playerid][1], 0);
	PlayerTextDrawSetProportional(playerid, CarInfoPTD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, CarInfoPTD[playerid][1], 0);

	CarInfoPTD[playerid][2] = CreatePlayerTextDraw(playerid, 310.000000, 166.000000, "~y~Requirments~w~: 3000 score");
	PlayerTextDrawFont(playerid, CarInfoPTD[playerid][2], 1);
	PlayerTextDrawLetterSize(playerid, CarInfoPTD[playerid][2], 0.195832, 0.899999);
	PlayerTextDrawTextSize(playerid, CarInfoPTD[playerid][2], 400.000000, 180.500000);
	PlayerTextDrawSetOutline(playerid, CarInfoPTD[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, CarInfoPTD[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, CarInfoPTD[playerid][2], 2);
	PlayerTextDrawColor(playerid, CarInfoPTD[playerid][2], -1);
	PlayerTextDrawBackgroundColor(playerid, CarInfoPTD[playerid][2], 255);
	PlayerTextDrawBoxColor(playerid, CarInfoPTD[playerid][2], 1097457995);
	PlayerTextDrawUseBox(playerid, CarInfoPTD[playerid][2], 0);
	PlayerTextDrawSetProportional(playerid, CarInfoPTD[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, CarInfoPTD[playerid][2], 0);

	//PUBG event
	PUBGBonusTD[playerid] = CreatePlayerTextDraw(playerid, 321.000000, 192.000000, "~g~+2 Score & $5,000");
	PlayerTextDrawFont(playerid, PUBGBonusTD[playerid], 2);
	PlayerTextDrawLetterSize(playerid, PUBGBonusTD[playerid], 0.266667, 1.450000);
	PlayerTextDrawTextSize(playerid, PUBGBonusTD[playerid], 400.000000, 387.000000);
	PlayerTextDrawSetOutline(playerid, PUBGBonusTD[playerid], 0);
	PlayerTextDrawSetShadow(playerid, PUBGBonusTD[playerid], 0);
	PlayerTextDrawAlignment(playerid, PUBGBonusTD[playerid], 2);
	PlayerTextDrawColor(playerid, PUBGBonusTD[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, PUBGBonusTD[playerid], 255);
	PlayerTextDrawBoxColor(playerid, PUBGBonusTD[playerid], 50);
	PlayerTextDrawUseBox(playerid, PUBGBonusTD[playerid], 0);
	PlayerTextDrawSetProportional(playerid, PUBGBonusTD[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, PUBGBonusTD[playerid], 0);

	//Flashbang
	FlashTD[playerid] = CreatePlayerTextDraw(playerid, 345.000000, -10.000000, "_");
	PlayerTextDrawAlignment(playerid, FlashTD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, FlashTD[playerid], 255);
	PlayerTextDrawFont(playerid, FlashTD[playerid], 3);
	PlayerTextDrawLetterSize(playerid, FlashTD[playerid], 0.210000, 51.300003);
	PlayerTextDrawColor(playerid, FlashTD[playerid], -1);
	PlayerTextDrawSetOutline(playerid, FlashTD[playerid], 0);
	PlayerTextDrawSetProportional(playerid, FlashTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, FlashTD[playerid], 546);
	PlayerTextDrawUseBox(playerid, FlashTD[playerid], 1);
	PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFFFF);
	PlayerTextDrawTextSize(playerid, FlashTD[playerid], 152.000000, 706.000000);

	//Spec system
	aSpecPTD[playerid][0] = CreatePlayerTextDraw(playerid, 260.000000, 360.000000, "Preview_Model");
	PlayerTextDrawFont(playerid, aSpecPTD[playerid][0], 5);
	PlayerTextDrawLetterSize(playerid, aSpecPTD[playerid][0], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, aSpecPTD[playerid][0], 36.500000, 42.000000);
	PlayerTextDrawSetOutline(playerid, aSpecPTD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, aSpecPTD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, aSpecPTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, aSpecPTD[playerid][0], -1);
	PlayerTextDrawBackgroundColor(playerid, aSpecPTD[playerid][0], 125);
	PlayerTextDrawBoxColor(playerid, aSpecPTD[playerid][0], 255);
	PlayerTextDrawUseBox(playerid, aSpecPTD[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid, aSpecPTD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, aSpecPTD[playerid][0], 0);
	PlayerTextDrawSetPreviewModel(playerid, aSpecPTD[playerid][0], 0);
	PlayerTextDrawSetPreviewRot(playerid, aSpecPTD[playerid][0], -10.000000, 0.000000, -20.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, aSpecPTD[playerid][0], 1, 1);

	aSpecPTD[playerid][1] = CreatePlayerTextDraw(playerid, 299.000000, 360.000000, "_");
	PlayerTextDrawFont(playerid, aSpecPTD[playerid][1], 1);
	PlayerTextDrawLetterSize(playerid, aSpecPTD[playerid][1], 0.225000, 0.800000);
	PlayerTextDrawTextSize(playerid, aSpecPTD[playerid][1], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, aSpecPTD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, aSpecPTD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, aSpecPTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, aSpecPTD[playerid][1], -8388353);
	PlayerTextDrawBackgroundColor(playerid, aSpecPTD[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, aSpecPTD[playerid][1], 50);
	PlayerTextDrawUseBox(playerid, aSpecPTD[playerid][1], 0);
	PlayerTextDrawSetProportional(playerid, aSpecPTD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, aSpecPTD[playerid][1], 0);

	aSpecPTD[playerid][2] = CreatePlayerTextDraw(playerid, 299.000000, 372.000000, "_");
	PlayerTextDrawFont(playerid, aSpecPTD[playerid][2], 1);
	PlayerTextDrawLetterSize(playerid, aSpecPTD[playerid][2], 0.183333, 0.900000);
	PlayerTextDrawTextSize(playerid, aSpecPTD[playerid][2], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, aSpecPTD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, aSpecPTD[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, aSpecPTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, aSpecPTD[playerid][2], -1);
	PlayerTextDrawBackgroundColor(playerid, aSpecPTD[playerid][2], 255);
	PlayerTextDrawBoxColor(playerid, aSpecPTD[playerid][2], 50);
	PlayerTextDrawUseBox(playerid, aSpecPTD[playerid][2], 0);
	PlayerTextDrawSetProportional(playerid, aSpecPTD[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, aSpecPTD[playerid][2], 0);

	//Kill system

	killedby[playerid] = CreatePlayerTextDraw(playerid,251.127502, 309.749847, "_");
	PlayerTextDrawLetterSize(playerid,killedby[playerid], 0.431259, 1.780833);
	PlayerTextDrawAlignment(playerid,killedby[playerid], 1);
	PlayerTextDrawColor(playerid,killedby[playerid], 8388863);
	PlayerTextDrawSetShadow(playerid,killedby[playerid], 0);
	PlayerTextDrawSetOutline(playerid,killedby[playerid], 0);
	PlayerTextDrawBackgroundColor(playerid,killedby[playerid], -2147450625);
	PlayerTextDrawFont(playerid,killedby[playerid], 1);

	deathbox[playerid] = CreatePlayerTextDraw(playerid,641.531494, 300.166687, "usebox");
	PlayerTextDrawLetterSize(playerid,deathbox[playerid], 0.000000, 4.609256);
	PlayerTextDrawTextSize(playerid,deathbox[playerid], -2.000000, 0.000000);
	PlayerTextDrawAlignment(playerid,deathbox[playerid], 1);
	PlayerTextDrawColor(playerid,deathbox[playerid], 0);
	PlayerTextDrawUseBox(playerid,deathbox[playerid], true);
	PlayerTextDrawBoxColor(playerid,deathbox[playerid], 102);
	PlayerTextDrawSetShadow(playerid,deathbox[playerid], 0);
	PlayerTextDrawSetOutline(playerid,deathbox[playerid], 0);
	PlayerTextDrawFont(playerid,deathbox[playerid], 0);

	killedtext[playerid] = CreatePlayerTextDraw(playerid,283.455261, 106.749977, "_");
	PlayerTextDrawLetterSize(playerid,killedtext[playerid], 0.449999, 1.600000);
	PlayerTextDrawAlignment(playerid,killedtext[playerid], 1);
	PlayerTextDrawColor(playerid,killedtext[playerid], -5963521);
	PlayerTextDrawSetShadow(playerid,killedtext[playerid], 0);
	PlayerTextDrawSetOutline(playerid,killedtext[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid,killedtext[playerid], 51);
	PlayerTextDrawFont(playerid,killedtext[playerid], 1);
	PlayerTextDrawSetProportional(playerid,killedtext[playerid], 1);

	killedbox[playerid] = CreatePlayerTextDraw(playerid,641.531494, 94.250000, "usebox");
	PlayerTextDrawLetterSize(playerid,killedbox[playerid], 0.000000, 4.349999);
	PlayerTextDrawTextSize(playerid,killedbox[playerid], -2.000000, 0.000000);
	PlayerTextDrawAlignment(playerid,killedbox[playerid], 1);
	PlayerTextDrawColor(playerid,killedbox[playerid], 0);
	PlayerTextDrawUseBox(playerid,killedbox[playerid], true);
	PlayerTextDrawBoxColor(playerid,killedbox[playerid], 102);
	PlayerTextDrawSetShadow(playerid,killedbox[playerid], 0);
	PlayerTextDrawSetOutline(playerid,killedbox[playerid], 0);
	PlayerTextDrawFont(playerid,killedbox[playerid], 0);

	//Notifier

	Notifier_PTD[playerid] = CreatePlayerTextDraw(playerid, 479.000000, 352.000000, "_");
	PlayerTextDrawFont(playerid, Notifier_PTD[playerid], 1);
	PlayerTextDrawLetterSize(playerid, Notifier_PTD[playerid], 0.145833, 0.900000);
	PlayerTextDrawTextSize(playerid, Notifier_PTD[playerid], 653.000000, 21.500000);
	PlayerTextDrawSetOutline(playerid, Notifier_PTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, Notifier_PTD[playerid], 0);
	PlayerTextDrawAlignment(playerid, Notifier_PTD[playerid], 1);
	PlayerTextDrawColor(playerid, Notifier_PTD[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, Notifier_PTD[playerid], 255);
	PlayerTextDrawBoxColor(playerid, Notifier_PTD[playerid], 137);
	PlayerTextDrawUseBox(playerid, Notifier_PTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, Notifier_PTD[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, Notifier_PTD[playerid], 0);

	//Capture system

	ProgressTD[playerid] = CreatePlayerTextDraw(playerid, 85.225006, 326.500030, "_");
	PlayerTextDrawAlignment(playerid,ProgressTD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid,ProgressTD[playerid], 255);
	PlayerTextDrawFont(playerid,ProgressTD[playerid], 1);
	PlayerTextDrawLetterSize(playerid,ProgressTD[playerid], 0.318124, 1.197500);
	PlayerTextDrawColor(playerid,ProgressTD[playerid], -1);
	PlayerTextDrawSetOutline(playerid,ProgressTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid,ProgressTD[playerid], 1);
	PlayerTextDrawSetSelectable(playerid,ProgressTD[playerid], 0);

	//Stats

	Stats_UIPTD[playerid] = CreatePlayerTextDraw(playerid, 480.000000, 366.000000, "_");
	PlayerTextDrawFont(playerid, Stats_UIPTD[playerid], 2);
	PlayerTextDrawLetterSize(playerid, Stats_UIPTD[playerid], 0.141667, 1.050000);
	PlayerTextDrawTextSize(playerid, Stats_UIPTD[playerid], 665.000000, 282.000000);
	PlayerTextDrawSetOutline(playerid, Stats_UIPTD[playerid], 0);
	PlayerTextDrawSetShadow(playerid, Stats_UIPTD[playerid], 0);
	PlayerTextDrawAlignment(playerid, Stats_UIPTD[playerid], 1);
	PlayerTextDrawColor(playerid, Stats_UIPTD[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, Stats_UIPTD[playerid], 255);
	PlayerTextDrawBoxColor(playerid, Stats_UIPTD[playerid], 50);
	PlayerTextDrawUseBox(playerid, Stats_UIPTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, Stats_UIPTD[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, Stats_UIPTD[playerid], 0);
	return 1;
}

RemovePlayerUI(playerid) {
	PlayerTextDrawDestroy(playerid, pRankStats[playerid]);

	for (new i = 0; i < sizeof(Stats_TD); i++) {
		TextDrawHideForPlayer(playerid, Stats_TD[i]);
	}

	PlayerTextDrawDestroy(playerid, FlashTD[playerid]);
	PlayerTextDrawDestroy(playerid, PUBGBonusTD[playerid]);

	TextDrawHideForPlayer(playerid, DMBox);
	TextDrawHideForPlayer(playerid, DMText);
	TextDrawHideForPlayer(playerid, DMText2[0]);
	TextDrawHideForPlayer(playerid, DMText2[1]);
	TextDrawHideForPlayer(playerid, DMText2[2]);
	TextDrawHideForPlayer(playerid, DMText2[3]);

	PlayerTextDrawDestroy(playerid, Stats_PTD[playerid][0]);
	PlayerTextDrawDestroy(playerid, Stats_PTD[playerid][1]);
	PlayerTextDrawDestroy(playerid, Stats_PTD[playerid][2]);

	PlayerTextDrawDestroy(playerid, aSpecPTD[playerid][0]);
	PlayerTextDrawDestroy(playerid, aSpecPTD[playerid][1]);
	PlayerTextDrawDestroy(playerid, aSpecPTD[playerid][2]);

	HidePlayerHUD(playerid);
	PlayerTextDrawDestroy(playerid, Notifier_PTD[playerid]);

	PlayerTextDrawDestroy(playerid, CarInfoPTD[playerid][0]);
	PlayerTextDrawDestroy(playerid, CarInfoPTD[playerid][1]);
	PlayerTextDrawDestroy(playerid, CarInfoPTD[playerid][2]);

	PlayerTextDrawDestroy(playerid, killedby[playerid]);
	PlayerTextDrawDestroy(playerid, deathbox[playerid]);
	PlayerTextDrawDestroy(playerid, killedtext[playerid]);
	PlayerTextDrawDestroy(playerid, killedbox[playerid]);

	PlayerTextDrawDestroy(playerid, Stats_UIPTD[playerid]);
	PlayerTextDrawDestroy(playerid, ProgressTD[playerid]);

	PlayerTextDrawDestroy(playerid, selectdraw_3[playerid]);
	PlayerTextDrawDestroy(playerid, selectdraw_4[playerid]);
	PlayerTextDrawDestroy(playerid, selectdraw_5[playerid]);
	PlayerTextDrawDestroy(playerid, selectdraw_6[playerid]);

	//Progress bars
	DestroyPlayerProgressBar(playerid, Player_SelectionBar[playerid]); // Selection Progress

	DestroyPlayerProgressBar(playerid, CW_PBAR[playerid][0]); //Clan War
	DestroyPlayerProgressBar(playerid, CW_PBAR[playerid][1]); // ^
	PlayerTextDrawDestroy(playerid, CW_PTD[playerid][0]);
	PlayerTextDrawDestroy(playerid, CW_PTD[playerid][1]);
	return 1;
}

ShowPlayerHUD(playerid) {
	PlayerTextDrawShow(playerid, Stats_UIPTD[playerid]);
	PlayerTextDrawShow(playerid, pRankStats[playerid]);
	for (new i = 0; i < sizeof(WarStatusTD); i++) {
		TextDrawShowForPlayer(playerid, WarStatusTD[i]);
	}
	for (new i = 0; i < sizeof(BoxTD); i++) {
		TextDrawShowForPlayer(playerid, BoxTD[i]);
	}
	TextDrawShowForPlayer(playerid, StatsDotTD);
	return 1;
}

HidePlayerHUD(playerid) {
	PlayerTextDrawHide(playerid, Stats_UIPTD[playerid]);
	PlayerTextDrawHide(playerid, pRankStats[playerid]);
	for (new i = 0; i < sizeof(WarStatusTD); i++) {
		TextDrawHideForPlayer(playerid, WarStatusTD[i]);
	}
	for (new i = 0; i < sizeof(BoxTD); i++) {
		TextDrawHideForPlayer(playerid, BoxTD[i]);
	}
	TextDrawHideForPlayer(playerid, StatsDotTD);
	return 1;
}

//Update player information on the UI

UpdatePlayerHUD(playerid) {
	new format_rank[220];

	new Float:KDR = floatdiv(PlayerInfo[playerid][pKills], PlayerInfo[playerid][pDeaths]);
	if (Ranks_GetPlayer(playerid) < MAX_RANKS - 1) {
		format(format_rank, sizeof(format_rank), "%s%d/%d~n~~n~%s", Team_GetGTColor(Team_GetPlayer(playerid)), GetPlayerScore(playerid), Ranks_GetScore(Ranks_GetPlayer(playerid) + 1), Ranks_ReturnName(Ranks_GetPlayer(playerid)));
		PlayerTextDrawSetString(playerid, pRankStats[playerid], format_rank);
	} else {
		format(format_rank, sizeof(format_rank), "%s%d/%d~n~~n~%s", Team_GetGTColor(Team_GetPlayer(playerid)), GetPlayerScore(playerid), Ranks_ReturnName(Ranks_GetPlayer(playerid)));
		PlayerTextDrawSetString(playerid, pRankStats[playerid], format_rank);
	}
	format(format_rank, sizeof(format_rank), "~w~EXP: %s%d ~w~KILLS: %s%d ~w~DEATHS: %s%d ~w~KDR: %s%0.2f",
		Team_GetGTColor(Team_GetPlayer(playerid)), PlayerInfo[playerid][pEXPEarned],
		Team_GetGTColor(Team_GetPlayer(playerid)), PlayerInfo[playerid][pKills],
		Team_GetGTColor(Team_GetPlayer(playerid)), PlayerInfo[playerid][pDeaths],
		Team_GetGTColor(Team_GetPlayer(playerid)), KDR);
	PlayerTextDrawSetString(playerid, Stats_UIPTD[playerid], format_rank);
	if (!PlayerInfo[playerid][pSelecting] && PlayerInfo[playerid][pLoggedIn] && !IsPlayerDying(playerid)
		&& IsPlayerSpawned(playerid))
	{
		if (GetPlayerConfigValue(playerid, "HUD") == 1) {
			ShowPlayerHUD(playerid);
		} else {
			HidePlayerHUD(playerid);
		}
	} else {
		HidePlayerHUD(playerid);
	}
	return 1;
}

//Update label text above head

UpdateLabelText(playerid) {
	if (!IsPlayerDying(playerid)) {
		new String[50];

		Update3DTextLabelText(RankLabel[playerid], 0xFFFFFF80, " ");

		format(String, sizeof(String), "");

		if (!PlayerInfo[playerid][pIsAFK]) {
			if (!PlayerInfo[playerid][pIsSpying]) {
				format(String, sizeof(String), "%s\n%s", Team_GetName(Team_GetPlayer(playerid)), Class_GetAbilityNames(Class_GetPlayerClass(playerid)));
			} else {
				format(String, sizeof(String), "%s\n%s", Team_GetName(PlayerInfo[playerid][pSpyTeam]), Class_GetAbilityNames(Class_GetPlayerClass(playerid)));
			}

			if (PlayerInfo[playerid][pDeathmatchId] == -1) {
				if (!pDuelInfo[playerid][pDInMatch])  {
					if (!PlayerInfo[playerid][pIsSpying]) {
						Update3DTextLabelText(RankLabel[playerid], Team_GetColor(Team_GetPlayer(playerid)), String);
					} else {
						Update3DTextLabelText(RankLabel[playerid], Team_GetColor(PlayerInfo[playerid][pSpyTeam]), String);
					}
				}
				else {
					Update3DTextLabelText(RankLabel[playerid], 0xFFFFFFCC, "Dueler");
				}
			}
			else {
				Update3DTextLabelText(RankLabel[playerid], 0xFFFFFFCC, "Deathmatcher");
			}
		}
	}
	else
	{
		Update3DTextLabelText(RankLabel[playerid], 0xC4C4C4CC, "..DEAD..");
	}
	if (pFlashLvl[playerid]) Update3DTextLabelText(RankLabel[playerid], COLOR_TOMATO, "..FLASH BANGED..");

	if ((!gInvisible[playerid]) || !IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		SetPlayerMarkerVisibility(playerid, 0xFF);
	} else {
		SetPlayerMarkerVisibility(playerid, 0x00);
	}
	return 1;
}

//Duel System

PlayerLeaveDuelCheck(playerid) {
	if (pDuelInfo[playerid][pDInMatch] == 1 && TargetOf[playerid] != INVALID_PLAYER_ID) {
		pDuelInfo[playerid][pDInMatch] = 0;
		pDuelInfo[TargetOf[playerid]][pDInMatch] = 0;

		if (!pDuelInfo[playerid][pDRCDuel]) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_21x, PlayerInfo[TargetOf[playerid]][PlayerName], PlayerInfo[playerid][PlayerName], ReturnWeaponName(pDuelInfo[playerid][pDWeapon]), formatInt(pDuelInfo[playerid][pDBetAmount]));
		} else {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_22x, PlayerInfo[TargetOf[playerid]][PlayerName], PlayerInfo[playerid][PlayerName], formatInt(pDuelInfo[playerid][pDBetAmount]));
		}

		GivePlayerCash(playerid, -pDuelInfo[playerid][pDBetAmount]);
		GivePlayerCash(TargetOf[playerid], pDuelInfo[playerid][pDBetAmount]);

		PlayerInfo[playerid][pDuelsLost]++;
		PlayerInfo[TargetOf[playerid]][pDuelsWon]++;

		SpawnPlayer(TargetOf[playerid]);

		pDuelInfo[TargetOf[playerid]][pDLocked] =
		pDuelInfo[TargetOf[playerid]][pDInMatch] =
		pDuelInfo[TargetOf[playerid]][pDWeapon] =
		pDuelInfo[TargetOf[playerid]][pDAmmo] =
		pDuelInfo[TargetOf[playerid]][pDMatchesPlayed] =
		pDuelInfo[TargetOf[playerid]][pDRematchOpt] =
		pDuelInfo[TargetOf[playerid]][pDBetAmount] = 0;

		TargetOf[TargetOf[playerid]] = INVALID_PLAYER_ID;
		TargetOf[playerid] = INVALID_PLAYER_ID;
	}

	TargetOf[playerid] = INVALID_PLAYER_ID;
	pDuelInfo[playerid][pDLocked] =
	pDuelInfo[playerid][pDInMatch] =
	pDuelInfo[playerid][pDWeapon] =
	pDuelInfo[playerid][pDAmmo] =
	pDuelInfo[playerid][pDBetAmount] =
	pDuelInfo[playerid][pDInMatch] = 0;
	return 1;
}

PlayerDuelSpawn(playerid) {
	//Player spawned and is recognized by being in a duel?!
	if (pDuelInfo[playerid][pDInMatch]) {
		if (TargetOf[playerid] == INVALID_PLAYER_ID || !pVerified[TargetOf[playerid]]) {
			pDuelInfo[playerid][pDLocked] =
			pDuelInfo[playerid][pDInMatch] =
			pDuelInfo[playerid][pDWeapon] =
			pDuelInfo[playerid][pDAmmo] =
			pDuelInfo[playerid][pDMatchesPlayed] =
			pDuelInfo[playerid][pDRematchOpt] =
			pDuelInfo[playerid][pDBetAmount] = 0;
		}
		else if (pDuelInfo[playerid][pDRematchOpt] && !pDuelInfo[playerid][pDMatchesPlayed]) {
			ResetPlayerWeapons(playerid);
			ResetPlayerWeapons(TargetOf[playerid]);

			pDuelInfo[TargetOf[playerid]][pDMatchesPlayed] =
				pDuelInfo[playerid][pDMatchesPlayed] = 1;

			pDuelInfo[playerid][pDLocked] = 1;
			pDuelInfo[TargetOf[playerid]][pDLocked] = 1;
			pDuelInfo[playerid][pDCountDown] = pDuelInfo[TargetOf[playerid]][pDCountDown] = gettime() + 99;

			KillTimer(DelayerTimer[playerid]);
			DelayerTimer[playerid] = SetTimerEx("InitPlayer", 3000, false, "i", playerid);
			TogglePlayerControllable(playerid, false);

			KillTimer(DelayerTimer[TargetOf[playerid]]);
			DelayerTimer[TargetOf[playerid]] = SetTimerEx("InitPlayer", 3000, false, "i", TargetOf[playerid]);
			TogglePlayerControllable(TargetOf[playerid], false);

			switch (pDuelInfo[playerid][pDMapId]) {
				case 0: {
					SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 0, 1358.6832,2185.3911,11.0156,147.3334);
					SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 0, 1317.3516,2120.9395,11.0156,327.8713);
				}
				case 1: {
					SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 10, -1018.2189,1056.7441,1342.9358,53.6926);
					SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 10, -1053.4242,1087.2908,1343.0204,230.7042);
				}
				case 2: {
					SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 3, 298.0534,176.0552,1007.1719,91.2696);
					SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 3, 238.5584,178.5376,1003.0300,267.9679);
				}
				case 3: {
					SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 3, 4888.9790,149.8565,15.1086);
					SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 3, 4858.3604,132.1908,15.0253);
				}
			}
			return 1;
		} else {
			pDuelInfo[playerid][pDInMatch] = 0;
			pDuelInfo[TargetOf[playerid]][pDInMatch] = 0;

			if (!pDuelInfo[playerid][pDRCDuel]) {
				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_21x, PlayerInfo[TargetOf[playerid]][PlayerName], PlayerInfo[playerid][PlayerName], ReturnWeaponName(pDuelInfo[playerid][pDWeapon]), pDuelInfo[playerid][pDBetAmount]);
			} else {
				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_22x, PlayerInfo[TargetOf[playerid]][PlayerName], PlayerInfo[playerid][PlayerName], pDuelInfo[playerid][pDBetAmount]);
			}

			GivePlayerCash(playerid, -pDuelInfo[playerid][pDBetAmount]);
			GivePlayerCash(TargetOf[playerid], pDuelInfo[playerid][pDBetAmount]);

			PlayerInfo[playerid][pDuelsLost]++;
			PlayerInfo[TargetOf[playerid]][pDuelsWon]++;

			SpawnPlayer(TargetOf[playerid]);

			pDuelInfo[TargetOf[playerid]][pDLocked] =
			pDuelInfo[TargetOf[playerid]][pDInMatch] =
			pDuelInfo[TargetOf[playerid]][pDWeapon] =
			pDuelInfo[TargetOf[playerid]][pDAmmo] =
			pDuelInfo[TargetOf[playerid]][pDMatchesPlayed] =
			pDuelInfo[TargetOf[playerid]][pDRematchOpt] =
			pDuelInfo[TargetOf[playerid]][pDBetAmount] = 0;

			TargetOf[TargetOf[playerid]] = INVALID_PLAYER_ID;
			TargetOf[playerid] = INVALID_PLAYER_ID;
		}
	}

	//Important duel stuff
	TargetOf[playerid] = INVALID_PLAYER_ID;
	pDuelInfo[playerid][pDLocked] =
	pDuelInfo[playerid][pDInMatch] =
	pDuelInfo[playerid][pDWeapon] =
	pDuelInfo[playerid][pDAmmo] =
	pDuelInfo[playerid][pDBetAmount] =
	pDuelInfo[playerid][pDInMatch] = 0;
	return 1;
}

//Player Stats

//For /stats command
UpdatePlayerStatsList(playerid, targetid) {
	new Left_Side[MEDIUM_STRING_LEN], Right_Side[MEDIUM_STRING_LEN];

	switch (pStats[playerid]) {
		case 0: {
			strcat(Left_Side, "~r~GENERAL INFO~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side),
				"%sScore: %d~n~Money: %s~n~EXP: %d~n~VIP Coins: %d", Left_Side,
				GetPlayerScore(targetid), formatInt(GetPlayerCash(targetid)), PlayerInfo[targetid][pEXPEarned], PlayerInfo[targetid][pCoins]);

			new d, h, m, s;
			CountPlayedTime(targetid, d, h, m, s);
			format(Right_Side, sizeof(Right_Side), "Played Time: %dd %dh %dm %ds~n~", d, h, m, s);
			format(Right_Side, sizeof(Right_Side), "%sRegistered %s~n~", Right_Side, GetWhen(PlayerInfo[targetid][pRegDate], gettime()));
			if (IsPlayerInAnyClan(targetid)) {
				format(Right_Side, sizeof(Right_Side), "%sClan: %s~n~Clan Rank: %s[%d]",
					Right_Side, GetPlayerClan(targetid), GetPlayerClanRankName(targetid), GetPlayerClanRank(targetid));
			}
		}
		case 1: {
			strcat(Left_Side, "~r~GAMEPLAY STATS~n~~n~~w~");

			if (playerid != targetid && PlayerInfo[targetid][pIsSpying] && PlayerInfo[targetid][pSpyTeam] == Team_GetPlayer(playerid)) {
				format(Left_Side, sizeof(Left_Side), "%sRank: %s~n~", Left_Side, Ranks_ReturnName(Ranks_GetPlayer(targetid)));
			} else {
				format(Left_Side, sizeof(Left_Side), "%sRank: %s~n~Team: %s~n~Class: %s~n~", Left_Side, Ranks_ReturnName(Ranks_GetPlayer(targetid)),
						Team_GetName(Team_GetPlayer(targetid)), Class_GetAbilityNames(Class_GetPlayerClass(targetid)));
			}
			format(Left_Side, sizeof(Left_Side), "%sPlayers Supported: %d", Left_Side, PlayerInfo[targetid][pSupportAttempts]);

			new Float:KDR = 0.0;
			if (PlayerInfo[targetid][pKills] && PlayerInfo[targetid][pDeaths]) {
				KDR = floatdiv(PlayerInfo[targetid][pKills], PlayerInfo[targetid][pDeaths]);
			}

			format(Right_Side, sizeof(Right_Side), "Kills: %d~n~DM Kills: %d~n~Deaths: %d~n~Suicides: %d~n~K/D Ratio: %0.2f",
				PlayerInfo[targetid][pKills], PlayerInfo[targetid][pDeathmatchKills], PlayerInfo[targetid][pDeaths], PlayerInfo[targetid][pSuicideAttempts], KDR);
		}
		case 2: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (2)~n~~n~~w~");

			new Float: ACC = 0.0;
			if (PlayerInfo[playerid][pKills] && PlayerInfo[playerid][pGunFires]) {
				ACC = floatdiv(PlayerInfo[targetid][pKills], PlayerInfo[targetid][pGunFires]);
			}
			format(Left_Side, sizeof(Left_Side), "%sK/S Accuracy: %0.2f~n~Kill Spree: %d~n~Headshots: %d~n~Headshot Streak: %d", Left_Side, ACC,
				pStreak[targetid], PlayerInfo[targetid][pHeadshots], PlayerInfo[targetid][pHeadshotStreak]);

			format(Right_Side, sizeof(Right_Side), "Most Kills: %d~n~Nutshots: %d~n~Kill Assists: %d~n~Most Kill Assists: %d~n~Revenges Taken: %d",
				PlayerInfo[targetid][pHighestKillStreak], PlayerInfo[targetid][pNutshots], PlayerInfo[targetid][pKillAssists], PlayerInfo[targetid][pHighestKillAssists],
				PlayerInfo[targetid][pRevengeTakes]);
		}
		case 3: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (3)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sKnife Kills: %d~n~Sawn Kills: %d~n~Zones Captured: %d~n~Capturing Streak: %d", Left_Side,
				PlayerInfo[targetid][pKnifeKills], PlayerInfo[targetid][pSawnKills], PlayerInfo[targetid][pZonesCaptured], PlayerInfo[targetid][pCaptureStreak]);

			format(Right_Side, sizeof(Right_Side), "Carepacks Dropped: %d",
				PlayerInfo[targetid][Carepacks]);
		}
		case 4: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (4)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sFist Kills: %d~n~Melee Kills: %d~n~Pistol Kills: %d~n~SMG Kills: %d", Left_Side,
				PlayerInfo[targetid][pFistKills], PlayerInfo[targetid][pMeleeKills], PlayerInfo[targetid][pPistolKills], PlayerInfo[targetid][pSMGKills]);

			format(Right_Side, sizeof(Right_Side), "Shotgun Kills: %d~n~Heavy Kills: %d",
				PlayerInfo[targetid][pShotgunKills], PlayerInfo[targetid][pHeavyKills]);
		}
		case 5: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (5)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sClose Kills: %d~n~Health Lost: %0.2f~n~Damage Rate: %0.2f~n~Far Kills: %d", Left_Side,
				PlayerInfo[targetid][pCloseKills], PlayerInfo[targetid][pHealthLost], PlayerInfo[targetid][pDamageRate], PlayerInfo[targetid][pLongDistanceKills]);

			format(Right_Side, sizeof(Right_Side), "Drivers Stabbed: %d~n~Spies Killed: %d~n~Kills As Spy: %d",
				PlayerInfo[targetid][pDriversStabbed], PlayerInfo[targetid][pSpiesEliminated], PlayerInfo[targetid][pKillsAsSpy]);
		}
		case 6: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (6)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sWeapons Dropped: %d~n~Weapons Picked: %d~n~Events Won: %d~n~Races Won: %d", Left_Side,
				PlayerInfo[targetid][pWeaponsDropped], PlayerInfo[targetid][pWeaponsPicked], PlayerInfo[targetid][pEventsWon], PlayerInfo[targetid][pRacesWon]);

			format(Right_Side, sizeof(Right_Side), "Items Used: %d~n~Players Healed: %d~n~Commands Used: %d~n~Class Abilities Used: %d",
				PlayerInfo[targetid][pItemsUsed], PlayerInfo[targetid][pPlayersHealed], PlayerInfo[targetid][pCommandsUsed], PlayerInfo[targetid][pClassAbilitiesUsed]);
		}
		case 7: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (7)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sDrones Exploded: %d~n~Health Gained: %0.2f~n~Zones Captured: %d~n~Backup Attempts: %d", Left_Side,
				PlayerInfo[targetid][pDronesExploded], PlayerInfo[targetid][pHealthGained], PlayerInfo[targetid][pZonesCaptured], PlayerInfo[targetid][pBackupAttempts]);

			format(Right_Side, sizeof(Right_Side), "Backups Responed: %d~n~Highest Bet: %d~n~Bounty On Head: %d~n~Bounty Spent: %d",
				PlayerInfo[targetid][pBackupsResponded], PlayerInfo[targetid][pHighestBet], PlayerInfo[targetid][pBountyAmount], PlayerInfo[targetid][pBountyCashSpent]);
		}
		case 8: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (8)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sCapture Streak: %d~n~Most Cap-Assists: %d~n~Clan Kills: %d~n~Clan Deaths: %d", Left_Side,
				PlayerInfo[targetid][pCaptureStreak], PlayerInfo[targetid][pHighestCaptureAssists], PlayerInfo[targetid][pClanKills], PlayerInfo[targetid][pClanDeaths]);

			format(Right_Side, sizeof(Right_Side), "Bounties Hit: %d~n~Longest Kill Distance: %0.2f~n~Nearest Kill Distance: %0.2f",
				PlayerInfo[targetid][pBountyPlayersKilled], PlayerInfo[targetid][pLongestKillDistance], PlayerInfo[targetid][pNearestKillDistance]);
		}
		case 9: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (9)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sPrototypes Stolen: %d~n~Antennas Destroyed: %d~n~Crates Opened: %d", Left_Side,
				PlayerInfo[targetid][pPrototypesStolen], PlayerInfo[targetid][pAntennasDestroyed], PlayerInfo[targetid][pCratesOpened]);

			format(Right_Side, sizeof(Right_Side), "Nukes Launched: %d~n~Airstrike Calls: %d~n~Flashbanged Players: %d~n~Anthrax Intoxications: %d",
				PlayerInfo[targetid][pNukesLaunched], PlayerInfo[targetid][pAirstrikesCalled], PlayerInfo[targetid][pFlashBangedPlayers], PlayerInfo[targetid][pAnthraxIntoxications]);
		}
		case 10: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (10)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sPUBG Events Won: %d~n~Rope Rappels: %d~n~Drive-by Kills: %d", Left_Side,
				PlayerInfo[targetid][pPUBGEventsWon], PlayerInfo[targetid][pRopeRappels], PlayerInfo[targetid][pDriveByKills]);

			format(Right_Side, sizeof(Right_Side), "Time Spent On Foot: %ds~n~Time Spent In Car: %ds~n~Time Spent AFK: %ds",
				PlayerInfo[targetid][pTimeSpentOnFoot], PlayerInfo[targetid][pTimeSpentInCar], PlayerInfo[targetid][pTimeSpentAFK]);
		}
		case 11: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (11)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sMedkits Used: %d~n~Armourkits Used: %d", Left_Side,
				PlayerInfo[targetid][pMedkitsUsed], PlayerInfo[targetid][pArmourkitsUsed]);

			new Float:WLR = 0.0;
			if (PlayerInfo[targetid][pDuelsWon] && PlayerInfo[targetid][pDuelsLost]) {
			 	WLR = floatdiv(PlayerInfo[targetid][pDuelsWon], PlayerInfo[targetid][pDuelsLost]);
			}

			format(Right_Side, sizeof(Right_Side), "Duels Played: %d~n~Duels Won: %d~n~Duels Lost: %d~n~W/L Ratio: %0.2f",
				PlayerInfo[targetid][pDuelsWon] + PlayerInfo[targetid][pDuelsLost], PlayerInfo[targetid][pDuelsWon], PlayerInfo[targetid][pDuelsLost], WLR);
		}
		case 12: {
			strcat(Left_Side, "~r~GAMEPLAY STATS (12)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sAir Rockets Dropped: %d~n~Anti Air Rockets Fired: %d~n~Rustler Rockets Dropped: %d~n~Rustler Rockets Hit: %d", Left_Side,
				PlayerInfo[targetid][pAirRocketsFired], PlayerInfo[targetid][pAntiAirRocketsFired], PlayerInfo[targetid][pRustlerRocketsFired], PlayerInfo[targetid][pRustlerRocketsHit]);
		}
		case 13: {
			strcat(Left_Side, "~r~SESSION STATS~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sKills: %d~n~Deaths: %d~n~Revenges Taken: %d~n~Kill Assists: %d", Left_Side,
				PlayerInfo[targetid][pSessionKills], PlayerInfo[targetid][pSessionDeaths], PlayerInfo[targetid][sRevenges],
				PlayerInfo[targetid][sAssistkills]);

			format(Right_Side, sizeof(Right_Side), "DM Kills: %d~n~Events Won: %d~n~Races Won: %d~n~",
				PlayerInfo[targetid][sDMKills], PlayerInfo[targetid][sRaces], PlayerInfo[targetid][sEvents]);
		}
		default: {
			strcat(Left_Side, "~r~SESSION STATS (2)~n~~n~~w~");

			format(Left_Side, sizeof(Left_Side), "%sKills As Spy: %d~n~Spies Eliminated: %d~n~Knife Kills: %d~n~Teargas Kills: %d", Left_Side,
				PlayerInfo[targetid][sDisguisedKills], PlayerInfo[targetid][sSpiesKilled],
				PlayerInfo[targetid][sKnives], PlayerInfo[targetid][sGasKills]);
		}
	}

	PlayerTextDrawSetString(playerid, Stats_PTD[playerid][1], Left_Side);
	PlayerTextDrawSetString(playerid, Stats_PTD[playerid][2], Right_Side);
	return 1;
}

//Save one player's stats
SavePlayerStats(playerid) {
	new query[2048];

	PlayerInfo[playerid][pTimesLoggedIn] ++;

	mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET LastVisit = '%d', ClanId = '%d', \
		ClanRank = '%d', Coins = '%d', PlayTime = '%d', GPCI = '%e', TimesLoggedIn = '%d', Warnings = '%d', AntiCheatWarnings = '%d', \
		PlayerReports = '%d', SpamAttempts = '%d', AdvAttempts = '%d', AntiSwearBlocks = '%d', TagPermitted = '%d', ReportAttempts = '%d', BannedTimes = '%d' WHERE ID = '%d' LIMIT 1",
	gettime(), pClan[playerid], pClanRank[playerid], PlayerInfo[playerid][pCoins], PlayerInfo[playerid][pTimePlayed], PlayerInfo[playerid][pGPCI],
	PlayerInfo[playerid][pIP], PlayerInfo[playerid][pTimesLoggedIn], PlayerInfo[playerid][pAccountWarnings],
	PlayerInfo[playerid][pAntiCheatWarnings], PlayerInfo[playerid][pPlayerReports], PlayerInfo[playerid][pSpamAttempts], PlayerInfo[playerid][pAdvAttempts],
	PlayerInfo[playerid][pAntiSwearBlocks], PlayerInfo[playerid][pTagPermitted], PlayerInfo[playerid][pReportAttempts], PlayerInfo[playerid][pBannedTimes],
	PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);

	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);

	new Float: Health, Float: Armour;
	GetPlayerHealth(playerid, Health);
	GetPlayerArmour(playerid, Armour);

	mysql_format(Database, query, sizeof(query), "UPDATE `PlayersData` SET Score = '%d', Cash = '%d', Kills = '%d', Deaths = '%d', GunFires = '%d', IsJailed = '%d', JailTime = '%d', \
		Headshots = '%d', Nutshots = '%d', KnifeKills = '%d', \
		RevengeTakes = '%d', ZonesCaptured = '%d', DeathmatchKills = '%d', RustlerRockets = '%d', RustlerRocketsHit = '%d', DuelsWon = '%d', DuelsLost = '%d', \
		MedkitsUsed = '%d', ArmourkitsUsed = '%d', SupportAttempts = '%d', EXP = '%d', KillAssists = '%d', CaptureAssists = '%d', HighestKillStreak = '%d', \
		SawedKills = '%d', AirRocketsFired = '%d', AntiAirRocketsFired = '%d', CarePackagesDropped = '%d', HealthLost = '%f', DamageRate = '%f', \
		SMGKills = '%d', ShotgunKills = '%d', HeavyKills = '%d', FistKills = '%d', CloseKills = '%d', DriversStabbed = '%d' WHERE pID = '%d' LIMIT 1",
	GetPlayerScore(playerid), GetPlayerCash(playerid), PlayerInfo[playerid][pKills], PlayerInfo[playerid][pDeaths], PlayerInfo[playerid][pGunFires], PlayerInfo[playerid][pJailed],
	PlayerInfo[playerid][pJailTime], PlayerInfo[playerid][pHeadshots], PlayerInfo[playerid][pNutshots],
	PlayerInfo[playerid][pKnifeKills], PlayerInfo[playerid][pRevengeTakes], PlayerInfo[playerid][pZonesCaptured],
	PlayerInfo[playerid][pDeathmatchKills], PlayerInfo[playerid][pRustlerRocketsFired], PlayerInfo[playerid][pRustlerRocketsHit],
	PlayerInfo[playerid][pDuelsWon], PlayerInfo[playerid][pDuelsLost], PlayerInfo[playerid][pMedkitsUsed], PlayerInfo[playerid][pArmourkitsUsed],
	PlayerInfo[playerid][pSupportAttempts], PlayerInfo[playerid][pEXPEarned], PlayerInfo[playerid][pKillAssists], PlayerInfo[playerid][pCaptureAssists], PlayerInfo[playerid][pHighestKillStreak],
	PlayerInfo[playerid][pSawnKills], PlayerInfo[playerid][pAirRocketsFired], PlayerInfo[playerid][pAntiAirRocketsFired], PlayerInfo[playerid][Carepacks],
	PlayerInfo[playerid][pHealthLost], PlayerInfo[playerid][pDamageRate], PlayerInfo[playerid][pSMGKills], PlayerInfo[playerid][pShotgunKills],
	PlayerInfo[playerid][pHeavyKills], PlayerInfo[playerid][pFistKills], PlayerInfo[playerid][pCloseKills], PlayerInfo[playerid][pDriversStabbed], PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);

	mysql_format(Database, query, sizeof(query), "UPDATE `PlayersData` SET SpiesEliminated = '%d', KillsAsSpy = '%d', LongDistanceKills = '%d', \
		WeaponsDropped = '%d', WeaponsPicked = '%d', EventsWon = '%d', RacesWon = '%d', \
		ItemsUsed = '%d', FavSkin = '%d', FavTeam = '%d', SuicideAttempts = '%d', PlayersHealed = '%d', CommandsUsed = '%d', CommandsFailed = '%d', \
		UnauthorizedActions = '%d', RCONLogins = '%d', RCONFailedAttempts = '%d', ClassAbilitiesUsed = '%d', DronesExploded = '%d', \
		HealthGained = '%f', InteriorsEntered = '%d', InteriorsExitted = '%d', PickupsPicked = '%d' WHERE pID = '%d' LIMIT 1",
	PlayerInfo[playerid][pSpiesEliminated], PlayerInfo[playerid][pKillsAsSpy], PlayerInfo[playerid][pLongDistanceKills], PlayerInfo[playerid][pWeaponsDropped],
	PlayerInfo[playerid][pWeaponsPicked], PlayerInfo[playerid][pEventsWon], PlayerInfo[playerid][pRacesWon],
	PlayerInfo[playerid][pItemsUsed], GetPlayerSkin(playerid), Team_GetPlayer(playerid), PlayerInfo[playerid][pSuicideAttempts],
	PlayerInfo[playerid][pPlayersHealed], PlayerInfo[playerid][pCommandsUsed], PlayerInfo[playerid][pCommandsFailed],
	PlayerInfo[playerid][pUnauthorizedActions], PlayerInfo[playerid][pRCONLogins], PlayerInfo[playerid][pRCONFailedAttempts],
	PlayerInfo[playerid][pClassAbilitiesUsed], PlayerInfo[playerid][pDronesExploded], PlayerInfo[playerid][pHealthGained],
	PlayerInfo[playerid][pInteriorsEntered], PlayerInfo[playerid][pInteriorsExitted], PlayerInfo[playerid][pPickupsPicked],
	PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);

	mysql_format(Database, query, sizeof(query), "UPDATE `PlayersData` SET QuestionsAsked = '%d', QuestionsAnswered = '%d', CrashTimes = '%d', SAMPClient = '%e', BackupAttempts = '%d', \
		BackupsResponded = '%d', BaseRapeAttempts = '%d', ChatMessagesSent = '%d', \
		MoneySent = '%d', MoneyReceived = '%d', HighestBet = '%d', DuelRequests = '%d', DuelsAccepted = '%d', \
		DuelsRefusedByPlayer = '%d', DuelsRefusedByOthers = '%d', BountyAmount = '%d', BountyCashSpent = '%d', CoinsSpent = '%d', \
		PaymentsAccepted = '%d', ClanKills = '%d', ClanDeaths = '%d', HighestCaptures = '%d', \
		KicksByAdmin = '%d', LongestKillDistance = '%f', NearestKillDistance = '%f', \
		HighestCaptureAssists = '%d', HighestKillAssists = '%d', BountyPlayersKilled = '%d', \
		PrototypesStolen = '%d', AntennasDestroyed = '%d', CratesOpened = '%d' WHERE pID = '%d' LIMIT 1",
	PlayerInfo[playerid][pQuestionsAsked], PlayerInfo[playerid][pQuestionsAnswered],
	PlayerInfo[playerid][pCrashTimes], PlayerInfo[playerid][pSAMPClient], PlayerInfo[playerid][pBackupAttempts],
	PlayerInfo[playerid][pBackupsResponded], PlayerInfo[playerid][pBaseRapeAttempts],
	PlayerInfo[playerid][pChatMessagesSent], PlayerInfo[playerid][pMoneySent], PlayerInfo[playerid][pMoneyReceived],
	PlayerInfo[playerid][pHighestBet], PlayerInfo[playerid][pDuelRequests], PlayerInfo[playerid][pDuelsAccepted],
	PlayerInfo[playerid][pDuelsRefusedByPlayer], PlayerInfo[playerid][pDuelsRefusedByOthers], PlayerInfo[playerid][pBountyAmount],
	PlayerInfo[playerid][pBountyCashSpent], PlayerInfo[playerid][pCoinsSpent], PlayerInfo[playerid][pPaymentsAccepted],
	PlayerInfo[playerid][pClanKills], PlayerInfo[playerid][pClanDeaths], PlayerInfo[playerid][pHighestCaptures],
	PlayerInfo[playerid][pKicksByAdmin], PlayerInfo[playerid][pLongestKillDistance], PlayerInfo[playerid][pNearestKillDistance],
	PlayerInfo[playerid][pHighestCaptureAssists], PlayerInfo[playerid][pHighestKillAssists],
	PlayerInfo[playerid][pBountyPlayersKilled],
	PlayerInfo[playerid][pPrototypesStolen], PlayerInfo[playerid][pAntennasDestroyed], PlayerInfo[playerid][pCratesOpened], PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);

	mysql_format(Database, query, sizeof(query), "UPDATE `PlayersData` SET LastPing = '%d', LastPacketLoss = '%f', \
		HighestPing = '%d', LowestPing = '%d', NukesLaunched = '%d', AirstrikesCalled = '%d', AnthraxIntoxications = '%d', \
		PUBGEventsWon = '%d', RopeRappels = '%d', AreasEntered = '%d', LastAreaId = '%d', LastPosX = '%f', LastPosY = '%f', LastPosZ = '%f', \
		LastHealth = '%f', LastArmour = '%f', TimeSpentOnFoot = '%d', TimeSpentInCar = '%d', TimeSpentAsPassenger = '%d', \
		TimeSpentInSelection = '%d', TimeSpentAFK = '%d', DriveByKills = '%d', CashAdded = '%d', CashReduced = '%d', \
		LastInterior = '%d', LastVirtualWorld = '%d', FlashBangedPlayers = '%d', PistolKills = '%d', MeleeKills = '%d' WHERE pID = '%d' LIMIT 1",
	PlayerInfo[playerid][pLastPing], PlayerInfo[playerid][pLastPacketLoss], PlayerInfo[playerid][pHighestPing], PlayerInfo[playerid][pLowestPing],
	PlayerInfo[playerid][pNukesLaunched], PlayerInfo[playerid][pAirstrikesCalled], PlayerInfo[playerid][pAnthraxIntoxications],
	PlayerInfo[playerid][pPUBGEventsWon], PlayerInfo[playerid][pRopeRappels],
	PlayerInfo[playerid][pAreasEntered], PlayerInfo[playerid][pLastAreaId],
	X, Y, Z, Health, Armour, PlayerInfo[playerid][pTimeSpentOnFoot], PlayerInfo[playerid][pTimeSpentInCar],
	PlayerInfo[playerid][pTimeSpentAsPassenger], PlayerInfo[playerid][pTimeSpentInSelection],
	PlayerInfo[playerid][pTimeSpentAFK], PlayerInfo[playerid][pDriveByKills],
	PlayerInfo[playerid][pCashAdded], PlayerInfo[playerid][pCashReduced], GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid),
	PlayerInfo[playerid][pFlashBangedPlayers], PlayerInfo[playerid][pPistolKills], PlayerInfo[playerid][pMeleeKills], PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);

	mysql_format(Database, query, sizeof(query), "UPDATE `PlayersConf` SET `DoNotDisturb` = '%d', `NoDuel` = '%d', `NoDogfights` = '%d', `NoTutor` = '%d', `GUIEnabled` = '%d', \
		`SpawnKillTime` = '%d', `AllowWatch` = '%d' WHERE pID = '%d' LIMIT 1",
	PlayerInfo[playerid][pDoNotDisturb], PlayerInfo[playerid][pNoDuel], PlayerInfo[playerid][pNoDogfight], PlayerInfo[playerid][pNoTutor],
	PlayerInfo[playerid][pGUIEnabled], PlayerInfo[playerid][pSpawnKillTime], PlayerInfo[playerid][pAllowWatch], PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);

	Weapons_ExitPlayer(playerid);
	Items_ExitPlayer(playerid);
	return 1;
}

//Save everyone's stats
SaveAllStats() {
	foreach (new i: Player) {
		if (PlayerInfo[i][pLoggedIn] && pVerified[i]) {
			SavePlayerStats(i);
		}
	}
	return 1;
}

//bcrypt
forward OnPlayerEncrypted(player_name[MAX_PLAYER_NAME]);
public OnPlayerEncrypted(player_name[MAX_PLAYER_NAME]) {
	new hash[61];
	bcrypt_get_hash(hash);
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `Password` = '%e', `Salt` = NULL WHERE `Username` = '%e' LIMIT 1", hash, player_name);
	mysql_tquery(Database, query);
	return 1;
}

forward OnPasswordChecked(playerid, bool:success);
public OnPasswordChecked(playerid, bool:success) {
	new pass[MAX_PASS_LEN];
	GetPVarString(playerid, "TMP_Pass", pass, sizeof(pass));
    inline Login(pid, dialogid, response, listitem, string:inputtext[]) {
    	#pragma unused listitem, dialogid
		if (!response) {
			return Kick(pid);
		}
		bcrypt_verify(playerid, "OnPasswordChecked", inputtext, pass);
    }
	if (success) {
		inline KeyLogin(pid, dialogid, response, listitem, string:inputtext[])
		{
			#pragma unused dialogid, listitem
			if (!response) return Kick(pid);
			if (!isnull(inputtext) && strval(inputtext) == GetPVarInt(playerid, "PlayerSupportKey"))
			{
				PlayerInfo[pid][pLoggedIn] = 1;
				LoginPlayer(pid);
			}
			else
			{
				Dialog_ShowCallback(pid, using inline KeyLogin, DIALOG_STYLE_INPUT, "Support Key", "Please try again.", "LOGIN", "X");
			}
		}
		if (GetPVarInt(playerid, "PlayerSupportKey") != 0)
		{
			SendClientMessage(playerid, X11_RED, "This account is protected by a support key. Please type it below to login.");
			Dialog_ShowCallback(playerid, using inline KeyLogin, DIALOG_STYLE_INPUT, "Support Key", "Type your support key below to login.", "LOGIN", "X");
		}
		else
		{
			PlayerInfo[playerid][pLoggedIn] = 1;
			LoginPlayer(playerid);
		}
	} else {
		PlayerInfo[playerid][pFailedLogins]++;
		new string[MEDIUM_STRING_LEN];
		format(string, sizeof(string), MSG_LOGIN_DESCFAIL, PlayerInfo[playerid][PlayerName], PlayerInfo[playerid][pFailedLogins]);
		Dialog_ShowCallback(playerid, using inline Login, DIALOG_STYLE_PASSWORD, MSG_LOGIN_CAP, string, MSG_LOGIN_1ST, MSG_LOGIN_2ND);
		if (PlayerInfo[playerid][pFailedLogins] == 3) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_LOGIN_FAIL, PlayerInfo[playerid][PlayerName], playerid);
			Kick(playerid);
		}
	}
	return 1;
}

//Post connection authentication
forward OnPlayerDataReceived(playerid, race_check);
public OnPlayerDataReceived(playerid, race_check) {
	if (race_check != pRaceCheck[playerid]) return Kick(playerid);

	for (new i = 0; i < sizeof(SvTTD); i++) {
		TextDrawHideForPlayer(playerid, SvTTD[i]);
	}

	for (new i = 0; i < 25; i++) {
		SendClientMessage(playerid, -1, "");
	}

	TextDrawShowForPlayer(playerid, Site_TD);

	//First server messages
	SendClientMessage(playerid, X11_STEELBLUE, "WELCOME TO OUR SERVER!");
	SendClientMessage(playerid, X11_STEELBLUE, "Use /cmds, /help and /rules for help!");
	SendClientMessage(playerid, X11_STEELBLUE, "Weburl:"CYAN" "WEBSITE"");
	SendClientMessage(playerid, X11_STEELBLUE, "Discord:"CYAN" https://discord.gg/N24BpY5");
	PlayerPlaySound(playerid, 176, 0.0, 0.0, 0.0);

	if (cache_num_rows() > 0) {
		pVerified[playerid] = true;
		PlayerInfo[playerid][pCacheId] = cache_save();

		new pass[MAX_PASS_LEN];
		cache_get_value_int(0, "ID", PlayerInfo[playerid][pAccountId]);
		cache_get_value(0, "Password", pass, MAX_PASS_LEN);
		SetPVarString(playerid, "TMP_Pass", pass);
		cache_get_value(0, "Salt", PlayerInfo[playerid][pSaltKey], 11);
		cache_get_value_int(0, "LastVisit", PlayerInfo[playerid][pLastVisit]);

		new key;
		cache_get_value_int(0, "SupportKey", key);
		if (key != 0) {
			SetPVarInt(playerid, "PlayerSupportKey", key);
		}

		inline Login(pid, dialogid, response, listitem, string:inputtext[]) {
	    	#pragma unused listitem, dialogid
			if (!response) {
				return Kick(pid);
			}
			if (isnull(pass) || !strlen(pass)) return Kick(playerid);
			bcrypt_verify(playerid, "OnPasswordChecked", inputtext, pass);
	    }
		new string[MEDIUM_STRING_LEN];
		format(string, sizeof(string), MSG_LOGIN_DESC, PlayerInfo[playerid][PlayerName]);
		Dialog_ShowCallback(playerid, using inline Login, DIALOG_STYLE_PASSWORD, MSG_LOGIN_CAP, string, MSG_LOGIN_1ST, MSG_LOGIN_2ND);
	} else {
		if (strfind(PlayerInfo[playerid][PlayerName], "[SvT]", true) != -1) {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_TAG_NOT_ALLOWED);
			return SetTimerEx("DelayKick", 500, false, "i", playerid);
		}

		pVerified[playerid] = false;

		PlayerInfo[playerid][pDoNotDisturb] =
		PlayerInfo[playerid][pNoDuel] =
		PlayerInfo[playerid][pNoDogfight] = 0;

		PlayerInfo[playerid][pGUIEnabled] = 1;

		PlayerInfo[playerid][pSpawnKillTime] = 15;

		PlayerInfo[playerid][pRegDate] = gettime();
		PlayerInfo[playerid][pLastVisit] = gettime();

		inline RegisterPassword(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			if (!response) {
				Kick(pid);
				return false;
			}

			if (strlen(inputtext) < 4 || strlen(inputtext) > 24) {
				new string[MEDIUM_STRING_LEN];
				format(string, sizeof(string), MSG_REGISTER_DESC_ERROR_PASS, PlayerInfo[playerid][PlayerName]);
				Dialog_ShowCallback(playerid, using inline RegisterPassword, DIALOG_STYLE_PASSWORD, MSG_REGISTER_CAP_PASS, string, MSG_REGISTER_1ST, "");
				SendGameMessage(pid, X11_SERV_ERR, MSG_PASS_LEN);
				return false;
			}

			SetPVarString(pid, "TMP_Pass", inputtext);
			SendGameMessage(pid, X11_SERV_SUCCESS, MSG_PASS_ACCEPTED);

			CompleteRegistration(pid);
		}
		new string[MEDIUM_STRING_LEN];
		format(string, sizeof(string), MSG_REGISTER_DESC, PlayerInfo[playerid][PlayerName]);
		Dialog_ShowCallback(playerid, using inline RegisterPassword, DIALOG_STYLE_PASSWORD, MSG_REGISTER_CAP_PASS, string, MSG_REGISTER_1ST, "");
	}

    SetPlayerInterior(playerid, 0);
 	SetPlayerCameraPos(playerid, 1310.6155, 1675.9182, 110.7390);
 	SetPlayerCameraLookAt(playerid, 2285.2944, 1919.3756, 68.2275);
    Streamer_UpdateEx(playerid, 1310.6155, 1675.9182, 110.7390);
    return true;
}

//Load gameplay data

forward LoadPlayerDataTable(playerid);
public LoadPlayerDataTable(playerid) {
	new query[SMALL_STRING_LEN];

	if (cache_num_rows() > 0) {
		new Score, money;

		cache_get_value_int(0, "Score", Score);
		cache_get_value_int(0, "Cash", money);
		cache_get_value_int(0, "Kills", PlayerInfo[playerid][pKills]);
		cache_get_value_int(0, "Deaths", PlayerInfo[playerid][pDeaths]);
		cache_get_value_int(0, "GunFires", PlayerInfo[playerid][pGunFires]);
		cache_get_value_int(0, "IsJailed", PlayerInfo[playerid][pJailed]);
		cache_get_value_int(0, "JailTime", PlayerInfo[playerid][pJailTime]);
		cache_get_value_int(0, "ZonesCaptured", PlayerInfo[playerid][pZonesCaptured]);
		cache_get_value_int(0, "Headshots", PlayerInfo[playerid][pHeadshots]);
		cache_get_value_int(0, "KnifeKills", PlayerInfo[playerid][pKnifeKills]);
		cache_get_value_int(0, "Nutshots", PlayerInfo[playerid][pNutshots]);
		cache_get_value_int(0, "RevengeTakes", PlayerInfo[playerid][pRevengeTakes]);
		cache_get_value_int(0, "RustlerRockets", PlayerInfo[playerid][pRustlerRocketsFired]);
		cache_get_value_int(0, "RustlerRocketsHit", PlayerInfo[playerid][pRustlerRocketsHit]);
		cache_get_value_int(0, "DuelsWon", PlayerInfo[playerid][pDuelsWon]);
		cache_get_value_int(0, "DuelsLost", PlayerInfo[playerid][pDuelsLost]);
		cache_get_value_int(0, "MedkitsUsed", PlayerInfo[playerid][pMedkitsUsed]);
		cache_get_value_int(0, "ArmourkitsUsed", PlayerInfo[playerid][pArmourkitsUsed]);
		cache_get_value_int(0, "SupportAttempts", PlayerInfo[playerid][pSupportAttempts]);
		cache_get_value_int(0, "EXP", PlayerInfo[playerid][pEXPEarned]);
		cache_get_value_int(0, "KillAssists", PlayerInfo[playerid][pKillAssists]);
		cache_get_value_int(0, "CaptureAssists", PlayerInfo[playerid][pCaptureAssists]);
		cache_get_value_int(0, "HighestKillStreak", PlayerInfo[playerid][pHighestKillStreak]);
		cache_get_value_int(0, "SawedKills", PlayerInfo[playerid][pSawnKills]);
		cache_get_value_int(0, "AirRocketsFired", PlayerInfo[playerid][pAirRocketsFired]);
		cache_get_value_int(0, "AntiAirRocketsFired", PlayerInfo[playerid][pAntiAirRocketsFired]);
		cache_get_value_int(0, "CarePackagesDropped", PlayerInfo[playerid][Carepacks]);
		cache_get_value_name_float(0, "HealthLost", PlayerInfo[playerid][pHealthLost]);
		cache_get_value_name_float(0, "DamageRate", PlayerInfo[playerid][pDamageRate]);
		cache_get_value_int(0, "SMGKills", PlayerInfo[playerid][pSMGKills]);
		cache_get_value_int(0, "PistolKills", PlayerInfo[playerid][pPistolKills]);
		cache_get_value_int(0, "MeleeKills", PlayerInfo[playerid][pMeleeKills]);
		cache_get_value_int(0, "ShotgunKills", PlayerInfo[playerid][pShotgunKills]);
		cache_get_value_int(0, "HeavyKills", PlayerInfo[playerid][pHeavyKills]);
		cache_get_value_int(0, "FistKills", PlayerInfo[playerid][pFistKills]);
		cache_get_value_int(0, "CloseKills", PlayerInfo[playerid][pCloseKills]);
		cache_get_value_int(0, "DriversStabbed", PlayerInfo[playerid][pDriversStabbed]);
		cache_get_value_int(0, "SpiesEliminated", PlayerInfo[playerid][pSpiesEliminated]);
		cache_get_value_int(0, "KillsAsSpy", PlayerInfo[playerid][pKillsAsSpy]);
		cache_get_value_int(0, "LongDistanceKills", PlayerInfo[playerid][pLongDistanceKills]);
		cache_get_value_int(0, "WeaponsDropped", PlayerInfo[playerid][pWeaponsDropped]);
		cache_get_value_int(0, "WeaponsPicked", PlayerInfo[playerid][pWeaponsPicked]);
		cache_get_value_int(0, "EventsWon", PlayerInfo[playerid][pEventsWon]);
		cache_get_value_int(0, "RacesWon", PlayerInfo[playerid][pRacesWon]);
		cache_get_value_int(0, "ItemsUsed", PlayerInfo[playerid][pItemsUsed]);
		cache_get_value_int(0, "FavSkin", PlayerInfo[playerid][pFavSkin]);
		cache_get_value_int(0, "FavTeam", PlayerInfo[playerid][pFavTeam]);
		cache_get_value_int(0, "SuicideAttempts", PlayerInfo[playerid][pSuicideAttempts]);
		cache_get_value_int(0, "PlayersHealed", PlayerInfo[playerid][pPlayersHealed]);
		cache_get_value_int(0, "CommandsUsed", PlayerInfo[playerid][pCommandsUsed]);
		cache_get_value_int(0, "CommandsFailed", PlayerInfo[playerid][pCommandsFailed]);
		cache_get_value_int(0, "UnauthorizedActions", PlayerInfo[playerid][pUnauthorizedActions]);
		cache_get_value_int(0, "RCONLogins", PlayerInfo[playerid][pRCONLogins]);
		cache_get_value_int(0, "RCONFailedAttempts", PlayerInfo[playerid][pRCONFailedAttempts]);
		cache_get_value_int(0, "ClassAbilitiesUsed", PlayerInfo[playerid][pClassAbilitiesUsed]);
		cache_get_value_int(0, "DronesExploded", PlayerInfo[playerid][pDronesExploded]);
		cache_get_value_name_float(0, "HealthGained", PlayerInfo[playerid][pHealthGained]);
		cache_get_value_int(0, "InteriorsEntered", PlayerInfo[playerid][pInteriorsEntered]);
		cache_get_value_int(0, "InteriorsExitted", PlayerInfo[playerid][pInteriorsExitted]);
		cache_get_value_int(0, "PickupsPicked", PlayerInfo[playerid][pPickupsPicked]);
		cache_get_value_int(0, "QuestionsAsked", PlayerInfo[playerid][pQuestionsAsked]);
		cache_get_value_int(0, "QuestionsAnswered", PlayerInfo[playerid][pQuestionsAnswered]);
		cache_get_value_int(0, "CrashTimes", PlayerInfo[playerid][pCrashTimes]);
		cache_get_value_int(0, "BackupAttempts", PlayerInfo[playerid][pBackupAttempts]);
		cache_get_value_int(0, "BackupsResponded", PlayerInfo[playerid][pBackupsResponded]);
		cache_get_value_int(0, "BaseRapeAttempts", PlayerInfo[playerid][pBaseRapeAttempts]);
		cache_get_value_int(0, "ChatMessagesSent", PlayerInfo[playerid][pChatMessagesSent]);
		cache_get_value_int(0, "MoneySent", PlayerInfo[playerid][pMoneySent]);
		cache_get_value_int(0, "MoneyReceived", PlayerInfo[playerid][pMoneyReceived]);
		cache_get_value_int(0, "HighestBet", PlayerInfo[playerid][pHighestBet]);
		cache_get_value_int(0, "DuelRequests", PlayerInfo[playerid][pDuelRequests]);
		cache_get_value_int(0, "DuelsAccepted", PlayerInfo[playerid][pDuelsAccepted]);
		cache_get_value_int(0, "DuelsRefusedByPlayer", PlayerInfo[playerid][pDuelsRefusedByPlayer]);
		cache_get_value_int(0, "DuelsRefusedByOthers", PlayerInfo[playerid][pDuelsRefusedByOthers]);
		cache_get_value_int(0, "BountyAmount", PlayerInfo[playerid][pBountyAmount]);
		cache_get_value_int(0, "BountyCashSpent", PlayerInfo[playerid][pBountyCashSpent]);
		cache_get_value_int(0, "CoinsSpent", PlayerInfo[playerid][pCoinsSpent]);
		cache_get_value_int(0, "PaymentsAccepted", PlayerInfo[playerid][pPaymentsAccepted]);
		cache_get_value_int(0, "ClanKills", PlayerInfo[playerid][pClanKills]);
		cache_get_value_int(0, "ClanDeaths", PlayerInfo[playerid][pClanDeaths]);
		cache_get_value_int(0, "HighestCaptures", PlayerInfo[playerid][pHighestCaptures]);
		cache_get_value_int(0, "KicksByAdmin", PlayerInfo[playerid][pKicksByAdmin]);
		cache_get_value_name_float(0, "LongestKillDistance", PlayerInfo[playerid][pLongestKillDistance]);
		cache_get_value_name_float(0, "NearestKillDistance", PlayerInfo[playerid][pNearestKillDistance]);
		cache_get_value_int(0, "HighestCaptureAssists", PlayerInfo[playerid][pHighestCaptureAssists]);
		cache_get_value_int(0, "HighestKillAssists", PlayerInfo[playerid][pHighestKillAssists]);
		cache_get_value_int(0, "BountyPlayersKilled", PlayerInfo[playerid][pBountyPlayersKilled]);
		cache_get_value_int(0, "PrototypesStolen", PlayerInfo[playerid][pPrototypesStolen]);
		cache_get_value_int(0, "AntennasDestroyed", PlayerInfo[playerid][pAntennasDestroyed]);
		cache_get_value_int(0, "CratesOpened", PlayerInfo[playerid][pCratesOpened]);
		cache_get_value_int(0, "LastPing", PlayerInfo[playerid][pLastPing]);
		cache_get_value_name_float(0, "LastPacketLoss", PlayerInfo[playerid][pLastPacketLoss]);
		cache_get_value_int(0, "HighestPing", PlayerInfo[playerid][pHighestPing]);
		cache_get_value_int(0, "LowestPing", PlayerInfo[playerid][pLowestPing]);
		cache_get_value_int(0, "NukesLaunched", PlayerInfo[playerid][pNukesLaunched]);
		cache_get_value_int(0, "AirstrikesCalled", PlayerInfo[playerid][pAirstrikesCalled]);
		cache_get_value_int(0, "AnthraxIntoxications", PlayerInfo[playerid][pAnthraxIntoxications]);
		cache_get_value_int(0, "PUBGEventsWon", PlayerInfo[playerid][pPUBGEventsWon]);
		cache_get_value_int(0, "RopeRappels", PlayerInfo[playerid][pRopeRappels]);
		cache_get_value_int(0, "AreasEntered", PlayerInfo[playerid][pAreasEntered]);
		cache_get_value_int(0, "LastAreaId", PlayerInfo[playerid][pLastAreaId]);
		cache_get_value_name_float(0, "LastPosX", PlayerInfo[playerid][pLastPosX]);
		cache_get_value_name_float(0, "LastPosY", PlayerInfo[playerid][pLastPosY]);
		cache_get_value_name_float(0, "LastPosZ", PlayerInfo[playerid][pLastPosZ]);
		cache_get_value_name_float(0, "LastHealth", PlayerInfo[playerid][pLastHealth]);
		cache_get_value_name_float(0, "LastArmour", PlayerInfo[playerid][pLastArmour]);
		cache_get_value_int(0, "TimeSpentOnFoot", PlayerInfo[playerid][pTimeSpentOnFoot]);
		cache_get_value_int(0, "TimeSpentInCar", PlayerInfo[playerid][pTimeSpentInCar]);
		cache_get_value_int(0, "TimeSpentAsPassenger", PlayerInfo[playerid][pTimeSpentAsPassenger]);
		cache_get_value_int(0, "TimeSpentInSelection", PlayerInfo[playerid][pTimeSpentInSelection]);
		cache_get_value_int(0, "TimeSpentAFK", PlayerInfo[playerid][pTimeSpentAFK]);
		cache_get_value_int(0, "DriveByKills", PlayerInfo[playerid][pDriveByKills]);
		cache_get_value_int(0, "CashAdded", PlayerInfo[playerid][pCashAdded]);
		cache_get_value_int(0, "CashReduced", PlayerInfo[playerid][pCashReduced]);
		cache_get_value_int(0, "LastInterior", PlayerInfo[playerid][pLastInterior]);
		cache_get_value_int(0, "LastVirtualWorld", PlayerInfo[playerid][pLastVirtualWorld]);

		SetPlayerScore(playerid, Score);
		Ranks_GetPlayer(playerid);

		ResetPlayerCash(playerid);
		pMoney[playerid] = money;
		GivePlayerMoney(playerid, money);
	} else {
		mysql_format(Database, query, sizeof(query), "INSERT INTO `PlayersData` (`pID`) VALUES('%d')", PlayerInfo[playerid][pAccountId]);
		mysql_tquery(Database, query);
		SetPlayerScore(playerid, 0);
		Ranks_GetPlayer(playerid);
		ResetPlayerCash(playerid);
	}
	return 1;
}

//Load player configuration

forward LoadPlayerConfiguration(playerid);
public LoadPlayerConfiguration(playerid) {
	if (cache_num_rows() > 0) {
		cache_get_value_int(0, "DoNotDisturb", PlayerInfo[playerid][pDoNotDisturb]);
		cache_get_value_int(0, "NoDuel", PlayerInfo[playerid][pNoDuel]);
		cache_get_value_int(0, "NoDogfights", PlayerInfo[playerid][pNoDogfight]);
		cache_get_value_name_bool(0, "NoTutor", PlayerInfo[playerid][pNoTutor]);
		cache_get_value_int(0, "GUIEnabled", PlayerInfo[playerid][pGUIEnabled]);
		cache_get_value_int(0, "SpawnKillTime", PlayerInfo[playerid][pSpawnKillTime]);
		cache_get_value_int(0, "AllowWatch", PlayerInfo[playerid][pAllowWatch]);
	} else {
		new query[100];

		mysql_format(Database, query, sizeof(query), "INSERT INTO `PlayersConf` (`pID`) VALUES ('%d')", PlayerInfo[playerid][pAccountId]);
		mysql_tquery(Database, query);

		PlayerInfo[playerid][pDoNotDisturb] =
		PlayerInfo[playerid][pAllowWatch] =
		PlayerInfo[playerid][pNoDuel] =
		PlayerInfo[playerid][pNoDogfight] = 0;

		PlayerInfo[playerid][pGUIEnabled] = 1;
		PlayerInfo[playerid][pSpawnKillTime] = 15;
	}
	return 1;
}

//Load player data
LoginPlayer(playerid) {
	new ip[MAX_IP_LEN];
	cache_set_active(PlayerInfo[playerid][pCacheId]);
	cache_get_value_int(0, "ID", PlayerInfo[playerid][pAccountId]);
	cache_get_value_int(0, "AdminLevel", PlayerInfo[playerid][pAdminLevel]);
	cache_get_value_int(0, "DonorLevel", PlayerInfo[playerid][pDonorLevel]);
	cache_get_value_int(0, "Coins", PlayerInfo[playerid][pCoins]);
	cache_get_value_int(0, "ClanId", pClan[playerid]);
	cache_get_value_int(0, "ClanRank", pClanRank[playerid]);
	cache_get_value_int(0, "PlayTime", PlayerInfo[playerid][pTimePlayed]);
	cache_get_value_int(0, "RegDate", PlayerInfo[playerid][pRegDate]);
	cache_get_value_int(0, "LastVisit", PlayerInfo[playerid][pLastVisit]);
	cache_get_value_int(0, "TimesLoggedIn", PlayerInfo[playerid][pTimesLoggedIn]);
	cache_get_value_int(0, "Warnings", PlayerInfo[playerid][pAccountWarnings]);
	cache_get_value_int(0, "AntiCheatWarnings", PlayerInfo[playerid][pAntiCheatWarnings]);
	cache_get_value_int(0, "PlayerReports", PlayerInfo[playerid][pPlayerReports]);
	cache_get_value_int(0, "SpamAttempts", PlayerInfo[playerid][pSpamAttempts]);
	cache_get_value_int(0, "AdvAttempts", PlayerInfo[playerid][pAdvAttempts]);
	cache_get_value_int(0, "AntiSwearBlocks", PlayerInfo[playerid][pAntiSwearBlocks]);
	cache_get_value_int(0, "TagPermitted", PlayerInfo[playerid][pTagPermitted]);
	cache_get_value_int(0, "ReportAttempts", PlayerInfo[playerid][pReportAttempts]);
	cache_get_value_int(0, "BannedTimes", PlayerInfo[playerid][pBannedTimes]);
	cache_get_value_int(0, "BannedTimes", PlayerInfo[playerid][pBannedTimes]);
	cache_get_value_name(0, "IP", ip, MAX_IP_LEN);

	LogConnection(playerid, 3, gettime());

	new rank[9];
	if (PlayerInfo[playerid][pDonorLevel] > 1) {
		PlayerInfo[playerid][pDonorLevel] = 1;
	}
	switch (PlayerInfo[playerid][pDonorLevel]) {
		case 0: rank = "regular";
		case 1: rank = "vip";
	}

	/*inline LoginSucc(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused response, dialogid, listitem, inputtext

		new whole_update[2047];
		for (new i = 0; i < sizeof(Changelog); i++) {
			format(whole_update, sizeof(whole_update), "%s\n%s", whole_update, Changelog[i]);
		}
		Dialog_Show(pid, DIALOG_STYLE_MSGBOX, Version, whole_update, "X");
	}*/

	new details[515];
	format(details, sizeof(details),
	""WHITE"Your last IP: %s\nYour current IP: %s\nLast visit: %s\nAccount: %s-%d\nHave a nice session!",
	ip, PlayerInfo[playerid][pIP], GetWhen(PlayerInfo[playerid][pLastVisit], gettime()), rank, PlayerInfo[playerid][pDonorLevel]);
	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Logged In to SvT!", details, "Play!");

	DeletePVar(playerid, "TMP_Pass");

	Update3DTextLabelText(RankLabel[playerid], 0xFFFFFFFF, " ");

	new query[240];

	mysql_format(Database, query, sizeof(query),
	"SELECT * FROM `PlayersData` WHERE `pID` = '%d'", PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query, "LoadPlayerDataTable", "i", playerid);


	mysql_format(Database, query, sizeof(query),
	"SELECT * FROM `PlayersConf` WHERE `pID` = '%d'", PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query, "LoadPlayerConfiguration", "i", playerid);

	PlayerInfo[playerid][pLoggedIn] = 1;

	Achievements_InitializePlayer(playerid);

	cache_delete(PlayerInfo[playerid][pCacheId]);
	PlayerInfo[playerid][pCacheId] = MYSQL_INVALID_CACHE;

	ReloadPrivileges(playerid);

	if (!ComparePrivileges(playerid, CMD_MEMBER) &&
			!PlayerInfo[playerid][pTagPermitted] &&
			strfind(PlayerInfo[playerid][PlayerName], "[SvT]", true) != -1) {
		SendGameMessage(playerid, X11_SERV_WARN, MSG_TAG_NOT_ALLOWED);
		return SetTimerEx("DelayKick", 500, false, "i", playerid);
	}
	TogglePlayerSpectating(playerid, false);
	ShowPlayerBasicSUI(playerid);
	Team_AddPlayerToBalanced(playerid);
	Weapons_LoadPlayer(playerid);
	Items_LoadPlayer(playerid);
	return true;
}

//Admin
ReloadPrivileges(playerid) {
	new i = PlayerInfo[playerid][pAdminLevel];
	switch (i) {
		case 1: pPrivileges[playerid] = CMD_MEMBER;
		case 2: pPrivileges[playerid] = CMD_MEMBER | CMD_OPERATOR;
		case 3: pPrivileges[playerid] = CMD_MEMBER | CMD_OPERATOR | CMD_OWNER;
		default: {
			if (IsPlayerAdmin(playerid)) {
				PlayerInfo[playerid][pAdminLevel] = MAX_ADMIN_RANKS;
				ReloadPrivileges(playerid);
			} else {
				pPrivileges[playerid] = 0;
			}
		}
	}
	return 1;
}

//Email syntax validity checkup
stock IsValidEmail(const text[]) {
	if (isnull(text)) return false;
	new Regex:r = Regex_New("[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+");
	new check = Regex_Check(text, r);
	Regex_Delete(r);
	return check;
}

//bcrypt
forward StoreRegPassword(playerid);
public StoreRegPassword(playerid) {
	new pass[MAX_PASS_LEN];
	GetPVarString(playerid, "TMP_Pass", pass, sizeof(pass));
	bcrypt_get_hash(pass);

	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `Password` = '%e', `Salt` = NULL WHERE `ID` = '%d' LIMIT 1", pass, PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);

	DeletePVar(playerid, "TMP_Pass");
	return 1;
}

//Successful registration callback to retrieve account ID and continue
forward OnPlayerRegister(playerid, string:password[MAX_PASS_LEN]);
public OnPlayerRegister(playerid, string:password[MAX_PASS_LEN]) {
	PlayerInfo[playerid][pAccountId] = cache_insert_id();
	pVerified[playerid] = true;
	SendGameMessage(playerid, X11_SERV_SUCCESS, MSG_ACC_CREATED);

	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `PlayersData` (`pID`) VALUES('%d')", PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);
	mysql_format(Database, query, sizeof(query), "INSERT INTO `PlayersConf` (`pID`) VALUES('%d')", PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, query);
	bcrypt_hash(playerid, "StoreRegPassword", password, BCRYPT_COST);

	new randbon=random(20) + 15;
	GivePlayerScore(playerid, randbon);
	new string[128];
	format(string, sizeof(string), "[GIFT] You got %d score for registration. THANK YOU!", randbon);
	SendClientMessage(playerid, X11_GREEN, string);
	TogglePlayerSpectating(playerid, false);
	ShowPlayerBasicSUI(playerid);
	Team_AddPlayerToBalanced(playerid);
	return 1;
}

//Complete players' registration
CompleteRegistration(playerid) {

	/*inline RegSucc(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem, inputtext

		new whole_update[2047];
		for (new i = 0; i < sizeof(Changelog); i++) {
			format(whole_update, sizeof(whole_update), "%s\n%s", whole_update, Changelog[i]);
		}
		Dialog_Show(pid, DIALOG_STYLE_MSGBOX, Version, whole_update, "X");
	}*/
	new pass[MAX_PASS_LEN];
	GetPVarString(playerid, "TMP_Pass", pass, sizeof(pass));

	new details[1024];
	format(details, sizeof(details),
	""WHITE"Thank you for registering an account on SvT!\n\n\
	We will be storing your progress on this account for the next sessions.\n\n\
	Please don't use cheats and follow our community rules written in /rules.\n\
	You can use /cmds and /help for info, or use /ask to contact our admins.\n\
	IF you spotted a cheater cooperate with us and use /report, if no admins are online simply /votekick!\n\n\
	Your IP address: %s\n\
	Your password: %s\n\n\
	WE will not ask you for your password, and it will be encrypted on our server. So, we can't recover it!\n\
	Thank you for supporting our server, have fun and play it nicely. ;)",
	PlayerInfo[playerid][pIP], pass);
	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Newly Registered On SvT!", details, "Play!");

	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `Players` (`Username`,`IP`,`RegDate`,`LastVisit`) \
	VALUES('%e','%e','%d','%d')", PlayerInfo[playerid][PlayerName], PlayerInfo[playerid][pIP], gettime(), gettime());
	mysql_tquery(Database, query, "OnPlayerRegister", "ds", playerid, pass);

	SetPlayerScore(playerid, 0);
	Ranks_GetPlayer(playerid);

	ResetPlayerCash(playerid);

	GivePlayerCash(playerid, 500000);

	PlayerInfo[playerid][pGUIEnabled] = 1;
	PlayerInfo[playerid][pSpawnKillTime] = 15;
	PlayerInfo[playerid][pRegDate] = gettime();
	PlayerInfo[playerid][pLastVisit] = gettime();
	PlayerInfo[playerid][pLoggedIn] = 1;

	Achievements_InitializePlayer(playerid);
	return 1;
}

//Notifiers

forward EndNotification(playerid);
public EndNotification(playerid) {
	KillTimer(NotifierTimer[playerid]);
	PlayerTextDrawHide(playerid, Notifier_PTD[playerid]);
	//TextDrawHideForPlayer(playerid, Notifier_TD);
	return 1;
}

forward HideCarInfo(playerid);
public HideCarInfo(playerid) {
	PlayerTextDrawHide(playerid, CarInfoPTD[playerid][0]);
	PlayerTextDrawHide(playerid, CarInfoPTD[playerid][1]);
	PlayerTextDrawHide(playerid, CarInfoPTD[playerid][2]);

	TextDrawHideForPlayer(playerid, CarInfoTD[0]);
	TextDrawHideForPlayer(playerid, CarInfoTD[1]);
	TextDrawHideForPlayer(playerid, CarInfoTD[2]);
	TextDrawHideForPlayer(playerid, CarInfoTD[3]);
	PlayerInfo[playerid][pCarInfoDisplayed] = 0;
	return 1;
}

ShowCarInfo(playerid, const car_name[30], const car_desc[125], const requirements[45]) {
	new string[130];

	format(string, sizeof(string), "~y~Model~w~: %s", car_name);
	PlayerTextDrawSetString(playerid, CarInfoPTD[playerid][0], string);

	format(string, sizeof(string), "~y~Abilities~w~: %s", car_desc);
	PlayerTextDrawSetString(playerid, CarInfoPTD[playerid][1], string);

	format(string, sizeof(string), "~y~Requirments~w~: %s", requirements);
	PlayerTextDrawSetString(playerid, CarInfoPTD[playerid][2], string);

	PlayerTextDrawShow(playerid, CarInfoPTD[playerid][0]);
	PlayerTextDrawShow(playerid, CarInfoPTD[playerid][1]);
	PlayerTextDrawShow(playerid, CarInfoPTD[playerid][2]);

	TextDrawShowForPlayer(playerid, CarInfoTD[0]);
	TextDrawShowForPlayer(playerid, CarInfoTD[1]);
	TextDrawShowForPlayer(playerid, CarInfoTD[2]);
	TextDrawShowForPlayer(playerid, CarInfoTD[3]);

	PlayerInfo[playerid][pCarInfoDisplayed] = 1;
	KillTimer(CarInfoTimer[playerid]);
	CarInfoTimer[playerid] = SetTimerEx("HideCarInfo", 4000, false, "i", playerid);
	return 1;
}

NotifyPlayer(playerid, const message[], sound = 0) {
	if (!PlayerInfo[playerid][pLoggedIn] || !IsPlayerSpawned(playerid)) return false;
	PlayerTextDrawSetString(playerid, Notifier_PTD[playerid], message);
	PlayerTextDrawShow(playerid, Notifier_PTD[playerid]);
	//TextDrawShowForPlayer(playerid, Notifier_TD);
	KillTimer(NotifierTimer[playerid]);
	NotifierTimer[playerid] = SetTimerEx("EndNotification", 7000, false, "i", playerid);
	if (sound) {
		PlayerPlaySound(playerid, 3600, 0.0, 0.0, 0.0);
	}
	return 1;
}

SendWarUpdate(const msg[]) {
	for (new i = 0; i < sizeof(WarStatusTD); i++) {
		format(WarStatusStr[i], 128, WarStatusStr[i + 1]);
		TextDrawSetString(WarStatusTD[i], WarStatusStr[i]);
	}
	format(WarStatusStr[sizeof(WarStatusTD) - 1], 128, msg);
	TextDrawSetString(WarStatusTD[sizeof(WarStatusTD) - 1], WarStatusStr[sizeof(WarStatusTD) - 1]);
	foreach (new i: Player) {
		UpdatePlayerHUD(i);
	}
	return 1;
}

//Loot system

DropPlayerItem(playerid, item, amount) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) || amount == 0 ||
		Items_GetPlayer(playerid, item) < amount || Items_GetPlayer(playerid, item) <= 0) return -1;
	Items_AddPlayer(playerid, item, -amount);

	new Float: Checkpos[3], Float: Check_X;
	GetPlayerPos(playerid, Checkpos[0], Checkpos[1], Checkpos[2]);

	CA_FindZ_For2DCoord(Checkpos[0], Checkpos[1], Check_X);
	if (Checkpos[2] < Check_X) return -1;

	new
		Float: FX,
		Float: FY,
		Float: FZ
	;

	GetPlayerPos(playerid, FX, FY, FZ);

	new dropped = 0;

	for (new i = 0; i < MAX_SLOTS; i++) {
		if (!gLootExists[i]) {
			GetPlayerPos(playerid, FX, FY, FZ);
			CA_FindZ_For2DCoord(FX, FY, FZ);

			gLootExists[i] = 1;
			gLootPickable[i] = 0;

			gLootItem[i] = item;
			gLootAmt[i] = amount;

			new Float: RX = 0.0;

			if (item != MASK && item != HELMET && item != LANDMINES) {
				RX = 90.0;
			}

			gLootObj[i] = CreateDynamicObject(Items_GetObject(item), FX + 0.5, FY, FZ + 0.1, RX, 0.0, 12.5);
			gLootPickable[i] = 1;

			gLootArea[i] = CreateDynamicSphere(FX, FY, FZ,5.0,-1,0);

			KillTimer(gLootTimer[i]);
			gLootTimer[i] = SetTimerEx("AlterLootPickup", 55000, false, "i", i);

			dropped = 1;

			break;
		}
	}

	if (!dropped) return -1;
	return item;
}

stock DropPlayerItems(playerid) {
	new Float: Checkpos[3], Float: Check_X;
	GetPlayerPos(playerid, Checkpos[0], Checkpos[1], Checkpos[2]);

	CA_FindZ_For2DCoord(Checkpos[0], Checkpos[1], Check_X);
	if (Checkpos[2] < Check_X) return 1;

	new pitems;
	for (new i = 0; i < MAX_ITEMS; i++) {
		if (Items_GetPlayer(playerid, i)) {
			pitems ++;
		}
	}

	new
		Float: FX,
		Float: FY,
		Float: FZ
	;

	GetPlayerPos(playerid, FX, FY, FZ);

	if (pitems) {
		for (new i = 0; i < MAX_SLOTS; i++) {
			if (!gLootExists[i]) {
				for (new x = 0; x < MAX_ITEMS; x++) {
					if (Items_GetPlayer(playerid, x) > 0) {
						new Float: RX = 0.0;

						if (x != MASK && x != HELMET && x != LANDMINES) {
							RX = 90.0;
						}

						gLootPickable[i] = 0;
						CA_FindZ_For2DCoord(FX, FY, FZ);
						gLootItem[i] = x;
						gLootAmt[i] = Items_GetPlayer(playerid, x);
						gLootObj[i] = CreateDynamicObject(Items_GetObject(x), FX, FY, FZ + 0.1, RX, 0.0, 12.5);
						gLootArea[i] = CreateDynamicSphere(FX, FY, FZ,5.0,-1,0);
						gLootPickable[i] = 1;
						Items_RemovePlayer(playerid, x);

						new randposchange = random(7);
						switch (randposchange) {
							case 0: FX += 2.0, FY -= 2.0;
							case 1: FX += 2.2, FY -= 2.2;
							case 2: FX += 2.4, FY -= 2.4;
							case 3: FX += 2.6, FY -= 2.6;
							case 4: FX -= 2.0, FY += 2.0;
							case 5: FX -= 2.2, FY += 2.2;
							case 6: FX -= 2.4, FY += 2.4;
						}
						KillTimer(gLootTimer[i]);
						gLootTimer[i] = SetTimerEx("AlterLootPickup", 7000, false, "i", i);
						gLootExists[i] = 1;
						break;
					}
				}
			}
		}
	}
	return 1;
}

//Anti-cheat

AntiCheatAlert(playerid, const cheat[]) {
	if (IsPlayerSpawned(playerid) && PlayerInfo[playerid][pACCooldown] < gettime()) {
		foreach (new i: Player) {
			if (ComparePrivileges(i, CMD_MEMBER)) {
				SendGameMessage(i, X11_SERV_WARN, MSG_AC_SUSPECT, PlayerInfo[playerid][PlayerName], playerid, PlayerInfo[playerid][pIP], cheat);
			}
		}
		PlayerInfo[playerid][pACCooldown] = gettime() + 5;
		PlayerInfo[playerid][pAntiCheatWarnings] ++;
	}
	LogCheat(playerid, cheat, gettime());
	return 1;
}

forward DestroyMedkit(medkitid);
public DestroyMedkit(medkitid) {
	DestroyDynamicObject(medkitid);
	return 1;
}

forward DestroyArmourkit(armourkitid);
public DestroyArmourkit(armourkitid) {
	DestroyDynamicObject(armourkitid);
	return 1;
}

forward PickupItem(playerid, objectid);
public PickupItem(playerid, objectid) {
	if (gLootAmt[objectid] && Items_AddPlayer(playerid, gLootItem[objectid], gLootAmt[objectid])) {
		new message[95];
		format(message, sizeof(message), "Picked up a/an %s", Items_GetName(gLootItem[objectid]));
		NotifyPlayer(playerid, message);
		gLootAmt[objectid] = 0;
		gLootItem[objectid] = 0;
		ApplyAnimation(playerid, "MISC", "PICKUP_box", 3.0, 0, 0, 0, 0, 0);
		gLootPickable[objectid] = 0;
		if (IsValidDynamicObject(gLootObj[objectid])) {
			DestroyDynamicObject(gLootObj[objectid]);
		}
		gLootObj[objectid] = INVALID_OBJECT_ID;
		if (IsValidDynamicArea(gLootArea[objectid])) {
			DestroyDynamicArea(gLootArea[objectid]);
		}
		KillTimer(gLootTimer[objectid]);
		gLootExists[objectid] = 0;
	}
	return 1;
}

forward AlterLootPickup(objectid);
public AlterLootPickup(objectid) {
	KillTimer(gLootTimer[objectid]);
	gLootExists[objectid] = 0;
	gLootPickable[objectid] = 0;
	gLootItem[objectid] = 0;
	if (IsValidDynamicObject(gLootObj[objectid])) {
		DestroyDynamicObject(gLootObj[objectid]);
		gLootObj[objectid] = INVALID_OBJECT_ID;
	}
	gLootObj[objectid] = INVALID_OBJECT_ID;
	if (IsValidDynamicArea(gLootArea[objectid])) {
		DestroyDynamicArea(gLootArea[objectid]);
		gLootArea[objectid] = -1;
	}
	gLootAmt[objectid] = 0;
	gLootPUBG[objectid] = 0;
	return 1;
}

//Medic kits

forward UseMK(playerid);
public UseMK(playerid) {
	new Float:HP;
	GetPlayerHealth(playerid, HP);
	if (gMedicKitHP[playerid] > 0.0) {
		gMedicKitHP[playerid] -= 1.0;
		SetPlayerHealth(playerid, ReturnHealth(playerid) + 1.0);
		GameTextForPlayer(playerid, "~g~+1 HP", 900, 3);
		PlayerInfo[playerid][pHealthGained] += 5.0;
	} else {
		gMedicKitStarted[playerid] = false;
		KillTimer(RecoverTimer[playerid]);
		Items_AddPlayer(playerid, MK, -1);
		PlayerInfo[playerid][pMedkitsUsed]++;
	}
	return 1;
}

//Armour kits

forward UseAK(playerid);
public UseAK(playerid) {
	new Float: AR;
	GetPlayerArmour(playerid, AR);

	Items_AddPlayer(playerid, AK, -1);
	PlayerInfo[playerid][pArmourkitsUsed]++;

	SetPlayerArmour(playerid, AR + 25.0);
	GetPlayerArmour(playerid, AR);
	return 1;
}

//Anticheat

public OnAntiCheatLagTroll(playerid) {
	AntiCheatAlert(playerid, "Troll Hack");
	return Kick(playerid);
}

public OnPlayerBreakAir(playerid, breaktype) {
	AntiCheatAlert(playerid, "Airbreak");
	return Kick(playerid);
}

public OnAntiCheatPlayerSpoof(playerid) {
	AntiCheatAlert(playerid, "Player Spoof");
	return Kick(playerid);
}

public OnPlayerWeaponHack(playerid, weaponid) {
	foreach (new i: Player) {
		if (ComparePrivileges(i, CMD_MEMBER)) {
			SendGameMessage(i, X11_SERV_WARN, MSG_AC_WH, PlayerInfo[playerid][PlayerName], playerid, ReturnWeaponName(weaponid));
		}
	}
	SetPlayerAmmo(playerid, weaponid, 0);
	return 1;
}

public OnPlayerFlyHack(playerid) {
	AntiCheatAlert(playerid, "Fly Hack");
	return Kick(playerid);
}

public OnPlayerSuspectedForAimbot(playerid, hitid, weaponid, warnings) {
	if(warnings & WARNING_OUT_OF_RANGE_SHOT) {
		foreach (new i: Player) {
			if (ComparePrivileges(i, CMD_MEMBER)) {
				SendGameMessage(i, X11_SERV_WARN, MSG_PROAIM_1, PlayerInfo[playerid][PlayerName], playerid, ReturnWeaponName(weaponid), BustAim::GetNormalWeaponRange(weaponid));
			}
		}
	}
	if(warnings & WARNING_PROAIM_TELEPORT) {
		foreach (new i: Player) {
			if (ComparePrivileges(i, CMD_MEMBER)) {
				SendGameMessage(i, X11_SERV_WARN, MSG_PROAIM_2, PlayerInfo[playerid][PlayerName], playerid);
			}
		}
	}
	if(warnings & WARNING_RANDOM_AIM) {
		foreach (new i: Player) {
			if (ComparePrivileges(i, CMD_MEMBER)) {
				SendGameMessage(i, X11_SERV_WARN, MSG_PROAIM_3, PlayerInfo[playerid][PlayerName], playerid, ReturnWeaponName(weaponid));
			}
		}
	}
	if(warnings & WARNING_CONTINOUS_SHOTS) {
		foreach (new i: Player) {
			if (ComparePrivileges(i, CMD_MEMBER)) {
				SendGameMessage(i, X11_SERV_WARN, MSG_PROAIM_4, PlayerInfo[playerid][PlayerName], playerid, ReturnWeaponName(weaponid), weaponid);
			}
		}
	}
	return 0;
}

//Server config

GetPlayerConfigValue(playerid, const opt[]) {
	switch (YHash(opt)) {
		case _H<DND>: return PlayerInfo[playerid][pDoNotDisturb];
		case _H<NODUEL>: return PlayerInfo[playerid][pNoDuel];
		case _H<NODOGFIGHT>: return PlayerInfo[playerid][pNoDogfight];
		case _H<HUD>: return PlayerInfo[playerid][pGUIEnabled];
		case _H<ANTISKTIME>: return PlayerInfo[playerid][pSpawnKillTime];
		case _H<WATCH>: return PlayerInfo[playerid][pAllowWatch];
	}
	return 0;
}

SetPlayerConfigValue(playerid, const opt[], val) {
	switch (YHash(opt)) {
		case _H<DND>: PlayerInfo[playerid][pDoNotDisturb] = val;
		case _H<NODUEL>: PlayerInfo[playerid][pNoDuel] = val;
		case _H<NODOGFIGHT>: PlayerInfo[playerid][pNoDogfight] = val;
		case _H<HUD>: PlayerInfo[playerid][pGUIEnabled] = val;
		case _H<ANTISKTIME>: PlayerInfo[playerid][pSpawnKillTime] = val;
		case _H<WATCH>: PlayerInfo[playerid][pAllowWatch] = val;
	}
	return 1;
}

//Resync the player to the stored data
ResyncData(playerid) {
	SetPlayerSkin(playerid, gOldSkin[playerid]);
	SetPlayerInterior(playerid, gOldInt[playerid]);
	SetPlayerVirtualWorld(playerid, gOldWorld[playerid]);
	SetPlayerPos(playerid, gOldPos[playerid][0], gOldPos[playerid][1], gOldPos[playerid][2]);
	SetPlayerFacingAngle(playerid, gOldPos[playerid][3]);
	SetPlayerColor(playerid, gOldCol[playerid]);
	for (new i = 0; i < 13; i++) {
		GivePlayerWeapon(playerid, gOldWeaps[playerid][i], gOldAmmo[playerid][i]);
	}
	pStreak[playerid] = gOldSpree[playerid];
	if (gOldVID[playerid] != -1) {
		PutPlayerInVehicle(playerid, gOldVID[playerid], 0);
	}
	UpdateLabelText(playerid);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_SYNC);
	ForceSync[playerid] = 0;
	return 1;
}

//Save the player data to sync them later
StoreData(playerid) {
	gOldInt[playerid] = GetPlayerInterior(playerid);
	gOldWorld[playerid] = GetPlayerVirtualWorld(playerid);
	gOldSkin[playerid] = GetPlayerSkin(playerid);
	GetPlayerPos(playerid, gOldPos[playerid][0], gOldPos[playerid][1], gOldPos[playerid][2]);
	GetPlayerFacingAngle(playerid, gOldPos[playerid][3]);
	gOldSpree[playerid] = pStreak[playerid];
	gOldVID[playerid] = GetPlayerVehicleID(playerid);
	for (new i = 0; i < 13; i++) {
		GetPlayerWeaponData(playerid, i, gOldWeaps[playerid][i], gOldAmmo[playerid][i]);
	}
	ForceSync[playerid] = 1;
	gOldCol[playerid] = GetPlayerColor(playerid);
	return 1;
}

forward Respawn(playerid);
public Respawn(playerid) {
	return TogglePlayerSpectating(playerid, false);
}

forward InitPlayer(playerid);
public InitPlayer(playerid) {
	switch (GetPlayerGameMode(playerid)) {
		case MODE_BATTLEFIELD: {
			SetPlayerHealth(playerid, 100.0);
		}
		case MODE_DEATHMATCH: {
			SetPlayerHealth(playerid, 100.0);
			SetPlayerArmour(playerid, 100.0);
			if (PlayerInfo[playerid][pDeathmatchId] == 5) {
				CarSpawner(playerid, 464);
			}
			if (PlayerInfo[playerid][pDeathmatchId] == 7) {
				CarSpawner(playerid, 432);
			}
		}
		case MODE_DUEL: {
			SetPlayerHealth(playerid, 100.0);
			SetPlayerArmour(playerid, 100.0);
			PlayGoSound(playerid);
			PlayGoSound(TargetOf[playerid]);
			pDuelInfo[playerid][pDLocked] = 0;
			if (!pDuelInfo[playerid][pDRCDuel]) {
				GivePlayerWeapon(playerid, pDuelInfo[playerid][pDWeapon], pDuelInfo[playerid][pDAmmo]);
				GivePlayerWeapon(playerid, pDuelInfo[playerid][pDWeapon2], pDuelInfo[playerid][pDAmmo2]);
				SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 1000);
			} else {
				if (pDuelInfo[playerid][pDRCDuel]) CarSpawner(playerid, 464);
			}
		}
	}

	//If player is frozen, they shouldn't be able to move yet
	if (PlayerInfo[playerid][pFrozen]) {
		TogglePlayerControllable(playerid, false);
	} else {
		TogglePlayerControllable(playerid, true);
	}
	return 1;
}

SetupPlayerSpawn(playerid) {
	if (!IsPlayerAnimsPreloaded[playerid]) {
		AnimPreloadForPlayer(playerid, "BOMBER");
		AnimPreloadForPlayer(playerid, "RAPPING");
		AnimPreloadForPlayer(playerid, "SHOP");
		AnimPreloadForPlayer(playerid, "BEACH");
		AnimPreloadForPlayer(playerid, "SMOKING");
		AnimPreloadForPlayer(playerid, "FOOD");
		AnimPreloadForPlayer(playerid, "ON_LOOKERS");
		AnimPreloadForPlayer(playerid, "DEALER");
		ApplyAnimation(playerid, "ROB_BANK", "null", 0.0, false, false, false, false, 0, false);

		IsPlayerAnimsPreloaded[playerid] = 1;
	}

	if (IsPlayerAnimsPreloaded[playerid] == 1) {
		AnimPreloadForPlayer(playerid, "CRACK");
		AnimPreloadForPlayer(playerid, "CARRY");
		AnimPreloadForPlayer(playerid, "COP_AMBIENT");
		AnimPreloadForPlayer(playerid, "PARK");
		AnimPreloadForPlayer(playerid, "INT_HOUSE");
		AnimPreloadForPlayer(playerid, "FOOD");
		AnimPreloadForPlayer(playerid, "GYMNASIUM");
		AnimPreloadForPlayer(playerid, "benchpress");
		AnimPreloadForPlayer(playerid, "Freeweights");

		IsPlayerAnimsPreloaded[playerid] = 2;
	}
	return 1;
}

EndProtection(playerid) {
	gInvisible[playerid] = false;

	//Update player marker status
	UpdateLabelText(playerid);

	//Remove spawn protection sprite if it exists
	if (IsPlayerAttachedObjectSlotUsed(playerid, 8)) {
		RemovePlayerAttachedObject(playerid, 8);
	}

	UpdatePlayerHUD(playerid);

	AntiSK[playerid] = 0;
	AntiSKStart[playerid] = 0;

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		//Invisibile players
		gInvisibleTime[playerid] = gettime();
		if (PlayerInfo[playerid][pDonorLevel]) {
			gInvisible[playerid] = true;
			gInvisibleTime[playerid] += 60 * 5;
		}
		if ((p_ClassAbilities(playerid, SNIPER)) && p_ClassAdvanced(playerid)) {
			gInvisible[playerid] = true;
			gInvisibleTime[playerid] += 60 * 15;
		}
		if ((p_ClassAbilities(playerid, RECON))) {
			gInvisible[playerid] = true;
			gInvisibleTime[playerid] += 60 * 30;
		}
		if (gInvisible[playerid]) {
			SetPlayerMarkerVisibility(playerid, 0x00);
		}
		ResetPlayerWeapons(playerid);
		GivePlayerWeapon(playerid, Class_GetWeapon(Class_GetPlayerClass(playerid)), Weapons_GetAmmo(Class_GetWeapon(Class_GetPlayerClass(playerid))));
		GivePlayerWeapon(playerid, Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 0), Weapons_GetAmmo(Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 0)));
		GivePlayerWeapon(playerid, Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 1), Weapons_GetAmmo(Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 1)));
		GivePlayerWeapon(playerid, Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 2), Weapons_GetAmmo(Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 2)));
		Weapons_GiveWeapons(playerid);
		AttachHelmet(playerid);
		AttachMask(playerid);
		AttachDynamite(playerid);
		SetPlayerArmour(playerid, 100);
		SetPlayerArmedWeapon(playerid, Class_GetWeapon(Class_GetPlayerClass(playerid)));
	}
	return 1;
}

//---------------
//Rustler rockets

forward RegenerateRocket(rusid);
public RegenerateRocket(rusid) {
	new rockets[30];
	gRustlerRockets[rusid] ++;
	format(rockets, 30, "Rustler Bomber\n[%d/4]", gRustlerRockets[rusid]);
	UpdateDynamic3DTextLabelText(gRustlerLabel[rusid], X11_CADETBLUE, rockets);
	return 1;
}

//Nevada rockets

forward RegenerateNevada(nevid);
public RegenerateNevada(nevid) {
	new rockets[30];
	gNevadaRockets[nevid] ++;
	format(rockets, 30, "Nevada Bomber\n[%d/4]", gNevadaRockets[nevid]);
	UpdateDynamic3DTextLabelText(gNevadaLabel[nevid], X11_CADETBLUE, rockets);
	return 1;
}

//---------------

//Load the Submarines
LoadSubmarines() {
	new subs = 0;
	for (new i = 0; i < sizeof(SubInfo); i++) {
		SubInfo[i][Sub_Id] = CreateDynamicObject(9958, SubInfo[i][Sub_Pos][0], SubInfo[i][Sub_Pos][1], SubInfo[i][Sub_Pos][2], 0.0, 0.0, SubInfo[i][Sub_Pos][3]);
		SubInfo[i][Sub_Label] = Create3DTextLabel("USS Numnutz", X11_CADETBLUE, SubInfo[i][Sub_Pos][0], SubInfo[i][Sub_Pos][1], SubInfo[i][Sub_Pos][2], 50, 0);
		SubInfo[i][Sub_VID] = CreateVehicle(484, SubInfo[i][Sub_Pos][0], SubInfo[i][Sub_Pos][1], SubInfo[i][Sub_Pos][2], SubInfo[i][Sub_Pos][3], -1, -1, -1);
		AttachDynamicObjectToVehicle(SubInfo[i][Sub_Id], SubInfo[i][Sub_VID], 0.0, 0.0, 4.2, 0.0, 0.0, 180.0);
		LinkVehicleToInterior(SubInfo[i][Sub_VID], 169);
		Attach3DTextLabelToVehicle(SubInfo[i][Sub_Label], SubInfo[i][Sub_VID], 0.0, 0.0, 0.0);
		subs ++;
	}
	return 1;
}

//Unload the Submarines
UnloadSubmarines() {
	for (new i = 0; i < sizeof(SubInfo); i++) {
		DestroyDynamicObject(SubInfo[i][Sub_Id]);
		Delete3DTextLabel(SubInfo[i][Sub_Label]);
		CarDeleter(SubInfo[i][Sub_VID]);
	}
	return 1;
}

//Load the AAC system
LoadAntiAir() {
	new aac = 0;
	for (new i = 0; i < sizeof(AACInfo); i++) {
		AACInfo[i][AAC_Id] = CreateVehicle(AACInfo[i][AAC_Model], AACInfo[i][AAC_Pos][0], AACInfo[i][AAC_Pos][1], AACInfo[i][AAC_Pos][2], AACInfo[i][AAC_Pos][3], 0, 0, 60);
		AACInfo[i][AAC_Text] = CreateDynamic3DTextLabel("Anti Aircraft\n[4/4]", X11_CADETBLUE, 0.0, 0.0, 0.0, 50.0, INVALID_PLAYER_ID, AACInfo[i][AAC_Id], 1);
		AACInfo[i][AAC_Rockets] = 4;
		AACInfo[i][AAC_Samsite] = CreateDynamicObject(3884, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
		switch (AACInfo[i][AAC_Model]) {
			case 422: AttachDynamicObjectToVehicle(AACInfo[i][AAC_Samsite], AACInfo[i][AAC_Id], 0.009999, -1.449998, -0.534999, 0.0, 0.0, 0.0);
			case 515: AttachDynamicObjectToVehicle(AACInfo[i][AAC_Samsite], AACInfo[i][AAC_Id], 0.000000, -3.520033, -1.179999, 0.000000, 0.000000, 0.000000);
		}
		AACInfo[i][AAC_Rockets] = 4;
		UpdateDynamic3DTextLabelText(AACInfo[i][AAC_Text], X11_CADETBLUE, "Anti Aircraft\n[4/4]");
		AACInfo[i][AAC_Driver] = INVALID_PLAYER_ID;
		AACInfo[i][AAC_Target] = INVALID_PLAYER_ID;
		aac ++;
	}
	return 1;
}

//Unload the AAC system
UnloadAntiAir() {
	for (new i = 0; i < sizeof(AACInfo); i++) {
		DestroyVehicle(AACInfo[i][AAC_Id]);
		if (IsValidDynamicObject(AACInfo[i][AAC_Samsite])) {
			DestroyDynamicObject(AACInfo[i][AAC_Samsite]);
		}
		DestroyDynamic3DTextLabel(AACInfo[i][AAC_Text]);
	}
	return 1;
}

//Recharge an AAC in case the player is in the recharge point

RechargeAAC(playerid) {
	for (new a = 0; a < sizeof(AACInfo); a++) {
		if (GetPlayerVehicleID(playerid) == AACInfo[a][AAC_Id]) {
			if (AACInfo[a][AAC_Rockets] < 4) {
				if (AACInfo[a][AAC_Regen_Timer] < gettime()) {
					AACInfo[a][AAC_Rockets] ++;
					AACInfo[a][AAC_Regen_Timer] = gettime() + 10;

					new text[25];
					format(text, sizeof(text), "Anti Aircraft\n[%d/4]", AACInfo[a][AAC_Rockets]);
					UpdateDynamic3DTextLabelText(AACInfo[a][AAC_Text], X11_CADETBLUE, text);
				}
				break;
			}
		}
	}
	return 1;
}

//Check if a player is targeted by an AAC

CheckTarget(playerid) {
	for (new i = 0; i < sizeof(AACInfo); i++) {
		if (AACInfo[i][AAC_Target] == playerid) {
			if (PlayerInfo[playerid][AntiAirAlerts] < 3) {
				new Float: X, Float: Y, Float: Z;
				GetDynamicObjectPos(AACInfo[i][AAC_RocketId], X, Y, Z);
				new Float: dist = GetPlayerDistanceFromPoint(playerid, X, Y, Z);
				if (dist > 50.0 && dist < 101.0) {
					GetPlayerPos(playerid, X, Y, Z);
					SetDynamicObjectFaceCoords3D(AACInfo[i][AAC_RocketId], X, Y, Z, 0.0, 90.0, 90.0);
					MoveDynamicObject(AACInfo[i][AAC_RocketId], X, Y, Z, 80.0);
					PlayerPlaySound(AACInfo[i][AAC_Driver], 1056, 0.0, 0.0, 0.0);
					PlayerPlaySound(playerid, 6001, 0.0, 0.0, 0.0);
					KillTimer(pAACTargetTimer[playerid]);
					pAACTargetTimer[playerid] = SetTimerEx("StopAlarm", 6000, false, "d", playerid);
				}
				if (dist < 20.0) {
					if (AACInfo[i][AAC_Driver] == INVALID_PLAYER_ID) {
						DamagePlayer(playerid, 54.2, INVALID_PLAYER_ID, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, true);
						DestroyDynamicObject(AACInfo[i][AAC_RocketId]);
						CreateExplosion(X, Y, Z, 7, 25.0);
						AACInfo[i][AAC_RocketId] = INVALID_OBJECT_ID;
						AACInfo[i][AAC_Target] = INVALID_PLAYER_ID;
					} else {
						GivePlayerScore(AACInfo[i][AAC_Driver], 1);
						DamagePlayer(playerid, 54.2, AACInfo[i][AAC_Driver], WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
						GetDynamicObjectPos(AACInfo[i][AAC_RocketId], X, Y, Z);
						DestroyDynamicObject(AACInfo[i][AAC_RocketId]);
						CreateExplosion(X, Y, Z, 7, 25.0);
						AACInfo[i][AAC_RocketId] = INVALID_OBJECT_ID;
						AACInfo[i][AAC_Target] = INVALID_PLAYER_ID;
					}
				}
				PlayerInfo[playerid][AntiAirAlerts] ++;
			} else {
				AACInfo[i][AAC_Target] = INVALID_PLAYER_ID;
				PlayerInfo[playerid][AntiAirAlerts] = 0;
				DestroyDynamicObject(AACInfo[i][AAC_RocketId]);
				AACInfo[i][AAC_RocketId] = INVALID_OBJECT_ID;
			}
			break;
		}
	}
	return 1;
}

//Delete cars

forward EraseCar(vehicleid);
public EraseCar(vehicleid) {
	if (IsValidVehicle(vehicleid)) {
		DestroyVehicle(vehicleid);
	}
	return 1;
}

//Weapon change

forward OnPlayerWeaponChange(playerid);
public OnPlayerWeaponChange(playerid) {
	return 1;
}

//Apply carrying animation

forward CarryAnim(playerid);
public CarryAnim(playerid) {
	return ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, 0, 1, 1, 1, 1, 1);
}

//Misc

forward ApplyBan(playerid);
public ApplyBan(playerid) {
	BlockIpAddress(PlayerInfo[playerid][pIP], (24 * 60 * 60 * 1000));
	Kick(playerid);
	return 1;
}

forward DelayKick(playerid);
public DelayKick(playerid) {
	Kick(playerid);
	return 1;
}

//Find a random position in a map area
stock RandPosInArea( Float: minx, Float: miny, Float: maxx, Float: maxy, &Float: fDestX, &Float: fDestY )
{
    new
        iMin, iMax,
        Float:mul = floatpower(10.0, 4)
    ;

    iMin = floatround(minx * mul);
    iMax = floatround(maxx * mul);

    fDestX = float(random(iMax - iMin) + iMin) / mul;

    iMin = floatround(miny * mul);
    iMax = floatround(maxy * mul);

    fDestY = float(random(iMax - iMin) + iMin) / mul;

}

stock GetAreaCenter(Float: minx, Float: miny, Float: maxx, Float: maxy, &Float: NewX, &Float: NewY) {
	NewX = floatdiv((maxx + minx), 2);
	NewY = floatdiv((maxy + miny), 2);
}

/////////////////////////////

//Get object's collision sphere radius (useful for draw-distance)
stock Float:GetColSphereRadius(objectmodel) {
	new Float:tmp, Float:rad;
	if(0 <= objectmodel <= 19999) {
		CA_GetModelBoundingSphere(objectmodel, tmp, tmp, tmp, rad);
		return rad;
	}
	return 0.0;
}

//Get distance between two points
forward Float:GetDistance(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2);
Float:GetDistance(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) {
	return floatsqroot(floatpower(floatabs(floatsub(x2,x1)),2)+floatpower(floatabs(floatsub(y2,y1)),2)+floatpower(floatabs(floatsub(z2,z1)),2));
}

//GetAngleToPos made by MegaDreams
stock Float: GetAngleToPos(Float: PX, Float: PY, Float: X, Float: Y) {
	new Float:Angle = floatabs(atan((Y-PY)/(X-PX)));
	Angle = (X<=PX && Y>=PY) ? floatsub(180,Angle) : (X<PX && Y<PY) ? floatadd(Angle,180) : (X>=PX && Y<=PY) ? floatsub(360.0,Angle) : Angle;
	Angle = floatsub(Angle, 90.0);
	Angle = (Angle>=360.0) ? floatsub(Angle, 360.0) : Angle;
	return Angle;
}

/////////////

//Text validity verification
IsValidText(const text[]) {
	new Regex:r = Regex_New("[A-Za-z0-9]+");
	new check = Regex_Check(text, r);
	Regex_Delete(r);
	return check;
}

//See if a vehicle is driven or not
IsVehicleUsed(vehicleid) {
	foreach (new i: Player) {
		if (pVerified[i] && IsPlayerInVehicle(i, vehicleid) && GetPlayerState(i) == PLAYER_STATE_DRIVER) return 1;
	}
	return 0;
}

//Get a vehicle's maximum speed (top speeds are defined in server header)
stock GetVehicleTopSpeed(vehicleid) {
    new model = GetVehicleModel(vehicleid);
    if (model) {
        return s_TopSpeed[(model - 400)];
    }
    return 0;
}

//Is it a plane?
stock IsAirVehicle(vehicleid) {
    new AirVeh[] = { 592, 577, 511, 512, 593, 520, 553, 476, 519, 460, 513, 548, 425, 417, 487, 488, 497, 563, 447, 469 };
    for(new i = 0; i < sizeof(AirVeh); i++) {
        if(GetVehicleModel(vehicleid) == AirVeh[i]) return 1;
    }
    return 0;
}

stock IsAirVehicleModel(vehicleid) {
    new AirVeh[] = { 592, 577, 511, 512, 593, 520, 553, 476, 519, 460, 513, 548, 425, 417, 487, 488, 497, 563, 447, 469 };
    for(new i = 0; i < sizeof(AirVeh); i++) {
        if(vehicleid == AirVeh[i]) return 1;
    }
    return 0;
}

//Return vehicle's model ID from a given name string (defined in server header)
GetVehicleModelIDFromName(const vname[]) {
	for (new i = 0; i < 211; i++) {
		if (strfind(VehicleNames[i], vname, true) != -1)
			return i + 400;
	}
	return -1;
}

//Extended vehicle functions

//Return a player's vehicle speed
GetPlayerVehicleSpeed(playerid) {
	new Float:X, Float:Y, Float:Z, Float:R;
	if (IsPlayerInAnyVehicle(playerid))
	{
		GetVehicleVelocity(GetPlayerVehicleID(playerid), X, Y, Z);
	}
	R = floatsqroot(floatabs(floatpower(X + Y + Z, 2)));
	return floatround(R * 100 * 1.61);
}

//What was this supposed to do? Get roof/boot/hood offsets? Apparently, it does..
stock GetVehicleOffset(vehicleid, type, &Float:x, &Float:y, &Float:z) {
	new Float:fPos[4], Float:fSize[3];

	if (!IsValidVehicle(vehicleid)) {
		x = 0.0;
		y = 0.0;
		z = 0.0;

		return 0;
	}
	else
	{
		GetVehiclePos(vehicleid, fPos[0], fPos[1], fPos[2]);
		GetVehicleZAngle(vehicleid, fPos[3]);
		GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, fSize[0], fSize[1], fSize[2]);

		switch (type)
		{
			case VEHICLE_OFFSET_BOOT:
			{
				x = fPos[0] - (floatsqroot(fSize[1] + fSize[1]) * floatsin(-fPos[3], degrees));
				y = fPos[1] - (floatsqroot(fSize[1] + fSize[1]) * floatcos(-fPos[3], degrees));
				z = fPos[2];
			}
			case VEHICLE_OFFSET_HOOD:
			{
				x = fPos[0] + (floatsqroot(fSize[1] + fSize[1]) * floatsin(-fPos[3], degrees));
				y = fPos[1] + (floatsqroot(fSize[1] + fSize[1]) * floatcos(-fPos[3], degrees));
				z = fPos[2];
			}
			case VEHICLE_OFFSET_ROOF:
			{
				x = fPos[0];
				y = fPos[1];
				z = fPos[2] + floatsqroot(fSize[2]);
			}
		}
	}
	return 1;
}

//Identify a vehicle's driver
stock GetVehicleDriver(vehicleid) {
	foreach (new i: Player) {
		if (GetPlayerState(i) == PLAYER_STATE_DRIVER && IsPlayerInVehicle(i, vehicleid)) {
			return i;
		}
	}
	return INVALID_PLAYER_ID;
}

//--
//---
//Skin validation
IsValidSkin(SkinID) {
	if (SkinID >= 0 && SkinID <= 311 && SkinID != 74) return 1;
	return 0;
}

//Weapon validation
IsValidWeapon(weaponid) {
	if (weaponid > 0 && weaponid < 19 || weaponid > 21 && weaponid < 47) return 1;
	return 0;
}

//Return weapon name from a text string
GetWeaponIDFromName(const WeaponName[]) {
	if (strfind("molotov", WeaponName, true) != -1) return 18;

	for (new i = 0; i < 46; i++) {
		switch (i) {
			case 0, 19, 20, 21, 44, 45: continue;

			default:
			{
				new name[32];
				GetWeaponName(i, name, 32);

				if (strfind(name, WeaponName, true) != -1) return i;
			}
		}
	}

	return -1;
}

//Return weapon model from weapon ID
GetWeaponModel(weaponid) {
	new weapon_model = -1;

	switch (weaponid) {
		case 1: weapon_model = 331;
		case 2: weapon_model = 333;
		case 3: weapon_model = 334;
		case 4: weapon_model = 335;
		case 5: weapon_model = 336;
		case 6: weapon_model = 337;
		case 7: weapon_model = 338;
		case 8: weapon_model = 339;
		case 9: weapon_model = 341;
		case 10: weapon_model = 321;
		case 11: weapon_model = 322;
		case 12: weapon_model = 323;
		case 13: weapon_model = 324;
		case 14: weapon_model = 325;
		case 15: weapon_model = 326;
		case 16: weapon_model = 342;
		case 17: weapon_model = 343;
		case 18: weapon_model = 344;
		case 22: weapon_model = 346;
		case 23: weapon_model = 347;
		case 24: weapon_model = 348;
		case 25: weapon_model = 349;
		case 26: weapon_model = 350;
		case 27: weapon_model = 351;
		case 28: weapon_model = 352;
		case 29: weapon_model = 353;
		case 30: weapon_model = 355;
		case 31: weapon_model = 356;
		case 32: weapon_model = 372;
		case 33: weapon_model = 357;
		case 34: weapon_model = 358;
		case 35: weapon_model = 359;
		case 36: weapon_model = 360;
		case 37: weapon_model = 361;
		case 38: weapon_model = 362;
		case 39: weapon_model = 363;
		case 41: weapon_model = 365;
		case 42: weapon_model = 366;
		case 46: weapon_model = 371;
	}
	return weapon_model;
}

//Remove a player's weapon from the weapon slot
stock RemovePlayerWeapon(playerid, weapon) {
	new weapons[13], ammo[13];
	for(new i; i < 13; i++) GetPlayerWeaponData(playerid, i, weapons[i], ammo[i]);
	ResetPlayerWeapons(playerid);
	for(new i; i < 13; i++) {
		if (weapons[i] == weapon) continue;
		GivePlayerWeapon(playerid, weapons[i], ammo[i]);
	}
	return 1;
}

//Weapon slot check
GetWeaponSlot(weaponid) {
	switch (weaponid) {
		case 0, 1:          return 0;
		case 2 .. 9:        return 1;
		case 10 .. 15:      return 10;
		case 16 .. 18, 39:  return 8;
		case 22 .. 24:      return 2;
		case 25 .. 27:      return 3;
		case 28, 29, 32:    return 4;
		case 30, 31:        return 5;
		case 33, 34:        return 6;
		case 35 .. 38:      return 7;
		case 40:            return 12;
		case 41 .. 43:      return 9;
		case 44 .. 46:      return 11;
	}
	return -1;
}

//Remove a certain weapon from a slot
stock RemoveWeaponFromSlot(playerid, weaponslot) {
	new weapons[13][2];
	for(new i = 0; i < 13; i++)
		GetPlayerWeaponData(playerid, i, weapons[i][0], weapons[i][1]);
	weapons[weaponslot][0] = 0;
	ResetPlayerWeapons(playerid);

	for(new i = 0; i < 13; i++)
		GivePlayerWeapon(playerid, weapons[i][0], weapons[i][1]);
	return 1;
}

//Add double ammo to the player
AddAmmo(playerid) {
	new slot, weapon, ammo;
	for (slot = 0; slot < 13; slot++) {
		GetPlayerWeaponData(playerid, slot, weapon, ammo);

		if (IsBulletWeapon(weapon) && weapon != WEAPON_MINIGUN) {
			GivePlayerWeapon(playerid, weapon, ammo);
		}
	}
	return 1;
}

//Check whether a player is in the given area
IsPlayerInArea(playerid, Float:MinX, Float:MinY, Float:MaxX, Float:MaxY) {
	new Float:X, Float:Y, Float:Z;

	GetPlayerPos(playerid, X, Y, Z);
	if (X >= MinX && X <= MaxX && Y >= MinY && Y <= MaxY) {
		return 1;
	}
	return 0;
}

//As much as IsPlayerInRangeOfPOINT
stock IsPointInRangeOfPoint(Float:x, Float:y, Float:z, Float:x2, Float:y2, Float:z2, Float:range) {
	x2 -= x;
	y2 -= y;
	z2 -= z;
	return ((x2 * x2) + (y2 * y2) + (z2 * z2)) < (range * range);
}

//Useful for projectiles, get coordinates in-front of player at given distance
stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance) {
	// Created by Y_Less

	new Float:a;

	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);

	if (GetPlayerVehicleID(playerid)) {
		GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
	}

	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

//Upside down check
stock IsVehicleUpsideDown(vehicleid) {
    new Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z;
    GetVehicleRotationQuat(vehicleid,quat_w,quat_x,quat_y,quat_z);
    new Float:y = atan2(2*((quat_y*quat_z)+(quat_w*quat_x)),(quat_w*quat_w)-(quat_x*quat_x)-(quat_y*quat_y)+(quat_z*quat_z));
    return (y > 90 || y < -90);
}

//Force the player's facing angle to given coordinates
SetPlayerLookAt(playerid, Float:X, Float:Y) {
	new Float:Px, Float:Py, Float: Pa;
	GetPlayerPos(playerid, Px, Py, Pa);
	Pa = floatabs(atan((Y-Py)/(X-Px)));
	if (X <= Px && Y >= Py) Pa = floatsub(180, Pa);
	else if (X < Px && Y < Py) Pa = floatadd(Pa, 180);
	else if (X >= Px && Y <= Py) Pa = floatsub(360.0, Pa);
	Pa = floatsub(Pa, 90.0);
	if (Pa >= 360.0) Pa = floatsub(Pa, 360.0);
	SetPlayerFacingAngle(playerid, Pa);
}

//Is a numbers-only string
IsNumeric(const String[]) {
	new numeric = 1;
	for (new i = 0, j = strlen(String); i < j; i++) {
		if (String[i] > '9' || String[i] < '0') {
			numeric = 0;
		}
	}

	return numeric;
}

//Return timestamp in seconds instead of ms
TimeStamp() {
	new time = GetTickCount() / 1000;
	return time;
}

//Compare two timestamps
GetWhen(start, till) {
	new seconds = till - start;

	const MINUTE = 60;
	const HOUR = 60 * MINUTE;
	const DAY = 24 * HOUR;
	const MONTH = 30 * DAY;

	new time_issued[32];
	if (seconds == 1)
		format(time_issued, sizeof (time_issued), "A seconds ago");
	if (seconds < (1 * MINUTE))
		format(time_issued, sizeof (time_issued), "%i seconds ago", seconds);
	else if (seconds < (2 * MINUTE))
		format(time_issued, sizeof (time_issued), "A minute ago");
	else if (seconds < (45 * MINUTE))
		format(time_issued, sizeof (time_issued), "%i minutes ago", (seconds / MINUTE));
	else if (seconds < (90 * MINUTE))
		format(time_issued, sizeof (time_issued), "An hour ago");
	else if (seconds < (24 * HOUR))
		format(time_issued, sizeof (time_issued), "%i hours ago", (seconds / HOUR));
	else if (seconds < (48 * HOUR))
		format(time_issued, sizeof (time_issued), "Yesterday");
	else if (seconds < (30 * DAY))
		format(time_issued, sizeof (time_issued), "%i days ago", (seconds / DAY));
	else if (seconds < (12 * MONTH)) {
		new months = floatround(seconds / DAY / 30);
		if (months <= 1)
			format(time_issued, sizeof (time_issued), "One month ago");
		else
			format(time_issued, sizeof (time_issued), "%i months ago", months);
	}
	else
	{
		new years = floatround(seconds / DAY / 365);
		if (years <= 1)
			format(time_issued, sizeof (time_issued), "One year ago");
		else
			format(time_issued, sizeof (time_issued), "%i years ago", years);
	}
	return time_issued;
}

//Convert numbers? What was this supposed to do..
stock convertNumber(value) {
	// http://forum.sa-mp.com/showthread.php?p=843781#post843781
	new string[24];
	format(string, sizeof(string), "%d", value);

	for(new i = (strlen(string) - 3); i > (value < 0 ? 1 : 0) ; i -= 3) {
		strins(string[i], ",", 0);
	}

	return string;
}

//Convert time to string
stock TimeConvert(time) {
	new minutes;
	new seconds;
	new string[SMALL_STRING_LEN];
	if (time > 59) {
		minutes = floatround(time/60);
		seconds = floatround(time - minutes*60);
		if (seconds>9)format(string,sizeof(string),"%d:%d",minutes,seconds);
		else format(string,sizeof(string),"%d:0%d",minutes,seconds);
	}
	else {
		seconds = floatround(time);
		if (seconds>9)format(string,sizeof(string),"0:%d",seconds);
		else format(string,sizeof(string),"0:0%d",seconds);
	}
	return string;
}

//Supposed to separate numbers using given separators
stock formatInt(intVariable, iThousandSeparator = ',', iCurrencyChar = '$') {
	/*
		By Kar
		https://gist.github.com/Kar2k/bfb0eafb2caf71a1237b349684e091b9/8849dad7baa863afb1048f40badd103567c005a5#file-formatint-function
	*/
	new
		s_szReturn[ 32 ],
		s_szThousandSeparator[ 2 ] = { ' ', EOS },
		s_szCurrencyChar[ 2 ] = { ' ', EOS },
		s_iVariableLen,
		s_iChar,
		s_iSepPos,
		bool:s_isNegative
	;

	format( s_szReturn, sizeof( s_szReturn ), "%d", intVariable );

	if (s_szReturn[0] == '-')
		s_isNegative = true;
	else
		s_isNegative = false;

	s_iVariableLen = strlen( s_szReturn );

	if ( s_iVariableLen >= 4 && iThousandSeparator) {
		s_szThousandSeparator[ 0 ] = iThousandSeparator;

		s_iChar = s_iVariableLen;
		s_iSepPos = 0;

		while ( --s_iChar > _:s_isNegative ) {
			if ( ++s_iSepPos == 3 ) {
				strins( s_szReturn, s_szThousandSeparator, s_iChar );

				s_iSepPos = 0;
			}
		}
	}
	if (iCurrencyChar) {
		s_szCurrencyChar[ 0 ] = iCurrencyChar;
		strins( s_szReturn, s_szCurrencyChar, _:s_isNegative );
	}
	return s_szReturn;
}

//Random number that actually has a minimum and a maximum value
stock RandomEx(min, max) //Y_Less
	return random(max - min) + min;

stock ConvertToMinutes(time) {
	// http://forum.sa-mp.com/showpost.php?p=3223897&postcount=11
	new string[15];//-2000000000:00 could happen, so make the string 15 chars to avoid any errors
	format(string, sizeof(string), "%02d:%02d", time / 60, time % 60);
	return string;
}

//Make a player visible or invisible..
SetPlayerMarkerVisibility(playerid, alpha = 0xFF) { //Thanks SA:MP wiki
	new oldcolor, newcolor;

	alpha = clamp(alpha, 0x00, 0xFF);
	oldcolor = GetPlayerColor(playerid);

	newcolor = (oldcolor & ~0xFF) | alpha;
	return SetPlayerColor(playerid, newcolor);
}

//What was this supposed to do? I can't recall
stock GetOffsetPos(&Float:x, &Float:y, Float:distance, Float: r) {	// Created by Y_Less
	x += (distance * floatsin(-r, degrees));
	y += (distance * floatcos(-r, degrees));
}

//.....
stock Get2DRandomDistanceAway(&Float: fwX, &Float: fwY, min_distance, max_distance = 100) {
	new Float: tempX = fwX, Float: tempY = fwY;
	new rX = random(max_distance);
	new rY = random(max_distance);
	tempX += float(rX-(max_distance/2));
	tempY += float(rY-(max_distance/2));
	while (GetDistance(tempX, tempY, 10.0, fwX, fwY, 10.0) < min_distance/2) {
		tempX = fwX;
		tempY = fwY;
		rX = random(max_distance);
		rY = random(max_distance);
		tempX += float(rX-(max_distance/2));
		tempY += float(rY-(max_distance/2));
	}
	fwX = tempX;
	fwY = tempY;
	return 1;
}

//...............
stock Get3DRandomDistanceAway(&Float: fwX, &Float: fwY, &Float: fwZ, min_distance, max_distance = 100) {
	new Float: tempX = fwX, Float: tempY = fwY, Float: tempZ = fwZ;
	new rX = random(max_distance);
	new rY = random(max_distance);
	new rZ = random(max_distance);
	tempX += float(rX-(max_distance/2));
	tempY += float(rY-(max_distance/2));
	tempZ += float(rZ-(max_distance/2));
	while (GetDistance(tempX, tempY, tempZ, fwX, fwY, fwZ) < min_distance/2) {
		tempX = fwX;
		tempY = fwY;
		tempZ = fwZ;
		rX = random(max_distance);
		rY = random(max_distance);
		rZ = random(max_distance);
		tempX += float(rX-(max_distance/2));
		tempY += float(rY-(max_distance/2));
		tempZ += float(rZ-(max_distance/2));
	}
	fwX = tempX;
	fwY = tempY;
	fwZ = tempZ;
	return 1;
}

//Replace a part of the given string
strreplace(string[], const search[], const replacement[], bool:ignorecase = false, pos = 0, limit = -1, maxlength = sizeof(string)) {
	// No need to do anything if the limit is 0.
	if (limit == 0)
		return 0;

	new
			 sublen = strlen(search),
			 replen = strlen(replacement),
		bool:packed = ispacked(string),
			 maxlen = maxlength,
			 len = strlen(string),
			 count = 0
	;


	// "maxlen" holds the max string length (not to be confused with "maxlength", which holds the max. array size).
	// Since packed strings hold 4 characters per array slot, we multiply "maxlen" by 4.
	if (packed)
		maxlen *= 4;

	// If the length of the substring is 0, we have nothing to look for..
	if (!sublen)
		return 0;

	// In this line we both assign the return value from "strfind" to "pos" then check if it's -1.
	while (-1 != (pos = strfind(string, search, ignorecase, pos))) {
		// Delete the string we found
		strdel(string, pos, pos + sublen);

		len -= sublen;

		// If there's anything to put as replacement, insert it. Make sure there's enough room first.
		if (replen && len + replen < maxlen) {
			strins(string, replacement, pos, maxlength);

			pos += replen;
			len += replen;
		}

		// Is there a limit of number of replacements, if so, did we break it?
		if (limit != -1 && ++count >= limit)
			break;
	}
	return count;
}

//Make an object face given 3D Coordinates
SetDynamicObjectFaceCoords3D(iObject, Float: fX, Float: fY, Float: fZ, Float: fRollOffset = 0.0, Float: fPitchOffset = 0.0, Float: fYawOffset = 0.0) {
	new
		Float: fOX,
		Float: fOY,
		Float: fOZ,
		Float: fPitch
	;
	GetDynamicObjectPos(iObject, fOX, fOY, fOZ);

	fPitch = floatsqroot(floatpower(fX - fOX, 2.0) + floatpower(fY - fOY, 2.0));
	fPitch = floatabs(atan2(fPitch, fZ - fOZ));

	fZ = atan2(fY - fOY, fX - fOX) - 90.0; // Yaw

	SetDynamicObjectRot(iObject, fRollOffset, fPitch + fPitchOffset, fZ + fYawOffset);
}

//Anti advertisement
//Who made this?
AdCheck(const szStr[], bool:fixedSeparation = false, bool:ignoreNegatives = false, bool:ranges = true) {
	new
		i = 0, ch, lastCh, len = strlen(szStr), trueIPInts = 0, bool:isNumNegative = false, bool:numIsValid = true, // Invalid numbers are 1-1
		numberFound = -1, numLen = 0, numStr[5], numSize = sizeof(numStr),
		lastSpacingPos = -1, numSpacingDiff, numLastSpacingDiff, numSpacingDiffCount // -225\0 (4 len)
	;
	while(i <= len) {
		lastCh = ch;
		ch = szStr[i];
		if (ch >= '0' && ch <= '9' || (ranges == true && ch == '*')) {
			if (numIsValid && numLen < numSize) {
				if (lastCh == '-') {
					if (numLen == 0 && ignoreNegatives == false) {
						isNumNegative = true;
					}
					else if (numLen > 0) {
						numIsValid = false;
					}
				}
				numberFound = strval(numStr);
				if (numLen == (3 + _:isNumNegative) && !(numberFound >= -255 && numberFound <= 255)) { // IP Num is valid up to 4 characters.. -255
					for (numLen = 3; numLen > 0; numLen--) {
						numStr[numLen] = EOS;
					}
				}
				else if (lastCh == '-' && ignoreNegatives) {
					i++;
					continue;
				} else {
					if (numLen == 0 && numIsValid == true && isNumNegative == true && lastCh == '-') {
						numStr[numLen++] = lastCh;
					}
					numStr[numLen++] = ch;
				}
			}
		} else {
			if (numLen && numIsValid) {
				numberFound = strval(numStr);
				if (numberFound >= -255 && numberFound <= 255) {
					if (fixedSeparation) {
						if (lastSpacingPos != -1) {
							numLastSpacingDiff = numSpacingDiff;
							numSpacingDiff = i - lastSpacingPos - numLen;
							if (trueIPInts == 1 || numSpacingDiff == numLastSpacingDiff) {
								++numSpacingDiffCount;
							}
						}
						lastSpacingPos = i;
					}
					if (++trueIPInts >= 4) {
						break;
					}
				}
				for (numLen = 3; numLen > 0; numLen--) {
					numStr[numLen] = EOS;
				}
				isNumNegative = false;
			} else {
				numIsValid = true;
			}
		}
		i++;
	}
	if (fixedSeparation == true && numSpacingDiffCount < 3) {
		return 0;
	}
	return (trueIPInts >= 4);
}

//Thanks to RyDeR`, return a random text string, useful for security codes
stock randomString(strDest[], strLen = 10) {
    while(strLen--)
        strDest[strLen] = random(2) ? (random(26) + (random(2) ? 'a' : 'A')) : (random(10) + '0');
}

//Command syntax message
ShowSyntax(playerid, const message[]) {
	return SendClientMessage(playerid, X11_LIGHTGREEN, message);
}

//S0beit Check (I remember learning this out of a quickview over the Modern Warfare 3 gamescript)
stock IsPlayerBot(playerid) {
    new TempId[80], TempNumb;
    gpci(playerid, TempId, sizeof(TempId));
    for(new i = 0; i < strlen(TempId); i++) {
        if(TempId[i] >= '0' && TempId[i] <= '9')  TempNumb++;
    }
    return (TempNumb >= 30 || strlen(TempId) <= 30) ? true : false;
}

//Animations

AnimPlayer(playerid, const animlib[], const animname[], Float:speed, looping, lockx, locky, lockz, lp) {
	ApplyAnimation(playerid, animlib, animname, speed, looping, lockx, locky, lockz, lp);
	return true;
}

AnimLoopPlayer(playerid, const animlib[], const animname[], Float:speed, looping, lockx, locky, lockz, lp) {
	IsPlayerUsingAnims[playerid] = 1;
	ApplyAnimation(playerid, animlib, animname, speed, looping, lockx, locky, lockz, lp);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_STOPANIM);
	return true;
}

StopAnimLoopPlayer(playerid) {
	IsPlayerUsingAnims[playerid] = 0;
	ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

AnimPreloadForPlayer(playerid, const animlib[]) {
	ApplyAnimation(playerid, animlib, "null", 0.0, 0, 0, 0, 0, 0);
	return 1;
}

stock IsPlayerInWater(playerid) {
	new anim = GetPlayerAnimationIndex(playerid);
	if (((anim >=  1538) && (anim <= 1542)) || (anim == 1544) || (anim == 1250) || (anim == 1062)) return 1;
	return 0;
}

stock IsPlayerAiming(playerid) {
	new anim = GetPlayerAnimationIndex(playerid);
	if (((anim >= 1160) && (anim <= 1163)) || (anim == 1167) || (anim == 1365) || (anim == 1643) || (anim == 1453) || (anim == 220)) return 1;
	return 0;
}

//Teleport system
forward LoadMap(playerid);
public LoadMap(playerid) {
	return TogglePlayerControllable(playerid, true);
}

//Playtime

stock CountSessionPlayedTime(playerid, &d, &h, &m, &s) {
	new seconds = (gettime() - PlayerInfo[playerid][pPlayTick]);

	d = (seconds / 86400);
	h = (seconds / 3600);
	m = (seconds / 60 % 60);
	s = (seconds % 60);
}

CountPlayedTime(playerid, &d, &h, &m, &s) {
	new seconds = (gettime() - PlayerInfo[playerid][pPlayTick]) + PlayerInfo[playerid][pTimePlayed];

	d = (seconds / 86400);
	h = (seconds / 3600);
	m = (seconds / 60 % 60);
	s = (seconds % 60);
}

RecountPlayedTime(playerid) {
	new seconds = (gettime() - PlayerInfo[playerid][pPlayTick]) + PlayerInfo[playerid][pTimePlayed];

	PlayerInfo[playerid][pSessionDays] = (seconds / 86400);
	PlayerInfo[playerid][pSessionHours] = (seconds / 3600);
	PlayerInfo[playerid][pSessionMins] = (seconds / 60 % 60);
}

//Score

GivePlayerScore(playerid, Score) {
	if ((GetPlayerScore(playerid) + Score) >= 0) {
		SetPlayerScore(playerid, GetPlayerScore(playerid) + Score);
	} else {
		SetPlayerScore(playerid, 0);
	}

	if (IsPlayerSpawned(playerid)) {
		if (Ranks_IsHigher(playerid)) {
			PlaySuccessSound(playerid);
			GivePlayerCash(playerid, 1000);
			SendGameMessage(playerid, X11_SERV_SUCCESS, MSG_NEW_RANK_UP, Ranks_ReturnName(Ranks_GetPlayer(playerid)));
		}
	}

	UpdatePlayerHUD(playerid);
	return 1;
}

//Countdown

forward StartCount(cdValue);
public StartCount(cdValue) {
	if (counterOn == 1) {
		if (counterValue > 0) {
			new text[10];
			format(text, sizeof(text), "~w~%d", counterValue);

			counterValue--;

			GameTextForAll(text, 1000, 3);

		} else {

			KillTimer(counterTimer);

			counterValue = -1;
			counterOn = 0;

			GameTextForAll("~r~GO!", 1000, 3);
			foreach (new i: Player) {
				PlayGoSound(i);
			}
		}
	}
	return 1;
}


//A player wants to reselect their class/skin
forward SwitchClass(playerid);
public SwitchClass(playerid) {
	ForceClassSelection(playerid);
	SetPlayerHealth(playerid, 0.0);
	PlayerInfo[playerid][pSelecting] = 1;
	return 1;
}

//---------------
//Carepacks

forward AlterCarepack(i);
public AlterCarepack(i) {
	KillTimer(gCarepackTimer[i]);
	if (IsValidDynamicObject(gCarepackObj[i])) {
		DestroyDynamicObject(gCarepackObj[i]);
	}
	gCarepackObj[i] = INVALID_OBJECT_ID;
	DestroyDynamic3DTextLabel(gCarepack3DLabel[i]);
	DestroyDynamicArea(gCarepackArea[i]);
	gCarepackPos[i][0] = gCarepackPos[i][1] = gCarepackPos[2][0] = 0.0;
	gCarepackExists[i] = 0;
	return 1;
}

forward OnCarepackForwarded(callid);
public OnCarepackForwarded(callid) {
	new Float: X = gCarepackPos[callid][0];
	new Float: Y = gCarepackPos[callid][1];
	new Float: Z = gCarepackPos[callid][2] + 7.174264;

	gCarepackObj[callid] = CreateDynamicObject(18849, X, Y, (Z - 7.174264) + 15.0, 0.0, 0.0, 0.0);
	MoveDynamicObject(gCarepackObj[callid], X, Y, Z, 30.0);

	gCarepackPos[callid][2] -= 7.174264;
	return 1;
}

//---------------
//Flashbang!!

forward DecreaseFlash(playerid);
public DecreaseFlash(playerid) {
	if (pFlashLvl[playerid] > 0) {
		switch (pFlashLvl[playerid]) {

			case 10: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFFE6);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 9: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFFCD);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 8: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFFB4);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 7: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFF9B);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 6: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFF82);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 5: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFF69);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 4: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFF50);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 3: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFF37);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 2: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFF1E);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
			case 1: {

				PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFF05);
				PlayerTextDrawShow(playerid, FlashTD[playerid]);
			}
		}
		pFlashLvl[playerid] --;
		SetTimerEx("DecreaseFlash", 500, false, "d", playerid);
	}
	else
	{
		PlayerTextDrawHide(playerid, FlashTD[playerid]);
		PlayerTextDrawBoxColor(playerid, FlashTD[playerid], 0xFFFFFFFF);
		UpdateLabelText(playerid);
	}
	return 1;
}

//There is a class that executes this callback to explode said vehicle ID
//Need to identify that class, I seem to forget things too quick
forward ExplodeCar(playerid, carid);
public ExplodeCar(playerid, carid) {
	new Float: X, Float: Y, Float: Z;
	GetVehiclePos(carid, X, Y, Z);
	CreateExplosion(X, Y, Z, 7, 10.0);
	SetVehicleHealth(carid, 0.0);

	foreach(new i: Player) {
		if (IsPlayerInMode(i, MODE_BATTLEFIELD) &&
			i != playerid && IsPlayerInRangeOfPoint(i, 15.0, X, Y, Z) && Team_GetPlayer(i) != Team_GetPlayer(playerid)) {
			new Float: iX, Float: iY, Float: iZ;
			GetPlayerPos(i, iX, iY, iZ);

			CreateExplosion(iX, iY, iZ, 1, 0.3);
			CreateExplosion(iX, iY, iZ, 1, 0.3);

			SuccessAlert(playerid);
			DamagePlayer(i, 0.0, playerid, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
		}
	}
	return 1;
}

//Explode the dynamite object on said slot
forward DynamiteExplosion(dyn_slot);
public DynamiteExplosion(dyn_slot) {
	CreateExplosion(gDynamitePos[dyn_slot][0], gDynamitePos[dyn_slot][1], gDynamitePos[dyn_slot][2], 1, 0.3);

	new playerid = INVALID_PLAYER_ID;
	foreach (new i: Player) {
		if (gDynamitePlacer[dyn_slot] == i
				&& i != playerid) {
			playerid = i;
			break;
		}
	}

	if (playerid != INVALID_PLAYER_ID && IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		new pdefender = INVALID_PLAYER_ID;

		foreach (new i: Player) {
			if (GetPlayerState(i) == PLAYER_STATE_ONFOOT && IsPlayerInMode(i, MODE_BATTLEFIELD)) {
				new keys, ud, lr;
				GetPlayerKeys(i, keys, ud, lr);
				if ((keys & KEY_YES) && IsPlayerInDynamicArea(i, gDynamiteArea[dyn_slot])) {
					pdefender = i;
					break;
				}
			}
		}

		if (pdefender != INVALID_PLAYER_ID) {
			return 1;
		}

		foreach (new i: Player) {
			if (IsPlayerInDynamicArea(i, gDynamiteArea[dyn_slot])) {
				if (IsPlayerInMode(i, MODE_BATTLEFIELD) && i != playerid && Team_GetPlayer(i) != Team_GetPlayer(playerid)) {
					new Float: X, Float: Y, Float: Z;
					GetPlayerPos(i, X, Y, Z);
					CreateExplosion(X, Y, Z, 1, 0.3);
					DamagePlayer(i, 0.0, playerid, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
				}
			}
		}

		foreach (new i: teams_loaded) {
			if (GetDistance(AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2],
					gDynamitePos[dyn_slot][0], gDynamitePos[dyn_slot][1], gDynamitePos[dyn_slot][2]) < 10.0
					&& AntennaInfo[i][Antenna_Exists] == 1 && Team_GetPlayer(playerid) != i) {
				AntennaInfo[i][Antenna_Hits] += 5001;

				new title[100];

				new Float: hp = floatdiv(5000 - AntennaInfo[i][Antenna_Hits], 5000) * 100;
				new color[9];
				if (hp > 70.0) {
					color = ""GREEN"";
				} else if (hp <= 70.0 && hp > 50.0) {
					color = ""YELLOW"";
				} else if (hp <= 50.0 && hp > 25.0) {
					color = ""ORANGE"";
				} else if (hp <= 25.0) {
					color = ""WINE"";
				}
				format(title, sizeof(title), "%s\n"IVORY"Radio Antenna\n%s%0.2f%%", Team_GetName(i), color, hp);
				UpdateDynamic3DTextLabelText(AntennaInfo[i][Antenna_Label], Team_GetColor(i), title);

				if (AntennaInfo[i][Antenna_Hits] >= 5001) {
					LogActivity(playerid, "Captured antenna [owner: %d]", gettime(), i);
					GivePlayerScore(playerid, 4);
					PlayerInfo[playerid][pEXPEarned] += 1;
					PlayerInfo[playerid][pAntennasDestroyed] ++;
					SuccessAlert(playerid);

					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_36x, PlayerInfo[playerid][PlayerName], Team_GetName(i));

					new crate = random(100);
					switch (crate) {
						case 0..25: {
							PlayerInfo[playerid][pCrates] ++;
							SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_RECEIVED);
						}
					}

					format(title, sizeof(title), "%s\n"IVORY"Radio Antenna\n"WINE"Offline", Team_GetName(i));
					UpdateDynamic3DTextLabelText(AntennaInfo[i][Antenna_Label], Team_GetColor(i), title);

					foreach (new j: Player) {
						if (IsPlayerInMode(j, MODE_BATTLEFIELD) && Team_GetPlayer(j) == i) {
							SendGameMessage(j, X11_SERV_INFO, MSG_LOST_ANTENNA);
						}
					}

					AntennaInfo[i][Antenna_Exists] = 0;

					SetDynamicObjectPos(AntennaInfo[i][Antenna_Id], AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2] - 10.0);

					CreateExplosion(AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2], 4, 3.0);
					CreateExplosion(AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2] + 5, 4, 3.0);
					CreateExplosion(AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2] + 10, 4, 3.0);

					AntennaInfo[i][Antenna_Kill_Time] = gettime() + 250;
					return 0;
				}

				break;
			}
		}
	}

	AlterDynamite(dyn_slot);
	return 1;
}

//Hide damage sprite
forward HideDamage(playerid);
public HideDamage(playerid) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, 8)) {
		RemovePlayerAttachedObject(playerid, 8);
	}
	return 1;
}

//Hide kill box
forward KilledBox(killerid);
public KilledBox(killerid) {
	PlayerTextDrawHide(killerid, killedtext[killerid]);
	PlayerTextDrawHide(killerid, killedbox[killerid]);
	return 1;
}

//Supporter class function - support nearby players with ammunition
SupportAmmo(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if ((p_ClassAbilities(playerid, SUPPORT))) {
			if (pCooldown[playerid][2] < gettime()) {
				new Float:x, Float:y, Float:z;
				GetPlayerPos(playerid, x, y, z);

				new count = 0;

				foreach (new i: Player) {
					new Float: extrarange = 0.0;
					if (p_ClassAdvanced(playerid)) {
						extrarange = 5.0;
					}
					if (IsPlayerInMode(i, MODE_BATTLEFIELD) &&
						i != playerid && IsPlayerInRangeOfPoint(i, 10.0 + extrarange, x, y, z) && Team_GetPlayer(playerid) == Team_GetPlayer(i)) {
						AddAmmo(i);

						PlayerInfo[playerid][pSupportAttempts]++;
						count ++;
					}
				}

				if (count) {
					pCooldown[playerid][2] = gettime() + 85;
				}
			} else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][2] - gettime());
			}
		}
	}
	return 1;
}

//With weapons
SupportWeaps(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if ((p_ClassAbilities(playerid, SUPPORT))) {
			if (pCooldown[playerid][14] < gettime()) {
				new Float:x, Float:y, Float:z;
				GetPlayerPos(playerid, x, y, z);

				new count = 0;

				foreach (new i: Player) {
					new Float: extrarange = 0.0;
					if (p_ClassAdvanced(playerid)) {
						extrarange = 5.0;
					}
					if (IsPlayerInMode(i, MODE_BATTLEFIELD) &&
						i != playerid && IsPlayerInRangeOfPoint(i, 10.0 + extrarange, x, y, z) && Team_GetPlayer(playerid) == Team_GetPlayer(i)) {
						GivePlayerWeapon(i, 24, 50);
						GivePlayerWeapon(i, 27, 50);
						GivePlayerWeapon(i, 32, 50);
						GivePlayerWeapon(i, 7, 2);
						PlayerInfo[playerid][pSupportAttempts]++;
						count ++;
					}
				}

				if (count) {
					pCooldown[playerid][14] = gettime() + 85;
				}
			} else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][14] - gettime());
			}
		}
	}
	return 1;
}

//Heal them
SupportHealth(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if ((p_ClassAbilities(playerid, SUPPORT))) {
			if (pCooldown[playerid][17] < gettime()) {
				new Float:x, Float:y, Float:z;
				GetPlayerPos(playerid, x, y, z);

				new count = 0;

				foreach (new i: Player) {
					new Float: extrarange = 0.0;
					if (p_ClassAdvanced(playerid)) {
						extrarange = 5.0;
					}
					if (IsPlayerInMode(i, MODE_BATTLEFIELD) && i != playerid && IsPlayerInRangeOfPoint(i, 10.0 + extrarange, x, y, z) && Team_GetPlayer(playerid) == Team_GetPlayer(i)) {
						SetPlayerHealth(i, 100.0);
						PlayerInfo[playerid][pSupportAttempts]++;
						count ++;
					}
				}

				if (count) {
					SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_NEARBY_SUPPORTER);
					pCooldown[playerid][17] = gettime() + 85;
				}
			} else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][17] - gettime());
			}
		}
	}
	return 1;
}

//Fix their armour
SupportArmour(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if ((p_ClassAbilities(playerid, SUPPORT))) {
			if (pCooldown[playerid][17] < gettime()) {
				new Float:x, Float:y, Float:z;
				GetPlayerPos(playerid, x, y, z);

				new count = 0;

				foreach (new i: Player) {
					new Float: extrarange = 0.0;
					if (p_ClassAdvanced(playerid)) {
						extrarange = 5.0;
					}
					if (IsPlayerInMode(i, MODE_BATTLEFIELD) && i != playerid && IsPlayerInRangeOfPoint(i, 10.0 + extrarange, x, y, z) && Team_GetPlayer(playerid) == Team_GetPlayer(i)) {
						SetPlayerArmour(i, 100.0);
						PlayerInfo[playerid][pSupportAttempts]++;
						count ++;
					}
				}

				if (count) {
					pCooldown[playerid][17] = gettime() + 85;
				}
			} else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][17] - gettime());
			}
		}
	}
	return 1;
}

//Medic feature, heal nearby players
HealClosePlayers(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if ((p_ClassAbilities(playerid, MEDIC))) {
			if (pCooldown[playerid][17] < gettime()) {
				new Float:x, Float:y, Float:z;
				GetPlayerPos(playerid, x, y, z);

				new count = 0;

				new Float:r = 7.5;
				if (p_ClassAdvanced(playerid)) {
					r = 15.0;
				}

				foreach (new i: Player) {
					if (IsPlayerInMode(i, MODE_BATTLEFIELD) && i != playerid && IsPlayerInRangeOfPoint(i, r, x, y, z) && Team_GetPlayer(playerid) == Team_GetPlayer(i)) {
						SetPlayerHealth(i, 100.0);

						PlayerInfo[playerid][pSupportAttempts]++;
						PlayerInfo[playerid][pPlayersHealed] ++;
						count ++;
					}
				}

				if (count) {
					pCooldown[playerid][17] = gettime() + 50;
				}
			} else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][17] - gettime());
			}
		}
	}
	return 1;
}

//Landmines

forward AlterLandmine(mineid);
public AlterLandmine(mineid) {
	DestroyDynamicObject(gLandmineObj[mineid]);
	gLandmineObj[mineid] = INVALID_OBJECT_ID;
	DestroyDynamicArea(gLandmineArea[mineid]);
	gLandmineExists[mineid] = 0;
	gLandminePlacer[mineid] = INVALID_PLAYER_ID;
	return 1;
}

forward AlterDynamite(dynid);
public AlterDynamite(dynid) {
	DestroyDynamicObject(gDynamiteObj[dynid]);
	gDynamiteObj[dynid] = INVALID_OBJECT_ID;
	DestroyDynamicArea(gDynamiteArea[dynid]);
	gDynamiteExists[dynid] = 0;
	gDynamitePlacer[dynid] = INVALID_PLAYER_ID;
	gDynamiteCD[dynid] = 0;
	KillTimer(gDynamiteTimer[dynid]);
	return 1;
}

//Weapon pickups

forward AlterWeaponPickup(playerid, objectid);
public AlterWeaponPickup(playerid, objectid) {
	KillTimer(gWeaponTimer[objectid]);
	DestroyDynamicObject(gWeaponObj[objectid]);
	gWeaponObj[objectid] = INVALID_OBJECT_ID;
	DestroyDynamic3DTextLabel(gWeapon3DLabel[objectid]);
	DestroyDynamicArea(gWeaponArea[objectid]);

	gWeaponExists[objectid] = 0;
	gWeaponPickable[objectid] = 0;
	gWeaponPUBG[objectid] = 0;

	if (playerid != INVALID_PLAYER_ID && pVerified[playerid]) {
		GivePlayerWeapon(playerid, gWeaponID[objectid], gWeaponAmmo[objectid]);
		PlayerInfo[playerid][pPickedWeap] = 0;
		ApplyAnimation(playerid, "MISC", "PICKUP_box", 3.0, 0, 0, 0, 0, 0);
	}
	return 1;
}

//DM
forward HideDMText(playerid);
public HideDMText(playerid) {
	DMTimer[playerid] = -1;
	TextDrawHideForPlayer(playerid, DMBox);
	TextDrawHideForPlayer(playerid, DMText);
	TextDrawHideForPlayer(playerid, DMText2[0]);
	TextDrawHideForPlayer(playerid, DMText2[1]);
	TextDrawHideForPlayer(playerid, DMText2[2]);
	TextDrawHideForPlayer(playerid, DMText2[3]);
	return 1;
}

ShowDMText(playerid) {
	TextDrawShowForPlayer(playerid, DMBox);
	TextDrawShowForPlayer(playerid, DMText);

	new dmstring[180], top[MAX_PLAYERS][2], topcount = 1;

	foreach(new p: Player) {
		top[p][0] = pDMKills[p][PlayerInfo[playerid][pDeathmatchId]];
		top[p][1] = p;

		topcount ++;
	}

	QuickSort_Pair(top, true, 0, topcount);

	for (new i = 0; i < topcount; i++) {
		if (i < 5) {
			if (top[i][0]) {
				format(dmstring, sizeof(dmstring), "%s%d. %s - K: %d~n~", dmstring, i + 1, PlayerInfo[top[i][1]][PlayerName], top[i][0]);
			}
		} else {
			break;
		}
	}

	if (isnull(dmstring)) {
		format(dmstring, sizeof(dmstring), "There is no top DMer.");
	}

	TextDrawSetString(DMText2[3], dmstring);
	TextDrawShowForPlayer(playerid, DMText2[0]);
	TextDrawShowForPlayer(playerid, DMText2[1]);
	TextDrawShowForPlayer(playerid, DMText2[2]);
	TextDrawShowForPlayer(playerid, DMText2[3]);

	DMTimer[playerid] = SetTimerEx("HideDMText", 3000, false, "i", playerid);
	return 1;
}

SetupDeathmatch(playerid) {
	ShowDMText(playerid);
	SetPlayerColor(playerid, 0xECECECFF);

	if (PlayerInfo[playerid][pDeathmatchId] != 7) {
		SetPlayerChatBubble(playerid, "*Immune*", X11_WINE, 150.0, 4000);
		SetPlayerAttachedObject(playerid, 8, 18729, 1, 0.87, -0.04, 1.62, -174.00, 0.00, 0.00, 1.00, 1.00, 1.00);
		AntiSKStart[playerid] = gettime() + 3;
		AntiSK[playerid] = 1;
	}

	SetPlayerHealth(playerid, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_HP]);
	SetPlayerArmour(playerid, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_AR]);

	GivePlayerWeapon(playerid, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_1][0], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_1][1]);
	GivePlayerWeapon(playerid, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_2][0], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_2][1]);
	GivePlayerWeapon(playerid, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_3][0], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_3][1]);
	GivePlayerWeapon(playerid, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_4][0], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_WEAP_4][1]);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 1000);

	new i = random(3);

	TogglePlayerControllable(playerid, false);

	switch (i) {
		case 0:
		{
			SetPlayerPosition(playerid, "", DM_WORLD, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_INT], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_1][0],
				DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_1][1], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_1][2], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_1][3]);
		}
		case 1:
		{
			SetPlayerPosition(playerid, "", DM_WORLD, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_INT], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_2][0],
				DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_2][1], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_2][2], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_2][3]);
		}
		case 2:
		{
			SetPlayerPosition(playerid, "", DM_WORLD, DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_INT], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_3][0],
				DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_3][1], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_3][2], DMInfo[PlayerInfo[playerid][pDeathmatchId]][DM_SPAWN_3][3]);
		}
	}

	UpdateLabelText(playerid);
	KillTimer(DelayerTimer[playerid]);
	DelayerTimer[playerid] = SetTimerEx("InitPlayer", GetPlayerPing(playerid) + 500, false, "i", playerid);
	return 1;
}

//Deathmatch Commands

ChangePlayerMode(playerid) {
	new
		string[110],
		dialogstr[470]
	;
	format(string, sizeof(string), "Shortcut\tArea\tPlayers\n");
	strcat(dialogstr, string);
	for (new i = 0; i < sizeof(DMInfo); i++) {
		new count = 0;
		foreach (new x: Player) {
			if (PlayerInfo[x][pDeathmatchId] == i) {
				count++;
			}
		}
		format(string, sizeof(string), "%s\t%d\n", DMInfo[i][DM_NAME], count);
		strcat(dialogstr, string);
	}
	inline DMList(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return 1;
		PlayerInfo[pid][pDeathmatchId] = listitem;
		new dm_count = 0;
		foreach (new i: Player) {
			if (i != pid) {
				if (PlayerInfo[pid][pDeathmatchId] == PlayerInfo[i][pDeathmatchId]) {
					dm_count ++;
				}
			}
		}
		PlayReadySound(playerid);
		SpawnPlayer(pid);
		format(string, sizeof(string), "~r~%s ~w~joined ~g~%s ~w~DM", PlayerInfo[pid][PlayerName], DMInfo[PlayerInfo[pid][pDeathmatchId]][DM_NAME]);
		SendWarUpdate(string);
		LogActivity(pid, "Joined DM: %s", gettime(), DMInfo[PlayerInfo[pid][pDeathmatchId]][DM_NAME]);
	}

	inline GameMode(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return 1;
		switch (listitem) {
			case 0: {
				if (IsPlayerInMode(pid, MODE_BATTLEFIELD)) return SendClientMessage(pid, X11_WINE, "You are alread in the battlefield.");
				SendClientMessage(pid, X11_WINE, "Returning back to the playzone...");
				if (PlayerInfo[pid][pDeathmatchId]  != -1) {
					pDMKills[pid][PlayerInfo[playerid][pDeathmatchId]] = 0;
				}	
				PlayerInfo[pid][pDeathmatchId] = -1;
				SetPlayerVirtualWorld(pid, BF_WORLD);
				SetPlayerHealth(pid, 0.0);
			}
			case 1:	{
				if (!IsPlayerInMode(pid, MODE_BATTLEFIELD)) return SendClientMessage(pid, X11_WINE, "You are not in the battlefield to change your mode.");
				Dialog_ShowCallback(pid, using inline DMList, DIALOG_STYLE_TABLIST_HEADERS, ""WINE"SvT - Deathmatch", dialogstr, ">>", "X");
			}
			case 2: {
				if (Iter_Count(Player) < 4) return SendClientMessage(playerid, X11_RED_2, "There have to be at least 4 online players for this event to work.");
				StartPUBGByPlayer(pid);
				PC_EmulateCommand(pid, "/pubg");
			}
			case 3: {
				PC_EmulateCommand(pid, "/race");
			}
		}
	}
	Dialog_ShowCallback(playerid, using inline GameMode, DIALOG_STYLE_LIST, ""WINE"SvT - Game Mode", "Battlefield\nDeathmatch\nPUBG Event\nRacing", ">>", "X");
	return 1;
}

//CLAN SYSTEM

forward KickClanMember(playerid, Reason[]);
forward OnClanLogView(playerid);
forward CancelInvite(playerid);
forward LoadClans();
forward InitializeClan(playerid, const clan_name[35]);
forward HideClanAdv();

public HideClanAdv() {
	foreach (new i: Player) {
		TextDrawHideForPlayer(i, CAdv_TD[0]);
		TextDrawHideForPlayer(i, CAdv_TD[1]);
	}
	return 1;
}

public KickClanMember(playerid, Reason[]) {
	if (cache_num_rows() > 0) {
		new username[MAX_PLAYER_NAME], id;
		cache_get_value(0, "Username", username, sizeof(username));
		cache_get_value_int(0, "Username", id);

		foreach (new i: Player) {
			if (IsPlayerInAnyClan(i)) {
				if (pClan[playerid] == pClan[i]) {
					SendGameMessage(i, X11_SERV_INFO, MSG_CLAN_KICK, username, Reason);
				}
			}

			if (!strcmp(PlayerInfo[i][PlayerName], username, true) && !isnull(username)) {
				pClan[i] = -1;
				pClanRank[i] = 0;
				PlayerInfo[i][pClanTag] = 0;
			}
		}

		new query[140];

		mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `ClanId` = '-1', `ClanRank` = '0' WHERE `Username` = '%e' LIMIT 1",  username);
		mysql_tquery(Database, query);

		format(query, sizeof(query), "Offline kicked #%d from the clan", id);
		AddClanLog(playerid, query);

	} else SendGameMessage(playerid, X11_SERV_ERR, MSG_CLAN_MISMATCH);
	return 1;
}

//Clan logger
public OnClanLogView(playerid) {
	if (cache_num_rows()) {
		for (new i, j = cache_num_rows(); i != j; i++) {
			new member[MAX_PLAYER_NAME], rank, action[MEDIUM_STRING_LEN], date;
			cache_get_value(i, "Member", member, sizeof(member));
			cache_get_value_int(i, "Rank", rank);
			cache_get_value_int(i, "Date", date);
			cache_get_value(i, "Action", action, sizeof(action));

			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLAN_LOG, member, rank, action, GetWhen(date, gettime()));
		}
	} else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}

//Cancel a clan invitation
public CancelInvite(playerid) {
	PlayerInfo[playerid][pIsInvitedToClan] = 0;
	PlayerInfo[playerid][pInvitedToClan][0] = EOS;
	return 1;
}

//Create clan
public InitializeClan(playerid, const clan_name[35]) {
	new const clanid = cache_insert_id();
	pClan[playerid] = clanid;
	pClanRank[playerid] = 10;
	AddClanLog(playerid, "Created the clan");
	new string[256];
	format(string, sizeof(string), "- CS - "CYAN"%s[%d] "ORANGE"made their new clan \""RED"%s"ORANGE"\" and feels lonely, ask them to join it!", PlayerInfo[playerid][PlayerName], playerid, clan_name);
	SendClientMessageToAll(X11_ORANGE, string);
	return 1;
}

//Main clan core

forward DeleteClan_Call(playerid);
public DeleteClan_Call(playerid)
{
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `ClanId` = '-1', `ClanRank` = '0' WHERE `ClanId` = '%d'", pClan[playerid]);
	mysql_tquery(Database, query);

	mysql_format(Database, query, sizeof(query), "DELETE FROM `ClansData` WHERE `ClanId` = '%d'", pClan[playerid]);
	mysql_tquery(Database, query);

	foreach (new i: Player)
	{
		if (pClan[i] == pClan[playerid])
		{
			pClan[i] = -1;
			pClanRank[i] = 0;
		}
	}

	SendGameMessage(@pVerified, X11_SERV_WARN, "[Warning] %s[%d] deleted their clan!", PlayerInfo[playerid][PlayerName], playerid);
	return 1;
}

DeleteClan(playerid)
{
	if (GetPVarInt(playerid, "ConfirmDeleteClan") < 3)
	{
		SendClientMessage(playerid, X11_SERV_WARN, "[Warning] Are you sure you want to delete this clan? Please re-select this option 3 times to confirm.");
		SetPVarInt(playerid, "ConfirmDeleteClan", GetPVarInt(playerid, "ConfirmDeleteClan") + 1);
		return 1;
	}
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanOwner` FROM `ClansData` WHERE `ClanId` = '%d' LIMIT 1", pClan[playerid]);
	mysql_tquery(Database, query, "DeleteClan_Call", "i", playerid);
	return 1;
}

CreateClan(playerid, const clan_name[35], const clan_tag[], const clan_rank1[], const clan_rank2[], const clan_rank3[], const clan_rank4[], const clan_rank5[],
	const clan_rank6[], const clan_rank7[], const clan_rank8[], const clan_rank9[], const clan_rank10[], const clan_message[]) {
	if (IsPlayerInAnyClan(playerid) || IsValidClan(clan_name) || IsValidClanTag(clan_tag) || clans >= MAX_CLANS - 1) {
		return SendGameMessage(playerid, X11_SERV_ERR, MSG_CANT_CREATE_CLAN);
	}

	GivePlayerCash(playerid, -500000);

	new query[600];

	mysql_format(Database, query, sizeof(query), "INSERT INTO `ClansData` (`ClanName`, `ClanTag`, `ClanOwner`, `ClanMotd`, `ClanWallet`, `ClanKills`, `ClanDeaths`, `ClanPoints`, `Rank1`, `Rank2`, `Rank3`, `Rank4`, `Rank5`, `Rank6`, `Rank7`, `Rank8`, `Rank9`, `Rank10`, `ClanLevel`, `ClanSkin`) \
	VALUES ('%e', '[%e]', '%e', '%e', '10000', '0', '0', '0', '%e', '%e', '%e', '%e', '%e', '%e', '%e', '%e', '%e', '%e', '0', '0')",
		clan_name, clan_tag, PlayerInfo[playerid][PlayerName], clan_message, clan_rank1, clan_rank2, clan_rank3, clan_rank4, clan_rank5, clan_rank6, clan_rank7,
		clan_rank8, clan_rank9, clan_rank10);

	mysql_tquery(Database, query, "InitializeClan", "is", playerid, clan_name);
	return 1;
}

IsPlayerInAnyClan(playerid) {
	if (pClan[playerid] != -1) return 1;
	return 0;
}

IsValidClan(const clan_name[]) {
	new Cache: VerifyQuery, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT 1 FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	VerifyQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_delete(VerifyQuery);
		return 1;
	}
	cache_delete(VerifyQuery);
	return 0;
}

IsValidClanTag(const clan_tag[]) {
	new Cache: VerifyQuery, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT 1 FROM `ClansData` WHERE `ClanTag` LIKE '%e' LIMIT 1", clan_tag);
	VerifyQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_delete(VerifyQuery);
		return 1;
	}
	cache_delete(VerifyQuery);
	return 0;
}

GetPlayerClan(playerid) {
	new Cache: NameQuery, clan_name[35], query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanName` FROM `ClansData` WHERE `ClanId` = '%d' LIMIT 1", pClan[playerid]);
	NameQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value(0, "ClanName", clan_name, sizeof(clan_name));
	}
	cache_delete(NameQuery);
	return clan_name;
}

GetPlayerClanRank(playerid) {
	return pClanRank[playerid];
}

GetPlayerClanRankName(playerid) {
	new Cache: RankQuery, clan_rank[25], query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `Rank%d` AS RankName FROM `ClansData` WHERE `ClanId` = '%d' LIMIT 1", pClanRank[playerid], pClan[playerid]);
	RankQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value(0, "RankName", clan_rank, sizeof(clan_rank));
	}
	cache_delete(RankQuery);
	return clan_rank;
}

GetClanRankName(const clan_name[], rankid) {
	new Cache: RankQuery, clan_rank[25], query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `Rank%d` AS RankName FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", rankid, clan_name);
	RankQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value(0, "RankName", clan_rank, sizeof(clan_rank));
	}
	cache_delete(RankQuery);
	return clan_rank;
}

SetClanName(const clan_name[], const newName[]) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanName`= '%e' WHERE `ClanName` LIKE '%e' LIMIT 1", newName, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

SetClanTag(const clan_name[], const new_tag[]) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanTag`= '[%e]' WHERE `ClanName` LIKE '%e' LIMIT 1", new_tag, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

SetClanRankName(const clan_name[], rankid, const new_rank[]) {
	if (rankid > 10 || rankid < 1) return printf("[Clan Error] Failed to update out of range clan rank %d to %s [clan: %s]", rankid, new_rank, clan_name);
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `Rank%d`= '%e' WHERE `ClanName` LIKE '%e' LIMIT 1", rankid, new_rank, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

GetClanMotd(const clan_name[]) {
	new Cache: MOTDQuery, clan_motd[60], query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanMotd` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	MOTDQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value(0, "ClanMotd", clan_motd, sizeof(clan_motd));
	}
	cache_delete(MOTDQuery);
	return clan_motd;
}

SetClanMotd(const clan_name[], const title[]) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanMotd`= '%e' WHERE `ClanName` LIKE '%e' LIMIT 1", title, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

GetClanWeapon(const clan_name[]) {
	new Cache: WeaponQuery, weaponid, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanWeap` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	WeaponQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanWeap", weaponid);
	}
	cache_delete(WeaponQuery);
	return weaponid;
}

GetClanAddPerms(const clan_name[]) {
	new Cache: PermsQuery, clan_perms, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `InviteClanLevel` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	PermsQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "InviteClanLevel", clan_perms);
	}
	cache_delete(PermsQuery);
	return clan_perms;
}

GetClanWarPerms(const clan_name[]) {
	new Cache: PermsQuery, clan_perms, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanWarLevel` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	PermsQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanWarLevel", clan_perms);
	}
	cache_delete(PermsQuery);
	return clan_perms;
}

GetClanSetPerms(const clan_name[]) {
	new Cache: PermsQuery, clan_perms, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanPermsLevel` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	PermsQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanPermsLevel", clan_perms);
	}
	cache_delete(PermsQuery);
	return clan_perms;
}

GetClanSkin(const clan_name[]) {
	new Cache: SkinQuery, skin, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanSkin` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	SkinQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanSkin", skin);
	}
	cache_delete(SkinQuery);
	return skin;
}

SetClanSkin(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanSkin`= '%d' WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

SetClanWeapon(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanWeap`= '%d' WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

SetClanAddPerms(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `InviteClanLevel`= '%d' WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

SetClanWarPerms(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanWarLevel`= '%d' WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

SetClanSetPerms(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanPermsLevel`= '%d' WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 1;
}
//InviteClanLevel = '%d', ClanWarLevel = '%d', ClanPermsLevel = '%d'
GetClanName(const clan_tag[]) {
	new Cache: NameQuery, clan_name[35], query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanName` FROM `ClansData` WHERE `ClanTag` LIKE '%e' LIMIT 1", clan_tag);
	NameQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value(0, "ClanName", clan_name, sizeof(clan_name));
	}
	cache_delete(NameQuery);
	return clan_name;
}

GetClanNameById(clan_id) {
	new Cache: NameQuery, clan_name[35], query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanName` FROM `ClansData` WHERE `ClanId` = '%d' LIMIT 1", clan_id);
	NameQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value(0, "ClanName", clan_name, sizeof(clan_name));
	}
	cache_delete(NameQuery);
	return clan_name;
}

GetClanIdByName(const clan_name[]) {
	new Cache: IdQuery, clan_id = -1, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanId` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	IdQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanId", clan_id);
	}
	cache_delete(IdQuery);
	return clan_id;
}

GetClanTag(const clan_name[]) {
	new Cache: TagQuery, clan_tag[10], query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanTag` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	TagQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value(0, "ClanTag", clan_tag, sizeof(clan_tag));
	}
	cache_delete(TagQuery);
	return clan_tag;
}

GetClanXP(const clan_name[]) {
	new Cache: XPQuery, xp, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanPoints` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	XPQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanPoints", xp);
	}
	cache_delete(XPQuery);
	return xp;
}

AddClanXP(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanPoints`=`ClanPoints`+%d WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 1;
}

GetClanLevel(const clan_name[]) {
	new Cache: LevelQuery, xp, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanPoints` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	LevelQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanPoints", xp);
		for (new x = sizeof(ClanRanks) - 1; x > -1; x--) {
			if (xp >= ClanRanks[x][C_LevelXP]) {
				xp = x;
				break;
			}
		}
	}
	cache_delete(LevelQuery);
	return xp;
}

GetClanWallet(const clan_name[]) {
	new Cache: WalletQuery, wallet, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanWallet` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	WalletQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanWallet", wallet);
	}
	cache_delete(WalletQuery);
	return wallet;
}

AddClanWallet(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanWallet`=`ClanWallet`+%d WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 0;
}

stock GetClanKills(const clan_name[]) {
	new Cache: KillsQuery, kills, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanKills` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	KillsQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanKills", kills);
	}
	cache_delete(KillsQuery);
	return kills;
}

AddClanKills(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanKills`=`ClanKills`+%d WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 0;
}

stock GetClanDeaths(const clan_name[]) {
	new Cache: DeathsQuery, deaths, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT `ClanDeaths` FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan_name);
	DeathsQuery = mysql_query(Database, query);
	if (cache_num_rows()) {
		cache_get_value_int(0, "ClanDeaths", deaths);
	}
	cache_delete(DeathsQuery);
	return deaths;
}

AddClanDeaths(const clan_name[], amount) {
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE `ClansData` SET `ClanDeaths`=`ClanDeaths`+%d WHERE `ClanName` LIKE '%e' LIMIT 1", amount, clan_name);
	mysql_tquery(Database, query);
	return 0;
}

AddClanLog(playerid, const action[]) {
	if (IsPlayerInAnyClan(playerid)) {
		new query[600];
		mysql_format(Database, query, sizeof(query),
			"INSERT INTO `ClanLog` (`cID`, `Member`, `Rank`, `Action`, `Date`) \
			VALUES('%d', '%e', '%d', '%e', '%d')", pClan[playerid], PlayerInfo[playerid][PlayerName],
				GetPlayerClanRank(playerid), action, gettime());
		mysql_tquery(Database, query);
	}
	return 1;
}

//Clan war

/*
enum CWData {
	CWStarted,
	CWId1,
	CWId2,
	CWMode,
	CWWeaps[5],
	CWAmmo[5],
	Float: CWPos1[4],
	Float: CWPos2[4],
	CWInt,
	CWWorld
}
new CWInfo[CWData];
*/

forward InitiateCW();
public InitiateCW() {
	if (CWCD) {
		new cd[6];
		format(cd, sizeof(cd), "~g~%d", CWCD);
		foreach (new i: CWCLAN1) GameTextForPlayer(i, cd, 1000, 3);
		foreach (new i: CWCLAN2) GameTextForPlayer(i, cd, 1000, 3);
		CWCD --;
	} else {
		KillTimer(CWTimer);
		foreach (new i: CWCLAN1) {
			GameTextForPlayer(i, "~g~GO!", 1000, 3);
			PlayGoSound(i);
			TogglePlayerControllable(i, true);
			SetPlayerMarkerVisibility(i, 0xFF);
			for (new x = 0; x < 5; x++) {
				GivePlayerWeapon(i, CWInfo[CWWeaps][x], CWInfo[CWAmmo][x]);
			}
		}
		foreach (new i: CWCLAN2) {
			GameTextForPlayer(i, "~g~GO!", 1000, 3);
			PlayGoSound(i);
			TogglePlayerControllable(i, true);
			SetPlayerMarkerVisibility(i, 0xFF);
			for (new x = 0; x < 5; x++) {
				GivePlayerWeapon(i, CWInfo[CWWeaps][x], CWInfo[CWAmmo][x]);
			}
		}
		UpdateClanWarStats();
	}
	return 1;
}

SetupClanwar(playerid) {
	new Float: fX = frandom(5.0, -5.0), Float: fY = frandom(5.0, -5.0);

	SetPlayerInterior(playerid, CWInfo[CWInt]);
	SetPlayerVirtualWorld(playerid, CWInfo[CWWorld]);

	UpdateLabelText(playerid);
	SetPlayerColor(playerid, (random(0xFFFFFF) << 8) + 0xFF);

	TogglePlayerControllable(playerid, false);

	if (Iter_Contains(CWCLAN1, playerid)) {
		SetPlayerPosition(playerid, "", CW_WORLD, 0, CWInfo[CWPos1][0] + fX, CWInfo[CWPos1][1] + fY, CWInfo[CWPos1][2], CWInfo[CWPos1][3], true);
	}

	if (Iter_Contains(CWCLAN2, playerid)) {
		SetPlayerPosition(playerid, "", CW_WORLD, 0, CWInfo[CWPos2][0] + fX, CWInfo[CWPos2][1] + fY, CWInfo[CWPos2][2], CWInfo[CWPos2][3], true);
	}

	new CWSkins[] = {
		21, 24, 25, 28, 29, 41, 66, 67, 68, 69, 100, 101, 111, 179, 191, 202, 249
	};
	SetPlayerSkin(playerid, CWSkins[random(sizeof(CWSkins))]);

	SetPlayerHealth(playerid, 100.0);
	SetPlayerArmour(playerid, 100.0);

	PlayReadySound(playerid);

	NotifyPlayer(playerid, "You are now in the clan war. Be prepared.");
}

UpdateClanWar(playerid) {
	if (!Iter_Contains(CWCLAN1, playerid) && !Iter_Contains(CWCLAN2, playerid)) return 1;
	if (Iter_Contains(CWCLAN1, playerid)) {
		new string[128];
		format(string, sizeof(string), "[CLAN WAR] "DARKGRAY"%s[%d] lost for %s (players left: %d/%d)",
			PlayerInfo[playerid][PlayerName], playerid, GetClanNameById(CWInfo[CWId1]), Iter_Count(CWCLAN1) - 1, CWInfo[CWParties1]);
		SendClientMessageToAll(X11_YELLOW, string);
		Iter_Remove(CWCLAN1, playerid);
	}
	if (Iter_Contains(CWCLAN2, playerid)) {
		new string[128];
		format(string, sizeof(string), "[CLAN WAR] "DARKGRAY"%s[%d] lost for %s (players left: %d/%d)",
			PlayerInfo[playerid][PlayerName], playerid, GetClanNameById(CWInfo[CWId2]), Iter_Count(CWCLAN2) - 1, CWInfo[CWParties2]);
		SendClientMessageToAll(X11_YELLOW, string);
		Iter_Remove(CWCLAN2, playerid);
	}
	GameTextForPlayer(playerid, "~r~LOSER!", 3000, 3);
	if (!Iter_Count(CWCLAN1)) {
		new string[128];
		format(string, sizeof(string), "[CLAN WAR] "DARKGRAY"%s won the clan war against %s (%d/%d)", GetClanNameById(CWInfo[CWId2]), GetClanNameById(CWInfo[CWId1]),
		Iter_Count(CWCLAN2), CWInfo[CWParties2]);
		SendClientMessageToAll(X11_YELLOW, string);
		AddClanXP(GetClanNameById(CWInfo[CWId2]), 5000);
		foreach (new i: CWCLAN2) {
			SuccessAlert(i);
			SpawnPlayer(i);
		}
		Iter_Clear(CWCLAN2);
	} else if (!Iter_Count(CWCLAN2)) {
		new string[128];
		format(string, sizeof(string), "[CLAN WAR] "DARKGRAY"%s won the clan war against %s (%d/%d)", GetClanNameById(CWInfo[CWId1]), GetClanNameById(CWInfo[CWId2]),
		Iter_Count(CWCLAN1), CWInfo[CWParties1]);
		SendClientMessageToAll(X11_YELLOW, string);
		AddClanXP(GetClanNameById(CWInfo[CWId1]), 5000);
		foreach (new i: CWCLAN1) {
			SuccessAlert(i);
			SpawnPlayer(i);
		}
		Iter_Clear(CWCLAN1);
	}
	UpdateClanWarStats();
	return 1;
}

forward OnCWPartyRemoved(playerid, userid, user[MAX_PLAYER_NAME]);
public OnCWPartyRemoved(playerid, userid, user[MAX_PLAYER_NAME]) {
	new message[128];
	format(message, sizeof(message), "You removed account id #%d (%s) from the first clan", userid, user);
	SendClientMessage(playerid, X11_GREEN, message);
	return 1;
}

forward AddCWParties(playerid);
public AddCWParties(playerid) {
	if (!cache_num_rows()) return SendClientMessage(playerid, X11_WINE, "An error occured. No users found in the clan war table.");
	for (new i, j = cache_num_rows(); i != j; i++) {
		new id, cid;
		cache_get_value_int(i, "pID", id);
		cache_get_value_int(i, "cID", cid);
		foreach (new x: Player) {
			if (PlayerInfo[x][pAccountId] == id) {
				if (cid == CWInfo[CWId1]) {
					Iter_Add(CWCLAN1, x);
				} else if (cid == CWInfo[CWId2]) {
					Iter_Add(CWCLAN2, x);
				}
			}
		}
	}

	if (CWInfo[CWParties1] != Iter_Count(CWCLAN1) || CWInfo[CWParties2] != Iter_Count(CWCLAN2)) {
		Iter_Clear(CWCLAN1);
		Iter_Clear(CWCLAN2);
		return SendClientMessage(playerid, X11_WINE, "One of the clans doesn't have the exact needed amount of online opponents to start.");
	}

	foreach (new i: CWCLAN1) {
		SetupClanwar(i);
	}

	foreach (new i: CWCLAN2) {
		SetupClanwar(i);
	}

	new string[128];
	format(string, sizeof(string), "[CLAN WAR] "DARKGRAY"Clan War begins %s[%d] VS [%d]%s", GetClanNameById(CWInfo[CWId1]), Iter_Count(CWCLAN1), Iter_Count(CWCLAN2), GetClanNameById(CWInfo[CWId2]));
	SendClientMessageToAll(X11_YELLOW, string);

	CWCD = 10;
	CWTimer = SetTimer("InitiateCW", 1000, true);
	ShowClanWarStandings();
	return 1;
}

ClanWarManager(playerid) {
	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return SendClientMessage(playerid, X11_WINE, "Only server managers can manage clan war.");

	inline CWRemoveParty(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		new Cache: CWParty, query[256];
		mysql_format(Database, query, sizeof(query), "SELECT `ID`, `ClanId` FROM `Players` WHERE `Username` LIKE '%e' LIMIT 1", inputtext);
		CWParty = mysql_query(Database, query);
		if (cache_num_rows()) {
			new userid, clan;
			cache_get_value_int(0, "ID", userid);
			cache_get_value_int(0, "ClanId", clan);
			if (CWInfo[CWId1] == clan) {
				CWInfo[CWParties1] --;
			} else if (CWInfo[CWId2] == clan) {
				CWInfo[CWParties2] --;
			}
			mysql_format(Database, query, sizeof(query), "DELETE FROM `CWParties` WHERE `pID` = '%d' LIMIT 1", userid);
			mysql_tquery(Database, query, "OnCWPartyRemoved", "iis", playerid, userid, inputtext);
		} else SendClientMessage(pid, X11_WINE, "There are no players with matching name in the clan war.");
		cache_delete(CWParty);
	}

	inline CWAddParty(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		new Cache: CWParty, query[256];
		mysql_format(Database, query, sizeof(query), "SELECT `ID`, `ClanId` FROM `Players` WHERE `Username` LIKE '%e' LIMIT 1", inputtext);
		CWParty = mysql_query(Database, query);
		if (cache_num_rows()) {
			new parties_limit = 0;
			switch (CWInfo[CWMode]) {
				case CW_8v8: parties_limit = 8;
				case CW_4v4: parties_limit = 4;
				case CW_2v2: parties_limit = 2;
				default: parties_limit = 1;
			}
			new clanid, userid;
			cache_get_value_int(0, "ClanId", clanid);
			cache_get_value_int(0, "ID", userid);
			if (clanid == CWInfo[CWId1]) {
				if (CWInfo[CWParties1] < parties_limit) {
					mysql_format(Database, query, sizeof(query), "INSERT INTO `CWParties`(`pID`, `cID`) VALUES ('%d', '%d')", userid, clanid);
					mysql_tquery(Database, query);
					format(query, sizeof(query), "You added account id #%d (%s) to the first clan", userid, inputtext);
					SendClientMessage(pid, X11_GREEN, query);
					CWInfo[CWParties1] ++;
				} else SendClientMessage(pid, X11_WINE, "The first clan already has the maximum amount of participants for this mode.");
			} else if (clanid == CWInfo[CWId2]) {
				if (CWInfo[CWParties2] < parties_limit) {
					mysql_format(Database, query, sizeof(query), "INSERT INTO `CWParties`(`pID`, `cID`) VALUES ('%d', '%d')", userid, clanid);
					mysql_tquery(Database, query);
					format(query, sizeof(query), "You added account id #%d (%s) to the second clan", userid, inputtext);
					SendClientMessage(pid, X11_GREEN, query);
					CWInfo[CWParties2] ++;
				} else SendClientMessage(pid, X11_WINE, "The second clan already has the maximum amount of participants for this mode.");
			} else SendClientMessage(pid, X11_WINE, "This player doesn't belong to either of the clan war opponents.");
		} else SendClientMessage(pid, X11_WINE, "There are no players with matching name.");
		cache_delete(CWParty);
	}

	inline CWOppMode(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, inputtext
		if (!response) return ClanWarManager(pid);
		switch (listitem) {
			case 0: {
				CWInfo[CWMode] = CW_8v8;
				SendClientMessage(pid, X11_GREEN, "Selecting Round 16 mode. You need to add 16 players (8 from each clan) to the system to start this war.");
			}
			case 1: {
				CWInfo[CWMode] = CW_4v4;
				SendClientMessage(pid, X11_GREEN, "Selecting Quarterfinals mode. You need to add 8 players (4 from each clan) to the system to start this war.");
			}
			case 2: {
				CWInfo[CWMode] = CW_2v2;
				SendClientMessage(pid, X11_GREEN, "Selecting Semifinals mode. You need to add 4 players (2 from each clan) to the system to start this war.");
			}
			default: {
				CWInfo[CWMode] = CW_1v1;
				SendClientMessage(pid, X11_GREEN, "Selecting Final mode. You need to add 2 players (1 from each clan) to the system to start this war.");
			}
		}
		ClanWarManager(pid);
	}

	inline CWManParty(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, inputtext
		if (!response) return ClanWarManager(pid);
		switch (listitem) {
			case 0: {
				new string[128];
				format(string, sizeof(string), "There are currently %dv%d participants.", CWInfo[CWParties1], CWInfo[CWParties2]);
				SendClientMessage(pid, X11_WINE, string);

				switch (CWInfo[CWMode]) {
					case CW_8v8: if ((CWInfo[CWParties1] + CWInfo[CWParties2]) >= 16) return SendClientMessage(pid, X11_WINE, "You can't add more participants to the 8v8 mode.");
					case CW_4v4: if ((CWInfo[CWParties1] + CWInfo[CWParties2]) >= 8) return SendClientMessage(pid, X11_WINE, "You can't add more participants to the 4v4 mode.");
					case CW_2v2: if ((CWInfo[CWParties1] + CWInfo[CWParties2]) >= 4) return SendClientMessage(pid, X11_WINE, "You can't add more participants to the 2v2 mode.");
					default: if ((CWInfo[CWParties1] + CWInfo[CWParties2]) >= 2) return SendClientMessage(pid, X11_WINE, "You can't add more participants to the 1v1 mode.");
				}
				Dialog_ShowCallback(pid, using inline CWAddParty, DIALOG_STYLE_INPUT, "Add Opponent", "Please write the name of a player to add to the system.", ">>", "X");
			}
			case 1: {
				Dialog_ShowCallback(pid, using inline CWRemoveParty, DIALOG_STYLE_INPUT, "Remove Opponent", "Please write the name of a player to remove from the system.", ">>", "X");
			}
			case 2: {
				new Cache: CWParty;
				CWParty = mysql_query(Database, "SELECT d1.Username, d1.ClanId FROM `Players` AS d1, `CWParties` AS d2 \
				WHERE d1.ID = d2.pID AND d1.ClanId = d2.cID");
				if (cache_num_rows()) {
					for (new i, j = cache_num_rows(); i != j; i++) {
						new clan_id, user[MAX_PLAYER_NAME], string[128];
						cache_set_active(CWParty);
						cache_get_value(i, "Username", user);
						cache_get_value_int(i, "ClanId", clan_id);
						format(string, sizeof(string), "%d. %s is part of %s in the war.", i + 1, user, GetClanNameById(clan_id));
						SendClientMessage(playerid, X11_CYAN, string);
					}
				} else SendClientMessage(playerid, X11_WINE, "There are no players in the clan war system.");
				cache_delete(CWParty);
			}
		}
	}

	inline CWFinalize(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem, inputtext
		if (!response) return ClanWarManager(pid);
		CWInfo[CWStarted] = 1;
		SendClientMessage(pid, X11_WINE, "You begun the clan war process. You will now be redirected to the clan war manager dialogue.");
		SendClientMessage(playerid, X11_YELLOW, "[CLAN WAR] "DARKGRAY"A clan war is being created behind the scenes!");
		ClanWarManager(pid);
	}

	inline CWWeapAmmo5(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		new weap, ammo;
		if (sscanf(inputtext, "ii", weap, ammo)) return SendClientMessage(pid, X11_WINE, "Insufficient or incorrect parameters specified. Please make sure to write weapon id/ammo properly.");
		if (!IsValidWeapon(weap) || ammo > 9999 || ammo < 0) return SendClientMessage(pid, X11_WINE, "Either the specified weapon is invalid, or the ammo is above 9999 or below 0.");
		CWInfo[CWWeaps][4] = weap, CWInfo[CWAmmo][4] = ammo;
		new string[128];
		format(string, sizeof(string), "Adding weapon %s[%d] with ammo %d to the clan war system.", ReturnWeaponName(weap), weap, ammo);
		SendClientMessage(pid, X11_WINE, string);
		Dialog_ShowCallback(pid, using inline CWFinalize, DIALOG_STYLE_MSGBOX, "Clan War Finalization", "Are you sure to start this clan war? Check for any wrong information above.", ">>", "X");
	}

	inline CWWeapAmmo4(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		new weap, ammo;
		if (sscanf(inputtext, "ii", weap, ammo)) return SendClientMessage(pid, X11_WINE, "Insufficient or incorrect parameters specified. Please make sure to write weapon id/ammo properly.");
		if (!IsValidWeapon(weap) || ammo > 9999 || ammo < 0) return SendClientMessage(pid, X11_WINE, "Either the specified weapon is invalid, or the ammo is above 9999 or below 0.");
		CWInfo[CWWeaps][3] = weap, CWInfo[CWAmmo][3] = ammo;
		new string[128];
		format(string, sizeof(string), "Adding weapon %s[%d] with ammo %d to the clan war system.", ReturnWeaponName(weap), weap, ammo);
		SendClientMessage(pid, X11_WINE, string);
		Dialog_ShowCallback(pid, using inline CWWeapAmmo5, DIALOG_STYLE_INPUT, "Clan War Weapons", "Please write the weapon id and ammo of the last clan weapon.", ">>", "X");
	}

	inline CWWeapAmmo3(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		new weap, ammo;
		if (sscanf(inputtext, "ii", weap, ammo)) return SendClientMessage(pid, X11_WINE, "Insufficient or incorrect parameters specified. Please make sure to write weapon id/ammo properly.");
		if (!IsValidWeapon(weap) || ammo > 9999 || ammo < 0) return SendClientMessage(pid, X11_WINE, "Either the specified weapon is invalid, or the ammo is above 9999 or below 0.");
		CWInfo[CWWeaps][2] = weap, CWInfo[CWAmmo][2] = ammo;
		new string[128];
		format(string, sizeof(string), "Adding weapon %s[%d] with ammo %d to the clan war system.", ReturnWeaponName(weap), weap, ammo);
		SendClientMessage(pid, X11_WINE, string);
		Dialog_ShowCallback(pid, using inline CWWeapAmmo4, DIALOG_STYLE_INPUT, "Clan War Weapons", "Please write the weapon id and ammo of the fourth clan weapon.", ">>", "X");
	}

	inline CWWeapAmmo2(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		new weap, ammo;
		if (sscanf(inputtext, "ii", weap, ammo)) return SendClientMessage(pid, X11_WINE, "Insufficient or incorrect parameters specified. Please make sure to write weapon id/ammo properly.");
		if (!IsValidWeapon(weap) || ammo > 9999 || ammo < 0) return SendClientMessage(pid, X11_WINE, "Either the specified weapon is invalid, or the ammo is above 9999 or below 0.");
		CWInfo[CWWeaps][1] = weap, CWInfo[CWAmmo][1] = ammo;
		new string[128];
		format(string, sizeof(string), "Adding weapon %s[%d] with ammo %d to the clan war system.", ReturnWeaponName(weap), weap, ammo);
		SendClientMessage(pid, X11_WINE, string);
		Dialog_ShowCallback(pid, using inline CWWeapAmmo3, DIALOG_STYLE_INPUT, "Clan War Weapons", "Please write the weapon id and ammo of the third clan weapon.", ">>", "X");
	}

	inline CWWeapAmmo1(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		new weap, ammo;
		if (sscanf(inputtext, "ii", weap, ammo)) return SendClientMessage(pid, X11_WINE, "Insufficient or incorrect parameters specified. Please make sure to write weapon id/ammo properly.");
		if (!IsValidWeapon(weap) || ammo > 9999 || ammo < 0) return SendClientMessage(pid, X11_WINE, "Either the specified weapon is invalid, or the ammo is above 9999 or below 0.");
		CWInfo[CWWeaps][0] = weap, CWInfo[CWAmmo][0] = ammo;
		new string[128];
		format(string, sizeof(string), "Adding weapon %s[%d] with ammo %d to the clan war system.", ReturnWeaponName(weap), weap, ammo);
		SendClientMessage(pid, X11_WINE, string);
		Dialog_ShowCallback(pid, using inline CWWeapAmmo2, DIALOG_STYLE_INPUT, "Clan War Weapons", "Please write the weapon id and ammo of the second clan weapon.", ">>", "X");
	}

	inline CWSpawns(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, inputtext
		if (!response) return ClanWarManager(pid);
		switch (listitem) {
			case 0: {
				GetPlayerPos(playerid, CWInfo[CWPos1][0], CWInfo[CWPos1][1], CWInfo[CWPos1][2]);
				GetPlayerFacingAngle(playerid, CWInfo[CWPos1][3]);
				CWInfo[CWInt] = GetPlayerInterior(playerid);
				CWInfo[CWWorld] = GetPlayerVirtualWorld(playerid);
				SendClientMessage(playerid, X11_WINE, "First clan spawn point set to your current coordiantes (so as the virtual world and interior).");
			}
			case 1: {
				GetPlayerPos(playerid, CWInfo[CWPos2][0], CWInfo[CWPos2][1], CWInfo[CWPos2][2]);
				GetPlayerFacingAngle(playerid, CWInfo[CWPos2][3]);
				SendClientMessage(playerid, X11_WINE, "Second clan spawn point set to your current coordiantes.");
			}
		}
	}

	inline CWManMatch(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, inputtext
		if (!response) return ClanWarManager(pid);
		switch (listitem) {
			case 0: Dialog_ShowCallback(pid, using inline CWWeapAmmo1, DIALOG_STYLE_INPUT, "Clan War Weapons", "Please write the weapon id and ammo of the first clan weapon.", ">>", "X");
			case 1: Dialog_ShowCallback(pid, using inline CWSpawns, DIALOG_STYLE_LIST, "Clan War Spawns", "Set 1st Spawn\nSet 2nd Spawn", ">>", "X");
			case 2: {
				switch (CWInfo[CWMode]) {
					case CW_8v8: if (CWInfo[CWParties1] != 8 || CWInfo[CWParties2] != 8) return SendClientMessage(pid, X11_WINE, "One of the clans doesn't have the needed amount of players yet.");
					case CW_4v4: if (CWInfo[CWParties1] != 4 || CWInfo[CWParties2] != 4) return SendClientMessage(pid, X11_WINE, "One of the clans doesn't have the needed amount of players yet.");
					case CW_2v2: if (CWInfo[CWParties1] != 2 || CWInfo[CWParties2] != 2) return SendClientMessage(pid, X11_WINE, "One of the clans doesn't have the needed amount of players yet.");
					default: if (CWInfo[CWParties1] != 1 || CWInfo[CWParties2] != 1) return SendClientMessage(pid, X11_WINE, "One of the clans doesn't have the needed amount of players yet.");
				}

				mysql_tquery(Database, "SELECT * FROM `CWParties`", "AddCWParties", "i", playerid);
			}
		}
	}

	inline CWManStart(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, inputtext
		if (!response) return 1;
		switch (listitem) {
			case 0: {
				if (!CWInfo[CWMode]) {
					Dialog_ShowCallback(pid, using inline CWOppMode, DIALOG_STYLE_LIST, "Opponent Mode",
					"Round 16 (8v8)\n\
					Quarterfinals (4v4)\n\
					Semifinals (2v2)\n\
					Final Round (1v1)", ">>", "X");
				} else {
					Dialog_ShowCallback(pid, using inline CWManParty, DIALOG_STYLE_LIST, "Manage Opponents", "Add Opponent\nRemove Opponent\nList Opponents", ">>", "X");
				}
			}
			case 1: {
				Dialog_ShowCallback(pid, using inline CWManMatch, DIALOG_STYLE_LIST, "Manage Match", "Reset Weapons\nMatch Spawns\nBegin Match", ">>", "X");
			}
			case 2: {
				new cw_reset[CWData];
				CWInfo = cw_reset;
				foreach (new i: CWCLAN1) {
					SpawnPlayer(i);
					GameTextForPlayer(playerid, "~r~NO WAR!", 3000, 3);
				}
				foreach (new i: CWCLAN2) {
					SpawnPlayer(i);
					GameTextForPlayer(playerid, "~r~NO WAR!", 3000, 3);
				}
				Iter_Clear(CWCLAN1);
				Iter_Clear(CWCLAN2);
				mysql_tquery(Database, "DELETE FROM `CWParties`");
				SendClientMessage(playerid, X11_WINE, "You successfully destroyed the current clan war setup.");
				SendClientMessage(playerid, X11_YELLOW, "[CLAN WAR] "DARKGRAY"The current clan war that was being planned has been aborted.");
			}
		}
	}

	inline CWSecondOpp(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		if (!IsValidClan(inputtext)) return SendClientMessage(pid, X11_WINE, "This clan doesn't seem to be valid at all.");
		CWInfo[CWId2] = GetClanIdByName(inputtext);
		if (CWInfo[CWId2] == -1) return SendClientMessage(playerid, X11_WINE, "Invalid clan name specified.");
		new string[128];
		format(string, sizeof(string), "Selecting clan \"%s\" as the second opponent clan.", inputtext);
		SendClientMessage(pid, X11_WINE, string);
		Dialog_ShowCallback(pid, using inline CWWeapAmmo1, DIALOG_STYLE_INPUT, "Clan War Weapons", "Please write the weapon id and ammo of the first clan weapon.", ">>", "X");
	}

	inline CWFirstOpp(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem
		if (!response) return ClanWarManager(pid);
		if (!IsValidClan(inputtext)) return SendClientMessage(pid, X11_WINE, "This clan doesn't seem to be valid at all.");
		CWInfo[CWId1] = GetClanIdByName(inputtext);
		if (CWInfo[CWId1] == -1) return SendClientMessage(playerid, X11_WINE, "Invalid clan name specified.");
		new string[128];
		format(string, sizeof(string), "Selecting clan \"%s\" as the first opponent clan.", inputtext);
		SendClientMessage(pid, X11_WINE, string);
		Dialog_ShowCallback(pid, using inline CWSecondOpp, DIALOG_STYLE_INPUT, "Second Opponent", "Please write the name of the second clan war opponent.", ">>", "X");
	}

	inline CWStart(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, inputtext
		if (response && listitem == 0) {
			new cw_reset[CWData];
			CWInfo = cw_reset;
			Iter_Clear(CWCLAN1);
			Iter_Clear(CWCLAN2);
			mysql_tquery(Database, "DELETE FROM `CWParties`");
			Dialog_ShowCallback(pid, using inline CWFirstOpp, DIALOG_STYLE_INPUT, "First Opponent", "Please write the name of the first clan war opponent.", ">>", "X");
		}
	}

	if (CWInfo[CWStarted]) {
		Dialog_ShowCallback(playerid, using inline CWManStart, DIALOG_STYLE_LIST, "Clan War Manager",
		"Manage Opponents\n\
		Match Control\n\
		End War", ">>", "X");
		return 1;
	}

	Dialog_ShowCallback(playerid, using inline CWStart, DIALOG_STYLE_LIST, "Start CW?", "Start Clan War", ">>", "X");
	return 1;
}

stock UpdateClanWarStats() {
	TextDrawSetString(CWTD_2, GetClanNameById(CWInfo[CWId1]));
	TextDrawSetString(CWTD_3, GetClanNameById(CWInfo[CWId2]));

	new clan_health[15], clan_participants_alive;

	foreach (new i: CWCLAN1) {
		if (IsPlayerSpawned(i)) {
			clan_participants_alive ++;
		}
	}
	format(clan_health, sizeof(clan_health), "%%%0.1f ALIVE", floatdiv(clan_participants_alive, Iter_Count(CWCLAN1)) * 100);
	foreach (new playerid: Player) {
		PlayerTextDrawSetString(playerid, CW_PTD[playerid][0], clan_health);
		SetPlayerProgressBarValue(playerid, CW_PBAR[playerid][0], floatdiv(clan_participants_alive, Iter_Count(CWCLAN1)) * 100);
	}

	clan_participants_alive = 0;

	foreach (new i: CWCLAN2) {
		if (IsPlayerSpawned(i)) {
			clan_participants_alive ++;
		}
	}
	format(clan_health, sizeof(clan_health), "%%%0.1f ALIVE", floatdiv(clan_participants_alive, Iter_Count(CWCLAN2)) * 100);
	foreach (new playerid: Player) {
		PlayerTextDrawSetString(playerid, CW_PTD[playerid][1], clan_health);
		SetPlayerProgressBarValue(playerid, CW_PBAR[playerid][1], floatdiv(clan_participants_alive, Iter_Count(CWCLAN2)) * 100);
	}

	if (!Iter_Count(CWCLAN1) && !Iter_Count(CWCLAN2)) {
		foreach (new i: Player) {
			TextDrawHideForPlayer(i, CWTD_0);
			TextDrawHideForPlayer(i, CWTD_1);
			TextDrawHideForPlayer(i, CWTD_2);
			TextDrawHideForPlayer(i, CWTD_3);
			PlayerTextDrawHide(i, CW_PTD[i][0]);
			PlayerTextDrawHide(i, CW_PTD[i][1]);
			HidePlayerProgressBar(i, CW_PBAR[i][0]);
			HidePlayerProgressBar(i, CW_PBAR[i][1]);
		}
	} else {
		foreach (new i: CWCLAN1) {
			TextDrawShowForPlayer(i, CWTD_0);
			TextDrawShowForPlayer(i, CWTD_1);
			TextDrawShowForPlayer(i, CWTD_2);
			TextDrawShowForPlayer(i, CWTD_3);
			PlayerTextDrawShow(i, CW_PTD[i][0]);
			PlayerTextDrawShow(i, CW_PTD[i][1]);
			ShowPlayerProgressBar(i, CW_PBAR[i][0]);
			ShowPlayerProgressBar(i, CW_PBAR[i][1]);
		}
		foreach (new i: CWCLAN2) {
			TextDrawShowForPlayer(i, CWTD_0);
			TextDrawShowForPlayer(i, CWTD_1);
			TextDrawShowForPlayer(i, CWTD_2);
			TextDrawShowForPlayer(i, CWTD_3);
			PlayerTextDrawShow(i, CW_PTD[i][0]);
			PlayerTextDrawShow(i, CW_PTD[i][1]);
			ShowPlayerProgressBar(i, CW_PBAR[i][0]);
			ShowPlayerProgressBar(i, CW_PBAR[i][1]);
		}
	}
	return true;
}

forward HideClanWarStandings();
public HideClanWarStandings() {
	TextDrawHideForAll(clanwar_0);
	TextDrawHideForAll(clanwar_1);
	TextDrawHideForAll(clanwar_2);
	TextDrawHideForAll(standing[0]);
	TextDrawHideForAll(standing[1]);
	TextDrawHideForAll(standing[2]);
	TextDrawHideForAll(standing[3]);
	TextDrawHideForAll(standing[4]);
	TextDrawHideForAll(standing[5]);
	TextDrawHideForAll(standing[6]);
	TextDrawHideForAll(standing[7]);
	return 1;
}

stock ShowClanWarStandings() {
	TextDrawShowForAll(clanwar_0);
	TextDrawShowForAll(clanwar_1);

	new string[95];
	format(string, sizeof(string), "%s ~r~VS ~w~%s", GetClanNameById(CWInfo[CWId1]), GetClanNameById(CWInfo[CWId2]));
	TextDrawSetString(clanwar_2, string);
	TextDrawShowForAll(clanwar_2);

	new standings = 0, standingstr[8][65];
	foreach (new i: CWCLAN1) {
		format(standingstr[standings], 65, "%s ~r~VS ~w~", PlayerInfo[i][PlayerName]);
		standings ++;
	}
	standings = 0;
	foreach (new i: CWCLAN2) {
		format(standingstr[standings], 65, "%s%s", standingstr[standings], PlayerInfo[i][PlayerName]);
		standings ++;
	}

	for (new i = 0; i < standings; i++) {
		TextDrawSetString(standing[i], standingstr[i]);
		TextDrawShowForAll(standing[i]);
	}

	SetTimer("HideClanWarStandings", 3000, false);

	return 1;
}

//RACE API

FetchFreeRaceSlot() {
	new raceid = -1;
	for (new i = 0; i < MAX_RACES - 1; i++) {
		if (!RaceStarted[i]) {
			raceid = i;
			break;
		}
	}
	return raceid;
}

ResetRaceSlot(raceid) {
	RaceStarted[raceid] = 0;
	RaceOpened[raceid] = 0;
	RaceTotalSpawns[raceid] = 0;
	RaceTotalCheckpoints[raceid] = 0;
	RaceInterior[raceid] = 0;
	RaceCar[raceid] = 0;
	KillTimer(RaceTimer[raceid]);
	for (new i = 0; i < MAX_CHECKPOINTS; i++) {
		RaceSpawns[raceid][i][0] = 0.0;
		RaceSpawns[raceid][i][1] = 0.0;
		RaceSpawns[raceid][i][2] = 0.0;
		RaceSpawns[raceid][i][3] = 0.0;
		RaceCheckpoints[raceid][i][0] = 0.0;
		RaceCheckpoints[raceid][i][1] = 0.0;
		RaceCheckpoints[raceid][i][2] = 0.0;
		RaceCheckpointType[raceid][i] = 0;
	}
	format(RaceName[raceid], 25, "");
	foreach (new i: Player) {
		if (pRaceId[i] == raceid) {
			pRaceId[i] = -1;
			new clear_pdata[E_PLAYER_ENUM];
			pEventInfo[i] = clear_pdata;
			if (Iter_Contains(ePlayers, i)) {
				Iter_SafeRemove(ePlayers, i, i);
			}
			DisablePlayerRaceCheckpoint(i);
			SpawnPlayer(i);
		}
	}
	return 1;
}

stock IsDefaultRace(raceid) {
	if (raceid == (MAX_RACES - 1)) return 1;
	return 0;
}

GenerateRaceSpawn(raceid, Float: X, Float: Y, Float: Z, Float: A) {
	if (!RaceStarted[raceid]) return 0;
	if (RaceTotalSpawns[raceid] == (MAX_CHECKPOINTS - 1)) return 0;
	RaceSpawns[raceid][RaceTotalSpawns[raceid]][0] = X;
	RaceSpawns[raceid][RaceTotalSpawns[raceid]][1] = Y;
	RaceSpawns[raceid][RaceTotalSpawns[raceid]][2] = Z;
	RaceSpawns[raceid][RaceTotalSpawns[raceid]][3] = A;
	RaceTotalSpawns[raceid] ++;
	return 1;
}

GenerateRaceCheckpoint(raceid, cptype, Float: X, Float: Y, Float: Z) {
	if (!RaceStarted[raceid]) return 0;
	if (RaceTotalCheckpoints[raceid] == (MAX_CHECKPOINTS - 1)) return 0;
	RaceCheckpointType[raceid][RaceTotalCheckpoints[raceid]] = cptype;
	RaceCheckpoints[raceid][RaceTotalCheckpoints[raceid]][0] = X;
	RaceCheckpoints[raceid][RaceTotalCheckpoints[raceid]][1] = Y;
	RaceCheckpoints[raceid][RaceTotalCheckpoints[raceid]][2] = Z;
	RaceTotalCheckpoints[raceid] ++;
	return 1;
}

//Event countdown
forward RaceCD(slot, cdvalue);
public RaceCD(slot, cdvalue) {
	if (RaceStarted[slot]) {
		if (cdvalue > 0) {
			new text[25];
			format(text, sizeof(text), "~r~- %dS LEFT -", cdvalue);
			foreach (new i: Player) {
				if (IsPlayerSpawned(i) && pRaceId[i] == slot) {
					GameTextForPlayer(i, text, 1000, 3);
					if (cdvalue == 15) {
						TogglePlayerControllable(i, false);
					}
				}
			}
			RaceTimer[slot] = SetTimerEx("RaceCD", 1000, false, "ii", slot, cdvalue - 1);
		} else {
			foreach (new i: Player) {
				if (IsPlayerSpawned(i) && pRaceId[i] == slot) {
					GameTextForPlayer(i, "~r~GO! ~g~GO! ~b~GO!", 1000, 3);
					PlayGoSound(i);
				}
			}
		}
	}
	return 1;
}

//The race menu displayed on using the /race command added below
//Does this need any improvements?
forward DisplayRacesList(playerid);
public DisplayRacesList(playerid) {
	if (cache_num_rows()) {
		inline RaceMenu(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (response) {
				new slot = FetchFreeRaceSlot();
				if (slot == -1 || !IsPlayerInMode(pid, MODE_BATTLEFIELD)) {
					SendClientMessage(playerid, X11_RED_2, "Abort. Failed to fetch a free race slot!");
					for (new i = 0; i < 20; i ++) {
						pRaceListItem[pid][i] = -1;
					}
					return 0;
				}
				ResetRaceSlot(slot);
				RaceStarted[slot] = 1;

				new raceId = pRaceListItem[pid][listitem];
				for (new i = 0; i < 20; i ++) {
					pRaceListItem[pid][i] = -1;
				}

				new Cache: RaceData, query[612];
				mysql_format(Database, query, sizeof(query), "SELECT * FROM `RacesData` WHERE `RaceId` = '%d' LIMIT 1", raceId);
				RaceData = mysql_query(Database, query);
				cache_get_value(0, "RaceName", RaceName[slot]);
				cache_get_value_int(0, "RaceVehicle", RaceCar[slot]);
				cache_get_value_int(0, "RaceInt", RaceInterior[slot]);
				//cache_get_value_int(0, "RaceWorld", EventInfo[E_WORLD]);
				cache_delete(RaceData);

				new Cache: RSQuery;
				mysql_format(Database, query, sizeof(query), "SELECT * FROM `RacesSpawnPoints` WHERE `RaceId` = '%d'", raceId);
				RSQuery = mysql_query(Database, query);
				for (new i = 0; i < cache_num_rows(); i++) {
					new Float: X, Float: Y, Float: Z, Float: A;
					cache_get_value_name_float(i, "RX", X);
					cache_get_value_name_float(i, "RY", Y);
					cache_get_value_name_float(i, "RZ", Z);
					cache_get_value_name_float(i, "RRot", A);
					GenerateRaceSpawn(slot, X, Y, Z, A);
				}
				cache_delete(RSQuery);

				new Cache: RCPQuery;
				mysql_format(Database, query, sizeof(query), "SELECT * FROM `RacesCheckpoints` WHERE `RaceId` = '%d'", raceId);
				RCPQuery = mysql_query(Database, query);
				for (new i = 0; i < cache_num_rows(); i++) {
					new cptype, Float: X, Float: Y, Float: Z;
					cache_get_value_name_float(i, "RX", X);
					cache_get_value_name_float(i, "RY", Y);
					cache_get_value_name_float(i, "RZ", Z);
					cache_get_value_name_int(i, "RType", cptype);
					GenerateRaceCheckpoint(slot, cptype, X, Y, Z);
				}
				cache_delete(RCPQuery);

				SetTimerEx("StartRace", 26000, false, "i", slot);
				RaceOpened[slot] = 1;

				KillTimer(RaceTimer[slot]);
				RaceTimer[slot] = SetTimerEx("RaceCD", 1000, false, "ii", slot, 25);

				new message[128];
				format(message, sizeof(message), "The race \"%s\" is starting in 25 seconds. Use /rjoin %d to participate!", RaceName[slot], slot);
				SendClientMessageToAll(X11_YELLOW1, message);

				format(message, sizeof(message), "/rjoin %d", slot);
				PC_EmulateCommand(pid, message);

				pCooldown[pid][41] = gettime() + 500;
			} else {
				for (new i = 0; i < 20; i ++) {
					pRaceListItem[pid][i] = -1;
				}
			}
		}

		new highestRaceId = 0;

		new string[1512];
		strcat(string, "Race Name\tRace Maker\tModel Id\tCreation Time\n");

		for (new i = 0; i < cache_num_rows(); i++) {
			new raceId, racename[24], racemaker[24], racevehicle, racedate;
			cache_get_value_int(i, "RaceId", raceId);
			cache_get_value(i, "RaceName", racename, sizeof(racename));
			cache_get_value(i, "RaceMaker", racemaker, sizeof(racemaker));
			cache_get_value_int(i, "RaceVehicle", racevehicle);
			cache_get_value_int(i, "RaceDate", racedate);

			pRaceListItem[playerid][highestRaceId] = raceId;
			highestRaceId ++;

			format(string, sizeof(string), "%s%s\t%s\t%d\t%s\n", string, racename, racemaker, racevehicle, GetWhen(racedate, gettime()));
		}
		Dialog_ShowCallback(playerid, using inline RaceMenu, DIALOG_STYLE_TABLIST_HEADERS, ""RED2"SvT - Races List", string, "Start Race", "X");
	}  else SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	return 1;
}

//Start a race event using the ordinary system
forward StartRace(slot);
public StartRace(slot) {
	if (RaceStarted[slot]) {
		RaceEndTime[slot] = gettime() + (60 * 7);
		RaceOpened[slot] = 0;
		new rcount = 0;
		foreach (new i: Player) {
			if (IsPlayerSpawned(i) && pRaceId[i] == slot) {
				rcount ++;
			}
		}
		if (rcount < 2) {
			ResetRaceSlot(slot);
			foreach (new i: Player) {
				if (IsPlayerSpawned(i) && pRaceId[i] == slot) {
					SetPlayerHealth(i, 0.0);
					SendGameMessage(i, X11_SERV_INFO, MSG_EVENT_CANCELLED);
				}
			}
			SendClientMessageToAll(X11_RED_2, "A race was cancelled for lacking at least 2 players!");
		} else {
			foreach (new i: Player) {
				if (IsPlayerSpawned(i) && pRaceId[i] == slot) {
					TogglePlayerControllable(i, true);
					SendClientMessage(i, X11_RED_2, "You have 7 minutes to finish this race.");
					PlayGoSound(i);
				}
			}
		}
	}
	return 1;
}

//Event race checkpoint check... PLAYER ENTERED A RACE CHECKPOINT, what to do?
RACES_OnPlayerEnterRaceCP(playerid) {
	if ((pRaceId[playerid] != -1 && RaceStarted[pRaceId[playerid]] && !RaceOpened[pRaceId[playerid]]) ||
	(Iter_Contains(ePlayers, playerid) && EventInfo[E_STARTED] && EventInfo[E_TYPE] == 2)) {
		if (pEventInfo[playerid][P_CP] >= RaceTotalCheckpoints[pRaceId[playerid]]) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_40x);

			new top[MAX_PLAYERS][2], topcount;

			foreach(new p: Player) {
				if (pRaceId[p] != -1 && pRaceId[p] == pRaceId[playerid]) {
					top[p][0] = pEventInfo[p][P_CP];
					top[p][1] = p;

					topcount ++;
				}
			}

			QuickSort_Pair(top, true, 0, topcount + 1);

			new time = gettime() - pEventInfo[playerid][P_RACETIME], resetslot = pRaceId[playerid];

			for (new i = 0; i < topcount + 1; i++) {
				if (top[i][0]) {
					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_2x, i + 1, PlayerInfo[top[i][1]][PlayerName], top[i][1], time, GetPlayerVehicleSpeed(top[i][1]), top[i][0], RaceTotalCheckpoints[resetslot]);
					SuccessAlert(top[i][1]);

					PlayerInfo[top[i][1]][sEvents] ++;
					PlayerInfo[top[i][1]][sRaces] ++;
					PlayerInfo[top[i][1]][pRacesWon] ++;
					PlayerInfo[top[i][1]][pEventsWon] ++;

					DisablePlayerRaceCheckpoint(top[i][1]);
					new clear_pdata[E_PLAYER_ENUM];
					pEventInfo[top[i][1]] = clear_pdata;
					SetPlayerHealth(top[i][1], 0.0);

					if (PlayerInfo[top[i][1]][pCar] != -1) {
						DestroyVehicle(PlayerInfo[top[i][1]][pCar]);
						PlayerInfo[top[i][1]][pCar] = -1;
					}
					pRaceId[top[i][1]] = -1;
				}
			}

			ResetRaceSlot(resetslot);
			if (resetslot == (MAX_RACES-1)) {
				new clear_data[E_DATA_ENUM];
				EventInfo = clear_data;
				EventInfo[E_OPENED] = 0;
				EventInfo[E_STARTED] = 0;
				EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
				EventInfo[E_TYPE] = -1;
				Iter_Clear(ePlayers);
			}
		}
		else if (pEventInfo[playerid][P_CP] + 1 != RaceTotalCheckpoints[pRaceId[playerid]])
		{
			if (RaceCheckpointType[pRaceId[playerid]][pEventInfo[playerid][P_CP]] == 0)
			{
				SetPlayerRaceCheckpoint(playerid, 0, RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][0], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][1], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][2],
				RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP] + 1][0], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP] + 1][1], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP] + 1][2], 10);
			}
			else
			{
				SetPlayerRaceCheckpoint(playerid, 3, RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][0], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][1], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][2],
				RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP] + 1][0], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP] + 1][1], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP] + 1][2], 10);
			}

			pEventInfo[playerid][P_CP]++;

			new time = gettime() - pEventInfo[playerid][P_RACETIME];
			new string[128];
			format(string, sizeof(string), "~r~Speed:~w~ %d KM/H ~r~Laps:~w~ %d/%d ~r~Seconds:~w~ %d", GetPlayerVehicleSpeed(playerid), pEventInfo[playerid][P_CP], RaceTotalCheckpoints[pRaceId[playerid]], time);
			NotifyPlayer(playerid, string);
			format(string, sizeof(string), "- Time left: %d seconds -", RaceEndTime[pRaceId[playerid]] - gettime());
			SendClientMessage(playerid, X11_PURPLE, string);
		}
		else if (pEventInfo[playerid][P_CP] + 1 == RaceTotalCheckpoints[pRaceId[playerid]])
		{
			if (RaceCheckpointType[pRaceId[playerid]][pEventInfo[playerid][P_CP]] == 0)
			{
				SetPlayerRaceCheckpoint(playerid, 1, RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][0], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][1], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][2], 0.0, 0.0, 0.0, 15);
			}
			else
			{
				SetPlayerRaceCheckpoint(playerid, 4, RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][0], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][1], RaceCheckpoints[pRaceId[playerid]][pEventInfo[playerid][P_CP]][2], 0.0, 0.0, 0.0, 15);
			}

			pEventInfo[playerid][P_CP]++;

			new time = gettime() - pEventInfo[playerid][P_RACETIME];
			new string[128];
			format(string, sizeof(string), "~r~Speed:~w~ %d KM/H ~r~Laps:~w~ %d/%d ~r~Seconds:~w~ %d", GetPlayerVehicleSpeed(playerid), pEventInfo[playerid][P_CP], RaceTotalCheckpoints[pRaceId[playerid]], time);
			NotifyPlayer(playerid, string);
			format(string, sizeof(string), "- Time left: %d seconds -", RaceEndTime[pRaceId[playerid]] - gettime());
			SendClientMessage(playerid, X11_PURPLE, string);
		}
	}
	return 1;
}

//PM System

forward SendPM(playerid, ID, const str2[128]);
public SendPM(playerid, ID, const str2[128]) {
	if (cache_num_rows()) {
		if (!ComparePrivileges(playerid, CMD_MEMBER)) {
			SendGameMessage(playerid, X11_SERV_INFO, MSG_BLOCKED_PLAYER);
		}
	}

	ForwardPlayerMessageToTarget(playerid, ID, str2);

	if (pLastMessager[ID] == INVALID_PLAYER_ID) {
		SendGameMessage(ID, X11_SERV_INFO, MSG_REPLY_PM);
	}

	pLastMessager[ID] = playerid;
	pLastMessager[playerid] = ID;

	return 1;
}

forward BlockPlayer(playerid, targetid);
public BlockPlayer(playerid, targetid) {
	if (!cache_num_rows()) {
		new query[150];
		mysql_format(Database, query, sizeof(query), "INSERT INTO `IgnoreList` (`BlockerId`, `BlockedId`) VALUES('%d', '%d')", PlayerInfo[playerid][pAccountId], PlayerInfo[targetid][pAccountId]);
		mysql_tquery(Database, query);

		SendGameMessage(playerid, X11_SERV_INFO, MSG_BLOCK_PLAYER, PlayerInfo[targetid][PlayerName]);
	} else {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_BLOCKED_ALREADY);
	}
	return 1;
}

forward UnblockPlayer(playerid, targetid);
public UnblockPlayer(playerid, targetid) {
	if (cache_num_rows()) {
		new query[150];
		mysql_format(Database, query, sizeof(query), "DELETE FROM `IgnoreList` WHERE `BlockerId` = '%d' AND `BlockedId` = '%d' LIMIT 1", PlayerInfo[playerid][pAccountId], PlayerInfo[targetid][pAccountId]);
		mysql_tquery(Database, query);

		SendGameMessage(playerid, X11_SERV_INFO, MSG_UNBLOCK_PLAYER, PlayerInfo[targetid][PlayerName]);
	} else {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_UNBLOCKED_ALREADY);
	}
	return 1;
}

//Team Waypoint
forward DestroyTeamWaypoint(team);
public DestroyTeamWaypoint(team) {
	foreach (new i: Player) {
		if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == team) {
			if (IsValidDynamicMapIcon(pWaypoint[i])) {
				DestroyDynamicMapIcon(pWaypoint[i]);
				SendClientMessage(i, X11_WINE, "Your team's waypoint has expired.");
			}
		}
	}
	Team_SetWaypoint(team, 0);
	return 1;
}

//Fix Glitch?

forward FixGlitch(playerid);
public FixGlitch(playerid) {
	TogglePlayerControllable(playerid, true);
	return 1;
}

//Crates

forward DestroyCrate(crateid);
public DestroyCrate(crateid) {
	DestroyDynamicObject(crateid);
	return 1;
}

forward OpenCrate(playerid);
public OpenCrate(playerid) {
	new random_obj = random(4);
	PlayerInfo[playerid][pCrates] --;
	PlayerInfo[playerid][pCratesOpened] ++;
	switch (random_obj) {
		case 0: {
			new random_cash = random(10000) + 500;
			GivePlayerCash(playerid, random_cash);

			new string[9];
			format(string, sizeof(string), "%s", formatInt(random_cash));
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_OPEN, string);
		}
		case 1: {
			new random_score = random(10) + 1;
			GivePlayerScore(playerid, random_score);

			new string[9];
			format(string, sizeof(string), "%d score", random_score);
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_OPEN, string);
		}
		case 2: {
			new random_weap = random(3);
			switch (random_weap) {
				case 0: {
					GivePlayerWeapon(playerid, 24, 50);
					SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_OPEN, "a desert eagle");
				}
				case 1: {
					GivePlayerWeapon(playerid, WEAPON_TEC9, 100);
					SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_OPEN, "a Tec-9");
				}
				case 2: {
					GivePlayerWeapon(playerid, WEAPON_SAWEDOFF, 100);
					SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_OPEN, "a sawn-off shotgun");
				}
			}
		}
		case 3: {
			new random_item = random(MAX_ITEMS);
			Items_AddPlayer(playerid, random_item, 1);
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_OPEN, Items_GetName(random_item));
		}
	}
	return 1;
}

/*Dogfighting Match facts, playing with database*/
forward DFMatchesPlayed(playerid);
public DFMatchesPlayed(playerid) {
	new Matches;
	cache_get_value_int(0, "Matches", Matches);
	if (!Matches) return SendClientMessage(playerid, X11_WINE, "Couldn't find any interesting dogfight match facts for you. Start dogfighting now!");

	new string[72];
	format(string, sizeof(string), "You overall played %d dogfight matches", Matches);
	SendClientMessage(playerid, X11_CYAN, string);

	//Matches Won
	new get_facts[256];
	mysql_format(Database, get_facts, sizeof(get_facts), "SELECT COUNT(*) AS Res FROM `Dogfights` WHERE `WinnerID` = '%d'",
	PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, get_facts, "DFMatchesWon", "i", playerid);

	//Most Lost Against
	mysql_format(Database, get_facts, sizeof(get_facts), "SELECT WinnerID, COUNT(WinnerID) AS WinnerCount \
	FROM `Dogfights` WHERE `FirstOppID` = '%d' GROUP BY WinnerID ORDER BY COUNT(WinnerID) DESC LIMIT 1",
	PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, get_facts, "DFMostLostAgainst", "i", playerid);

	return 1;
}

forward DFMostLostAgainst(playerid);
public DFMostLostAgainst(playerid) {
	new WinnerCount;
	cache_get_value_int(0, "WinnerCount", WinnerCount);
	if (!WinnerCount) return 1;

	new id;
	cache_get_value_int(0, "WinnerID", id);

	new get_facts_name[256];
	mysql_format(Database, get_facts_name, sizeof(get_facts_name), "SELECT `Username` FROM `Players` WHERE `ID` = '%d' LIMIT 1", id);
	mysql_tquery(Database, get_facts_name, "ReturnDFMLAName", "i", playerid);
	return 1;
}

forward ReturnDFMLAName(playerid);
public ReturnDFMLAName(playerid) {
	new user[MAX_PLAYER_NAME];
	cache_get_value(0, "Username", user, MAX_PLAYER_NAME);

	new string[128];
	format(string, sizeof(string), "You lost against %s most of the time", user);
	SendClientMessage(playerid, X11_CYAN, string);
	return 1;
}

forward DFMatchesWon(playerid);
public DFMatchesWon(playerid) {
	new Res;
	cache_get_value_int(0, "Res", Res);
	if (!Res) return 1;

	new string[72];
	format(string, sizeof(string), "You won %d matches", Res);
	SendClientMessage(playerid, X11_CYAN, string);

	//Most Matched
	new get_facts[370];
	mysql_format(Database, get_facts, sizeof(get_facts), "SELECT FirstOppID, COUNT(FirstOppID) AS OppCount \
	FROM `Dogfights` WHERE `WinnerID` = '%d' GROUP BY FirstOppID ORDER BY COUNT(FirstOppID) DESC LIMIT 1",
	PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, get_facts, "DFMostMatched", "i", playerid);

	//Most used VID
	mysql_format(Database, get_facts, sizeof(get_facts), "SELECT DogfightVID AS plane, COUNT(DogfightVID) AS MostDVID \
	FROM `Dogfights` WHERE `WinnerID` = '%d' GROUP BY DogfightVID ORDER BY COUNT(DogfightVID) DESC LIMIT 1",
	PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, get_facts, "DFMostVehicleUsed", "i", playerid);

	//AVG Stats

	mysql_format(Database, get_facts, sizeof(get_facts), "SELECT AVG(SecondOppVHP) AS GetAVGVHP, AVG(DogfightTL) AS GetAVGTL \
	FROM `Dogfights` WHERE `WinnerID` = '%d'",
	PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, get_facts, "DFAvg", "i", playerid);
	return 1;
}

forward DFMostVehicleUsed(playerid);
public DFMostVehicleUsed(playerid) {
	new count_vids;
	cache_get_value_int(0, "MostDVID", count_vids);
	if (!count_vids) return 1;

	new planeid;
	cache_get_value_int(0, "plane", planeid);

	new string[128];
	format(string, sizeof(string), "Most vehicle used in dogfights: %s", VehicleNames[400-planeid]);
	SendClientMessage(playerid, X11_CYAN, string);
	return 1;
}

forward DFAvg(playerid);
public DFAvg(playerid) {
	new Float: avg1, Float: avg2;
	cache_get_value_name_float(0, "GetAVGVHP", avg1);
	cache_get_value_name_float(0, "GetAVGTL", avg2);

	new string[128];
	format(string, sizeof(string), "Your average vehicle health: %0.2f", avg1);
	SendClientMessage(playerid, X11_CYAN, string);
	format(string, sizeof(string), "Your average winning time (as winner): %0.2f", avg2);
	SendClientMessage(playerid, X11_CYAN, string);
	return 1;
}

forward DFMostMatched(playerid);
public DFMostMatched(playerid) {
	new OppCount;
	cache_get_value_int(0, "OppCount", OppCount);
	if (!OppCount) return 1;

	new id;
	cache_get_value_int(0, "FirstOppID", id);

	new get_facts_name[256];
	mysql_format(Database, get_facts_name, sizeof(get_facts_name), "SELECT `Username` FROM `Players` WHERE `ID` = '%d' LIMIT 1", id);
	mysql_tquery(Database, get_facts_name, "ReturnDFMMName", "i", playerid);
	return 1;
}

forward ReturnDFMMName(playerid);
public ReturnDFMMName(playerid) {
	new user[MAX_PLAYER_NAME];
	cache_get_value(0, "Username", user, MAX_PLAYER_NAME);

	new string[128];
	format(string, sizeof(string), "You won against %s most of the time", user);
	SendClientMessage(playerid, X11_CYAN, string);
	return 1;
}

//Dogfight

forward InitiateDogfight(playerid);
public InitiateDogfight(playerid) {
	if (pDogfightCD[playerid] > 1) {
		new cd[5];
		format(cd, sizeof(cd), "~g~%d", pDogfightCD[playerid] - 1);
		GameTextForPlayer(playerid, cd, 1000, 3);
		pDogfightCD[playerid] --;
	} else {
		pDogfightTime[playerid] = gettime() + 1000;
		KillTimer(pDogfightTimer[playerid]);
		GameTextForPlayer(playerid, "~g~GO!", 1000, 3);
		PlayGoSound(playerid);
		TogglePlayerControllable(playerid, true);
		pDogfightCD[playerid] = 0;
		SetPlayerMarkerVisibility(playerid, 0xFF);
	}
	return 1;
}

CreateDFPlane(playerid, Float: x, Float: y, Float: z, Float: angle, world) {
	if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
	PlayerInfo[playerid][pCar] = -1;
	new vehicleid = CreateVehicle(pDogfightModel[playerid], x, y, z, angle, random(104), random(103), -1);
	SetVehicleVirtualWorld(vehicleid, world);
	LinkVehicleToInterior(vehicleid, 0);
	SetVehiclePos(vehicleid, x, y, z);
	SetVehicleZAngle(vehicleid, angle);
	pVehId[playerid] = PlayerInfo[playerid][pCar] = vehicleid;
	PutPlayerInVehicle(playerid, vehicleid, 0);
	new string[70];
	format(string, sizeof(string), "~g~Your %s was set up!", VehicleNames[pDogfightModel[playerid]-400]);
	NotifyPlayer(playerid, string);
	return 1;
}

SetupDogfightMode(playerid) {
	EndProtection(playerid);
	PlayReadySound(playerid);
	pDogfightCD[playerid] = 4;
	pDogfightTimer[playerid] = SetTimerEx("InitiateDogfight", 1000, true, "i", playerid);
	pDogfightTime[playerid] = gettime() + 1000;
	SendClientMessage(playerid, X11_GREEN, "Dogfight accepted!! Go on! You have 1000 seconds to take down the enemy.");
	TogglePlayerControllable(playerid, false);
	return 1;
}

DogfightCheckStatus(playerid) {
	if (pDogfightTarget[playerid] != INVALID_PLAYER_ID) {
		new string[128];
		format(string, sizeof(string), "%s[%d] lost against %s[%d] in a dogfight for %s (plane model: %s).", PlayerInfo[playerid][PlayerName],
		playerid, PlayerInfo[pDogfightTarget[playerid]][PlayerName], pDogfightTarget[playerid], formatInt(pDogfightBet[playerid]), VehicleNames[pDogfightModel[playerid]-400]);
		SendClientMessageToAll(X11_CYAN, string);

		new query[456], Float: VHP;
		GetVehicleHealth(GetPlayerVehicleID(pDogfightTarget[playerid]), VHP);
		mysql_format(Database, query, sizeof(query), "INSERT INTO `Dogfights` (`FirstOppID`, `WinnerID`, `SecondOppVHP`, `DogfightVID`, `DogfightTL`) \
		VALUES ('%d', '%d', '%0.4f', '%d', '%d')", PlayerInfo[playerid][pAccountId], PlayerInfo[pDogfightTarget[playerid]][pAccountId],
			VHP, pDogfightModel[playerid], 1000 - (pDogfightTime[playerid] - gettime()));
		mysql_tquery(Database, query);

		format(string, sizeof(string), "||MATCH FACTS|| "RED"Winner's Vehicle Health: %0.4f | Time Taken to Win: %d seconds", VHP, 1000 - (pDogfightTime[playerid] - gettime()));
		SendClientMessageToAll(X11_YELLOW, string);

		SendClientMessage(pDogfightModel[playerid], X11_GREEN, "Use /matchfacts to know how cool you are in dogfights!");

		GivePlayerCash(playerid, -pDogfightBet[playerid]);
		GivePlayerCash(pDogfightTarget[playerid], pDogfightBet[playerid]);
		GameTextForPlayer(pDogfightTarget[playerid], "~g~WINNER!", 3000, 3);
		PlaySuccessSound(pDogfightTarget[playerid]);
		GameTextForPlayer(playerid, "~r~LOSER!", 3000, 3);
		SetPlayerVirtualWorld(playerid, 0);
		SetPlayerVirtualWorld(pDogfightTarget[playerid], 0);
		new Float: X, Float: Y, Float: Z;
		GetPlayerPos(playerid, X, Y, Z);
		SetPlayerPos(playerid, X, Y, Z + 200.0);
		GivePlayerWeapon(playerid, 46, 1);
		GetPlayerPos(pDogfightTarget[playerid], X, Y, Z);
		SetPlayerPos(pDogfightTarget[playerid], X, Y, Z + 200.0);
		GivePlayerWeapon(pDogfightTarget[playerid], 46, 1);
		CarDeleter(PlayerInfo[playerid][pCar]);
		CarDeleter(PlayerInfo[pDogfightTarget[playerid]][pCar]);
		UpdateLabelText(playerid);
		UpdateLabelText(pDogfightTarget[playerid]);
		pDogfightTarget[pDogfightTarget[playerid]] = INVALID_PLAYER_ID;
		pDogfightTarget[playerid] = INVALID_PLAYER_ID;
	}
	return 1;
}

forward SpawnBMX(playerid);
public SpawnBMX(playerid) {
	CarSpawner(playerid, 481);
	return 1;
}

//#include "players/admin/clan.pwn"
//#include "players/admin/event.pwn"
//#include "players/admin/discord.pwn"
//#include "players/admin/personnel.pwn"
//#include "players/admin/logs.pwn"
//
/*
		ADMIN MODULE - C A L L B A C K S!
*/
//

forward OfflineBan(playerid, nickname[], days, reason[]);
forward ProceedUnbanPlayer();
forward UnbanPlayer(playerid, nickname[]);
forward CheckBansData(playerid);
forward IPBanCheck(playerid);
forward Unfreeze(targetid);
forward IsForbiddenName(playerid, nick[]);
forward LoadForbiddenWords();
forward LoadForbiddenNames();

public OfflineBan(playerid, nickname[], days, reason[]) {
	new query[550], IP[MAX_IP_LEN];

	if (cache_num_rows() > 0) {
		new rank;
		cache_get_value_int(0, "AdminLevel", rank);
		if (rank == MAX_ADMIN_RANKS
				|| (rank >= PlayerInfo[playerid][pAdminLevel] && !ComparePrivileges(playerid, CMD_OWNER))) return SendGameMessage(playerid, X11_SERV_ERR, MSG_ADMIN_FAILED_ACTION);
		if ((days > 30) || (days <= 0 && days != -1)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_ADMIN_BAN_DAYS);

		new converttime;

		if (days != -1)
			converttime = gettime() + (86400 * days);
		else
			converttime = -1;

		new pID, pName[MAX_PLAYER_NAME];

		cache_get_value_int(0, "ID", pID);
		cache_get_value(0, "Username", pName, MAX_PLAYER_NAME);
		cache_get_value(0, "IP", IP, MAX_IP_LEN);

		mysql_format(Database, query, sizeof (query), "UPDATE `Players` SET `IsBanned` = '1', `BannedTimes`=`BannedTimes`+1 WHERE `Username` = '%e' LIMIT 1", nickname);
		mysql_tquery(Database, query);

		SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s unbanned %s in offline mode for %d days for %s.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName], pName, days, reason);

		mysql_format(Database, query, sizeof(query), "INSERT INTO `BansData` (`BannedName`, `AdminName`, `BanReason`, `ExpiryDate`, `BanDate`) VALUES ('%e', '%e', '%e', '%d', NOW())", pName, PlayerInfo[playerid][PlayerName], reason, converttime);
		mysql_tquery(Database, query);

		mysql_format(Database, query, sizeof(query), "INSERT INTO `BansHistoryData` (`BannedName`, `AdminName`, `BanReason`, `ExpiryDate`, `BanDate`) VALUES ('%e', '%e', '%e', '%d', NOW())", pName, PlayerInfo[playerid][PlayerName], reason, converttime);
		mysql_tquery(Database, query);
	} else return SendClientMessage(playerid, X11_RED2, "This name does not exist in the database.");
	return 1;
}

public ProceedUnbanPlayer()
{
	if (cache_num_rows())
	{
		new IP[MAX_IP_LEN];
		cache_get_value(0, "IP", IP);
		UnBlockIpAddress(IP);
	}
	return 1;
}

public UnbanPlayer(playerid, nickname[]) {
	new query[MEDIUM_STRING_LEN];

	if (cache_num_rows() > 0) {
		mysql_format(Database, query, sizeof(query), "DELETE FROM `BansData` WHERE `BannedName` = '%e' LIMIT 1", nickname);
		mysql_tquery(Database, query);

		mysql_format(Database, query, sizeof(query), "SELECT `IP` FROM `Players` WHERE `Username` LIKE '%e' LIMIT 1", nickname);
		mysql_tquery(Database, query, "ProceedUnbanPlayer");

		mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `IsBanned` = '0' WHERE `Username` LIKE '%e' LIMIT 1", nickname);
		mysql_tquery(Database, query);

		SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s unbanned %s in offline mode.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName], nickname);

		mysql_format(Database, query, sizeof(query), "INSERT INTO `Punishments` (PunishedPlayer, Punisher, Action, ActionReason, PunishmentTime, ActionDate) \
			VALUES ('%e', '%e', 'Unban', '', '', '%d')", nickname, PlayerInfo[playerid][PlayerName], gettime());
		mysql_tquery(Database, query);
	}  else SendGameMessage(playerid, X11_SERV_ERR, MSG_ADMIN_FAILED_ACTION);
	return 1;
}

public CheckBansData(playerid) {
	if (cache_num_rows() > 0) {
		new query[400], days;
		cache_get_value_int(0, "ExpiryDate", days);

		if (days != -1) {
			if (gettime() > days) {
				if (pVerified[playerid]) {
					mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `IsBanned` = '0' WHERE `Username` = '%e' LIMIT 1", PlayerInfo[playerid][PlayerName]);
					mysql_tquery(Database, query);
				}

				mysql_format(Database, query, sizeof(query), "DELETE FROM `BansData` WHERE `BannedName` = '%e' LIMIT 1", PlayerInfo[playerid][PlayerName]);
				mysql_tquery(Database, query);

				SendGameMessage(playerid, X11_SERV_INFO, MSG_BAN_EXPIRED);
			} else {
				mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `IsBanned` = '1' WHERE `Username` = '%e' LIMIT 1", PlayerInfo[playerid][PlayerName]);
				mysql_tquery(Database, query);

				SendGameMessage(playerid, X11_SERV_INFO, MSG_BANNED_PLAYER);
				SetTimerEx("ApplyBan", 500, false, "i", playerid);

				new AdminName[MAX_PLAYER_NAME], Reason[35], Days, Date[24];

				cache_get_value(0, "AdminName", AdminName, sizeof(AdminName));
				cache_get_value(0, "BanReason", Reason, sizeof(Reason));
				cache_get_value_int(0, "ExpiryDate", Days);
				cache_get_value(0, "BanDate", Date, sizeof(Date));

				new dialog[290], sub[60];

				format(sub, sizeof(sub), ""RED2"Nickname: "IVORY"%s\n", PlayerInfo[playerid][PlayerName]);
				strcat(dialog, sub);

				format(sub, sizeof(sub), ""RED2"Banning Administrator: "IVORY"%s\n", AdminName);
				strcat(dialog, sub);

				format(sub, sizeof(sub), ""RED2"Banned for "IVORY"%s\n", Reason);
				strcat(dialog, sub);

				new seconds = Days - gettime(), d, h, m, s;

				d = (seconds / 86400);
				h = (seconds / 60 / 60 % 60);
				m = (seconds / 60 % 60);
				s = (seconds % 60);

				format(sub, sizeof(sub), ""RED2"Expiring In "IVORY"%d dy, %d hr, %d min, %d sec\n", d, h, m, s);
				strcat(dialog, sub);

				format(sub, sizeof(sub), ""RED2"Issued "IVORY"%s", Date);
				strcat(dialog, sub);

				Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, ""RED2"You are banned", dialog, "X", "");
			}
		} else {
			SendGameMessage(playerid, X11_SERV_INFO, MSG_PERMANENT_BAN);
			SetTimerEx("ApplyBan", 500, false, "i", playerid);
		}
	}
	else {
		new query[MEDIUM_STRING_LEN];
		mysql_format(Database, query, sizeof(query), "SELECT `IP`, `GPCI` FROM `Players` WHERE `IsBanned` = '1' AND `Username` LIKE '%e' AND `IP` LIKE '%e' ORDER BY `ID` DESC LIMIT 1", PlayerInfo[playerid][PlayerName], PlayerInfo[playerid][pIP]);
		mysql_tquery(Database, query, "IPBanCheck", "i", playerid);
	}
	return 1;
}

public IPBanCheck(playerid) {
	if (cache_num_rows() > 0) {
		SetTimerEx("ApplyBan", 1000, false, "i", playerid);
	}
	return 1;
}

public Unfreeze(targetid) {
	TogglePlayerControllable(targetid, true);
	KillTimer(FreezeTimer[targetid]);
	PlayerInfo[targetid][pFrozen] = 0;
	return 1;
}

public IsForbiddenName(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new part_name[MAX_PLAYER_NAME];

		for (new i, j = cache_num_rows(); i != j; i++) {
			cache_get_value(i, "Text", part_name, sizeof(part_name));
			if (strfind(PlayerInfo[playerid][PlayerName], part_name, true) != -1) {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_144x, part_name);
				SetTimerEx("DelayKick", 500, false, "i", playerid);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_34x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
			}
		}
	}
	return 1;
}

public LoadForbiddenWords() {
	if (cache_num_rows() > 0) {
		new words;
		for (new i, j = cache_num_rows(); i != j; i++) {
			if (words < MAX_FORBIDS) {
				new word[25];
				cache_get_value(i, "Text", word, 25);
				format(ForbiddenWords[words], 25, word);
			}

			words ++;
		}
	}
	return 1;
}

public LoadForbiddenNames() {
	if (cache_num_rows() > 0) {
		new names;
		for (new i, j = cache_num_rows(); i != j; i++) {
			if (names < MAX_FORBIDS) {
				new name[25];
				cache_get_value(i, "Text", name, 25);
				format(ForbiddenNames[names], 25, name);
			}
			names ++;
		}
	}
	return 1;
}

//
/*
		F U N C T I O N S!
*/
//

//Anonymize Account
AnonymizeAccount(const account_name[MAX_PLAYER_NAME])
{
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `IP` = NULL, `Password` = NULL, `GPCI` = NULL, `ClanId` = '-1', `ClanRank` = '0',\
		`SupportKey` = '0', `AdminLevel` = '0' WHERE `Username` LIKE '%e' LIMIT 1", account_name);
	mysql_tquery(Database, query);

	new anonymize_name[MAX_PLAYER_NAME];
	randomString(anonymize_name, 10);
	format(anonymize_name, sizeof(anonymize_name), "Deleted #%s", anonymize_name);
	RenameAccount(account_name, anonymize_name);
	return 1;
}

//Rename all account names (Unfinished)
RenameAccount(const old_name[MAX_PLAYER_NAME], const new_name[MAX_PLAYER_NAME])
{
	new query[MEDIUM_STRING_LEN];
	//Main account name
	mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `Username` = '%e' WHERE `Username` = '%e' LIMIT 1", new_name, old_name);
	mysql_tquery(Database, query);

	//Logs
	mysql_format(Database, query, sizeof(query), "UPDATE `ClanLog` SET `Member` = '%e' WHERE `Member` = '%e'", new_name, old_name);
	mysql_tquery(Database, query);

	//Logs
	mysql_format(Database, query, sizeof(query), "UPDATE `Punishments` SET `PunishedPlayer` = '%e' WHERE `PunishedPlayer` = '%e'", new_name, old_name);
	mysql_tquery(Database, query);

	mysql_format(Database, query, sizeof(query), "UPDATE `Punishments` SET `Punisher` = '%e' WHERE `Punisher` = '%e'", new_name, old_name);
	mysql_tquery(Database, query);

	//Bans
	mysql_format(Database, query, sizeof(query), "UPDATE `BansData` SET `BannedName` = '%e' WHERE `BannedName` = '%e' LIMIT 1", new_name, old_name);
	mysql_tquery(Database, query);

	//Bans
	mysql_format(Database, query, sizeof(query), "UPDATE `BansData` SET `AdminName` = '%e' WHERE `AdminName` = '%e'", new_name, old_name);
	mysql_tquery(Database, query);
	return 1;
}

_Get_Role(playerid) {
	new string[25] = "N/A";
	if (!PlayerInfo[playerid][pAdminLevel] && !ComparePrivileges(playerid, CMD_OWNER)) return string;
	if (ComparePrivileges(playerid, CMD_OWNER)) {
		string = "Owner";
		return string;
	}
	format(string, sizeof(string), _staff_roles[(PlayerInfo[playerid][pAdminLevel] - 1)]);
	return string;
}

///////

RandomSpectate(playerid) {
	new count = Iter_Count(Player);
	if (count < 2) {
		return StopSpectate(playerid);
	}

	new x = Iter_Random(Player);

	if (IsPlayerSpawned(x)) {
		StartSpectate(playerid, x);
	} else StopSpectate(playerid);
	return 1;
}

StartSpectate(playerid, specplayerid) {
	if (!ComparePrivileges(playerid, CMD_MEMBER)) return 0;
	SetPlayerInterior(playerid, GetPlayerInterior(specplayerid));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(specplayerid));

	foreach (new x: Player) {
		if (GetPlayerState(x) == PLAYER_STATE_SPECTATING && PlayerInfo[x][pSpecId] == playerid) {
			RandomSpectate(x);
		}
	}

	TogglePlayerSpectating(playerid, true);

	if (IsPlayerInAnyVehicle(specplayerid)) {
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(specplayerid));
		PlayerInfo[playerid][pSpecId] = specplayerid;
		PlayerInfo[playerid][pSpecMode] = ADMIN_SPEC_TYPE_VEHICLE;
	} else {
		PlayerSpectatePlayer(playerid, specplayerid);
		PlayerInfo[playerid][pSpecId] = specplayerid;
		PlayerInfo[playerid][pSpecMode] = ADMIN_SPEC_TYPE_PLAYER;
	}

	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_155x);

	for (new i = 0; i < sizeof(aSpecTD); i++) {
		TextDrawShowForPlayer(playerid, aSpecTD[i]);
	}

	new str[SMALL_STRING_LEN];

	format(str, sizeof(str), "%s[%d]",
		PlayerInfo[specplayerid][PlayerName], specplayerid);

	PlayerTextDrawSetString(playerid, aSpecPTD[playerid][1], str);

	format(str, sizeof(str), "%s (%d)~n~Speed: %0.2f KM/H",
		ReturnWeaponName(GetPlayerWeapon(specplayerid)),
		 GetPlayerAmmo(specplayerid), GetPlayerSpeed(specplayerid));

	PlayerTextDrawSetString(playerid, aSpecPTD[playerid][2], str);

	PlayerTextDrawSetPreviewModel(playerid, aSpecPTD[playerid][0], GetPlayerSkin(specplayerid));

	PlayerTextDrawShow(playerid, aSpecPTD[playerid][0]);
	PlayerTextDrawShow(playerid, aSpecPTD[playerid][1]);
	PlayerTextDrawShow(playerid, aSpecPTD[playerid][2]);

	SelectTextDraw(playerid, X11_DEEPPINK);
	UpdatePlayerHUD(playerid);
	return 1;
}

StopSpectate(playerid) {
	CancelSelectTextDraw(playerid);
	TogglePlayerSpectating(playerid, false);

	PlayerInfo[playerid][pSpecId] = INVALID_PLAYER_ID;
	PlayerInfo[playerid][pSpecMode] = ADMIN_SPEC_TYPE_NONE;

	for (new i = 0; i < sizeof(aSpecTD); i++) {
		TextDrawHideForPlayer(playerid, aSpecTD[i]);
	}

	PlayerTextDrawHide(playerid, aSpecPTD[playerid][0]);
	PlayerTextDrawHide(playerid, aSpecPTD[playerid][1]);
	PlayerTextDrawHide(playerid, aSpecPTD[playerid][2]);
	return 1;
}

//Taken from vlang - Message

stock _SendGameMessage(@PlayerSet:players, const VlangCol, const Identifier[128], GLOBAL_TAG_TYPES:...) {
    new message[256];
    strcat(message, Identifier);
    format(message, sizeof(message), message, ___(3));
    foreach (new playerid: PS(players)) {
		SendClientMessage(playerid, VlangCol, message);
	}	
    return 1;
}

//The Admin panel

va_EmulateCommand(playerid, const cmdtext[128], va_args<>) {
	new emulated_cmd[256];
	va_format(emulated_cmd, sizeof(emulated_cmd), cmdtext, va_start<2>);
	return PC_EmulateCommand(playerid, emulated_cmd);
}

AdminPanel(playerid, clickedplayerid) {
	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return SendClientMessage(playerid, X11_RED2, "This feature is limited to managers only.");

	inline AdminManageMute(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new reason[128];
		if (sscanf(inputtext, "s[128]", reason)) return SendClientMessage(playerid, X11_RED2, "That doesn't seem like a nice reason.");
		va_EmulateCommand(pid, "/mute %d %s", clickedplayerid, reason);
	}

	inline AdminManageFreeze(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new minutes, reason[25];
		if (sscanf(inputtext, "is[25]", minutes, reason)) return SendClientMessage(playerid, X11_RED2, "Incorrect arguments specified.");
		va_EmulateCommand(pid, "/freeze %d %d %s", clickedplayerid, minutes, reason);
	}

	inline AdminManageJail(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new minutes, reason[25];
		if (sscanf(inputtext, "is[25]", minutes, reason)) return SendClientMessage(playerid, X11_RED2, "Incorrect arguments specified.");
		va_EmulateCommand(pid, "/jail %d %d %s", clickedplayerid, minutes, reason);
	}

	inline AdminManageBan(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		va_EmulateCommand(pid, "/ban %d -1 %s", clickedplayerid, inputtext);
	}

	inline AdminManageKick(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new reason[128];
		if (sscanf(inputtext, "s[128]", reason)) return SendClientMessage(playerid, X11_RED2, "That doesn't seem like a nice reason.");
		va_EmulateCommand(pid, "/kick %d %s", clickedplayerid, reason);
	}

	inline AdminManageTP(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new dest;
		if (sscanf(inputtext, "u", dest)) return SendClientMessage(playerid, X11_RED2, "Please write the ID/name of the player to teleport this player to.");
		va_EmulateCommand(pid, "/teleplayer %d %d", clickedplayerid, dest);
	}

	inline AdminManageHP(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new Float: floatval;
		if (sscanf(inputtext, "f", floatval)) return SendClientMessage(playerid, X11_RED2, "Invalid parameter value specified.");
		va_EmulateCommand(pid, "/sethealth %d %0.4f", clickedplayerid, floatval);
	}

	inline AdminManageAR(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new Float: floatval;
		if (sscanf(inputtext, "f", floatval)) return SendClientMessage(playerid, X11_RED2, "Invalid parameter value specified.");
		va_EmulateCommand(pid, "/setarmour %d %0.4f", clickedplayerid, floatval);
	}

	inline AdminManageVHP(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new Float: carhealth;
		if (sscanf(inputtext, "i", carhealth)) return SendClientMessage(playerid, X11_RED2, "Invalid parameter value specified.");
		va_EmulateCommand(pid, "/carhealth %d %d", clickedplayerid, carhealth);
	}

	inline AdminManageWeap(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new weap[25], ammo;
		if (sscanf(inputtext, "s[25]i", weap, ammo)) return SendClientMessage(playerid, X11_RED2, "Invalid parameter values specified.");
		va_EmulateCommand(pid, "/giveweapon %d %s %d", clickedplayerid, weap, ammo);
	}

	inline AdminManageAnswer(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return AdminPanel(playerid, clickedplayerid);
		new message[128];
		if (sscanf(inputtext, "s[128]", message)) return SendClientMessage(playerid, X11_RED2, "That doesn't seem like a nice answer to send to this player.");
		va_EmulateCommand(pid, "/answer %d %s", clickedplayerid, message);
	}

	inline AdminManageActions(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return AdminPanel(playerid, clickedplayerid);
		switch (listitem) {
			case 0: Dialog_ShowCallback(playerid, using inline AdminManageKick, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Are you sure you want to kick this player?\nPlease write a reason below to proceed.", ">>", "X");
			case 1: Dialog_ShowCallback(playerid, using inline AdminManageBan, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Are you sure you want to ban this player?\nPlease write a reason below to proceed.\n\
				"RED"* Please note that bans through this dialog are all PERMANENT.", ">>", "X");
			case 2: {
				if (PlayerInfo[clickedplayerid][pMuted]) {
					va_EmulateCommand(pid, "/unmute %d", clickedplayerid);
				} else {
					Dialog_ShowCallback(playerid, using inline AdminManageMute, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
						"Please write the reason to mute this player for below.", ">>", "X");
				}
			}
			case 3: {
				if (PlayerInfo[clickedplayerid][pFrozen]) {
					va_EmulateCommand(pid, "/unfreeze %d", clickedplayerid);
				} else {
					Dialog_ShowCallback(playerid, using inline AdminManageFreeze, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
						"(Freeze) Please write the amount of minutes and reason below in the form of 'minutes reason'.", ">>", "X");
				}
			}
			case 4: {
				if (PlayerInfo[clickedplayerid][pJailed]) {
					va_EmulateCommand(pid, "/unjail %d", clickedplayerid);
				} else {
					Dialog_ShowCallback(playerid, using inline AdminManageJail, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
						"(Jail) Please write the amount of minutes and reason below in the form of 'minutes reason'.", ">>", "X");
				}
			}
			case 5: va_EmulateCommand(pid, "/disablecaps %d", clickedplayerid);
			case 6: va_EmulateCommand(pid, "/spawn %d", clickedplayerid);
			case 7: va_EmulateCommand(pid, "/get %d", clickedplayerid);
			case 8: va_EmulateCommand(pid, "/goto %d", clickedplayerid);
			case 9: Dialog_ShowCallback(playerid, using inline AdminManageTP, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Please write the destination player to teleport this player to.", ">>", "X");
			case 10: va_EmulateCommand(pid, "/sethealth %d 0.0", clickedplayerid);
			case 11: Dialog_ShowCallback(playerid, using inline AdminManageHP, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Write the new health value for this player in form of a float value between 0.0 and 100.0.", ">>", "X");
			case 12: Dialog_ShowCallback(playerid, using inline AdminManageAR, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Write the new armour value for this player in form of a float value between 0.0 and 100.0.", ">>", "X");
			case 13: Dialog_ShowCallback(playerid, using inline AdminManageVHP, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Write the new armour value for this player's car health in form of a float value between 0.0 and 1000.0.", ">>", "X");
			case 14: Dialog_ShowCallback(playerid, using inline AdminManageWeap, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Please specify both weapon name and it's ammo, like 'sniper 500'.", ">>", "X");
			case 15: va_EmulateCommand(pid, "/disarm %d", clickedplayerid);
			case 16: va_EmulateCommand(pid, "/slap %d", clickedplayerid);
			case 17: va_EmulateCommand(pid, "/explode %d", clickedplayerid);
			case 18: Dialog_ShowCallback(playerid, using inline AdminManageAnswer, DIALOG_STYLE_INPUT, PlayerInfo[clickedplayerid][PlayerName],
				"Please write an answer for this player if they asked anything at all.", ">>", "X");
		}
	}

	inline AdminManagePanel(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return 1;
		switch (listitem) {
			case 0: va_EmulateCommand(pid, "/spec %d", clickedplayerid);
			case 1: {
				Dialog_ShowCallback(pid, using inline AdminManageActions, DIALOG_STYLE_LIST, "Select an Action...",
					"Kick\nBan\n(Un)mute\n(Un)freeze\n(Un)jail\nDisable Caps\nRespawn\nTeleport Here\nTeleport There\nTeleport To\n\
					Kill Player\nChange Health\nChange Armour\nCar Health\nGive Weapon\nDisarm\nSlap\n\
					Explode\nAnswer Question", ">>", "X");
			}
			case 2: {
				SendClientMessage(playerid, X11_LIMEGREEN, "You are such a cute admin huh? Get back to your work.");
			}
		}
	}

	Dialog_ShowCallback(playerid, using inline AdminManagePanel, DIALOG_STYLE_LIST, PlayerInfo[clickedplayerid][PlayerName],
		"Watch\nActions\nGive them a cookie!", ">>", "X");
	return 1;
}

//Clear reports
ClearReportsData(playerid) {
	for (new i = 0; i < MAX_REPORTS; i++) {
		if (ReportInfo[i][R_FROM_ID] == playerid) {
			ReportInfo[i][R_FROM_ID] = INVALID_PLAYER_ID;
		} else if (ReportInfo[i][R_AGAINST_ID] == playerid) {
			ReportInfo[i][R_AGAINST_ID] = INVALID_PLAYER_ID;
		}
	}
	return 1;
}

//Jail system

JailPlayer(targetid) {
	SetPlayerVirtualWorld(targetid, JAIL_WORLD);
	TogglePlayerControllable(targetid, true);
	SetPlayerPos(targetid, 197.6661, 173.8179, 1003.0234);
	SetPlayerInterior(targetid, 3);
	SetCameraBehindPlayer(targetid);
	JailTimer[targetid] = SetTimerEx("JailRelease", PlayerInfo[targetid][pJailTime], false, "d", targetid);
	PlayerInfo[targetid][pJailed] = 1;
	return 1;
}

JailRelease(targetid) {
	KillTimer(JailTimer[targetid]);
	PlayerInfo[targetid][pJailTime] = 0;
	PlayerInfo[targetid][pJailed] = 0;
	SetPlayerInterior(targetid, 0);
	SetPlayerVirtualWorld(targetid, BF_WORLD);
	SetPlayerPos(targetid, 0.0, 0.0, 0.0);
	SpawnPlayer(targetid);
	SendGameMessage(targetid, X11_SERV_INFO, MSG_JAIL_RELEASED);
	return 1;
}

//
/*
		A P I!
*/
//

//Reset
ADMIN_OnPlayerConnect(playerid) {
	PlayerInfo[playerid][pDonorLevel] = 0;
	PlayerInfo[playerid][pAdminLevel] = 0;
	return 1;
}

ADMIN_OnPlayerDisconnect(playerid) {
	//Ensure that the admin system is properly reset
	PlayerInfo[playerid][pJailed] = 0;
	PlayerInfo[playerid][pFrozen] = 0;

	//Update spectator mode if this player was being spectated by an admin
	foreach (new x: Player) {
		if (GetPlayerState(x) == PLAYER_STATE_SPECTATING && PlayerInfo[x][pSpecId] == playerid) {
			if (ComparePrivileges(x, CMD_MEMBER)) {
				RandomSpectate(x);
			} else {
				StopSpectate(x);
			}
		}
	}
	return 1;
}

ADMIN_OnPlayerSpawn(playerid) {
	//Update administrators whom are spectating this player
	foreach (new x: Player) {
		if (pVerified[x] && GetPlayerState(x) == PLAYER_STATE_SPECTATING) {
			if (PlayerInfo[x][pSpecId] == playerid && ComparePrivileges(x, CMD_MEMBER)) {
				PlayerSpectatePlayer(x, playerid);
				NotifyPlayer(x, "Player respawned...");
			}
			if (PlayerInfo[x][pSpecId] == playerid && !ComparePrivileges(x, CMD_MEMBER)) {
				PlayerInfo[x][pSpecId] = INVALID_PLAYER_ID;
				TogglePlayerSpectating(x, false);
			}
		}
	}

	//Reset spectator mode if this player was spectating
	if (PlayerInfo[playerid][pSpecId] != INVALID_PLAYER_ID) {
		PlayerInfo[playerid][pSpecId] = INVALID_PLAYER_ID;
		PlayerInfo[playerid][pSpecMode] = ADMIN_SPEC_TYPE_NONE;
	}
	return 1;
}

ADMIN_OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
	//If the admin wants to spectate a random player, why not let him be?
	if (PRESSED(KEY_WALK)) {
		if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) {
			if (ComparePrivileges(playerid, CMD_MEMBER)) {
				RandomSpectate(playerid);
			}
		}
	}
	return 1;
}

//Spectator mode
ADMIN_OnPlayerStateChange(playerid, newstate, oldstate) {
	#pragma unused oldstate
	foreach (new x: Player) {
		if (GetPlayerState(x) == PLAYER_STATE_SPECTATING && PlayerInfo[x][pSpecId] == playerid) {
			if (!ComparePrivileges(x, CMD_MEMBER)) {
				StopSpectate(x);
			} else {
				SetPlayerInterior(x, GetPlayerInterior(playerid));
				SetPlayerVirtualWorld(x, GetPlayerVirtualWorld(playerid));

				if (newstate == PLAYER_STATE_ONFOOT) {
					TogglePlayerSpectating(x, true);
					PlayerSpectatePlayer(x, playerid);
					PlayerInfo[x][pSpecMode] = ADMIN_SPEC_TYPE_PLAYER;
				}

				if (newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) {
					TogglePlayerSpectating(x, true);
					PlayerSpectateVehicle(x, GetPlayerVehicleID(playerid));
					PlayerInfo[x][pSpecMode] = ADMIN_SPEC_TYPE_VEHICLE;
				}
			}
		}
	}
	RACE_OnPlayerStateChange(playerid);
	return 1;
}

ADMIN_OnPlayerClickTD(playerid, Text:clickedid) {
	if (clickedid == aSpecTD[1]) {
		StopSpectate(playerid);
		return 1;
	}

	if (clickedid == aSpecTD[4]) {
		new count = Iter_Count(Player);
		if (count < 2) {
			return StopSpectate(playerid);
		}

		new x = PlayerInfo[playerid][pSpecId] - 1;
		if (x < 0) x = Iter_Count(Player);

		if (pVerified[x]) {
			StartSpectate(playerid, x);
		} else StopSpectate(playerid);
		return 1;
	}

	if (clickedid == aSpecTD[5]) {
		new count = Iter_Count(Player);
		if (count < 2) {
			return StopSpectate(playerid);
		}

		new x = PlayerInfo[playerid][pSpecId] + 1;
		if (x >= MAX_PLAYERS) x = 0;

		if (pVerified[x]) {
			StartSpectate(playerid, x);
		} else StopSpectate(playerid);
		return 1;
	}

	if (clickedid == aSpecTD[7]) {
		new cmd[15];
		format(cmd, sizeof(cmd), "/weaps %d", PlayerInfo[playerid][pSpecId]);
		PC_EmulateCommand(playerid, cmd);
		return 1;
	}

	if (clickedid == aSpecTD[8]) {
		new cmd[15];
		format(cmd, sizeof(cmd), "/items %d", PlayerInfo[playerid][pSpecId]);
		PC_EmulateCommand(playerid, cmd);
		return 1;
	}

	if (clickedid == aSpecTD[9]) {
		new cmd[15];
		format(cmd, sizeof(cmd), "/bstats %d", PlayerInfo[playerid][pSpecId]);
		PC_EmulateCommand(playerid, cmd);
		return 1;
	}

	if (clickedid == aSpecTD[10]) {
		new cmd[15];
		format(cmd, sizeof(cmd), "/getinfo %d", PlayerInfo[playerid][pSpecId]);
		PC_EmulateCommand(playerid, cmd);
		return 1;
	}

	if (clickedid == aSpecTD[11]) {
		AdminPanel(playerid, PlayerInfo[playerid][pSpecId]);
		return 1;
	}
	return 1;
}

//Log Functions

forward GetLog_Ban(playerid, nick[]);
forward GetLog_Kick(playerid, nick[]);
forward GetLog_Unban(playerid, nick[]);
forward GetLog_Jail(playerid, nick[]);
forward GetLog_Mute(playerid, nick[]);
forward GetLog_Warn(playerid, nick[]);
forward GetLog_Freeze(playerid, nick[]);

public GetLog_Kick(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new Admin[MAX_PLAYER_NAME], Reason[35], Date;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_549z, nick);
		for (new i = cache_num_rows() - 1; i > -1; i--) {
			cache_get_value(i, "Punisher", Admin, sizeof(Admin));
			cache_get_value(i, "ActionReason", Reason, sizeof(Reason));
			cache_get_value_int(i, "ActionDate", Date);

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_9x, i, Admin, Reason, GetWhen(Date, gettime()));
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}

public GetLog_Ban(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new Admin[MAX_PLAYER_NAME], Reason[35], Days, Date[24];
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_549z, nick);
		for (new i, j = cache_num_rows(); i != j; i++) {
			cache_get_value(i, "AdminName", Admin, sizeof(Admin));
			cache_get_value(i, "BanReason", Reason, sizeof(Reason));
			cache_get_value_int(i, "ExpiryDate", Days);
			cache_get_value(i, "BanDate", Date, sizeof(Date));

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_10x, i, Admin, Reason, Days, Date);
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}

public GetLog_Warn(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new Admin[MAX_PLAYER_NAME], Reason[35], Date;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_549z, nick);
		for (new i, j = cache_num_rows(); i != j; i++) {
			cache_get_value(i, "Punisher", Admin, sizeof(Admin));
			cache_get_value(i, "ActionReason", Reason, sizeof(Reason));
			cache_get_value_int(i, "ActionDate", Date);

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_11x, i, Admin, Reason, GetWhen(Date, gettime()));
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}
public GetLog_Unban(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new Admin[MAX_PLAYER_NAME], Date;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_549z, nick);
		for (new i, j = cache_num_rows(); i != j; i++) {
			cache_get_value(i, "Punisher", Admin, sizeof(Admin));
			cache_get_value_int(i, "ActionDate", Date);

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_12x, i, Admin, GetWhen(Date, gettime()));
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}

public GetLog_Mute(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new Admin[MAX_PLAYER_NAME], Reason[35], Date;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_549z, nick);
		for (new i, j = cache_num_rows(); i != j; i++) {
			cache_get_value(i, "Punisher", Admin, sizeof(Admin));
			cache_get_value(i, "ActionReason", Reason, sizeof(Reason));
			cache_get_value_int(i, "ActionDate", Date);

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_13x, i, Admin, Reason, GetWhen(Date, gettime()));
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}

public GetLog_Freeze(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new Admin[MAX_PLAYER_NAME], PunishmentTime[24], Reason[35], Date;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_549z, nick);
		for (new i, j = cache_num_rows(); i != j; i++) {
			cache_get_value(i, "Punisher", Admin, sizeof(Admin));
			cache_get_value(i, "ActionReason", Reason, sizeof(Reason));
			cache_get_value(i, "PunishmentTime", PunishmentTime, sizeof(PunishmentTime));
			cache_get_value_int(i, "ActionDate", Date);

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_14x, i, Admin, PunishmentTime, Reason, GetWhen(Date, gettime()));
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}

public GetLog_Jail(playerid, nick[]) {
	if (cache_num_rows() != 0) {
		new Admin[MAX_PLAYER_NAME], PunishmentTime[24], Reason[35], Date;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_549z, nick);
		for (new i, j = cache_num_rows(); i != j; i++) {
			cache_get_value(i, "Punisher", Admin, sizeof(Admin));
			cache_get_value(i, "ActionReason", Reason, sizeof(Reason));
			cache_get_value_int(i, "ActionDate", Date);
			cache_get_value(i, "PunishmentTime", PunishmentTime, sizeof(PunishmentTime));

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_15x, i, Admin, PunishmentTime, Reason, GetWhen(Date, gettime()));
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NO_RECORDS);
	return 1;
}

//PUBG FUNCTIONS

forward HideBonus(playerid);
public HideBonus(playerid) return PlayerTextDrawHide(playerid, PUBGBonusTD[playerid]);

forward HidePUBGWinner();
public HidePUBGWinner() {
	for (new i = 0; i < sizeof(PUBGWinnerTD); i++) {
		TextDrawHideForAll(PUBGWinnerTD[i]);
	}
	TextDrawHideForAll(PUBGKillTD);
	TextDrawHideForAll(PUBGKillsTD);
	TextDrawHideForAll(PUBGAliveTD);
	TextDrawHideForAll(PUBGAreaTD);
	for (new i = 0; i < 5; i++) {
		if (IsValidVehicle(PUBGVehicles[i])) {
			CarDeleter(PUBGVehicles[i]);
		}
	}
	return 1;
}

forward AliveUpdate();
public AliveUpdate() {
	if (PUBGOpened) {
		new players[10];
		format(players, sizeof(players), "%d ALIVE", Iter_Count(PUBGPlayers));
		TextDrawSetString(PUBGAliveTD, players);
		foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAliveTD);
		SetTimer("AliveUpdate", 1000, false);
	}
	return 1;
}

forward StartPUBG();
public StartPUBG() {
	if (Iter_Count(PUBGPlayers) < 4) {
		if (!Iter_Count(PUBGPlayers)) {
			HidePUBGWinner();
		} else {
			foreach (new i: Player) {
				if (Iter_Contains(PUBGPlayers, i)) {
					TextDrawHideForPlayer(i, PUBGKillsTD);
					TextDrawHideForPlayer(i, PUBGAreaTD);
					TextDrawHideForPlayer(i, PUBGAliveTD);
					TextDrawHideForPlayer(i, PUBGKillTD);
					SpawnPlayer(i);
					Iter_SafeRemove(PUBGPlayers, i, i);
				}
			}
		}
		SendWarUpdate("PUBG Event ended now!");
		for (new i = 0; i < MAX_SLOTS; i++) {
			if (gLootExists[i] && gLootPUBG[i]) {
				AlterLootPickup(i);
			}
			if (gWeaponExists[i] && gWeaponPUBG[i]) {
				AlterWeaponPickup(INVALID_PLAYER_ID, i);
			}
		}
		PUBGStarted = false;
		SendClientMessageToAll(X11_RED_2, "PUBG Event was cancelled due to lacking at least 4 participants!");
		return 1;
	}
	if (PUBGOpened) {
		PUBGOpened = false;
		PUBGStarted = true;
		SetTimer("UpdatePUBG", 1000, false);
		foreach(new i: PUBGPlayers) {
			PlayerPlaySound(i, 15805, 0, 0, 0);
			SendGameMessage(i, X11_SERV_INFO, MSG_GO);
			SetPlayerVirtualWorld(i, PUBG_WORLD);
			SetPlayerInterior(i, 0);
			SetPlayerPos(i, 3300.2144 + frandom(15.0, -10.0), 3613.9907 + frandom(10.0, -15.0), frandom(200.0, 150.0));
			GivePlayerWeapon(i, 46, 1);
		}
	}
	return 1;
}

forward ExecuteToxication();
public ExecuteToxication() {
	if (!PUBGStarted) return 1;
	PUBGRadius -= Multiplier;
	GZ_ShapeDestroy(PUBGCircle);
	PUBGCircle = GZ_ShapeCreate(CIRCUMFERENCE, 4023.5042, 3750.9209, PUBGRadius);
	GZ_ShapeShowForAll(PUBGCircle, X11_RED2);
	PUBGMeters -= Multiplier;
	if (PUBGMeters < 1.0) return 1;
	else return SetTimerEx("IntoxicateT", 500, false, "f", PUBGMeters);
}

forward UpdatePUBG();
public UpdatePUBG() {
	if (PUBGStarted) {
		new pubg[10];
		format(pubg, sizeof(pubg), "%d ALIVE", Iter_Count(PUBGPlayers));
		TextDrawSetString(PUBGAliveTD, pubg);
		foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAliveTD);

		if (PUBGKillTick > 0) {
			foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGKillTD);
			PUBGKillTick --;
		} else TextDrawHideForAll(PUBGKillTD);

		if (++PUBGTimer > 5) {
			foreach (new i: Player) {
				if (GetPlayerState(i) != PLAYER_STATE_SPECTATING) {
					if (Iter_Contains(PUBGPlayers, i)) {
						new Float: X, Float: Y, Float: Z;
						GetPlayerPos(i, X, Y, Z);
						if (PUBGRadius < GetPointDistanceToPoint(X, Y, 4023.5042, 3750.9209)) {
							GameTextForPlayer(i, MSG_PUBG_DANGER, 3000, 3);
							new Float: HP;
							GetPlayerHealth(i, HP);
							SetPlayerHealth(i, HP -1.0);
							PlayerPlaySound(i, 1134, 0, 0, 0);
						}
					}
				}
			}
		}
		switch (PUBGTimer) {
			case 60:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 1 minute");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 65: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 110:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 10 seconds");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 115: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 120:
			{
				Multiplier = 5.0;
				TextDrawSetString(PUBGAreaTD, "Intoxicating.");
				Intoxicate(75.00);
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 125: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 130:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 4 minutes");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 135: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 190:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 3 minutes");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 195: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 250:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 2 minutes");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 255: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 310:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 1 minute");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 315: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 360:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 10 seconds");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 365: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 370:
			{
				Multiplier = 10.0;
				TextDrawSetString(PUBGAreaTD, "Intoxicating..");
				Intoxicate(100.00);
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 375: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 380:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 5 minutes");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 385: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 440:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 4 minutes");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 445: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 500:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 3 minutes");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 505: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 560:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 2 minutes");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 565: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 620:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 1 minute");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 625: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 670:
			{
				TextDrawSetString(PUBGAreaTD, "Restricting area in 10 seconds");
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 675: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
			case 680:
			{
				Multiplier = 15.0;
				TextDrawSetString(PUBGAreaTD, "Intoxicating...");
				Intoxicate(700.00);
				foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGAreaTD);
			}
			case 685: foreach(new i: PUBGPlayers) TextDrawHideForPlayer(i, PUBGAreaTD);
		}
		SetTimer("UpdatePUBG", 1000, false);
	}
	return 1;
}

StartPUBGByPlayer(playerid) {
	if (PUBGOpened || PUBGStarted) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_171x);
	SetTimer("AliveUpdate", 1000, false);
	SetTimer("StartPUBG", 60000, false);
	SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_58x);
	PUBGOpened = true;
	PUBGRadius = 800.0;
	GZ_ShapeDestroy(PUBGCircle);
	PUBGCircle = GZ_ShapeCreate(CIRCUMFERENCE, 4023.5042, 3750.9209, PUBGRadius);
	GZ_ShapeShowForAll(PUBGCircle, X11_RED2);
	PUBGKills = 0;
	TextDrawSetString(PUBGKillsTD, "0 KILLED");

	PUBGVehicles[0] = CreateVehicle(423,-38.5218,-41.0587,3.1429,337.0879,0,7,-1); // pubg car
	PUBGVehicles[1] = CreateVehicle(509,-20.7211,47.5877,2.6267,70.0511,0,7,-1); // pubg bike
	PUBGVehicles[2] = CreateVehicle(531,-54.2063,27.2287,3.0787,70.1768,0,7,-1); // farm tractor
	PUBGVehicles[3] = CreateVehicle(531,-51.7645,47.1532,3.0826,341.7239,0,7,-1); // farm tractor
	PUBGVehicles[4] = CreateVehicle(531,-102.9677,65.6263,3.0828,295.1403,0,7,-1); // farm tractor

	for (new i = 0; i < sizeof(PUBGVehicles); i++) {
		SetVehicleVirtualWorld(PUBGVehicles[i], 113);
	}

	new
		Float: FX,
		Float: FY,
		Float: FZ
	;

	for (new p = 0; p < _loaded_pubg_items; p++) {
		FX = PUBGArray[p][0];
		FY = PUBGArray[p][1];
		CA_FindZ_For2DCoord(FX, FY, FZ);

		new random_type = random(100);
		switch (random_type) {
			case 0..39: {
				for (new i = 0; i < MAX_SLOTS; i++) {
					if (!gLootExists[i]) {
						gLootItem[i] = random(MAX_ITEMS) - 5;
						new Float: RX = 0.0;
						if (gLootItem[i] != MASK && gLootItem[i] != HELMET && gLootItem[i] != LANDMINES) {
							RX = 90.0;
						}
						gLootPickable[i] = 0;
						gLootAmt[i] = random(2) + 1;
						gLootObj[i] = CreateDynamicObject(Items_GetObject(gLootItem[i]), FX, FY, FZ + 0.1, RX, 0.0, 12.5);
						gLootArea[i] = CreateDynamicCircle(FX, FY, 1.0);
						gLootPickable[i] = 1;
						new randposchange = random(7);
						switch (randposchange) {
							case 0: FX += 2.0, FY -= 2.0;
							case 1: FX += 2.2, FY -= 2.2;
							case 2: FX += 2.4, FY -= 2.4;
							case 3: FX += 2.6, FY -= 2.6;
							case 4: FX -= 2.0, FY += 2.0;
							case 5: FX -= 2.2, FY += 2.2;
							case 6: FX -= 2.4, FY += 2.4;
						}
						KillTimer(gLootTimer[i]);
						gLootTimer[i] = SetTimerEx("AlterLootPickup", 795000, false, "i", i);
						gLootExists[i] = 1;
						gLootPUBG[i] = 1;
						break;
					}
				}
			}
			case 40..100: {
				new randomweap = random(10), weapon, ammo;
				switch (randomweap) {
					case 0: weapon = WEAPON_DEAGLE, ammo = random(100) + 50;
					case 1: weapon = WEAPON_SHOTGSPA, ammo = random(100) + 50;
					case 2: weapon = WEAPON_SHOTGUN, ammo = random(100) + 50;
					case 3: weapon = WEAPON_GRENADE, ammo = random(2) + 1;
					case 4: weapon = WEAPON_MOLTOV, ammo = random(2) + 1;
					case 5: weapon = WEAPON_COLT45, ammo = random(200) + 55;
					case 6: weapon = WEAPON_SILENCED, ammo = random(200) + 55;
					case 7: weapon = WEAPON_TEC9, ammo = random(200) + 55;
					case 8: weapon = WEAPON_MP5, ammo = random(200) + 55;
					case 9: weapon = WEAPON_SNIPER, ammo = random(25) + 55;
				}
				for (new a = 0; a < MAX_SLOTS; a++) {
					if (!gWeaponExists[a]) {
						gWeaponExists[a] = 1;
						gWeaponPickable[a] = 0;
						gWeaponPUBG[a] = 1;

						gWeaponObj[a] = CreateDynamicObject(GetWeaponModel(weapon), FX, FY, FZ, 90.0, 0.0, 0.0);

						new weap_label[45];
						format(weap_label, sizeof(weap_label), "%s(%d)", ReturnWeaponName(weapon), ammo);
						gWeapon3DLabel[a] = CreateDynamic3DTextLabel(weap_label, 0xFFFFFFFF, FX, FY, FZ, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

						gWeaponID[a] = weapon;
						gWeaponAmmo[a] = ammo;

						gWeaponPickable[a] = 1;
						gWeaponTimer[a] = SetTimerEx("AlterWeaponPickup", 450000, false, "ii", INVALID_PLAYER_ID, a);
						gWeaponArea[a] = CreateDynamicCircle(FX, FY, 2.5);

						break;
					}
				}
			}
		}
	}
	return 1;
}

Intoxicate(Float:meters)  {
	PUBGMeters = meters;
	SetTimer("ExecuteToxication", 500, 0);
	return 1;
}

PUBG_OnPlayerSpawn(playerid) {
	if (Iter_Contains(PUBGPlayers, playerid)) {
		Iter_Remove(PUBGPlayers, playerid);
	}
	TextDrawHideForPlayer(playerid, PUBGAreaTD);
	TextDrawHideForPlayer(playerid, PUBGAliveTD);
	TextDrawHideForPlayer(playerid, PUBGKillTD);
	TextDrawHideForPlayer(playerid, PUBGKillsTD);
	return 1;
}

PUBG_OnPlayerDisconnect(playerid) {
	if (Iter_Contains(PUBGPlayers, playerid)) {
		TextDrawHideForPlayer(playerid, PUBGKillsTD);

		new msg[SMALL_STRING_LEN];

		format(msg, sizeof(msg), "%d Kills", PUBGKills ++);
		TextDrawSetString(PUBGKillsTD, msg);

		Iter_Remove(PUBGPlayers, playerid);
		TextDrawHideForPlayer(playerid, PUBGAreaTD);
		TextDrawHideForPlayer(playerid, PUBGAliveTD);
		TextDrawHideForPlayer(playerid, PUBGKillTD);
		if (Iter_Count(PUBGPlayers) == 1) {
			new winner = Iter_Random(PUBGPlayers);
			TextDrawHideForPlayer(winner, PUBGKillsTD);
			TextDrawHideForPlayer(winner, PUBGKillTD);
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_CHICKEN_DINNER, PlayerInfo[winner][PlayerName]);
			PlayerInfo[winner][pPUBGEventsWon] ++;
			PlayerInfo[winner][pEXPEarned] += 50;
			SuccessAlert(winner);
			Iter_Clear(PUBGPlayers);
			PUBGStarted = false;
			SetPlayerHealth(winner, 0);
			TextDrawHideForPlayer(winner, PUBGAreaTD);
			TextDrawHideForPlayer(winner, PUBGAliveTD);
			GameTextForPlayer(winner, "~g~WINNER WINNER CHICKEN DINNER!", 3000, 3);
			TextDrawSetString(PUBGWinnerTD[1], PlayerInfo[winner][PlayerName]);
			new str[SMALL_STRING_LEN];
			format(str, sizeof(str), "~w~KILLS: ~g~%d            ~w~REWARD: ~g~$1,000 & 1 Score", PUBGKills);
			TextDrawSetString(PUBGWinnerTD[3], str);
			for (new i = 0; i < sizeof(PUBGWinnerTD); i++) {
				TextDrawShowForAll(PUBGWinnerTD[i]);
			}
			SetTimer("HidePUBGWinner", 3000, false);
			for (new i = 0; i < MAX_SLOTS; i++) {
				if (gLootExists[i] && gLootPUBG[i]) {
					AlterLootPickup(i);
				}
				if (gWeaponExists[i] && gWeaponPUBG[i]) {
					AlterWeaponPickup(INVALID_PLAYER_ID, i);
				}
			}
		}
		else if (!Iter_Count(PUBGPlayers)) {
			PUBGStarted = false;
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_28x);
			HidePUBGWinner();
		}
	}
	Iter_Remove(PUBGPlayers, playerid);
	return 1;
}

PUBG_OnPlayerDeath(playerid, killerid) {
	if (Iter_Contains(PUBGPlayers, playerid)) {
		TextDrawHideForPlayer(playerid, PUBGKillsTD);

		new msg[SMALL_STRING_LEN];
		if (killerid != INVALID_PLAYER_ID) {
			format(msg, sizeof(msg), "~g~~h~%s ~w~killed ~r~~h~%s~w~ with ~b~~h~%s", PlayerInfo[playerid][PlayerName], PlayerInfo[killerid][PlayerName], ReturnWeaponName(GetPlayerWeapon(killerid)));
		} else format(msg, sizeof(msg), "~r~~h~%s ~w~ was eliminated", PlayerInfo[playerid][PlayerName]);

		TextDrawSetString(PUBGKillTD, msg);

		format(msg, sizeof(msg), "%d Kills", PUBGKills ++);
		TextDrawSetString(PUBGKillsTD, msg);
		foreach(new i: PUBGPlayers) TextDrawShowForPlayer(i, PUBGKillsTD);

		if (killerid != INVALID_PLAYER_ID) {
			PlayerTextDrawSetString(killerid, PUBGBonusTD[killerid], "~g~~h~~h~+2 Score & $10,000");
			PlayerTextDrawShow(killerid, PUBGBonusTD[killerid]);
			SetTimerEx("HideBonus", 3000, false, "i", killerid);
		}

		Iter_Remove(PUBGPlayers, playerid);
		TextDrawHideForPlayer(playerid, PUBGAreaTD);
		TextDrawHideForPlayer(playerid, PUBGAliveTD);
		TextDrawHideForPlayer(playerid, PUBGKillTD);
		if (Iter_Count(PUBGPlayers) == 1) {
			new winner = Iter_Random(PUBGPlayers);
			TextDrawHideForPlayer(winner, PUBGKillsTD);
			TextDrawHideForPlayer(winner, PUBGKillTD);
			PlayerInfo[winner][pPUBGEventsWon] ++;
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_CHICKEN_DINNER, PlayerInfo[winner][PlayerName]);
			PlayerInfo[winner][pEXPEarned] += 50;
			SuccessAlert(winner);
			Iter_Clear(PUBGPlayers);
			PUBGStarted = false;
			SetPlayerHealth(winner, 0);
			TextDrawHideForPlayer(winner, PUBGAreaTD);
			TextDrawHideForPlayer(winner, PUBGAliveTD);
			GameTextForPlayer(winner, "~g~WINNER WINNER CHICKEN DINNER!", 3000, 3);
			TextDrawSetString(PUBGWinnerTD[1], PlayerInfo[winner][PlayerName]);
			new str[SMALL_STRING_LEN];
			format(str, sizeof(str), "~w~KILLS: ~g~%d            ~w~REWARD: ~g~$1,000 & 1 Score", PUBGKills);
			TextDrawSetString(PUBGWinnerTD[3], str);
			for (new i = 0; i < sizeof(PUBGWinnerTD); i++) {
				TextDrawShowForAll(PUBGWinnerTD[i]);
			}
			SetTimer("HidePUBGWinner", 3000, false);
			for (new i = 0; i < MAX_SLOTS; i++) {
				if (gLootExists[i] && gLootPUBG[i]) {
					AlterLootPickup(i);
				}
				if (gWeaponExists[i] && gWeaponPUBG[i]) {
					AlterWeaponPickup(INVALID_PLAYER_ID, i);
				}
			}
		}
		else if (!Iter_Count(PUBGPlayers)) {
			PUBGStarted = false;
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_28x);
			HidePUBGWinner();
		}
		Iter_Remove(PUBGPlayers, playerid);
		TextDrawHideForPlayer(playerid, PUBGAreaTD);
		TextDrawHideForPlayer(playerid, PUBGAliveTD);
		TextDrawHideForPlayer(playerid, PUBGKillTD);
		TextDrawHideForPlayer(playerid, PUBGKillsTD);
	}
	return 1;
}

//Events Functions

//Event countdown
forward EventCD(cdValue);
public EventCD(cdValue) {
	if (counterOn == 1) {
		if (counterValue > 0) {
			new text[10];
			format(text, sizeof(text), "~w~%d", counterValue);

			counterValue--;

			foreach (new i: ePlayers) {
				if (IsPlayerSpawned(i)) {
					GameTextForPlayer(i, text, 1000, 3);
				}
			}
		} else {
			KillTimer(counterTimer);

			counterValue = -1;
			counterOn = 0;

			foreach (new i: ePlayers) {
				if (IsPlayerSpawned(i)) {
					SendGameMessage(i, X11_SERV_INFO, MSG_GO);
					PlayGoSound(i);
				}
			}
		}
	} else {
		KillTimer(counterTimer);
	}
	return 1;
}

EVENTS_OnGameModeInit() {
	new clear_data[E_DATA_ENUM];
	EventInfo = clear_data;
	EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
	EventInfo[E_TYPE] = -1;
	return 1;
}

EVENTS_OnPlayerConnect(playerid) {
	new clear_data2[E_PLAYER_ENUM] = -1;
	pEventInfo[playerid] = clear_data2;
	return 1;
}

EVENTS_OnPlayerDisconnect(playerid) {
	if (Iter_Contains(ePlayers, playerid)) {
		Iter_Remove(ePlayers, playerid);
		foreach (new i: ePlayers) {
			SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_265x, PlayerInfo[playerid][PlayerName]);
		}

		if (!Iter_Count(ePlayers)) {
			new clear_data[E_DATA_ENUM];
			EventInfo = clear_data;

			EventInfo[E_STARTED] = 0;
			EventInfo[E_OPENED] = 0;

			EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
			EventInfo[E_TYPE] = -1;
		}

		if (EventInfo[E_TYPE] == 1) {
			new winner_count, eteam[2];

			foreach (new i: ePlayers) {
				if (IsPlayerSpawned(i)) {
					if (pEventInfo[i][P_TEAM] == 0) {
						eteam[0] ++;
					} else {
						eteam[1] ++;
					}
				}
			}

			if ((!eteam[1] && eteam[0]) || (!eteam[0] && eteam[1])) {
				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_26x, EventInfo[E_NAME]);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_37x);

				EventInfo[E_OPENED] = 0;
				EventInfo[E_STARTED] = 0;
				foreach (new i: ePlayers) {
					TogglePlayerControllable(i, true);
					SetPlayerHealth(i, 0.0);

					winner_count ++;

					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_EVENT_WON_LIST, winner_count, PlayerInfo[i][PlayerName], EventInfo[E_SCORE], EventInfo[E_CASH]);

					GivePlayerCash(i, EventInfo[E_CASH]);
					GivePlayerScore(i, EventInfo[E_SCORE]);
					PlayerInfo[i][sEvents] ++;
					PlayerInfo[i][pEventsWon] ++;

					if (PlayerInfo[i][pCar] != -1) DestroyVehicle(PlayerInfo[i][pCar]);
					PlayerInfo[i][pCar] = -1;
				}

				new clear_data[E_DATA_ENUM];
				EventInfo = clear_data;

				EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
				EventInfo[E_TYPE] = -1;
				Iter_Clear(ePlayers);
			} else {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_266x);

				EventInfo[E_OPENED] = 0;
				EventInfo[E_STARTED] = 0;

				new clear_data[E_DATA_ENUM];
				EventInfo = clear_data;

				EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
				EventInfo[E_TYPE] = -1;
				Iter_Clear(ePlayers);
			}
		}
	}

	new clear_data[E_PLAYER_ENUM];
	pEventInfo[playerid] = clear_data;
	return 1;
}

//Vehicle Repair

forward PrepareRVeh(playerid);
public PrepareRVeh(playerid) {
	if (pRaceId[playerid] == -1) return 1;
	if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
	PlayerInfo[playerid][pCar] = -1;

	new Float: Position[4], Int, World;

	Int = RaceInterior[pRaceId[playerid]];
	World = 2000 + (pRaceId[playerid]);

	GetPlayerPos(playerid, Position[0], Position[1], Position[2]);
	GetPlayerFacingAngle(playerid, Position[3]);

	PlayerInfo[playerid][pCar] = CreateVehicle(RaceCar[pRaceId[playerid]], Position[0], Position[1], Position[2], Position[3], 0, 3, -1);

	LinkVehicleToInterior(PlayerInfo[playerid][pCar], Int);
	SetVehicleVirtualWorld(PlayerInfo[playerid][pCar], World);
	PutPlayerInVehicle(playerid, PlayerInfo[playerid][pCar], 0);
	Tuneacar(PlayerInfo[playerid][pCar]);
	return 1;
}

//Log Messages

LogPublicMessage(playerid, const message[128], time)
{
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `Messages_Log` (`Sender`,`Receiver`,`Message`,`Time`) \
		VALUES('%d','-1','%e','%d')", PlayerInfo[playerid][pAccountId], message, time);
	mysql_tquery(Database, query);
	return 1;
}

LogPrivateMessage(playerid, targetid, const message[128], time)
{
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `Messages_Log` (`Sender`,`Receiver`,`Message`,`Time`) \
		VALUES('%d','%d','%e','%d')", PlayerInfo[playerid][pAccountId], PlayerInfo[targetid][pAccountId], message, time);
	mysql_tquery(Database, query);
	return 1;
}

LogCommand(playerid, const command[], const parameters[], flags, time)
{
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `Commands_Log` (`Sender`,`Command`,`Parameters`,`Flags`,`Time`) \
		VALUES('%d','%e','%e','%d','%d')", PlayerInfo[playerid][pAccountId], command, parameters, flags, time);
	mysql_tquery(Database, query);
	return 1;
}

LogCheat(playerid, const cheat[], time)
{
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `Anticheat_Log` (`Suspect`,`Cheat`,`Time`) \
		VALUES('%d','%e','%d')", PlayerInfo[playerid][pAccountId], cheat, time);
	mysql_tquery(Database, query);
	return 1;
}

LogConnection(playerid, reason, time)
{
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `Connections_Log` (`Player`,`Reason`,`Time`) \
		VALUES('%d','%d','%d')", PlayerInfo[playerid][pAccountId], reason, time);
	mysql_tquery(Database, query);
	return 1;
}

LogActivity(playerid, const action[128], time, GLOBAL_TAG_TYPES:...)
{
	new actionex[128];
	format(actionex, sizeof(actionex), action, ___(3));
	new query[MEDIUM_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "INSERT INTO `Activity_Log` (`Player`,`Action`,`Time`) \
		VALUES('%d','%e','%d')", PlayerInfo[playerid][pAccountId], actionex, time);
	mysql_tquery(Database, query);
	return 1;
}

//TASKS

task RandonMessages[220000]() {
	new randmessage[300];
	format(randmessage, sizeof(randmessage), ">> {698DFA}%s", UpdateMessages[random(sizeof(UpdateMessages))]);
	foreach (new i: Player) {
		if (!PlayerInfo[i][pNoTutor]) {
			SendClientMessage(i, -1, randmessage);
		}
	}
	return 1;
}

task NewBountyTask[2000000]() {
	// Update weather every 30mins
    //UpdateWorldWeather();

	//Random bounty
	if (Iter_Count(Player)) {
		new luckypal = Iter_Random(Player);
		new randbount = random(100);
		switch (randbount) {
			case 1..10: PlayerInfo[luckypal][pBountyAmount] += 100000;
			default: PlayerInfo[luckypal][pBountyAmount] += 25000;
		}
	}
	return  1;
}

task SiteStyleChange[2500]() {
	if (sequenceProgress >= sizeof(gametextColors) - 1) {
		sequenceProgress = 0;
	} else {
		sequenceProgress ++;
	}

	if (reverseProgress <= 0) {
		reverseProgress = sizeof(gametextColors) - 1;
	} else {
		reverseProgress --;
	}

	new bool: reverse_letter = false;

	new plain_text[18 * (3 * MAX_GT_COLORS)] = "h2omultiplayer.com",
        styled_text[18 * (3 * MAX_GT_COLORS)];
    new plain_len = strlen(plain_text);
    new plain_len_left = strlen(plain_text);
	for (new i = 0; i < plain_len; i++) {
        plain_len_left--;
		if (!reverse_letter) {
            strcat(styled_text, gametextColors[sequenceProgress]);
			reverse_letter = true;
		} else {
            strcat(styled_text, gametextColors[reverseProgress]);
			reverse_letter = false;
		}
        strcat(styled_text, plain_text[i]);
        strdel(styled_text, strlen(styled_text) - plain_len_left, strlen(styled_text));
	}
	TextDrawSetString(Site_TD, styled_text);
	TextDrawShowForAll(Site_TD);
	return 1;
}

stock UpdateWorldWeather() {
	/*new next_weather_prob = random(100);*/
	/*if(next_weather_prob < 70)*/
	SetWeather(fine_weather_ids[random(sizeof(fine_weather_ids))]);
	/*else if(next_weather_prob < 95) SetWeather(foggy_weather_ids[random(sizeof(foggy_weather_ids))]);
	else							SetWeather(wet_weather_ids[random(sizeof(wet_weather_ids))]);*/
	return 1;
}

task GameUpdate[1000]() {
	//Race
	RaceEndCheck();

	//Prototype

	foreach (new i: teams_loaded) {
		if (PrototypeInfo[i][Prototype_Attacker] != INVALID_PLAYER_ID && !IsPlayerInVehicle(PrototypeInfo[i][Prototype_Attacker], PrototypeInfo[i][Prototype_Id])
			&& gettime() >= PlayerInfo[PrototypeInfo[i][Prototype_Attacker]][pLeavetime]) {
			DisablePlayerRaceCheckpoint(PrototypeInfo[i][Prototype_Attacker]);
			SetVehicleToRespawn(PrototypeInfo[i][Prototype_Id]);

			new update[SMALL_STRING_LEN];
			format(update, sizeof(update), MSG_SERVER_50x, PlayerInfo[PrototypeInfo[i][Prototype_Attacker]][PlayerName], Team_GetName(i));
			SendWarUpdate(update);
			GameTextForPlayer(PrototypeInfo[i][Prototype_Attacker], MSG_PROTOTYPE_FAILED, 3000, 3);

			PrototypeInfo[i][Prototype_Attacker] = INVALID_PLAYER_ID;

			break;
		}
	}

	TeamWarWinCheck();

	if (EventInfo[E_STARTED] && !EventInfo[E_OPENED]) {
		if (EventInfo[E_TYPE] == 1 && EventInfo[E_SPAWN_TYPE] != EVENT_SPAWN_INVALID
			&& EventInfo[E_AUTO])
		{
			new winner_count, eteam[2];

			foreach (new i: ePlayers)
			{
				if (pEventInfo[i][P_TEAM] == 0) {
					eteam[0] ++;
				} else {
					eteam[1] ++;
				}
			}

			if ((eteam[1] <= 0 && eteam[0] >= 1) || (eteam[0] <= 0 && eteam[1] >= 1)) {
				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_26x, EventInfo[E_NAME]);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_37x);

				EventInfo[E_OPENED] = 0;
				EventInfo[E_STARTED] = 0;
				foreach (new i: ePlayers) {
					TogglePlayerControllable(i, true);
					SetPlayerHealth(i, 0.0);

					winner_count ++;

					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_EVENT_WON_LIST, winner_count, PlayerInfo[i][PlayerName], EventInfo[E_SCORE], EventInfo[E_CASH]);

					GivePlayerCash(i, EventInfo[E_CASH]);
					GivePlayerScore(i, EventInfo[E_SCORE]);
					PlayerInfo[i][sEvents] ++;
					PlayerInfo[i][pEventsWon] ++;

					if (PlayerInfo[i][pCar] != -1) DestroyVehicle(PlayerInfo[i][pCar]);
					PlayerInfo[i][pCar] = -1;
				}
				Iter_Clear(ePlayers);

				new clear_data[E_DATA_ENUM];
				EventInfo = clear_data;

				EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
				EventInfo[E_TYPE] = -1;
			} else if (eteam[1] <= 0 && eteam[0] <= 0) {
				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_27x);

				EventInfo[E_OPENED] = 0;
				EventInfo[E_STARTED] = 0;

				new clear_data[E_DATA_ENUM];
				EventInfo = clear_data;

				EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
				EventInfo[E_TYPE] = -1;
				Iter_Clear(ePlayers);
			}
		}
	}
	return 1;
}

task GameUpdate2[500000]() {
	if (nukeIsLaunched == 1 && gettime() > nukeCooldown) {
		UpdateDynamic3DTextLabelText(nukeRemoteLabel, 0xFFFFFFFF, "Nuke\n{00CC00}Online");

		nukeIsLaunched = 0;
		SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_39x);
	}

	foreach (new i: teams_loaded) {
		if (AntennaInfo[i][Antenna_Exists] == 0 && AntennaInfo[i][Antenna_Kill_Time] <= gettime()) {
			AntennaInfo[i][Antenna_Exists] = 1;
			AntennaInfo[i][Antenna_Hits] = 0;

			CA_FindZ_For2DCoord(AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2]);
			SetDynamicObjectPos(AntennaInfo[i][Antenna_Id], AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2]);

			new update[SMALL_STRING_LEN];
			format(update, sizeof(update), MSG_SERVER_40x, Team_GetName(i));
			SendWarUpdate(update);

			new title[140];
			format(title, sizeof(title), "%s\n"IVORY"Radio Antenna", Team_GetName(i));
			UpdateDynamic3DTextLabelText(AntennaInfo[i][Antenna_Label], Team_GetColor(i), title);
		}
	}

	if (Iter_Count(Player)) {
		if (!WarInfo[War_Started]) {
			WarInfo[War_Team1] = Iter_Random(teams_loaded);
			WarInfo[War_Team2] = Iter_Random(teams_loaded);
			if (WarInfo[War_Team2] == WarInfo[War_Team1])
			{
				WarInfo[War_Team2] = 1;
				WarInfo[War_Team1] = 0;
			}

			WarInfo[Team1_Score] = 0;
			WarInfo[Team2_Score] = 0;

			WarInfo[War_Time] = 60 * 30; //30 mins
			war_time = WarInfo[War_Time] + gettime();

			WarInfo[War_Target] = random(sizeof(WarTargets));
			WarInfo[War_Score] = random(20) + 20; //max score
			WarInfo[War_Started] = 1;

			new war_str[135];
			format(war_str, sizeof(war_str), "|| WAR STARTED || Next war target: "RED"%s"CYAN" [pts needed: %d] (/war)!", WarTargets[WarInfo[War_Target]], WarInfo[War_Score]);
			SendClientMessageToAll(X11_CYAN, war_str);

			format(war_str, sizeof(war_str), "Team War: %s%s ~w~vs %s%s", Team_GetGTColor(WarInfo[War_Team1]), Team_GetName(WarInfo[War_Team1]),
			Team_GetGTColor(WarInfo[War_Team2]), Team_GetName(WarInfo[War_Team2]));
			TextDrawSetString(WarTD, war_str);
			foreach (new i: Player) {
				if (IsPlayerInMode(i, MODE_BATTLEFIELD)) {
					TextDrawShowForPlayer(i, WarTD);
				}
			}
		}
	}

	if (!PUBGOpened && PUBGStarted) {
		if (!Iter_Count(PUBGPlayers)) {
			HidePUBGWinner();
			foreach (new i: Player) {
				if (Iter_Contains(PUBGPlayers, i)) {
					TextDrawHideForPlayer(i, PUBGKillsTD);
					TextDrawHideForPlayer(i, PUBGAreaTD);
					TextDrawHideForPlayer(i, PUBGAliveTD);
					TextDrawHideForPlayer(i, PUBGKillTD);
					SpawnPlayer(i);
					Iter_SafeRemove(PUBGPlayers, i, i);
				}
			}
			SendWarUpdate("PUBG Event ended now!");
			for (new i = 0; i < MAX_SLOTS; i++) {
				if (gLootExists[i] && gLootPUBG[i]) {
					AlterLootPickup(i);
				}
				if (gWeaponExists[i] && gWeaponPUBG[i]) {
					AlterWeaponPickup(INVALID_PLAYER_ID, i);
				}
			}
			PUBGStarted = false;
		}
	}

	SaveAllStats();
	return 1;
}

task voteKicks[10000]() {
	new admins = 0;
	foreach (new i: Player) {
		if (ComparePrivileges(i, CMD_MEMBER)) {
			admins ++;
		}
	}
	if (admins) return true;

	foreach (new i: Player) {
		if ((pVotesKick[i] / Iter_Count(Player) * 100) > 20.0
				&& pVotesKick[i] > 3) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_VOTE_KICK, PlayerInfo[i][PlayerName]);
			SetTimerEx("ApplyBan", 500, false, "i", i);
		}
	}
	return 1;
}

//Player Timer (sync player activity)
ptask PlayerUpdate[1000](playerid) {
	if (PlayerInfo[playerid][pSelecting]) {
		PlayerInfo[playerid][pTimeSpentInSelection] ++;
	}
	PlayerInfo[playerid][pLastPing] = GetPlayerPing(playerid);
	PlayerInfo[playerid][pLastPacketLoss] = NetStats_PacketLossPercent(playerid);
	if (IsPlayerSpawned(playerid) && !PlayerInfo[playerid][pSelecting]) {
		foreach (new x: Player) {
			if (GetPlayerState(x) == PLAYER_STATE_SPECTATING && PlayerInfo[x][pSpecId] == playerid
				&& ComparePrivileges(x, CMD_MEMBER) && !Iter_Contains(PUBGPlayers, x))
			{
				new str[SMALL_STRING_LEN];

				format(str, sizeof(str), "%s[%d]",
					PlayerInfo[playerid][PlayerName], playerid);

				PlayerTextDrawSetString(x, aSpecPTD[x][1], str);

				format(str, sizeof(str), "%s (%d)~n~Speed: %0.2f KM/H",
					ReturnWeaponName(GetPlayerWeapon(playerid)),
					 GetPlayerAmmo(playerid), GetPlayerSpeed(playerid));

				PlayerTextDrawSetString(x, aSpecPTD[x][2], str);

				PlayerTextDrawShow(x, aSpecPTD[x][0]);
				PlayerTextDrawShow(x, aSpecPTD[x][1]);
				PlayerTextDrawShow(x, aSpecPTD[x][2]);
			}
		}

		if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
			PlayerInfo[playerid][pTimeSpentInCar] ++;
		}

		if (GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
			PlayerInfo[playerid][pTimeSpentOnFoot] ++;
	        if (!ComparePrivileges(playerid, CMD_MEMBER)) {
	        	if (GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK && !(p_ClassAbilities(playerid, JETTROOPER))) {
	        		AntiCheatAlert(playerid, "Jetpack Spawner");

	        		new Float: X, Float: Y, Float: Z;
	        		GetPlayerPos(playerid, X, Y, Z);
	        		SetPlayerPos(playerid, X, Y, Z + 5.0);
	        	}
		    }
		}

		if (GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) {
			PlayerInfo[playerid][pTimeSpentAsPassenger] ++;
		}

		if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
			new vid = GetPlayerVehicleID(playerid);
			if (vid) {
				new Float: X, Float: Y, Float: Z;
				GetVehicleVelocity(vid, X, Y, Z);
				if (floatround(floatsqroot(X * X + Y * Y) * 200, floatround_round) > 300) {
					AntiCheatAlert(playerid, "Vehicle Speed Hack");
					SetVehicleToRespawn(GetPlayerVehicleID(playerid));
				}
			}

			CheckTarget(playerid);

			if (gInvisible[playerid] && gInvisibleTime[playerid] < gettime()) {
				gInvisible[playerid] = false;
				SetPlayerMarkerVisibility(playerid, 0xFF);
			}

			if (gInvisible[playerid]) {
				gInvisible[playerid] = false;
				UpdateLabelText(playerid);
			}

			RechargeAAC(playerid);

			if (PlayerInfo[playerid][pBackup] != INVALID_PLAYER_ID && pBackupResponded[playerid] == 1) {
				if (gBackupTimer[playerid] > gettime()) {
					if (pVerified[PlayerInfo[playerid][pBackup]]) {
						switch (gBackupHighlight[playerid]) {
							case 0: SetPlayerMarkerForPlayer(playerid, PlayerInfo[playerid][pBackup], 0xFFFF00FF), gBackupHighlight[playerid] = 1;
							case 1: SetPlayerMarkerForPlayer(playerid, PlayerInfo[playerid][pBackup], Team_GetColor(Team_GetPlayer(PlayerInfo[playerid][pBackup]))), gBackupHighlight[playerid] = 0;
						}

						new Float: X, Float: Y, Float: Z;
						GetPlayerPos(PlayerInfo[playerid][pBackup], X, Y, Z);
						if (IsPlayerInRangeOfPoint(playerid, 15.0, X, Y, Z)) {
							SendGameMessage(playerid, X11_SERV_INFO, MSG_DEST_REACHED);
							pBackupResponded[playerid] = 0;
							SetPlayerMarkerForPlayer(playerid, PlayerInfo[playerid][pBackup], Team_GetColor(Team_GetPlayer(PlayerInfo[playerid][pBackup])));
							PlayerInfo[playerid][pBackup] = INVALID_PLAYER_ID;
						}
					}
				} else {
					foreach (new x: Player) {
						if (PlayerInfo[x][pBackup] == playerid) {
							SendGameMessage(x, X11_SERV_INFO, MSG_DEST_LOST);

							pBackupResponded[x] = 0;
							SetPlayerMarkerForPlayer(playerid, PlayerInfo[playerid][pBackup], Team_GetColor(Team_GetPlayer(PlayerInfo[playerid][pBackup])));
							PlayerInfo[x][pBackup] = INVALID_PLAYER_ID;
						}
					}
				}
			}
			else {
				PlayerInfo[playerid][pBackup] = INVALID_PLAYER_ID;
			}
		}

		if (GetPlayerPing(playerid) > PlayerInfo[playerid][pHighestPing]) {
			PlayerInfo[playerid][pHighestPing] = GetPlayerPing(playerid);
		}

		if (GetPlayerPing(playerid) < PlayerInfo[playerid][pLowestPing]) {
			PlayerInfo[playerid][pLowestPing] = GetPlayerPing(playerid);
		}

		if (GetPlayerPing(playerid) >= svtconf[max_ping] + 300 && svtconf[max_ping_kick] == 1 && !ComparePrivileges(playerid, CMD_OWNER)) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_35x, PlayerInfo[playerid][PlayerName]);
			Kick(playerid);
		}

		if (GetPlayerCameraMode(playerid) == 53) {
			new Float:kLibPos[3];
			GetPlayerCameraPos(playerid, kLibPos[0], kLibPos[1], kLibPos[2]);
			if (kLibPos[2] < -50000.0 || kLibPos[2] > 50000.0) {
				AntiCheatAlert(playerid, "Player Crasher");
				Kick(playerid);
				return 0;
			}
		}

		if (AntiSK[playerid] && AntiSKStart[playerid] <= gettime()) {
			EndProtection(playerid);
		}

		if ((GetTickCount() - PlayerInfo[playerid][pLastSync]) > 6500
				&& !PlayerInfo[playerid][pIsAFK])
		{
			 PlayerInfo[playerid][pAFKTick] = gettime();
			 PlayerInfo[playerid][pIsAFK] = 1;
			 UpdateLabelText(playerid);
			 DogfightCheckStatus(playerid);
			 return 1;
		}

		if (PlayerInfo[playerid][pIsAFK]) {
			if ((GetTickCount() - PlayerInfo[playerid][pLastSync]) < 3000) {
				PlayerInfo[playerid][pIsAFK] = 0;

				PlayerInfo[playerid][pTimeSpentAFK] += gettime() - PlayerInfo[playerid][pAFKTick];
				PlayerInfo[playerid][pAFKTick] = 0;
				UpdateLabelText(playerid);
			}
		}

		if (pDuelInfo[playerid][pDInMatch] && !pDuelInfo[playerid][pDLocked]
			&& TargetOf[playerid] != INVALID_PLAYER_ID) {
			if (pDuelInfo[playerid][pDCountDown] < gettime()) {
				pDuelInfo[playerid][pDInMatch] = 0;
				pDuelInfo[TargetOf[playerid]][pDInMatch] = 0;

				SendGameMessage(playerid, X11_SERV_INFO, MSG_DUEL_TIME_UP);
				SendGameMessage(TargetOf[playerid], X11_SERV_INFO, MSG_DUEL_TIME_UP);

				GivePlayerCash(playerid, -pDuelInfo[playerid][pDBetAmount]);
				GivePlayerCash(TargetOf[playerid], -pDuelInfo[playerid][pDBetAmount]);

				PlayerInfo[playerid][pDuelsLost]++;
				PlayerInfo[TargetOf[playerid]][pDuelsLost]++;

				SpawnPlayer(playerid);
				SpawnPlayer(TargetOf[playerid]);

				pDuelInfo[TargetOf[playerid]][pDLocked] =
				pDuelInfo[TargetOf[playerid]][pDInMatch] =
				pDuelInfo[TargetOf[playerid]][pDWeapon] =
				pDuelInfo[TargetOf[playerid]][pDAmmo] =
				pDuelInfo[TargetOf[playerid]][pDMatchesPlayed] =
				pDuelInfo[TargetOf[playerid]][pDRematchOpt] =
				pDuelInfo[TargetOf[playerid]][pDBetAmount] = 0;

				TargetOf[TargetOf[playerid]] = INVALID_PLAYER_ID;
				TargetOf[playerid] = INVALID_PLAYER_ID;
			} else if (!pDuelInfo[playerid][pDLocked]) {
				new string[25];
				format(string, sizeof(string), "~w~Time left: ~r~%d", pDuelInfo[playerid][pDCountDown] - gettime());
				NotifyPlayer(playerid, string);
				NotifyPlayer(TargetOf[playerid], string);
			}
		}

		if (PlayerInfo[playerid][pJailed] == 1 && gettime() > PlayerInfo[playerid][pJailTime]) {
			PlayerInfo[playerid][pJailed] = 0;
			SpawnPlayer(playerid);

			SendGameMessage(playerid, X11_SERV_INFO, MSG_UNJAILED_PLAYER);
		}

		if (TargetOf[playerid] != INVALID_PLAYER_ID || pDuelInfo[playerid][pDLocked]) {
			if (!pDuelInfo[playerid][pDInMatch] && pDuelInfo[playerid][pDInvitePeriod] < gettime()) {
				pDuelInfo[playerid][pDInMatch] = 0;
				pDuelInfo[playerid][pDLocked] = 0;
				TargetOf[playerid] = INVALID_PLAYER_ID;
			}
		}

		if (PlayerInfo[playerid][pIsAFK] == 1) {
			if ((GetTickCount() - PlayerInfo[playerid][pLastSync]) > 5000) {
				new String[25];
				Update3DTextLabelText(RankLabel[playerid], 0xD6588CFF, " ");

				format(String, sizeof(String), "AFK (%d)", gettime() - PlayerInfo[playerid][pAFKTick]);
				Update3DTextLabelText(RankLabel[playerid], 0xFF0000CC, String);
			}
		}

		if (pDogfightTarget[playerid] != INVALID_PLAYER_ID && !pDogfightCD[playerid]) {
			if (!IsPlayerInAnyVehicle(playerid) || (GetVehicleModel(GetPlayerVehicleID(playerid)) != 476 &&
				GetVehicleModel(GetPlayerVehicleID(playerid)) != 520)) {
					DogfightCheckStatus(playerid);
			} else {
				if (gettime() > pDogfightTime[playerid]) {
					GameTextForPlayer(playerid, "~r~TIME'S UP!", 3000, 3);
					GameTextForPlayer(pDogfightTarget[playerid], "~r~TIME'S UP!", 3000, 3);
					pDogfightTarget[pDogfightTarget[playerid]] = INVALID_PLAYER_ID;
					pDogfightTarget[playerid] = INVALID_PLAYER_ID;
				} else {
					new string[25];
					format(string, sizeof(string), "~w~Time left: ~r~%d", pDogfightTime[playerid] - gettime());
					NotifyPlayer(playerid, string);
				}
			}
		}
	}

	if ((Iter_Contains(ePlayers, playerid) && EventInfo[E_ALLOWLEAVECARS] == 0
		&& !IsPlayerInAnyVehicle(playerid) && !EventInfo[E_OPENED]) || (pRaceId[playerid] != -1 &&
			RaceStarted[pRaceId[playerid]] && !RaceOpened[pRaceId[playerid]] && !IsPlayerInAnyVehicle(playerid))) {
		if (pEventInfo[playerid][P_CARTIMER]) {
			pEventInfo[playerid][P_CARTIMER]--;
			new string[25];
			format(string, sizeof(string), "~r~%d", pEventInfo[playerid][P_CARTIMER]);
			GameTextForPlayer(playerid, string, 1000, 3);
			if (pEventInfo[playerid][P_CARTIMER] <= 0) {
				pRaceId[playerid] = -1;
				SpawnPlayer(playerid);
			}
		}
	}
	return 1;
}

forward SwitchTeam(playerid);
forward RebuildAntenna(playerid);
forward OnNukeLaunch(playerid, base);
forward OnNukeFinish(base);
forward EndFirstSpawn(playerid);
forward StopAlarm(playerid);
forward RegenerateToxic(cropid);
forward AnthraxToxication(playerid, X, Y, Z);
forward Balloon();

//Balloon

public Balloon() {
	if (bRouteCoords == 0) {
		ballonDestination = 0;
		bRouteCoords ++;
		MoveDynamicObject(ballonObjectId, ballonRouteArray[bRouteCoords][0], ballonRouteArray[bRouteCoords][1], ballonRouteArray[bRouteCoords][2], 15.0);
	} else {
		ballonDestination = 1;
		bRouteCoords -= 2;
		MoveDynamicObject(ballonObjectId, ballonRouteArray[bRouteCoords][0], ballonRouteArray[bRouteCoords][1], ballonRouteArray[bRouteCoords][2], 15.0);
	}
	return 1;
}

//Anthrax gas

public RegenerateToxic(cropid) {
	new rockets[30];
	CropAnthrax[cropid][Anthrax_Rockets] ++;
	format(rockets, 30, "Anthrax Cropduster\n[%d/4]", CropAnthrax[cropid][Anthrax_Rockets]);
	UpdateDynamic3DTextLabelText(CropAnthrax[cropid][Anthrax_Label], X11_CADETBLUE, rockets);
	return 1;
}

//Anthrax Intoxication

public AnthraxToxication(playerid, X, Y, Z) {
	if (-- PlayerInfo[playerid][pAnthraxTimes] > 0) {
		foreach (new i: Player) {
			new Float: r = 35.0;
			if (PlayerInfo[playerid][pDonorLevel]) { r = 45.0; }
			if (IsPlayerInRangeOfPoint(i, r, X, Y, Z) && GetPlayerState(i) == PLAYER_STATE_ONFOOT && i != playerid) {
				new Float: HP;
				GetPlayerHealth(i, HP);

				if (HP <= 5.2) {
					GameTextForPlayer(i, MSG_ANTHRAX_DEAD, 5000, 3);
					DamagePlayer(i, 0.0, playerid, WEAPON_TEARGAS, BODY_PART_UNKNOWN, true);
					SendGameMessage(playerid, X11_SERV_INFO, MSG_INTOXICATE_BONUS, PlayerInfo[i][PlayerName], i);
					GivePlayerScore(playerid, 3);
					if (IsPlayerInAnyClan(playerid)) {
						if (pClan[playerid] != pClan[i]) {
							AddClanXP(GetPlayerClan(playerid), 3);
							foreach (new x: Player) {
								if (pClan[x] == pClan[playerid]) {
									SendGameMessage(x, X11_SERV_INFO, MSG_INTOXICATION_CLAN_BONUS, GetPlayerClan(playerid), PlayerInfo[playerid][PlayerName]);
								}
							}
						}
					}
				} else {
					new Float: dmg = 0.0;
					if (!IsPlayerAttachedObjectSlotUsed(i, 3)
						&& !Items_GetPlayer(i, MASK)) {
						dmg = 12.5;
						GameTextForPlayer(i, MSG_ANTHRAX_12HP, 1000, 3);
					} else {
						dmg -= 5.2;
						GameTextForPlayer(i, MSG_ANTHRAX_5HP,  1000, 3);
					}
					DamagePlayer(i, dmg, playerid, WEAPON_TEARGAS, BODY_PART_UNKNOWN, true);
				}
			}
		}

		PlayerInfo[playerid][pAnthraxTimer] = SetTimerEx("AnthraxToxication", 500, false, "ifff", playerid, X, Y, Z);
	} else {
		for (new i = 0; i < 17; i++) {
			if (IsValidDynamicObject(PlayerInfo[playerid][pAnthraxEffects][i])) {
				DestroyDynamicObject(PlayerInfo[playerid][pAnthraxEffects][i]);
			}
			PlayerInfo[playerid][pAnthraxEffects][i] = INVALID_OBJECT_ID;
		}

		foreach(new i: Player) {
			if (IsPlayerInRangeOfPoint(i, 35.0, X, Y, Z)) {
				GameTextForPlayer(i, MSG_TOXICATION_EXPIRED, 1000, 3);
			}
		}

		KillTimer(PlayerInfo[playerid][pAnthraxTimer]);
	}
	return 1;
}


//Stop alarms
public StopAlarm(playerid) {
	PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
	return 1;
}


//Finish a player's first spawn
public EndFirstSpawn(playerid) {
	pFirstSpawn[playerid] = 0;

	PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
	RemoveObjectsForPlayer(playerid);

	if (IsPlayerInAnyClan(playerid)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLAN_MOTD, GetClanMotd(GetPlayerClan(playerid)));
	}
	return 1;
}

//Player switching team (used for the timer)
public SwitchTeam(playerid) {
	SendGameMessage(playerid, X11_SERV_INFO, MSG_SWITCH_TEAM);
	new i = Team_GetPlayer(playerid);
	Team_AddPlayerToBalanced(playerid);
	if (i != Team_GetPlayer(playerid)) {
		ForceClassSelection(playerid);
		SetPlayerHealth(playerid, 0.0);
		UpdatePlayerHUD(playerid);
	} else {
		SendGameMessage(playerid, X11_SERV_ERR, MSG_ERR_CANT_CHANGE_TEAM);
	}
	return 1;
}

//A player fixed their team's radio antenna.. Nice?
public RebuildAntenna(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return 0;
	foreach (new i: teams_loaded) {
		if (i == Team_GetPlayer(playerid)) {
			if (IsPlayerInRangeOfPoint(playerid, 20.0, AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2])) {
				if (AntennaInfo[i][Antenna_Exists] == 0 && AntennaInfo[i][Antenna_Kill_Time] > gettime()) {
					AntennaInfo[i][Antenna_Exists] = 1;
					AntennaInfo[i][Antenna_Hits] = 0;

					SetDynamicObjectPos(AntennaInfo[i][Antenna_Id], AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2]);
					
					new update[SMALL_STRING_LEN];
					format(update, sizeof(update), MSG_SERVER_37x, PlayerInfo[playerid][PlayerName], Team_GetName(i));
					SendWarUpdate(update);

					SendGameMessage(playerid, X11_SERV_INFO, MSG_ANTENNA_REPAIRED);
					GivePlayerScore(playerid, 4);

					new title[140];

					format(title, sizeof(title), "%s\n"IVORY"Radio Antenna", Team_GetName(i));
					UpdateDynamic3DTextLabelText(AntennaInfo[i][Antenna_Label], Team_GetColor(i), title);
				}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_ANTENNA_NOT_DESTROYED);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_ANTENNA_TOO_FAR);
		}
	}
	return 1;
}

//Nuke is directly related to the team system so putting it in this module is logical, no teams, no nuke, right?
public OnNukeLaunch(playerid, base) {
	nukePlayerId = INVALID_PLAYER_ID;

	new count = 0;

	SetWeather(19);
	SendWarUpdate("~g~Nuclear systems launched.");
	LogActivity(playerid, "Launched nuke [base: %d]", gettime(), base);

	GangZoneFlashForAll(Zones_GetTeamGangZone(base), ALPHA(X11_IVORY, 100));

	UpdateDynamic3DTextLabelText(nukeRemoteLabel, 0xFFFFFFFF, "Nuke\n{FF0000}Offline");

	SetTimerEx("OnNukeFinish", 9000, false, "i", base);

	new Float: X, Float: Y, Float: Z;
	GetAreaCenter(Team_GetMapArea(Team_GetPlayer(playerid), 0), Team_GetMapArea(Team_GetPlayer(playerid), 1), Team_GetMapArea(Team_GetPlayer(playerid), 2), Team_GetMapArea(Team_GetPlayer(playerid), 3), X, Y);
	CA_FindZ_For2DCoord(X, Y, Z);
	CreateAirstrike(playerid, X, Y, Z);

	RandPosInArea(Team_GetMapArea(Team_GetPlayer(playerid), 0), Team_GetMapArea(Team_GetPlayer(playerid), 1), Team_GetMapArea(Team_GetPlayer(playerid), 2), Team_GetMapArea(Team_GetPlayer(playerid), 3), X, Y);
	CA_FindZ_For2DCoord(X, Y, Z);
	CreateAirstrike(playerid, X, Y, Z);

	RandPosInArea(Team_GetMapArea(Team_GetPlayer(playerid), 0), Team_GetMapArea(Team_GetPlayer(playerid), 1), Team_GetMapArea(Team_GetPlayer(playerid), 2), Team_GetMapArea(Team_GetPlayer(playerid), 3), X, Y);
	CA_FindZ_For2DCoord(X, Y, Z);
	CreateAirstrike(playerid, X, Y, Z);

	if (count) {
		SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_7x, PlayerInfo[playerid][PlayerName], count);
	}
	return 1;
}

//If the nuke finished, return stuff to their normal state.. :D
public OnNukeFinish(base) {
	SetWeather(0);
	GangZoneStopFlashForAll(Zones_GetTeamGangZone(base));
	return 1;
}

//Selection Progress
ShowPlayerBasicSUI(playerid) {
	TextDrawShowForPlayer(playerid, selectdraw_0);
	TextDrawShowForPlayer(playerid, selectdraw_1);
	SetPlayerProgressBarValue(playerid, Player_SelectionBar[playerid], 0.0);
	ShowPlayerProgressBar(playerid, Player_SelectionBar[playerid]);
	return 1;
}

UpdatePlayerSUI1(playerid) {
	SetPlayerProgressBarValue(playerid, Player_SelectionBar[playerid], 50.0);
	ShowPlayerProgressBar(playerid, Player_SelectionBar[playerid]);
	new team_style[40];
	format(team_style, sizeof(team_style), "%s%s", Team_GetGTColor(Team_GetPlayer(playerid)), Team_GetName(Team_GetPlayer(playerid)));
	PlayerTextDrawSetString(playerid, selectdraw_3[playerid],  team_style);
	PlayerTextDrawShow(playerid, selectdraw_3[playerid]);
	return 1;
}

UpdatePlayerSUI2(playerid) {
	SetPlayerProgressBarValue(playerid, Player_SelectionBar[playerid], 100.0);
	ShowPlayerProgressBar(playerid, Player_SelectionBar[playerid]);
	new class_weapons[MEDIUM_STRING_LEN];
	format(class_weapons, sizeof(class_weapons), "~y~~h~%s, %s, %s, %s~n~(they will replace yours)~n~~g~(%s at %s)",
	ReturnWeaponName(Class_GetWeapon(Class_GetPlayerClass(playerid))),
	ReturnWeaponName(Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 0)),
	ReturnWeaponName(Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 1)),
	ReturnWeaponName(Class_GetOtherWeapon(Class_GetPlayerClass(playerid), 2)),
	Class_GetType(Class_GetPlayerClass(playerid)) == 0 ? "Interior" : "Exterior",
	Class_GetAreaName(Class_GetPlayerClass(playerid)));
	PlayerTextDrawSetString(playerid, selectdraw_5[playerid],  class_weapons);
	PlayerTextDrawSetString(playerid, selectdraw_4[playerid],  Class_GetAbilityNames(Class_GetPlayerClass(playerid)));
	PlayerTextDrawSetString(playerid, selectdraw_6[playerid],  Class_GetAbilityFeatures(Class_GetPlayerClass(playerid)));
	PlayerTextDrawShow(playerid, selectdraw_4[playerid]);
	PlayerTextDrawShow(playerid, selectdraw_5[playerid]);
	PlayerTextDrawShow(playerid, selectdraw_6[playerid]);
	return 1;
}

HidePlayerSUI(playerid) {
	HidePlayerProgressBar(playerid, Player_SelectionBar[playerid]);
	TextDrawHideForPlayer(playerid, selectdraw_0);
	TextDrawHideForPlayer(playerid, selectdraw_1);
	PlayerTextDrawHide(playerid, selectdraw_3[playerid]);
	PlayerTextDrawHide(playerid, selectdraw_4[playerid]);
	PlayerTextDrawHide(playerid, selectdraw_5[playerid]);
	PlayerTextDrawHide(playerid, selectdraw_6[playerid]);
	return 1;
}

//Rope Rappelling
CreateRope(playerid, numropes) {
	new Float:Angle;
	GetPlayerFacingAngle(playerid, Angle);

	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	PlayerInfo[playerid][pRopeRappels] ++;

	for (new i = 0; i < numropes; i++) {
		pRope[playerid][RopeID][i] = CreateDynamicObject(19089, pRope[playerid][RRX], pRope[playerid][RRY], pRope[playerid][RRZ]- 2.6 - (i * 5.1), 0, 0, Angle);
	}
}

//Is the player in his base's area?
IsPlayerInBase(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return 0;
	new InBase = 0;

	foreach (new i: teams_loaded) {
		if (Team_GetPlayer(playerid) == i) {
			if (IsPlayerInDynamicArea(playerid, Team_GetArea(Team_GetPlayer(playerid)))) {
				InBase = 1;
			}
		}
	}

	return InBase;
}

//Team War System

//Tell the player they won the war?
NotifyTW(playerid) {
	return NotifyPlayer(playerid, "~g~Your team won the team war!");
}

forward HideTW();
public HideTW() {
	TextDrawHideForAll(WarTD);
	return 1;
}

//Check if a team won the war
TeamWarWinCheck() {
	if (WarInfo[War_Started] == 1 && (gettime() >= war_time || WarInfo[Team1_Score] >= WarInfo[War_Score] || WarInfo[Team2_Score] >= WarInfo[War_Score])) {
		WarInfo[War_Started] = 0;
		if (WarInfo[Team1_Score] > WarInfo[Team2_Score]) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_44x, Team_GetName(WarInfo[War_Team1]), Team_GetName(WarInfo[War_Team2]));
			foreach (new i: Player) {
				if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == WarInfo[War_Team1]) {
					SuccessAlert(i);
					NotifyTW(i);
				}
			}
			new string[128];
			format(string, sizeof(string), "%s%s ~w~won the war [s: %d]!", Team_GetGTColor(WarInfo[War_Team1]), Team_GetName(WarInfo[War_Team1]), WarInfo[Team1_Score]);
			TextDrawSetString(WarTD, string);
		} else if (WarInfo[Team2_Score] > WarInfo[Team1_Score]) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_44x, Team_GetName(WarInfo[War_Team2]), Team_GetName(WarInfo[War_Team1]));
			foreach (new i: Player) {
				if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == WarInfo[War_Team2]) {
					SuccessAlert(i);
					NotifyTW(i);
				}
			}
			new string[128];
			format(string, sizeof(string), "%s%s ~w~won the war [s: %d]!", Team_GetGTColor(WarInfo[War_Team2]), Team_GetName(WarInfo[War_Team2]), WarInfo[Team2_Score]);
			TextDrawSetString(WarTD, string);
		} else SendClientMessageToAll(X11_WINE, "There's no team that actually managed to win the war!");
		foreach (new i: Player) {
			if (IsPlayerInMode(i, MODE_BATTLEFIELD)) {
				TextDrawShowForPlayer(i, WarTD);
			}
		}
		SetTimer("HideTW", 3000, false);
	}
	return 1;
}

//Update team war information for player(s)
UpdateTeamWarInfo() {
	if (WarInfo[War_Started]) {
		new war_str[165];
		format(war_str, sizeof(war_str), "Team War: %s%s [%d] ~w~VS %s[%d] %s", Team_GetGTColor(WarInfo[War_Team1]), Team_GetName(WarInfo[War_Team1]),
		WarInfo[Team1_Score], Team_GetGTColor(WarInfo[War_Team2]), WarInfo[Team2_Score], Team_GetName(WarInfo[War_Team2]));
		SendWarUpdate(war_str);
	}
	return 1;
}

//Reward player for team war
AddTeamWarScore(playerid, Score, Mode) {
	if (WarInfo[War_Started] && WarInfo[War_Target] == Mode) {
		if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return 0;
		if (Team_GetPlayer(playerid) == WarInfo[War_Team1]) {
			WarInfo[Team1_Score] += Score;
			SendGameMessage(playerid, X11_SERV_INFO, MSG_TEAMWAR_PROGRESS, Score);
		}
		else if (Team_GetPlayer(playerid) == WarInfo[War_Team2]) {
			WarInfo[Team2_Score] += Score;
			SendGameMessage(playerid, X11_SERV_INFO, MSG_TEAMWAR_PROGRESS, Score);
		}
		UpdateTeamWarInfo();
	}
	if (WarInfo[War_Started]) {
		TeamWarWinCheck();
	}
	return 1;
}

//Briefcase, isn't this a team feature too?

ShowItemsDialog(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendClientMessage(playerid, X11_WINE, "You can't do that out of the battlefield!");
	inline BriefcaseItems(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return ShowBriefcase(pid);
		ShowItemsDialog(pid);
		ApplyActorAnimation(ShopActors[Team_GetPlayer(pid)], "DEALER", "DEALER_DEAL", 3.0, 0, 0, 0, 0, 0);
		if (GetPlayerCash(pid) < Items_GetPrice(listitem)) return PlayerPlaySound(pid, 1055, 0.0, 0.0, 0.0), SendGameMessage(pid, X11_SERV_ERR, MSG_ITEM_CNT_AFFRD, Items_GetName(listitem), formatInt(Items_GetPrice(listitem) - GetPlayerCash(playerid)));
		if (Items_GetPlayer(pid, listitem) >= Items_GetMax(listitem)) return SendGameMessage(pid, X11_SERV_ERR, MSG_ITEM_NO_MORE, Items_GetName(listitem));
		Items_SavePlayer(pid, listitem, 1);
		SendGameMessage(pid, X11_SERV_SUCCESS, MSG_ITEM_PD, Items_GetName(listitem));
		GivePlayerCash(pid, -Items_GetPrice(listitem));
		PlayerPlaySound(pid, 1054, 0.0, 0.0, 0.0);
	}
	new buf[LARGE_STRING_LEN];
	strcat(buf, "Item\tCost($)\tInfo\n");
	for (new i = 0; i < MAX_ITEMS; i++) {
		format(buf, sizeof(buf), "%s"YELLOW"%s\t%s\t%s (You have: "RED"%d "YELLOW"(+1) "WHITE"| Max: "RED"%d"WHITE")\n",
		buf, Items_GetName(i), formatInt(Items_GetPrice(i)), Items_GetInfo(i), Items_GetPlayer(playerid, i), Items_GetMax(i));
	}
	Dialog_ShowCallback(playerid, using inline BriefcaseItems, DIALOG_STYLE_TABLIST_HEADERS, "Items Store", buf, ">>", "<<");
	return 1;
}

ShowWeaponDialog(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendClientMessage(playerid, X11_WINE, "You can't do that out of the battlefield!");
	new weapons_str[100], overall[2048], weapon_listitem[MAX_WEAPONS], total_weapons;

	foreach (new i: allowed_weapons) {
		format(weapons_str, sizeof(weapons_str), "%s\t%d Ammo\t%s\n", ReturnWeaponName(i), Weapons_GetAmmo(i), formatInt(Weapons_GetPrice(i)));
		strcat(overall, weapons_str);
		weapon_listitem[total_weapons] = i;
		total_weapons ++;
	}

	inline BriefcaseWeapons(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		ApplyActorAnimation(ShopActors[Team_GetPlayer(pid)], "DEALER", "DEALER_DEAL", 3.0, 0, 0, 0, 0, 0);
		if (!response) return ShowBriefcase(pid);
		if (Weapons_GetPrice(weapon_listitem[listitem]) > GetPlayerCash(pid)) return PlayerPlaySound(pid, 1053, 0.0, 0.0, 0.0), SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_231x);
		SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_235x, ReturnWeaponName(weapon_listitem[listitem]), formatInt(Weapons_GetPrice(weapon_listitem[listitem])));
		GivePlayerCash(pid, -Weapons_GetPrice(weapon_listitem[listitem]));
		GivePlayerWeapon(pid, weapon_listitem[listitem], Weapons_GetAmmo(weapon_listitem[listitem]));
		ShowWeaponDialog(pid);
		PlayerPlaySound(pid, 1052, 0.0, 0.0, 0.0);
		Weapons_SavePlayer(pid, weapon_listitem[listitem], Weapons_GetAmmo(weapon_listitem[listitem]));
		
	}

	Dialog_ShowCallback(playerid, using inline BriefcaseWeapons, DIALOG_STYLE_TABLIST, ""WINE"SvT - Weapons Store", overall, ">>", "<<");
	return 1;
}

ShowBriefcase(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendClientMessage(playerid, X11_WINE, "You can't do that out of the battlefield!");
	inline BriefcaseEnhancements(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return ShowBriefcase(pid);
		switch (listitem) {
			case 0: {
				ApplyActorAnimation(ShopActors[Team_GetPlayer(pid)], "DEALER", "DEALER_DEAL", 3.0, 0, 0, 0, 0, 0);
				if (GetPlayerCash(pid) < 25000) return PlayerPlaySound(pid, 1055, 0.0, 0.0, 0.0), SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_243x);
				if (pKatanaEnhancement[pid]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_244x);
				pKatanaEnhancement[pid] = 10;
				GivePlayerWeapon(pid, WEAPON_KATANA, 1);
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_245x);
				GivePlayerCash(pid, -25000);
				PlayerPlaySound(pid, 1057, 0.0, 0.0, 0.0);
			}
		}
	}
	inline Briefcase(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_246x);
		switch (listitem) {
			case 0: {
				ApplyActorAnimation(ShopActors[Team_GetPlayer(pid)], "DEALER", "DEALER_DEAL", 3.0, 0, 0, 0, 0, 0);
				if (ReturnHealth(pid) >= 100.0) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_247x);
				if (GetPlayerCash(pid) < 5000) return PlayerPlaySound(pid, 1055, 0.0, 0.0, 0.0), SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_248x);

				SetPlayerHealth(pid, 100.0);
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_542x);
				GivePlayerCash(pid, -5000);
				PlayerPlaySound(pid, 1057, 0.0, 0.0, 0.0);
				ShowBriefcase(pid);
			}
			case 1: {
				new Float: AR;
				GetPlayerArmour(pid, AR);
				ApplyActorAnimation(ShopActors[Team_GetPlayer(pid)], "DEALER", "DEALER_DEAL", 3.0, 0, 0, 0, 0, 0);
				if (AR >= 100.0) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_543x);
				if (GetPlayerCash(pid) < 5000) return PlayerPlaySound(pid, 1055, 0.0, 0.0, 0.0), SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_249x);
				SetPlayerArmour(pid, 100.0);
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_251x);
				GivePlayerCash(pid, -5000);
				PlayerPlaySound(pid, 1057, 0.0, 0.0, 0.0);
				ShowBriefcase(pid);
			}
			case 2: {
				ApplyActorAnimation(ShopActors[Team_GetPlayer(pid)], "DEALER", "DEALER_DEAL", 3.0, 0, 0, 0, 0, 0);
				ShowWeaponDialog(pid);
			}
			case 3: {
				ShowItemsDialog(pid);
			}
			case 4: {
				Dialog_ShowCallback(pid, using inline BriefcaseEnhancements, DIALOG_STYLE_TABLIST_HEADERS, ""WINE"SvT - Enhancements",
					"Enhancement\tPrice\n\
					Katana Insta-kill\t"GREEN"$25,000",
					">>", "<<");
			}
		}
	}
	Dialog_ShowCallback(playerid, using inline Briefcase, DIALOG_STYLE_TABLIST_HEADERS, ""WINE"SvT - Team Briefcase",
		"Option\tPrice\n\
		Regenerate Health\t"GREEN"$5,000\n\
		Purchase Armour\t"GREEN"$5,000\n\
		Weapons Store\n\
		Items Store\n\
		Enhancements", ">>", "X");
	ApplyActorAnimation(ShopActors[Team_GetPlayer(playerid)], "DEALER", "DEALER_DEAL", 3.0, 0, 0, 0, 0, 0);
	return 1;
}

//Balloon
MoveBalloon() {
	if (!ballonDestination) {
		bRouteCoords ++;
	} else {
		bRouteCoords --;
	}
	if (bRouteCoords == sizeof(ballonRouteArray)) {
		SetTimer("Balloon", 20000, false);
	} else {
		if (bRouteCoords != -1) {
			MoveDynamicObject(ballonObjectId, ballonRouteArray[bRouteCoords][0], ballonRouteArray[bRouteCoords][1], ballonRouteArray[bRouteCoords][2], 15.0);
		} else {
			bRouteCoords = 0;
		}
	}
	return 1;
}

//Load PUBG item positions from file
LoadPUBGArray(const loot_file[45])
{
	new File:handle = fopen(loot_file, io_read), buf[40];
	if (handle)
	{
		while (fread(handle, buf))
		{
			if (sscanf(buf, "p<,>ffff", PUBGArray[_loaded_pubg_items][0], PUBGArray[_loaded_pubg_items][1], PUBGArray[_loaded_pubg_items][2], PUBGArray[_loaded_pubg_items][3]))
			{
				printf("PUBG Item (id:%d) failed to load.", _loaded_pubg_items + 1);
			}
			_loaded_pubg_items ++;
		}
		printf("Read %d PUBG Items from %s", _loaded_pubg_items, loot_file);
		fclose(handle);
	} else printf("File %s does not exist", loot_file);
	return 1;
}

//Our nice entry point

main() {
	print(" ");
	printf("-> Loading SWAT vs Terrorists v%d.%d.%d", LEGACY_TDM_VERSION_MAJOR, LEGACY_TDM_VERSION_MINOR, LEGACY_TDM_VERSION_PATCH);
	print(" ");
}

public OnGameModeInit() {
	//Initialization time
	new Success = GetTickCount();

	//*************************************************************************************//
	//							SWAT vs Terrorists DATABASE CONFIG  					   //
	//										SET CORE									   //
	//*************************************************************************************//

	new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	Database = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id);
	if (Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0) {
		print("Invalid MySQL server... Restarting.");
		return SendRconCommand("exit");
	} else {
		print("MySQL Connection Successful");
	}

	//Reset CW Parties
	mysql_tquery(Database, "DELETE FROM `CWParties`");

	//Load forbidden lists
	mysql_tquery(Database, "SELECT * FROM `ForbiddenList` WHERE `Type` = 'Word'", "LoadForbiddenWords");
	mysql_tquery(Database, "SELECT * FROM `ForbiddenList` WHERE `Type` = 'Name'", "LoadForbiddenNames");
	/////////////////////////////////////////

	EVENTS_OnGameModeInit();

	//*************************************************************************************//
	//							SWAT vs Terrorists SERVER CONFIG  						   //
	//										LOAD CORE									   //
	//*************************************************************************************//

	//Conifg Defaults
	svtconf[kick_bad_nicknames] = 1,
	svtconf[anti_spam] = 1,
	svtconf[anti_swear] = 1,
	svtconf[anti_caps] = 0,
	svtconf[server_open] = 1,
	svtconf[disable_chat] = 0,
	svtconf[anti_adv] = 1,
	svtconf[max_ping] = 500,
	svtconf[max_ping_kick] = 1,
	svtconf[max_warns] = 3,
	svtconf[max_duel_bets] = 5000,
	svtconf[safe_restart] = 0;

	//Presets						 SWAT vs Terrorists [0.3.7]

	//SetWorldTime(20); //Set default hour
	SetWeather(0); //Set default weather
	SetVehiclePassengerDamage(true); //Allow vehicle passenger damage
	SetDisableSyncBugs(true); //Fix sync bugs
	SetRespawnTime(3000); //Player respawns in 3 seconds after death
	SetCbugAllowed(false);
	SetDamageFeed(true);
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_STREAMED);
	DisableInteriorEnterExits(); //No players going out of interiors
	//SetMaxConnections(5, e_FLOOD_ACTION_FBAN); //Limit connections
	//ToggleKnifeShootForAll(true);
	EnableStuntBonusForAll(false);
	UsePlayerPedAnims();
	Streamer_TickRate(60);
	Streamer_VisibleItems(STREAMER_TYPE_OBJECT, 650);
	SetNameTagDrawDistance(100.0);

	//Load toys from file
	toyslist = LoadModelSelectionMenu("toys.txt");

	clanskinlist = LoadModelSelectionMenu("clanskins.txt"); //Load the clan skin menu...
	//Why not create a separate file for clan skins?

	//Reset some things
	nukePlayerId = INVALID_PLAYER_ID;
	foreach (new i: Player) {
		for (new j = 0; j < MAX_ROPES; j++) {
			pRope[i][RopeID][j] = -1;
		}
	}

	for (new i = 0; i < MAX_SLOTS; i++) {
		KillTimer(gLandmineTimer[i]);
		KillTimer(gDynamiteTimer[i]);
		gLandmineExists[i] = 0;
		gLandminePos[i][0] = gLandminePos[i][1] = gLandminePos[i][2] = 0.0;
		gLandminePlacer[i] = INVALID_PLAYER_ID;
		gDynamiteExists[i] = 0;
		gDynamitePos[i][0] = gDynamitePos[i][1] = gDynamitePos[i][2] = 0.0;
		gDynamitePlacer[i] = INVALID_PLAYER_ID;
		gWeaponID[i] = 0;
		gWeaponAmmo[i] = 0;
		gWeaponExists[i] = 0;
		gWeaponPUBG[i] = 0;
		gWeaponPickable[i] = 0;
		gLootItem[i] = 0;
		gLootAmt[i] = 0;
		gLootPickable[i] = 0;
		KillTimer(gLootTimer[i]);
		gLootExists[i] = 0;
		gLootPUBG[i] = 0;
	}

	//Create teams
	Team_Create("Terrorists");
	Team_Create("SWAT");

	//Generate ranks
	Ranks_Generate();

	//Load classes
	Class_Load("classes.txt");

	//Load PUBG Items
	LoadPUBGArray("pubg_loot.txt");

	//Generate weapons
	Weapons_Generate();

	//Generate zones
	Zones_Generate();

	//Create our balloon
	ballonObjectId = CreateDynamicObject(19332, ballonRouteArray[0][0], ballonRouteArray[0][1], ballonRouteArray[0][2], 0.0, 0.0, 0.0);
	Balloon_Label = Create3DTextLabel("Air Balloon\nPress 'N' key to fly", 0xCC0000CC, ballonRouteArray[0][0], ballonRouteArray[0][1], ballonRouteArray[0][2] + 2.0, 50.0, 0);
	ballonDestination = 0;
	bRouteCoords = 0;
	Balloon_Timer = gettime();

	//Anthrax
	g_pickups[4] = CreatePickup(1254, 1, -356.8720,1588.9048,76.5136, -1); // Anthrax
	CreateDynamic3DTextLabel("*ANTHRAX SKULL*", X11_DEEPSKYBLUE, -356.8720,1588.9048,76.5136, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	//Nuke
	g_pickups[2] = CreatePickup(364, 1, -352.8720,1584.9048,76.5136, -1); // Nuke Pickup
	nukeRemoteLabel = CreateDynamic3DTextLabel("Nuke\n{00CC00}Online", 0xFFFFFFFF, -352.8720,1584.9048,76.5136, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	//Create an entrable area for both nuke and anthrax
	Anthrax_Area = CreateDynamicSphere(-356.8720,1588.9048,76.5136,5.0,BF_WORLD,0);
	Nuke_Area = CreateDynamicSphere(-352.8720,1584.9048,76.5136,5.0,BF_WORLD,0);

	for (new i = 0; i < sizeof(Interiors); i++) {
		Interiors[i][IntEnterPickup] = CreateDynamicPickup(1318, 1, Interiors[i][IntEnterPos][0], Interiors[i][IntEnterPos][1], Interiors[i][IntEnterPos][2]);
		Interiors[i][IntExitPickup] = CreateDynamicPickup(1318, 1, Interiors[i][IntExitPos][0], Interiors[i][IntExitPos][1], Interiors[i][IntExitPos][2]);
		Interiors[i][IntEnterLabel] = CreateDynamic3DTextLabel(Interiors[i][IntName], -1, Interiors[i][IntEnterPos][0], Interiors[i][IntEnterPos][1], Interiors[i][IntEnterPos][2], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);
		Interiors[i][IntExitLabel] = CreateDynamic3DTextLabel(Interiors[i][IntName], -1, Interiors[i][IntExitPos][0], Interiors[i][IntExitPos][1], Interiors[i][IntExitPos][2], 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0);
		if (Interiors[i][IntIco] != -1) {
			CreateDynamicMapIcon(Interiors[i][IntEnterPos][0], Interiors[i][IntEnterPos][1], Interiors[i][IntEnterPos][2], Interiors[i][IntIco], 0, 0, 0, -1, 450.0, MAPICON_LOCAL);
		}
	}

	CreateDynamicObject(18762, 272.3060, 1826.0844, 17.5088, 0.0, 0.0, 90.0);
	CreateDynamicObject(18762, 272.3060, 1825.5844, 17.5088, 0.0, 0.0, 90.0);

	//--------------------
	//Security Center

	//Camera
	gCameraId = CreateDynamicObject(1622, -185.50005, 1554.98340, 40.94810,   0.00000, -6.00000, 121.00000);
	CreateDynamicMapIcon(-185.50005, 1554.98340, 40.94810, 30, 0, 0, 0, -1, 450.0, MAPICON_LOCAL);


	//Watchroom Pickup
	gWatchRoom = CreateDynamicPickup(19130, 1, -259.4019, 1532.8566, 29.3609);
	CreateDynamic3DTextLabel("[ Watch Room ]", COLOR_TOMATO, -259.4019, 1532.8566, 29.3609, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	//------------------
	//Some whores

	new dance1 = CreateActor(87, 1213.8302,-30.2960,1000.9531,44.0354);
	new dance2 = CreateActor(140, 1208.5111,-27.6828,1000.9531,232.6639);
	new dance3 = CreateActor(91, 1206.5964,-35.4083,1000.9531,349.2249);
	new dance4 = CreateActor(90, 1209.0974,-35.5458,1001.4844,14.9186);
	new dance5 = CreateActor(178, 1209.6107,-38.5748,1001.4844,324.1581);
	new dance6 = CreateActor(246, 1213.0743,-39.9945,1001.4844,346.7183);
	new dance7 = CreateActor(244, 1212.0743,-37.9945,1001.4844,346.7183);
	new dance8 = CreateActor(245, 1206.2000,-30.3105,1000.9606,271.5409);

	ApplyActorAnimation(dance1, "DANCING", "DAN_Down_A", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(dance2, "DANCING", "DAN_Left_A", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(dance3, "DANCING", "DAN_Loop_A", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(dance4, "DANCING", "dnce_M_a", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(dance5, "DANCING", "dnce_M_b", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(dance6, "DANCING", "bd_clap", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(dance7, "DANCING", "DAN_Right_A", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(dance8, "DANCING", "dance_loop", 3.0, 1, 0, 0, 0, 0);

	//Spectators for the whores below

	new spec1 = CreateActor(84, 1210.9200,-35.7031,1000.9606,111.4261);
	new spec2 = CreateActor(82, 1211.2236,-37.4733,1000.9606,113.6194);

	ApplyActorAnimation(spec1, "KISSING", "gfwave2", 3.0, 1, 0, 0, 0, 0);
	ApplyActorAnimation(spec2, "KISSING", "gfwave2", 3.0, 1, 0, 0, 0, 0);

	//Guard

	CreateActor(163, 1210.0093,-26.0043,1000.9531,183.3484);

	//=========================================================================

	//Create various server pickups

	g_pickups[0] = CreatePickup(1318, 1, -247.2287,2301.2598,111.9679, -1); // Pickup
	CreateDynamic3DTextLabel("*DOWN*", X11_GREEN, -247.2287,2301.2598,111.9679, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	g_pickups[1] = CreatePickup(1318, 1, -446.2921,2144.0662,48.0871, -1); // Pickup
	CreateDynamic3DTextLabel("*UP*", X11_GREEN, -446.2921,2144.0662,48.0871, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	g_pickups[3] = CreatePickup(358, 1, 476.2704,2317.9246,38.0893, -1); // Sniper Pickup
	CreateDynamic3DTextLabel("*RIFLE*", X11_DEEPSKYBLUE, 476.2704,2317.9246,38.0893, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	g_pickups[5] = CreatePickup(1318, 1, -103.4188,2273.0049,121.1062, -1); // Hill Pickup
	CreateDynamic3DTextLabel("*DOWN*", X11_GREEN, -103.4188,2273.0049,121.1062, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	g_pickups[6] = CreatePickup(1318, 1, -101.5193,2339.4768,20.9152, -1); // Hill Pickup
	CreateDynamic3DTextLabel("*UP*", X11_GREEN, -101.5193,2339.4768,20.9152, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

	CreateUI(); //Create the server's User Interface

	//Load Achievements
	Achievements_Load();

	/////////////////////////////////////////

	LoadAntiAir(); //Load anti air vehicles
	LoadSubmarines(); //Load submarines

	//Setup special vehicles
	for (new i = 0; i < MAX_VEHICLES; i++) {
		if (GetVehicleModel(i) == 432) {
			SetVehicleHealth(i, 2500);
		}
		if (GetVehicleModel(i) == 553) {
			SetVehicleHealth(i, 2000);
		}
		if (GetVehicleModel(i) == 553) {
			gNevadaLabel[i] = CreateDynamic3DTextLabel("Nevada Bomber\n[4/4]", X11_CADETBLUE, 0.0, 0.0, 0.0, 50.0, INVALID_PLAYER_ID, i, 1, 0, 0);
			gNevadaRockets[i] = 4;
		}
		if (GetVehicleModel(i) == 476) {
			gRustlerLabel[i] = CreateDynamic3DTextLabel("Rustler Bomber\n[4/4]", X11_CADETBLUE, 0.0, 0.0, 0.0, 50.0, INVALID_PLAYER_ID, i, 1, 0, 0);
			gRustlerRockets[i] = 4;
			Rustler_Rockets[i][0] = CreateDynamicObject(3790, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			AttachDynamicObjectToVehicle(Rustler_Rockets[i][0], i, 2.925019, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
			Rustler_Rockets[i][1] = CreateDynamicObject(3790, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			AttachDynamicObjectToVehicle(Rustler_Rockets[i][1], i, 3.455031, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
			Rustler_Rockets[i][2] = CreateDynamicObject(3790, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			AttachDynamicObjectToVehicle(Rustler_Rockets[i][2], i, -2.925019, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
			Rustler_Rockets[i][3] = CreateDynamicObject(3790, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			AttachDynamicObjectToVehicle(Rustler_Rockets[i][3], i, -3.455031, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
		}
		if (GetVehicleModel(i) == 512) {
			CropAnthrax[i][Anthrax_Label] = CreateDynamic3DTextLabel("Anthrax Cropduster\n[4/4]", X11_CADETBLUE, 0.0, 0.0, 0.0, 50.0, INVALID_PLAYER_ID, i, 1, 0, 0);
			CropAnthrax[i][Anthrax_Rockets] = 4;
			CropAnthrax[i][Anthrax_Cooldown] = gettime();
		}
	}

	//-----------
	//Missing vehicles
	//CreateVehicle(512,-423.4167,2369.5242,117.9840,268.7932,-1,-1,60); // cropdust
	CreateVehicle(512,294.7434,1925.3944,17.3317,0.0131,1,1,60); // cropdust
	/*AddStaticVehicle(468,186.8209,1924.9069,17.3991,179.1586,0,7); // sanchez
	AddStaticVehicle(468,225.4988,1925.2216,17.3099,180.1413,0,7); // sanchez
	AddStaticVehicle(468,118.2941,1867.1399,17.4984,90.8638,0,7); // sanchez
	AddStaticVehicle(468,205.2829,1814.2047,17.3086,0.4219,0,7); // sanchez
	AddStaticVehicle(468,211.8439,1828.0620,17.3082,178.9877,0,7); // sanchez
	AddStaticVehicle(468,207.1815,1827.9609,17.3097,180.0193,0,7); // sanchez
	AddStaticVehicle(468,-347.9691,2241.4644,50.8868,90.0935,0,7); // sanchez
	AddStaticVehicle(468,-343.2443,2241.4644,50.8879,90.0939,0,7); // sanchez
	AddStaticVehicle(468,-352.9611,2171.9131,50.8888,90.1111,0,7); // sanchez
	AddStaticVehicle(468,-372.2235,2162.8369,50.8887,359.2683,0,7); // sanchez
	AddStaticVehicle(468,-372.3045,2156.5798,50.8873,359.2686,0,7); // sanchez
	AddStaticVehicle(468,-405.5382,2260.2175,50.8886,183.0837,0,7); // sanchez
	AddStaticVehicle(468,-424.3455,2216.2129,50.8850,272.8933,0,7); // sanchez
	AddStaticVehicle(468,-421.0903,2187.0112,50.8841,3.2436,0,7); // sanchez
	AddStaticVehicle(468,-426.0223,2186.9597,50.8835,5.2717,0,7); // sanchez
	AddStaticVehicle(468,-430.9844,2187.2500,50.8848,1.8567,0,7); // sanchez
	AddStaticVehicle(468,-436.7222,2187.5938,50.8843,3.8621,0,7); // sanchez
	AddStaticVehicle(468,204.0832,1814.1801,17.3095,0.7160,0,7); // sanchez
	AddStaticVehicle(468,-416.0666,2260.0112,50.8849,181.4206,0,7); // sanchez
	AddStaticVehicle(468,-424.1352,2243.0642,50.8845,269.0049,0,7); // sanchez
	AddStaticVehicle(468,-429.8277,2243.1624,50.8839,269.0054,0,7); // sanchez
	AddStaticVehicle(408,989.0023,2161.0969,11.3634,179.3760,0,7); // trash
	AddStaticVehicle(408,1012.5596,2128.6406,11.2865,359.2329,0,7); // trash
	AddStaticVehicle(468,23.1080,1164.3622,19.2579,179.1718,46,46); // sanchez
	AddStaticVehicle(468,5.8219,1164.0082,19.2933,1.5656,46,46); // sanchez
	AddStaticVehicle(468,-93.0153,1221.7064,19.4043,179.7446,46,46); // sanchez
	AddStaticVehicle(468,-90.5474,1221.6484,19.4110,181.3231,46,46); // sanchez
	AddStaticVehicle(468,-54.9967,1116.3679,19.4195,89.6050,46,46); // sanchez
	AddStaticVehicle(468,-81.0383,1215.6317,19.4104,180.2057,46,46); // sanchez
	AddStaticVehicle(468,4397.3291,4037.1035,9.2544,91.2431,0,7); // sanchez
	AddStaticVehicle(468,4037.9968,4030.1965,13.2345,88.6069,0,7); // sanchez*/
	AddStaticVehicle(495,3709.5229,4021.2410,10.5090,91.9164,0,7); // sand
	AddStaticVehicle(470,3609.2148,4020.4548,10.1490,321.0668,0,7); // pat
	AddStaticVehicle(470,3475.0210,3939.2754,9.4449,180.2452,0,7); // pat
	AddStaticVehicle(470,3474.4353,3879.1050,9.2411,178.9529,0,7); // pat
	AddStaticVehicle(470,3614.6873,3537.5864,5.6899,224.0729,0,7); // pat
	AddStaticVehicle(470,3634.4666,3518.7708,3.6438,244.4944,0,7); // pat
	AddStaticVehicle(495,3970.1978,3444.0615,13.7079,315.0380,0,7); // pub
	AddStaticVehicle(495,3991.2241,3451.5400,13.7583,345.1254,0,7); // pub
	AddStaticVehicle(400,3603.3804,3582.3340,7.4325,90.4678,0,7); // pubg
	AddStaticVehicle(493,3369.4302,3632.4724,-0.5201,181.2233,0,7); // boat
	///////////////////////////////////////////////////////////////////////

	printf("Server was initialized in %d ms!", GetTickCount() - Success);
	print("(c) H2O Multiplayer 2020. All rights reserved.");
	return 1;
}

public OnGameModeExit() {
	new Success = GetTickCount();

	//Remove classes
	Class_Unload();

	//Remove some pickups
	DestroyPickup(g_pickups[0]);
	DestroyPickup(g_pickups[1]);
	DestroyPickup(g_pickups[2]);
	DestroyPickup(g_pickups[3]);
	DestroyPickup(g_pickups[4]);
	DestroyPickup(g_pickups[5]);
	DestroyPickup(g_pickups[6]);

	//Unload streamer content
	DestroyAllDynamicObjects();
	DestroyAllDynamic3DTextLabels();

	DestroyAllDynamicCPs();
	DestroyAllDynamicRaceCPs();

	DestroyAllDynamicAreas();
	DestroyAllDynamicMapIcons();

	//Erase User Interface
	RemoveUI();

	printf("SvT was unloaded in %d ms.", GetTickCount() - Success);

	UnloadSubmarines();
	UnloadAntiAir();

	//Unload special vehicles' stuff
	for (new i = 0; i < MAX_VEHICLES; i++) {
		if (IsValidDynamicObject(Rustler_Rockets[i][0])) DestroyDynamicObject(Rustler_Rockets[i][0]);
		if (IsValidDynamicObject(Rustler_Rockets[i][1])) DestroyDynamicObject(Rustler_Rockets[i][1]);
		if (IsValidDynamicObject(Rustler_Rockets[i][2])) DestroyDynamicObject(Rustler_Rockets[i][2]);
		if (IsValidDynamicObject(Rustler_Rockets[i][3])) DestroyDynamicObject(Rustler_Rockets[i][3]);
		DestroyDynamic3DTextLabel(gRustlerLabel[i]);
	}

	//Carepacks - a Nevada feature
	for (new i = 0; i < MAX_SLOTS; i++) {
		KillTimer(gCarepackTimer[i]);
		gCarepackPos[i][0] = gCarepackPos[i][1] = gCarepackPos[i][2] = 0.0;
		gCarepackExists[i] = 0;
		gCarepackUsable[i] = 0;
	}

	foreach (new i: teams_loaded) {
		DestroyPickup(ShopInfo[i][Shop_Id]);
	}

	foreach (new i: teams_loaded) {
		DestroyDynamicObject(AntennaInfo[i][Antenna_Id]);

		AntennaInfo[i][Antenna_Exists] = 0;
		AntennaInfo[i][Antenna_Hits] = 0;
	}

	foreach (new i: teams_loaded) {
		DestroyVehicle(PrototypeInfo[i][Prototype_Id]);
		PrototypeInfo[i][Prototype_Attacker] = INVALID_PLAYER_ID;
	}

	//Remove our balloon
	KillTimer(Balloontimer);
	DestroyDynamicObject(ballonObjectId);
	Delete3DTextLabel(Balloon_Label);

	mysql_close(Database);
	return 1;
}

public OnIncomingConnection(playerid, ip_address[], port) {
	if (!svtconf[server_open]) {
		Kick(playerid);
	}

	if (!strcmp(g_LastIp, ip_address, true) && !isnull(g_LastIp)) {
		if (g_Tick > gettime()) {
			if (g_Connections > 3) {
				g_Connections = 0;
				g_Tick = gettime();

				BlockIpAddress(ip_address, 60 * 1000 * 10);
				format(g_LastIp, 30, "");
			}
		}

		g_Connections ++;
		g_Tick = gettime() + 3;
	}
	else {
		format(g_LastIp, 30, "%s", ip_address);
		g_Connections = 0;
		g_Tick = gettime();
	}
	return 1;
}

public OnPlayerConnect(playerid) {
	if (IsPlayerBot(playerid)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_263x);
		GameTextForPlayer(playerid, "~r~UNAUTHORIZED ACCESS", 3000, 3);

		new suspectIp[25];
		GetPlayerIp(playerid, suspectIp, sizeof(suspectIp));
		BlockIpAddress(suspectIp, 60000 * 60);

		AntiCheatAlert(playerid, "Fake Client");
		return Kick(playerid);
	}
	Team_ResetPlayer(playerid);
	Ranks_ResetPlayer(playerid);
	ADMIN_OnPlayerConnect(playerid);
	EVENTS_OnPlayerConnect(playerid);
	Items_ResetPlayer(playerid);
	Trades_ResetPlayer(playerid);
	TogglePlayerSpectating(playerid, true);
	pStreamedLink[playerid] = 0;
	pPreviousStreamdLink[playerid][0] = EOS;
	//
	pRaceId[playerid] =  -1;
	wasspectating[playerid] = false;

	//Reset dogfight
	pDogfightTarget[playerid] = INVALID_PLAYER_ID;
	pDogfightInviter[playerid] = INVALID_PLAYER_ID;
	pDogfightTime[playerid] = gettime();
	pDogfightBet[playerid] = 0;
	pDogfightModel[playerid] = 0;

	//Votekick
	pVotesKick[playerid] = 0;
	foreach (new i: Player) {
		pVotedKick[playerid][i] = false;
	}
	pVoteKickCD[playerid] = gettime();

	//Ain't no spies
	PlayerInfo[playerid][pSpyTeam] = -1;

	//Of course not selecting a team on connection?
	pTeamSTimer[playerid] = -1;

	RankLabel[playerid] = Create3DTextLabel(" ", 0xFFFFFFFF, 0.0, 0.0, 0.0, 20.0, 0, 1);

	//-----------GENERAL RESET
	new clear_data[E_PLAYER_ENUM];
	pEventInfo[playerid] = clear_data;
	new clear_data2[PlayerData];
	PlayerInfo[playerid] = clear_data2;
	SetPlayerConfigValue(playerid, "HUD", 0);
	VipLabel[playerid] = Create3DTextLabel(" ", 0x00000000, 0.0, 0.0, 8.0, 50.0, 0, 1);
	pStats[playerid] = -1;
	pStatsID[playerid] = INVALID_PLAYER_ID;
	pVehId[playerid] = INVALID_VEHICLE_ID;
	pFirstSpawn[playerid] = 1;
	pKillerCam[playerid] = INVALID_PLAYER_ID;
	LoadingTimer[playerid] = -1;
	AntiSK[playerid] = 0;
	pMinigunFires[playerid] = 0;
	InDrone[playerid] = false;
	gMedicKitHP[playerid] = 0.0;
	gMedicKitStarted[playerid] = false;
	for (new i = 0; i < 13; i++) {
		pWeaponData[playerid][i] = pAmmoData[playerid][i] = 0;
	}
	pMoney[playerid] = 0;
	LastKilled[playerid] = INVALID_PLAYER_ID;
	NukeTimer[playerid] =
	pTeamSTimer[playerid] =
	RecoverTimer[playerid] =
	AKTimer[playerid] =
	ExplodeTimer[playerid] =
	RepairTimer[playerid] =
	JailTimer[playerid] =
	DelayerTimer[playerid] =
	FreezeTimer[playerid] =
	DMTimer[playerid] =
	pClickedID[playerid] = INVALID_PLAYER_ID;
	gLastWeap[playerid] = 0;
	for (new i = 0; i < sizeof(pCooldown[]) - 1; i++) {
		pCooldown[playerid][i] = gettime();
	}
	gRappelling[playerid] = 0;
	pHelmetAttached[playerid] = 0;
	pMaskAttached[playerid] = 0;
	PlayerInfo[playerid][pPlayTick] = gettime();
	PlayerInfo[playerid][pKnifer] = INVALID_PLAYER_ID;
	LastTarget[playerid] = INVALID_PLAYER_ID;
	PlayerInfo[playerid][pBountyAmount] = 0;
	PlayerInfo[playerid][pDeathmatchId] = -1;
	PlayerInfo[playerid][pLastKiller] = INVALID_PLAYER_ID;
	PlayerInfo[playerid][pACWarnings] = 0;
	PlayerInfo[playerid][pACCooldown] = gettime();
	pIsWorldObjectsRemoved[playerid] = false;
	PlayerInfo[playerid][pDeathmatchId] = -1;
	cLoggerList[playerid] = 0;
	pWatching[playerid] = false;
	new reset_bullet_stats[BulletData];
	BulletStats[playerid] = reset_bullet_stats;
	gMedicTick[playerid] = GetTickCount();
	BulletStats[playerid][Last_Shot_MS] = GetTickCount();
	BulletStats[playerid][MS_Between_Shots] = GetTickCount();
	Last_Pickup[playerid] = -1;
	Last_Pickup_Tick[playerid] = GetTickCount();
	gIntCD[playerid] = GetTickCount();
	PlayerInfo[playerid][pCar] = -1;
	gMGOverheat[playerid] = 0;
	PlayerInfo[playerid][pCaptureStreak] = 0;
	PlayerInfo[playerid][pZonesCaptured] = 0;
	gEditSlot[playerid] = -1;
	gEditModel[playerid] = -1;
	gEditList[playerid] = 0;
	pKatanaEnhancement[playerid] = 0;
	for (new i = 0; i < 4; i++) {
		gModelsSlot[playerid][i] = -1;
		gModelsObj[playerid][i] = -1;
		gModelsPart[playerid][i] = -1;
	}
	gInvisible[playerid] = false;
	gInvisibleTime[playerid] = gettime();
	PlayerInfo[playerid][acWarnings] = 0;
	PlayerInfo[playerid][acTotalWarnings] = 0;
	PlayerInfo[playerid][acCooldown] = gettime();
	pRapidFireBullets{playerid} = 0;
	pRapidFireTick[playerid] = GetTickCount();
	IsPlayerUsingAnims[playerid] = 0;
	IsPlayerAnimsPreloaded[playerid] = 0;
	pLastMessager[playerid] = INVALID_PLAYER_ID;
	rconAttempts[playerid] = 0;
	PlayerInfo[playerid][pKnifeTarget] = INVALID_PLAYER_ID;
	PlayerInfo[playerid][pDeathmatchId] = -1;
	TargetOf[playerid] = INVALID_PLAYER_ID;
	pDuelInfo[playerid][pDLocked] =
	pDuelInfo[playerid][pDWeapon] =
	pDuelInfo[playerid][pDAmmo] =
	pDuelInfo[playerid][pDWeapon2] =
	pDuelInfo[playerid][pDAmmo2] =
	pDuelInfo[playerid][pDBetAmount] =
	pDuelInfo[playerid][pDInMatch] =
	pDuelInfo[playerid][pDCountDown] =
	AntiSK[playerid] = 0;
	if (svtconf[kick_bad_nicknames]) {
		for (new i = 0; i < sizeof(ForbiddenNames); i++) {
			if (strfind(PlayerInfo[playerid][PlayerName], ForbiddenNames[i], true) != -1 && !isnull(ForbiddenNames[i])) {
				PlayerInfo[playerid][pAntiSwearBlocks] ++;
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_264x);
				Kick(playerid);
			}
		}
	}
	pStreak[playerid] = 0;
    pVotesKick[playerid] = 0;
	pRaceCheck[playerid]++;
	//Reset variables
	PlayerInfo[playerid][pIsInvitedToClan] = 0;
	pClan[playerid] = -1;
	pClanRank[playerid] = 0;

	//IP retrieval
	GetPlayerIp(playerid, PlayerInfo[playerid][pIP], 25);
	gpci(playerid, PlayerInfo[playerid][pGPCI], MAX_GPCI_LEN);

	//Show the player our intro
	for (new i = 0; i < sizeof(SvTTD); i++) {
		TextDrawShowForPlayer(playerid, SvTTD[i]);
	}

	//Update objects for player even if they don't move, useful for avoiding desync
	Streamer_ToggleIdleUpdate(playerid, true);

	//Client
	GetPlayerVersion(playerid, PlayerInfo[playerid][pSAMPClient], 10);

	//-----------

	/* Reset objects */

	PlayerInfo[playerid][pAnthrax] = INVALID_OBJECT_ID;
	for (new i = 0; i < 17; i++) {
		PlayerInfo[playerid][pAnthraxEffects][i] = INVALID_OBJECT_ID;
	}

	//Set player's maximum health to 100 by default
	SetPlayerMaxHealth(playerid, 100.0);

	//Reset other stuff
	ResetToysData(playerid);

	//Load player's name
	GetPlayerName(playerid, PlayerInfo[playerid][PlayerName], MAX_PLAYER_NAME);

	//Create map icons
	SetPlayerMapIcon(playerid, 33, -337.7852, 1596.3204, 75.7351, 27, 0, MAPICON_LOCAL);
	SetPlayerMapIcon(playerid, 34, -356.8720, 1588.9048, 76.5136, 23, 0, MAPICON_LOCAL); //Anthrax

	//Mod place
	gModMapIcon[playerid] = CreateDynamicMapIcon(2387.1062, 1046.6208, 18.3189, 27, 0, 0, 0, playerid, 450.0, MAPICON_LOCAL);

	//-----------

	//If the player is advertising in their name, kick them
	if (!ComparePrivileges(playerid, CMD_OWNER) && svtconf[anti_adv] && AdCheck(PlayerInfo[playerid][PlayerName])) {
		return Kick(playerid);
	}

	//Let others know that this player connected
	SetPlayerColor(playerid, 0xFFFFFFFF);

	new string[128];
	format(string, sizeof(string), "%s[%d] ~g~hopped ~w~in the server ~y~[p: %d]!", PlayerInfo[playerid][PlayerName], playerid, Iter_Count(Player));
	SendWarUpdate(string);

	//Create the GUI
	CreatePlayerUI(playerid);

	//Reset some dangerous stuff
	PlayerInfo[playerid][pAdminLevel] = 0;
	PlayerInfo[playerid][pDonorLevel] = 0;

	//Authenticate

	new query[MEDIUM_STRING_LEN];

	mysql_format(Database, query, sizeof(query), "SELECT * FROM `BansData` WHERE `BannedName` = '%e' LIMIT 1", PlayerInfo[playerid][PlayerName]);
	mysql_tquery(Database, query, "CheckBansData", "i", playerid);

	mysql_format(Database, query, sizeof query, "SELECT * FROM `Players` WHERE `Username` = '%e' LIMIT 1", PlayerInfo[playerid][PlayerName]);
	mysql_tquery(Database, query, "OnPlayerDataReceived", "dd", playerid, pRaceCheck[playerid]);
	return 1;
}

RaceEndCheck() {
	for (new i = 0; i < MAX_RACES - 1; i++) {
		if (RaceStarted[i] && !RaceOpened[i] && gettime() >= RaceEndTime[i]) {
			foreach (new x: Player) {
				if (pRaceId[x] == i) {
					pRaceId[x] = -1;
					DisablePlayerRaceCheckpoint(x);
					SpawnPlayer(x);
					GameTextForPlayer(x, "~r~RACE TIME'S UP!", 3000, 3);
				}
			}
			ResetRaceSlot(i);
		}
	}
}

public OnPlayerDisconnect(playerid, reason) {
	ADMIN_OnPlayerDisconnect(playerid);
	PUBG_OnPlayerDisconnect(playerid);
	EVENTS_OnPlayerDisconnect(playerid);

	pRaceCheck[playerid]++;
	pPrivileges[playerid] = 0;

	//A real race check
	if (pRaceId[playerid] != -1) {
		if (RaceStarted[pRaceId[playerid]] && pRaceId[playerid] != (MAX_RACES-1)) {
			new rcount = 0;
			foreach (new i: Player) {
				if (IsPlayerSpawned(i) && pRaceId[i] == pRaceId[playerid]) {
					rcount ++;
				}
			}
			if (!rcount) {
				ResetRaceSlot(pRaceId[playerid]);
			}
		}
		pRaceId[playerid] = -1;
	}

	//Dogfight
	DogfightCheckStatus(playerid);
	pDogfightInviter[playerid] = INVALID_PLAYER_ID;
	pDogfightTime[playerid] = gettime();
	pDogfightBet[playerid] = 0;
	pDogfightModel[playerid] = 0;
	foreach (new i: Player) {
		if (pDogfightInviter[i] == playerid) {
			pDogfightInviter[i] = INVALID_PLAYER_ID;
			SendClientMessage(playerid, X11_WINE, "The player you invited for a dogfight left the server.");
		}
	}
	KillTimer(pDogfightTimer[playerid]);
	pDogfightCD[playerid] = 0;

	//Votekick
	foreach (new i: Player) {
		pVotedKick[i][playerid] = false;
	}

	//Player left during selection waiting time? Abort.
	KillTimer(pTeamSTimer[playerid]);

	//CW Abort
	UpdateClanWar(playerid);

	//o.o
	Delete3DTextLabel(RankLabel[playerid]);

	//WP
	if (IsValidDynamicMapIcon(pWaypoint[playerid])) {
		DestroyDynamicMapIcon(pWaypoint[playerid]);
	}

	//Reset prototype data for this player
	foreach (new i: teams_loaded) {
		if (PrototypeInfo[i][Prototype_Attacker] == playerid) {
			DisablePlayerRaceCheckpoint(playerid);
			SetVehicleToRespawn(PrototypeInfo[i][Prototype_Id]);

			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_50x, PlayerInfo[playerid][PlayerName], Team_GetName(i));
			PrototypeInfo[i][Prototype_Attacker] = INVALID_PLAYER_ID;

			break;
		}
	}

	//No anthrax
	KillTimer(PlayerInfo[playerid][pAnthraxTimer]);

	if (IsValidDynamicObject(PlayerInfo[playerid][pAnthrax])) {
		DestroyDynamicObject(PlayerInfo[playerid][pAnthrax]);
	}
	PlayerInfo[playerid][pAnthrax] = INVALID_OBJECT_ID;
	for (new i = 0; i < 17; i++) {
		if (IsValidDynamicObject(PlayerInfo[playerid][pAnthraxEffects][i])) {
			DestroyDynamicObject(PlayerInfo[playerid][pAnthraxEffects][i]);
		}
		PlayerInfo[playerid][pAnthraxEffects][i] = INVALID_OBJECT_ID;
	}

	ForceSync[playerid] = 0;

	////////Timers/////////////

	KillTimer(FirstSpawn_Timer[playerid]);
	KillTimer(KillerTimer[playerid]);
	KillTimer(RespawnTimer[playerid]);
	KillTimer(LoadingTimer[playerid]);
	KillTimer(InviteTimer[playerid]);
	KillTimer(ac_InformTimer[playerid]);
	KillTimer(CrateTimer[playerid]);

	///////////////////////////

	TargetOf[playerid] = INVALID_PLAYER_ID;
	pKillerCam[playerid] = INVALID_PLAYER_ID;

	RemovePlayerUI(playerid);

	//------------
	PlayerInfo[playerid][pTimePlayed] += gettime() - PlayerInfo[playerid][pPlayTick];

	RecountPlayedTime(playerid);

	KillTimer(TutoTimer[playerid]);
	KillTimer(NotifierTimer[playerid]);
	KillTimer(CarInfoTimer[playerid]);

	TextDrawHideForPlayer(playerid, Site_TD);

	KillTimer(SpawnTimer[playerid]);

	foreach (new i: Player) {
		if (pClickedID[i] == playerid) {
			pClickedID[i] = INVALID_PLAYER_ID;
		}

		if (pLastMessager[i] == playerid) {
			pLastMessager[i] = INVALID_PLAYER_ID;
		}

		for (new x = 0; x < MAX_SLOTS; x++) {
			if (gLandminePlacer[x] == playerid) {
				gLandminePlacer[x] = INVALID_PLAYER_ID;
			}

			if (gDynamitePlacer[x] == playerid) {
				gDynamitePlacer[x] = INVALID_PLAYER_ID;
			}
		}
	}

	pLastMessager[playerid] = INVALID_PLAYER_ID;

	DeletePVar(playerid, "DialogListitem");

	Delete3DTextLabel(VipLabel[playerid]);

	KillTimer(DamageTimer[playerid]);

	if (nukePlayerId == playerid) {
		UpdateDynamic3DTextLabelText(nukeRemoteLabel, 0xFFFFFFFF, "Nuke\n{00CC00}Online");
		SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_52x);
		KillTimer(NukeTimer[playerid]);
	}

	KillTimer(RecoverTimer[playerid]);
	KillTimer(AKTimer[playerid]);
	KillTimer(ExplodeTimer[playerid]);
	KillTimer(RepairTimer[playerid]);
	KillTimer(JailTimer[playerid]);
	KillTimer(DelayerTimer[playerid]);
	KillTimer(FreezeTimer[playerid]);
	KillTimer(DMTimer[playerid]);

	pClickedID[playerid] = INVALID_PLAYER_ID;

	RemovePlayerMapIcon(playerid, 33);
	RemovePlayerMapIcon(playerid, 34);
	RemovePlayerMapIcon(playerid, 35);

	DestroyDynamicMapIcon(gModMapIcon[playerid]);

	ClearReportsData(playerid);

	foreach (new i: Player) {
		if (PlayerInfo[i][pBackup] == playerid && i != playerid) {
			pBackupResponded[i] = 0;
			PlayerInfo[i][pBackup] = INVALID_PLAYER_ID;
		}
	}

	////////////////////////////

	new string[128];
	switch (reason) {
		case 0: format(string, sizeof(string), "%s[%d] ~r~left ~w~the server ~y~[p: %d]!", PlayerInfo[playerid][PlayerName], playerid, Iter_Count(Player));
		case 1: {
			format(string, sizeof(string), "%s[%d] lost their connectivity ~r~[p: %d]!", PlayerInfo[playerid][PlayerName], playerid, Iter_Count(Player));
			PlayerInfo[playerid][pCrashTimes] ++;
		}
		case 2: format(string, sizeof(string), "%s[%d] was kicked/banned ~r~[p: %d]!", PlayerInfo[playerid][PlayerName], playerid, Iter_Count(Player));
	}
	SendWarUpdate(string);

	pStreak[playerid] = 0;
	rconAttempts[playerid] = 0;

	pLastMessager[playerid] = INVALID_PLAYER_ID;

	Delete3DTextLabel(VipLabel[playerid]);

	for (new i = 0; i < 10; i++) {
		if (IsPlayerAttachedObjectSlotUsed(playerid, i)) {
			RemovePlayerAttachedObject(playerid, i);
		}
	}

	//Check if player goodbye'd their opponent
	PlayerLeaveDuelCheck(playerid);

	if (cache_is_valid(PlayerInfo[playerid][pCacheId])) {
		cache_delete(PlayerInfo[playerid][pCacheId]);
		PlayerInfo[playerid][pCacheId] = MYSQL_INVALID_CACHE;
	}

	//AAC
	for (new i = 0; i < sizeof(AACInfo) - 1; i++) {
		if (LastVehicleID[playerid] == AACInfo[i][AAC_Driver]) {
			AACInfo[i][AAC_Driver] = INVALID_PLAYER_ID;
		}
		if (AACInfo[i][AAC_Target] == playerid) {
			AACInfo[i][AAC_Target] = INVALID_PLAYER_ID;
			if (IsValidDynamicObject(AACInfo[i][AAC_RocketId])) {
				DestroyDynamicObject(AACInfo[i][AAC_RocketId]);
				AACInfo[i][AAC_RocketId] = INVALID_OBJECT_ID;
			}
		}
	}
	KillTimer(pAACTargetTimer[playerid]);

	//Reset car values
	if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
	PlayerInfo[playerid][pCar] = -1;
	LastVehicleID[playerid] = INVALID_VEHICLE_ID;

	PlayerInfo[playerid][pInvitedToClan][0] = EOS;

	if (PlayerInfo[playerid][pLoggedIn] && pVerified[playerid]) {
		SavePlayerStats(playerid);
		LogConnection(playerid, reason, gettime());
	}

	PlayerInfo[playerid][pLoggedIn] = 0;

	//Unverify this account slot
	new clear_data2[PlayerData];
	PlayerInfo[playerid] = clear_data2;

	pVerified[playerid] = false;
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success) {
	if (!success) {
		foreach (new i: Player) {
			if (!strcmp(PlayerInfo[i][pIP], ip) && !isnull(PlayerInfo[i][pIP])) {
				PlayerInfo[i][pRCONFailedAttempts] ++;
			}
		}
		return BlockIpAddress(ip, 60 * 100000);
	} else {
		foreach (new i: Player) {
			if (!strcmp(PlayerInfo[i][pIP], ip) && !isnull(PlayerInfo[i][pIP])) {
				PlayerInfo[i][pRCONLogins] ++;
				ReloadPrivileges(i);
			}
		}
	}
	return 1;
}

public OnPlayerSpawn(playerid) {
	//Login Restriction

	if (!PlayerInfo[playerid][pLoggedIn]) {
		return Kick(playerid);
	}

	//Apply first spawn stuff
	if (pFirstSpawn[playerid]) {
		TogglePlayerControllable(playerid, false);
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_391x, Ranks_ReturnName(Ranks_GetPlayer(playerid)));
		FirstSpawn_Timer[playerid] = SetTimerEx("EndFirstSpawn", 5000, false, "i", playerid);
		SetPlayerInterior(playerid, 3);
		SetPlayerPos(playerid, 349.0453, 193.2271, 1014.1797);
		SetPlayerFacingAngle(playerid, 286.25);
		SetPlayerCameraPos(playerid, 352.9164, 194.5702, 1014.1875);
		SetPlayerCameraLookAt(playerid, 349.0453, 193.2271, 1014.1797);
		return 1;
	}

	//Display new zones
	Zones_ShowForPlayer(playerid);

	//Reset weapons
	ResetPlayerWeapons(playerid);

	//Add body toys if player set any of them
	for (new i = 0; i < 4; i++) {
		if (gModelsSlot[playerid][i] != -1) {
			SetPlayerAttachedObject(playerid, gModelsSlot[playerid][i], gModelsObj[playerid][i], gModelsPart[playerid][i],
				ao[playerid][gModelsSlot[playerid][i]][ao_x], ao[playerid][gModelsSlot[playerid][i]][ao_y], ao[playerid][gModelsSlot[playerid][i]][ao_z],
				ao[playerid][gModelsSlot[playerid][i]][ao_rx], ao[playerid][gModelsSlot[playerid][i]][ao_ry], ao[playerid][gModelsSlot[playerid][i]][ao_rz],
				ao[playerid][gModelsSlot[playerid][i]][ao_sx], ao[playerid][gModelsSlot[playerid][i]][ao_sy], ao[playerid][gModelsSlot[playerid][i]][ao_sz]);
		}
	}

	//Reset various variables and player items for a clean spawn
	if (!wasspectating[playerid]) {
		ResetPlayerVars(playerid);
	} else {
		wasspectating[playerid] = false;
	}

	//Other systems

	ADMIN_OnPlayerSpawn(playerid);
	PUBG_OnPlayerSpawn(playerid);

	//Race check
	if (pRaceId[playerid] != -1) {
		if (RaceStarted[pRaceId[playerid]] && pRaceId[playerid] != (MAX_RACES-1)) {
			new rcount = 0;
			foreach (new i: Player) {
				if (IsPlayerSpawned(i) && pRaceId[i] == pRaceId[playerid]) {
					rcount ++;
				}
			}
			if (!rcount) {
				ResetRaceSlot(pRaceId[playerid]);
			}
		}
		pRaceId[playerid] = -1;
		DisablePlayerRaceCheckpoint(playerid);
	}

	//Update player's HUD
	UpdatePlayerHUD(playerid);

	//Check if player is in duel
	PlayerDuelSpawn(playerid);

	//Dogfight check
	DogfightCheckStatus(playerid);

	//Clan War Update
	if (Iter_Contains(CWCLAN1, playerid)) {
		Iter_Remove(CWCLAN1, playerid);
	}

	if (Iter_Contains(CWCLAN2, playerid)) {
		Iter_Remove(CWCLAN2, playerid);
	}

	//Prototype
	foreach (new i: teams_loaded) {
		if (PrototypeInfo[i][Prototype_Attacker] == playerid) {
			DisablePlayerRaceCheckpoint(playerid);
			SetVehicleToRespawn(PrototypeInfo[i][Prototype_Id]);
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_50x, PlayerInfo[playerid][PlayerName], Team_GetName(i));
			PrototypeInfo[i][Prototype_Attacker] = INVALID_PLAYER_ID;
			break;
		}
	}

	//Players can't avoid the jail man
	if (PlayerInfo[playerid][pJailed]) {
		ResetPlayerWeapons(playerid);
		JailPlayer(playerid);
		return 1;
	}

	//Sync player if something goes wrong
	if (ForceSync[playerid]) {
		ResyncData(playerid);
		return 1;
	}

	//If player's in a duel YET, abort the spawn stuff and rest of code
	if (pDuelInfo[playerid][pDInMatch]) {
		return 1;
	}

	//Then comes death-match
	if (PlayerInfo[playerid][pDeathmatchId] >= 0) {
		return SetupDeathmatch(playerid);
	}

	//PUBG integration
	if (PUBGStarted && Iter_Contains(PUBGPlayers, playerid)) {
		if (pVerified[PlayerInfo[playerid][pSpecId]]) {
			ResetPlayerWeapons(playerid);
			GivePlayerWeapon(playerid, 46, 1);
			new Float: X, Float: Y, Float: Z;
			GetPlayerPos(PlayerInfo[playerid][pSpecId], X, Y, Z);
			new Float:rx = frandom(15.0, -15.0, 2), Float:ry = frandom(15.0, -15.0, 2), Float:rz = frandom(15.0, -15.0, 2);
			SetPlayerPos(playerid, X + rx, Y + ry, Z + rz + 100);
			PlayerInfo[playerid][pSpecId] = INVALID_PLAYER_ID;
			ApplyAnimation(playerid, "PARACHUTE", "FALL_skyDive", 0.0, 0, 0, 0, 0, 0);
			SetPlayerVirtualWorld(playerid, PUBG_WORLD);
			SetPlayerInterior(playerid, 0);
			return 1;
		}
	}

	SetPlayerVirtualWorld(playerid, BF_WORLD);
	SetPlayerInterior(playerid, 0);

	//Initiate player (disable control to not fall below ground)
	KillTimer(DelayerTimer[playerid]);
	DelayerTimer[playerid] = SetTimerEx("InitPlayer", GetPlayerPing(playerid) + 500, false, "i", playerid);
	TogglePlayerControllable(playerid, false);

	//Preload animations and add headshot-protection helmet for low level newbies (may include other stuff later)
	SetupPlayerSpawn(playerid);

	//Add promised donor stuff
	SetPlayerDonorSpawn(playerid);

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		//Prepare spawn-kill protection
		AntiSKStart[playerid] = gettime() + PlayerInfo[playerid][pSpawnKillTime];

		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_278x, PlayerInfo[playerid][pSpawnKillTime]);
		AntiSK[playerid] = 1;
		SetPlayerAttachedObject(playerid, 8, 18700, 1, 1.081000, 0.000000, -1.595999, -0.699999, -4.800000, -92.500000, 1.000000, 0.000000, 1.000000);
		SetPlayerChatBubble(playerid, "*Spawn Protected*", X11_WINE, 150.0, PlayerInfo[playerid][pSpawnKillTime] * 1000);
		SetPlayerColor(playerid, Team_GetColor(Team_GetPlayer(playerid)));
		UpdateLabelText(playerid);
	}
	return 1;
}

public OnPlayerDamageDone(playerid, Float:amount, issuerid, weapon, bodypart) {
	if (issuerid != INVALID_PLAYER_ID) {
		new damage_string[20];
		format(damage_string, sizeof(damage_string), "-%.0f", amount);
		SetPlayerChatBubble(playerid, damage_string, 0xFF0000FF, 100.0, 2000);

		if (amount > 44.5) {
			KillTimer(DamageTimer[playerid]);
			DamageTimer[playerid] = SetTimerEx("HideDamage", 1000, false, "i", playerid);
			SetPlayerAttachedObject(playerid, 8, 18668, 1, 1.081000, 0.000000, -1.595999, -0.699999, -4.800000, -92.500000, 1.000000, 0.000000, 1.000000);
		}
	}
	return 1;
}

public OnPlayerDamage(&playerid, &Float:amount, &issuerid, &weapon, &bodypart) {
	if (PlayerInfo[playerid][pIsAFK] || PlayerInfo[playerid][pSelecting] || pFirstSpawn[playerid] || AntiSK[playerid]) {
		return 0;
	}

	//BustAim fix
	if((0 <= issuerid < MAX_PLAYERS) && (0 <= playerid < MAX_PLAYERS) && (0 <= weapon < 50)) BustAim_g_IntrnlPlayerSettings{issuerid} |= PREVIOUS_SHOT_DID_DAMAGE;
	//

	if (IsPlayerAttachedObjectSlotUsed(playerid, 8)) {
		RemovePlayerAttachedObject(playerid, 8);
	}

	if (issuerid != INVALID_PLAYER_ID) {
		if (issuerid != playerid) {
			LastDamager[playerid] = issuerid;
			LastTarget[issuerid] = playerid;

			if (AntiSK[playerid]) {
				GameTextForPlayer(issuerid, MSG_SPY_KILLED, 3000, 3);
				return 0;
			}

			if (IsPlayerInMode(playerid, MODE_BATTLEFIELD) && IsPlayerInMode(issuerid, MODE_BATTLEFIELD)) {
				if (PlayerInfo[issuerid][pIsSpying] && PlayerInfo[issuerid][pSpyTeam] == Team_GetPlayer(playerid)) {
					GameTextForPlayer(playerid, MSG_TEAM_SPY, 3000, 3);
				}

				if (weapon == WEAPON_CARPARK || weapon == WEAPON_HELIBLADES) {
					GameTextForPlayer(issuerid, MSG_ILLEGAL_KILL, 3000, 3);
					LogActivity(issuerid, "Illegal heliblade against #%d", gettime(), PlayerInfo[playerid][pAccountId]);
					return 0;
				}

				if (!Iter_Contains(PUBGPlayers, playerid) && !Iter_Contains(ePlayers, playerid) && PlayerInfo[playerid][pDeathmatchId] == -1 && !pDuelInfo[playerid][pDInMatch]
				   && !Iter_Contains(CWCLAN1, playerid) && !Iter_Contains(CWCLAN2, playerid) && Team_GetPlayer(playerid) == Team_GetPlayer(issuerid)) {
					GameTextForPlayer(issuerid, MSG_TEAMMATE, 3000, 3);
					return 0;
				}

				if (IsPlayerInBase(playerid) && IsPlayerInAnyVehicle(issuerid) && Team_GetPlayer(playerid) != Team_GetPlayer(issuerid)
				   && (GetVehicleModel(GetPlayerVehicleID(issuerid)) == 432 || GetVehicleModel(GetPlayerVehicleID(issuerid)) == 520 ||
				   GetVehicleModel(GetPlayerVehicleID(issuerid)) == 425 || GetVehicleModel(GetPlayerVehicleID(issuerid)) == 447)) {
					GameTextForPlayer(issuerid, MSG_BASERAPE, 3000, 3);
					PlayerInfo[issuerid][pBaseRapeAttempts] ++;

					new Float: X, Float: Y, Float: Z;
					GetPlayerPos(issuerid, X, Y, Z);
					SetPlayerPos(issuerid, X + 1.0, Y + 1.0, Z + 1.0);
					PC_EmulateCommand(issuerid, "/ep");
					LogActivity(issuerid, "Illegal base attack against #%d", gettime(), PlayerInfo[playerid][pAccountId]);
					return 0;
				}

				if (weapon == WEAPON_KATANA
						&& pKatanaEnhancement[issuerid]) {
					DamagePlayer(playerid, 0.0, issuerid, 255, BODY_PART_UNKNOWN, true);
					pKatanaEnhancement[issuerid] --;
					return 0;
				}
			} else {

				if (!Iter_Contains(PUBGPlayers, playerid) && !Iter_Contains(ePlayers, playerid) && PlayerInfo[playerid][pDeathmatchId] == -1 && !pDuelInfo[playerid][pDInMatch]
				   && !Iter_Contains(CWCLAN1, playerid) && !Iter_Contains(CWCLAN2, playerid) && IsPlayerInAnyClan(playerid) && pClan[playerid] == pClan[issuerid]) {
					GameTextForPlayer(issuerid, MSG_CLANMATE, 3000, 3);
					return 0;
				}

				if (EventInfo[E_STARTED] && EventInfo[E_TYPE] == 1 && Iter_Contains(ePlayers, playerid)) {
					if (pEventInfo[playerid][P_TEAM] == pEventInfo[issuerid][P_TEAM]) {
						GameTextForPlayer(issuerid, MSG_EVENT_TEAMMATE, 3000, 3);
						return 0;
					}
				}

				if (PlayerInfo[playerid][pDeathmatchId] > -1 &&
					bodypart == 4 && (weapon == 34 || weapon == 33)) {
					DamagePlayer(playerid, 0.0, issuerid, weapon, BODY_PART_UNKNOWN, true);
					GameTextForPlayer(issuerid, MSG_NUTSHOT_KILL, 3000, 3);
					GameTextForPlayer(playerid, MSG_NUTSHOT, 3000, 3);
					GivePlayerScore(issuerid, 1);
					PlayerInfo[issuerid][pNutshots]++;
					return 0;
				}
			}

			if (AntiSK[issuerid]) {
				EndProtection(issuerid);
			}

			PlayerInfo[playerid][pLastHitTick] = gettime() + 15;
			pIsDamaged[playerid] = 1;
			PlayerInfo[playerid][pHealthLost] += amount;
			PlayerInfo[issuerid][pDamageRate] += amount;

			if (bodypart == 9 && (weapon == 34 || weapon == 33) &&
				((GetPlayerInterior(issuerid) == 0 && Team_GetPlayer(playerid) != Team_GetPlayer(issuerid)) || PlayerInfo[issuerid][pDeathmatchId] > -1)) {
				if (IsPlayerInAnyVehicle(playerid) && GetVehicleModel(GetPlayerVehicleID(playerid)) == 427) return 1;
				if (Items_GetPlayer(playerid, HELMET)) {
					switch (Items_GetPlayer(playerid, HELMET)) {
						case 1: {
							Items_RemovePlayer(playerid, HELMET);
							GameTextForPlayer(playerid, MSG_HELMET_LOST, 3000, 3);
							PlayerPlaySound(playerid, 1131, 0.0, 0.0, 0.0);
						}
						default: {
							Items_AddPlayer(playerid, HELMET, -1);
							GameTextForPlayer(playerid, MSG_HELMET_HIT, 3000, 3);
							PlayerPlaySound(playerid, 1131, 0.0, 0.0, 0.0);
						}
					}
				} else {
					new Float: meters, Float: X, Float: Y, Float: Z;

					GetPlayerPos(playerid, X, Y, Z);
					meters = GetPlayerDistanceFromPoint(issuerid, X, Y, Z);

					DamagePlayer(playerid, 0.0, issuerid, WEAPON_DROWN, BODY_PART_UNKNOWN, true);

					GameTextForPlayer(issuerid, MSG_HEADSHOT_KILL, 3000, 3);
					GameTextForPlayer(playerid, MSG_HEADSHOT, 3000, 3);

					PlayerPlaySound(issuerid, 1095, 0.0, 0.0, 0.0);
					SendGameMessage(issuerid, X11_SERV_INFO, MSG_CLIENT_267x, PlayerInfo[playerid][PlayerName], meters);

					new string[128];
					format(string, sizeof(string), "~y~%s[%d] ~r~headshot ~y~%s[%d] ~b~(%0.2f meters)", PlayerInfo[issuerid][PlayerName], issuerid, PlayerInfo[playerid][PlayerName], playerid, meters);
					SendWarUpdate(string);

					LogActivity(issuerid, "Headshot #%d from %0.2f meters", gettime(), PlayerInfo[playerid][pAccountId], meters);

					GivePlayerScore(issuerid, 5);

					PlayerInfo[issuerid][pHeadshots]++;
					PlayerInfo[issuerid][pHeadshotStreak]++;

					AddTeamWarScore(issuerid, 1, 2);

					SendGameMessage(issuerid, X11_SERV_INFO, MSG_CLIENT_268x, PlayerInfo[issuerid][pHeadshotStreak], PlayerInfo[issuerid][pHeadshots]);

					if (IsPlayerInAnyClan(issuerid)) {
						AddClanXP(GetPlayerClan(issuerid), 5);
						foreach (new x: Player) {
							if (pClan[x] == pClan[issuerid]) {
								SendGameMessage(x, X11_SERV_INFO, MSG_CLIENT_544x, PlayerInfo[issuerid][PlayerName]);
							}
						}
					}

					return 0;
				}
			}
		}
	}
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ) {
	if (hittype == BULLET_HIT_TYPE_PLAYER) if(hitid == INVALID_PLAYER_ID) return 0;
	if (!GetPlayerWeapon(playerid)) return 0;
	if (hitid == playerid) return 0;
	if (!IsBulletWeapon(weaponid)) {
		return 0;
	}
	if (hittype == BULLET_HIT_TYPE_PLAYER && ((fX >= 10.0 || fX <= -10.0) || (fY >= 10.0 || fY <= -10.0) || (fZ >= 10.0 || fZ <= -10.0 ))) {
		return 0;
	}

	// Anti-Rapid Fire (idea taken from Lorenc_)
	if (!pRapidFireTick[playerid]) {
		pRapidFireTick[playerid] = GetTickCount( );
	}
	else {
		new
			shotsInterval = GetTickCount( ) - pRapidFireTick[playerid];
		if ((shotsInterval <= 35 && (weaponid != 38 && weaponid != 28 && weaponid != 32)) || (shotsInterval <= 370 && (weaponid == 34 || weaponid == 33))) {
			if (pRapidFireBullets{playerid} ++ >= 5) {
				AntiCheatAlert(playerid, "Rapid Fire");
		    	return 0;
			}
		} else {
			pRapidFireBullets{playerid} = 0;
		}
		pRapidFireTick[playerid] = GetTickCount();
	}

	if (hittype != BULLET_HIT_TYPE_NONE) {
		if (!(-1000.0 <= fX <= 1000.0) || !(-1000.0 <= fY <= 1000.0) || !(-1000.0 <= fZ <= 1000.0)) {
			AntiCheatAlert(playerid, "Bullet Crasher");
			Kick(playerid);
			return 0;
		}
	}

	new slot = GetWeaponSlot(GetPlayerWeapon(playerid));
	pAmmoData[playerid][slot] --;
	Weapons_LowerAmmo(playerid, weaponid);

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		if (((p_ClassAbilities(playerid, SCOUT)) || (p_ClassAbilities(playerid, RECON))) && weaponid == 34 &&
				hitid == BULLET_HIT_TYPE_PLAYER) {
			SetPlayerChatBubble(playerid, "+7 sniper damage", X11_BLUE, 120.0, 1000);
			DamagePlayer(hitid, 7.0, playerid, weaponid, BODY_PART_UNKNOWN, true);
		}
		if (weaponid == WEAPON_MINIGUN) {
			if (pCooldown[playerid][33] > gettime()) {
				pMinigunFires[playerid] = 0;
				gMGOverheat[playerid] += 500;
				SetPlayerDrunkLevel(playerid, gMGOverheat[playerid]);
				if (gMGOverheat[playerid] >= 10000) {
					gMGOverheat[playerid] = 0;
					SetPlayerDrunkLevel(playerid, gMGOverheat[playerid]);
					AnimPlayer(playerid, "PED", "BIKE_fall_off", 4.1, 0, 0, 0, 0, 0);
					return 0;
				}

			}
			else if (pMinigunFires[playerid] > 15) {
				pCooldown[playerid][33] = gettime() + 15;
				SetPlayerDrunkLevel(playerid, 5000);
				gMGOverheat[playerid] = 1000;
				pMinigunFires[playerid] = 0;
			}

			pMinigunFires[playerid]++;
		}

		//Protect team players
		if (hitid == BULLET_HIT_TYPE_VEHICLE) {
			foreach (new i: Player) {
				if (IsPlayerInVehicle(i, hitid)) {
					if (Team_GetPlayer(i) == Team_GetPlayer(playerid)) {
						return 0;
					}
				}
			}
		}

		//Same as previous
		if (hittype == BULLET_HIT_TYPE_VEHICLE && IsValidVehicle(hitid) && IsVehicleUsed(hitid) && IsBulletWeapon(weaponid)) {
			foreach (new i: Player) {
				if (GetPlayerState(i) == PLAYER_STATE_DRIVER && GetPlayerVehicleID(i) == hitid && Team_GetPlayer(i) == Team_GetPlayer(playerid)) {
					SendGameMessage(playerid, X11_SERV_INFO, MSG_TEAMMATE);
					return 0;
				}
			}
		}
	}

	PlayerInfo[playerid][pGunFires]++;
	PlayerInfo[playerid][pSessionGunFires]++;

	if (hittype == BULLET_HIT_TYPE_PLAYER) {
		if (hitid != INVALID_PLAYER_ID) {
			BulletStats[playerid][Bullets_Hit] ++;
			BulletStats[playerid][Group_Hits] ++;

			if (BulletStats[playerid][Group_Hits] > BulletStats[playerid][Highest_Hits]) {
				BulletStats[playerid][Highest_Hits] = BulletStats[playerid][Group_Hits];
			}

			if (BulletStats[playerid][Group_Misses] != 1) {
				BulletStats[playerid][Group_Misses] = 0;
			} else {
				BulletStats[playerid][Hits_Per_Miss] ++;
			}

			new ms_between_shots = GetTickCount() - BulletStats[playerid][Last_Shot_MS];
			BulletStats[playerid][Last_Shot_MS] = GetTickCount();
			BulletStats[playerid][Last_Hit_MS] = GetTickCount();
			BulletStats[playerid][MS_Between_Shots] = ms_between_shots;
			BulletStats[playerid][Bullet_Vectors][0] = fX,
			BulletStats[playerid][Bullet_Vectors][1] = fY,
			BulletStats[playerid][Bullet_Vectors][2] = fZ;

			new Float: X, Float: Y, Float: Z;
			GetPlayerPos(hitid, X, Y, Z);
			new Float: Distance = GetPlayerDistanceFromPoint(playerid, X, Y, Z);
			BulletStats[playerid][Last_Hit_Distance] = Distance;
			if (BulletStats[playerid][Last_Hit_Distance] > BulletStats[playerid][Longest_Hit_Distance]) {
				BulletStats[playerid][Longest_Hit_Distance] = BulletStats[playerid][Last_Hit_Distance];
				BulletStats[playerid][Longest_Distance_Weapon] = GetPlayerWeapon(playerid);
			}
			if (BulletStats[playerid][Last_Hit_Distance] >= BulletStats[playerid][Shortest_Hit_Distance]) {
				if (BulletStats[playerid][Shortest_Hit_Distance] == 0.0 && BulletStats[playerid][Longest_Hit_Distance] >= BulletStats[playerid][Shortest_Hit_Distance]) {
					BulletStats[playerid][Shortest_Hit_Distance] = BulletStats[playerid][Last_Hit_Distance];
				}
			}
			if (BulletStats[playerid][Shortest_Hit_Distance] > BulletStats[playerid][Last_Hit_Distance]) {
				BulletStats[playerid][Shortest_Hit_Distance] = BulletStats[playerid][Last_Hit_Distance];
			}
			new Float: HMR = floatdiv(BulletStats[playerid][Bullets_Hit], BulletStats[playerid][Bullets_Miss]);
			if (BulletStats[playerid][Hits_Per_Miss] - BulletStats[playerid][Misses_Per_Hit] > 10 ||
				BulletStats[playerid][Bullets_Hit] == HMR) {
				BulletStats[playerid][Aim_SameHMRate] ++;
			}

			if (!IsPlayerAimingAtPlayer(playerid, hitid) && weaponid != 38) {
				BulletStats[playerid][Hits_Without_Aiming] ++;
			}
		}
	} else {
		BulletStats[playerid][Bullets_Miss] ++;
		BulletStats[playerid][Group_Misses] ++;

		if (BulletStats[playerid][Group_Misses] > BulletStats[playerid][Highest_Misses]) {
			BulletStats[playerid][Highest_Misses] = BulletStats[playerid][Group_Misses];
		}

		if (BulletStats[playerid][Group_Hits] != 1) {
			BulletStats[playerid][Group_Hits] = 0;
		} else {
			BulletStats[playerid][Misses_Per_Hit] ++;
		}

		new ms_between_shots = GetTickCount() - BulletStats[playerid][Last_Shot_MS];
		BulletStats[playerid][Last_Shot_MS] = GetTickCount();
		BulletStats[playerid][MS_Between_Shots] = ms_between_shots;
		BulletStats[playerid][Bullet_Vectors][0] = fX,
		BulletStats[playerid][Bullet_Vectors][1] = fY,
		BulletStats[playerid][Bullet_Vectors][2] = fZ;
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason) {
	PUBG_OnPlayerDeath(playerid, killerid);
	if (IsPlayerAttachedObjectSlotUsed(playerid, 8)) {
		RemovePlayerAttachedObject(playerid, 8);
	}

	DogfightCheckStatus(playerid);
	UpdateClanWar(playerid);

	//--------------

	UpdateLabelText(playerid);

	//------------------------

	KillTimer(RecoverTimer[playerid]);
	KillTimer(AKTimer[playerid]);
	KillTimer(DamageTimer[playerid]);

	LastDamager[playerid] = INVALID_PLAYER_ID;

	if (killerid != INVALID_PLAYER_ID && killerid != playerid) {
		LogActivity(killerid, "Killed #%d reason %d", gettime(), PlayerInfo[playerid][pAccountId], reason);
		if (IsPlayerInAnyClan(killerid)) {
			if (pClan[killerid] != pClan[playerid]) {
				AddClanXP(GetPlayerClan(killerid), 1);
				AddClanKills(GetPlayerClan(killerid), 1);
				PlayerInfo[killerid][pClanKills] ++;
			}
		}

		if (IsPlayerInMode(killerid, MODE_BATTLEFIELD)) {
			pKillerCam[playerid] = killerid;
		} else {
			pKillerCam[playerid] = INVALID_PLAYER_ID;
		}

		SendGameMessage(killerid, X11_SERV_SUCCESS, MSG_CLIENT_393x, PlayerInfo[playerid][PlayerName], playerid);
		GivePlayerScore(killerid, 1);
		GivePlayerCash(killerid, 1000);

		if (GetPlayerState(killerid) == PLAYER_STATE_PASSENGER) {
			PlayerInfo[playerid][pDriveByKills] ++;
		}

		if (Ranks_GetPlayer(playerid) > 5) {
			SendGameMessage(killerid, X11_SERV_INFO, MSG_CLIENT_279x);
			PlayerInfo[killerid][pEXPEarned] += 1;
		}

		if (PlayerInfo[killerid][pDeathmatchId] >= 0) {
			PlayerInfo[killerid][sDMKills] ++;
			PlayerInfo[killerid][pDeathmatchKills] ++;
			pDMKills[killerid][PlayerInfo[killerid][pDeathmatchId]] ++;
		}

		if (IsBulletWeapon(GetPlayerWeapon(killerid))) {
			GivePlayerWeapon(killerid, GetPlayerWeapon(killerid), 25);
		} else if (IsValidWeapon(GetPlayerWeapon(killerid))) {
			GivePlayerWeapon(killerid, GetPlayerWeapon(killerid), 1);
		}

		LastKilled[killerid] = playerid;

		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_394x, PlayerInfo[killerid][PlayerName], killerid);
		GivePlayerCash(playerid, -250);

		if (pStreak[playerid] >= 3) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_54x, PlayerInfo[killerid][PlayerName], PlayerInfo[playerid][PlayerName]);
		}

		pStreak[playerid] = 0;

		new Float: X, Float: Y, Float: Z;
		GetPlayerPos(killerid, X, Y, Z);

		if (IsPlayerInMode(playerid, MODE_PUBG)) {
			DropPlayerItems(playerid);
		}

		if (IsPlayerInMode(killerid, MODE_BATTLEFIELD)) {
			if (IsPlayerInAnyClan(playerid)) {
				AddClanDeaths(GetPlayerClan(playerid), 1);
				PlayerInfo[playerid][pClanDeaths] ++;
			}
			PlayerInfo[playerid][pDeaths]++;
			new crate = random(100);
			switch (crate) {
				case 0..5: {
					PlayerInfo[killerid][pCrates] ++;
					SendGameMessage(killerid, X11_SERV_INFO, MSG_CRATE_RECEIVED);
				}
			}
			AddTeamWarScore(killerid, 1, 0);
			if (reason == 24) {
				AddTeamWarScore(killerid, 1, 1);
			}
			if (!IsPlayerInRangeOfPoint(playerid, 100.0, X, Y, Z)) {
				AddTeamWarScore(killerid, 1, 3);
			}
			if (!IsPlayerInRangeOfPoint(playerid, 20.0, X, Y, Z)) {
				AddTeamWarScore(killerid, 1, 4);
			}
			if (PlayerInfo[playerid][pBountyAmount]) {
				GivePlayerCash(killerid, PlayerInfo[playerid][pBountyAmount]);
				SendGameMessage(@pVerified, X11_SERV_SUCCESS, MSG_NEWSERVER_60x, MSG_NEWSERVER_1x, PlayerInfo[killerid][PlayerName], killerid, formatInt(PlayerInfo[playerid][pBountyAmount]), PlayerInfo[playerid][PlayerName], playerid);
				PlayerInfo[playerid][pBountyAmount] = 0;
				PlayerInfo[killerid][pBountyPlayersKilled] ++;
			}
			if (PlayerInfo[killerid][pIsSpying] && PlayerInfo[killerid][pSpyTeam] == Team_GetPlayer(playerid)) {
				SendGameMessage(killerid, X11_SERV_INFO, MSG_CLIENT_400x);
				PlayerInfo[playerid][sDisguisedKills] ++;
				PlayerInfo[playerid][pKillsAsSpy] ++;

				GivePlayerScore(killerid, 1);
				GameTextForPlayer(playerid, MSG_SPIED, 3000, 1);
			}

			if (PlayerInfo[playerid][pIsSpying] && PlayerInfo[playerid][pSpyTeam] == Team_GetPlayer(killerid)) {
				GameTextForPlayer(killerid, MSG_SPY_KILLED, 3000, 1);
				PlayerInfo[killerid][pSpiesEliminated] ++;
			}
			if (PlayerInfo[playerid][pIsSpying] && PlayerInfo[playerid][pSpyTeam] == Team_GetPlayer(killerid)) {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_401x);
				GivePlayerScore(killerid, 1);

				PlayerInfo[playerid][sSpiesKilled] ++;
			}
		}
		PlayerInfo[playerid][pSessionDeaths]++;

		UpdatePlayerHUD(killerid);
		UpdatePlayerHUD(playerid);

		foreach (new x: Player) {
			if (IsPlayerInRangeOfPoint(x, 150.0, X, Y, Z)) {
				if (x != killerid && Team_GetPlayer(x) != Team_GetPlayer(playerid)) {
					if (LastTarget[x] == playerid || (IsPlayerInAnyVehicle(x) && GetPlayerVehicleID(x) == GetPlayerVehicleID(killerid)
						&& GetPlayerState(x) == PLAYER_STATE_DRIVER)) {
						SendGameMessage(x, X11_SERV_INFO, MSG_CLIENT_397x, PlayerInfo[killerid][PlayerName], killerid, PlayerInfo[playerid][PlayerName], playerid);

						new string4[60];
						format(string4, sizeof(string4), "Assist Killed ~w~%s", PlayerInfo[playerid][PlayerName]);
						PlayerTextDrawSetString(x, killedtext[x], string4);
						PlayerTextDrawShow(x, killedtext[x]);
						PlayerTextDrawShow(x, killedbox[x]);

						PlayerPlaySound(x, 1095, 0.0, 0.0, 0.0);

						KillTimer(KillerTimer[x]);
						KillerTimer[x] = SetTimerEx("KilledBox", 3000, false, "i", x);

						LogActivity(x, "Assist Killed: %d", gettime(), PlayerInfo[playerid][pAccountId]);

						PlayerInfo[x][pKillAssists] ++;
						if (PlayerInfo[x][pKillAssists] > PlayerInfo[x][pHighestKillAssists]) {
							PlayerInfo[x][pHighestKillAssists] = PlayerInfo[x][pKillAssists];
						}
						PlayerInfo[x][sAssistkills] ++;

						GivePlayerScore(x, 1);

						LastTarget[x] = INVALID_PLAYER_ID;
					}
				}
			}
		}

		PlayerInfo[playerid][pLastKiller] = killerid;

		if (PlayerInfo[killerid][pLastKiller] == playerid && playerid != killerid) {
			SendGameMessage(killerid, X11_SERV_INFO, MSG_CLIENT_399x, PlayerInfo[playerid][PlayerName]);

			PlayerInfo[killerid][pRevengeTakes] ++;

			GivePlayerScore(killerid, 1);
			PlayerInfo[killerid][pLastKiller] = INVALID_PLAYER_ID;
		}

		PlayerInfo[killerid][pKills] ++;
		switch (reason) {
			case 0: PlayerInfo[playerid][pFistKills] ++;
			case 1..18, 39..42: PlayerInfo[playerid][pMeleeKills] ++;
			case 21..24: PlayerInfo[playerid][pPistolKills] ++;
			case WEAPON_TEC9, WEAPON_UZI, WEAPON_MP5: PlayerInfo[killerid][pSMGKills] ++;
			case WEAPON_SHOTGUN, WEAPON_SHOTGSPA, WEAPON_SAWEDOFF: PlayerInfo[killerid][pShotgunKills] ++;
			case WEAPON_MINIGUN, WEAPON_ROCKETLAUNCHER, WEAPON_HEATSEEKER: PlayerInfo[killerid][pHeavyKills] ++;
		}

		GetPlayerPos(playerid, X, Y, Z);
		new Float: Distance = GetPlayerDistanceFromPoint(killerid, X, Y, Z);
		if (Distance < 45.0) {
			PlayerInfo[killerid][pCloseKills] ++;
			if (Distance < PlayerInfo[killerid][pNearestKillDistance]) {
				PlayerInfo[killerid][pNearestKillDistance] = Distance;
			}
		}
		if (Distance > 100.0) {
			PlayerInfo[killerid][pLongDistanceKills] ++;
			if (Distance > PlayerInfo[killerid][pLongestKillDistance]) {
				PlayerInfo[killerid][pLongestKillDistance] = Distance;
			}
		}

		if (reason == WEAPON_SAWEDOFF) {
			PlayerInfo[killerid][pSawnKills] ++;
		}

		new KillerName[MAX_PLAYER_NAME];
		GetPlayerName(killerid, KillerName, sizeof(KillerName));

		if (reason == WEAPON_KNIFE) {
			PlayerInfo[killerid][pKnifeKills] ++;
		}

		if (reason == WEAPON_TEARGAS) {
			PlayerInfo[killerid][sGasKills] ++;
		}

		pStreak[killerid]++;
		SendDeathMessage(killerid, playerid, reason);

		if (pStreak[killerid] > PlayerInfo[killerid][pHighestKillStreak]) {
			SendGameMessage(killerid, X11_SERV_INFO, MSG_CLIENT_548y);
			PlayerInfo[killerid][pHighestKillStreak] = pStreak[killerid];
		}

		PlayerInfo[killerid][pSessionKills]++;

		new string4[60];

		format(string4,sizeof(string4),"~g~Killed By ~r~%s",PlayerInfo[killerid][PlayerName]);
		PlayerTextDrawSetString(playerid,killedby[playerid],string4);
		PlayerTextDrawShow(playerid,killedby[playerid]);
		PlayerTextDrawShow(playerid,deathbox[playerid]);

		format(string4,sizeof(string4),"Eliminated ~w~%s",PlayerInfo[playerid][PlayerName]);
		PlayerTextDrawSetString(killerid,killedtext[killerid],string4);
		PlayerTextDrawShow(killerid,killedtext[killerid]);
		PlayerTextDrawShow(killerid,killedbox[killerid]);

		KillTimer(KillerTimer[killerid]);
		KillerTimer[killerid] = SetTimerEx("KilledBox", 3000, false, "i", killerid);
	}

	//AAC
	for (new i = 0; i < sizeof(AACInfo); i++) {
		if (AACInfo[i][AAC_Target] == playerid) {
			AACInfo[i][AAC_Target] = INVALID_PLAYER_ID;
		}
	}
	PlayerInfo[playerid][pBackup] = INVALID_PLAYER_ID;
	return 1;
}

public OnPlayerPrepareDeath(playerid, animlib[32], animname[32], &anim_lock, &respawn_time) {
	PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
	return 1;
}

public OnPlayerDeathFinished(playerid, bool:cancelable) {
	if (pKillerCam[playerid] != INVALID_PLAYER_ID) {
		TogglePlayerSpectating(playerid, true);
		PlayerSpectatePlayer(playerid, pKillerCam[playerid]);
		RespawnTimer[playerid] = SetTimerEx("Respawn", 2000, false, "i", playerid);
		return 0;
	}
	return 1;
}

//Player update
public OnPlayerUpdate(playerid) {
	new weap = GetPlayerWeapon(playerid);

	new keys, ud, lr;
	GetPlayerKeys(playerid, keys, ud, lr);

	switch (weap) {
	    case 44, 45:
	    {
			if ((keys & KEY_FIRE) && (!IsPlayerInAnyVehicle(playerid))) {
				return 0;
			}
		}
	}

	PlayerInfo[playerid][pLastSync] = GetTickCount();

	if (weap != gLastWeap[playerid]) {
		OnPlayerWeaponChange(playerid);
		gLastWeap[playerid] = weap;
	}

	if (!ud && !lr) {
		StaticPlayer[playerid] = 1;
	}
	else {
		StaticPlayer[playerid] = 0;
		PlayerInfo[playerid][pLastMove] = GetTickCount();
	}

	if (!StaticPlayer[playerid] && gMedicKitStarted[playerid]) {
		gMedicKitStarted[playerid] = false;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_UNFINISHED_USEMK);
		KillTimer(RecoverTimer[playerid]);
		pCooldown[playerid][25] = gettime();
	}

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		if ((p_ClassAbilities(playerid, MEDIC)) && p_ClassAdvanced(playerid) && PlayerInfo[playerid][pLastHitTick] <= gettime() && gMedicTick[playerid] <= GetTickCount()) {
			new Float: HP;
			GetPlayerHealth(playerid, HP);
			if (HP <= 95.0) {
				HP += 5.0;
				SetPlayerHealth(playerid, HP);
				NotifyPlayer(playerid, "You got +5 HP (doctor perk)");
				SetPlayerChatBubble(playerid, "+5 HP (Doctor Class)", X11_LIMEGREEN, 100.0, 3000);
				gMedicTick[playerid] = GetTickCount() + 30000;
				PlayerInfo[playerid][pHealthGained] += 5.0;
			}
		}
	}
	return 1;
}

//Special Vehicles

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
	pVehId[playerid] = vehicleid;

	new string[SMALL_STRING_LEN];
	format(string, sizeof(string), "~g~%s", VehicleNames[GetVehicleModel(vehicleid)-400]);
	GameTextForPlayer(playerid, string, 5000, 1);

	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X, Y, Z);

	for (new i = 0; i < sizeof(SubInfo); i++) {
		if (SubInfo[i][Sub_VID] == vehicleid) {
			ShowCarInfo(playerid, "Submarine", "/fire to fire rockets.", "Scout Class");
			if (!(p_ClassAbilities(playerid, SCOUT))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_SUBMARINE_LOCKED), RemovePlayerFromVehicle(playerid);
		}
	}

	if ((p_ClassAbilities(playerid, GROUNDUNIT)) && p_ClassAdvanced(playerid) && GetVehicleModel(vehicleid) == 432) {
		SetPlayerChatBubble(playerid, "+150 Rhino HP", X11_YELLOW, 100.0, 2000);

		new Float: VHP;
		GetVehicleHealth(vehicleid, VHP);
		if (VHP + 150 <= 1500 && VHP >= 1000) {
			SetVehicleHealth(vehicleid, VHP + 150);
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid) {
	if (PlayerInfo[playerid][pDoorsLocked] == 1) {
		SetVehicleParamsForPlayer(GetPlayerVehicleID(playerid), playerid, false, false);
		PlayerInfo[playerid][pDoorsLocked] = 0;
	}

	LastVehicleID[playerid] = vehicleid;
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid) {
	new vehicleide = GetVehicleModel(vehicleid);
	new modok = islegalcarmod(vehicleide, componentid);
	if (!modok) {
		AntiCheatAlert(playerid, "Vehicle Mod Crasher");
		Kick(playerid);
		return 0;
	}
	return 1;
}

public OnVehicleSpawn(vehicleid) {
	LinkVehicleToInterior(vehicleid, 0);
	SetVehicleVirtualWorld(vehicleid, 0);

	if (GetVehicleModel(vehicleid) == 432) {
		SetVehicleHealth(vehicleid, 2500);
	}

	if (GetVehicleModel(vehicleid) == 553) {
		SetVehicleHealth(vehicleid, 2000);
	}

	foreach(new i: Player) {
		if (gOldVID[i] == vehicleid) {
			gOldVID[i] = -1;
		}
	}

	for (new i = 0; i < sizeof(SubInfo); i++) {
		if (SubInfo[i][Sub_VID] == vehicleid) {
			AttachDynamicObjectToVehicle(SubInfo[i][Sub_Id], SubInfo[i][Sub_VID], 0.0, 0.0, 4.2, 0.0, 0.0, 180.0);
			LinkVehicleToInterior(SubInfo[i][Sub_VID], 169);
			Attach3DTextLabelToVehicle(SubInfo[i][Sub_Label], SubInfo[i][Sub_VID], 0.0, 0.0, 0.0);
			break;
		}
	}

	if (GetVehicleModel(vehicleid) == 553) {
		UpdateDynamic3DTextLabelText(gNevadaLabel[vehicleid], X11_CADETBLUE, "Nevada Bomber\n[4/4]");
		gNevadaRockets[vehicleid] = 4;
	}

	if (GetVehicleModel(vehicleid) == 476) {
		AttachDynamicObjectToVehicle(Rustler_Rockets[vehicleid][0], vehicleid, 2.925019, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
		AttachDynamicObjectToVehicle(Rustler_Rockets[vehicleid][1], vehicleid, 3.605034, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
		AttachDynamicObjectToVehicle(Rustler_Rockets[vehicleid][2], vehicleid, -2.925019, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
		AttachDynamicObjectToVehicle(Rustler_Rockets[vehicleid][3], vehicleid, -3.605034, 0.639999, -0.719999, 0.000000, 0.000000, -90.449951);
		UpdateDynamic3DTextLabelText(gRustlerLabel[vehicleid], X11_CADETBLUE, "Rustler Bomber\n[4/4]");
		gRustlerRockets[vehicleid] = 4;
	}

	if (GetVehicleModel(vehicleid) == 512) {
		UpdateDynamic3DTextLabelText(CropAnthrax[vehicleid][Anthrax_Label], X11_CADETBLUE, "Anthrax Cropduster\n[4/4]");
		CropAnthrax[vehicleid][Anthrax_Rockets] = 4;
		CropAnthrax[vehicleid][Anthrax_Cooldown] = gettime();
	}

	for (new a = 0; a < sizeof(AACInfo); a++) {
		if (AACInfo[a][AAC_Id] == vehicleid) {
			switch (AACInfo[a][AAC_Model]) {
				case 422: AttachDynamicObjectToVehicle(AACInfo[a][AAC_Samsite], AACInfo[a][AAC_Id], 0.009999, -1.449998, -0.534999, 0.0, 0.0, 0.0);
				case 515: AttachDynamicObjectToVehicle(AACInfo[a][AAC_Samsite], AACInfo[a][AAC_Id], 0.000000, -3.520033, -1.179999, 0.000000, 0.000000, 0.000000);
			}
			AACInfo[a][AAC_Rockets] = 4;
			UpdateDynamic3DTextLabelText(AACInfo[a][AAC_Text], X11_CADETBLUE, "Anti Aircraft\n[4/4]");

			break;
		}
	}

	foreach (new i: Player) {
		foreach (new x: teams_loaded)
		{
			if (vehicleid == PrototypeInfo[x][Prototype_Id]) {
				SetVehicleHealth(vehicleid, 1500.0);
				break;
			}
		}
	}
	return 1;
}

public OnUnoccupiedVehicleUpdate(vehicleid, playerid, passenger_seat, Float:new_x, Float:new_y, Float:new_z, Float:vel_x, Float:vel_y, Float:vel_z) {
	if (GetVehicleDistanceFromPoint(vehicleid, new_x, new_y, new_z) > 50.0) {
		PlayerInfo[playerid][pWrapWarnings] ++;
		if (PlayerInfo[playerid][pWrapWarnings] > 3) {
			AntiCheatAlert(playerid, "Car Wrap");
			//Kick(playerid);
		}
		SetVehicleToRespawn(vehicleid);
		return 0;
	}
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid) {
	if (IsPlayerInMode(forplayerid, MODE_BATTLEFIELD)) {
		foreach (new i: teams_loaded) {
			if (vehicleid == PrototypeInfo[i][Prototype_Id]) {
				if (PrototypeInfo[i][Prototype_Attacker] != INVALID_PLAYER_ID || Team_GetPlayer(forplayerid) == i) {
					SetVehicleParamsForPlayer(PrototypeInfo[i][Prototype_Id], forplayerid, 1, 1);
				}
				else {
					SetVehicleParamsForPlayer(PrototypeInfo[i][Prototype_Id], forplayerid, 1, 0);
				}

				break;
			}
		}
	}
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid) {
	return 1;
}

public OnVehicleDeath(vehicleid, killerid) {
	if (PlayerInfo[killerid][pDeathmatchId] > -1) {
		foreach(new i: Player) {
			if (pVehId[i] == vehicleid && killerid != i) {
				DamagePlayer(i, 0.0, killerid, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, true);
			}
		}
	}
	return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid) {
	new Float: VHP;
	GetVehicleHealth(vehicleid, VHP);
	if (VHP <= 300.0) {
		if (GetPlayerScore(playerid) <= 300) {
			if ((IsPlayerInAnyVehicle(playerid) && VHP <= 350.0) || GetVehicleModel(GetPlayerVehicleID(playerid)) == 464) {
				new Float: X, Float: Y, Float: Z;
				GetPlayerPos(playerid, X, Y, Z);
				SetPlayerPos(playerid, X, Y, Z + 200);
				PC_EmulateCommand(playerid, "/ep");
				NotifyPlayer(playerid, "Automatic eject will not work when you reach 300 Score.");
			}
		}
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate) {
	ADMIN_OnPlayerStateChange(playerid, newstate, oldstate);
	TOYS_OnPlayerStateChange(playerid, newstate, oldstate);
	if(newstate == PLAYER_STATE_PASSENGER) {
		new vid = GetPlayerVehicleID(playerid);
		switch (GetVehicleModel(vid)) {
		    case 519, 539, 476, 425, 520, 512, 513, 577, 553: {
			    AntiCheatAlert(playerid, "Vehicle Seat Crasher");
			    Kick(playerid);
			    return 0;
		    }
		}
	}

	/*if (!PlayerInfo[playerid][pSelecting]) {
		switch (newstate) {
			case PLAYER_STATE_ONFOOT,PLAYER_STATE_DRIVER,PLAYER_STATE_PASSENGER,PLAYER_STATE_WASTED: SetHealthBarVisible(playerid, true);
			default: SetHealthBarVisible(playerid, false);
		}
	} else {
		SetHealthBarVisible(playerid, false);
	}*/

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		if (newstate == PLAYER_STATE_PASSENGER && (GetVehicleModel(GetPlayerVehicleID(playerid)) == 497 || GetVehicleModel(GetPlayerVehicleID(playerid)) == 497)) {
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_280x);
		}

		//Class-related vehicle restrictions and other
		if (newstate == PLAYER_STATE_DRIVER) {
			switch (GetVehicleModel(GetPlayerVehicleID(playerid))) {
				case 432:
				{
					if (!Iter_Contains(ePlayers, playerid) && PlayerInfo[playerid][pDeathmatchId] != 7) {
						if (!(p_ClassAbilities(playerid, GROUNDUNIT)) || !p_ClassAdvanced(playerid)) {
							SendGameMessage(playerid, X11_SERV_INFO, MSG_RHINO_ERROR);
							RemovePlayerFromVehicle(playerid);
							ShowCarInfo(playerid, "Rhino", "Shoot enemies using rhino's rockets.", "Rifleman Class");
							PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
						}
					}
				}
				case 447:
				{
					if (Iter_Contains(ePlayers, playerid) && !PlayerInfo[playerid][pDonorLevel]) {
						if ((!(p_ClassAbilities(playerid, JETTROOPER)) || !p_ClassAdvanced(playerid))) {
							if (!(p_ClassAbilities(playerid, PILOT))) {
								SendGameMessage(playerid, X11_SERV_INFO, MSG_SEASP_ERROR);
								RemovePlayerFromVehicle(playerid);
								PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
							}
						}
					}
					if ((p_ClassAbilities(playerid, PILOT)) && p_ClassAdvanced(playerid)) {
						new Float: VHP;
						GetVehicleHealth(GetPlayerVehicleID(playerid), VHP);
						if (VHP + 500 <= 1500 && VHP >= 1000) {
							SetVehicleHealth(GetPlayerVehicleID(playerid), VHP + 500);
						}
						SetPlayerChatBubble(playerid, "+500 health on sea sparrow", X11_BLUE, 120.0, 10000);
						PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
					}
				}
				case 520:
				{
					if (!Iter_Contains(ePlayers, playerid) && !PlayerInfo[playerid][pDonorLevel]) {
						if (!(p_ClassAbilities(playerid, PILOT)) && pDogfightTarget[playerid] == INVALID_PLAYER_ID) {
							SendGameMessage(playerid, X11_SERV_INFO, MSG_HYDRA_ERROR);
							RemovePlayerFromVehicle(playerid);
							PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
						}
					}
					if ((p_ClassAbilities(playerid, PILOT)) && p_ClassAdvanced(playerid)) {
						new Float: VHP;
						GetVehicleHealth(GetPlayerVehicleID(playerid), VHP);
						if (VHP + 500 <= 1500 && VHP >= 1000) {
							SetVehicleHealth(GetPlayerVehicleID(playerid), VHP + 500);
						}
						SetPlayerChatBubble(playerid, "+500 health on hydra", X11_BLUE, 120.0, 10000);
						PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
					}
				}
				case 425:
				{
					if (!Iter_Contains(ePlayers, playerid) && !PlayerInfo[playerid][pDonorLevel]) {
						if (!(p_ClassAbilities(playerid, PILOT))) {
							SendGameMessage(playerid, X11_SERV_INFO, MSG_HUNTER_ERROR);
							RemovePlayerFromVehicle(playerid);
							PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
						}
					}
					if ((p_ClassAbilities(playerid, PILOT)) && p_ClassAdvanced(playerid)) {
						new Float: VHP;
						GetVehicleHealth(GetPlayerVehicleID(playerid), VHP);
						if (VHP + 500 <= 1500 && VHP >= 1000) {
							SetVehicleHealth(GetPlayerVehicleID(playerid), VHP + 500);
						}
						SetPlayerChatBubble(playerid, "+500 health on hunter", X11_BLUE, 120.0, 10000);
						PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
					}
				}
				case 476:
				{
					if (!Iter_Contains(ePlayers, playerid) && !PlayerInfo[playerid][pDonorLevel]) {
						if (!(p_ClassAbilities(playerid, PILOT)) && pDogfightTarget[playerid] == INVALID_PLAYER_ID) {
							SendGameMessage(playerid, X11_SERV_INFO, MSG_RUSTLER_ERROR);
							RemovePlayerFromVehicle(playerid);
							PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
						}
					}
					if ((p_ClassAbilities(playerid, PILOT)) && p_ClassAdvanced(playerid)) {
						new Float: VHP;
						GetVehicleHealth(GetPlayerVehicleID(playerid), VHP);
						if (VHP + 500 <= 1500 && VHP >= 1000) {
							SetVehicleHealth(GetPlayerVehicleID(playerid), VHP + 500);
						}
						SetPlayerChatBubble(playerid, "+500 health on rustler", X11_BLUE, 120.0, 10000);
						PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
					}
					ShowCarInfo(playerid, "Rustler", "/fire to drop rockets.", "Pilot/License");
				}
				case 512:
				{
					if (!Iter_Contains(ePlayers, playerid) && !PlayerInfo[playerid][pDonorLevel]) {
						if (!(p_ClassAbilities(playerid, PILOT))) {
							SendGameMessage(playerid, X11_SERV_INFO, MSG_CROPDUST_ERROR);
							RemovePlayerFromVehicle(playerid);
							PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
						}
					}
					if ((p_ClassAbilities(playerid, PILOT)) && p_ClassAdvanced(playerid)) {
						new Float: VHP;
						GetVehicleHealth(GetPlayerVehicleID(playerid), VHP);
						if (VHP + 500 <= 1500 && VHP >= 1000) {
							SetVehicleHealth(GetPlayerVehicleID(playerid), VHP + 500);
						}
						SetPlayerChatBubble(playerid, "+500 health on cropduster", X11_BLUE, 120.0, 10000);
						PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
					}
					ShowCarInfo(playerid, "Cropduster", "/fire to drop anthrax.", "Pilot/License");
				}
				case 553:
				{
					if (!Iter_Contains(ePlayers, playerid) && !PlayerInfo[playerid][pDonorLevel]) {
						if (!(p_ClassAbilities(playerid, PILOT))) {
							SendGameMessage(playerid, X11_SERV_INFO, MSG_NEVADA_ERROR);
							RemovePlayerFromVehicle(playerid);
							PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
						}
					}
					if ((p_ClassAbilities(playerid, PILOT)) && p_ClassAdvanced(playerid)) {
						new Float: VHP;
						GetVehicleHealth(GetPlayerVehicleID(playerid), VHP);
						if (VHP + 500 <= 1500 && VHP >= 1000) {
							SetVehicleHealth(GetPlayerVehicleID(playerid), VHP + 500);
						}
						SetPlayerChatBubble(playerid, "+500 health on nevada", X11_BLUE, 120.0, 10000);
						PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
					}
					ShowCarInfo(playerid, "Nevada", "/fire to drop rockets.", "Pilot/License");
				}
				default: {
					for (new a = 0; a < sizeof(AACInfo) - 1; a++) {
						if (GetPlayerVehicleID(playerid) == AACInfo[a][AAC_Id]) {
							if ((p_ClassAbilities(playerid, SUPPORT)) && p_ClassAdvanced(playerid)) {
								ShowCarInfo(playerid, "Anti-Aircraft", "/fire to fire rockets", "Veteran Supporter");

								if (!IsValidDynamicObject(AACInfo[a][AAC_Samsite])) {
									AACInfo[a][AAC_Samsite] = CreateDynamicObject(3884, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
									switch (AACInfo[a][AAC_Model]) {
										case 422: AttachDynamicObjectToVehicle(AACInfo[a][AAC_Samsite], AACInfo[a][AAC_Id], 0.009999, -1.449998, -0.534999, 0.0, 0.0, 0.0);
										case 515: AttachDynamicObjectToVehicle(AACInfo[a][AAC_Samsite], AACInfo[a][AAC_Id], 0.000000, -3.520033, -1.179999, 0.000000, 0.000000, 0.000000);
									}
								}
								AACInfo[a][AAC_Driver] = playerid;
							} else {
								ClearAnimations(playerid);
								ShowCarInfo(playerid, "Anti-Aircraft", "/fire to fire rockets", "Veteran Supporter");
							}
							break;
						}
					}
				}
			}
		}

		//Prototypes
		foreach (new i: teams_loaded) {
			if (GetPlayerVehicleID(playerid) == PrototypeInfo[i][Prototype_Id]) {
				if (gettime() >= PrototypeInfo[i][Prototype_Cooldown]) {
					new Float: RandTeamX, Float: RandTeamY;
					GetAreaCenter(Team_GetMapArea(Team_GetPlayer(playerid), 0), Team_GetMapArea(Team_GetPlayer(playerid), 1), Team_GetMapArea(Team_GetPlayer(playerid), 2), Team_GetMapArea(Team_GetPlayer(playerid), 3), RandTeamX, RandTeamY);
					new Float: Z;
					CA_FindZ_For2DCoord(RandTeamX, RandTeamY, Z);
					SetPlayerRaceCheckpoint(playerid, 1, RandTeamX, RandTeamY, Z, 0.0, 0.0, 0.0, 10.0);
					PrototypeInfo[i][Prototype_Attacker] = playerid;
					SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_281x);
				} else {
					SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_282x);

					new Float: X, Float: Y, Float: Z;
					GetPlayerPos(playerid, X, Y, Z);
					SetPlayerPos(playerid, X, Y, Z);
				}
				break;
			}
		}

		//AAC
		if (oldstate == PLAYER_STATE_DRIVER) {
			for (new a = 0; a < sizeof(AACInfo) - 1; a++) {
				if (playerid == AACInfo[a][AAC_Driver]
						&& !IsPlayerInVehicle(playerid, AACInfo[a][AAC_Id])) {
					AACInfo[a][AAC_Driver] = INVALID_PLAYER_ID;
				}
			}
		}
	}

	//General

	if (GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) {
		if (!IsVehicleUsed(GetPlayerVehicleID(playerid))) {
			RemovePlayerFromVehicle(playerid);
		}
	}

	if (newstate == PLAYER_STATE_PASSENGER) {
		new vehicle_drivers = 0;
		foreach (new i: Player) {
			if (GetPlayerVehicleID(i) == GetPlayerVehicleID(playerid)
				&& GetPlayerState(i) == PLAYER_STATE_DRIVER) {
				vehicle_drivers ++;
			}
		}
		if (!vehicle_drivers) {
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_283x);
			PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
		}
	}

	if (oldstate == PLAYER_STATE_DRIVER) {
		foreach (new i: Player) {
			if (GetPlayerVehicleID(i) == GetPlayerVehicleID(playerid)
				&& GetPlayerState(i) == PLAYER_STATE_PASSENGER) {
				PutPlayerInVehicle(i, GetPlayerVehicleID(i), 0);
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_284x);
				break;
			}
		}

		foreach (new i: teams_loaded) {
			if (PrototypeInfo[i][Prototype_Attacker] == playerid && !IsPlayerInVehicle(playerid, PrototypeInfo[i][Prototype_Id])) {
				if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
					PlayerInfo[playerid][pLeavetime] = gettime() + 25;
					SendGameMessage(playerid, X11_SERV_INFO, MSG_PROTOTYPE_TIMELEFT, PlayerInfo[playerid][pLeavetime] - gettime());
					PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
				} else {
					PlayerInfo[playerid][pLeavetime] = gettime();
				}
				break;
			}
		}
	}

	LastVehicleID[playerid] = GetPlayerVehicleID(playerid);
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
	ADMIN_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
	TOYS_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
	if (gRappelling[playerid]) {
		gRappelling[playerid] = 0;
		ClearAnimations(playerid);

		for (new i = 0; i < MAX_ROPES; i++) {
			if (pRope[playerid][RopeID][i] == -1) {
				break;
			}

			DestroyDynamicObject(pRope[playerid][RopeID][i]);
			pRope[playerid][RopeID][i] = -1;
		}
		return 1;
	}

	if (IsPlayerUsingAnims[playerid]) {
		StopAnimLoopPlayer(playerid);
		return 1;
	}

	if (PRESSED(KEY_FIRE) && PlayerInfo[playerid][pSpecId] != INVALID_PLAYER_ID) {
		TogglePlayerSpectating(playerid, false);
		return 1;
	}

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		//Mechanic & OtherIntegration
		if (HOLDING(KEY_FIRE)) {
			PC_EmulateCommand(playerid, "/fire");
			if (GetPlayerWeapon(playerid) == WEAPON_SPRAYCAN && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT &&
				(p_ClassAbilities(playerid, MECHANIC))) {
				for (new i = 0; i < MAX_VEHICLES; i++) {
					new Float: X, Float: Y, Float: Z;
					GetVehiclePos(i, X, Y, Z);
					if (IsPlayerInRangeOfPoint(playerid, 12.5, X, Y, Z)) {
						new Float: vHP;
						GetVehicleHealth(i, vHP);
						SetPlayerLookAt(playerid, X, Y);
						if (vHP < 900.0) {
							if (p_ClassAdvanced(playerid)) {
								vHP += 5.00;
							}
							SetVehicleHealth(i, vHP + RandomEx(5, 10));
						} else if (vHP >= 900.0 && vHP < 1000.0) {
							SetVehicleHealth(i, 1000.0);
							RepairVehicle(i);
						}
					}
				}
			}
		}

		//Submarine Integration
		if (PRESSED(KEY_SECONDARY_ATTACK)) {
			for (new i = 0; i < sizeof(SubInfo); i++) {
				new Float:X, Float:Y, Float:Z;
				GetVehiclePos(SubInfo[i][Sub_VID], X, Y, Z);
				if (IsPlayerInRangeOfPoint(playerid, 7.0, X, Y, Z) && !IsPlayerInAnyVehicle(playerid) && !IsVehicleUpsideDown(SubInfo[i][Sub_VID])) {
					PutPlayerInVehicle(playerid, SubInfo[i][Sub_VID], 0);
					break;
				}
			}
		}

		if (PRESSED(KEY_CTRL_BACK)) {
			if (IsPlayerInAnyVehicle(playerid) && GetVehicleModel(GetPlayerVehicleID(playerid)) == 476
				&& (p_ClassAbilities(playerid, KAMIKAZE))) {
				new Float: X, Float: Y, Float: Z;
				GetPlayerPos(playerid, X, Y, Z);

				new Float: range;
				if (p_ClassAdvanced(playerid)) {
					range = 15.0;
				} else {
					range = 10.0;
				}

				foreach (new x: Player) {
					if (IsPlayerInMode(x, MODE_BATTLEFIELD) && Team_GetPlayer(x) != Team_GetPlayer(playerid) && IsPlayerInRangeOfPoint(x, range, X, Y, Z) && x != playerid) {
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_404x, PlayerInfo[x][PlayerName]);
						GivePlayerScore(playerid, 1);
						DamagePlayer(x, 0.0, playerid, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
						SendGameMessage(x, X11_SERV_INFO, MSG_KAMIKAZED);
					}
				}

				CreateExplosion(X, Y, Z, 7, 7.5);
				SetPlayerHealth(playerid, 0.0);
				return 1;
			}
		}

		//------
		//WatchRoom
		if (pWatching[playerid]) {
			pWatching[playerid] = false;
			SetCameraBehindPlayer(playerid);
			return 1;
		}

		//Hot air balloon :)
		if (PRESSED(KEY_NO)) {
			if (IsPlayerInRangeOfPoint(playerid, 3.0, ballonRouteArray[0][0], ballonRouteArray[0][1], ballonRouteArray[0][2])) {
				if (bRouteCoords == 0) {
					if (Balloon_Timer < gettime()) {
						Balloon_Timer = gettime() + 15;
						SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_23x, PlayerInfo[playerid][PlayerName]);
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_252x);
						Balloontimer = SetTimer("Balloon", 11000, false);
						return 1;
					}  else return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_253x);
				}  else return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_255x);
			}

			//Drone
			if (InDrone[playerid]) {
				InDrone[playerid] = false;

				new Float: X, Float: Y, Float: Z;
				GetPlayerPos(playerid, X, Y, Z);
				new vid = GetPlayerVehicleID(playerid);
				SetPlayerPos(playerid, gDroneLastPos[playerid][0], gDroneLastPos[playerid][1], gDroneLastPos[playerid][2]);
				CarDeleter(vid);
				foreach (new i: Player) {
					if (IsPlayerInRangeOfPoint(i, 7.5, X, Y, Z)) {
						if (i != playerid) {
							DamagePlayer(i, 0.0, playerid, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
							SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_408x, PlayerInfo[i][PlayerName]);
							GivePlayerScore(playerid, 1);
							if (IsPlayerInAnyClan(playerid)) {
								GivePlayerScore(playerid, 1);
								AddClanXP(GetPlayerClan(playerid), 2);
								foreach (new x: Player) {
									if (pClan[x] == pClan[playerid]) {
										SendGameMessage(x, X11_SERV_INFO, MSG_CLIENT_409x, PlayerInfo[playerid][PlayerName]);
									}
								}
							}
						}
					}
				}
				CreateExplosion(X, Y, Z, 6, 7.5);
				return 1;
			}
		}

		if (PRESSED(KEY_YES) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
			new Float: VHP;
			GetVehicleHealth(GetPlayerVehicleID(playerid), VHP);
			if ((IsPlayerInAnyVehicle(playerid) && VHP <= 350.0) || GetVehicleModel(GetPlayerVehicleID(playerid)) == 464) {
				new Float: X, Float: Y, Float: Z;
				GetPlayerPos(playerid, X, Y, Z);
				SetPlayerPos(playerid, X, Y, Z + 500);
				PC_EmulateCommand(playerid, "/ep");
				return 1;
			}
		}

		//Onfoot stuff
		if (PRESSED(KEY_YES) && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
			if ((p_ClassAbilities(playerid, SUPPORT))) {
				inline SupportClass(pid, dialogid, response, listitem, string:inputtext[]) {
					#pragma unused dialogid, inputtext
					if (response) {
						switch (listitem) {
							case 0: SupportHealth(pid);
							case 1: SupportArmour(pid);
							case 2: SupportWeaps(pid);
							case 3: SupportAmmo(pid);
						}
					}
				}
				Dialog_ShowCallback(playerid, using inline SupportClass, DIALOG_STYLE_LIST, MSG_SUPPORT_MENU_CAP, MSG_SUPPORT_MENU_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CLOSE);
				return 1;
			}

			if (GetPlayerScore(playerid) >= 25000) {
				foreach (new i: Player) {
					new Float: X, Float: Y, Float: Z;
					GetPlayerPos(playerid, X, Y, Z);
					if (IsPlayerInRangeOfPoint(i, 3.0, X, Y, Z) && i != playerid && Items_GetPlayer(i, HELMET)) {
						Items_RemovePlayer(i, HELMET);
						return 1;
					}
				}
			}

			if ((p_ClassAbilities(playerid, SCOUT))) {
				if (GetPlayerSpeed(playerid) > 15) return 1;
				if (pCooldown[playerid][38] > gettime()) {
					SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_407x, pCooldown[playerid][38] - gettime());
					return 1;
				}

				new Float: pPos[3];
				GetPlayerPos(playerid, pPos[0], pPos[1], pPos[2]);

				new Float: range = 20.0;
				if (p_ClassAdvanced(playerid)) range = 30.0;
				pCooldown[playerid][38] = gettime() + 15;
				GameTextForPlayer(playerid, MSG_FLASHBANG, 3000, 1);
				foreach (new i: Player) {
					if (IsPlayerInMode(i, MODE_BATTLEFIELD) &&
						Team_GetPlayer(playerid) != Team_GetPlayer(i) && IsPlayerInRangeOfPoint(i, range, pPos[0], pPos[1], pPos[2]) ) {
						PlayerInfo[playerid][pFlashBangedPlayers] ++;
						PlayerTextDrawShow(i, FlashTD[i]);
						pFlashLvl[i] = 10;
						UpdateLabelText(i);
						SetPlayerDrunkLevel(i, 2500);
						SetTimerEx("DecreaseFlash", 600, false, "d", i);
						GameTextForPlayer(i, MSG_FLASHBANGED, 3000, 1);
					}
				}
				return 1;
			}

			new Float: x, Float: y, Float: z2, Float: dist;
			GetPlayerPos(playerid, x, y, z2);

			new Float: z;
			CA_FindZ_For2DCoord(x, y, z);
			//Rope rappelling
			if (!gRappelling[playerid] && z2 > z && z2 < 120.0 && GetPlayerState(playerid) == PLAYER_STATE_PASSENGER
				&& !gRappelling[playerid] && (GetVehicleModel(GetPlayerVehicleID(playerid)) == 497 || GetVehicleModel(GetPlayerVehicleID(playerid)) == 497)) {
				z += 10.0;

				RemovePlayerFromVehicle(playerid);

				GetPlayerPos(playerid, pRope[playerid][RRX], pRope[playerid][RRY], pRope[playerid][RRZ]);
				SetPlayerPos(playerid, x, y, z2 - 5);

				gRappelling[playerid] = 1;
				ApplyAnimation(playerid, "ped", "abseil", 4.0, 0, 0, 0, 1, 0);

				dist = GetPlayerDistanceFromPoint(playerid, x, y, z);

				new numropes = floatround(floatdiv(dist, 5.1), floatround_ceil);
				CreateRope(playerid, numropes);
				return 1;
			} else if (gRappelling[playerid]) {
				ClearAnimations(playerid);

				for (new i = 0; i < MAX_ROPES; i++) {
					if (pRope[playerid][RopeID][i] == -1) {
						break;
					}

					DestroyDynamicObject(pRope[playerid][RopeID][i]);
					pRope[playerid][RopeID][i] = -1;
				}
				return 1;
			}
		}
	}

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD) || IsPlayerInMode(playerid, MODE_PUBG)) {
		if (HOLDING(KEY_FIRE)) {
			if (GetPlayerWeapon(playerid) == WEAPON_TEARGAS && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
				PlayerInfo[playerid][pFixTGGlitch] ++;
				if (PlayerInfo[playerid][pFixTGGlitch] > 3) {
					PlayerInfo[playerid][pFixTGGlitch] = 0;

					new Float: X, Float: Y, Float: Z;
					GetPlayerPos(playerid, X, Y, Z);
					GetXYZInfrontOfPlayer(playerid, X, Y, 3.7);

					foreach (new i: Player) {
						if (IsPlayerInRangeOfPoint(i, 5.0, X, Y, Z) && pCooldown[playerid][32] <= gettime()) {
							if (GetPlayerState(i) == PLAYER_STATE_ONFOOT && i != playerid) {
								pCooldown[playerid][32] = gettime() + 7;
								if (IsPlayerAttachedObjectSlotUsed(playerid, 3)) {
									switch (Items_GetPlayer(i, MASK)) {
										case 1: {
											DamagePlayer(i, 3.5, playerid, WEAPON_TEARGAS, BODY_PART_UNKNOWN, true);
											ApplyAnimation(i, "ped", "gas_cwr", 4.1, 0, 0, 0, 0, 0);
										}
										case 2: {
											DamagePlayer(i, 2.3, playerid, WEAPON_TEARGAS, BODY_PART_UNKNOWN, true);
											ApplyAnimation(i, "ped", "gas_cwr", 4.1, 0, 0, 0, 0, 0);
										}
									}
								} else {
									DamagePlayer(i, 10.5, playerid, WEAPON_TEARGAS, BODY_PART_UNKNOWN, true);
									ApplyAnimation(i, "ped", "gas_cwr", 4.1, 0, 0, 0, 0, 0);
								}
							}
						}
					}
				}
				return 1;
			}
		} else {
			if (!PlayerInfo[playerid][pFixTGGlitch]) {
				PlayerInfo[playerid][pFixTGGlitch] = 0;
			}
		}
	}

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD) || IsPlayerInMode(playerid, MODE_DEATHMATCH)) {
		if (PRESSED(KEY_NO)) {
			if (AntiSK[playerid]) {
				EndProtection(playerid);
				return 1;
			}
		}
	}

	/*if (PRESSED(KEY_YES)) {
		if (PlayerInfo[playerid][pAdminLevel] && IsPlayerInAnyVehicle(playerid) && GetVehicleModel(GetPlayerVehicleID(playerid)) == 592) {
			if (PUBGStarted && !PUBGOpened) {
				foreach (new i: PUBGPlayers) {
					if (GetPlayerState(i) == PLAYER_STATE_SPECTATING) {
						PlayerPlaySound(i, 15805, 0, 0, 0);
						TogglePlayerSpectating(i, false);
					}
				}
			}
			return 1;
		}
	}*/

	return 1;
}

//------------
//Model Selection Fix

public OnPlayerModelSelection(playerid, response, listid, modelid) {
	//Clan Skins
	if (listid == clanskinlist) {
		if (!response) return 1;
		SetClanSkin(GetPlayerClan(playerid), modelid);
		AddClanXP(GetPlayerClan(playerid), -5000);

		foreach(new i: Player) if (pClan[i] == pClan[playerid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_412x, PlayerInfo[playerid][PlayerName], modelid);
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_300x);
		return 1;
	}

	//Toys
	if (listid == toyslist) {
		if (!response) return SendGameMessage(playerid, X11_SERV_INFO, MSG_BODY_TOYS_CANCEL);
		gEditModel[playerid] = modelid;

		inline ToysBodyPart(pid, dialogid, diagresponse, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (!diagresponse) return PC_EmulateCommand(pid, "/toys");
			SetPlayerAttachedObject(pid, gEditSlot[pid], gEditModel[pid], listitem + 1);
			EditAttachedObject(pid, gEditSlot[pid]);
			SendGameMessage(pid, X11_SERV_INFO, MSG_BODY_TOY_ADDED, gEditSlot[pid], gEditSlot[pid]);
			gModelsObj[pid][gEditList[pid]] = gEditModel[pid];
			gModelsSlot[pid][gEditList[pid]] = gEditSlot[pid];
			gModelsPart[pid][gEditList[pid]] = listitem + 1;
			gEditModel[pid] = -1;
			gEditList[pid] = 0;
			gEditSlot[pid] = -1;
		}
		Dialog_ShowCallback(playerid, using inline ToysBodyPart, DIALOG_STYLE_LIST, MSG_DIALOG_SELECT_CAP, MSG_BODY_TOYS_DESC, MSG_DIALOG_SELECT, MSG_DIALOG_CANCEL);
		return 1;
	}
	return 1;
}

//------------

//Checkpoints

public OnPlayerEnterRaceCheckpoint(playerid) {
	RACES_OnPlayerEnterRaceCP(playerid);
	if (!Iter_Contains(ePlayers, playerid) && pRaceId[playerid] == -1) {
		DisablePlayerRaceCheckpoint(playerid);
	}

	if (IsPlayerInAnyVehicle(playerid)) {
		new vehicleid = GetPlayerVehicleID(playerid);

		foreach (new x: teams_loaded) {
			if (vehicleid == PrototypeInfo[x][Prototype_Id] && PrototypeInfo[x][Prototype_Attacker] == playerid) {
				LogActivity(playerid, "Stole prototype [owner: %d]", gettime(), x);

				new crate = random(100);
				switch (crate) {
					case 0..35: {
						PlayerInfo[playerid][pCrates] ++;
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CRATE_RECEIVED);
					}
				}

				PlayerInfo[playerid][pEXPEarned] += 1;

				SetVehicleToRespawn(vehicleid);

				SuccessAlert(playerid);

				PrototypeInfo[x][Prototype_Attacker] = INVALID_PLAYER_ID;

				PrototypeInfo[x][Prototype_Cooldown] = gettime() + 300;

				new update[SMALL_STRING_LEN];
				format(update, sizeof(update), MSG_SERVER_43x, PlayerInfo[playerid][PlayerName], Team_GetName(x));
				SendWarUpdate(update);

				PlayerInfo[playerid][pPrototypesStolen] ++;

				foreach (new i: Player) {
					if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == x) {
						SendGameMessage(i, X11_SERV_INFO, MSG_PROTOTYPE_LOST);
					}
				}

				break;
			}
		}
	}
	return 1;
}

//------------
//Attached Objects/Toys

public OnPlayerEditAttachedObject(playerid, response, index, modelid, boneid, Float:fOffsetX, Float:fOffsetY, Float:fOffsetZ, Float:fRotX, Float:fRotY, Float:fRotZ, Float:fScaleX, Float:fScaleY, Float:fScaleZ) {
	if (response) {
		ao[playerid][index][ao_x] = fOffsetX;
		ao[playerid][index][ao_y] = fOffsetY;
		ao[playerid][index][ao_z] = fOffsetZ;
		ao[playerid][index][ao_rx] = fRotX;
		ao[playerid][index][ao_ry] = fRotY;
		ao[playerid][index][ao_rz] = fRotZ;
		ao[playerid][index][ao_sx] = fScaleX;
		ao[playerid][index][ao_sy] = fScaleY;
		ao[playerid][index][ao_sz] = fScaleZ;
		switch (index) {
			case 2: PlayerInfo[playerid][pAdjustedHelmet] = 1;
			case 3: PlayerInfo[playerid][pAdjustedMask] = 1;
			case 5: PlayerInfo[playerid][pAdjustedDynamite] = 1;
		}
	}
	else
	{
		switch (index) {
			case 2: PlayerInfo[playerid][pAdjustedHelmet] = 0, AttachHelmet(playerid);
			case 3: PlayerInfo[playerid][pAdjustedMask] = 0, AttachMask(playerid);
			case 5: PlayerInfo[playerid][pAdjustedDynamite] = 0, AttachDynamite(playerid);
		}
	}
	return 1;
}

//------------

//Checkpoints

public OnPlayerEnterDynamicCP(playerid, checkpointid) {
	return 1;
}

//Dynamic Areas

public OnPlayerEnterDynamicArea(playerid, areaid) {
	PlayerInfo[playerid][pAreasEntered] ++;
	PlayerInfo[playerid][pLastAreaId] = areaid;
	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !AntiSK[playerid]) {
		if (Nuke_Area == areaid) { //Nuke checkup
			if (!p_ClassAbilities(playerid, NUKEMASTER)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_CLIENT_166x);
			if (Team_GetPlayer(playerid) != gAnthraxOwner) return SendGameMessage(playerid, X11_SERV_ERR, MSG_CLIENT_295x);
			if (nukeCooldown > gettime() && nukeIsLaunched) {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_167x, nukeCooldown - gettime());
			} else {
				new alt[50], string[250], count[MAX_TEAMS] = 0;

				format(string, sizeof(string), "Team\tPlayers in base\n");

				foreach (new i: teams_loaded) {
					foreach (new x: Player) {
						if (IsPlayerInBase(x) && Team_GetPlayer(x) != Team_GetPlayer(playerid)) {
							count[Team_GetPlayer(x)] ++;
						}
					}

					format(alt, sizeof(alt), "{%06x}%s\t%d\n", Team_GetColor(i) >>> 8, Team_GetName(i), count[i]);
					strcat(string, alt);
				}

				inline Nuke(pid, dialogid, response, listitem, string:inputtext[]) {
					#pragma unused dialogid, inputtext
					if (!response) {
						SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_168x);
						return 1;
					}

					if (nukeIsLaunched) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_169x);
					if (listitem == Team_GetPlayer(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_170x);
					Nuke_Priority = 2;

					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_20x, PlayerInfo[pid][PlayerName], Team_GetName(listitem));

					KillTimer(NukeTimer[pid]);
					NukeTimer[pid] = SetTimerEx("OnNukeLaunch", 8000 + (1000 * Nuke_Priority), false, "ii", pid, listitem);
					nukeCooldown = gettime() + 600;
					nukeIsLaunched = 1;
					nukePlayerId = pid;

					SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_171x);
					PlayerInfo[pid][pNukesLaunched] ++;
				}

				Dialog_ShowCallback(playerid, using inline Nuke, DIALOG_STYLE_TABLIST_HEADERS, "Nuclear", string, ">>", "X");
			}
		}
		//Anthrax checkup, another team feature
		if (Anthrax_Area == areaid) {
			if (GetPlayerCash(playerid) < 500000 || gAnthraxOwner == Team_GetPlayer(playerid)) return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0), SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_303x);
			if (gAnthraxCooldown > gettime()) {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_415x, gAnthraxCooldown - gettime());
				return 1;
			}

			inline ConfirmAnthrax(pid, dialogid, response, listitem, string:inputtext[]) {
				#pragma unused dialogid, listitem, inputtext
				if (!response) return 1;

				GivePlayerCash(pid, -500000);
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_305x);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_30x, PlayerInfo[pid][PlayerName], Team_GetName(Team_GetPlayer(pid)));

				gAnthraxOwner = Team_GetPlayer(pid);
				gAnthraxCooldown = gettime() + (60 * 30);
				PlayerPlaySound(pid, 1054, 0.0, 0.0, 0.0);
			}

			Dialog_ShowCallback(playerid, using inline ConfirmAnthrax, DIALOG_STYLE_MSGBOX, MSG_DIALOG_MESSAGE_CAP, MSG_CONFIRM_ANTHRAX, MSG_DIALOG_YES, MSG_DIALOG_NO);
		}
		//Player accessed a TEAM shop
		if (!IsPlayerInAnyVehicle(playerid)) {
			foreach (new i: teams_loaded) {
				if (ShopInfo[i][Shop_Area] == areaid) {
					if (Team_GetPlayer(playerid) == i) {
						pShopDelay[playerid] = gettime() + 3;
						ShowBriefcase(playerid);
					} else {
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_306x);
					}

					break;
				}
			}
		}
	}
	for (new i = 0; i < MAX_SLOTS; i++) {
		if (gWeaponExists[i] && gWeaponArea[i] == areaid) {
			new message[100];
			format(message, sizeof(message), "Use /pickup to pickup %s.", ReturnWeaponName(gWeaponID[i]));
			NotifyPlayer(playerid, message);
			break;
		}
	}

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !AntiSK[playerid]) {
		for (new x = 0; x < MAX_SLOTS; x++) {
			if (gLandmineExists[x] == 1 && gLandmineArea[x] == areaid) {
				if (gLandminePlacer[x] == INVALID_PLAYER_ID || (gLandminePlacer[x] != INVALID_PLAYER_ID && Team_GetPlayer(gLandminePlacer[x]) != Team_GetPlayer(playerid))) {
					KillTimer(gLandmineTimer[x]);
					AlterLandmine(x);

					CreateExplosion(gLandminePos[x][0], gLandminePos[x][1], gLandminePos[x][2], 1, 0.3);

					if (gLandminePlacer[x] != INVALID_PLAYER_ID) {
						DamagePlayer(playerid, 85.6, INVALID_PLAYER_ID, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
					}
					else {
						DamagePlayer(playerid, 85.6, gLandminePlacer[x], WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
					}

					gLandminePlacer[x] = INVALID_PLAYER_ID;
					break;
				}
			}
		}

		for (new i = 0; i < MAX_SLOTS; i++) {
			if (gCarepackExists[i] && gCarepackArea[i] == areaid && gCarepackUsable[i]) {
				gCarepackUsable[i] = 0;
				new random_weapon_id = Iter_Random(allowed_weapons);
				GivePlayerWeapon(playerid, random_weapon_id, Weapons_GetAmmo(random_weapon_id));
				GameTextForPlayer(playerid, ReturnWeaponName(random_weapon_id), 1, 3000);

				KillTimer(gCarepackTimer[i]);
				DestroyDynamicObject(gCarepackObj[i]);
				gCarepackObj[i] = INVALID_OBJECT_ID;
				DestroyDynamic3DTextLabel(gCarepack3DLabel[i]);

				DestroyDynamicArea(areaid);
				gCarepackPos[i][0] = gCarepackPos[i][1] = gCarepackPos[2][0] = 0.0;
				gCarepackExists[i] = 0;

				ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0);
				break;
			}
		}
	}
	return 1;
}

public OnPlayerLeaveDynamicArea(playerid, STREAMER_TAG_AREA:areaid) {
	return 1;
}

//Map teleport
public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ) {
	if (ComparePrivileges(playerid, CMD_OPERATOR)) {
		new Float: Convert_Pos_Z;
		CA_FindZ_For2DCoord(fX, fY, Convert_Pos_Z);
		SetPlayerPos(playerid, fX, fY, Convert_Pos_Z);
	}
	return 1;
}

//Include admin panel on clicking a player
public OnPlayerClickPlayer(playerid, clickedplayerid, source) {
	AdminPanel(playerid, clickedplayerid);
	return 1;
}

/* To avoid errors */
public OnPlayerLeaveDynamicCP(playerid, checkpointid) {
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid) {
	if (clickedid == Text:INVALID_TEXT_DRAW && pStats[playerid] != -1) {
		pStats[playerid] = -1;
		CancelSelectTextDraw(playerid);
		for (new i = 0; i < sizeof(Stats_TD); i++) {
			TextDrawHideForPlayer(playerid, Stats_TD[i]);
		}
		PlayerTextDrawHide(playerid, Stats_PTD[playerid][0]);
		PlayerTextDrawHide(playerid, Stats_PTD[playerid][1]);
		PlayerTextDrawHide(playerid, Stats_PTD[playerid][2]);
		return 1;
	}
	ADMIN_OnPlayerClickTD(playerid, clickedid);

	if (clickedid == Stats_TD[2]) {
		new selec = pStats[playerid] - 1;
		if (selec < 0) {
			pStats[playerid] = 14;
		} else {
			pStats[playerid] = selec;
		}

		new targetid = pStatsID[playerid];
		if (targetid == INVALID_PLAYER_ID) {
			pStats[playerid] = -1;
			CancelSelectTextDraw(playerid);
			for (new i = 0; i < sizeof(Stats_TD); i++) {
				TextDrawHideForPlayer(playerid, Stats_TD[i]);
			}
			PlayerTextDrawHide(playerid, Stats_PTD[playerid][0]);
			PlayerTextDrawHide(playerid, Stats_PTD[playerid][1]);
			PlayerTextDrawHide(playerid, Stats_PTD[playerid][2]);
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_299x);
			return 1;
		}

		UpdatePlayerStatsList(playerid, targetid);

		PlayerTextDrawShow(playerid, Stats_PTD[playerid][1]);
		PlayerTextDrawShow(playerid, Stats_PTD[playerid][2]);
		return 1;
	}

	if (clickedid == Stats_TD[3]) {
		new selec = pStats[playerid] + 1;
		if (selec > 14) {
			pStats[playerid] = 0;
		} else {
			pStats[playerid] = selec;
		}

		new targetid = pStatsID[playerid];
		if (targetid == INVALID_PLAYER_ID) {
			pStats[playerid] = 0;
			CancelSelectTextDraw(playerid);
			for (new i = 0; i < sizeof(Stats_TD); i++) {
				TextDrawHideForPlayer(playerid, Stats_TD[i]);
			}
			PlayerTextDrawHide(playerid, Stats_PTD[playerid][0]);
			PlayerTextDrawHide(playerid, Stats_PTD[playerid][1]);
			PlayerTextDrawHide(playerid, Stats_PTD[playerid][2]);
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_299x);
			return 1;
		}

		UpdatePlayerStatsList(playerid, targetid);

		PlayerTextDrawShow(playerid, Stats_PTD[playerid][1]);
		PlayerTextDrawShow(playerid, Stats_PTD[playerid][2]);
		return 1;
	}

	if (clickedid == Stats_TD[4]) {
		pStats[playerid] = -1;
		CancelSelectTextDraw(playerid);
		for (new i = 0; i < sizeof(Stats_TD); i++) {
			TextDrawHideForPlayer(playerid, Stats_TD[i]);
		}
		PlayerTextDrawHide(playerid, Stats_PTD[playerid][0]);
		PlayerTextDrawHide(playerid, Stats_PTD[playerid][1]);
		PlayerTextDrawHide(playerid, Stats_PTD[playerid][2]);
		return 1;
	}
	return 0;
}

//Objects

public OnDynamicObjectMoved(STREAMER_TAG_OBJECT:objectid) {
	if (ballonObjectId == objectid) {
		MoveBalloon();
	}

	//Anthrax related
	foreach (new i: Player) {
		if (PlayerInfo[i][pAnthrax] == objectid) {
			new Float: X, Float: Y, Float: Z;
			GetDynamicObjectPos(PlayerInfo[i][pAnthrax], X, Y, Z);
			DestroyDynamicObject(PlayerInfo[i][pAnthrax]);
			PlayerInfo[i][pAnthrax] = INVALID_OBJECT_ID;
			for (new x = 0; x < 17; x++) {
				if (IsValidDynamicObject(PlayerInfo[i][pAnthraxEffects][x])) {
					DestroyDynamicObject(PlayerInfo[i][pAnthraxEffects][x]);
				}
				PlayerInfo[i][pAnthraxEffects][x] = INVALID_OBJECT_ID;
			}
			PlayerInfo[i][pAnthraxEffects][0] = CreateDynamicObject(18732, X, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][1] = CreateDynamicObject(18732, X + 5, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][2] = CreateDynamicObject(18732, X - 5, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][3] = CreateDynamicObject(18732, X + 10, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][4] = CreateDynamicObject(18732, X - 10, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][5] = CreateDynamicObject(18732, X + 15, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][6] = CreateDynamicObject(18732, X - 20, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][7] = CreateDynamicObject(18732, X + 25, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][8] = CreateDynamicObject(18732, X - 25, Y, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][9] = CreateDynamicObject(18732, X, Y + 5, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][10] = CreateDynamicObject(18732, X, Y - 5, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][11] = CreateDynamicObject(18732, X, Y + 10, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][12] = CreateDynamicObject(18732, X, Y - 10, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][13] = CreateDynamicObject(18732, X, Y + 15, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][14] = CreateDynamicObject(18732, X, Y - 15, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][15] = CreateDynamicObject(18732, X, Y + 20, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxEffects][16] = CreateDynamicObject(18732, X, Y - 20, Z, 0.0, 0.0, 0.0);
			PlayerInfo[i][pAnthraxTimes] = 40;
			PlayerInfo[i][pAnthraxTimer] = SetTimerEx("AnthraxToxication", 500, false, "ifff", i, X, Y, Z);
			PlayerInfo[i][pAnthraxIntoxications] ++;
		}
	}
	//Related to AAC
	for (new i = 0; i < sizeof(AACInfo); i++) {
		if (AACInfo[i][AAC_RocketId] == objectid) {
			if (AACInfo[i][AAC_Target] == INVALID_PLAYER_ID) {
				new Float: X, Float: Y, Float: Z, Float: New_Z;
				GetDynamicObjectPos(AACInfo[i][AAC_RocketId], X, Y, Z);
				CA_FindZ_For2DCoord(X, Y, New_Z);
				SetDynamicObjectFaceCoords3D(AACInfo[i][AAC_RocketId], X, Y, New_Z, 0.0, 90.0, 90.0);
				if (New_Z != Z) {
					MoveDynamicObject(AACInfo[i][AAC_RocketId], X, Y, New_Z, 50.0);
				} else {
					CreateExplosion(X, Y, Z, 7, 25.0);
					DestroyDynamicObject(AACInfo[i][AAC_RocketId]);
					AACInfo[i][AAC_RocketId] = INVALID_OBJECT_ID;
				}
			}
		}
	}

	for (new i = 0; i < MAX_SLOTS; i++) {
		if (gCarepackExists[i] && gCarepackObj[i] == objectid) {
			gCarepackArea[i] = CreateDynamicSphere(gCarepackPos[i][0], gCarepackPos[i][1], gCarepackPos[i][2],5.0,BF_WORLD,0);
			CA_FindZ_For2DCoord(gCarepackPos[i][0], gCarepackPos[i][1], gCarepackPos[i][2]);

			new Caller[90];
			format(Caller, sizeof(Caller), "Carepack\n"IVORY"Dropped by %s", gCarepackCaller[i]);
			gCarepack3DLabel[i] = CreateDynamic3DTextLabel(Caller, X11_MAROON, gCarepackPos[i][0], gCarepackPos[i][1], gCarepackPos[i][2], 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);

			format(gCarepackCaller[i], MAX_PLAYER_NAME, "");
			gCarepackUsable[i] = 1;
			gCarepackTimer[i] = SetTimerEx("AlterCarepack", 50000, false, "i", i);

			break;
		}
	}
	return 1;
}

//Reset
ResetPlayerVars(playerid) {
	for (new i = 0; i < 20; i ++) {
		pRaceListItem[playerid][i] = -1;
	}
	//
	AntiSK[playerid] =
	pStreak[playerid] =
	PlayerInfo[playerid][pCaptureStreak] =
	pBackupRequested[playerid] =
	pBackupResponded[playerid] =
	pIsDamaged[playerid] =
	PlayerInfo[playerid][pSelecting] =
	pHelmetAttached[playerid] =
	PlayerInfo[playerid][pIsSpying] = 0;
	PlayerInfo[playerid][pSpyTeam] = -1;
	pVehId[playerid] = INVALID_VEHICLE_ID;
	pWatching[playerid] = false;
	gMGOverheat[playerid] = 0;
	pKatanaEnhancement[playerid] = 0;
	gMedicKitHP[playerid] = 0.0;
	gMedicKitStarted[playerid] = false;
	PlayerInfo[playerid][pPickedWeap] = 0;
	PlayerInfo[playerid][pACWarnings] = 0;
	PlayerInfo[playerid][pACCooldown] = gettime();
	if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
	PlayerInfo[playerid][pCar] = -1;
	if (Iter_Contains(ePlayers, playerid)) {
		foreach (new i: ePlayers) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_540x, PlayerInfo[playerid][PlayerName]);
		Iter_Remove(ePlayers, playerid);
		if (!Iter_Count(ePlayers)) {
			new clear_data[E_DATA_ENUM];
			EventInfo = clear_data;
			EventInfo[E_STARTED] = 0;
			EventInfo[E_OPENED] = 0;
			EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
			EventInfo[E_TYPE] = -1;
		} else if (Iter_Count(ePlayers) > 2) {
			//SendGameMessage(playerid, X11_SERV_INFO, MSG_EVENT_WATCH);
		}
		DisablePlayerRaceCheckpoint(playerid);
	}
	new clear_data[E_PLAYER_ENUM];
	pEventInfo[playerid] = clear_data;
	LastDamager[playerid] = INVALID_PLAYER_ID;
	PlayerTextDrawHide(playerid, deathbox[playerid]);
	PlayerTextDrawHide(playerid, killedby[playerid]);
	Attach3DTextLabelToPlayer(RankLabel[playerid], playerid, 0.0, 0.0, 0.7);
	Attach3DTextLabelToPlayer(VipLabel[playerid], playerid, 0.0, 0.0, 0.9);
	LastTarget[playerid] = INVALID_PLAYER_ID;
	DisablePlayerRaceCheckpoint(playerid);
	PlayerInfo[playerid][pBackup] = INVALID_PLAYER_ID;
	PlayerInfo[playerid][pLastHitTick] = gettime();
	PlayerInfo[playerid][acWarnings] = 0;
	PlayerInfo[playerid][acTotalWarnings] = 0;
	PlayerInfo[playerid][acCooldown] = gettime();
	InDrone[playerid] = false;
	PlayerInfo[playerid][AntiAirAlerts] = 0;
	for (new i = 0; i < sizeof(AACInfo); i++) {
		if (AACInfo[i][AAC_Target] == playerid) {
			AACInfo[i][AAC_Target] = INVALID_PLAYER_ID;
		}
	}
	ClearAnimations(playerid);
	PlayerInfo[playerid][pLimit] = gettime();
	PlayerInfo[playerid][pLimit2] = gettime();
	pKillerCam[playerid] = INVALID_PLAYER_ID;
	KillTimer(RespawnTimer[playerid]);
	for (new i = 0; i < 13; i++) {
		pWeaponData[playerid][i] = pAmmoData[playerid][i] = 0;
	}
	pMinigunFires[playerid] = 0;
	PlayerInfo[playerid][pHeadshotStreak] = 0;
	PlayerInfo[playerid][pSpyTeam] = -1;
	LastKilled[playerid] = INVALID_PLAYER_ID;
	foreach (new i: Player) {
		if (pDogfightInviter[i] == playerid) {
			pDogfightInviter[i] = INVALID_PLAYER_ID;
			SendClientMessage(playerid, X11_WINE, "The player you invited for a dogfight respawned.");
		}
	}
	if (IsValidDynamicMapIcon(pWaypoint[playerid])) {
		DestroyDynamicMapIcon(pWaypoint[playerid]);
	}
	GotClanWeap[playerid] = false;
	return 1;
}

//This is mostly related to the selection system, which is also related to teams? Hence we put this here
public OnPlayerRequestClass(playerid, classid) {
	if (PlayerInfo[playerid][pLoggedIn]) {
		UpdatePlayerSUI1(playerid);
		if (!pFirstSpawn[playerid]) {
			ShowPlayerBasicSUI(playerid);
		}
	}
	PlayerInfo[playerid][pSelecting] = 1;

    SetPlayerInterior(playerid, 3);
    SetPlayerPos(playerid, 349.0453, 193.2271, 1014.1797);
    SetPlayerFacingAngle(playerid, 286.25);
    SetPlayerCameraPos(playerid, 352.9164, 194.5702, 1014.1875);
    SetPlayerCameraLookAt(playerid, 349.0453, 193.2271, 1014.1797);

	SetPVarInt(playerid, "ConfirmSpawn", 0);
	Class_LinkToPlayer(playerid, classid);
	return 1;
}

//Player wants to spawn!
public OnPlayerRequestSpawn(playerid) {
	if (!PlayerInfo[playerid][pLoggedIn]) return 0;
	if (!GetPVarInt(playerid, "ConfirmSpawn")) {
		SetPVarInt(playerid, "ConfirmSpawn", 1);
		UpdatePlayerSUI2(playerid);
		SendGameMessage(playerid, X11_SERV_SUCCESS, MSG_CONFIRM_SPAWN);
		return 0;
	}
	HidePlayerSUI(playerid);
	SetPVarInt(playerid, "ConfirmSpawn", 0);
	return 1;
}

//CLAN

//CLAN COMMANDS for handling the clans

alias:ccreate("createclan")
CMD:ccreate(playerid, params[]) {
	if (!pVerified[playerid]) return SendClientMessage(playerid, X11_RED, "Please register an account on our server first.");
	if (GetPlayerScore(playerid) < 500 || GetPlayerCash(playerid) < 500000) {
		return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_174x);
	}
	new clan_name[35], clan_tag[7], clan_rank[10][20], clan_message[60];
	inline CreateClanInline(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem, inputtext
		if (!response) return SendClientMessage(playerid, X11_WINE, "You are not creating any more clans here.");
		CreateClan(pid, clan_name, clan_tag, clan_rank[0],
			clan_rank[1], clan_rank[2], clan_rank[3], clan_rank[4],
			clan_rank[5], clan_rank[6], clan_rank[7], clan_rank[8],
			clan_rank[9], clan_message);
	}

	inline ClanMessage(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 59 || strlen(inputtext) < 3) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 3-59 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan message you entered contains special characters. Continue anyways?");
		format(clan_message, sizeof(clan_message), inputtext);
		new clan_info[1024];
		format(clan_info, sizeof(clan_info),
		""WHITE"Would you like to create the clan \"%s\"?\n\n\
		You will be able to delete this clan only by a request to the management.\n\n\
		You and your clan members will receive extra bonuses on various game activities.\n\
		You can purchase perks for your clan through our VIP shop.\n\
		You will be able to manage your clan through /clan.\n\n\
		"WINE"Confirm clan creation! Here is what we know.\n\
		"YELLOW"Your clan tag: "CADETBLUE"[%s]\n\
		"YELLOW"Clan Rank 1: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 2: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 3: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 4: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 5: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 6: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 7: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 8: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 9: "CADETBLUE"%s\n\
		"YELLOW"Clan Rank 10: "CADETBLUE"%s\n\
		"YELLOW"Clan Message: "CADETBLUE"%s\n\n\
		"WHITE"Create anyway?", clan_name, clan_tag, clan_rank[0],
		clan_rank[1], clan_rank[2], clan_rank[3], clan_rank[4],
		clan_rank[5], clan_rank[6], clan_rank[7], clan_rank[8],
		clan_rank[9], clan_message);
		Dialog_ShowCallback(pid, using inline CreateClanInline, DIALOG_STYLE_MSGBOX, clan_name,
		clan_info, "CREATE", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your clan message will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}

	inline ClanRank10(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 59 || strlen(inputtext) < 3) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[9], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanMessage, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Write some interesting message for people in your clan.\n\
		This is also known as MOTD. Message of the day.", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your tenth clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}
	inline ClanRank9(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[8], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank10, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Write the name of the leader role, the one that will also be assigned to yourself.", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your ninth clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}
	inline ClanRank8(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[7], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank9, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your ninth clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your eighth clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}
	inline ClanRank7(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[6], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank8, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your eighth clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your seventh clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}
	inline ClanRank6(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[5], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank7, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your seventh clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your sixth clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}
	inline ClanRank5(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[4], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank6, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your sixth clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your fifth clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}

	inline ClanRank4(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[3], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank5, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your fifth clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your fourth clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}

	inline ClanRank3(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[2], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank4, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your fourth clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your third clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}

	inline ClanRank2(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[1], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank3, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your third clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your second clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}


	inline ClanRank1(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 14 || strlen(inputtext) < 1) return SendClientMessage(playerid, X11_WINE, "Clan rank doesn't meet the 1-14 characters limit.");
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan rank you entered contains special characters. Continue anyways?");
		format(clan_rank[0], 20, inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank2, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your second clan rank (characters: 1-14).", ">>", "X");
		new message[35 + 65];
		format(message, sizeof(message), "Your first clan rank will be: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}

	inline ClanTag(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 4 || strlen(inputtext) < 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_499x);
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan tag you entered contains special characters. Continue anyways?");
		format(clan_tag, sizeof(clan_tag), inputtext);
		Dialog_ShowCallback(pid, using inline ClanRank1, DIALOG_STYLE_INPUT, clan_name,
		""MAROON"Beginning with ranks from 1 to 10.\n\
		Write the name of your first clan rank, which is the lowest (characters: 1-14).", ">>", "X");
		new message[35 + 50];
		format(message, sizeof(message), "Your new clan's tag is: [%s]", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}

	inline ClanName(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (!response) return SendClientMessage(pid, X11_WINE, "You are not creating any more clans here.");
		if (strlen(inputtext) > 30 || strlen(inputtext) < 5) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_498x);
		if (!IsValidText(inputtext)) SendClientMessage(pid, X11_WINE, "It looks like the clan name you entered contains special characters. Continue anyways?");
		format(clan_name, sizeof(clan_name), inputtext);
		Dialog_ShowCallback(pid, using inline ClanTag, DIALOG_STYLE_INPUT, inputtext,
		""MAROON"Write your clan's tag below to continue (characters 1-4, don't add the tag).", ">>", "X");
		new message[35 + 50];
		format(message, sizeof(message), "Your new clan's name is: %s", inputtext);
		SendClientMessage(pid, X11_CADETBLUE, message);
	}

	Dialog_ShowCallback(playerid, using inline ClanName, DIALOG_STYLE_INPUT, "Create a clan on SvT",
	""WHITE"You are now setting up your clan on SvT.\n\n\
	A clan has a maximum of 10 ranks, once you create the clan you are given rank 10 which is the highest.\n\
	In the creation process you are asked to give more details about the clan before it's successfully created.\n\n\
	All clan permissions are given to rank 10 by default, you can change that in /clan, so as other various clan information.\n\
	"WINE"Please take note that you cannot delete your game account once you're part of a clan.\n\
	"MAROON"Write your clan's name below to continue (characters 5-30).", ">>", "X");
	return 1;
}

//-------------------------------------------------------------------------------------------------------

CMD:clan(playerid) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (GetPlayerClanRank(playerid) < 10) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	if (!IsValidClan(GetPlayerClan(playerid))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

	new clan_message[900];
	format(clan_message, sizeof(clan_message),
	""DEEPSKYBLUE"Clan Moto\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 1\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 2\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 3\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 4\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 5\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 6\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 7\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 8\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 9\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Rank 10\t"CYAN"%s\n\
	"DEEPSKYBLUE"Change Perms\n\
	"DEEPSKYBLUE"Change Name\t"CYAN"%s\n\
	"DEEPSKYBLUE"Change Tag\t"CYAN"%s\n\
	"DEEPSKYBLUE"Clan Perks\n\
	"DEEPSKYBLUE"Clan Delete",
	GetClanMotd(GetPlayerClan(playerid)),
	GetClanRankName(GetPlayerClan(playerid), 1),
	GetClanRankName(GetPlayerClan(playerid), 2),
	GetClanRankName(GetPlayerClan(playerid), 3),
	GetClanRankName(GetPlayerClan(playerid), 4),
	GetClanRankName(GetPlayerClan(playerid), 5),
	GetClanRankName(GetPlayerClan(playerid), 6),
	GetClanRankName(GetPlayerClan(playerid), 7),
	GetClanRankName(GetPlayerClan(playerid), 8),
	GetClanRankName(GetPlayerClan(playerid), 9),
	GetClanRankName(GetPlayerClan(playerid), 10),
	GetPlayerClan(playerid),
	GetClanTag(GetPlayerClan(playerid)));

	AddClanLog(playerid, "Used the /clan command");

	inline ClanManagerClanName(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 31 || strlen(inputtext) <= 4) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_498x);
		if (GetClanXP(GetPlayerClan(pid)) < 500) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_501x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_502x, PlayerInfo[pid][PlayerName], GetClanName(GetPlayerClan(pid)), inputtext);
		SetClanName(GetPlayerClan(pid), inputtext);
		AddClanXP(GetPlayerClan(pid), -500);
		new logmessage[500];
		format(logmessage, sizeof(logmessage), "Updated clan name to: %s (lost 500 XP)", inputtext);
		AddClanLog(pid, logmessage);
	}

	inline ClanManagerClanTag(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 5 || strlen(inputtext) <= 0) return 1; //SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_599x);
		if (GetClanXP(GetPlayerClan(pid)) < 500) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_501x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_504x, PlayerInfo[pid][PlayerName], GetClanTag(GetPlayerClan(pid)), inputtext);
		SetClanTag(GetPlayerClan(pid), inputtext);
		AddClanXP(GetPlayerClan(pid), -500);
		new logmessage[500];
		format(logmessage, sizeof(logmessage), "Updated clan tag to: %s (lost 500 XP)", inputtext);
		AddClanLog(pid, logmessage);
	}

	inline ClanManagerMotd(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 59 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_505x);
		SetClanMotd(GetPlayerClan(pid), inputtext);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_506x, PlayerInfo[pid][PlayerName], inputtext);
		new logmessage[500];
		format(logmessage, sizeof(logmessage), "Updated clan motd to: %s", inputtext);
		AddClanLog(pid, logmessage);
	}

	inline ClanManagerRank1(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 1), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 1), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 1, inputtext);
	}

	inline ClanManagerRank2(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 2), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 2), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 2, inputtext);
	}

	inline ClanManagerRank3(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 3), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 3), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 3, inputtext);
	}

	inline ClanManagerRank4(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 4), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 4), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 4, inputtext);
	}

	inline ClanManagerRank5(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 5), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 5), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 5, inputtext);
	}

	inline ClanManagerRank6(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 6), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 6), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 6, inputtext);
	}

	inline ClanManagerRank7(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 7), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 7), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 7, inputtext);
	}

	inline ClanManagerRank8(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 8), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 8), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 8, inputtext);
	}

	inline ClanManagerRank9(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 9), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 9), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 9, inputtext);
	}

	inline ClanManagerRank10(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strlen(inputtext) >= 19 || strlen(inputtext) <= 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_507x);
		PC_EmulateCommand(pid, "/clan");
		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_508x, PlayerInfo[pid][PlayerName], GetClanRankName(GetPlayerClan(pid), 10), inputtext);
		new logmessage[SMALL_STRING_LEN];
		format(logmessage, sizeof(logmessage), "Updated clan rank %s to %s", GetClanRankName(GetPlayerClan(pid), 10), inputtext);
		AddClanLog(pid, logmessage);
		SetClanRankName(GetPlayerClan(pid), 10, inputtext);
	}

	inline ClanManagerPermsInvite(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strval(inputtext) > 10 || strval(inputtext) < 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_509x);
		SetClanAddPerms(GetPlayerClan(pid), strval(inputtext));
		SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_510x);
		PC_EmulateCommand(pid, "/clan");
		AddClanLog(pid, "Changed clan permissions");
	}

	inline ClanManagerPermsWar(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (strval(inputtext) > 10 || strval(inputtext) < 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_509x);
		SetClanWarPerms(GetPlayerClan(pid), strval(inputtext));
		SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_510x);
		PC_EmulateCommand(pid, "/clan");
		AddClanLog(pid, "Changed clan permissions");
	}

	inline ClanManagerPermsRanks(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/clan");
		if (strval(inputtext) > 10 || strval(inputtext) < 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_509x);
		SetClanSetPerms(GetPlayerClan(pid), strval(inputtext));
		SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_510x);
		PC_EmulateCommand(pid, "/clan");
		AddClanLog(pid, "Changed clan permissions");
	}

	inline ClanManagerClanPerms(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
			switch (listitem) {
				case 0: Dialog_ShowCallback(pid, using inline ClanManagerPermsInvite, DIALOG_STYLE_INPUT, MSG_CLAN_PERMS_CAP, MSG_CLAN_FIRST_PERM_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 1: Dialog_ShowCallback(pid, using inline ClanManagerPermsWar, DIALOG_STYLE_INPUT, MSG_CLAN_PERMS_CAP, MSG_CLAN_SECOND_PERM_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 2: Dialog_ShowCallback(pid, using inline ClanManagerPermsRanks, DIALOG_STYLE_INPUT, MSG_CLAN_PERMS_CAP, MSG_CLAN_THIRD_PERM_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
			}
		} else {
			PC_EmulateCommand(pid, "/clan");
		}
	}

	inline ClanManager(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			if (!IsPlayerInAnyClan(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
			switch (listitem) {
				case 0: Dialog_ShowCallback(pid, using inline ClanManagerMotd, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_CLAN_MOTD_CHANGE, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 1: Dialog_ShowCallback(pid, using inline ClanManagerRank1, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 2: Dialog_ShowCallback(pid, using inline ClanManagerRank2, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 3: Dialog_ShowCallback(pid, using inline ClanManagerRank3, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 4: Dialog_ShowCallback(pid, using inline ClanManagerRank4, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 5: Dialog_ShowCallback(pid, using inline ClanManagerRank5, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 6: Dialog_ShowCallback(pid, using inline ClanManagerRank6, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 7: Dialog_ShowCallback(pid, using inline ClanManagerRank7, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 8: Dialog_ShowCallback(pid, using inline ClanManagerRank8, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 9: Dialog_ShowCallback(pid, using inline ClanManagerRank9, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 10: Dialog_ShowCallback(pid, using inline ClanManagerRank10, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_NEW_CLAN_RANK_DESC, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 11: { 
					new string[LARGE_STRING_LEN];
					format(string, sizeof(string), MSG_CLAN_RANK_PERMS_DESC, GetClanRankName(GetPlayerClan(pid), GetClanAddPerms(GetPlayerClan(pid))), GetClanRankName(GetPlayerClan(pid), GetClanWarPerms(GetPlayerClan(pid))), GetClanRankName(GetPlayerClan(pid), GetClanSetPerms(GetPlayerClan(pid))));
					Dialog_ShowCallback(pid, using inline ClanManagerClanPerms, DIALOG_STYLE_TABLIST, MSG_DIALOG_SELECT_CAP, string, MSG_DIALOG_SELECT, MSG_DIALOG_CANCEL);
				}
				case 12: Dialog_ShowCallback(pid, using inline ClanManagerClanName, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_CLAN_NAME_CHANGE, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 13: Dialog_ShowCallback(pid, using inline ClanManagerClanTag, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_CLAN_TAG_CHANGE, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
				case 14: PC_EmulateCommand(pid, "/clanperks");
				case 15: {
					DeleteClan(playerid);
				}
			}
		}
	}
	Dialog_ShowCallback(playerid, using inline ClanManager, DIALOG_STYLE_TABLIST, GetPlayerClan(playerid), clan_message, ">>", "X");
	return 1;
}

CMD:clanperks(playerid) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_311x);
	if (GetPlayerClanRank(playerid) < 10) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	if (!IsValidClan(GetPlayerClan(playerid))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

	inline ClanPerks(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			switch (listitem) {
				case 0: {
					PC_EmulateCommand(pid, "/cskin");
				}
				case 1: {
					PC_EmulateCommand(pid, "/cweapon");
				}
			}
		}
	}

	Dialog_ShowCallback(playerid, using inline ClanPerks, DIALOG_STYLE_TABLIST, MSG_CLAN_PERKS_CAP, MSG_CLAN_PERKS_DESC, MSG_DIALOG_PURCHASE, MSG_DIALOG_CANCEL);
	AddClanLog(playerid, "Used the /clanperks command");
	return 1;
}

CMD:cmembers(playerid) {
	if (!IsPlayerInAnyClan(playerid) || !IsValidClan(GetPlayerClan(playerid))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	SendClientMessage(playerid, X11_GREEN, "All clan members:-");
	new Cache: CMembers, query[175];
	mysql_format(Database, query, sizeof(query), "SELECT d1.Username, d1.ClanRank, d1.LastVisit, d2.ClanName FROM `Players` AS d1, ClansData AS d2 WHERE d1.ClanId = '%d' AND d2.ClanId = d1.ClanId", pClan[playerid]);
	CMembers = mysql_query(Database, query);
	if (cache_num_rows() > 0) {
		for (new i, j = cache_num_rows(); i != j; i++) {
			new username[MAX_PLAYER_NAME], clan_name[35], clan_rank, last_visit;
			cache_set_active(CMembers);
			cache_get_value(i, "Username", username, sizeof(username));
			cache_get_value(i, "ClanName", clan_name, sizeof(clan_name));
			cache_get_value_int(i, "ClanRank", clan_rank);
			cache_get_value_int(i, "LastVisit", last_visit);
			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_21x, i + 1, username, GetClanRankName(clan_name, clan_rank), clan_rank, GetWhen(last_visit, gettime()));
		}
	} else SendGameMessage(playerid, X11_SERV_INFO, MSG_EMPTY_CLAN);
	cache_delete(CMembers);
	return 1;
}

CMD:cmon(playerid) {
	if (IsPlayerInAnyClan(playerid)) {
		SendClientMessage(playerid, X11_GREEN, "Online clan members:-");
		new string[95];
		foreach(new i: Player) {
			if (IsPlayerInAnyClan(i) && pClan[playerid] == pClan[i]) {
				format(string, sizeof(string), "%s - %s (%d)", PlayerInfo[i][PlayerName], GetPlayerClanRankName(i), GetPlayerClanRank(i));
				SendClientMessage(playerid, 0x0099CCFF, string);
			}
		}
		if (isnull(string)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	}
	else
		return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	return 1;
}

CMD:clogger(playerid, params[]) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (GetPlayerClanRank(playerid) < 10) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

	new query[SMALL_STRING_LEN];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ClanLog` WHERE `cID` = '%d' ORDER BY `ID` DESC LIMIT 15", pClan[playerid]);
	mysql_tquery(Database, query, "OnClanLogView", "i", playerid);
	return 1;
}

alias:clans("topclans")
CMD:clans(playerid) {
	new Cache: topClans;
	topClans = mysql_query(Database, "SELECT `ClanName`, `ClanPoints` FROM `ClansData` ORDER BY `ClanPoints` DESC LIMIT 10");
	if (cache_num_rows()) {
		SendClientMessage(playerid, X11_WINE, "The following are the top 10 clans ordered by points:");
		for (new i = 0; i < cache_num_rows(); i++) {
			new clanName[35], clanPoints;
			cache_get_value(i, "ClanName", clanName);
			cache_get_value_int(i, "ClanPoints", clanPoints);

			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_185x, clanName, i + 1, clanPoints);
		}
	} else SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	cache_delete(topClans);
	return 1;
}

CMD:usetag(playerid) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (!PlayerInfo[playerid][pClanTag]) {
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		PlayerInfo[playerid][pClanTag] = 1;
	}
	else
	{
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		PlayerInfo[playerid][pClanTag] = 0;
	}
	return 1;
}

CMD:cann(playerid, params[]) {
	if (IsPlayerInAnyClan(playerid) && GetPlayerClanRank(playerid) == 10) {
		if (GetClanLevel(GetPlayerClan(playerid)) >= 7) {
			new message[SMALL_STRING_LEN];
			format(message, sizeof(message), "Clan %s is open for new members, contact %s[%d] for more information.", GetPlayerClan(playerid),
				PlayerInfo[playerid][PlayerName], playerid);
			SendClientMessageToAll(0x30A69EFF, message);
			AddClanLog(playerid, "Advertised clan");
			format(message, sizeof(message), "Clan %s is open for new members~n~contact %s[%d] for more information.", GetPlayerClan(playerid),
				PlayerInfo[playerid][PlayerName], playerid);
			TextDrawSetString(CAdv_TD[1], message);
			foreach (new i: Player) {
				TextDrawShowForPlayer(i, CAdv_TD[0]);
				TextDrawShowForPlayer(i, CAdv_TD[1]);
			}
			SetTimer("HideClanAdv", 15000, false);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_518x);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	return 1;
}

CMD:c(playerid, params[]) {
	if (isnull(params)) return 1;
	new message[150 + MAX_PLAYER_NAME];

	if (IsPlayerInAnyClan(playerid)) {
		foreach (new i: Player) {
			if (IsPlayerInAnyClan(i)) {
				if (pClan[playerid] == pClan[i]) {
					format(message, sizeof(message), "[C-%s]{%06x} %s %s[%d]:"IVORY" %s", GetPlayerClan(playerid), GetPlayerColor(playerid) >>> 8, GetPlayerClanRankName(playerid), PlayerInfo[playerid][PlayerName], playerid, params);
					SendClientMessage(i, 0xFFFF00FF, message);
				}
			}
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	return 1;
}

CMD:csetleader(playerid, params[]) {
	if (IsPlayerInAnyClan(playerid)) {
		if (GetPlayerClanRank(playerid) < 10) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		new targetid;
		if (sscanf(params, "ud", targetid)) return ShowSyntax(playerid, "/csetleader [playerid/name]");
		if (!pVerified[targetid] || targetid == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);

		if (IsPlayerInAnyClan(targetid) && pClan[playerid] == pClan[targetid]) {
			if (pClanRank[targetid] != 10) {
				pClanRank[targetid] = 10;
			} else {
				pClanRank[targetid] = 9;
			}

			foreach (new i: Player) {
				if (IsPlayerInAnyClan(i)) {
					if (pClan[playerid] == pClan[i]) {
						SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_520x, PlayerInfo[targetid][PlayerName], GetClanRankName(GetPlayerClan(playerid), pClanRank[targetid]));
					}
				}
			}

			new message[90];
			format(message, sizeof(message), "Made #%d level %d in clan", PlayerInfo[targetid][pAccountId], pClanRank[targetid]);
			AddClanLog(playerid, message);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_434x);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	return 1;
}

CMD:resetskin(playerid, params[]) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (GetClanSkin(GetPlayerClan(playerid)) == 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_521x);

	SetClanSkin(GetPlayerClan(playerid), 0);
	AddClanXP(GetPlayerClan(playerid), 5000);
	AddClanLog(playerid, "Reset the clan skin");
	foreach(new i: Player) if (pClan[i] == pClan[playerid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_522x, PlayerInfo[playerid][PlayerName]);
	return 1;
}

CMD:csetrank(playerid, params[]) {
	if (IsPlayerInAnyClan(playerid)) {
		if (GetPlayerClanRank(playerid) < GetClanSetPerms(GetPlayerClan(playerid))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		new rankid, targetid;
		if (sscanf(params, "ud", targetid, rankid)) return ShowSyntax(playerid, "/csetrank [playerid/name] [level 1-9]");
		if (rankid > 9 || rankid < 1) return ShowSyntax(playerid, "/csetrank [player name/id] [level 1-9]");
		if (!pVerified[targetid] || targetid == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);

		if (IsPlayerInAnyClan(targetid) && pClan[playerid] == pClan[targetid]) {
			if (pClanRank[targetid] >= pClanRank[playerid]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
			if (pClanRank[targetid] == rankid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

			pClanRank[targetid] = rankid;

			foreach (new i: Player) {
				if (IsPlayerInAnyClan(i)) {
					if (pClan[playerid] == pClan[i]) {
						SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_520x, PlayerInfo[playerid][PlayerName], GetClanRankName(GetPlayerClan(playerid), pClanRank[targetid]));
					}
				}
			}

			new message[90];
			format(message, sizeof(message), "Made #%d level %d in clan", PlayerInfo[targetid][pAccountId], pClanRank[targetid]);
			AddClanLog(playerid, message);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_523x);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	return 1;
}

CMD:claninfo(playerid, params[]) {
	if (!IsPlayerInAnyClan(playerid) && !ComparePrivileges(playerid, CMD_OWNER)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);

	new clan[35];
	if (isnull(params)) {
		if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_524x);
		format(clan, sizeof(clan), GetPlayerClan(playerid));
	} else {
		if (!IsValidClanTag(params) && !IsValidClan(params)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_525x);
		format(clan, sizeof(clan), params);
	}

	new Cache: ClanSearch, query[256];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ClansData` WHERE `ClanName` LIKE '%e' LIMIT 1", clan);
	ClanSearch = mysql_query(Database, query);
	if (cache_num_rows()) {
		new clan_name[35], clan_tag[10], clan_weapon, clan_skin, clan_wallet, clan_points, clan_level, clan_kills, clan_deaths, clan_motd[60];
		cache_get_value(0, "ClanName", clan_name, sizeof(clan_name));
		cache_get_value(0, "ClanTag", clan_tag, sizeof(clan_tag));
		cache_get_value(0, "ClanMotd", clan_motd, sizeof(clan_motd));
		cache_get_value_int(0, "ClanWeap", clan_weapon);
		cache_get_value_int(0, "ClanSkin", clan_skin);
		cache_get_value_int(0, "ClanWallet", clan_wallet);
		cache_get_value_int(0, "ClanPoints", clan_points);
		cache_get_value_int(0, "ClanLevel", clan_level);
		cache_get_value_int(0, "ClanKills", clan_kills);
		cache_get_value_int(0, "ClanDeaths", clan_deaths);

		new clan_stats[170], full_stats[170 * 5];
		format(clan_stats, sizeof(clan_stats), ""IVORY"Clan name:"DEEPSKYBLUE" %s\n"IVORY"Clan tag:"DEEPSKYBLUE" %s\n"IVORY"Clan weapon:"DEEPSKYBLUE" %s\n",
		clan_name, clan_tag, clan_weapon != 0 ? ReturnWeaponName(clan_weapon) : "None");
		strcat(full_stats, clan_stats);

		format(clan_stats, sizeof(clan_stats), ""IVORY"Clan wallet:"DEEPSKYBLUE" %s\n"IVORY"clan points:"DEEPSKYBLUE" %d\n"IVORY"Clan rank:"DEEPSKYBLUE" %s\n"IVORY"Clan level:"DEEPSKYBLUE" %d\n",
		formatInt(clan_wallet), clan_points, ClanRanks[clan_level][C_LevelName], clan_level);
		strcat(full_stats, clan_stats);

		format(clan_stats, sizeof(clan_stats), ""IVORY"Clan motd:"DEEPSKYBLUE" %s\n"IVORY"Clan kills:"DEEPSKYBLUE" %d\n"IVORY"Clan deaths:"DEEPSKYBLUE" %d\n"IVORY"Clan KDR:"DEEPSKYBLUE" %0.2f",
		clan_motd, clan_kills, clan_deaths, floatdiv(clan_kills, clan_deaths));
		strcat(full_stats, clan_stats);

		Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, clan, full_stats, "X", "");
	} else SendClientMessage(playerid, X11_WINE, "[ERROR] We couldn't find any matches for this clan name/tag.");
	cache_delete(ClanSearch);
	return 1;
}

CMD:cdonate(playerid, params[]) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_524x);

	new amount;
	if (sscanf(params, "i", amount)) return ShowSyntax(playerid, "/cdonate [amount]");
	if (amount < 1000) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_526x);
	if (amount > 100000) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_527x);
	if (amount > GetPlayerMoney(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_528x);

	AddClanWallet(GetPlayerClan(playerid), amount);
	GivePlayerCash(playerid, -amount);

	foreach (new i: Player) {
		if (IsPlayerInAnyClan(i)) {
			if (pClan[playerid] == pClan[i]) {
				SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_529x, PlayerInfo[playerid][PlayerName], formatInt(amount));
			}
		}
	}

	new message[90];
	format(message, sizeof(message), "Donated %s to the clan", formatInt(amount));
	AddClanLog(playerid, message);
	return 1;
}

CMD:cwithdraw(playerid, params[]) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (GetPlayerClanRank(playerid) < 10) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

	new amount;
	if (sscanf(params, "i", amount)) return ShowSyntax(playerid, "/cwithdraw [amount]");
	if (amount < 5000 || !amount) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_530x);
	if (amount > 100000) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_531x);
	if (GetClanWallet(GetPlayerClan(playerid)) < amount ||
		!GetClanWallet(GetPlayerClan(playerid))) SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_532x);

	AddClanWallet(GetPlayerClan(playerid), -amount);
	GivePlayerCash(playerid, amount);

	foreach (new i: Player) {
		if (pClan[playerid] == pClan[i]) {
			SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_533x, PlayerInfo[playerid][PlayerName], formatInt(amount));
		}
	}

	new message[90];
	format(message, sizeof(message), "Withdrew %s from the clan", formatInt(amount));
	AddClanLog(playerid, message);
	return 1;
}

CMD:ockick(playerid, params[]) {
	if (IsPlayerInAnyClan(playerid)) {
		if (GetPlayerClanRank(playerid) == 10) {
			new Name[MAX_PLAYER_NAME], Reason[25];

			if (sscanf(params, "s[25]s[25]", Name, Reason)) return ShowSyntax(playerid, "/ockick [name] [reason]");
			if (!strcmp(Name, PlayerInfo[playerid][PlayerName], true)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_390x);

			new query[140];

			mysql_format(Database, query, sizeof(query), "SELECT * FROM `Players` WHERE `Username` = '%e' AND `ClanId` = '%d' LIMIT 1",  Name, pClan[playerid]);
			mysql_tquery(Database, query, "KickClanMember", "is", playerid, Reason);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	}
	return 1;
}

CMD:ckick(playerid, params[]) {
	if (IsPlayerInAnyClan(playerid)) {
		if (GetPlayerClanRank(playerid) >= GetClanAddPerms(GetPlayerClan(playerid))) {
			new targetid, Reason[25];

			if (sscanf(params, "us[25]", targetid, Reason)) return ShowSyntax(playerid, "/ckick [playerid/name] [reason]");
			if (!pVerified[targetid] || targetid == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);

			if (pClan[playerid] == pClan[targetid]) {
				if (pClanRank[targetid] >= pClanRank[playerid]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
				foreach (new i: Player) {
					if (IsPlayerInAnyClan(i)) {
						if (pClan[playerid] == pClan[i]) {
							SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_534x, PlayerInfo[targetid][PlayerName], Reason);
						}
					}
				}

				new query[140];

				mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `ClanId` = '-1', `ClanRank` = '0' WHERE `ID` = '%d' LIMIT 1",  PlayerInfo[targetid][pAccountId]);
				mysql_tquery(Database, query);

				pClan[targetid] = -1;
				pClanRank[targetid] = 0;
				PlayerInfo[targetid][pClanTag] = 0;
				format(query, sizeof(query), "Kicked #%d from the clan", PlayerInfo[targetid][pAccountId]);
				AddClanLog(playerid, query);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_389x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	}
	return 1;
}

CMD:cleave(playerid) {
	if (IsPlayerInAnyClan(playerid)) {
		if (GetPlayerClanRank(playerid) < 10) {
			foreach (new i: Player) {
				if (IsPlayerInAnyClan(i)) {
					if (pClan[playerid] == pClan[i]) {
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_535x, PlayerInfo[playerid][PlayerName]);
					}
				}
			}

			AddClanLog(playerid, "Left the clan");

			pClan[playerid] = -1;
			pClanRank[playerid] = 0;
			PlayerInfo[playerid][pClanTag] = 0;
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_388x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_387x);
	}
	return 1;
}

CMD:cinvite(playerid, params[]) {
	new targetid;

	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (GetPlayerClanRank(playerid) < GetClanAddPerms(GetPlayerClan(playerid))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/cinvite [playerid/name]");
	if (!IsPlayerStreamedIn(targetid, playerid) || targetid == playerid) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_STREAMED);
	if (IsPlayerInAnyClan(targetid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_385x);

	if (pCooldown[playerid][35] > gettime()) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_384x, pCooldown[playerid][35] - gettime());
		return 1;
	}

	pCooldown[playerid][35] = gettime() + 70;

	PlayerInfo[targetid][pIsInvitedToClan] = 1;
	format(PlayerInfo[targetid][pInvitedToClan], 35, "%s", GetPlayerClan(playerid));

	SendGameMessage(targetid, X11_SERV_INFO, MSG_CLIENT_383x, PlayerInfo[playerid][PlayerName], GetPlayerClan(playerid));
	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_382x);

	new message[70];
	format(message, sizeof(message), "Invited #%d to the clan", PlayerInfo[targetid][pAccountId]);
	AddClanLog(playerid, message);

	KillTimer(InviteTimer[targetid]);
	InviteTimer[targetid] = SetTimerEx("CancelInvite", 9000, false, "i", targetid);
	return 1;
}

CMD:accept(playerid, params[]) {
	if (IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_381x);
	if (!PlayerInfo[playerid][pIsInvitedToClan]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_380x);
	PlayerInfo[playerid][pIsInvitedToClan] = 0;

	KillTimer(InviteTimer[playerid]);

	pClan[playerid] = GetClanIdByName(PlayerInfo[playerid][pInvitedToClan]);
	pClanRank[playerid] = 1;

	foreach (new i: Player) {
		if (IsPlayerInAnyClan(i)) {
			if (pClan[playerid] == pClan[i]) {
				SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_536x, PlayerInfo[playerid][PlayerName]);
			}
		}
	}

	AddClanLog(playerid, "Joined the clan");
	return 1;
}

CMD:clanpoints(playerid) {
	inline ClanPoints(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, response, listitem, inputtext
		//nothing...
	}
	Dialog_ShowCallback(playerid, using inline ClanPoints, DIALOG_STYLE_TABLIST_HEADERS, MSG_CLAN_POINTS_CAP, MSG_CLAN_POINTS_DESC, MSG_DIALOG_GOTIT, "");
	return 1;
}

CMD:clanranks(playerid) {
	new c_info[1024];
	strcat(c_info, "Rank\tPoints\n");
	for (new i = 0; i < sizeof(ClanRanks); i++) {
		format(c_info, sizeof(c_info), ""YELLOW"%s(#%d) %s\t["LIMEGREEN"%d"WHITE"]\n", c_info, i, ClanRanks[i][C_LevelName], ClanRanks[i][C_LevelXP]);
	}

	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLAN_RANKS_HINT);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLAN_RANKS_2HINT);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLAN_RANKS_3HINT);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLAN_RANKS_4HINT);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLAN_RANKS_5HINT);
	Dialog_Show(playerid, DIALOG_STYLE_TABLIST_HEADERS, "Clan Ranks", c_info, "X", "");
	return 1;
}

CMD:cskin(playerid) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (GetPlayerClanRank(playerid) < 10) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	if (GetClanXP(GetPlayerClan(playerid)) < 5000) return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0), SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_377x);
	ShowModelSelectionMenu(playerid, clanskinlist, "Clan Skins", 0x000000CC, X11_DEEPPINK, X11_IVORY);
	AddClanLog(playerid, "Accessed the clan skin command");
	return 1;
}

CMD:cweapon(playerid) {
	if (!IsPlayerInAnyClan(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_358x);
	if (GetPlayerClanRank(playerid) < 10) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	if (GetClanXP(GetPlayerClan(playerid)) < 5000) return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0), SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_377x);

	new weapons_str[65], overall[970], weapon_listitem[MAX_WEAPONS], total_weapons;
	strcat(overall, "Weapon\tAmmo\tPrice\n");

	foreach (new i: allowed_weapons) {
		format(weapons_str, sizeof(weapons_str), ""LIGHTBLUE"%s\t"IVORY"%d\t"YELLOW"%s\n", ReturnWeaponName(i), Weapons_GetAmmo(i), formatInt(Weapons_GetPrice(i)));
		strcat(overall, weapons_str);
		weapon_listitem[total_weapons] = i;
		total_weapons ++;
	}

	inline ClanWeapon(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return 1;
		if (GetClanWallet(GetPlayerClan(pid)) < Weapons_GetPrice(weapon_listitem[listitem])) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_379x);
		if (GetClanXP(GetPlayerClan(pid)) < 5000) return PlayerPlaySound(pid, 1055, 0.0, 0.0, 0.0), SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_377x);
		AddClanXP(GetPlayerClan(pid), -5000);
		AddClanWallet(GetPlayerClan(pid), -Weapons_GetPrice(weapon_listitem[listitem]));

		SetClanWeapon(GetPlayerClan(pid), weapon_listitem[listitem]);
		PlayerPlaySound(pid, 1054, 0.0, 0.0, 0.0);

		foreach(new i: Player) if (pClan[i] == pClan[pid]) SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_537x, ReturnWeaponName(weapon_listitem[listitem]), formatInt(Weapons_GetAmmo(weapon_listitem[listitem])));
		AddClanLog(pid, "Changed clan weapon (lost cash and 5000 XP)");

		SendClientMessage(pid, X11_GREEN, "Remember: Your clan members have to use /cweap to spawn this clan weapon!");
	}

	Dialog_ShowCallback(playerid, using inline ClanWeapon, DIALOG_STYLE_TABLIST_HEADERS, "Clan Weapon:", overall, ">>", "X");
	AddClanLog(playerid, "Accessed the clan weapon command");
	return 1;
}

//Stats command

CMD:stats(playerid, params[]) {
	new  targetid;

	if (isnull(params)) targetid = playerid;
	else targetid = strval(params);

	if (pVerified[targetid]) {
		pStats[playerid] = 0;
		pStatsID[playerid] = targetid;

		new player_name[MAX_PLAYER_NAME + 5];
		if (targetid == playerid) {
			format(player_name, sizeof(player_name), "%s (You)", PlayerInfo[targetid][PlayerName]);
		} else {
			format(player_name, sizeof(player_name), PlayerInfo[targetid][PlayerName]);
		}

		PlayerTextDrawSetString(playerid, Stats_PTD[playerid][0], player_name);
		PlayerTextDrawShow(playerid, Stats_PTD[playerid][0]);

		UpdatePlayerStatsList(playerid, targetid);
		PlayerTextDrawShow(playerid, Stats_PTD[playerid][1]);
		PlayerTextDrawShow(playerid, Stats_PTD[playerid][2]);

		for (new i = 0; i < sizeof(Stats_TD); i++) {
			TextDrawShowForPlayer(playerid, Stats_TD[i]);
		}

		SelectTextDraw(playerid, X11_BLUE);

	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
	return 1;
}

//World/Mode Detection

GetPlayerGameMode(playerid) {
	if (PlayerInfo[playerid][pIsAFK]
		|| PlayerInfo[playerid][pFrozen] || PlayerInfo[playerid][pJailed]
		|| !pVerified[playerid]) return MODE_DISABLED;
	if (!IsPlayerSpawned(playerid) && !IsPlayerDying(playerid)) return MODE_DISABLED;
	new world = GetPlayerVirtualWorld(playerid);
	switch (world) {
		case SPECIAL_WORLD, JAIL_WORLD: return MODE_DISABLED;
		case DM_WORLD: return MODE_DEATHMATCH;
		case PUBG_WORLD: return MODE_PUBG;
		default: {
			if (pDuelInfo[playerid][pDInMatch]) return MODE_DUEL;
			if (pDogfightTarget[playerid] != INVALID_PLAYER_ID) return MODE_DOGFIGHT;
			if (Iter_Contains(ePlayers, playerid)) return MODE_EVENT;
			if (Iter_Contains(CWCLAN1, playerid) || Iter_Contains(CWCLAN2, playerid)) return MODE_CLANWAR;
			if (pRaceId[playerid] != -1) return MODE_RACE;
			return MODE_BATTLEFIELD;
		}
	}
	return -1;
}

IsPlayerInMode(playerid, mode) {
	if (GetPlayerGameMode(playerid) == mode) {
		return true;
	}
	return false;
}

CMD:ranks(playerid) {
	new string[200];
	format(string, sizeof(string), "{FFFFFF}There's a total of "GREEN"%d {FFFFFF}ranks.\n\
	Every rank up rewards "GREEN"$1,000 {FFFFFF}and might unlock a special ability (see /rank)\n\
	{FFFFFF}Your current rank is "GREEN"%d", MAX_RANKS, Ranks_GetPlayer(playerid));
	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, ""WINE"SvT - Ranks", string, "X", "");
	return 1;
}

CMD:rank(playerid) {
	new text[100];

	format(text, sizeof(text), "%s (%d/%d)", Ranks_ReturnName(Ranks_GetPlayer(playerid)), Ranks_GetPlayer(playerid), MAX_RANKS - 1);
	SendClientMessage(playerid, X11_YELLOW, text);
	return 1;
}

//Zone offer
CMD:invest(playerid) {
	Zones_ShowOffer(playerid);
	return 1;
}

//Trade
CMD:trade(playerid, params[]) {
	new targetid, string:item[SMALL_STRING_LEN], item_type = -1, item_id, quantity, price;
	if (sscanf(params, "us[128]dd", targetid, item, quantity, price)) return ShowSyntax(playerid, "/trade [player name/id] [item name (weapon/item)] [quantity] [price]");
	if (Items_IsValidName(item) != -1) {
		item_type = ITEM_TYPE_ITEM;
		item_id = Items_IsValidName(item);
	} else if (Weapons_IsValid(item) != -1) {
		item_type = ITEM_TYPE_WEAP;
		item_id = Weapons_IsValid(item);
	}
	if (item_type == -1) return SendGameMessage(playerid, X11_SERV_ERR, ERR_ITEM_NONEXISTENT);
	Trades_OfferItem(playerid, targetid, item_type, item_id, quantity, price);
	return 1;
}

CMD:tradepanel(playerid, params[]) {
	new targetid;
	if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/tradepanel [player name/id]");
	Trades_DisplayPanel(playerid, targetid);
	return 1;
}

//Inventory Commands

alias:inv("inventory")
CMD:inv(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	new selected_item, item_listitem[MAX_ITEMS];

	inline InvManageDialog(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			switch (listitem) {
				case 0:	SendClientMessage(pid, X11_SERV_INFO, Items_GetInfo(selected_item));
				case 1: DropPlayerItem(pid, selected_item, 1);
			}
		}
	}

	inline NewInventoryDialog(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			selected_item = item_listitem[listitem];
			Dialog_ShowCallback(pid, using inline InvManageDialog, DIALOG_STYLE_LIST, Items_GetName(listitem), "Information about this item\nDrop this item", ">>", "X");
		}
	}

	new buf[MEDIUM_STRING_LEN], count = 0;
	strcat(buf, "Item\tBrief\tYour Qty/Max\n");
	for (new i = 0; i < MAX_ITEMS; i++) {
		if (Items_GetPlayer(playerid, i)) {
			format(buf, sizeof(buf), "%s%s\t%s\t%d/%d\n", buf, Items_GetName(i), Items_GetInfo(i), Items_GetPlayer(playerid, i), Items_GetMax(i));
			item_listitem[count] = i;
			count ++;
		}
	}
	if (count) {
		Dialog_ShowCallback(playerid, using inline NewInventoryDialog, DIALOG_STYLE_TABLIST_HEADERS, "Your Items", buf, ">>", "X");
	} else {
		Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "No Items!", "You don't have anything :(", "X", "");
	}	
	return 1;
}

//Medic kits

CMD:mk(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !IsPlayerInMode(playerid, MODE_PUBG)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (Items_GetPlayer(playerid, MK) > 0) {
		if (pCooldown[playerid][25] < gettime()) {
			if (ReturnHealth(playerid) >= 100) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_448x);

			pCooldown[playerid][25] = gettime() + 15;

			KillTimer(RecoverTimer[playerid]);
			gMedicKitStarted[playerid] = true;
			gMedicKitHP[playerid] = 100.0 - ReturnHealth(playerid);
			RecoverTimer[playerid] = SetTimerEx("UseMK", 100, true, "i", playerid);
			AnimPlayer(playerid, "ROB_BANK", "CAT_Safe_Open", 8.0, 0, 0, 0, 0, 0);

			new Float: X, Float: Y, Float: Z;
			GetXYZInfrontOfPlayer(playerid, X, Y, 0.7);
			CA_FindZ_For2DCoord(X, Y, Z);

			new medkit = CreateDynamicObject(11738, X, Y, Z, 0.0, 0.0, 0.0);
			SetTimerEx("DestroyMedkit", 3500, false, "i", medkit);
		} else {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][25] - gettime());
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_446x);
	return 1;
}

//Armour kits

CMD:ak(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !IsPlayerInMode(playerid, MODE_PUBG)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (Items_GetPlayer(playerid, AK) > 0) {
		if (pCooldown[playerid][37] < gettime()) {
			new Float: AR;
			GetPlayerArmour(playerid, AR);
			if (AR >= 100) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_448x);

			pCooldown[playerid][37] = gettime() + 15;

			KillTimer(RecoverTimer[playerid]);
			RecoverTimer[playerid] = SetTimerEx("UseAK", 3000, false, "i", playerid);
			AnimPlayer(playerid, "ROB_BANK", "CAT_Safe_Open", 8.0, 0, 0, 0, 0, 0);

			new Float: X, Float: Y, Float: Z;
			GetXYZInfrontOfPlayer(playerid, X, Y, 0.7);
			CA_FindZ_For2DCoord(X, Y, Z);

			new armourkit = CreateDynamicObject(19515, X, Y, Z + 0.1, 90.0, 0.0, 0.0);
			SetTimerEx("DestroyArmourkit", 3500, false, "i", armourkit);
		} else {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][37] - gettime());
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_446x);
	return 1;
}

//Landmines

alias:landmine("pmine", "plm")
CMD:landmine(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !IsPlayerInMode(playerid, MODE_PUBG)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_445x);
	if (!Items_GetPlayer(playerid, LANDMINES)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_446x);
	if (pCooldown[playerid][9] > gettime()) return SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][9] - gettime());

	new Float: Checkpos[3], Float: Check_X;
	GetPlayerPos(playerid, Checkpos[0], Checkpos[1], Checkpos[2]);

	CA_FindZ_For2DCoord(Checkpos[0], Checkpos[1], Check_X);
	if (Checkpos[2] < Check_X) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	for (new i = 0; i < MAX_SLOTS; i++) {
		if (!gLandmineExists[i]) {
			pCooldown[playerid][9] = gettime() + 35;
			new Float: X, Float: Y, Float: Z;
			GetPlayerPos(playerid, X, Y, Z);
			CA_FindZ_For2DCoord(X, Y, Z);
			gLandmineExists[i] = 1;
			gLandminePlacer[i] = playerid;
			gLandmineObj[i] = CreateDynamicObject(19602, X, Y, Z, 0.0, 0.0, 0.0);
			gLandmineArea[i] = CreateDynamicSphere(X, Y, Z,5.0,-1,0);
			gLandminePos[i][0] = X;
			gLandminePos[i][1] = Y;
			gLandminePos[i][2] = Z;
			Items_AddPlayer(playerid, LANDMINES, -1);
			PlayerInfo[playerid][pItemsUsed] ++;
			gLandmineTimer[i] = SetTimerEx("AlterLandmine", 50000, false, "i", i);
			ApplyAnimation(playerid, "MISC", "PICKUP_box", 3.0, 0, 0, 0, 0, 0);
			break;
		}
	}
	return 1;
}

//Chat messages

public OnPlayerText(playerid, text[]) {
	if (!PlayerInfo[playerid][pLoggedIn]) return 0;
	PlayerInfo[playerid][pChatMessagesSent] ++;

	new String[128];

	//////////
	//Add code for admin chat
	if (text[0] == '.' && ComparePrivileges(playerid, CMD_MEMBER)) {
		foreach(new i: Player) if (ComparePrivileges(i, CMD_MEMBER)) SendGameMessage(i, X11_SERV_INFO, MSG_ADMIN_CHAT, PlayerInfo[playerid][PlayerName], playerid, text[1]);
		return 0;
	}

	//Add code for manager chat
	if (text[0] == '@' && ComparePrivileges(playerid, CMD_OPERATOR)) {
		GetPlayerName(playerid, String, sizeof(String));

		format(String, sizeof(String), "[Operator] %s[%d]: %s", String, playerid, text[1]);
		foreach(new i: Player) if (ComparePrivileges(i, CMD_OPERATOR)) SendClientMessage(i, X11_GREEN, String);
		return 0;
	}

	////////////////////////////////////////

	if (text[0] == '$' && PlayerInfo[playerid][pDonorLevel]) {
		GetPlayerName(playerid, String, sizeof(String));

		format(String, sizeof(String), "[VIP CHAT] %s[%d]: %s", String, playerid, text[1]);

		foreach (new i: Player) {
			if (PlayerInfo[i][pDonorLevel] >= 1) {
				SendClientMessage(i, X11_GREEN, String);
			}
		}
		return 0;
	}

	if (!ComparePrivileges(playerid, CMD_OWNER) && svtconf[anti_adv] && AdCheck(text)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_ADV_ALERT);
		PlayerInfo[playerid][pAdvAttempts] ++;
		return 0;
	}


	if (svtconf[disable_chat] == 1 || PlayerInfo[playerid][pMuted] == 1) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_MUTE_ALERT);
		return 0;
	}

	if (PlayerInfo[playerid][pCapsDisabled] == 1) {
		LOWERCASE(text);
	}
	else if (svtconf[anti_caps]) {
		LOWERCASE(text);
	}

	if (!isnull(PlayerInfo[playerid][pPreviousMessage]) &&
		!strcmp(PlayerInfo[playerid][pPreviousMessage], text, true)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_SPAM_ALERT);
		return 0;
	}

	if (svtconf[anti_spam] && !ComparePrivileges(playerid, CMD_MEMBER)) {
		if (PlayerInfo[playerid][pSpamCount] == 0) PlayerInfo[playerid][pSpamTick] = TimeStamp();

		PlayerInfo[playerid][pSpamCount] ++;
		PlayerInfo[playerid][pSpamAttempts] ++;

		if (TimeStamp() - PlayerInfo[playerid][pSpamTick] > SPAM_TIMELIMIT) {
			PlayerInfo[playerid][pSpamCount] = 0;
			PlayerInfo[playerid][pSpamTick] = TimeStamp();
		} else if (PlayerInfo[playerid][pSpamCount] == MAX_MESSAGES) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_31x, PlayerInfo[playerid][PlayerName]);
			Kick(playerid);
			return 0;
		} else if (PlayerInfo[playerid][pSpamCount] == MAX_MESSAGES - 1) {
			SendGameMessage(playerid, X11_SERV_INFO, MSG_SPAM_ALERT);
			return 0;
		}
	}

	SetPlayerChatBubble(playerid, text, 0xFFFFFFFF, 100.0, 10000);

	for (new i = 0; i < sizeof(ForbiddenWords); i++) {
		if (strfind(text, ForbiddenWords[i], true) != -1 && !isnull(ForbiddenWords[i])) {
			SendGameMessage(playerid, X11_SERV_INFO, MSG_FORBIDDEN_MESSAGE, ForbiddenWords[i]);
			PlayerInfo[playerid][pAntiSwearBlocks] ++;
			return 0;
		}
	}

	if (PlayerInfo[playerid][pClanTag] && IsPlayerInAnyClan(playerid)) {
		strcat(String, "(");
		strcat(String, GetClanTag(GetPlayerClan(playerid)));
		strcat(String, ") ");
	}

	format(PlayerInfo[playerid][pPreviousMessage], 128, text);

	if (PlayerInfo[playerid][pDonorLevel]) {
		strcat(String, "(VIP) ");
	}

	strcat(String, text);

	if (PlayerInfo[playerid][pDonorLevel]) {
		strreplace(String, "<r>", ""WINE"");
		strreplace(String, "<b>", ""LIGHTBLUE"");
		strreplace(String, "<w>", ""WHITE"");
		strreplace(String, "<g>", ""GREEN"");
		strreplace(String, "<y>", ""YELLOW"");
	}

	ForwardPlayerMessageToAll(playerid, String);
	return 0;
}

CMD:pm(playerid, params[]) {
	if (PlayerInfo[playerid][pMuted] == 1) return 1;
	if (!ComparePrivileges(playerid, CMD_OWNER) && svtconf[anti_adv] && AdCheck(params)) {
		PlayerInfo[playerid][pAdvAttempts] ++;
		return 0;
	}

	new query[MEDIUM_STRING_LEN], str2[128], ID;
	if (sscanf(params, "us[128]", ID, str2)) return ShowSyntax(playerid, "/pm [player id/name] [message]");

	if (GetPlayerConfigValue(playerid, "DND") == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_433x);

	if (pVerified[ID]) {
	   if (ID != playerid) {
			if (GetPlayerConfigValue(ID, "DND") == 0) {
				mysql_format(Database, query, sizeof(query), "SELECT * FROM `IgnoreList` WHERE `BlockerId` = '%d' AND `BlockedId` = '%d' LIMIT 1", PlayerInfo[ID][pAccountId], PlayerInfo[playerid][pAccountId]);
				mysql_tquery(Database, query, "SendPM", "iis", playerid, ID, str2);
			} else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
		}
	} else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
	return 1;
}

alias:r("rpm", "reply")
CMD:r(playerid, params[]) {
   if (PlayerInfo[playerid][pMuted] == 1)
   {
		return 0;
   }

   if (!ComparePrivileges(playerid, CMD_OWNER) && svtconf[anti_adv] && AdCheck(params)) {
		PlayerInfo[playerid][pAdvAttempts] ++;
		return 0;
   }

   new str[290], str2[140];
   if (sscanf(params, "s[140]", str2)) return ShowSyntax(playerid, "/r(eply) [message]");

   new ID = -1;
   if (pLastMessager[playerid] != INVALID_PLAYER_ID) {
	   ID = pLastMessager[playerid];
   }

   if (GetPlayerConfigValue(playerid, "DND") == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_433x);

   if (ID != -1) {
	   if (GetPlayerConfigValue(ID, "DND") == 0) {
			mysql_format(Database, str, sizeof(str), "SELECT * FROM `IgnoreList` WHERE `BlockerId` = '%d' AND `BlockedId` = '%d' LIMIT 1", PlayerInfo[ID][pAccountId], PlayerInfo[playerid][pAccountId]);
			mysql_tquery(Database, str, "SendPM", "iis", playerid, ID, str2);
			pLastMessager[ID] = playerid;
	   } else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
   } else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);

   return 1;
}

CMD:dnd(playerid) {
   if (GetPlayerConfigValue(playerid, "DND") == 0) {
	   SetPlayerConfigValue(playerid, "DND", 1);
	   PlayerPlaySound(playerid, 1057, 	0.0, 	0.0, 	0.0);
   } else if (GetPlayerConfigValue(playerid, "DND") == 1) {
	   SetPlayerConfigValue(playerid, "DND", 0);
	   PlayerPlaySound(playerid, 	1085, 	0.0, 	0.0, 	0.0);
   }
   return 1;
}

CMD:block(playerid, params[]) {
	new targetid;
	if (!pVerified[playerid]) return SendClientMessage(playerid, X11_RED, "Please register an account on our server first.");
	if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/block [playerid/name]");
	if (!pVerified[targetid] || targetid == INVALID_PLAYER_ID || targetid == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);

	new query[150];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `IgnoreList` WHERE `BlockerId` = '%d' AND `BlockedId` = '%d' LIMIT 1", PlayerInfo[playerid][pAccountId], PlayerInfo[targetid][pAccountId]);
	mysql_tquery(Database, query, "BlockPlayer", "ii", playerid, targetid);
	return 1;
}

CMD:unblock(playerid, params[]) {
	new targetid;
	if (!pVerified[playerid]) return SendClientMessage(playerid, X11_RED, "Please register an account on our server first.");
	if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/unblock [playerid/name]");
	if (!pVerified[targetid] || targetid == INVALID_PLAYER_ID || targetid == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);

	new query[150];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `IgnoreList` WHERE `BlockerId` = '%d' AND `BlockedId` = '%d' LIMIT 1", PlayerInfo[playerid][pAccountId], PlayerInfo[targetid][pAccountId]);
	mysql_tquery(Database, query, "UnblockPlayer", "ii", playerid, targetid);
	return 1;
}

//Local chat

alias:l("local")
CMD:l(playerid, params[]) {
	if (!ComparePrivileges(playerid, CMD_OWNER) && svtconf[anti_adv] && AdCheck(params)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_ADV_ALERT);
		PlayerInfo[playerid][pAdvAttempts] ++;
		return 0;
	}

	if (PlayerInfo[playerid][pMuted] == 1) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
		return 0;
	}

	if (isnull(params)) return ShowSyntax(playerid, "/l [text]");

	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	new String[128];
	format(String, sizeof(String), "(Local) %s", params);
	foreach (new i: Player) {
		if (IsPlayerInRangeOfPoint(i, 7.0, x, y, z) && i != playerid) ForwardPlayerMessageToTarget(playerid, i, String);
	}
	return 1;
}

//Class Commands

CMD:suicide(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !IsPlayerInMode(playerid, MODE_PUBG)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (!Items_GetPlayer(playerid, DYNAMITE)
		&& !(p_ClassAbilities(playerid, DEMOLISHER)) && !(p_ClassAbilities(playerid, SUICIDER))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);
	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_NOTONFOOT);

	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);

	new Float: r = 10.0;
	if ((p_ClassAbilities(playerid, SUICIDER))) {
		r += 4.5;
		PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
	} else {
		PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
	}

	foreach (new i: Player) {
		if (i != playerid && IsPlayerInRangeOfPoint(i, r, X, Y, Z)) {
			DamagePlayer(i, 84.1, playerid, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
			PlayerPlaySound(i, 1095, 0.0, 0.0, 0.0);
		}
	}

	CreateExplosion(X, Y, Z, 7, 5.0);

	SetPlayerHealth(playerid, 0.0);

	if (!(p_ClassAbilities(playerid, DEMOLISHER)) && !(p_ClassAbilities(playerid, SUICIDER))) {
		Items_AddPlayer(playerid, DYNAMITE, -1);
		PlayerInfo[playerid][pItemsUsed] ++;
	} else {
		PlayerInfo[playerid][pClassAbilitiesUsed] ++;
	}
	return 1;
}

CMD:fr(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !IsPlayerInMode(playerid, MODE_PUBG)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (!(p_ClassAbilities(playerid, DEMOLISHER)) || !p_ClassAdvanced(playerid))
		return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);

	if (!IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);

	if (pCooldown[playerid][26] < gettime()) {
		pCooldown[playerid][26] = gettime() + 30;

		new Float: vX, Float: vY, Float: vZ, count;
		GetVehiclePos(GetPlayerVehicleID(playerid), vX, vY, vZ);

		new bool:mega_attack = false, Float: attack_radius = 8.0;

		if ((p_ClassAbilities(playerid, DEMOLISHER))
			&& p_ClassAdvanced(playerid)) {
			mega_attack = true;
			attack_radius = 16.0;
		}

		foreach(new i: Player) {
			if (IsPlayerInAnyVehicle(i) && IsPlayerInRangeOfPoint(i, attack_radius, vX, vY, vZ)) {
				SetVehicleHealth(GetPlayerVehicleID(i), 0.0);
				if (!mega_attack) {
					GameTextForPlayer(i, "~r~PYROATTACK!", 3000, 3);
				} else GameTextForPlayer(i, "~r~MEGA PYROATTACK!", 3000, 3);
				if (i != playerid) {
					count ++;

					SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_452x, PlayerInfo[i][PlayerName]);
					GivePlayerScore(playerid, 1);

					PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);
					PlayerPlaySound(i, 1095, 0.0, 0.0, 0.0);
				}
			}
		}

		CreateExplosion(vX, vY, vZ, 7, 7.0);
		PlayerInfo[playerid][pClassAbilitiesUsed] ++;
	} else {
		SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][26] - gettime());
	}
	return 1;
}

CMD:drone(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (!(p_ClassAbilities(playerid, RECON)) || !p_ClassAdvanced(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);
	if (IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);

	if (pCooldown[playerid][39] > gettime()) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_453x, pCooldown[playerid][39] - gettime());
		return 1;
	}

	pCooldown[playerid][39] = gettime() + 150;
	InDrone[playerid] = true;
	GetPlayerPos(playerid, gDroneLastPos[playerid][0], gDroneLastPos[playerid][1], gDroneLastPos[playerid][2]);
	CarSpawner(playerid, 501);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	PlayerInfo[playerid][pClassAbilitiesUsed] ++;
	PlayerInfo[playerid][pDronesExploded] ++;
	return 1;
}

alias:ex("pb", "plantbomb")
CMD:ex(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !IsPlayerInMode(playerid, MODE_PUBG)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (!Items_GetPlayer(playerid, DYNAMITE))
		if (!(p_ClassAbilities(playerid, DEMOLISHER))) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);
	if (IsPlayerInBase(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_454x);

	new seconds;

	if (sscanf(params, "i", seconds)) return ShowSyntax(playerid, "/pb [seconds]");
	if (seconds > 50 || seconds < 15) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_455x);

	if (pCooldown[playerid][25] < gettime()) {
		if (GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
			pCooldown[playerid][25] = gettime() + 50;

			ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0);
			GameTextForPlayer(playerid, "~r~PLANTING DYNAMITE", 5000, 3);

			for (new i = 0; i < MAX_SLOTS; i++) {
				if (!gDynamiteExists[i]) {
					if (pCooldown[playerid][9] < gettime()) {
						pCooldown[playerid][9] = gettime() + 35;

						new Float: X, Float: Y, Float: Z;
						GetXYZInfrontOfPlayer(playerid, X, Y, 0.7);
						CA_FindZ_For2DCoord(X, Y, Z);

						gDynamiteExists[i] = 1;

						gDynamitePlacer[i] = playerid;
						gDynamiteObj[i] = CreateDynamicObject(1654, X, Y, Z, 90.0, 0.0, 0.0);
						gDynamiteArea[i] = CreateDynamicSphere(X, Y, Z,5.0,-1,0);

						gDynamitePos[i][0] = X;
						gDynamitePos[i][1] = Y;
						gDynamitePos[i][2] = Z;

						gDynamiteCD[i] = gettime() + seconds;

						if (!(p_ClassAbilities(playerid, DEMOLISHER))) {
							Items_AddPlayer(playerid, DYNAMITE, -1);
							PlayerInfo[playerid][pItemsUsed] ++;
						} else {
							PlayerInfo[playerid][pClassAbilitiesUsed] ++;
						}

						KillTimer(gDynamiteTimer[i]);
						gDynamiteTimer[i] = SetTimerEx("DynamiteExplosion", seconds * 1000, false, "i", i);
						ApplyAnimation(playerid, "MISC", "PICKUP_box", 3.0, 0, 0, 0, 0, 0);

						break;
					} else {
						SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][9] - gettime());
					}
				}
			}
		} else {
			pCooldown[playerid][25] = gettime() + 50;
			KillTimer(ExplodeTimer[playerid]);
			ExplodeTimer[playerid] = SetTimerEx("ExplodeCar", seconds * 1000, false, "ii", playerid, GetPlayerVehicleID(playerid));
			GameTextForPlayer(playerid, "~g~~h~BOMBING CAR", 5000, 3);
		}
	} else {
		SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][25] - gettime());
	}
	return 1;
}

CMD:rebuildantenna(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (!(p_ClassAbilities(playerid, MECHANIC)) || !p_ClassAdvanced(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);

	foreach (new i: teams_loaded) {
		if (i == Team_GetPlayer(playerid)) {
			if (IsPlayerInRangeOfPoint(playerid, 20.0, AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2])) {
				if (AntennaInfo[i][Antenna_Exists] == 0) {
					SetTimerEx("RebuildAntenna", 12000, false, "i", playerid);
					PlaySuccessSound(playerid);
					PlayerInfo[playerid][pSupportAttempts]++;
					break;
				}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_456x);
		}
	}
	return 1;
}

CMD:spy(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (((p_ClassAbilities(playerid, SPY)))) {
		if (PlayerInfo[playerid][pIsSpying]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_457x);
		new string[50], alt[MEDIUM_STRING_LEN];

		foreach (new i: teams_loaded)
		{
			format(string, sizeof(string), "{%06x}%s\n", Team_GetColor(i) >>> 8, Team_GetName(i));
			strcat(alt, string);
		}

		inline SpySystem(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (!response) {
				return 1;
			}
			if (listitem == Team_GetPlayer(pid)) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_458x);
			if (PlayerInfo[pid][pIsSpying]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_457x);
			PlayerInfo[pid][pIsSpying] = 1;
			PlayerInfo[pid][pSpyTeam] = listitem;
			SetPlayerColor(pid, Team_GetColor(listitem));
			UpdateLabelText(pid);
			SetPlayerSkin(pid, Team_GetDefSkin(PlayerInfo[pid][pSpyTeam]));
		}

		Dialog_ShowCallback(playerid, using inline SpySystem, DIALOG_STYLE_LIST, "Disguise", alt, ">>", "X");

		if ((p_ClassAbilities(playerid, SPY))) {
			PlayerInfo[playerid][pClassAbilitiesUsed] ++;
		}

	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);
	return 1;
}

CMD:nospy(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pIsSpying] == 1) {
		PlayerInfo[playerid][pIsSpying] = 0;
		PlayerInfo[playerid][pSpyTeam] = -1;

		SetPlayerColor(playerid, Team_GetColor(Team_GetPlayer(playerid)));
		UpdateLabelText(playerid);
	} else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_459x);
	return 1;
}

CMD:stab(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendClientMessage(playerid, X11_RED_2, "You can't stab players out of the battlefield!");
	if (!(p_ClassAbilities(playerid, SPY)))
		return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0), SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);
	if (!IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_445x);
	if (GetPlayerState(playerid) != PLAYER_STATE_PASSENGER) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_445x);

	new stabbed = 0;

	foreach (new i: Player) {
		if (GetPlayerVehicleID(i) == GetPlayerVehicleID(playerid) && GetPlayerState(i) == PLAYER_STATE_DRIVER
			&& IsPlayerInMode(i, MODE_BATTLEFIELD)) {
			if (Team_GetPlayer(i) == Team_GetPlayer(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_460x);
			if (pCooldown[playerid][34] > gettime()) {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_453x, pCooldown[playerid][34] - gettime());
				return 1;
			}

			pCooldown[playerid][34] = gettime() + 3;
			DamagePlayer(i, 40.0, playerid, WEAPON_KNIFE, BODY_PART_UNKNOWN, true);
			GameTextForPlayer(playerid, "~g~STABBED", 2000, 3);
			GameTextForPlayer(i, "~r~STABBED", 2000, 3);
			PlayerInfo[playerid][pDriversStabbed] ++;
			PlayerInfo[playerid][pClassAbilitiesUsed] ++;
			stabbed = 1;
		}
	}

	if (!stabbed)
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_461x);
	return 1;
}

CMD:heal(playerid) return HealClosePlayers(playerid);

CMD:vest(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (!(p_ClassAbilities(playerid, CUSTODIAN))) {
		return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);
	}

	if (pCooldown[playerid][42] > gettime()) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_453x, pCooldown[playerid][42] - gettime());
		return 1;
	}

	new Float: X, Float: Y, Float: Z, Float: rRange, Float: AR, nearby_players = 0;
	GetPlayerPos(playerid, X, Y, Z);
	if (p_ClassAdvanced(playerid)) {
		rRange = 15.0;
		AR = 50.0;
	} else {
		rRange = 10.0;
		AR = 25.0;
	}

	foreach (new i: Player) {
		if (IsPlayerInMode(i, MODE_BATTLEFIELD) && IsPlayerInRangeOfPoint(i, rRange, X, Y, Z) && i != playerid && Team_GetPlayer(i) == Team_GetPlayer(playerid)) {
			new Float: pAR;
			GetPlayerArmour(i, pAR);
			if (pAR + AR < 100) {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_462x, PlayerInfo[i][PlayerName]);

				PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
				PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);

				SetPlayerArmour(i, pAR + AR);
				GivePlayerScore(playerid, 1);
				nearby_players ++;
			}
		}
	}

	if (nearby_players) {
		pCooldown[playerid][42] = gettime() + 60;
	}

	PlayerInfo[playerid][pClassAbilitiesUsed] ++;
	return 1;
}

CMD:jp(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD) && !IsPlayerInMode(playerid, MODE_PUBG)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if (((p_ClassAbilities(playerid, JETTROOPER)))) {
			if (pCooldown[playerid][9] < gettime()) {
				SetPlayerSpecialAction(playerid, 2);
				PlayerInfo[playerid][pClassAbilitiesUsed] ++;

				pCooldown[playerid][9] = gettime() + 15;
			} else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][9] - gettime());
			}
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_451x);
	}
	return 1;
}

CMD:sc(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());

	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_NOTONFOOT);
	KillTimer(pTeamSTimer[playerid]);

	if (AntiSK[playerid]) {
		EndProtection(playerid);
	}

	pTeamSTimer[playerid] = SetTimerEx("SwitchClass", 5000, false, "i", playerid);
	return 1;
}

CMD:classes(playerid) {
	new string[LARGE_STRING_LEN];
	foreach (new i: classes_loaded) {
		format(string, sizeof(string), "%s%s#%d: Team: %s, Skin: %d, Weapon: %s, Name: %s, Ability: %s, Type: %s\n",
			string, Class_GetPlayerClass(playerid) == i ? ""GREEN"" : ""GRAY"", i, Team_GetName(Class_GetTeam(i)), Class_GetSkin(i), ReturnWeaponName(Class_GetWeapon(i)), Class_GetAbilityNames(i),
			Class_GetAbilityFeatures(i), Class_GetType(i) == 0 ? "Interior" : "Exterior");
	}
	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, ""WINE"SvT - Class Abilities", string, "X", "");
	return 1;
}

//DROP/PICK
CMD:dropgun(playerid) {
	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD) || IsPlayerInMode(playerid, MODE_PUBG)) {
		if (GetPlayerAmmo(playerid) != 0 && GetWeaponModel(GetPlayerWeapon(playerid)) != -1 && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT && GetPlayerInterior(playerid) == 0
			&& GetWeaponSlot(GetPlayerWeapon(playerid)) != 0) {
			new Float: Checkpos[3], Float: Check_X;
			GetPlayerPos(playerid, Checkpos[0], Checkpos[1], Checkpos[2]);

			CA_FindZ_For2DCoord(Checkpos[0], Checkpos[1], Check_X);
			if (Checkpos[2] < Check_X) return 1;

			for (new a = 0; a < MAX_SLOTS; a++) {
				if (!gWeaponExists[a]) {
					new
						Float: X,
						Float: Y,
						Float: Z
					;

					GetPlayerPos(playerid, X, Y, Z);
					CA_FindZ_For2DCoord(X, Y, Z);

					gWeaponExists[a] = 1;
					gWeaponPickable[a] = 0;

					gWeaponObj[a] = CreateDynamicObject(GetWeaponModel(GetPlayerWeapon(playerid)), X, Y, Z, 90.0, 0.0, 0.0);

					new weap_label[45];
					format(weap_label, sizeof(weap_label), "%s[%d]", ReturnWeaponName(GetPlayerWeapon(playerid)), GetPlayerAmmo(playerid));
					gWeapon3DLabel[a] = CreateDynamic3DTextLabel(weap_label, 0xFFFFFFFF, X, Y, Z, 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0);

					gWeaponID[a] = GetPlayerWeapon(playerid);
					gWeaponAmmo[a] = GetPlayerAmmo(playerid);

					gWeaponPickable[a] = 1;
					gWeaponTimer[a] = SetTimerEx("AlterWeaponPickup", 45000, false, "ii", INVALID_PLAYER_ID, a);
					SetPlayerAmmo(playerid, GetPlayerWeapon(playerid), 0);

					gWeaponArea[a] = CreateDynamicSphere(X, Y, Z, 2.5,-1,0);
					PlayerInfo[playerid][pWeaponsDropped] ++;

					Weapons_ResetAmmo(playerid, gWeaponID[a]);
					break;
				}
			}
			return 1;
		}
		return 1;
	}
	SendClientMessage(playerid, X11_RED_2, "Failed to drop the current gun in your hand. Unsupported mode or gun.");
	return 1;
}

CMD:pickup(playerid) {
	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD) || IsPlayerInMode(playerid, MODE_PUBG)) {
		if (pPickupCD[playerid] <= GetTickCount()) {
			for (new x = 0; x < MAX_SLOTS; x++) {
				if (gLootExists[x]) {
					if (gLootPickable[x] && IsPlayerInDynamicArea(playerid, gLootArea[x])) {
						PickupItem(playerid, x);
						gLootPickable[x] = 0;
						pPickupCD[playerid] = GetTickCount() + 1000;
						return 1;
					}
				}

				if (gWeaponExists[x] && gWeaponPickable[x]) {
					if (IsPlayerInDynamicArea(playerid, gWeaponArea[x])) {
						if (!PlayerInfo[playerid][pPickedWeap]) {
							new weapon, ammo;
							GetPlayerWeaponData(playerid, GetWeaponSlot(gWeaponID[x]), weapon, ammo);

							if (weapon && weapon != gWeaponID[x]) {
								if (PlayerInfo[playerid][pAcceptedWeap] == 0) {
									new weapon_name[2][35];

									GetWeaponName(weapon, weapon_name[0], 35);
									GetWeaponName(gWeaponID[x], weapon_name[1], 35);

									SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_410x, weapon_name[0], weapon_name[1]);
									PlayerInfo[playerid][pAcceptedWeap] = 1;
								} else {
									gWeaponPickable[x] = 0;

									PlayerInfo[playerid][pPickedWeap] = 1;
									PlayerInfo[playerid][pAcceptedWeap] = 0;

									KillTimer(gWeaponTimer[x]);

									AlterWeaponPickup(playerid, x);
									PlayerInfo[playerid][pAcceptedWeap] = 0;
									pPickupCD[playerid] = GetTickCount() + 3000;
									PlayerInfo[playerid][pWeaponsPicked] ++;
								}
							} else {
								gWeaponPickable[x] = 0;
								PlayerInfo[playerid][pPickedWeap] = 1;

								KillTimer(gWeaponTimer[x]);
								AlterWeaponPickup(playerid, x);
								pPickupCD[playerid] = GetTickCount() + 3000;
								PlayerInfo[playerid][pWeaponsPicked] ++;
							}

							return 1;
						}
					}
				}
			}
		}
		return 1;
	}
	SendClientMessage(playerid, X11_RED_2, "ERROR: Unsupported mode or failed to find any nearby item!");
	return 1;
}

//FIRE INTEGRITY
alias:fire("toxic")
CMD:fire(playerid) {
	if (IsPlayerInAnyVehicle(playerid) && IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		//Submarines Integration
		if (GetVehicleModel(GetPlayerVehicleID(playerid)) == 484) {
			for (new i = 0; i < sizeof(SubInfo); i++) {
				if (GetPlayerVehicleID(playerid) == SubInfo[i][Sub_VID]) {

					if (PlayerInfo[playerid][pLimit] > gettime()) {
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_411x, PlayerInfo[playerid][pLimit] - gettime());
						return 1;
					}

					if (IsVehicleUpsideDown(SubInfo[i][Sub_VID])) return SendClientMessage(playerid, X11_RED_2, "This submarine is upside down!");

					CreateMissileLauncher(playerid);
					CreateMissileLauncher(playerid);
					CreateMissileLauncher(playerid);
					CreateMissileLauncher(playerid);
					CreateMissileLauncher(playerid);

					PlayerInfo[playerid][pLimit] = gettime() + 20;

					break;
				}
			}
			return 1;
		}

		//AAC Integration
		if (GetVehicleModel(GetPlayerVehicleID(playerid)) == 515 ||
			GetVehicleModel(GetPlayerVehicleID(playerid)) == 422) {
			for (new a = 0; a < sizeof(AACInfo); a++) {
				if (GetPlayerVehicleID(playerid) == AACInfo[a][AAC_Id]) {

					if (PlayerInfo[playerid][pLimit] > gettime()) {
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_411x, PlayerInfo[playerid][pLimit] - gettime());
						return 1;
					}

					if (IsVehicleUpsideDown(AACInfo[a][AAC_Id])) {
						return SendClientMessage(playerid, X11_RED_2, "This Anti Aircraft is upside down!");
					}

					if (AACInfo[a][AAC_Rockets] == 0) {
						SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_286x);
						return 1;
					}

					if (IsValidDynamicObject(AACInfo[a][AAC_RocketId])) {
						return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_287x);
					}

					switch (AACInfo[a][AAC_Model]) {
						case 422: AttachDynamicObjectToVehicle(AACInfo[a][AAC_Samsite], AACInfo[a][AAC_Id], 0.009999, -1.449998, -0.534999, 0.0, 0.0, 0.0);
						case 515: AttachDynamicObjectToVehicle(AACInfo[a][AAC_Samsite], AACInfo[a][AAC_Id], 0.000000, -3.520033, -1.179999, 0.000000, 0.000000, 0.000000);
					}

					new Float: X, Float: Y, Float: Z;
					GetVehiclePos(AACInfo[a][AAC_Id], X, Y, Z);

					PlayerInfo[playerid][pLimit] = gettime() + 35;

					AACInfo[a][AAC_Rockets] --;
					AACInfo[a][AAC_RocketId] = CreateDynamicObject(3790, X, Y, (Z + 4.0), 0.0, 0.0, 0.0);

					new Float: Front_X, Float: Front_Y;
					GetXYZInfrontOfAAC(a, Front_X, Front_Y, 300.0);

					new Float: ca_X, Float: ca_Y, Float: ca_Z;
					if (CA_RayCastLine(X, Y, Z, Front_X, Front_Y, Z, ca_X, ca_Y, ca_Z) != 0) {
						Front_X = ca_X;
						Front_Y = ca_Y;
						Z = ca_Z;
					}

					AACInfo[a][AAC_Target] = INVALID_PLAYER_ID;

					foreach (new i: Player) {
						if (IsPlayerInRangeOfPoint(i, 300.0, X, Y, Z) && IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) != Team_GetPlayer(playerid)) {
							switch (GetVehicleModel(GetPlayerVehicleID(i))) {
								case 417, 425, 447, 460, 469, 476, 487, 488, 497, 511, 512, 513, 519,
								520, 548, 553, 563, 577, 592, 593: { // Airplanes and helicopters
									new Float: pX, Float: pY, Float: pZ;
									GetPlayerPos(i, pX, pY, pZ);

									if (CA_RayCastLine(X, Y, Z, pX, pY, pZ, ca_X, ca_Y, ca_Z) != 0) {
										pX = ca_X;
										pY = ca_Y;
										pZ = ca_Z;
									}

									AACInfo[a][AAC_Target] = i;
									SetDynamicObjectFaceCoords3D(AACInfo[a][AAC_RocketId], pX, pY, pZ, 0.0, 90.0, 90.0);
									MoveDynamicObject(AACInfo[a][AAC_RocketId], pX, pY, pZ, 100.0);
									PlayerPlaySound(i, 1159, 0.0, 0.0, 0.0);
								}
							}
							break;
						}
					}

					if (AACInfo[a][AAC_Target] == INVALID_PLAYER_ID) {
						SetDynamicObjectFaceCoords3D(AACInfo[a][AAC_RocketId], Front_X, Front_Y, Z, 0.0, 90.0, 90.0);
						MoveDynamicObject(AACInfo[a][AAC_RocketId], Front_X, Front_Y, Z, 100.0);
					}

					PlayerPlaySound(playerid, 1159, 0.0, 0.0, 0.0);
					PlayerInfo[playerid][pAntiAirRocketsFired] ++;

					new text[25];
					format(text, sizeof(text), "Anti Aircraft\n[%d/4]", AACInfo[a][AAC_Rockets]);
					UpdateDynamic3DTextLabelText(AACInfo[a][AAC_Text], X11_CADETBLUE, text);

					break;
				}
			}
			return 1;
		}

		//Nevada Integration
		if (GetVehicleModel(GetPlayerVehicleID(playerid)) == 553) {
			if (gNevadaRockets[GetPlayerVehicleID(playerid)] <= 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_289x);

			CreateMissileLauncher(playerid);
			CreateMissileLauncher(playerid);
			CreateMissileLauncher(playerid);
			CreateMissileLauncher(playerid);

			gNevadaRockets[GetPlayerVehicleID(playerid)] --;

			new rockets[30];
			format(rockets, 30, "Nevada Bomber\n[%d/4]", gNevadaRockets[GetPlayerVehicleID(playerid)]);
			UpdateDynamic3DTextLabelText(gNevadaLabel[GetPlayerVehicleID(playerid)], X11_CADETBLUE, rockets);
			SetTimerEx("RegenerateNevada", 19000 * 5, false, "i", GetPlayerVehicleID(playerid));
			return 1;
		}

		//Rustler Integration
		if (GetVehicleModel(GetPlayerVehicleID(playerid)) == 476) {
			if (gRustlerRockets[GetPlayerVehicleID(playerid)] <= 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_290x);
			new Float: X, Float: Y, Float: Z, Float: RZ, inbase = 0;

			GetPlayerPos(playerid, X, Y, Z);
			CA_FindZ_For2DCoord(X, Y, RZ);

			foreach (new i: teams_loaded) {
				if (IsPlayerInArea(playerid, Team_GetMapArea(i, 0),
				Team_GetMapArea(i, 1),
				Team_GetMapArea(i, 2),
				Team_GetMapArea(i, 3)) &&
					Team_GetPlayer(playerid) != i) {
					inbase = 1;
					break;
				}
			}
			if (inbase) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_292x);
			if ((Z - RZ) >= 15.0)
			{
				gRustlerRockets[GetPlayerVehicleID(playerid)] --;
				PlayerInfo[playerid][pRustlerRocketsFired] ++;

				new rockets[30];
				format(rockets, 30, "Rustler Bomber\n[%d/4]", gRustlerRockets[GetPlayerVehicleID(playerid)]);
				UpdateDynamic3DTextLabelText(gRustlerLabel[GetPlayerVehicleID(playerid)], X11_CADETBLUE, rockets);

				if (!PlayerInfo[playerid][pDonorLevel]) {
					PlayerInfo[playerid][pLimit2] = gettime() + 12;
				} else {
					PlayerInfo[playerid][pLimit2] = gettime() + 6;
				}

				CreateMissileLauncher(playerid);

				PlayerInfo[playerid][pAirRocketsFired] ++;
				SetTimerEx("RegenerateRocket", 7000 * 5, false, "i", GetPlayerVehicleID(playerid));
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_293x);
			return 1;
		}

		//Anthrax Plane Integration
		if (GetVehicleModel(GetPlayerVehicleID(playerid)) == 512) {
			if (CropAnthrax[GetPlayerVehicleID(playerid)][Anthrax_Rockets] <= 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_294x);
			if (Team_GetPlayer(playerid) != gAnthraxOwner) return SendGameMessage(playerid, X11_SERV_ERR, MSG_CLIENT_295x);
			new Float: X, Float: Y, Float: Z, Float: RZ, inbase = 0;

			GetPlayerPos(playerid, X, Y, Z);
			CA_FindZ_For2DCoord(X, Y, RZ);

			foreach (new i: teams_loaded) {
				if (IsPlayerInArea(playerid, Team_GetMapArea(i, 0),
				Team_GetMapArea(i, 1),
				Team_GetMapArea(i, 2),
				Team_GetMapArea(i, 3)) &&
					Team_GetPlayer(playerid) != i) {
					inbase = 1;
					break;
				}
			}
			if (inbase) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_297x);
			if ((Z - RZ) >= 15.0)
			{
				CropAnthrax[GetPlayerVehicleID(playerid)][Anthrax_Rockets] --;

				new rockets[30];
				format(rockets, 30, "Anthrax Cropduster\n[%d/4]", CropAnthrax[GetPlayerVehicleID(playerid)][Anthrax_Rockets]);
				UpdateDynamic3DTextLabelText(CropAnthrax[GetPlayerVehicleID(playerid)][Anthrax_Label], X11_CADETBLUE, rockets);

				if (IsValidDynamicObject(PlayerInfo[playerid][pAnthrax])) {
					DestroyDynamicObject(PlayerInfo[playerid][pAnthrax]);
				}
				PlayerInfo[playerid][pAnthrax] = INVALID_OBJECT_ID;

				new Float: Coords[3];
				GetPlayerPos(playerid, Coords[0], Coords[1], Coords[2]);
				PlayerInfo[playerid][pAnthrax] = CreateDynamicObject(1636, Coords[0], Coords[1], Coords[2] - 5.0, 0.0, 0.0, 0.0);

				CA_FindZ_For2DCoord(Coords[0], Coords[1], Coords[2]);
				MoveDynamicObject(PlayerInfo[playerid][pAnthrax], Coords[0], Coords[1], Coords[2] - 2.0, 45.0);
				PlayerInfo[playerid][pAirRocketsFired] ++;
				SetTimerEx("RegenerateToxic", 20000 * 5, false, "i", GetPlayerVehicleID(playerid));
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_298x);
		}
		return 1;
	}
	return 1;
}

//Carepack

alias:drop("dcp")
CMD:drop(playerid) {
	if (GetVehicleModel(GetPlayerVehicleID(playerid)) == 553) {
		if ((p_ClassAbilities(playerid, PILOT))) {
			if (PlayerInfo[playerid][pLimit2] > gettime()) {
     			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_347x, PlayerInfo[playerid][pLimit2] - gettime());
				return 1;
			}

			new Float: X, Float: Y, Float: Z, Float: Check_Z;
			GetPlayerPos(playerid, X, Y, Z);

			CA_FindZ_For2DCoord(X, Y, Check_Z);
			if ((Z - Check_Z) < 15.0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_346x);

			for (new i = 0; i < MAX_SLOTS; i++) {
				if (!gCarepackExists[i]) {
					GetPlayerPos(playerid, X, Y, Z);
					CA_FindZ_For2DCoord(X, Y, Z);

					gCarepackExists[i] = 1;

					gCarepackPos[i][0] = X;
					gCarepackPos[i][1] = Y;
					gCarepackPos[i][2] = Z;

					gCarepackUsable[i] = 0;

					KillTimer(gCarepackTimer[i]);
					gCarepackTimer[i] = SetTimerEx("OnCarepackForwarded", 1000, false, "i", i);

					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_57x, PlayerInfo[playerid][PlayerName]);

					GetPlayerName(playerid, gCarepackCaller[i], MAX_PLAYER_NAME);

					PlayerInfo[playerid][pLimit2] = gettime() + 80;
					PlayerInfo[playerid][Carepacks] ++;
					PlayerInfo[playerid][pClassAbilitiesUsed] ++;

					PlayerPlaySound(playerid, 1095, 0.0, 0.0, 0.0);

					break;
				}
			}
		} else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_345x);
	} else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_344x);
	return 1;
}

CMD:waypoint(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_445x);
	if (Team_GetWaypoint(Team_GetPlayer(playerid))) return SendClientMessage(playerid, X11_WINE, "A waypoint already exists. Please wait for it to expire.");
	Team_SetWaypoint(Team_GetPlayer(playerid), 1);

	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);

	new string[128];
	format(string, sizeof(string), "%s[%d] "DARKGRAY"created a team waypoint for 15 seconds "GREEN"(/waypoint)", PlayerInfo[playerid][PlayerName], playerid);

	foreach (new i: Player) {
		if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == Team_GetPlayer(playerid)) {
			if (IsValidDynamicMapIcon(pWaypoint[i])) {
				DestroyDynamicMapIcon(pWaypoint[i]);
			}
			pWaypoint[i] = CreateDynamicMapIcon(X, Y, Z, 41, 0, 0, 0, i, 1000.0, MAPICON_GLOBAL);
			SendClientMessage(playerid, X11_RED, string);
		}
	}

	SetTimerEx("DestroyTeamWaypoint", 15000, false, "i", Team_GetPlayer(playerid));

	return 1;
}

//Locator ability

alias:locate("loc")
CMD:locate(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (!(p_ClassAbilities(playerid, RECON))) return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0), SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_444x);
	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_445x);

	new targetid;

	if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/locate [playerid/name] to search players.");
	if (playerid == targetid || !pVerified[targetid]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
	if (GetPlayerInterior(targetid) != 0 || IsPlayerAttachedObjectSlotUsed(targetid, 7)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

	new Float:Pos2[3];
	GetPlayerPos(targetid, Pos2[0], Pos2[1], Pos2[2]);
	SetPlayerRaceCheckpoint(playerid, 1, Pos2[0], Pos2[1], Pos2[2], 0.0, 0.0, 0.0, 5);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	PlayerInfo[playerid][pClassAbilitiesUsed] ++;
	return 1;
}

//Pickups
public OnPlayerPickUpDynamicPickup(playerid, pickupid) {
	PlayerInfo[playerid][pPickupsPicked] ++;

	//Interiors
	for (new i = 0; i < sizeof(Interiors); i++) {
		if (pickupid == Interiors[i][IntEnterPickup]) {
			if (gIntCD[playerid] < GetTickCount()) {
				new Float: x, Float: y;
				x = Interiors[i][IntExitPos][0],
				y = Interiors[i][IntExitPos][1];
				gIntCD[playerid] = GetTickCount() + 3000;
				SetPlayerPosition(playerid, "", GetPlayerVirtualWorld(playerid), Interiors[i][IntId], x, y, Interiors[i][IntExitPos][2], 0.0, true);
				PlayerInfo[playerid][pInteriorsEntered] ++;
				NotifyPlayer(playerid, "Loading...");
			}
			break;
		} else if (pickupid == Interiors[i][IntExitPickup]) {
			if (gIntCD[playerid] < GetTickCount()) {
				new Float: x, Float: y;
				x = Interiors[i][IntEnterPos][0],
				y = Interiors[i][IntEnterPos][1];
				gIntCD[playerid] = GetTickCount() + 3000;
				SetPlayerPos(playerid, x, y, Interiors[i][IntEnterPos][2]);
				SetPlayerInterior(playerid, 0);
				PlayerInfo[playerid][pInteriorsExitted] ++;
			}
			break;
		}
	}

	//WatchRoom
	if (pickupid == gWatchRoom) {
		if (!pWatching[playerid]) {
			SetPlayerPos(playerid, -253.8266, 1534.5271, 29.3609);
			SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_307x);
			pWatching[playerid] = true;
			AttachCameraToDynamicObject(playerid, gCameraId);
		}
	}
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
	PlayerInfo[playerid][pPickupsPicked] ++;

	if (Last_Pickup[playerid] != -1 && Last_Pickup[playerid] != pickupid) {
		if ((GetTickCount() - Last_Pickup_Tick[playerid]) < 200 && GetTickCount() > gIntCD[playerid]) {
			AntiCheatAlert(playerid, "Auto Pickup");
			return Kick(playerid);
		}
	}
	Last_Pickup[playerid] = pickupid;
	Last_Pickup_Tick[playerid] = GetTickCount();

	if (IsPlayerInMode(playerid, MODE_BATTLEFIELD)) { //battlefield pickups
		if (g_pickups[0] == pickupid) {
			SetPlayerPos(playerid, -378.4082,2186.8958,51.2200);
		}

		if (g_pickups[1] == pickupid) {
			SetPlayerPos(playerid, -247.4149,2306.7480,111.9679);
			PC_EmulateCommand(playerid, "/ep");
		}

		if (g_pickups[3] == pickupid) {
			if (pCooldown[playerid][27] < gettime()) {
				pCooldown[playerid][27] = gettime() + 200;
				GivePlayerWeapon(playerid, 34, 5);
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_308x);
			} else {
				 SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_416x, pCooldown[playerid][27] - gettime());
				 return 1;
			}
		}

		if (g_pickups[5] == pickupid) {
			SetPlayerPos(playerid, -101.0826,2342.9851,20.0358);
		}

		if (g_pickups[6] == pickupid) {
			SetPlayerPos(playerid, -103.5930,2269.3291,121.4385);
			PC_EmulateCommand(playerid, "/ep");
		}
	}
	return 1;
}

//Handle Commands

public OnPlayerCommandReceived(playerid, cmd[], params[], flags) {
	if (!PlayerInfo[playerid][pLoggedIn])
	{
		printf("Unlogged command by id: %d, command: %s, params: %s", cmd, params);
		Kick(playerid);
		return 0;
	}
	LogCommand(playerid, cmd, params, flags, gettime());

	if (svtconf[anti_spam] && !ComparePrivileges(playerid, CMD_MEMBER)) {
		if (PlayerInfo[playerid][pCMDSpamCount] == 0) PlayerInfo[playerid][pCMDSpamTick] = TimeStamp();

		PlayerInfo[playerid][pCMDSpamCount] ++;
		PlayerInfo[playerid][pSpamAttempts] ++;

		if (TimeStamp() - PlayerInfo[playerid][pCMDSpamTick] > SPAM_TIMELIMIT) {
			PlayerInfo[playerid][pCMDSpamCount] = 0;
			PlayerInfo[playerid][pCMDSpamTick] = TimeStamp();
		} else if (PlayerInfo[playerid][pCMDSpamCount] == MAX_MESSAGES) {
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_31x, PlayerInfo[playerid][PlayerName]);
			Kick(playerid);
			return 0;
		} else if (PlayerInfo[playerid][pCMDSpamCount] == MAX_MESSAGES - 1) {
			SendGameMessage(playerid, X11_SERV_INFO, MSG_SPAM_ALERT);
			return 0;
		}
	}

	if (!IsPlayerSpawned(playerid)) {
		if (GetPlayerState(playerid) != PLAYER_STATE_SPECTATING) {
			return 0;
		}
	}

	if (IsPlayerDying(playerid)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_315x);
		return 0;
	}

	if (PlayerInfo[playerid][pJailed] && !ComparePrivileges(playerid, CMD_MEMBER)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_316x);
		return 0;
	}

	if (AntiSK[playerid]) {
		EndProtection(playerid);
		SendGameMessage(playerid, X11_SERV_WARN, MSG_NOT_PROCESSED);
		return 0;
	}

	if (flags && !(flags & pPrivileges[playerid])) {
		PlayerInfo[playerid][pUnauthorizedActions] ++;
		return 0;
	}
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmd[], params[], result, flags) {
	if (result == -1) {
		PlayerInfo[playerid][pCommandsFailed] ++;
		if (!PC_CommandExists(cmd)) {
			return SendClientMessage(playerid, X11_RED, ">!< Command doesn't exist! Use /cmds for a list of available commands or use /help!!");
		}
	}
	PlayerInfo[playerid][pCommandsUsed] ++;
	return 1;
}

//All Commands

//Teams

//Player wants to switch their team?
alias:st("switchteam")
CMD:st(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());

	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_NOTONFOOT);
	KillTimer(pTeamSTimer[playerid]);

	if (AntiSK[playerid]) {
		EndProtection(playerid);
	}

	pTeamSTimer[playerid] = SetTimerEx("SwitchTeam", 5000, false, "i", playerid);
	return 1;
}

//Request backup, alerts team members
CMD:backup(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (pBackupRequested[playerid] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_433x);
	pBackupRequested[playerid] = 1;
	PlayerInfo[playerid][pBackupAttempts] ++;

	foreach (new i: Player) {
		if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == Team_GetPlayer(playerid)) {
			SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_435x, PlayerInfo[playerid][PlayerName]);
		}
	}
	return 1;
}

//Respond to a team backup request
alias:respond("responda")
CMD:respond(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	new in_proto = 0;

	foreach (new i: teams_loaded) {
		if (PrototypeInfo[i][Prototype_Attacker] == playerid) {
			in_proto = 1;
			break;
		}
	}

	if (in_proto) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);

	new targetid;

	if (sscanf(params, "i", targetid)) return ShowSyntax(playerid, "/respond [ID]");
	if (!pVerified[targetid] || targetid == INVALID_PLAYER_ID) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	if (!IsPlayerInMode(targetid, MODE_BATTLEFIELD) &&
		Team_GetPlayer(targetid) != Team_GetPlayer(playerid) || pBackupRequested[targetid] == 0 || playerid == targetid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_437x);

	pBackupRequested[targetid] = 0;
	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_438x);

	pBackupResponded[playerid] = 1;
	PlayerInfo[playerid][pBackupsResponded] ++;
	PlayerInfo[playerid][pBackup] = targetid;

	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	gBackupTimer[playerid] = gettime() + 75;
	return 1;
}

//Team radio is of course related to teams
CMD:tr(playerid, params[]) {
	if (!ComparePrivileges(playerid, CMD_OWNER) && svtconf[anti_adv] && AdCheck(params)) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_ADV_ALERT);
		PlayerInfo[playerid][pAdvAttempts] ++;
		return 1;
	}

	if (PlayerInfo[playerid][pMuted] == 1) {
		if (PlayerInfo[playerid][pSpamWarnings] < 3) {
			PlayerInfo[playerid][pSpamWarnings] ++;
			PlayerInfo[playerid][pSpamAttempts] ++;
			SendGameMessage(playerid, X11_SERV_INFO, MSG_MUTED);
		}
		return 1;
	}

	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
		return SendClientMessage(playerid, X11_RED_2, "You aren't in the battlefield. No radio.");
	}

	if (AntennaInfo[Team_GetPlayer(playerid)][Antenna_Exists] == 0) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_433x);
		return 1;
	}

	new String[SMALL_STRING_LEN];

	format(String, sizeof(String), "(Radio) %s", params);
	foreach (new i: Player) {
		if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == Team_GetPlayer(playerid) && i != playerid) ForwardPlayerMessageToTarget(playerid, i, String);
	}
	return 1;
}

//Display a list of teams?
CMD:teams(playerid) {
	new dialog[240];
	strcat(dialog, "Team\tPlayers\n");
	foreach (new x: teams_loaded) {
		new teamPlayers;
		foreach (new i: Player) {
			if (IsPlayerInMode(i, MODE_BATTLEFIELD) && Team_GetPlayer(i) == x) {
				teamPlayers++;
			}
		}
		format(dialog, sizeof(dialog), "%s{%06x}%s\t%d\n", dialog, Team_GetColor(x) >>> 8, Team_GetName(x), teamPlayers);
	}
	Dialog_Show(playerid, DIALOG_STYLE_TABLIST_HEADERS, ""WINE"SvT - Teams", dialog, "X", "");
	return 1;
}

//Nuke

CMD:nuke(playerid) {
	if (nukeCooldown > gettime() && nukeIsLaunched) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_472x, nukeCooldown - gettime());
	} else {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_473x);
	}
	return 1;
}

CMD:nukehelp(playerid) {
	SendClientMessage(playerid, X11_DEEPPINK, "Nuclear Help");
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_173x);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_174x);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_175x);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_176x);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_177x);
	return 1;
}

//DM-Mode

alias:mode("dm")
CMD:mode(playerid) {
	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || pDuelInfo[playerid][pDInMatch] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_495x);
	if (Iter_Contains(ePlayers, playerid) || Iter_Contains(PUBGPlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	ChangePlayerMode(playerid);
	return 1;
}

CMD:qdm(playerid) {
	if (PlayerInfo[playerid][pDeathmatchId] >= 0 && pDuelInfo[playerid][pDInMatch] == 0) {
		pDMKills[playerid][PlayerInfo[playerid][pDeathmatchId]] = 0;
		PlayerInfo[playerid][pDeathmatchId] = -1;

		SetPlayerHealth(playerid, 0.0);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_497x);
	return 1;
}

CMD:dmers(playerid) {
	new sub_holder[27], string[MEDIUM_STRING_LEN], count = 0;

	foreach (new i: Player) {
		if (PlayerInfo[i][pDeathmatchId] >= 0) {
			format(sub_holder, sizeof(sub_holder), "%s\t%s\n", PlayerInfo[i][PlayerName], DMInfo[PlayerInfo[i][pDeathmatchId]][DM_NAME]);
			strcat(string, sub_holder);

			count = 1;
		}
	}

	if (count) {
		Dialog_Show(playerid, DIALOG_STYLE_TABLIST, "DM Players", string, "X", "");
	}  else SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	return 1;
}

//Top Players

CMD:top(playerid) {
	inline TopPlayersMenu(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return 1;
		switch (listitem) {
			case 0: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`Kills` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`Kills` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, Kills;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "Kills", Kills);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_33x, playerName, i + 1, Kills);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 1: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`Deaths` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`Deaths` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, Deaths;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "Deaths", Deaths);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_34x, playerName, i + 1, Deaths);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 2: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`Headshots` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`Headshots` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, Headshots;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "Headshots", Headshots);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_35x, playerName, i + 1, Headshots);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 3: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`DeathmatchKills` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`DeathmatchKills` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, DeathmatchKills;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "DeathmatchKills", DeathmatchKills);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_36x, playerName, i + 1, DeathmatchKills);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 4: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT `Username`, `ID`, `PlayTime` FROM `Players` ORDER BY `PlayTime` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID;
						cache_get_value_int(i, "ID", pID);
						cache_get_value(i, "Username", playerName);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_37x, playerName, i + 1);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 5: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`ZonesCaptured` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`ZonesCaptured` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, ZonesCaptured;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "ZonesCaptured", ZonesCaptured);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_38x, playerName, i + 1, ZonesCaptured);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 6: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`ClassAbilitiesUsed` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`ClassAbilitiesUsed` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, ClassAbilitiesUsed;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "ClassAbilitiesUsed", ClassAbilitiesUsed);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_39x, playerName, i + 1, ClassAbilitiesUsed);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 7: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`DuelsWon` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`DuelsWon` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, DuelsWon;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "DuelsWon", DuelsWon);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_40x, playerName, i + 1, DuelsWon);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 8: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`DuelsLost` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`DuelsLost` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, DuelsLost;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "DuelsLost", DuelsLost);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_41x, playerName, i + 1, DuelsLost);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 9: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`Cash` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`Cash` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, Cash;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "Cash", Cash);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_42x, playerName, i + 1, formatInt(Cash));
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 10: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`EXP` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`EXP` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, EXP;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "EXP", EXP);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_43x, playerName, i + 1, EXP);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 11: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`Score` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`Score` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, Score;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "Score", Score);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_44x, playerName, i + 1, Score);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 12: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`HighestKillStreak` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`HighestKillStreak` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, HighestKillStreak;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "HighestKillStreak", HighestKillStreak);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_45x, playerName, i + 1, HighestKillStreak);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 13: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`HighestCaptures` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`HighestCaptures` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, HighestCaptures;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "HighestCaptures", HighestCaptures);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_46x, playerName, i + 1, HighestCaptures);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 14: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`HighestKillAssists` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`HighestKillAssists` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, HighestKillAssists;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "HighestKillAssists", HighestKillAssists);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_47x, playerName, i + 1, HighestKillAssists);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
			case 15: {
				new Cache: topResult;
				topResult = mysql_query(Database, "SELECT d1.`Username`, d2.`pID`, d2.`HighestCaptureAssists` FROM `Players` AS d1, `PlayersData` AS d2 WHERE d1.`ID` = d2.`pID` ORDER BY d2.`HighestCaptureAssists` DESC LIMIT 10");
				if (cache_num_rows()) {
					for (new i = 0; i < cache_num_rows(); i++) {
						new playerName[MAX_PLAYER_NAME], pID, HighestCaptureAssists;
						cache_get_value_int(i, "pID", pID);
						cache_get_value(i, "Username", playerName);
						cache_get_value_int(i, "HighestCaptureAssists", HighestCaptureAssists);

						SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_48x, playerName, i + 1, HighestCaptureAssists);
					}
				} else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_423x);
				cache_delete(topResult);
			}
		}
	}
	Dialog_ShowCallback(playerid, using inline TopPlayersMenu, DIALOG_STYLE_LIST, MSG_TOP_PLAYERS_CAP, MSG_TOP_PLAYERS_DESC, MSG_DIALOG_SELECT, MSG_DIALOG_CLOSE);
	return 1;
}

//Change password

CMD:supportkey(playerid, params[]) {
	if (!pVerified[playerid]) return SendClientMessage(playerid, X11_RED, "Please register an account on our server first.");
	if (GetPVarInt(playerid, "UsedSupportKey") == 0) {
		SendClientMessage(playerid, X11_SERV_INFO, "Using a support key will be needed to:");
		SendClientMessage(playerid, X11_SERV_INFO, "- Change account password.");
		SendClientMessage(playerid, X11_SERV_INFO, "- Confirm ownership or delete account.");
		SendClientMessage(playerid, X11_SERV_WARN, "* Use /supportkey again to set one.");
		SetPVarInt(playerid, "UsedSupportKey", 1);
	} 
	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		new new_support_key;
		inline ConfirmKey(pid, dialogid, response, listitem, string:inputtext[])
		{
			#pragma unused dialogid, listitem
			if (response && !isnull(inputtext) && new_support_key == strval(inputtext))
			{
				PlayerPlaySound(pid, 1057, 0.0, 0.0, 0.0);
				SendGameMessage(pid, X11_SERV_SUCCESS, MSG_KEY_CHANGED);
				new query[SMALL_STRING_LEN];
				mysql_format(Database, query, sizeof(query), "UPDATE `Players` SET `SupportKey` = '%d' WHERE `ID` = '%d' LIMIT 1",
				new_support_key, PlayerInfo[pid][pAccountId]);
				mysql_tquery(Database, query);
			}
			else
			{
				SendGameMessage(pid, X11_SERV_ERR, MSG_KEY_UNCHANGED);
			}
		}
		inline ChangeKey(pid, dialogid, response, listitem, string:inputtext[])
		{
			#pragma unused dialogid, listitem
			if (!response) return 1;
			if (isnull(inputtext)) return ShowSyntax(pid, "You haven't entered a new key!");
			if (strlen(inputtext) < 4 || strlen(inputtext) > 20 || !IsNumeric(inputtext)) return ShowSyntax(pid, "Allowed key length is between 4 and 20 numbers and should be numeric only.");
			new_support_key = strval(inputtext);
			Dialog_ShowCallback(pid, using inline ConfirmKey, DIALOG_STYLE_INPUT, "Confirm Key", "Please confirm your new  key below.", "SET", "X");
		}
		Dialog_ShowCallback(playerid, using inline ChangeKey, DIALOG_STYLE_INPUT, "New Key", "Please type your support key below.", ">>", "X");
	} else return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0);
	return 1;
}

CMD:changepass(playerid, params[]) {
	if (!pVerified[playerid]) return SendClientMessage(playerid, X11_RED, "Please register an account on our server first.");
	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		new new_password[MAX_PASS_LEN];
		inline ConfirmPass(pid, dialogid, response, listitem, string:inputtext[])
		{
			#pragma unused dialogid, listitem
			if (response && !isnull(inputtext) && !strcmp(inputtext, new_password))
			{
				bcrypt_hash(pid, "OnPlayerEncrypted", inputtext, BCRYPT_COST);
				PlayerPlaySound(pid, 1057, 0.0, 0.0, 0.0);
				SendGameMessage(pid, X11_SERV_SUCCESS, MSG_NEWCLIENT_49x, inputtext);
				LogActivity(pid, "Changed password", gettime());
			}
			else
			{
				SendGameMessage(pid, X11_SERV_ERR, MSG_ERR_PASS_CHANGE_FAILED);
			}
		}
		inline ChangePass(pid, dialogid, response, listitem, string:inputtext[])
		{
			#pragma unused dialogid, listitem
			if (!response) return 1;
			if (isnull(inputtext)) return ShowSyntax(pid, "You haven't entered a new password!");
			if (strlen(inputtext) < 4 || strlen(inputtext) > 20) return ShowSyntax(pid, "Allowed password length is between 4 and 20 characters.");
			strcat(new_password, inputtext);
			Dialog_ShowCallback(pid, using inline ConfirmPass, DIALOG_STYLE_PASSWORD, "Confirm Password", "Please confirm your new login password below.", "SET", "X");
		}
		Dialog_ShowCallback(playerid, using inline ChangePass, DIALOG_STYLE_PASSWORD, "New Password", "Please type a new login password below.", ">>", "X");
	} else return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0);
	return 1;
}

//Player Settings

DeleteAccount(playerid)
{
	if (GetPVarInt(playerid, "ConfirmDeleteAcc") < 3)
	{
		SendClientMessage(playerid, X11_SERV_WARN, "[Warning] Are you sure you want to delete this account? Please re-select this option 3 times to confirm.");
		SetPVarInt(playerid, "ConfirmDeleteAcc", GetPVarInt(playerid, "ConfirmDeleteAcc") + 1);
		return 1;
	}
	new pname[MAX_PLAYER_NAME];
	format(pname, MAX_PLAYER_NAME, PlayerInfo[playerid][PlayerName]);
	Kick(playerid);
	AnonymizeAccount(pname);
	return 1;
}

CMD:settings(playerid) {
	if (!pVerified[playerid]) return SendClientMessage(playerid, X11_RED, "Please register an account on our server first.");

	inline AntiSKTime(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/settings");

		new seconds;
		if (sscanf(inputtext, "i", seconds)) return ShowSyntax(playerid, "Anti-SK secs: 3-15");
		if (seconds > 15 || seconds <= 2) return ShowSyntax(playerid, "Anti-SK secs: 3-15");
		PlayerPlaySound(pid, 1057, 0.0, 0.0, 0.0);

		PC_EmulateCommand(pid, "/settings");
		PlayerInfo[pid][pSpawnKillTime] = seconds;
	}

	inline PlayerSettings(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return 1;

		new id[6];
		format(id, sizeof(id), "%d", pid);

		switch (listitem) {
			case 0: PC_EmulateCommand(pid, "/noduel");
			case 1: PC_EmulateCommand(pid, "/dnd");
			case 2: PC_EmulateCommand(pid, "/toys");
			case 3: PC_EmulateCommand(pid, "/hud");
			case 4: Dialog_ShowCallback(pid, using inline AntiSKTime, DIALOG_STYLE_INPUT, MSG_DIALOG_MESSAGE_CAP, MSG_ANTI_SPAWN_TIME, MSG_DIALOG_CONFIRM, MSG_DIALOG_CANCEL);
			case 5: PC_EmulateCommand(pid, "/togwatch");
			case 6: PC_EmulateCommand(pid, "/st");
			case 7: PC_EmulateCommand(pid, "/sc");
			case 8: PC_EmulateCommand(pid, "/dm");
			case 9: PC_EmulateCommand(pid, "/mstop");
			case 10: PC_EmulateCommand(pid, "/nodogfight");
			case 11: {
				if (PlayerInfo[pid][pNoTutor]) {
					PlayerInfo[pid][pNoTutor] = false;
					SendClientMessage(playerid, X11_GREEN1, "You will now receive help messages in the chat again.");
				} else {
					PlayerInfo[pid][pNoTutor] = true;
					SendClientMessage(playerid, X11_RED_2, "You will no longer receive help messages forever.");
				}
			}
			case 12: {
				PC_EmulateCommand(pid, "/supportkey");
			}
			case 13: {
				DeleteAccount(pid);
			}
		}
	}

	new settings[1010];
	format(settings, sizeof(settings), "Option\tInfo\n\
	"LIGHTBLUE"No Duels\t%s\n\
	"LIGHTBLUE"Do Not Disturb (No PMs)\t%s\n\
	"LIGHTBLUE"Body Toys\n\
	"LIGHTBLUE"Toggle User Interface\t%s\n\
	"LIGHTBLUE"Spawn Protection Seconds\t%d\n\
	"LIGHTBLUE"Toggle Watch\t%s\n\
	"LIGHTBLUE"Change Team\n\
	"LIGHTBLUE"Change Class\n\
	"LIGHTBLUE"Deathmatch\n\
	"LIGHTBLUE"Stop Playing Sounds\n\
	"LIGHTBLUE"No Dogfights\t%s\n\
	"LIGHTBLUE"Help Messages\t%s\n\
	"LIGHTBLUE"Change Support Key\n\
	"LIGHTBLUE"Delete Account",
	(GetPlayerConfigValue(playerid, "NODUEL") > 0) ? ("[On]") : ("[Off]"),
	(GetPlayerConfigValue(playerid, "DND") > 0) ? ("[On]") : ("[Off]"),
	(GetPlayerConfigValue(playerid, "HUD") > 0) ? ("[On]") : ("[Off]"),
	PlayerInfo[playerid][pSpawnKillTime],
	(GetPlayerConfigValue(playerid, "WATCH") > 0) ? ("[On]") : ("[Off]"),
	(GetPlayerConfigValue(playerid, "NODOGFIGHT") > 0) ? ("[On]") : ("[Off]"),
	(PlayerInfo[playerid][pNoTutor] == true) ? ("[Off]") : ("[On]"));

	Dialog_ShowCallback(playerid, using inline PlayerSettings, DIALOG_STYLE_TABLIST_HEADERS, ""WINE"SvT - Player Settings", settings, ">>", "X");
	return 1;
}

//Help Commands

CMD:help(playerid) {
	inline HelpDialog(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			switch (listitem) {
				case 0: PC_EmulateCommand(pid, "/about");
				case 1: PC_EmulateCommand(pid, "/cmds");
				case 2: PC_EmulateCommand(pid, "/stats");
				case 3: PC_EmulateCommand(pid, "/settings");
				case 4: PC_EmulateCommand(pid, "/objectives");
				case 5: PC_EmulateCommand(pid, "/rules");
				case 6: PC_EmulateCommand(pid, "/teams");
				case 7: PC_EmulateCommand(pid, "/st");
				case 8: PC_EmulateCommand(pid, "/sc");
				case 9: PC_EmulateCommand(pid, "/dm");
				case 10: PC_EmulateCommand(pid, "/streaks");
				case 11: PC_EmulateCommand(pid, "/ranks");
				case 12: PC_EmulateCommand(pid, "/classes");
				case 13: PC_EmulateCommand(pid, "/rank");
				case 14: PC_EmulateCommand(pid, "/streak");
				case 15: PC_EmulateCommand(pid, "/nukehelp");
				case 16: PC_EmulateCommand(pid, "/vshop");
				case 17: PC_EmulateCommand(pid, "/vcmds");
				case 18: PC_EmulateCommand(pid, "/settings");
				case 19: PC_EmulateCommand(pid, "/credits");
			}
		}
	}

	Dialog_ShowCallback(playerid, using inline HelpDialog, DIALOG_STYLE_LIST, "Help",
		"About\n\
		Game Commands\n\
		Your Stats\n\
		Your Settings\n\
		Game Objectives\n\
		Game Rules\n\
		Game Teams\n\
		Switch Team\n\
		Switch Class\n\
		Deathmatch\n\
		Streaks\n\
		Ranks\n\
		Classes\n\
		Your Rank\n\
		Your Streak\n\
		Nuke Help\n\
		V.I.P Shop\n\
		V.I.P Commands\n\
		Settings/Options\n\
		Credits", "Next", "X");
	return 1;
}

CMD:about(playerid) {
	SendClientMessage(playerid, X11_DEEPPINK, "SvT/SvT Server");
	SendClientMessage(playerid, X11_IVORY, "Website:"LIGHTBLUE" "WEBSITE"");
	SendClientMessage(playerid, X11_IVORY, "Discord server:"LIGHTBLUE" https://discord.gg/N24BpY5");
	return 1;
}

CMD:rules(playerid) {
	inline ConfirmRules(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, response, listitem, inputtext
		if (!response) {
			SendClientMessage(pid, X11_WINE, "If you don't agree with our rules please /q.");
		}
	}

	Dialog_ShowCallback(playerid, using inline ConfirmRules, DIALOG_STYLE_MSGBOX, ""WINE"SvT - Server Rules",
	""WHITE"SvT/SvT Game Rules:-\n\
	"WINE"1.) Don't use cheats, hacks or third-party mods\n\
	"WINE"2.) Don't advertise anything out of this server\n\
	"WINE"3.) Use common sense and respect other members\n\
	"WINE"4.) Don't harass, flame or threaten anyone\n\
	"WINE"5.) Don't share your or anyone's personal information\n\
	"WINE"6.) Your game account is completely your responsibility\n\
	"WINE"7.) We will not be removing accounts unless there's a reason for that\n\
	"WINE"8.) Our staff members may punish you for any reason they deem necessary\n\
	"WINE"9.) We may apply other rules that are not listed herein\n\
	"WINE"10.) You may not disrespect the community here or anywhere else\n\
	"WINE"11.) Don't ask for game items, perks or levels from anyone\n\
	"WINE"12.) Use /report if you spot a cheater or have problems with someone\n\
	"WINE"13.) Don't exhaust our staff members with meaningless requests\n\
	"WINE"14.) Don't use server, SA-MP or GTA:SA bugs or attempt to gain profit out of them\n\
	"WINE"15.) We will not ask you for your password on SvT or anywhere else\n\
	"WINE"16.) Don't share your files or allow anyone on your computer for any reason!\n\
	"WINE"17.) We allow slide bug and 2-shot in the battlefield.\n\n\
	"GREEN"Check our website "WEBSITE" and discord server for more information.", "Understood", "No?");
	return 1;
}

CMD:objectives(playerid) {
	SendClientMessage(playerid, X11_LIMEGREEN, "Your objective is to eliminate enemies in the battlefield.");
	return 1;
}

CMD:credits(playerid) {
	SendClientMessage(playerid, -1, "");
	SendClientMessage(playerid, -1, "");
	SendClientMessage(playerid, X11_MAROON, "------=Credits=------");
	SendClientMessage(playerid, X11_WINE, "==> Senior Game Development and Ownership: H2O");
	SendClientMessage(playerid, X11_WINE, "==> Community Management: Swanson, denNorske");
	SendClientMessage(playerid, X11_WINE, "==> Beta Team: Aevanora, Impulse, Queen, Alfa, Swanson");
	SendClientMessage(playerid, X11_WINE, "==> Minor Past Scripting: DarkZero");
	SendClientMessage(playerid, X11_WINE, "==> Past Mapping Lead: Hydra, JustCurious");
	SendClientMessage(playerid, X11_WINE, "==> Past Mappers: SKAY, Revan, ScreaM, Lucifer");
	SendClientMessage(playerid, X11_WINE, "==> Additional Mapping Used: spitfire, RedFusion");
	SendClientMessage(playerid, X11_WINE, "==> Thanks for everyone who helped make this possible.");
	SendClientMessage(playerid, X11_WINE, "==> And you for playing!");
	SendClientMessage(playerid, -1, "");
	SendClientMessage(playerid, -1, "");
	return 1;
}

alias:forum("website", "web")
CMD:forum(playerid) {
	SendClientMessage(playerid, X11_DEEPSKYBLUE, "Website: https://"WEBSITE"/");
	return 1;
}

CMD:war(playerid) {
	if (!WarInfo[War_Started]) return SendClientMessage(playerid, X11_WINE, "There is no running team war currently.");
	new string[128];
	format(string, sizeof(string), "|| WAR INFO || First Team: "RED"%s"CYAN" - Second Team: "RED"%s", Team_GetName(WarInfo[War_Team1]), Team_GetName(WarInfo[War_Team2]));
	SendClientMessage(playerid, X11_CYAN, string);
	format(string, sizeof(string), "|| WAR TARGET || %s - %d pts needed", WarTargets[WarInfo[War_Target]], WarInfo[War_Score]);
	SendClientMessage(playerid, X11_CYAN, string);
	return 1;
}

CMD:cmds(playerid) {
	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, ""WINE"SvT - Commands",
	"{638FD6}All Commands\n\n\
	{FFFFFF}\
	/help /objectives /top /admins /about /afks /mode /dmers /elist /pubgers\n\
	/duelers /qdm /kill /exit /nuke /music /mstop /streaks /ep /rules /bounties\n\
	/ranks /teams /vips /vip /race\n\n\
	{638FD6}Player Commands\n\n\
	{FFFFFF}\
	/st /sc /sp /vshop /changepass /streak /rank /tr /pm /r /missions /block /unblock\n\
	/local /sendmoney /setbounty /hud /settings /laser /duel /dogfight /noduel\n\
	/backup /respond /edithelmet /editmask /editdynamite /toys /wine /edittoy\n\
	/rmtoy /opencrate /ewatch /votekick /cweap /inv /invest /trade /tradepanel\n\n\
	{638FD6}Clan Commands\n\n\
	{FFFFFF}\
	/ccreate /claninfo /ckick /ockick /cskin /cmyskin /clanperks /accept /cleave /clans /cmembers\n\
	/cmon /clan /csetrank /csetleader /cinvite /cdonate /cwithdraw /clanranks /clanpoints\n\
	/cweapon /cweap /c /cann /resetskin /clogger\n\n\
	{638FD6}Limited Commands\n\n\
	{FFFFFF}\
	/airstrike /drop /rebuildantenna /mk /ak /heal /repair /pb /suicide /spy /spy /locate\n\
	/nospy /jp /fr /classes /togwatch /watch /watchoff /fire /dropgun /pickup\n\n\
	{638FD6}Animations\n\n\
	{FFFFFF}\
	/handsup /drunk /bomb /getarrested /laugh /robman /crossarms /lay /hide /vomit /wave\n\
	/taichi /piss /deal /crack /smokem /smokef /sit /chat /dance /fu\n\n\
	"WINE"KEY_YES: Rope rappelling from helicopter, stopping dynamite, emergency eject, grabbing helmet,\n\
	Activating base balloon, flashbang (Scout Class)\n\
	KEY_FIRE: Emulates the /fire command",
	"X", "");
	return 1;
}
alias:cmds("commands", "chelp", "ccmds", "pcmds", "gcmds", "scmds", "shortcuts")

alias:ask("helpme", "admin")
CMD:ask(playerid, params[]) {
	if (PlayerInfo[playerid][pMuted] == 1) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
		return 0;
	}

	if (!ComparePrivileges(playerid, CMD_OWNER) && svtconf[anti_adv] && AdCheck(params)) {
		PlayerInfo[playerid][pAdvAttempts] ++;
		return 0;
	}

	if (PlayerInfo[playerid][pQuestionAsked]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_449x);
	PlayerInfo[playerid][pQuestionsAsked] ++;

	new String[MEDIUM_STRING_LEN], message[SMALL_STRING_LEN];
	if (sscanf(params, "s[128]", message)) {
		ShowSyntax(playerid, "/ask [text]");
		return 1;
	}

	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_108x, PlayerInfo[playerid][PlayerName], playerid, message);
	foreach (new i: Player) {
		if (ComparePrivileges(i, CMD_MEMBER)) {
			SendGameMessage(i, X11_SERV_INFO, MSG_NEWCLIENT_108x, PlayerInfo[playerid][PlayerName], playerid, message);
		}
	}

	format(String, sizeof(String), "%s[%d] asked: %s (in game)", PlayerInfo[playerid][PlayerName], playerid, message);

	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_450x);
	PlayerInfo[playerid][pQuestionAsked] = 1;
	return 1;
}

//Achievements

alias:achievements("myachs", "achs", "myachievements")
CMD:achievements(playerid) {
	Dialog_Show(playerid, DIALOG_STYLE_TABLIST_HEADERS, ""WINE"SvT - Achievements", Achievements_List(), "X");
	return 1;
}

//Commit Suicide

alias:kill("exit")
CMD:kill(playerid) {
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	if (!IsPlayerSpawned(playerid)) return SendClientMessage(playerid, X11_RED_2, "You cannot use this command right now!");

	if (AntiSK[playerid]) {
		EndProtection(playerid);
	}

	if (PlayerInfo[playerid][pDeathmatchId] != -1) {
		pDMKills[playerid][PlayerInfo[playerid][pDeathmatchId]] = 0;
		PlayerInfo[playerid][pDeathmatchId] = -1;
	}
	SetPlayerVirtualWorld(playerid, BF_WORLD);
	SetPlayerHealth(playerid, 0.0);

	SendDeathMessage(INVALID_PLAYER_ID, playerid, 255);
	PlayerInfo[playerid][pSuicideAttempts] ++;
	return 1;
}

//User Interface

CMD:hud(playerid) {
	if (GetPlayerConfigValue(playerid, "HUD")) {
		SetPlayerConfigValue(playerid, "HUD", 0);
	} else {
		SetPlayerConfigValue(playerid, "HUD", 1);
	}

	UpdatePlayerHUD(playerid);
	return 1;
}

CMD:watch(playerid, params[]) {
	new targetid;
	if (sscanf(params, "u", targetid)) return SendClientMessage(playerid, X11_WINE, "Invalid player id/name specified.");
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_445x);
	if (!pVerified[targetid] || targetid == INVALID_PLAYER_ID || playerid == targetid) return SendClientMessage(playerid, X11_WINE, "Can't spectate this player.");
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	if (!GetPlayerConfigValue(targetid, "WATCH")) return SendClientMessage(playerid, X11_WINE, "This player doesn't allow others from watching them. Tell them to use /togwatch!");
	TogglePlayerSpectating(playerid, true);
	PlayerInfo[playerid][pSpecId] = targetid;
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
	SetPlayerInterior(playerid, GetPlayerInterior(targetid));
	if (!IsPlayerInAnyVehicle(targetid)) {
		PlayerSpectatePlayer(playerid, targetid);
	} else {
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(targetid));
	}
	new string[128];
	format(string, sizeof(string), "You are now watching %s[%d]. Use /watchoff to stop watching them!", PlayerInfo[targetid][PlayerName], targetid);
	SendClientMessage(playerid, X11_GREEN, string);
	format(string, sizeof(string), "You are being watched by %s[%d]. Use /togwatch to disable this feature!", PlayerInfo[playerid][PlayerName], playerid);
	SendClientMessage(targetid, X11_ORANGE, string);
	return 1;
}

CMD:watchoff(playerid) {
	if (PlayerInfo[playerid][pSpecId] != INVALID_PLAYER_ID) {
		SendClientMessage(playerid, X11_GREEN, "You will be respawned.");
		StopSpectate(playerid);
	} else SendClientMessage(playerid, X11_WINE, "You are not watching anyone.");
	return 1;
}

CMD:togwatch(playerid) {
	if (GetPlayerConfigValue(playerid, "WATCH")) {
		SetPlayerConfigValue(playerid, "WATCH", 0);
		SendClientMessage(playerid, X11_WINE, "Other players will not be able to watch you.");
		foreach (new i: Player) {
			if (PlayerInfo[i][pSpecId] == playerid && !ComparePrivileges(i, CMD_MEMBER)) {
				StopSpectate(i);
				SendClientMessage(playerid, X11_WINE, "This player no longer allows you to watch them.");
			}
		}
	} else {
		SetPlayerConfigValue(playerid, "WATCH", 1);
		SendClientMessage(playerid, X11_GREEN, "Other players will now be able to watch you.");
	}
	return 1;
}

//Animations

CMD:handsup(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_HANDSUP);
	return 1;
}

CMD:cellin(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USECELLPHONE);
	return 1;
}

CMD:cellout(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_STOPUSECELLPHONE);
	return 1;
}

CMD:drunk(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "PED", "WALK_DRUNK", 4.0, 1, 1, 1, 1, 0);
	return 1;
}

CMD:wine(playerid) {
	return SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DRINK_WINE);
}

CMD:bomb(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	ClearAnimations(playerid);
	AnimPlayer(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:getarrested(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "ped", "ARRESTgun", 4.0, 0, 1, 1, 1, -1);
	return 1;
}

CMD:laugh(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "RAPPING", "Laugh_01", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:lookout(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "SHOP", "ROB_Shifty", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:piss(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	SetPlayerSpecialAction(playerid, 68);
	return 1;
}

CMD:robman(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "SHOP", "ROB_Loop_Threat", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:crossarms(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "COP_AMBIENT", "Coplook_loop", 4.0, 0, 1, 1, 1, -1);
	return 1;
}

CMD:lay(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "BEACH", "bather", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:hide(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "ped", "cower", 3.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:vomit(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "FOOD", "EAT_Vomit_P", 3.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:eat(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "FOOD", "EAT_Burger", 3.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:wave(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "ON_LOOKERS", "wave_loop", 4.0, 1, 0, 0, 0, 0);

	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);

	foreach (new i: Player) {
		if (IsPlayerInRangeOfPoint(i, 10.0, X, Y, Z) && i != playerid) {
			SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_546x, PlayerInfo[playerid][PlayerName], playerid);
		}
	}
	return 1;
}

CMD:slapass(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "SWEET", "sweet_Adm_slap", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:deal(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "DEALER", "DEALER_DEAL", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:crack(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "CRACK", "crckdeth2", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:smokem(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "SMOKING", "M_smklean_loop", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:smokef(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "SMOKING", "F_smklean_loop", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:sit(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "BEACH", "ParkSit_M_loop", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:fu(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "PED", "fucku", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:taichi(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "PARK", "Tai_Chi_Loop", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:chairsit(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimLoopPlayer(playerid, "BAR", "dnk_stndF_loop", 4.0, 1, 0, 0, 0, 0);
	return 1;
}

CMD:chat(playerid) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);
	AnimPlayer(playerid, "PED", "IDLE_CHAT", 4.0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:dance(playerid, params[]) {
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_464x);

	new dancestyle;
	if (!sscanf(params, "d", dancestyle)) {
		switch (dancestyle) {
			case 1: {
				SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE1);
			}
			case 2: {
				SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE2);
			}
			case 3: {
				SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE3);
			}
			case 4: {
				SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE4);
			}
			default: {
				GameTextForPlayer(playerid, "~r~Invalid, Dance Id~n~~w~~y~/Dance (1-4)", 3500, 3);
			}
		}
	} else return GameTextForPlayer(playerid, "~w~~y~/Dance (1-4)", 3500, 3);
	return 1;
}

alias:spree("streak")
CMD:spree(playerid) {
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_110x, pStreak[playerid]);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_111x, PlayerInfo[playerid][pHighestKillStreak]);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_112x, PlayerInfo[playerid][pHighestKillAssists]);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_113x, PlayerInfo[playerid][pCaptureStreak]);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_114x, PlayerInfo[playerid][pHighestCaptures]);
	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_115x, PlayerInfo[playerid][pHighestCaptureAssists]);
	return 1;
}

//Radio

StreamURL(playerid, const URL[], custom = true) {
	if (!custom) return PlayAudioStreamForPlayer(playerid, URL, 0.0, 0.0, 0.0, 0.0, 0);
	PlayAudioStreamForPlayer(playerid, URL, 0.0, 0.0, 0.0, 0.0, 0);
	format(pPreviousStreamdLink[playerid], 512, URL);
	pStreamedLink[playerid] = 1;
	return 1;
}

alias:radio("music", "stream", "playurl")
CMD:radio(playerid, params[]) {
	inline CustomURL(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem
		if (response) {
			if (strlen(inputtext) >= 511 || strlen(inputtext) < 10) return SendClientMessage(playerid, X11_RED_2, "The URL you specified is either too long or too short.");
			StreamURL(pid, inputtext);
		}
	}
	inline RadioSystem(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			switch (listitem) {
				case 0: Dialog_ShowCallback(pid, using inline CustomURL, DIALOG_STYLE_INPUT, ""WINE"SvT - Stream URL", "Please write a valid MP3 URL to stream",
						"Play", "Cancel");
				case 1: {
					if (!isnull(pPreviousStreamdLink[pid])) {
						StreamURL(pid, pPreviousStreamdLink[pid]);
					} else SendClientMessage(pid, X11_RED_2, "You haven't played any link previously!");
				}
				case 2: PC_EmulateCommand(pid, "/mstop");
			}
		}
	}
	Dialog_ShowCallback(playerid, using inline RadioSystem, DIALOG_STYLE_LIST, ""WINE"SvT - Audio Management",
	"Play Custom URL\n\
	Play Previous\n\
	Stop Streaming", ">>", "X");
	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_465x);
	return 1;
}

CMD:mstop(playerid) {
	pStreamedLink[playerid] = 0;
	StopAudioStreamForPlayer(playerid);
	return 1;
}

//General

//Updates

/*alias:updates("news", "update", "changelog")
CMD:updates(playerid) {
	new whole_update[2047];
	for (new i = 0; i < sizeof(Changelog); i++) {
		format(whole_update, sizeof(whole_update), "%s\n%s", whole_update, Changelog[i]);
	}
	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, Version, whole_update, "X");
	return 1;
}*/

CMD:afks(playerid) {
	new count;

	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_187x);

	foreach (new i: Player) {
		if (PlayerInfo[i][pIsAFK]) {
			count ++;
			SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_188x, count, PlayerInfo[i][PlayerName], gettime() - PlayerInfo[i][pAFKTick]);
		}
	}

	if (!count) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_337x);
	}
	return 1;
}

//Bounties

CMD:setbounty(playerid, params[]) {
	new targetid, amount;
	if (sscanf(params, "ui", targetid, amount)) return ShowSyntax(playerid, "/setbounty [playerid/name] [cash]");
	if (!pVerified[targetid] || targetid == INVALID_PLAYER_ID) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	if (PlayerInfo[targetid][pBountyAmount] > 100000000) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_332x);
	if (amount <= 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_325x);
	if (amount > GetPlayerCash(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_326x);

	SendGameMessage(@pVerified, X11_SERV_WARN, MSG_NEWSERVER_60x, PlayerInfo[playerid][PlayerName], playerid, formatInt(amount), PlayerInfo[targetid][PlayerName], targetid);

	PlayerInfo[targetid][pBountyAmount] += amount;
	PlayerInfo[playerid][pBountyCashSpent] += amount;

	GivePlayerCash(playerid, -amount);
	return 1;
}

CMD:bounties(playerid) {
	new sub_holder[35], bounty_holder[750], count = 0;

	strcat(bounty_holder, "Player\tValue\n");

	foreach (new i: Player) {
		if (PlayerInfo[i][pBountyAmount]) {
			format(sub_holder, sizeof(sub_holder), "%s\t%s\n", PlayerInfo[i][PlayerName], formatInt(PlayerInfo[i][pBountyAmount]));
			strcat(bounty_holder, sub_holder);

			count ++;
		}
	}

	if (count) {
		Dialog_Show(playerid, DIALOG_STYLE_TABLIST_HEADERS, "Bounty Heads", bounty_holder, "X", "");
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_331x);
	return 1;
}

//Parachute

CMD:ep(playerid) {
	GivePlayerWeapon(playerid, 46, 1);
	return 1;
}

//Get ID

CMD:getid(playerid, params[]) {
	if (isnull(params)) return ShowSyntax(playerid, "/getid [part name]");

	new rows;

	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_192x, params);

	foreach (new i: Player) {
		new bool: searched = false;
		for (new pos = 0; pos <= strlen(PlayerInfo[i][PlayerName]); pos ++) {
			if (searched != true) {
				if (strfind(PlayerInfo[i][PlayerName], params, true) == pos) {
					new string[75];
					format(string, sizeof(string), "%s [id: %d]", PlayerInfo[i][PlayerName], i);
					SendClientMessage(playerid, X11_LIMEGREEN, string);
					searched = true;
					rows ++;
				}
			}
		}
	}

	if (rows == 0) SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_327x);
	return 1;
}

//Sending Money

alias:sm("sendmoney")
CMD:sm(playerid, params[]) {
	new
		targetid,
		amount
	;

	if (sscanf(params, "ud", targetid, amount)) return ShowSyntax(playerid, "/sm [playerid/name] [amount]");
	if (targetid == INVALID_PLAYER_ID || !pVerified[targetid] || targetid == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);

	if (GetPlayerCash(playerid) <= amount) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_326x);

	if (amount < 1 || !amount) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_325x);
	if (amount > MAX_SM) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_324x);

	GivePlayerCash(targetid, amount);
	GivePlayerCash(playerid, -amount);

	SendGameMessage(targetid, X11_SERV_INFO, MSG_CLIENT_322x, formatInt(amount), PlayerInfo[playerid][PlayerName]);
	PlayerInfo[targetid][pMoneyReceived] += amount;

	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_323x, formatInt(amount), PlayerInfo[targetid][PlayerName]);
	PlayerInfo[playerid][pMoneySent] += amount;
	return 1;
}

//Commands

CMD:cmyskin(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (IsPlayerInAnyClan(playerid) && GetClanSkin(GetPlayerClan(playerid)) != 0) {
		SetPlayerSkin(playerid, (GetClanSkin(GetPlayerClan(playerid))));
	}
	return 1;
}

CMD:cweap(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	if (pDogfightTarget[playerid] != INVALID_PLAYER_ID) return SendClientMessage(playerid, X11_WINE, "You are dogfighting someone.");

	//Clan weapon
	if (IsPlayerInAnyClan(playerid)) {
		if (GetClanWeapon(GetPlayerClan(playerid)) != 0) {
			foreach (new x: allowed_weapons) {
				if (x == GetClanWeapon(GetPlayerClan(playerid))) {
					new message[150];
					GivePlayerWeapon(playerid, x, Weapons_GetAmmo(x));

					format(message, sizeof(message), "~g~Clan Weap On:~w~ %s[ammo: %d]", ReturnWeaponName(x), Weapons_GetAmmo(x));
					NotifyPlayer(playerid, message);
					break;
				}
			}
		} else SendClientMessage(playerid, X11_WINE, "Your clan leader didn't purchase any clan weapons.");
	} else SendClientMessage(playerid, X11_WINE, "You are not in any clan.");
	return 1;
}

CMD:opencrate(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (!PlayerInfo[playerid][pCrates]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_335x);
	if (PlayerInfo[playerid][pDonorLevel]) {
		KillTimer(CrateTimer[playerid]);
		OpenCrate(playerid);
		PlayerPlaySound(playerid, 1068, 0.0, 0.0, 0.0);
		AnimPlayer(playerid, "ROB_BANK", "CAT_Safe_Open", 8.0, 0, 0, 0, 0, 0);

		new Float: X, Float: Y, Float: Z;
		GetXYZInfrontOfPlayer(playerid, X, Y, 0.7);
		CA_FindZ_For2DCoord(X, Y, Z);

		new crate = CreateDynamicObject(3014, X, Y, Z, 0.0, 0.0, 0.0);
		SetTimerEx("DestroyCrate", 5000, false, "i", crate);
	} else {
		KillTimer(CrateTimer[playerid]);
		CrateTimer[playerid] = SetTimerEx("OpenCrate", 5000, false, "i", playerid);
		PlayerPlaySound(playerid, 1068, 0.0, 0.0, 0.0);
		AnimPlayer(playerid, "ROB_BANK", "CAT_Safe_Open", 8.0, 0, 0, 0, 0, 0);

		new Float: X, Float: Y, Float: Z;
		GetXYZInfrontOfPlayer(playerid, X, Y, 0.7);
		CA_FindZ_For2DCoord(X, Y, Z);

		new crate = CreateDynamicObject(3014, X, Y, Z, 0.0, 0.0, 0.0);
		SetTimerEx("DestroyCrate", 5000, false, "i", crate);
	}
	return 1;
}

//Duel Commands

CMD:duelers(playerid) {
	new sub_holder[27], string[MEDIUM_STRING_LEN], count = 0;

	foreach (new i: Player) {
		if (pDuelInfo[i][pDInMatch]) {
			format(sub_holder, sizeof(sub_holder), "%s\t%s\t%s\t%s\n", PlayerInfo[i][PlayerName],
				PlayerInfo[TargetOf[i]][PlayerName], ReturnWeaponName(GetPlayerWeapon(i)), formatInt(pDuelInfo[i][pDBetAmount]));
			strcat(string, sub_holder);

			count = 1;
		}
	}

	if (count) {
		Dialog_Show(playerid, DIALOG_STYLE_TABLIST, "Duelers", string, "X", "");
	}  else SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	return 1;
}

CMD:dogfighters(playerid) {
	new sub_holder[27], string[MEDIUM_STRING_LEN], count = 0;

	foreach (new i: Player) {
		if (pDogfightTarget[i] != INVALID_PLAYER_ID) {
			format(sub_holder, sizeof(sub_holder), "%s\t%s\t%s\t%s\n", PlayerInfo[i][PlayerName],
				PlayerInfo[TargetOf[i]][PlayerName], VehicleNames[pDogfightModel[i]-400], formatInt(pDogfightBet[i]));
			strcat(string, sub_holder);

			count = 1;
		}
	}

	if (count) {
		Dialog_Show(playerid, DIALOG_STYLE_TABLIST, "Dogfighters", string, "X", "");
	}  else SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	return 1;
}

CMD:matchfacts(playerid) {
	NotifyPlayer(playerid, "Fetching your dogfight match facts... Please wait.", 1);

	new get_facts[256];

	//Matches Played
	mysql_format(Database, get_facts, sizeof(get_facts), "SELECT COUNT(*) AS Matches FROM `Dogfights` WHERE `FirstOppID` = '%d' OR `WinnerID` = '%d'",
	PlayerInfo[playerid][pAccountId], PlayerInfo[playerid][pAccountId]);
	mysql_tquery(Database, get_facts, "DFMatchesPlayed", "i", playerid);

	return 1;
}

//pDogfightTarget[playerid]
/*
pDogfightTarget[playerid] = INVALID_PLAYER_ID;
pDogfightBet[playerid] = 0;
*/
CMD:dogfight(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	if (pDogfightTarget[playerid] != INVALID_PLAYER_ID) return SendClientMessage(playerid, X11_WINE, "You are already dogfighting someone.");

	new
		ID, bet, model;
	if (sscanf(params, "uii", ID, bet, model)) return ShowSyntax(playerid, "/dogfight [playerid/name] [bet] [plane model(476-520 only)]");
	if (!IsPlayerStreamedIn(ID, playerid) || ID == playerid) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_STREAMED);

	if (GetPlayerCash(playerid) < bet || GetPlayerCash(ID) < bet) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_483x);
	if (bet > svtconf[max_duel_bets] || bet < 1) {
		new string[95];
		format(string, sizeof(string), "Bet: $1-%s", formatInt(svtconf[max_duel_bets]));
		SendClientMessage(playerid, X11_WINE, string);
		return 1;
	}
	if (model != 476 && model != 520) return SendClientMessage(playerid, X11_WINE, "The plane model must be a rustler or a hydra!");
	if (pDogfightInviter[ID] != INVALID_PLAYER_ID) return SendClientMessage(playerid, X11_WINE, "This player was already invited to a dogfight recently.");

	new string[128];
	format(string, sizeof(string), "You were invited to a dogfight by %s[%d] for %s (plane model: %s). Use /acceptdogfight or /rejectdogfight!", PlayerInfo[playerid][PlayerName], playerid, formatInt(bet), VehicleNames[model-400]);

	pDogfightBet[playerid] = bet;
	pDogfightModel[playerid] = model;
	pDogfightInviter[ID] = playerid;

	SendClientMessage(playerid, X11_YELLOW, "Your dogfight request was sent. Please wait the player to accept it.");
	SendClientMessage(ID, X11_YELLOW, string);
	SendClientMessage(ID, X11_RED, "You can toggle off duels/dogfight requests at any time using /noduel.");
	return 1;
}

CMD:acceptdogfight(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	if (!pVerified[pDogfightInviter[playerid]]
	|| pDogfightInviter[playerid] == playerid || GetPlayerConfigValue(pDogfightInviter[playerid], "NODUEL") == 1
		|| !IsPlayerInMode(pDogfightInviter[playerid], MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_482x);
	if (AntiSK[playerid] == 1 || AntiSK[pDogfightInviter[playerid]] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_482x);
	if (pDogfightModel[pDogfightInviter[playerid]] != 476 && pDogfightModel[pDogfightInviter[playerid]] != 520) return SendClientMessage(playerid, X11_WINE, "The plane model chosen by the opponent must be a rustler or a hydra!");

	//Initialize the dogfight
	SetupDogfightMode(playerid);
	SetupDogfightMode(pDogfightInviter[playerid]);

	//Setup targets
	pDogfightTarget[playerid] = pDogfightInviter[playerid];
	pDogfightTarget[pDogfightInviter[playerid]] = playerid;

	//Sync the dogfight across the opponents
	pDogfightBet[playerid] = pDogfightBet[pDogfightTarget[playerid]];
	pDogfightModel[playerid] = pDogfightModel[pDogfightTarget[playerid]];

	//Set one unique virtual world
	SetPlayerVirtualWorld(playerid, DUEL_WORLD + playerid);
	SetPlayerVirtualWorld(pDogfightTarget[playerid], DUEL_WORLD + playerid);

	new random_airport = random(3);
	switch (random_airport) {
		case 0: { //Los Santos
			CreateDFPlane(playerid, 1466.8269,1596.0817,11.5179,179.1749, DUEL_WORLD + playerid);
			CreateDFPlane(pDogfightTarget[playerid], 1477.5409,1596.7214,11.5192,0.8927, DUEL_WORLD + playerid);
		}
		case 1: { //San Fierro
			CreateDFPlane(playerid, -1447.8286,33.8538,14.8610,317.0442, DUEL_WORLD + playerid);
			CreateDFPlane(pDogfightTarget[playerid], -1457.8441,45.3680,14.8678,134.9894, DUEL_WORLD + playerid);
		}
		default: { //Las Venturas
			CreateDFPlane(playerid, 1754.7589,-2600.7361,14.2543,270.4100, DUEL_WORLD + playerid);
			CreateDFPlane(pDogfightTarget[playerid], 1756.2159,-2584.8354,14.2600,89.9626, DUEL_WORLD + playerid);
		}
	}

	//Player is no longer "invited"
	pDogfightInviter[playerid] = INVALID_PLAYER_ID;

	//
	new string[128];
	format(string, sizeof(string), "Dogfight ~r~%s ~w~vs ~r~%s ~w~for ~g~%s", PlayerInfo[playerid][PlayerName], PlayerInfo[pDogfightTarget[playerid]][PlayerName], formatInt(pDogfightBet[playerid]));
	SendWarUpdate(string);
	LogActivity(pDogfightTarget[playerid], "Dogfight against #%d for %s with %d", gettime(), PlayerInfo[playerid][pAccountId], formatInt(pDogfightBet[playerid]), pDogfightModel[playerid]);
	LogActivity(playerid, "Dogfight against #%d for %s with %d", gettime(), PlayerInfo[pDogfightTarget[playerid]][pAccountId], formatInt(pDogfightBet[playerid]), pDogfightModel[playerid]);
	return 1;
}

CMD:rejectdogfight(playerid) {
	if (pDogfightInviter[playerid] == INVALID_PLAYER_ID) return SendClientMessage(playerid, X11_WINE, "You are not invited to a dogfight currently.");
	if (!pVerified[pDogfightInviter[playerid]]) return SendClientMessage(playerid, X11_WINE, "The player who invited you for a dogfight is no longer signed in."),
		pDogfightInviter[playerid] = INVALID_PLAYER_ID;
	new string[128];
	format(string, sizeof(string), "%s[%d] rejected your dogfight request. Try again sometime later!", PlayerInfo[playerid][PlayerName], playerid);
	SendClientMessage(pDogfightInviter[playerid], X11_WINE, string);
	SendClientMessage(playerid, X11_WINE, "You rejected the dogfight request. You can use /noduel to disable all dogfight/duel requests.");
	pDogfightInviter[playerid] = INVALID_PLAYER_ID;
	return 1;
}

CMD:duel(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	
	new
		ID, bet, rematch, rcduel;
	if (sscanf(params, "uiii", ID, bet, rematch, rcduel)) return ShowSyntax(playerid, "/duel [playerid/name] [bet cash] [rematch (0-1)] [rcduel (0-1)]");
	if (!IsPlayerStreamedIn(ID, playerid) || ID == playerid) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_STREAMED);

	if (GetPlayerCash(playerid) < bet || GetPlayerCash(ID) < bet) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_483x);
	if (bet > svtconf[max_duel_bets] || bet < 1) {
		new string[95];
		format(string, sizeof(string), "Bet: $1-%s", formatInt(svtconf[max_duel_bets]));
		SendClientMessage(playerid, X11_WINE, string);
		return 1;
	}

	if (rematch > 1 || rematch < 0) return ShowSyntax(playerid, "Rematch opt: 0-1");
	if (rcduel > 1 || rcduel < 0) return ShowSyntax(playerid, "RC duel opt: 0-1");

	new sub_str[30], weaponstr[1024], weapon_listitem[MAX_WEAPONS], total_weapons;

	foreach (new i: allowed_weapons) {
		format(sub_str, sizeof(sub_str), "{00CC00}%s\n", ReturnWeaponName(i));
		strcat(weaponstr, sub_str);
		weapon_listitem[total_weapons] = i;
		total_weapons ++;
	}

	inline DuelMap(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return TargetOf[pid] = INVALID_PLAYER_ID;
		if (TargetOf[pid] != INVALID_PLAYER_ID && pVerified[TargetOf[pid]]) {
			if (pDuelInfo[TargetOf[pid]][pDInMatch] == 0 && pDuelInfo[TargetOf[pid]][pDLocked] == 0) {
				if (AntiSK[TargetOf[pid]] == 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_482x);

				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_484x, ReturnWeaponName(pDuelInfo[pid][pDWeapon]), PlayerInfo[TargetOf[pid]][PlayerName], formatInt(pDuelInfo[pid][pDBetAmount]));

				TargetOf[TargetOf[pid]] = pid;
				pDuelInfo[pid][pDMapId] = listitem;

				SendGameMessage(TargetOf[pid], X11_SERV_INFO, MSG_CLIENT_485x, PlayerInfo[pid][PlayerName], ReturnWeaponName(pDuelInfo[pid][pDWeapon]), formatInt(pDuelInfo[pid][pDBetAmount]), (pDuelInfo[pid][pDRematchOpt] == 1) ? ("Yes") : ("No"));
				SendGameMessage(TargetOf[pid], X11_SERV_INFO, MSG_CLIENT_486x);

				pDuelInfo[pid][pDInvitePeriod] = gettime() + 50;
				pDuelInfo[TargetOf[pid]][pDInvitePeriod] = gettime() + 50;
				pDuelInfo[pid][pDLocked] = 1;
				pDuelInfo[TargetOf[pid]][pDLocked] = 1;
				PlayerInfo[pid][pDuelRequests] ++;
				SendClientMessage(TargetOf[pid], X11_RED, "You can toggle off duels/dogfight requests at any time using /noduel.");
			}
		}  else SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_487x);
	}

	if (!rcduel) {
		inline DuelWeapon2(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (!response) return TargetOf[pid] = INVALID_PLAYER_ID;

			Dialog_ShowCallback(pid, using inline DuelMap, DIALOG_STYLE_LIST, "Select Map:", "Stadium\nBattlefield\nLVPD\nDocks Arena", ">>", "Exit");

			pDuelInfo[pid][pDWeapon2] = weapon_listitem[listitem];
			pDuelInfo[pid][pDAmmo2] = 9999;
		}

		inline DuelWeapon1(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (!response) return TargetOf[pid] = INVALID_PLAYER_ID;

			foreach (new i: allowed_weapons) {
				format(sub_str, sizeof(sub_str), "{00CC00}%s\n", ReturnWeaponName(i));
				strcat(weaponstr, sub_str);
			}
			Dialog_ShowCallback(pid, using inline DuelWeapon2, DIALOG_STYLE_LIST, "Select Weapon (2):", weaponstr, ">>", "Exit");

			pDuelInfo[pid][pDWeapon] = weapon_listitem[listitem];
			pDuelInfo[pid][pDAmmo] = 9999;
		}
		Dialog_ShowCallback(playerid, using inline DuelWeapon1, DIALOG_STYLE_LIST, "Select Weapon (1):", weaponstr, ">>", "Exit");
	} else {
		Dialog_ShowCallback(playerid, using inline DuelMap, DIALOG_STYLE_LIST, "Select RC Duel Map:", "Stadium\nBattlefield\nLVPD\nDocks Arena", ">>", "Exit");
	}

	TargetOf[playerid] = ID;
	pDuelInfo[playerid][pDBetAmount] = bet;
	pDuelInfo[playerid][pDRematchOpt] = rematch;
	pDuelInfo[playerid][pDRCDuel] = rcduel;
	pDuelInfo[playerid][pDInvitePeriod] = gettime() + 30;
	return 1;
}

CMD:noduel(playerid) {
	if (pDuelInfo[playerid][pDInMatch]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INDUEL);
	if (GetPlayerConfigValue(playerid, "NODUEL") == 1) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_488x);
		SetPlayerConfigValue(playerid, "NODUEL", 0);
	}
	else
	{
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_489x);
		SetPlayerConfigValue(playerid, "NODUEL", 1);
	}
	return 1;
}

CMD:nodogfight(playerid) {
	if (pDuelInfo[playerid][pDInMatch]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INDUEL);
	if (GetPlayerConfigValue(playerid, "NODOGFIGHT") == 1) {
		SendClientMessage(playerid, X11_RED_2, "> Disabled dogfights.");
		SetPlayerConfigValue(playerid, "NODOGFIGHT", 0);
	}
	else
	{
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_489x);
		SetPlayerConfigValue(playerid, "NODOGFIGHT", 1);
		SendClientMessage(playerid, X11_RED_2, "> Enabled dogfights.");
	}
	return 1;
}

CMD:acceptduel(playerid) {
	if (gettime() > pDuelInfo[playerid][pDInvitePeriod] || !pDuelInfo[playerid][pDLocked]) {
		return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_490x);
	}

	if (TargetOf[playerid] == INVALID_PLAYER_ID || !pVerified[TargetOf[playerid]]) {
		pDuelInfo[playerid][pDInMatch] = 0;
		pDuelInfo[playerid][pDLocked] = 0;
		TargetOf[playerid] = INVALID_PLAYER_ID;

		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_491x);
		return 1;
	}

	if (!IsPlayerSpawned(TargetOf[playerid])) {
		pDuelInfo[playerid][pDLocked] = 0;
		pDuelInfo[TargetOf[playerid]][pDLocked] = 0;
		TargetOf[playerid] = INVALID_PLAYER_ID;

		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_492x);
		return 1;
	}

	SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_69x, PlayerInfo[TargetOf[playerid]][PlayerName], PlayerInfo[playerid][PlayerName], formatInt(pDuelInfo[TargetOf[playerid]][pDBetAmount]));

	EndProtection(playerid);
	EndProtection(TargetOf[playerid]);

	ResetPlayerWeapons(playerid);
	ResetPlayerWeapons(TargetOf[playerid]);

	pDuelInfo[playerid][pDCountDown] = pDuelInfo[TargetOf[playerid]][pDCountDown] = gettime() + 99;
	pDuelInfo[playerid][pDBetAmount] = pDuelInfo[TargetOf[playerid]][pDBetAmount];
	pDuelInfo[playerid][pDMapId] = pDuelInfo[TargetOf[playerid]][pDMapId];
	pDuelInfo[playerid][pDWeapon] = pDuelInfo[TargetOf[playerid]][pDWeapon];
	pDuelInfo[playerid][pDAmmo] = pDuelInfo[TargetOf[playerid]][pDAmmo];
	pDuelInfo[playerid][pDWeapon2] = pDuelInfo[TargetOf[playerid]][pDWeapon2];
	pDuelInfo[playerid][pDAmmo2] = pDuelInfo[TargetOf[playerid]][pDAmmo2];
	pDuelInfo[playerid][pDInMatch] = pDuelInfo[TargetOf[playerid]][pDInMatch] = 1;
	pDuelInfo[playerid][pDRematchOpt] = pDuelInfo[TargetOf[playerid]][pDRematchOpt];
	pDuelInfo[playerid][pDMatchesPlayed] = pDuelInfo[TargetOf[playerid]][pDMatchesPlayed] = 0;
	pDuelInfo[playerid][pDRCDuel] = pDuelInfo[TargetOf[playerid]][pDRCDuel];

	if (pDuelInfo[playerid][pDBetAmount] > PlayerInfo[playerid][pHighestBet]) {
		PlayerInfo[playerid][pHighestBet] = pDuelInfo[playerid][pDBetAmount];
	}

	if (pDuelInfo[TargetOf[playerid]][pDBetAmount] > PlayerInfo[TargetOf[playerid]][pHighestBet]) {
		PlayerInfo[TargetOf[playerid]][pHighestBet] = pDuelInfo[TargetOf[playerid]][pDBetAmount];
	}

	PlayerInfo[playerid][pDuelsAccepted] ++;

	PlayReadySound(playerid);
	PlayReadySound(TargetOf[playerid]);

	KillTimer(DelayerTimer[playerid]);
	DelayerTimer[playerid] = SetTimerEx("InitPlayer", 3000, false, "i", playerid);
	TogglePlayerControllable(playerid, false);

	KillTimer(DelayerTimer[TargetOf[playerid]]);
	DelayerTimer[TargetOf[playerid]] = SetTimerEx("InitPlayer", 3000, false, "i", TargetOf[playerid]);
	TogglePlayerControllable(TargetOf[playerid], false);

	switch (pDuelInfo[playerid][pDMapId]) {
		case 0: {
			SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 0, 1358.6832,2185.3911,11.0156,147.3334);
			SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 0, 1317.3516,2120.9395,11.0156,327.8713);
		}
		case 1: {
			SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 10, -1018.2189,1056.7441,1342.9358,53.6926);
			SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 10, -1053.4242,1087.2908,1343.0204,230.7042);
		}
		case 2: {
			SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 3, 298.0534,176.0552,1007.1719,91.2696);
			SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 3, 238.5584,178.5376,1003.0300,267.9679);
		}
		case 3: {
			SetPlayerPosition(playerid, "", playerid + DUEL_WORLD, 3, 4888.9790,149.8565,15.1086);
			SetPlayerPosition(TargetOf[playerid], "", playerid + DUEL_WORLD, 3, 4858.3604,132.1908,15.0253);
		}
	}

	new string[128];
	format(string, sizeof(string), "Match ~r~%s ~w~vs ~r~%s ~w~for ~g~%s", PlayerInfo[playerid][PlayerName], PlayerInfo[TargetOf[playerid]][PlayerName], formatInt(pDuelInfo[playerid][pDBetAmount]));
	SendWarUpdate(string);
	LogActivity(playerid, "Duel against #%d with %d, %d for %s (%d|%d)", gettime(), PlayerInfo[TargetOf[playerid]][pAccountId], pDuelInfo[playerid][pDWeapon],  pDuelInfo[playerid][pDWeapon2],
		formatInt(pDuelInfo[playerid][pDBetAmount]), pDuelInfo[playerid][pDRematchOpt], pDuelInfo[playerid][pDRCDuel]);
	LogActivity(TargetOf[playerid], "Duel against #%d with %d, %d for %s (%d|%d)", gettime(), PlayerInfo[playerid][pAccountId], pDuelInfo[playerid][pDWeapon],  pDuelInfo[playerid][pDWeapon2],
		formatInt(pDuelInfo[playerid][pDBetAmount]), pDuelInfo[playerid][pDRematchOpt], pDuelInfo[playerid][pDRCDuel]);
	return 1;
}

CMD:refuseduel(playerid) {
	if (gettime() > pDuelInfo[playerid][pDInvitePeriod]) {
		return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_490x);
	}

	if (TargetOf[playerid] != INVALID_PLAYER_ID) {
		SendGameMessage(TargetOf[playerid], X11_SERV_INFO, MSG_CLIENT_494x);
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_493x);
		pDuelInfo[TargetOf[playerid]][pDInMatch] = 0;
		pDuelInfo[TargetOf[playerid]][pDLocked] = 0;
		TargetOf[TargetOf[playerid]] = INVALID_PLAYER_ID;
		pDuelInfo[playerid][pDInMatch] = 0;
		pDuelInfo[playerid][pDLocked] = 0;
		PlayerInfo[TargetOf[playerid]][pDuelsRefusedByOthers] ++;
		TargetOf[playerid] = INVALID_PLAYER_ID;
		PlayerInfo[playerid][pDuelsRefusedByPlayer] ++;
	}
	return 1;
}

//Other

CMD:votekick(playerid, params[]) {
	if (!PlayerInfo[playerid][pLoggedIn]) return 0;

	new targetid;
	if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/votekick [playerid/name]");
	if (!pVerified[targetid] || targetid == INVALID_PLAYER_ID ||
			targetid == playerid) return 0;

	if (pVotesKick[playerid] > 3) return 0;
	if (pVotedKick[playerid][targetid] == true || ComparePrivileges(targetid, CMD_MEMBER)) return 0;
	if (pVoteKickCD[playerid] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_VOTE_CD);

	pVotedKick[playerid][targetid] = true;
	pVotesKick[targetid] ++;

	SendGameMessage(playerid, X11_SERV_INFO, MSG_VOTED_KICK, PlayerInfo[targetid][PlayerName]);

	pVoteKickCD[playerid] = gettime() + 60;
	return 1;
}

/*CMD:testvk(playerid) {
	pVotesKick[playerid] ++;
	return 1;
}*/

/*
	ADMIN MODULE - EXPORTED CODE
*/

//General commands

flags:miniguns(CMD_MEMBER)
CMD:miniguns(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new bool:First2 = false, carty, String[140], slot, weap, ammo;

		foreach (new i: Player) {
			for (slot = 0; slot < 13; slot++) {
				GetPlayerWeaponData(i, slot, weap, ammo);

				if (ammo != 0 && weap == 38) {
					carty++;

					if (!First2) {
						format(String, sizeof(String), "Minigun: [%d]%s Ammo - %d", i, PlayerInfo[i][PlayerName], ammo);
						First2 = true;
					} else {
						format(String, sizeof(String), "%s, [%d]%s Ammo - %d", String, i, PlayerInfo[i][PlayerName], ammo);
					}
				}
			}
		}

		if (carty == 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_418x);
		SendClientMessage(playerid, 0xFFFFFFFF, String);
	}
	return 1;
}

flags:hseeks(CMD_MEMBER)
CMD:hseeks(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new bool:First2 = false, carty, String[140], slot, weap, ammo;

		foreach (new i: Player) {
			for (slot = 0; slot < 13; slot++) {
				GetPlayerWeaponData(i, slot, weap, ammo);
				if (ammo != 0 && weap == 36) {
					carty++;
					if (!First2) {
						format(String, sizeof(String), "Heat Seeker: [%d]%s Ammo - %d", i, PlayerInfo[i][PlayerName], ammo);
						First2 = true;
					}
					else
					{
						format(String, sizeof(String), "%s, [%d]%s Ammo - %d", String, i, PlayerInfo[i][PlayerName], ammo);
					}
				}
			}
		}

		if (carty == 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_419x);
		SendClientMessage(playerid, 0xFFFFFFFF, String);
	}
	return 1;
}

flags:spec(CMD_MEMBER)
CMD:spec(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new specplayerid;
		if (sscanf(params, "u", specplayerid)) return ShowSyntax(playerid, "/spec [playerid/name]");
		if (!pVerified[specplayerid] || specplayerid == INVALID_PLAYER_ID) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
		if (specplayerid == playerid || (GetPlayerState(specplayerid) == PLAYER_STATE_SPECTATING && PlayerInfo[specplayerid][pSpecId] != INVALID_PLAYER_ID) ||
			(GetPlayerState(specplayerid) != 1 && GetPlayerState(specplayerid) != 2 && GetPlayerState(specplayerid) != 3)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

		if (!ForceSync[playerid]) {
			StoreData(playerid);
		}
		StartSpectate(playerid, specplayerid);
	}
	return 1;
}

flags:specoff(CMD_MEMBER)
CMD:specoff(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (PlayerInfo[playerid][pSpecMode] != ADMIN_SPEC_TYPE_NONE) {
			wasspectating[playerid] = true;
			StopSpectate(playerid);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
	}
	return 1;
}

flags:specs(CMD_MEMBER)
CMD:specs(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new sub_holder[120], string[800], count = 0;

		strcat(string, "Spectator\n");

		foreach (new i: Player) {
			if (GetPlayerState(i) == PLAYER_STATE_SPECTATING) {
				if (ComparePrivileges(playerid, CMD_MEMBER) && pVerified[PlayerInfo[i][pSpecId]]) {
					format(sub_holder, sizeof(sub_holder), "%s is watching %s (/spec)\n", PlayerInfo[i][PlayerName], PlayerInfo[PlayerInfo[i][pSpecId]][PlayerName]);
				} else {
					format(sub_holder, sizeof(sub_holder), "%s is watching unknown\n", PlayerInfo[i][PlayerName]);
				}
				strcat(string, sub_holder);
				count = 1;
			}
		}

		if (count) {
			Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Spectators", string, "X", "");
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_421x);
	}
	return 1;
}

flags:reports(CMD_MEMBER)
CMD:reports(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new dialog[1000], count = 0;
		dialog[0] = EOS;

		format(dialog, sizeof(dialog), "Status\tReported\tReporter\n");

		for (new i = 0; i < MAX_REPORTS; i++) {
			if (ReportInfo[i][R_VALID]) {
				if (ReportInfo[i][R_READ] == 1) {
					format(dialog, sizeof (dialog), "%s{0099FF}Checked\t{AC3069}%s\t%s\t%s\n", dialog, ReportInfo[i][R_AGAINST_NAME], ReportInfo[i][R_FROM_NAME]);
				}
				else {
					format(dialog, sizeof (dialog), "%s{FF0000}Unchecked\t{AC3069}%s\t%s\t%s\n", dialog, ReportInfo[i][R_AGAINST_NAME], ReportInfo[i][R_FROM_NAME]);
				}

				count ++;
			}
		}

		if (count == 0) return SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);

		inline ReportStatus(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			if (response) {
				if (!strcmp(inputtext, "erase", true)) {
					if (ReportInfo[GetPVarInt(pid, "DialogListitem")][R_VALID] == false) return DeletePVar(pid, "DialogListitem");
					ReportInfo[GetPVarInt(pid, "DialogListitem")][R_VALID] = false;
					DeletePVar(pid, "DialogListitem");
					return 1;
				}

				if (!strcmp(inputtext, "panel", true)) {
					if (pVerified[ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]] && ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID] != INVALID_PLAYER_ID) {
						if (ComparePrivileges(pid, CMD_MEMBER)) {
							pClickedID[pid] = ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID];
							AdminPanel(pid, ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]);
							return 1;
						}
					}
				}

				if (!strcmp(inputtext, "kick", true)) {
					if (pVerified[ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]] && ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID] != INVALID_PLAYER_ID) {

						SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_41x, PlayerInfo[ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]][PlayerName], ReportInfo[GetPVarInt(pid, "DialogListitem")][R_REASON]);
						SetTimerEx("DelayKick", 500, false, "i", ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]);

						new query[MEDIUM_STRING_LEN];

						mysql_format(Database, query, sizeof(query), "INSERT INTO `Punishments` (PunishedPlayer, Punisher, Action, ActionReason, PunishmentTime, ActionDate) \
							VALUES ('%e', '%e', 'Kick', '%e', '', '%d')", PlayerInfo[ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]][PlayerName],
							PlayerInfo[pid][PlayerName], ReportInfo[GetPVarInt(pid, "DialogListitem")][R_REASON], gettime());
						mysql_tquery(Database, query);

						DeletePVar(pid, "DialogListitem");
						return 1;
					}
				}

				if (!strcmp(inputtext, "ban", true)) {
					if (pVerified[ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]] && ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID] != INVALID_PLAYER_ID) {
						new params[100];
						format(params, sizeof(params), "/ban %d %s", ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID], ReportInfo[GetPVarInt(pid, "DialogListitem")][R_REASON]);
						DeletePVar(pid, "DialogListitem");
						PC_EmulateCommand(pid, params);
						return 1;
					}
				}

				if (!strcmp(inputtext, "spec", true)) {
					if (pVerified[ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID]] && ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID] != INVALID_PLAYER_ID) {
						if (ReportInfo[GetPVarInt(pid, "DialogListitem")][R_CHECKED] == true) {
							ReportInfo[GetPVarInt(pid, "DialogListitem")][R_CHECKED] = false;

							PlayerReportChecked[pid][GetPVarInt(pid, "DialogListitem")] = true;
							ReportInfo[GetPVarInt(pid, "DialogListitem")][R_READ] = 1;
						}

						new specpid = ReportInfo[GetPVarInt(pid, "DialogListitem")][R_AGAINST_ID];

						if (!pVerified[specpid] || specpid == INVALID_PLAYER_ID)  return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_320x);

						if (specpid == pid) return SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_193x);

						if (GetPlayerState(specpid) == PLAYER_STATE_SPECTATING && PlayerInfo[specpid][pSpecId] != INVALID_PLAYER_ID) return SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
						if (GetPlayerState(specpid) != 1 && GetPlayerState(specpid) != 2 && GetPlayerState(specpid) != 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_NEWCLIENT_194x);

						StartSpectate(pid, specpid);
						DeletePVar(pid, "DialogListitem");
						return 1;
					}
				}

				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
				DeletePVar(pid, "DialogListitem");
				PC_EmulateCommand(pid, "/reports");
			}
		}

		inline ReportsList(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (response) {
				new string[500];

				format(string, sizeof (string), ""DEEPSKYBLUE"Issued{E8E8E8} %s\n\n"DEEPSKYBLUE"Complainer:{E8E8E8} %s[%d]\n"DEEPSKYBLUE"Target:{E8E8E8} %s[%d]\n\n"DEEPSKYBLUE"Reason:{E8E8E8} %s\n\n{AACC99}Actions: erase, spec, kick, ban, panel",
					GetWhen(ReportInfo[listitem][R_TIMESTAMP], gettime()), ReportInfo[listitem][R_FROM_NAME], ReportInfo[listitem][R_FROM_ID], ReportInfo[listitem][R_AGAINST_NAME], ReportInfo[listitem][R_AGAINST_ID], ReportInfo[listitem][R_REASON], ReportInfo[listitem][R_AGAINST_NAME], ReportInfo[listitem][R_AGAINST_NAME], ReportInfo[listitem][R_AGAINST_NAME], ReportInfo[listitem][R_AGAINST_NAME]);

				Dialog_ShowCallback(pid, using inline ReportStatus, DIALOG_STYLE_INPUT, "Report Status", string, "Proceed", "<<");
				SetPVarInt(pid, "DialogListitem", listitem);
			}
		}

		Dialog_ShowCallback(playerid, using inline ReportsList, DIALOG_STYLE_TABLIST_HEADERS, "Reports", dialog, ">>", "X");

	}
	return 1;
}

flags:offlineban(CMD_MEMBER)
CMD:offlineban(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new
			nickname[MAX_PLAYER_NAME], days, reason[25];
		if (sscanf(params, "s[24]ds[25]", nickname, days, reason)) return ShowSyntax(playerid, "/offlineban [name] [days] [reason]");

		new
			query[450];

		mysql_format(Database, query, sizeof(query), "SELECT * FROM `Players` WHERE `Username` LIKE '%e' LIMIT 1", nickname);
		mysql_tquery(Database, query, "OfflineBan", "dsds", playerid, nickname, days, reason);
	}
	return 1;
}

flags:unban(CMD_MEMBER)
CMD:unban(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new
			nickname[MAX_PLAYER_NAME];
		if (sscanf(params, "s[24]", nickname)) return ShowSyntax(playerid, "/unban [nickname]");

		new
			query[450];

		mysql_format(Database, query, sizeof(query), "SELECT * FROM `BansData` WHERE `BannedName` = '%e' LIMIT 1", nickname);
		mysql_tquery(Database, query, "UnbanPlayer", "ds", playerid, nickname);
	}
	return 1;
}

flags:ban(CMD_MEMBER)
CMD:ban(playerid, params[]) {
	if (PlayerInfo[playerid][pLoggedIn]) {
		if (ComparePrivileges(playerid, CMD_MEMBER)) {
			new targetid, reason[25], playername[MAX_PLAYER_NAME], String[140],
			query[300], days, converttime;

			if (sscanf(params, "uis", targetid, days, reason)) {
				ShowSyntax(playerid, "/ban [playerid/name] [days] [reason]");
				return 1;
			}

			if (isnull(reason)) return ShowSyntax(playerid, "Reason is insufficinet to carry out this action.");
			if (days > 30 || (days < 1 && days != -1)) return ShowSyntax(playerid, "Days have to range be either 1-30 for a timed ban or -1 for a permanent ban.");

			if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && targetid != playerid) {
				if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
					return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

				if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

				GetPlayerName(targetid, playername, sizeof(playername));

				new year, month, day, hour, minute, second;

				getdate(year, month, day);
				gettime(hour, minute, second);

				if (days != -1)
					converttime = gettime() + (86400 * days);
				else
					converttime = -1;

				mysql_format(Database, query, sizeof(query), "INSERT INTO `BansData` (`BannedName`, `AdminName`, `BanReason`, `ExpiryDate`, `BanDate`) VALUES ('%e', '%e', '%e', '%d', NOW())", PlayerInfo[targetid][PlayerName], PlayerInfo[playerid][PlayerName], reason, converttime);
				mysql_tquery(Database, query);

				mysql_format(Database, query, sizeof(query), "INSERT INTO `BansHistoryData` (`BannedName`, `AdminName`, `BanReason`, `ExpiryDate`, `BanDate`) VALUES ('%e', '%e', '%e', '%d', NOW())", PlayerInfo[targetid][PlayerName], PlayerInfo[playerid][PlayerName], reason, converttime);
				mysql_tquery(Database, query);

				new fullString[500];

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_43x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], playername, reason);

				new pgpci[41];
				gpci(targetid, pgpci, sizeof(pgpci));
				if (pVerified[targetid]) {
					mysql_format(Database, query, sizeof query, "UPDATE `Players` SET IsBanned = '1', GPCI = '%e', IP = '%e' WHERE `Username` = '%e' LIMIT 1", pgpci, PlayerInfo[targetid][pIP], playername);
					mysql_tquery(Database, query);
				}

				format(String, sizeof(String), ""RED2"Your name: "IVORY"%s\n", PlayerInfo[targetid][PlayerName]);
				strcat(fullString, String);

				format(String, sizeof(String), ""RED2"Banning Administrator: "IVORY"%s\n", PlayerInfo[playerid][PlayerName]);
				strcat(fullString, String);

				if (days != -1) {
					format(String, sizeof(String), ""RED2"Duration: "IVORY"%d days\n", days);
					strcat(fullString, String);
				} else {
					strcat(fullString, ""RED2"Duration: "IVORY"Not Expiring\n");
				}

				format(String, sizeof(String), ""RED2"Ban Reason: "IVORY"%s\n", reason);
				strcat(fullString, String);

				format(String, sizeof(String), ""RED2"Date and Time: "IVORY"%d/%d/%d %d:%d:%d\n\n", day, month, year, hour, minute, second);
				strcat(fullString, String);

				strcat(fullString, ""LIGHTBLUE"Website: "IVORY"https://h2omultiplayer.com/");
				Dialog_Show(targetid, DIALOG_STYLE_MSGBOX, ""RED2"You are banned!", fullString, "X", "");

				foreach(new i: Player) {
					if (pVerified[i]) {
						for (new x = 0; x < sizeof(ReportInfo); x++) {
							if (i != targetid && i == ReportInfo[x][R_FROM_ID] && targetid == ReportInfo[x][R_AGAINST_ID]) {
								SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_424x);
								GivePlayerScore(i, 2);
								break;
							}
						}
					}
				}
				PlayerInfo[targetid][pBannedTimes] ++;
				SetTimerEx("ApplyBan", 500, false, "i", targetid);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);
		}
	}
	return 1;
}

flags:warn(CMD_MEMBER)
CMD:warn(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new warned, reason[25];

		if (sscanf(params, "us[25]", warned, reason)) return ShowSyntax(playerid, "/warn [playerid/name] [Reason]");
		if (pVerified[warned] && warned != INVALID_PLAYER_ID) {
			if (ComparePrivileges(warned, CMD_OWNER))
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			if (CheckPrivileges(warned, playerid) && warned != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

			if (warned != playerid) {
				if (Anti_Warn[warned] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_195x);
				PlayerInfo[warned][pTempWarnings]++;

				new query[MEDIUM_STRING_LEN];
				mysql_format(Database, query, sizeof(query), "INSERT INTO `Punishments` (PunishedPlayer, Punisher, Action, ActionReason, PunishmentTime, ActionDate) \
					VALUES ('%e', '%e', 'Warn', '%s', '', '%d')", PlayerInfo[warned][PlayerName], PlayerInfo[playerid][PlayerName], reason, gettime());
				mysql_tquery(Database, query);

				if ( PlayerInfo[warned][pTempWarnings] == svtconf[max_warns]) {
					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_44x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[warned][PlayerName],  PlayerInfo[warned][pTempWarnings], svtconf[max_warns], reason);
					Kick(warned);
					PlayerInfo[warned][pTempWarnings] = 0;
				} else {
					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_45x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[warned][PlayerName], PlayerInfo[warned][pTempWarnings], svtconf[max_warns],reason);
					Anti_Warn[warned] = 1;
				}

				new warn_info[300];
				format(warn_info, sizeof(warn_info), "{0099FF}Reason:{E8E8E8} %s\n\
					{0099FF}Admin:{E8E8E8} %s\n\
					{0099FF}Warning:{E8E8E8} %d/%d\n\nPlease be nice next time.", reason, PlayerInfo[playerid][PlayerName], PlayerInfo[warned][pTempWarnings], svtconf[max_warns]);
				Dialog_Show(warned, DIALOG_STYLE_MSGBOX, "You are warned", warn_info, "X", "");

				Anti_Warn[warned] = gettime() + 5;
				PlayerInfo[warned][pAccountWarnings] ++;
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:removewarnings(CMD_MEMBER)
CMD:removewarnings(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new warned;
		if (sscanf(params, "u", warned)) return ShowSyntax(playerid, "/removewarnings [playerid/name]");
		if (pVerified[warned] && warned != INVALID_PLAYER_ID) {
			if (CheckPrivileges(warned, playerid) && warned != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);
			if (warned != playerid) {
				if (PlayerInfo[warned][pTempWarnings] > 0) {
					PlayerInfo[warned][pTempWarnings] = 0;

					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_48x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[warned][PlayerName]);
				}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_196x);
			}
		}
	}
	return 1;
}

flags:kick(CMD_MEMBER)
CMD:kick(playerid, params[]) {
	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if (ComparePrivileges(playerid, CMD_MEMBER)) {
			new targetid, reason[25];

			if (sscanf(params, "us[25]", targetid, reason)) return ShowSyntax(playerid, "/kick [playerid/name] [reason]");

			if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && targetid != playerid) {
				if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
					return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

				if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

				if (ComparePrivileges(playerid, CMD_MEMBER)) {
					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_49x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName], reason);
				} else {
					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_50x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName], reason);
				}

				new query[MEDIUM_STRING_LEN];

				mysql_format(Database, query, sizeof(query), "INSERT INTO `Punishments` (PunishedPlayer, Punisher, Action, ActionReason, PunishmentTime, ActionDate) \
					VALUES ('%e', '%e', 'Kick', '%s', '', '%d')", PlayerInfo[targetid][PlayerName], PlayerInfo[playerid][PlayerName], reason, gettime());
				mysql_tquery(Database, query);

				PlayerInfo[targetid][pKicksByAdmin] ++;

				foreach(new i: Player) {
					if (pVerified[i]) {
						for (new x = 0; x < sizeof(ReportInfo); x++) {
							if (i != targetid && i == ReportInfo[x][R_FROM_ID] && targetid == ReportInfo[x][R_AGAINST_ID]) {
								SendGameMessage(i, X11_SERV_INFO, MSG_CLIENT_424x);
								GivePlayerScore(i, 2);
								break;
							}
						}
					}
				}
				SetTimerEx("DelayKick", 500, false, "i", targetid);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);
		}
	}
	return 1;
}

flags:slap(CMD_MEMBER)
CMD:slap(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/slap [playerid/name]");
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
			if (!IsPlayerInAnyVehicle(targetid)) {
				new Float:x, Float:y, Float:z;
				GetPlayerPos(targetid, x, y, z);
				SetPlayerPos(targetid, x, y, z + 16);
			} else {
				new Float:x, Float:y, Float:z;
				GetVehiclePos(GetPlayerVehicleID(targetid), x, y, z);
				SetVehiclePos(GetPlayerVehicleID(targetid), x, y, z + 16);
			}
			PlayerPlaySound(playerid, 1190, 0.0, 0.0, 0.0);
			PlayerPlaySound(targetid, 1130, 0.0, 0.0, 0.0);
			SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s slapped %s.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName]);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:explode(CMD_MEMBER)
CMD:explode(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/explode [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			new Float:burnx, Float:burny, Float:burnz;
			GetPlayerPos(targetid,burnx, burny, burnz);
			CreateExplosion(burnx, burny, burnz, 7, 10.0);
			SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s exploded %s.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName]);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:jail(CMD_MEMBER)
CMD:jail(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, playername[MAX_PLAYER_NAME], adminname[MAX_PLAYER_NAME], reason[25], jtime;
		if (sscanf(params, "uis[25]", targetid, jtime, reason)) return ShowSyntax(playerid, "/jail [playerid/name] [minutes] [reason]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

			if (PlayerInfo[targetid][pJailed] == 0) {

				GetPlayerName(targetid, playername, sizeof(playername));
				GetPlayerName(playerid, adminname, sizeof(adminname));

				if (jtime == 0) jtime = 5;

				PlayerInfo[targetid][pJailTime] = (jtime * 60) + gettime();

				ResetPlayerWeapons(targetid);

				JailPlayer(targetid);
				PlayerInfo[targetid][pJailed] = 1;

				new query[MEDIUM_STRING_LEN];
				mysql_format(Database, query, sizeof(query), "INSERT INTO `Punishments` (PunishedPlayer, Punisher, Action, ActionReason, PunishmentTime, ActionDate) \
					VALUES ('%e', '%e', 'Jail', '%s', '%d Minutes', '%d')", PlayerInfo[targetid][PlayerName], PlayerInfo[playerid][PlayerName], reason, jtime, gettime());
				mysql_tquery(Database, query);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_51x, _Get_Role(playerid), adminname, playername, jtime, reason);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_197x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:unjail(CMD_MEMBER)
CMD:unjail(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/unjail [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID)
		 {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

			if (PlayerInfo[targetid][pJailed] == 1) {
				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_52x, PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName]);

				JailRelease(targetid);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_196x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:jailed(CMD_MEMBER)
CMD:jailed(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new bool:First2 = false, cout, adminname[MAX_PLAYER_NAME], String[140];

		foreach (new i: Player)
			if (pVerified[i] && PlayerInfo[i][pJailed])
				 cout++;

		if (cout == 0) return SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);

		foreach (new i: Player) {
			if (pVerified[i] && PlayerInfo[i][pJailed]) {
				GetPlayerName(i, adminname, sizeof(adminname));

				if (!First2) {
					format(String, sizeof(String), "Jailed Players: (%d)%s", i, adminname);
					First2 = true;
				} else format(String, sizeof(String), "%s, (%d)%s ", String, i, adminname);

			}
		}

		SendClientMessage(playerid, 0xFFFFFFFF, String);
	}
	return 1;
}

flags:freeze(CMD_MEMBER)
CMD:freeze(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, reason[25], ftime;
		if (sscanf(params, "uis[25]", targetid, ftime, reason)) return ShowSyntax(playerid, "/freeze [playerid/name] [minutes] [reason]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

			if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

			if (PlayerInfo[targetid][pFrozen] == 0) {
				if (ftime == 0) ftime = 5;

				TogglePlayerControllable(targetid, false);

				PlayerInfo[targetid][pFrozen] = 1;
				PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);

				PlayerInfo[targetid][pFreezeTime] = ftime * 1000 * 60;
				FreezeTimer[targetid] = SetTimerEx("Unfreeze", PlayerInfo[targetid][pFreezeTime], 0, "d", targetid);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_53x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName], ftime, reason);

				new query[MEDIUM_STRING_LEN];

				mysql_format(Database, query, sizeof(query), "INSERT INTO `Punishments` (PunishedPlayer, Punisher, Action, ActionReason, PunishmentTime, ActionDate) \
					VALUES ('%e', '%e', 'Freeze', '%s', '%d Minutes', '%d')", PlayerInfo[targetid][PlayerName], PlayerInfo[playerid][PlayerName], reason, ftime, gettime());
				mysql_tquery(Database, query);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_197x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:unfreeze(CMD_MEMBER)
CMD:unfreeze(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/unfreeze [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

			if (PlayerInfo[targetid][pFrozen] == 1) {
				Unfreeze(targetid);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_54x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName]);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_196x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:frozen(CMD_MEMBER)
CMD:frozen(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new bool:First2 = false, cot, adminname[MAX_PLAYER_NAME], String[140];

		foreach (new i: Player) if (PlayerInfo[i][pFrozen]) cot++;
		if (cot == 0) return SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);

		foreach (new i: Player) if (PlayerInfo[i][pFrozen]) {
			GetPlayerName(i, adminname, sizeof(adminname));

			if (!First2) {
				format(String, sizeof(String), "Frozen Players: (%d)%s", i, adminname);
				First2 = true;
			}
			else format(String, sizeof(String), "%s, (%d)%s ", String,i,adminname);
		}
		return SendClientMessage(playerid, 0xFFFFFFFF, String);
	}
	return 1;
}

flags:mute(CMD_MEMBER)
CMD:mute(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, reason[25];
		if (sscanf(params, "us[25]", targetid, reason)) return ShowSyntax(playerid, "/mute [playerid/name] [reason]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

			if (!PlayerInfo[targetid][pMuted]) {
				PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);

				PlayerInfo[targetid][pMuted] = 1;

				new query[MEDIUM_STRING_LEN];

				mysql_format(Database, query, sizeof(query), "INSERT INTO `Punishments` (PunishedPlayer, Punisher, Action, ActionReason, PunishmentTime, ActionDate) \
					VALUES ('%e', '%e', 'Mute', '%s', '', '%d')", PlayerInfo[targetid][PlayerName], PlayerInfo[playerid][PlayerName], reason, gettime());
				mysql_tquery(Database, query);

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_55x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName]);
			} else return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_197x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:unmute(CMD_MEMBER)
CMD:unmute(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/unmute [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			if (CheckPrivileges(targetid, playerid) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_321x);

			if (PlayerInfo[targetid][pMuted] == 1) {
				PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
				PlayerInfo[targetid][pMuted] = 0;

				SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_56x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName]);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_196x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:muted(CMD_MEMBER)
CMD:muted(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new bool:First2 = false, cart, adminname[MAX_PLAYER_NAME], String[140];
		foreach (new i: Player) if (PlayerInfo[i][pMuted]) cart++;
		if (cart == 0) return SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);

		foreach (new i: Player) if (PlayerInfo[i][pMuted]) {
			GetPlayerName(i, adminname, sizeof(adminname));

			if (!First2) {
				format(String, sizeof(String), "Muted Players: (%d)%s", i, adminname);
				First2 = true;
			}
			else format(String, sizeof(String), "%s, (%d)%s ", String, i, adminname);
		}

		SendClientMessage(playerid, 0xFFFFFFFF, String);
	}
	return 1;
}

flags:items(CMD_MEMBER)
CMD:items(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, String[SMALL_STRING_LEN];
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/items [playerid/name]");

		new items;
		format(String, sizeof(String), "%s[%d]'s Items:", PlayerInfo[targetid][PlayerName], targetid);
		SendClientMessage(playerid, 0x2281C8FF, String);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			for (new i = 0; i < MAX_ITEMS; i++) {
				if (Items_GetPlayer(targetid, i)) {
					items ++;
					format(String, sizeof(String), "-%s <%d>", Items_GetName(i), Items_GetPlayer(targetid, i));
					SendClientMessage(playerid, 0x2281C8FF, String);
				}
			}
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:breset(CMD_MEMBER)
CMD:breset(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/bstats [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			new reset_bullet_stats[BulletData];
			BulletStats[targetid] = reset_bullet_stats;
		}
	}
	return 1;
}

flags:bstats(CMD_MEMBER)
CMD:bstats(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, String[910];
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/bstats [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (BulletStats[targetid][Bullet_Vectors][0] == 0.0 && BulletStats[targetid][Bullet_Vectors][1] == 0.0 && BulletStats[targetid][Bullet_Vectors][2] == 0.0) {
				SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
				return 1;
			}

			new Float: HMR = floatdiv(BulletStats[targetid][Bullets_Hit], BulletStats[targetid][Bullets_Miss]);
			new Float: Avg = floatdiv(BulletStats[targetid][Bullets_Hit] + BulletStats[targetid][Bullets_Miss], 2);
			new Float: Dist = floatdiv(BulletStats[targetid][Longest_Hit_Distance] + BulletStats[targetid][Shortest_Hit_Distance], 2);
			new WeaponName[32];
			GetWeaponName(BulletStats[targetid][Longest_Distance_Weapon], WeaponName, sizeof(WeaponName));

			new WeaponName2[32];
			GetWeaponName(GetPlayerWeapon(targetid), WeaponName2, sizeof(WeaponName2));
			format(String, sizeof(String), ""DARKBLUE"Viewing %s[%d]'s bullet statistics:\n\n\
			{E8E8E8}Bullets hit by player: %d\n\
			Bullets missed by player: %d\n\
			Bullets hit/miss acuracy: %0.2f\n\
			Avg bullet hit/miss: %0.1f\n\
			Seconds since last shot: %0.1f\n\
			Interval between shots: %0.1f\n\
			Bullets hit in a row: %d\n\
			Bullets missed in a row: %d\n\
			Seconds since last hit: %0.1f\n\
			Longest hit distance: %0.2f\n\
			Shortest hit distance: %0.2f\n\
			Last hit distance: %0.2f\n\
			Avg hit distance: %0.2f\n",
			PlayerInfo[targetid][PlayerName], targetid, BulletStats[targetid][Bullets_Hit], BulletStats[targetid][Bullets_Miss], HMR, Avg, floatdiv(GetTickCount() - BulletStats[targetid][Last_Shot_MS], 1000), floatdiv(BulletStats[targetid][MS_Between_Shots], 1000),
			BulletStats[targetid][Group_Hits], BulletStats[targetid][Group_Misses], BulletStats[targetid][Last_Hit_MS], BulletStats[targetid][Longest_Hit_Distance], BulletStats[targetid][Shortest_Hit_Distance],
			BulletStats[targetid][Last_Hit_Distance], Dist);
			format(String, sizeof(String), "%sHits per one miss: %d\n\
			Misses per one hit: %d\n\
			Longest distance weapon: %s[%d]\n\
			Current weapon: %s[%d]\n\
			Shots hit without aiming: %d\n\
			Last shot vectors: %0.2f, %0.2f, %0.2f\n\
			Highest hit record without a miss: %d\n\
			Highest miss record without a hit: %d\n\n", String, BulletStats[targetid][Hits_Per_Miss], BulletStats[targetid][Misses_Per_Hit], WeaponName,
			BulletStats[targetid][Longest_Distance_Weapon], WeaponName2, GetPlayerWeapon(targetid),
			BulletStats[targetid][Hits_Without_Aiming],
			BulletStats[targetid][Bullet_Vectors][0], BulletStats[targetid][Bullet_Vectors][1], BulletStats[targetid][Bullet_Vectors][2],
			BulletStats[targetid][Highest_Hits], BulletStats[targetid][Highest_Misses]);
			format(String, sizeof(String), "%s"DARKBLUE"Network statistics:\n\n\
			{E8E8E8}Packet loss percent: %0.2f\n\
			Player is lagging? %s\n\
			Player ping: %d", String, NetStats_PacketLossPercent(targetid), (NetStats_PacketLossPercent(targetid) > 1.0) ? ("Yes") : ("No"),
			GetPlayerPing(targetid));
			Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Bullet/Network Stats", String, "X", "");
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:weaps(CMD_MEMBER)
CMD:weaps(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, String[140], WeapName[24], slot, weap, ammo, wh, x;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/weaps [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			format(String, sizeof(String), "%s[%d]'s weapons:", PlayerInfo[targetid][PlayerName], targetid);
			SendClientMessage(playerid, 0x2281C8FF, String);

			format(String, sizeof(String), " ");

			for (slot = 0; slot < 13; slot++) {
				GetPlayerWeaponData(targetid, slot, weap, ammo);

				if (ammo != 0 && weap != 0) {
					wh++;
				}
			}

			if (wh < 1) {
				return SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
			}

			if (wh >= 1) {
				for (slot = 0; slot < 13; slot++) {
					GetPlayerWeaponData(targetid, slot, weap, ammo);

					if ( ammo != 0 && weap != 0) {
						GetWeaponName(weap, WeapName, sizeof(WeapName));
						if (ammo == 65535 || ammo == 1)
						{
							format(String, sizeof(String), "%s%s (1)", String, WeapName);
						} else format(String, sizeof(String), "%s%s (%d)", String, WeapName, ammo );

						x++;

						if (x >= 5)
						{
							SendClientMessage(playerid, 0x2281C8FF, String);
							x = 0;
							format(String, sizeof(String), "");
						} else format(String, sizeof(String), "%s,  ", String);
					}
				}

				if (x <= 4 && x > 0) {
					String[strlen(String)-3] = '.';
					SendClientMessage(playerid, 0x2281C8FF, String);
				}
			}
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:countdown(CMD_MEMBER)
CMD:countdown(playerid, params[]) {
	if (!ComparePrivileges(playerid, CMD_MEMBER)) return 0;

	new cdValue = 0;
	if (sscanf(params, "i", cdValue)) return ShowSyntax(playerid, "/countdown [seconds]");

	counterValue = cdValue;
	counterOn = 1;

	KillTimer(counterTimer);
	counterTimer = SetTimer("StartCount", 1500, true);
	return 1;
}

//Vehicle spawn

flags:sv(CMD_OWNER)
CMD:sv(playerid, params[]) {
  if (ComparePrivileges(playerid, CMD_OWNER)) {
	  new vehID;
	  if (sscanf(params, "i",  vehID)) return ShowSyntax(playerid, "/sv [ID]" );
	  if (vehID == INVALID_VEHICLE_ID) return 0;

	  SetVehicleToRespawn( vehID );
  }
  return 1;
}

flags:dv(CMD_OWNER)
CMD:dv(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_OWNER)) {
		new vehID;
		if (sscanf( params, "i",  vehID)) return ShowSyntax(playerid, "/dv [vehicle id]");
		if (vehID == INVALID_VEHICLE_ID) return ShowSyntax(playerid, "/dv (delete vehicle) [vehicle id]");
		DestroyVehicle(vehID);
	}
	return 1;
}

flags:rac(CMD_MEMBER)
CMD:rac(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		for (new i = 0; i < GetVehiclePoolSize(); i++) {
			if (!IsVehicleUsed(i)) {
				SetVehicleToRespawn(i);
			}
		}
	}
	return 1;
}
alias:rac("respawncars")

//Commands

flags:answer(CMD_MEMBER)
CMD:answer(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new id, input[141];
		if (sscanf(params, "us[140]", id, input)) return ShowSyntax(playerid, "/answer [name/ID] [text]");
		if (!pVerified[id] || id == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
		if (!PlayerInfo[id][pQuestionAsked]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_434x);

		SendGameMessage(id, X11_SERV_INFO, MSG_NEWCLIENT_31x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], playerid, input);

		foreach(new i: Player) {
			if (ComparePrivileges(i, CMD_MEMBER)) {
				SendGameMessage(i, X11_SERV_INFO, MSG_NEWCLIENT_32x, _Get_Role(playerid), PlayerInfo[playerid][PlayerName], playerid, PlayerInfo[id][PlayerName], id, input);
			}
		}

		PlayerInfo[id][pQuestionAsked] = 0;
		PlayerInfo[id][pQuestionsAnswered] ++;
	}
	return 1;
}

flags:giveweapon(CMD_MEMBER)
alias:giveweapon("gw")
CMD:giveweapon(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, weap, weaponname[32], ammoval, ammo, WeapName[32];

		if (sscanf(params, "us[32]i", targetid, weaponname, ammoval)) return ShowSyntax(playerid, "/giveweapon [playerid/name] [weapon ID/weapon name] [ammo]");

		if (ammoval <= 0 || ammoval > 99999) {
			ammo = 500;
		} else ammo = ammoval;

		if (!IsNumeric(weaponname)) weap = GetWeaponIDFromName(weaponname); else weap = strval(weaponname);

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (!IsValidWeapon(weap)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_422x);

			GetWeaponName(weap, WeapName, 32);

			GivePlayerWeapon(targetid, weap, ammo);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:sethealth(CMD_MEMBER)
alias:sethealth("sh")
CMD:sethealth(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, Float: health;

		if (sscanf(params, "uf", targetid, health)) return ShowSyntax(playerid, "/sethealth [playerid/name] [amount]");
		if (health > 100.0) return ShowSyntax(playerid, "/sethealth [player name/id] [health 0-100]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			SetPlayerHealth(targetid, health);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:setarmour(CMD_MEMBER)
CMD:setarmour(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, Float: armour;

		if (sscanf(params, "uf", targetid, armour)) return ShowSyntax(playerid, "/setarmour [playerid/name] [amount]");
		if (armour < 0.0 || armour > 100.0) return ShowSyntax(playerid, "/setarmour [player name/id] [armour 0-100]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			SetPlayerArmour(targetid, armour);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:setskin(CMD_MEMBER)
CMD:setskin(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, amount;

		if (sscanf(params, "ud", targetid, amount)) return ShowSyntax(playerid, "/setskin [playerid/name] [amount]");
		if (IsValidSkin(amount)) return ShowSyntax(playerid, "/setskin [player name/id] [amount]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			SetPlayerSkin(targetid, amount);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:setinterior(CMD_MEMBER)
CMD:setinterior(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, amount;

		if (sscanf(params, "ud", targetid, amount)) return ShowSyntax(playerid, "/setinterior [playerid/name] [amount]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			SetPlayerInterior(targetid, amount);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:setworld(CMD_MEMBER)
CMD:setworld(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, amount;

		if (sscanf(params, "ud", targetid, amount)) return ShowSyntax(playerid, "/setworld [playerid/name] [amount]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			SetPlayerVirtualWorld(targetid, amount);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:setcolor(CMD_MEMBER)
CMD:setcolor(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, amount;

		if (sscanf(params, "ux", targetid, amount)) return ShowSyntax(playerid, "/setcolor [playerid/name] [hex color]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			SetPlayerColor(targetid, amount);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:disablecaps(CMD_MEMBER)
CMD:disablecaps(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;

		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/disablecaps [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
			if (!PlayerInfo[targetid][pCapsDisabled]) {
				PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
				PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
				PlayerInfo[targetid][pCapsDisabled] = 1;
			} else {
				PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
				PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
				PlayerInfo[targetid][pCapsDisabled] = 0;
			}
			SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s changed capslock status for %s.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName], PlayerInfo[targetid][PlayerName]);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:givecar(CMD_MEMBER)
CMD:givecar(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new carid, targetid;
		if (sscanf(params, "ui", targetid, carid)) return ShowSyntax(playerid, "/givecar [playerid/name] [car]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && targetid != playerid) {
			if (IsPlayerInAnyVehicle(targetid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_194x);
			if (carid < 400 || carid > 611) return ShowSyntax(playerid, "/givecar [player name/id] [vehicle id 400-610]");

			new Float:x, Float:y, Float:z;
			GetPlayerPos(targetid, x, y, z);

			CarSpawner(targetid, carid);
			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
			PlayerPlaySound(targetid, 1068, 0.0, 0.0, 0.0);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);
	}
	return 1;
}

flags:eject(CMD_MEMBER)
CMD:eject(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, Float:x, Float:y, Float:z;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/eject [playerid/name]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (IsPlayerInAnyVehicle(targetid)) {
				GetPlayerPos(targetid, x, y, z);
				SetPlayerPos(targetid, x, y, z + 3);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_194x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:spawn(CMD_MEMBER)
CMD:spawn(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/spawn [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && IsPlayerSpawned(targetid)) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			SpawnPlayer(targetid);
			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
	}
	return 1;
}

flags:disarm(CMD_MEMBER)
CMD:disarm(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/disarm [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid)
				return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
			ResetPlayerWeapons(targetid);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:car(CMD_MEMBER)
CMD:car(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new car, Carstr[90];
		if (sscanf(params, "s[90]", Carstr)) return ShowSyntax(playerid, "/car [modelid/name]");
		if (IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
		if (!IsNumeric(Carstr))
		{
		   car = GetVehicleModelIDFromName(Carstr);

		} else car = strval(Carstr);

		if (car < 400 || car > 611) return ShowSyntax(playerid, "/car [vehicle id 400-610/name]");
		if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
		PlayerInfo[playerid][pCar] = -1;

		new LVehicleID, Float:X, Float:Y, Float:Z, Float:Angle, int1;

		GetPlayerPos(playerid, X, Y, Z);
		GetPlayerFacingAngle(playerid, Angle);

		int1 = GetPlayerInterior(playerid);

		LVehicleID = CreateVehicle(car, X + 3, Y, Z + 2, Angle, 0, 7, -1);
		pVehId[playerid] = PlayerInfo[playerid][pCar] = LVehicleID;

		LinkVehicleToInterior(LVehicleID, int1);

		new world;
		world = GetPlayerVirtualWorld(playerid);
		SetVehicleVirtualWorld(LVehicleID, world);

		PutPlayerInVehicle(playerid, PlayerInfo[playerid][pCar], 0);
	}
	return 1;
}

flags:carhealth(CMD_MEMBER)
CMD:carhealth(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, health;

		if (sscanf(params, "ui", targetid, health)) return ShowSyntax(playerid, "/carhealth [playerid/name] [amount]");
		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (IsPlayerInAnyVehicle(targetid)) {
				SetVehicleHealth(GetPlayerVehicleID(targetid), health);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_194x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:carcolor(CMD_MEMBER)
CMD:carcolor(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid, colour1, colour2;

		if (sscanf(params, "uii", targetid, colour1, colour2)) return ShowSyntax(playerid, "/carcolor [playerid/name] [colour1] [colour2]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (IsPlayerInAnyVehicle(targetid)) {
				ChangeVehicleColor(GetPlayerVehicleID(targetid), colour1, colour2);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_194x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);
	}
	return 1;
}

flags:jetpack(CMD_MEMBER)
CMD:jetpack(playerid, params[]) {
	if (isnull(params)) {
		if (ComparePrivileges(playerid, CMD_MEMBER)) {
			SetPlayerSpecialAction(playerid, 2);
		}
	} else {
		new targetid;
		targetid = strval(params);
		if (ComparePrivileges(playerid, CMD_MEMBER)) {
			if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && targetid != playerid) {
				SetPlayerSpecialAction(targetid, 2);
			} else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);
		}
	}
	return 1;
}

flags:aflip(CMD_MEMBER)
CMD:aflip(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (isnull(params)) {
			if (IsPlayerInAnyVehicle(playerid)) {
				new VehicleID, Float:X, Float:Y, Float:Z, Float:Angle;
				GetPlayerPos(playerid, X, Y, Z);
				VehicleID = GetPlayerVehicleID(playerid);
				GetVehicleZAngle(VehicleID, Angle);
				SetVehiclePos(VehicleID, X, Y, Z);
				SetVehicleZAngle(VehicleID, Angle);
				SetVehicleHealth(VehicleID, 1000.0);
				return 1;

			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
		}

		new targetid;
		targetid = strval(params);

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && targetid != playerid) {
			if (IsPlayerInAnyVehicle(targetid)) {
				new VehicleID, Float:X, Float:Y, Float:Z, Float:Angle;
				GetPlayerPos(targetid, X, Y, Z);
				VehicleID = GetPlayerVehicleID(targetid);
				GetVehicleZAngle(VehicleID, Angle);
				SetVehiclePos(VehicleID, X, Y, Z);
				SetVehicleZAngle(VehicleID, Angle);
				SetVehicleHealth(VehicleID, 1000.0);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_194x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);
	}
	return 1;
}

flags:destroycar(CMD_MEMBER)
CMD:destroycar(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
		PlayerInfo[playerid][pCar] = -1;
	}
	return 1;
}

//Alerts

flags:asay(CMD_MEMBER)
CMD:asay(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (isnull(params)) return ShowSyntax(playerid, "/asay [text]");

		new String[140];
		format(String, sizeof(String), "***%s: %s", _Get_Role(playerid), PlayerInfo[playerid][PlayerName], params);
		SendClientMessageToAll(0x6700A6FF, String);
	}
	return 1;
}

flags:ann(CMD_MEMBER)
CMD:ann(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (isnull(params)) return ShowSyntax(playerid, "/announce <text>");
		GameTextForAll(params, 4000, 3);
	}
	return 1;
}

flags:ann2(CMD_MEMBER)
CMD:ann2(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new style, time, text[80];
		if (sscanf(params, "iis[80]", style, time, text)) return ShowSyntax(playerid, "/announce2 <style> <time> <text>");
		if (style > 6 || style < 0 || style == 2) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_422x);
		GameTextForAll(text, time, style);
	}
	return 1;
}

alias:ann("announce")
alias:ann2("announce2")

//Teleport

flags:teleplayer(CMD_MEMBER)
CMD:teleplayer(playerid, params[]) {
	new targetid, player2, Float:plocx, Float:plocy, Float:plocz;

	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (sscanf(params, "uu", targetid, player2)) return ShowSyntax(playerid, "/teleplayer [playerid/name] [targetid/name]");

		if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID) {
			if (pVerified[player2] && player2 != INVALID_PLAYER_ID) {
				GetPlayerPos(player2, plocx, plocy, plocz);

				new intid = GetPlayerInterior(player2);

				SetPlayerInterior(targetid,intid);
				SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(player2));

				if (GetPlayerState(targetid) == PLAYER_STATE_DRIVER) {
					new VehicleID = GetPlayerVehicleID(targetid);
					SetVehiclePos(VehicleID, plocx, plocy + 4, plocz);

					LinkVehicleToInterior(VehicleID, intid);
					SetVehicleVirtualWorld(VehicleID, GetPlayerVirtualWorld(player2));
				} else SetPlayerPos(targetid, plocx, plocy + 2, plocz);
			}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_193x);
	}
	return 1;
}

flags:teles(CMD_MEMBER)
CMD:teles(playerid) {
	if (!ComparePrivileges(playerid, CMD_MEMBER)) return 0;
	inline AdminTeleports(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return 1;
		switch (listitem) {
			case 0: {
				SetPlayerPosition(pid, "Sherman dam", 0, 17,   -959.564392,1848.576782,9.000000);
			}
			case 1: {
				SetPlayerPosition(pid, "Warehouse", 0, 18,     1302.519897,-1.787510,1001.028259);
			}
			case 2: {
				SetPlayerPosition(pid, "SF Police HQ", 0, 10, 246.375991,109.245994,1003.218750);
			}
			case 3: {
				SetPlayerPosition(pid, "LS Police HQ", 0,  6, 246.783996,63.900199,1003.640625);
			}
			case 4: {
				SetPlayerPosition(pid, "Shamal", 0, 1,     1.808619,32.384357,1199.593750);
			}
			case 5: {
				SetPlayerPosition(pid, "Jefferson motel", 0, 15,   2215.454833,-1147.475585,1025.796875);
			}
			case 6: {
				SetPlayerPosition(pid, "Betting shop", 0, 3,   833.269775,10.588416,1004.179687);
			}
			case 7: {
				SetPlayerPosition(pid, "Sex shop", 0, 3,   -103.559165,-24.225606,1000.718750);
			}
			case 8: {
				SetPlayerPosition(pid, "Meat factory", 0, 1,   963.418762,2108.292480,1011.030273);
			}
			case 9: {
				SetPlayerPosition(pid, "RC shop", 0, 6,    -2240.468505,137.060440,1035.414062);
			}
			case 10:  {
				SetPlayerPosition(pid, "Catigula's basement", 0, 1,    2169.461181,1618.798339,999.976562);
			}
			case 11:  {
				SetPlayerPosition(pid, "Woozie's office", 0, 1,    -2159.122802,641.517517,1052.381713);
			}
			case 12:  {
				SetPlayerPosition(pid, "Binco", 0, 15, 207.737991,-109.019996,1005.132812);
			}
			case 13:  {
				SetPlayerPosition(pid, "Jay's diner", 0, 4,    457.304748,-88.428497,999.554687);
			}
			case 14:  {
				SetPlayerPosition(pid, "Burger shot", 0, 10,   375.962463,-65.816848,1001.507812);
			}
			case 15:  {
				SetPlayerPosition(pid, "LS Gym", 0,    5,  772.111999,-3.898649,1000.728820);
			}
			case 16:  {
				SetPlayerPosition(pid, "Sweet's house", 0, 1,  2527.654052,-1679.388305,1015.498596);
			}
			case 17:  {
				SetPlayerPosition(pid, "Crack factory", 0, 2,  2543.462646,-1308.379882,1026.728393);
			}
			case 18:  {
				SetPlayerPosition(pid, "Strip club", 0, 2,     1204.809936,-11.586799,1000.921875);
			}
			case 19: {
				SetPlayerPosition(pid, "Pleasure domes", 0, 3, -2640.762939,1406.682006,906.460937);
			}
			case 20: {
				SetPlayerPosition(pid, "8-Track", 0, 7, -1398.065307,-217.028900,1051.115844);
			}
			case 21: {
				SetPlayerPosition(pid, "Bloodbowl", 0, 15, -1398.103515,937.631164,1036.479125);
			}
			case 22: {
				SetPlayerPosition(pid, "Vice stadium", 0, 1, -1401.829956,107.051300,1032.273437);
			}
			case 23: {
				SetPlayerPosition(pid, "Kickstart", 0, 14, -1465.268676,1557.868286,1052.531250);
			}
			case 24: {
				SetPlayerPosition(pid, "RC Battlefield", 0, 10, -975.975708,1060.983032,1345.671875);
			}
			case 25: {
				SetPlayerPosition(pid, "LS Atruim", 0, 18, 1710.433715,-1669.379272,20.225049);
			}
			case 26: {
				SetPlayerPosition(pid, "LV police HQ", 0, 3, 288.745971,169.350997,1007.171875);
			}
			case 27: {
				SetPlayerPosition(pid, "Planning dept.", 0, 3, 384.808624,173.804992,1008.382812);
			}
			case 28: {
				SetPlayerPosition(pid, "Zombie Island", 0, 3, 1435.9980,-3881.3413,17.0);
			}
			case 29: {
				SetPlayerPosition(pid, "Clanwar Island", 150, 3, 2495.3467,-2839.5181,57.2000,89.0618);
			}
			case 30: {
				SetPlayerPosition(pid, "Madd Doggs", 0, 5, 1267.663208,-781.323242,1091.906250);
			}
			case 31: {
				SetPlayerPosition(pid, "Big Spread Ranch", 0, 3, 1212.019897,-28.663099,1000.953125);
			}
		}
		SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s teleported to an interior.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
	}

	Dialog_ShowCallback(playerid, using inline AdminTeleports, DIALOG_STYLE_LIST, "Teleports",
	"Sherman dam\nWarehouse\n\
	SF Police HQ\nLS Police HQ\nShamal\n\
	Jefferson motel\n\
	Betting shop\nSex shop\nMeat factory\nRC shop\n\
	Catigula's\nWoozie's office\nBinco\nJay's diner\n\
	Burger shot\nLS Gym\nSweet's House\nCrack factory\nStrip club\nPleasure domes\n8-Track\n\
	Bloodbowl\nVice stadium\nKickstart\nRC Battlefield\nLS Atrium\nLV police HQ\nPlanning dept.\n\
	Zombie Island\nClanwar Island\nMadd Doggs\nBig Spread Ranch", "Go", "X");
	return 1;
}

flags:goto(CMD_MEMBER)
CMD:goto(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;

		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/goto [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && targetid != playerid) {
			new Float: x, Float: y, Float: z;
			GetPlayerPos(targetid, x, y, z);

			SetPlayerInterior(playerid, GetPlayerInterior(targetid));
			SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));

			if (GetPlayerState(playerid) == 2) {
				SetVehiclePos(GetPlayerVehicleID(playerid), x + 3, y, z);

				LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(targetid));
				SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(targetid));
			}
			else
				SetPlayerPos(playerid, x + 2, y, z);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);
	}
	return 1;
}

flags:vgoto(CMD_MEMBER)
CMD:vgoto(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "i", targetid)) return ShowSyntax(playerid, "/vgoto [vehicle]");

		new Float:x, Float:y, Float:z;
		GetVehiclePos(targetid, x, y, z);

		SetPlayerVirtualWorld(playerid,GetVehicleVirtualWorld(targetid));
		if (GetPlayerState(playerid) == 2) {
			SetVehiclePos(GetPlayerVehicleID(playerid), x + 3, y, z);
			SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetVehicleVirtualWorld(targetid));
		} else SetPlayerPos(playerid, x + 2, y, z);
	}
	return 1;
}

flags:vget(CMD_MEMBER)
CMD:vget(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "i", targetid)) return ShowSyntax(playerid, "/vget [vehicle]");

		new Float:x, Float:y, Float:z;

		GetPlayerPos(playerid, x, y, z);
		SetVehiclePos(targetid, x + 3, y, z);

		SetVehicleVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
	}
	return 1;
}

flags:vslap(CMD_MEMBER)
CMD:vslap(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "i", targetid)) return ShowSyntax(playerid, "/vslap [vehicle]");

		new Float:x, Float:y, Float:z;

		GetVehiclePos(targetid, x, y, z);
		SetVehiclePos(targetid, x, y, z + 5);

		SetVehicleVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
	}
	return 1;
}

flags:get(CMD_MEMBER)
CMD:get(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		new targetid;
		if (sscanf(params, "u", targetid)) return ShowSyntax(playerid, "/get [playerid/name]");

		if (pVerified[targetid] && targetid != INVALID_PLAYER_ID && targetid != playerid) {
			if (ComparePrivileges(targetid, CMD_OWNER) && !ComparePrivileges(playerid, CMD_OWNER) && targetid != playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);

			new Float:x, Float:y, Float:z;
			GetPlayerPos(playerid, x, y, z);
			SetPlayerInterior(targetid, GetPlayerInterior(playerid));

			SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));

			if (GetPlayerState(targetid) == 2) {
				new VehicleID = GetPlayerVehicleID(targetid);

				SetVehiclePos(VehicleID,x + 3, y, z);
				LinkVehicleToInterior(VehicleID, GetPlayerInterior(playerid));

				SetVehicleVirtualWorld(GetPlayerVehicleID(targetid), GetPlayerVirtualWorld(playerid));

			} else SetPlayerPos(targetid, x + 2, y, z);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_319x);
	}
	return 1;
}

//PLAYER SECTION

//Admins

CMD:admins(playerid) {
	new count = 0, AdmStr[SMALL_STRING_LEN];

	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_189x);

	foreach (new i: Player) {
		if (ComparePrivileges(i, CMD_MEMBER)) {
			format(AdmStr, sizeof(AdmStr), "%s[%d] - %s [%d]", PlayerInfo[i][PlayerName], i, _staff_roles[(PlayerInfo[i][pAdminLevel] - 1)], PlayerInfo[i][pAdminLevel]);
			SendClientMessage(playerid, X11_GRAY, AdmStr);
			count++;
		}
	}

	if (count == 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_336x);
	return 1;
}

//Report

CMD:report(playerid, params[]) {
	new targetid, reason[45];

	if (sscanf(params, "us[45]", targetid, reason)) return ShowSyntax(playerid, "/report [playerid/name] [reason]");
	if (strlen(reason) < 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_330x);
	if (targetid == playerid) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_329x);
	if (!pVerified[targetid] || targetid == INVALID_PLAYER_ID) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_320x);

	new hour, minute, second;
	gettime(hour, minute, second);

	new String[SMALL_STRING_LEN];
	format(String, sizeof(String), "[REPORT] %s[%d] reported %s[%d] for \"%s\".", PlayerInfo[playerid][PlayerName], playerid, PlayerInfo[targetid][PlayerName], targetid, reason);
	foreach (new i: Player)
	{
		if (ComparePrivileges(i, CMD_MEMBER))
		{
			SendClientMessage(i, X11_SERV_WARN, String);
		}
	}

	for (new i = (MAX_REPORTS - 1); i >= 1; i--) {
		ReportInfo[i][R_VALID] = ReportInfo[i - 1][R_VALID];
		ReportInfo[i][R_AGAINST_ID] = ReportInfo[i - 1][R_AGAINST_ID];

		format(ReportInfo[i][R_AGAINST_NAME], MAX_PLAYER_NAME, ReportInfo[i - 1][R_AGAINST_NAME]);
		ReportInfo[i][R_FROM_ID] = ReportInfo[i - 1][R_FROM_ID];

		format(ReportInfo[i][R_FROM_NAME], MAX_PLAYER_NAME, ReportInfo[i - 1][R_FROM_NAME]);
		ReportInfo[i][R_TIMESTAMP] = ReportInfo[i - 1][R_TIMESTAMP];

		format(ReportInfo[i][R_REASON], 65, ReportInfo[i - 1][R_REASON]);

		ReportInfo[i][R_CHECKED] = ReportInfo[i - 1][R_CHECKED];
		ReportInfo[i][R_READ] = ReportInfo[i - 1][R_READ];
	}

	ReportInfo[0][R_VALID] = true;
	ReportInfo[0][R_AGAINST_ID] = targetid;

	GetPlayerName(targetid, ReportInfo[0][R_AGAINST_NAME], MAX_PLAYER_NAME);
	ReportInfo[0][R_FROM_ID] = playerid;

	GetPlayerName(playerid, ReportInfo[0][R_FROM_NAME], MAX_PLAYER_NAME);
	ReportInfo[0][R_TIMESTAMP] = gettime();

	format(ReportInfo[0][R_REASON], 65, reason);

	ReportInfo[0][R_CHECKED] = true;
	ReportInfo[0][R_READ] = 0;

	foreach( new x: Player) {
		PlayerReportChecked[x][0] = PlayerReportChecked[x][0];
	}

	new query[240];

	mysql_format(Database, query, sizeof(query), "INSERT INTO `PlayersReports` (`Reporter`, `ReportedPlayer`, `Reason`, `DateIssued`) VALUES ('%e', '%e', '%e', CURDATE())", PlayerInfo[playerid][PlayerName], reason, PlayerInfo[targetid][PlayerName]);
	mysql_tquery(Database, query);

	PlayerInfo[playerid][pUsedReport] = 1;

	PlayerInfo[playerid][pPlayerReports] ++;
	PlayerInfo[targetid][pReportAttempts] ++;

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_328x);
	return 1;
}

//EO-MODULE

//EXPORTED CLAN CODE

//Clan management commands

flags:acw(CMD_OPERATOR)

CMD:acw(playerid) {
	return ClanWarManager(playerid);
}

//EXPORTED LOG CORE

//Some commands for logging
flags:getbans(CMD_OPERATOR)
CMD:getbans(playerid, params[]) {
	new nick[MAX_PLAYER_NAME], query[MEDIUM_STRING_LEN], offset;

	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return 0;
	if (sscanf(params, "s[24]i", nick, offset)) return ShowSyntax(playerid, "/getbans [name] [offset]");


	mysql_format(Database, query, sizeof(query), "SELECT * FROM `BansHistoryData` WHERE `BannedName` = '%e' ORDER BY `BanId` DESC LIMIT %d, %d", nick, offset, offset + 10);
	mysql_tquery(Database, query, "GetLog_Ban", "is", playerid, nick);
	return 1;
}

flags:getfreezes(CMD_OPERATOR)
CMD:getfreezes(playerid, params[]) {
	new nick[MAX_PLAYER_NAME], query[MEDIUM_STRING_LEN], offset;

	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return 0;
	if (sscanf(params, "s[24]i", nick, offset)) return ShowSyntax(playerid, "/getfreezes [name] [offset]");


	mysql_format(Database, query, sizeof(query), "SELECT * FROM `Punishments` WHERE `PunishedPlayer` = '%e' AND `Action` = 'Freeze' ORDER BY `ActionId` DESC LIMIT %d, %d", nick, offset, offset + 10);
	mysql_tquery(Database, query, "GetLog_Freeze", "is", playerid, nick);
	return 1;
}

flags:getwarns(CMD_OPERATOR)
CMD:getwarns(playerid, params[]) {
	new nick[MAX_PLAYER_NAME], query[MEDIUM_STRING_LEN], offset;

	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return 0;
	if (sscanf(params, "s[24]i", nick, offset)) return ShowSyntax(playerid, "/getwarns [name] [offset]");


	mysql_format(Database, query, sizeof(query), "SELECT * FROM `Punishments` WHERE `PunishedPlayer` = '%e' AND `Action` = 'Warn' ORDER BY `ActionId` DESC LIMIT %d, %d", nick, offset, offset + 10);
	mysql_tquery(Database, query, "GetLog_Warn", "is", playerid, nick);
	return 1;
}

flags:getmutes(CMD_OPERATOR)
CMD:getmutes(playerid, params[]) {
	new nick[MAX_PLAYER_NAME], query[MEDIUM_STRING_LEN], offset;

	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return 0;
	if (sscanf(params, "s[24]i", nick, offset)) return ShowSyntax(playerid, "/getmutes [name] [offset]");


	mysql_format(Database, query, sizeof(query), "SELECT * FROM `Punishments` WHERE `PunishedPlayer` = '%e' AND `Action` = 'Mute' ORDER BY `ActionId` DESC LIMIT %d, %d", nick, offset, offset + 10);
	mysql_tquery(Database, query, "GetLog_Mute", "is", playerid, nick);
	return 1;
}

flags:getunbans(CMD_OPERATOR)
CMD:getunbans(playerid, params[]) {
	new nick[MAX_PLAYER_NAME], query[MEDIUM_STRING_LEN], offset;

	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return 0;
	if (sscanf(params, "s[24]i", nick, offset)) return ShowSyntax(playerid, "/getunbans [name] [offset]");


	mysql_format(Database, query, sizeof(query), "SELECT * FROM `Punishments` WHERE `PunishedPlayer` = '%e' AND `Action` = 'Unban' ORDER BY `ActionId` DESC LIMIT %d, %d", nick, offset, offset + 10);
	mysql_tquery(Database, query, "GetLog_Unban", "is", playerid, nick);
	return 1;
}

flags:getkicks(CMD_OPERATOR)
CMD:getkicks(playerid, params[]) {
	new nick[MAX_PLAYER_NAME], query[110 + MAX_PLAYER_NAME], offset;

	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return 0;
	if (sscanf(params, "s[24]i", nick, offset)) return ShowSyntax(playerid, "/getkicks [name] [offset]");

	mysql_format(Database, query, sizeof(query), "SELECT * FROM `Punishments` WHERE `PunishedPlayer` = '%e' AND `Action` = 'Kick' ORDER BY `ActionId` DESC LIMIT %d, %d", nick, offset, offset + 10);
	mysql_tquery(Database, query, "GetLog_Kick", "is", playerid, nick);
	return 1;
}

flags:getjails(CMD_OPERATOR)
CMD:getjails(playerid, params[]) {
	new nick[MAX_PLAYER_NAME], query[110 + MAX_PLAYER_NAME], offset;

	if (!ComparePrivileges(playerid, CMD_OPERATOR)) return 0;
	if (sscanf(params, "s[24]i", nick, offset)) return ShowSyntax(playerid, "/getjails [name] [offset]");

	mysql_format(Database, query, sizeof(query), "SELECT * FROM `Punishments` WHERE `PunishedPlayer` = '%e' AND `Action` = 'Jail' ORDER BY `ActionId` DESC LIMIT %d, %d", nick, offset, offset + 10);
	mysql_tquery(Database, query, "GetLog_Jail", "is", playerid, nick);
	return 1;
}

//EXPORTED EVENT CORE

//Check player state
RACE_OnPlayerStateChange(playerid) {
	if ((Iter_Contains(ePlayers, playerid) && EventInfo[E_ALLOWLEAVECARS] == 0 && EventInfo[E_STARTED]) ||
		(pRaceId[playerid] != -1 && RaceStarted[pRaceId[playerid]] && !RaceOpened[pRaceId[playerid]])) {
		pEventInfo[playerid][P_CARTIMER] = 20;
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_172x);
	}
	return 1;
}

//
/*
		C O M M A N D S!
*/
//

//PUBG

//PUBG event commands

flags:spubg(CMD_MEMBER)
CMD:spubg(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		StartPUBGByPlayer(playerid);
		SendWarUpdate("PUBG Event begins now!");
		GameTextForAll("~g~PUBG EVENT STARTING!!~n~/PUBG", 3000, 3);
		SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s started the PUBG event.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
	}
	return 1;
}

flags:epubg(CMD_MEMBER)
CMD:epubg(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (!PUBGStarted) return SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_172x);
		SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s ended the PUBG event.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
		if (!Iter_Count(PUBGPlayers)) {
			PUBGStarted = false;
			SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_65x);
			HidePUBGWinner();
		}
		foreach (new i: Player) {
			if (Iter_Contains(PUBGPlayers, i)) {
				TextDrawHideForPlayer(i, PUBGKillsTD);

				new msg[SMALL_STRING_LEN];

				format(msg, sizeof(msg), "%d Kills", PUBGKills ++);
				TextDrawSetString(PUBGKillsTD, msg);

				TextDrawHideForPlayer(i, PUBGAreaTD);
				TextDrawHideForPlayer(i, PUBGAliveTD);
				TextDrawHideForPlayer(i, PUBGKillTD);
				if (Iter_Count(PUBGPlayers) == 1) {
					new winner = Iter_Random(PUBGPlayers);
					TextDrawHideForPlayer(winner, PUBGKillsTD);
					TextDrawHideForPlayer(winner, PUBGKillTD);
					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_CHICKEN_DINNER, PlayerInfo[winner][PlayerName]);
					PlayerInfo[winner][pPUBGEventsWon] ++;
					PlayerInfo[winner][pEXPEarned] += 50;
					SuccessAlert(winner);
					Iter_Clear(PUBGPlayers);
					PUBGStarted = false;
					SetPlayerHealth(winner, 0);
					TextDrawHideForPlayer(winner, PUBGAreaTD);
					TextDrawHideForPlayer(winner, PUBGAliveTD);
					GameTextForPlayer(winner, "~g~WINNER WINNER CHICKEN DINNER!", 3000, 3);
					TextDrawSetString(PUBGWinnerTD[1], PlayerInfo[winner][PlayerName]);
					new str[SMALL_STRING_LEN];
					format(str, sizeof(str), "~w~KILLS: ~g~%d            ~w~REWARD: ~g~$500,000 & 100 Score", PUBGKills);
					TextDrawSetString(PUBGWinnerTD[3], str);
					for (new x = 0; x < sizeof(PUBGWinnerTD); x++) {
						TextDrawShowForAll(PUBGWinnerTD[x]);
					}
					SetTimer("HidePUBGWinner", 3000, false);
				}
				Iter_SafeRemove(PUBGPlayers, i, i);
			}
		}
		SendWarUpdate("PUBG Event ended now!");
		for (new i = 0; i < MAX_SLOTS; i++) {
			if (gLootExists[i] && gLootPUBG[i]) {
				AlterLootPickup(i);
			}
			if (gWeaponExists[i] && gWeaponPUBG[i]) {
				AlterWeaponPickup(INVALID_PLAYER_ID, i);
			}
		}
	}
	return 1;
}

//Event commands

flags:event(CMD_MEMBER)
CMD:event(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		inline EventCash(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
			if (EventInfo[E_CASH] > 10000 || EventInfo[E_CASH] <= 0) return GameTextForPlayer(playerid, "~g~CASH FOR EVENT~n~~w~$0-10,000", 3000, 3);

			EventInfo[E_CASH] = strval(inputtext);
			SendClientMessage(playerid, X11_GREEN, "Event cash bonus updated.");
		}
		inline EventScore(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
			if (EventInfo[E_SCORE] > 10 || EventInfo[E_SCORE] <= 0) return GameTextForPlayer(playerid, "~g~SCORE FOR EVENT~n~~w~0-10", 3000, 3);

			EventInfo[E_SCORE] = strval(inputtext);
			SendClientMessage(playerid, X11_GREEN, "Event score bonus updated.");
		}
		inline EventName(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
			if (!strlen(inputtext)) return Dialog_ShowCallback(pid, using inline EventName, DIALOG_STYLE_INPUT, "Custom event name:", "Write the name of this event:", "Input", "X");

			format(EventInfo[E_NAME], sizeof(EventInfo[E_NAME]), "%s", inputtext);
			SendClientMessage(playerid, X11_GREEN, "Event name updated.");
		}
		inline EventVehicle(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
			if (strval(inputtext) < 400 || strval(inputtext) > 611 || !strlen(inputtext)) return Dialog_ShowCallback(pid, using inline EventVehicle, DIALOG_STYLE_INPUT, "Custom event vehicle:", "{FF0000}Wrong vehicle ID.\nWrite the vehicle id for current event players:", "Input", "X");

			foreach (new i: ePlayers) {
				if (PlayerInfo[i][pCar] != -1) DestroyVehicle(PlayerInfo[i][pCar]);
				PlayerInfo[i][pCar] = -1;

				new Float: Position[4], Int, World;

				Int = GetPlayerInterior(i);
				World = GetPlayerVirtualWorld(i);

				GetPlayerPos(i, Position[0], Position[1], Position[2]);
				GetPlayerFacingAngle(i, Position[3]);

				PlayerInfo[i][pCar] = CreateVehicle(strval(inputtext), Position[0], Position[1], Position[2], Position[3], 0, 3, -1);

				LinkVehicleToInterior(PlayerInfo[i][pCar], Int);
				SetVehicleVirtualWorld(PlayerInfo[i][pCar], World);
				PutPlayerInVehicle(i, PlayerInfo[i][pCar], 0);
			}
			SendClientMessage(playerid, X11_GREEN, "Event vehicle given to any event player online.");
			SetPVarInt(playerid, "LastRaceCreatedVID", strval(inputtext));
		}
		inline EventWeap1(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

			new weapon, ammo;
			if (sscanf(inputtext, "ii", weapon, ammo)) {
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_422x);
				return Dialog_ShowCallback(pid, using inline EventWeap1, DIALOG_STYLE_INPUT, "Custom event weapon 1:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
			}

			EventInfo[E_WEAP1][0] = weapon;
			EventInfo[E_WEAP1][1] = ammo;

			foreach (new i: ePlayers) {
				GivePlayerWeapon(i, EventInfo[E_WEAP1][0], EventInfo[E_WEAP1][1]);
			}
			SendClientMessage(playerid, X11_GREEN, "Event weapon 1 updated.");
		}
		inline EventWeap2(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

			new weapon, ammo;
			if (sscanf(inputtext, "ii", weapon, ammo)) {
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_422x);
				return Dialog_ShowCallback(pid, using inline EventWeap2, DIALOG_STYLE_INPUT, "Custom event weapon 2:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
			}

			EventInfo[E_WEAP2][0] = weapon;
			EventInfo[E_WEAP2][1] = ammo;

			foreach (new i: ePlayers) {
				GivePlayerWeapon(i, EventInfo[E_WEAP2][0], EventInfo[E_WEAP2][1]);
			}
			SendClientMessage(playerid, X11_GREEN, "Event weapon 2 updated.");
		}
		inline EventWeap3(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

			new weapon, ammo;
			if (sscanf(inputtext, "ii", weapon, ammo)) {
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_422x);
				return Dialog_ShowCallback(pid, using inline EventWeap3, DIALOG_STYLE_INPUT, "Custom event weapon 3:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
			}

			EventInfo[E_WEAP3][0] = weapon;
			EventInfo[E_WEAP3][1] = ammo;

			foreach (new i: ePlayers) {
				GivePlayerWeapon(i, EventInfo[E_WEAP3][0], EventInfo[E_WEAP3][1]);
			}
			SendClientMessage(playerid, X11_GREEN, "Event weapon 3 updated.");
		}
		inline EventWeap4(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext, listitem
			PC_EmulateCommand(pid, "/event");
			if (!response) return 1;
			if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

			new weapon, ammo;
			if (sscanf(inputtext, "ii", weapon, ammo)) {
				SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_422x);
				return Dialog_ShowCallback(pid, using inline EventWeap4, DIALOG_STYLE_INPUT, "Custom event weapon 4:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
			}

			EventInfo[E_WEAP4][0] = weapon;
			EventInfo[E_WEAP4][1] = ammo;

			foreach (new i: ePlayers) {
				GivePlayerWeapon(i, EventInfo[E_WEAP4][0], EventInfo[E_WEAP4][1]);
			}
			SendClientMessage(playerid, X11_GREEN, "Event weapon 4 updated.");
		}
		inline EventSpawnType(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (!response) return PC_EmulateCommand(pid, "/event");
			switch (listitem) {
				case 0: {
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (EventInfo[E_SPAWN_TYPE] != EVENT_SPAWN_INVALID) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_425x);

					if (EventInfo[E_TYPE] != 1) {
						EventInfo[E_MAX_PLAYERS] = 16;
					} else {
						EventInfo[E_MAX_PLAYERS] = 32;
					}

					EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_RANDOM;
					EventInfo[E_SPAWNS] = 0;
					SendClientMessage(playerid, X11_GREEN, "Event spawn mode was changed. Please use /here to generate spawn points.");
				}
				case 1: {
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (EventInfo[E_SPAWN_TYPE] != EVENT_SPAWN_INVALID) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_425x);
					if (EventInfo[E_TYPE] == 1 || EventInfo[E_TYPE] == 2) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_426x);

					new Float: Position[4], Int, World;

					EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_ADMIN;
					EventInfo[E_MAX_PLAYERS] = 32;

					GetPlayerPos(pid, Position[0], Position[1], Position[2]);
					GetPlayerFacingAngle(pid, Position[3]);

					Int = GetPlayerInterior(pid);
					World = GetPlayerVirtualWorld(pid);

					SpawnInfo[0][S_COORDS][0] = Position[0];
					SpawnInfo[0][S_COORDS][1] = Position[1];
					SpawnInfo[0][S_COORDS][2] = Position[2];
					SpawnInfo[0][S_COORDS][3] = Position[3];

					EventInfo[E_INTERIOR] = Int;
					EventInfo[E_WORLD] = World;

					PC_EmulateCommand(pid, "/event");
					SendClientMessage(playerid, X11_GREEN, "Event spawn mode was changed. Using /here is no longer required.");
				}
			}
		}
		inline EventMode(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (!response) return 1;

			switch (listitem) {
				case 0:
				{
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (Iter_Count(ePlayers) >= 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_427x);

					EventInfo[E_TYPE] = 1;
					SendClientMessage(playerid, X11_GREEN, "DM/TDM mode set.");
					PC_EmulateCommand(pid, "/event");
				}
				case 1:
				{
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (Iter_Count(ePlayers) >= 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_427x);

					EventInfo[E_TYPE] = 2;
					RaceStarted[MAX_RACES-1] = 1;
					SendClientMessage(playerid, X11_GREEN, "Race mode set. Please use /cp to generate checkpoints.");
					PC_EmulateCommand(pid, "/event");
				}
				case 2:
				{
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (Iter_Count(ePlayers) >= 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_427x);

					EventInfo[E_TYPE] = 0;
					SendClientMessage(playerid, X11_GREEN, "DM/TDM mode set.");
					PC_EmulateCommand(pid, "/event");
				}
			}
		}
		inline EventManager(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused dialogid, inputtext
			if (!response) return 1;

			switch (listitem) {
				case 0: {
					if (EventInfo[E_STARTED] == 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_425x);

					new clear_data[E_DATA_ENUM];
					EventInfo = clear_data;

					new clear_data3[E_SPAWN_ENUM];

					for (new i = 0; i < MAX_CHECKPOINTS; i++) {
						SpawnInfo[i] = clear_data3;
					}
					ResetRaceSlot(MAX_RACES-1);

					EventInfo[E_STARTED] = 1;
					RaceStarted[MAX_RACES-1] = 0;

					EventInfo[E_OPENED] = 0;

					EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
					EventInfo[E_TYPE] = -1;

					EventInfo[E_FREEZE] = 1;
					EventInfo[E_AUTO] = 0;
					SendClientMessage(playerid, X11_GREEN, "Event plan mode set.");
				}
				case 1: {
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (EventInfo[E_SPAWN_TYPE] != EVENT_SPAWN_INVALID) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_425x);

					Dialog_ShowCallback(pid, using inline EventSpawnType, DIALOG_STYLE_LIST, "Choose Spawn",
					"Random spawn locations\n\
					Set location here", ">>", "X");
				}
				case 2: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					Dialog_ShowCallback(pid, using inline EventWeap1, DIALOG_STYLE_INPUT, "Custom event weapon 1:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
				}
				case 3: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					Dialog_ShowCallback(pid, using inline EventWeap2, DIALOG_STYLE_INPUT, "Custom event weapon 2:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
				}
				case 4: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					Dialog_ShowCallback(pid, using inline EventWeap3, DIALOG_STYLE_INPUT, "Custom event weapon 3:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
				}
				case 5: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					Dialog_ShowCallback(pid, using inline EventWeap4, DIALOG_STYLE_INPUT, "Custom event weapon 4:", "Write your weapon id and ammount of ammo below.\n {E8E8E8}-> (e.g. 24 500)", "Input", "X");
				}
				case 6: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					Dialog_ShowCallback(pid, using inline EventVehicle, DIALOG_STYLE_INPUT, "Custom event vehicle:", "Write the vehicle id for current event players:", "Input", "X");
				}
				case 7: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					Dialog_ShowCallback(pid, using inline EventName, DIALOG_STYLE_INPUT, "Custom event name:", "Write the name of this event:", "Input", "X");
				}
				case 8: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

					foreach (new i: ePlayers) {
						SetPlayerHealth(i, 100.0);
					}
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s refilled health the event players.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 9: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

					foreach (new i: ePlayers) {
						SetPlayerArmour(i, 100.0);
					}
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s refilled armour for the event players.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 10: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

					new Float: Position[3], Int, World;

					Int = GetPlayerInterior(pid);
					World = GetPlayerVirtualWorld(pid);

					GetPlayerPos(pid, Position[0], Position[1], Position[2]);

					foreach (new i: ePlayers) {
						SetPlayerPos(i, Position[0], Position[1], Position[2]);
						SetPlayerInterior(i, Int);
						SetPlayerVirtualWorld(i, World);
					}
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s teleported the event players.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 11: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

					EventInfo[E_FREEZE] = 1;

					foreach (new i: ePlayers) {
						TogglePlayerControllable(i, false);
					}
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s froze the event players.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 12: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

					EventInfo[E_FREEZE] = 0;

					foreach (new i: ePlayers) {
						TogglePlayerControllable(i, true);
					}
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s unfroze the event players.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 13: {
					PC_EmulateCommand(pid, "/event");
					if (EventInfo[E_STARTED] == 1 && EventInfo[E_OPENED] == 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_425x);
					if (!strlen(EventInfo[E_NAME])) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_428x);
					if (EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_INVALID) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);
					if (EventInfo[E_TYPE] != 2 && EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_RANDOM && EventInfo[E_SPAWNS] == 0) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);
					if (EventInfo[E_TYPE] == 2 && RaceTotalCheckpoints[MAX_RACES-1] < 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_430x);
					if (EventInfo[E_TYPE] == 2 && RaceTotalSpawns[MAX_RACES-1] < 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);

					GameTextForAll("~w~EVENT!~n~~g~/join",4000,3);
					EventInfo[E_OPENED] = 1;
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s opened the event.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 14: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED] || EventInfo[E_OPENED] == 0) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_425x);
					if (!strlen(EventInfo[E_NAME])) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_428x);
					if (EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_INVALID) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);
					if (EventInfo[E_TYPE] != 2 && EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_RANDOM && EventInfo[E_SPAWNS] == 0) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);
					if (EventInfo[E_TYPE] == 2 && RaceTotalCheckpoints[MAX_RACES-1] < 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_430x);
					if (EventInfo[E_TYPE] == 2 && RaceTotalSpawns[MAX_RACES-1] < 3) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);

					EventInfo[E_OPENED] = 0;

					foreach (new i: ePlayers) {
						GameTextForPlayer(i, "~g~GO GO!", 2000, 3);
						TogglePlayerControllable(i, true);

						if (EventInfo[E_FREEZE] == 1) {
								EventInfo[E_FREEZE] = 0;
						}
					}

					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s started the event.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 15: {
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (EventInfo[E_TYPE] == 2) return SendClientMessage(playerid, X11_RED_2, "Race events have bonuses setup internally.");
					Dialog_ShowCallback(pid, using inline EventScore, DIALOG_STYLE_INPUT, "Custom event score bonus:", "Write the score bonus of event below:", "Input", "X");
				}
				case 16: {
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (EventInfo[E_TYPE] == 2) return SendClientMessage(playerid, X11_RED_2, "Race events have bonuses setup internally.");
					Dialog_ShowCallback(pid, using inline EventCash, DIALOG_STYLE_INPUT, "Custom event cash bonus:", "Write the cash bonus of event below:", "Input", "X");
				}
				case 17: {
					PC_EmulateCommand(pid, "/event");
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (!strlen(EventInfo[E_NAME])) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_428x);
					if (EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_INVALID) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);
					if (EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_RANDOM && EventInfo[E_SPAWNS] == 0) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_429x);
					if (EventInfo[E_TYPE] == 2) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_426x);

					new count;

					foreach (new i: ePlayers) {
						if (IsPlayerSpawned(i)) {
							count++;
						}
					}

					if (count == 0) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_26x, EventInfo[E_NAME]);

					SendGameMessage(@pVerified, X11_SERV_INFO, MSG_NEWSERVER_37x);

					EventInfo[E_OPENED] = 0;
					EventInfo[E_STARTED] = 0;
					RaceStarted[MAX_RACES-1] = 0;

					new winners = 0;

					foreach (new i: ePlayers) {
						TogglePlayerControllable(i, true);
						SetPlayerHealth(i, 0.0);

						new Player_Name[MAX_PLAYER_NAME];
						GetPlayerName(i, Player_Name, sizeof(Player_Name));

						winners ++;

						SendGameMessage(@pVerified, X11_SERV_INFO, MSG_EVENT_WON_LIST, winners, Player_Name, EventInfo[E_SCORE], formatInt(EventInfo[E_CASH]));

						GivePlayerCash(i, EventInfo[E_CASH]);
						GivePlayerScore(i, EventInfo[E_SCORE]);
						PlayerInfo[i][sEvents] ++;
						PlayerInfo[i][pEventsWon] ++;

						if (PlayerInfo[i][pCar] != -1) {
							DestroyVehicle(PlayerInfo[i][pCar]);
						}
					}

					Iter_Clear(ePlayers);

					new clear_data[E_DATA_ENUM];
					EventInfo = clear_data;

					EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
					EventInfo[E_TYPE] = -1;
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s finished the event.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);

					if (EventInfo[E_TYPE] == 2 && GetPVarInt(pid, "LastRaceCreatedVID") != 0) {
						new query[650];
						mysql_format(Database, query, sizeof(query), "INSERT INTO `RacesData` (`RaceName`, `RaceMaker`, `RaceVehicle`, `RaceInt`, `RaceWorld`, `RaceDate`) \
							VALUES ('%e', '%e', '%d', '%d', '%d', '%d')", EventInfo[E_NAME], PlayerInfo[pid][PlayerName], GetPVarInt(pid, "LastRaceCreatedVID"), EventInfo[E_INTERIOR], EventInfo[E_WORLD], gettime());
						mysql_tquery(Database, query);

						for (new i = 0; i < RaceTotalSpawns[MAX_RACES-1]; i++) {
							mysql_format(Database, query, sizeof(query), "INSERT INTO `RacesSpawnPoints` (`RaceId`, `RX`, `RY`, `RZ`, `RRot`) \
								VALUES ((SELECT `RaceId` FROM `RacesData` WHERE `RaceName` = '%e'), '%f', '%f', '%f', '%f')",
								EventInfo[E_NAME], RaceSpawns[MAX_RACES-1][i][0], RaceSpawns[MAX_RACES-1][i][1], RaceSpawns[MAX_RACES-1][i][2], RaceSpawns[MAX_RACES-1][i][3]);
							mysql_tquery(Database, query);
						}

						for (new i = 0; i < RaceTotalCheckpoints[MAX_RACES-1]; i++) {
							mysql_format(Database, query, sizeof(query), "INSERT INTO `RacesCheckpoints` (`RaceId`, `RX`, `RY`, `RZ`, `RType`) \
								VALUES ((SELECT `RaceId` FROM `RacesData` WHERE `RaceName` = '%e'), '%f', '%f', '%f', '%d')",
								EventInfo[E_NAME], RaceCheckpoints[MAX_RACES-1][i][0], RaceCheckpoints[MAX_RACES-1][i][1], RaceCheckpoints[MAX_RACES-1][i][2], RaceCheckpointType[MAX_RACES-1][i]);
							mysql_tquery(Database, query);
						}
					}
				}
				case 18: {
					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

					new clear_data[E_DATA_ENUM];
					EventInfo = clear_data;

					EventInfo[E_STARTED] = 0;
					RaceStarted[MAX_RACES-1] = 0;
					EventInfo[E_OPENED] = 0;

					EventInfo[E_SPAWN_TYPE] = EVENT_SPAWN_INVALID;
					EventInfo[E_TYPE] = -1;

					foreach (new i: ePlayers) {
						SpawnPlayer(i);
						DisablePlayerCheckpoint(i);
					}

					Iter_Clear(ePlayers);
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s canceled the event.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 19: {
					PC_EmulateCommand(pid, "/event");

					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);
					if (EventInfo[E_TYPE] == 1) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_426x);

					if (EventInfo[E_ALLOWLEAVECARS] == 1) {
						EventInfo[E_ALLOWLEAVECARS] = 0;
						SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_431x);
					}
					else
					{
						EventInfo[E_ALLOWLEAVECARS] = 1;
						SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_432x);
					}
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s event vehicle status updated.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
				case 20: {
					PC_EmulateCommand(pid, "/event");

					if (!EventInfo[E_STARTED]) return SendGameMessage(pid, X11_SERV_INFO, MSG_CLIENT_420x);

					foreach (new i: ePlayers) {
						if (IsPlayerInAnyVehicle(i)) {
							RepairVehicle(i);
						}
					}
					SendGameMessage(@pVerified, X11_SERV_INFO, "%s %s repaired vehicle for the event players.", _Get_Role(playerid), PlayerInfo[playerid][PlayerName]);
				}
			}
		}
		if (EventInfo[E_STARTED] == 1) {
			if (EventInfo[E_TYPE] != -1) {
				if (EventInfo[E_SPAWN_TYPE] != -1) {
					Dialog_ShowCallback(playerid, using inline EventManager, DIALOG_STYLE_LIST, "Event",
					"{FF0000}Start Event\n{FF0000}Event Location\nEvent Weapon 1\nEvent Weapon 2\nEvent Weapon 3\nEvent Weapon 4\n\
					Give Vehicle\nEvent Name\nHeal Players\nArmour Players\nGet Players\nFreeze Players\nUnfreeze Players\n\
					Allow Joins\nClose Joins\nEvent Score\nEvent Money\nEvent Finish\nEvent Stop\nLeaving Cars", ">>", "X");
				} else {
					Dialog_ShowCallback(playerid, using inline EventManager, DIALOG_STYLE_LIST, "Event",
					"{FF0000}Start Event\nEvent Location", ">>", "X");
				}
			}
			else
			{
				Dialog_ShowCallback(playerid, using inline EventMode, DIALOG_STYLE_LIST, "Event",
				"TDM Event\nRace Event\nDeath-match Event", ">>", "X");
			}
		} else if (!EventInfo[E_STARTED]) {
			Dialog_ShowCallback(playerid, using inline EventManager, DIALOG_STYLE_LIST, "Event",
			"Start Event", ">>", "X");
		}
	}
	return 1;
}

flags:here(CMD_MEMBER)
CMD:here(playerid) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (EventInfo[E_TYPE] == 1 && EventInfo[E_SPAWNS] == 2) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_433x);
		if (EventInfo[E_SPAWN_TYPE] != EVENT_SPAWN_RANDOM) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_426x);
		if (EventInfo[E_SPAWNS] >= 69) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

		new Float: Position[4], Int, World;

		GetPlayerPos(playerid, Position[0], Position[1], Position[2]);
		GetPlayerFacingAngle(playerid, Position[3]);

		Int = GetPlayerInterior(playerid);
		World = GetPlayerVirtualWorld(playerid);

		if (EventInfo[E_TYPE] != 2) {
			SpawnInfo[EventInfo[E_SPAWNS]][S_COORDS][0] = Position[0];
			SpawnInfo[EventInfo[E_SPAWNS]][S_COORDS][1] = Position[1];
			SpawnInfo[EventInfo[E_SPAWNS]][S_COORDS][2] = Position[2];
			SpawnInfo[EventInfo[E_SPAWNS]][S_COORDS][3] = Position[3];
			EventInfo[E_MAX_PLAYERS] += 7;
			EventInfo[E_SPAWNS]++;
			EventInfo[E_INTERIOR] = Int;
			EventInfo[E_WORLD] = World;
			SendClientMessage(playerid, X11_GREEN1, "Event checkpoint generated at those coordinates!");
		} else {
			GenerateRaceSpawn(MAX_RACES-1, Position[0], Position[1], Position[2], Position[3]);
			RaceInterior[MAX_RACES-1] = Int;
			SendClientMessage(playerid, X11_GREEN1, "Race spawn generated at those coordinates!");
		}
	}
	return 1;
}

//EO-MODULE

/*
	PUBG MODULE
*/

//PUBG Commands

CMD:pubg(playerid) {
	if (GetPlayerVirtualWorld(playerid) || GetPlayerInterior(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_466x);
	if (IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_467x);
	if (pDuelInfo[playerid][pDInMatch] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INDUEL);
	if (PlayerInfo[playerid][pDeathmatchId] > -1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INDM);
	if (Iter_Contains(ePlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_468x);
	if (Iter_Contains(CWCLAN1, playerid) || Iter_Contains(CWCLAN2, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INCW);
	if (!PUBGOpened) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_469x);
	if (Iter_Contains(PUBGPlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_470x);
	SetPlayerInterior(playerid, 0);
	SetPlayerPos(playerid, -2304.3433,-1608.0492,483.9337);
	SetPlayerFacingAngle(playerid, 188.4081);
	SetPlayerVirtualWorld(playerid, PUBG_WORLD);
	ResetPlayerWeapons(playerid);
	Items_ResetPlayer(playerid);

	SetPlayerArmour(playerid, 0);
	SetPlayerHealth(playerid, 100);
	SetPlayerColor(playerid, 0xFFFFFF00);
	TextDrawShowForPlayer(playerid, PUBGAliveTD);
	TextDrawShowForPlayer(playerid, PUBGKillsTD);
	Iter_Add(PUBGPlayers, playerid);
	return 1;
}

CMD:pubgers(playerid) {
	new sub_holder[27], string[MEDIUM_STRING_LEN], count = 0;
	if (!PUBGStarted) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_471x);

	foreach(new i: Player) {
		if (Iter_Contains(PUBGPlayers, i)) {
			format(sub_holder, sizeof(sub_holder), "%s\n", PlayerInfo[i][PlayerName]);
			strcat(string, sub_holder);

			count = 1;
		}
	}

	if (count) {
		Dialog_Show(playerid, DIALOG_STYLE_TABLIST, "PUBG Players", string, "X", "");
	}  else SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	return 1;
}

//EO-MODULE

/*
	TOYS MODULE
*/

//TOYS Commands

CMD:toys(playerid) {
	inline ToysBodySlots(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (!response) return PC_EmulateCommand(pid, "/toys");
		switch (listitem) {
			case 0: gEditSlot[pid] = 0;
			case 1: gEditSlot[pid] = 1;
			case 2: gEditSlot[pid] = 6;
			case 3: gEditSlot[pid] = 9;
		}
		gEditList[pid] = listitem;
		ShowModelSelectionMenu(pid, toyslist, "Body Toys", 0x000000CC, X11_DEEPPINK, X11_IVORY);
	}
	if (!PlayerInfo[playerid][pDonorLevel]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	new toys_dialog2[506];
	format(toys_dialog2, sizeof(toys_dialog2), "Body Slot 1\t%s\n\
			Body Slot 2\t%s\n\
			Body Slot 3\t%s\n\
			Body Slot 4\t%s",
				(IsPlayerAttachedObjectSlotUsed(playerid, 0) == 1) ? (""GREEN"[USED]") : (""RED2"[UNUSED]"),
				(IsPlayerAttachedObjectSlotUsed(playerid, 1) == 1) ? (""GREEN"[USED]") : (""RED2"[UNUSED]"),
				(IsPlayerAttachedObjectSlotUsed(playerid, 6) == 1) ? (""GREEN"[USED]") : (""RED2"[UNUSED]"),
				(IsPlayerAttachedObjectSlotUsed(playerid, 9) == 1) ? (""GREEN"[USED]") : (""RED2"[UNUSED]"));
	Dialog_ShowCallback(playerid, using inline ToysBodySlots, DIALOG_STYLE_TABLIST, ""RED2"SvT - Body Toys", toys_dialog2, ">>", "<<");
	return 1;
}

CMD:edittoy(playerid, params[]) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, strval(params))) {
		EditAttachedObject(playerid, strval(params));
		GameTextForPlayer(playerid, "~y~EDIT BODY TOY", 1000, 3);
	}
	return 1;
}

CMD:rmtoy(playerid, params[]) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, strval(params))) {
		RemovePlayerAttachedObject(playerid, strval(params));
		GameTextForPlayer(playerid, "~r~REMOVED BODY TOY", 1000, 3);
	}
	return 1;
}

CMD:edithelmet(playerid) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, 2)) {
		EditAttachedObject(playerid, 2);
	}
	return 1;
}

CMD:editmask(playerid) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, 3)) {
		EditAttachedObject(playerid, 3);
	}
	return 1;
}

CMD:editdynamite(playerid) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, 5)) {
		EditAttachedObject(playerid, 5);
	}
	return 1;
}

//EO-MODULE

/*
	RACES MODULE
*/

//Create race checkpoints, some important admin features
//used for over 2 years
flags:cp(CMD_MEMBER)
CMD:cp(playerid, params[]) {
	if (ComparePrivileges(playerid, CMD_MEMBER)) {
		if (EventInfo[E_TYPE] != 2) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_426x);
		if (RaceTotalCheckpoints[MAX_RACES-1] >= MAX_CHECKPOINTS || RaceOpened[MAX_RACES-1] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);

		new type[20], cptype;
		if (sscanf(params, "s[20]", type)) return ShowSyntax(playerid, "/cp [air/ground]");

		if (!strcmp(type, "ground", true)) {
			cptype = 0;
		} else if (!strcmp(type, "air", true)) {
			cptype = 1;
		} else return ShowSyntax(playerid, "/cp (info: race checkpoint) [params: air (for ring)/ground (for normal)]");

		new Float: Position[3];
		GetPlayerPos(playerid, Position[0], Position[1], Position[2]);
		GenerateRaceCheckpoint(MAX_RACES-1, cptype, Position[0], Position[1], Position[2]);
		SendClientMessage(playerid, X11_GREEN1, "Race checkpoint generated at those coordinates!");
	}
	return 1;
}

//Add code for race menu
//Isn't 2500 score too low to start a RACE event?!
alias:race("races", "racing")
CMD:race(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendClientMessage(playerid, X11_RED_2, "To join a race, you have to be in the battlefield.");
	if (pCooldown[playerid][41] > gettime()) {
		SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_475x, pCooldown[playerid][41] - gettime());
		return 1;
	}

	mysql_tquery(Database, "SELECT * FROM `RacesData` ORDER BY `RaceDate` DESC LIMIT 20", "DisplayRacesList", "i", playerid);
	return 1;
}

//EO-MODULE

/*
	VIP MODULE
*/

SetPlayerDonorSpawn(playerid) {
	if (PlayerInfo[playerid][pDonorLevel]) {
		Update3DTextLabelText(VipLabel[playerid], 0x9C693DCC, " ");
		Update3DTextLabelText(VipLabel[playerid], X11_GREEN, "*VIP*");
		SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 1000);
	} else {
		Update3DTextLabelText(VipLabel[playerid], 0x00000000, " ");
		if (!(p_ClassAbilities(playerid, SCOUT)) || !p_ClassAdvanced(playerid)) {
			SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, PlayerInfo[playerid][pSawnKills]);
		} else {
			SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 1000);
		}
	}
	return 1;
}

//Donor Commands

CMD:vips(playerid) {
	new count = 0, VipStr[SMALL_STRING_LEN];

	SendGameMessage(playerid, X11_SERV_INFO, MSG_NEWCLIENT_109x);

	foreach (new i: Player) {
		if (PlayerInfo[i][pDonorLevel] >= 1) {
			format(VipStr, sizeof(VipStr), "%d. %s[%d]", count+1, PlayerInfo[i][PlayerName], i);
			SendClientMessage(playerid, X11_GRAY, VipStr);
			count++;
		}
	}

	if (count == 0) return SendGameMessage(playerid, X11_SERV_ERR, MSG_INTERNAL_ERROR);
	return 1;
}

alias:vcmds("vip")
CMD:vcmds(playerid) {
   if (PlayerInfo[playerid][pLoggedIn] == 1) {
		Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, ""RED2"SvT - VIP Features",
		""RED2"~~ THE VIP SYSTEM ~~\n\
		"YELLOW"~~ One VIP tier, all of the premium features in one package!\n\n\
		"WHITE"SWAT vs Terrorists now features more premium features added to one standalone package.\n\
		Things you can do as a VIP is pretty much countless and interesting!\n\n\
		"YELLOW"- Anthrax intoxication radius increased to 45.0 meters instead of 35.0!\n\
		"YELLOW"- Free invisibility for the first 5 minutes after spawn\n\
		"YELLOW"- Double ammunition on all weapons can be added with /vammo\n\
		"YELLOW"- Tired of losing cash upon getting killed? Say no more to that\n\
		"YELLOW"- Enter any heavy air vehicle without further restrictons. You're a pilot!\n\
		"YELLOW"- Six seconds cooldown only on rustler bombs. It's 12 by default\n\
		"YELLOW"- Get a fixed radius on all bombs (inc. Rustler) of 12 meters. Normally it's 7.5-10!\n\
		"YELLOW"- Speak with other VIP members through the VIP chat by using '"YELLOW"$"YELLOW"' and text after it!\n\
		"YELLOW"- Get a special \"V.I.P\" numberplate on specially spawned vehicles (i.e. VIP cars)\n\
		"YELLOW"- Get some special chat features like VIP tag and message tags.\n\
		"YELLOW"* Message tags are "WHITE"<w> for white"YELLOW", "RED"<r> for red"YELLOW",\n\
		"GREEN"<g> for green"YELLOW", "BLUE"<b> for blue"YELLOW" and "YELLOW"<y> for yellow\n\
		"YELLOW"- Open crates that are given as a bonus in an instant, get no waiting time anymore!\n\
		"YELLOW"- Unlock the double sawnoff skill level (no need to buy it from the shop anymore!)\n\
		"YELLOW"- Get a special "LIMEGREEN"*VIP*"YELLOW" text label above your head to represent your premium subscription!\n\
		"YELLOW"- Spawn special VIP vehicles like /vcar, /vbike, /vheli, /vboat, /vtc and /vmon\n\
		"YELLOW"- Tune any vehicle with an ease with /vtune or /vcc for car color, or even /vnos to add nitro!\n\
		"YELLOW"- Change your current time/weather using /vtime or /vweather\n\
		"YELLOW"- Support yourself with special VIP weapons with /vweaps\n\
		"YELLOW"- Change your skin anywhere using /vskin\n\
		"YELLOW"- Give yourself a health refill using /vheal, helps in combats.\n\
		"YELLOW"- And much more..!\n\n\
		"WHITE"Interested in those features? Sure you do. Spend a few hours in game to receive VIP coins.\n\
		You also receive VIP coins by ranking up. Read /ranks for more information and use /vshop to buy it.\n\
		You can also donate to our project to receive VIP coins. Thank you <3\n\n\
		"GREEN"Our website definitely has more information: "WEBSITE"", "Browse", "X");
   }

   return 1;
}

CMD:vtune(playerid, params[]) {
	if (PlayerInfo[playerid][pDonorLevel]) {
		if (IsPlayerInAnyVehicle(playerid)) {
			new LVehicleID = GetPlayerVehicleID(playerid), LModel = GetVehicleModel(LVehicleID);
			switch (LModel) {
				case 448, 461, 462, 463, 468, 471, 509, 510, 521, 522, 523, 581, 586, 449: return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_426x);
			}
			Tuneacar(LVehicleID);
			PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
			SetPlayerChatBubble(playerid, "VIP vehicle tuned", 0xFF00FFCC, 100.0, 3000);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_445x);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_362x);
	return 1;
}

CMD:vtc(playerid, params[]) {
	if (PlayerInfo[playerid][pDonorLevel]) {
		if (!IsPlayerInAnyVehicle(playerid)) {
			if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
			PlayerInfo[playerid][pCar] = -1;

			new Float:X, Float:Y, Float:Z, Float:Angle, Tunedcar;
			GetPlayerPos(playerid, X, Y, Z);

			GetPlayerFacingAngle(playerid, Angle);
			Tunedcar = CreateVehicle(560, X, Y, Z, Angle, 1, -1, -1);
			PutPlayerInVehicle(playerid, Tunedcar, 0);

			AddVehicleComponent(Tunedcar, 1028);
			AddVehicleComponent(Tunedcar, 1030);
			AddVehicleComponent(Tunedcar, 1031);
			AddVehicleComponent(Tunedcar, 1138);
			AddVehicleComponent(Tunedcar, 1140);
			AddVehicleComponent(Tunedcar, 1170);
			AddVehicleComponent(Tunedcar, 1028);
			AddVehicleComponent(Tunedcar, 1030);
			AddVehicleComponent(Tunedcar, 1031);
			AddVehicleComponent(Tunedcar, 1138);
			AddVehicleComponent(Tunedcar, 1140);
			AddVehicleComponent(Tunedcar, 1170);
			AddVehicleComponent(Tunedcar, 1080);
			AddVehicleComponent(Tunedcar, 1086);
			AddVehicleComponent(Tunedcar, 1087);
			AddVehicleComponent(Tunedcar, 1010);

			PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
			ChangeVehiclePaintjob(Tunedcar, 0);

			SetVehicleVirtualWorld(Tunedcar, GetPlayerVirtualWorld(playerid));
			LinkVehicleToInterior(Tunedcar, GetPlayerInterior(playerid));

			pVehId[playerid] = PlayerInfo[playerid][pCar] = Tunedcar;
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_433x);
	}
	return 1;
}

CMD:vbike(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());

	if (PlayerInfo[playerid][pDonorLevel]) {
		if (pCooldown[playerid][31] < gettime()) {
			CarSpawner(playerid, 522);
			pCooldown[playerid][31] = gettime() + 35;
			SetPlayerChatBubble(playerid, "Spawned VIP bike", X11_PINK, 120.0, 10000);
		} else {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][31] - gettime());
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vtime(playerid, params[]) {
	if (PlayerInfo[playerid][pDonorLevel]) {
		if (isnull(params)) return ShowSyntax(playerid, "/vtime [hour]");

		new time = strval(params);
		SetPlayerTime(playerid, time, 0);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vweather(playerid, params[]) {
	if (PlayerInfo[playerid][pDonorLevel]) {
		new weather;
		if (sscanf(params, "i", weather)) return ShowSyntax(playerid, "/vweather [weather]");
		if (weather > 45 || weather < 0) return ShowSyntax(playerid, "/vweather [weather id 0-45]");
		SetPlayerWeather(playerid, weather);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vboat(playerid,params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());

	if (PlayerInfo[playerid][pDonorLevel]) {
		if (pCooldown[playerid][5] < gettime()) {
			CarSpawner(playerid, 452);
			pCooldown[playerid][5] = gettime() + 35;
		} else {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][5] - gettime());
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vcar(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());

	if (PlayerInfo[playerid][pDonorLevel]) {
		if (pCooldown[playerid][5] < gettime()) {
			CarSpawner(playerid, 411);
			pCooldown[playerid][5] = gettime() + 35;
			SetPlayerChatBubble(playerid, "Spawned VIP car", X11_PINK, 120.0, 10000);
		} else {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][5] - gettime());
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vmon(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());

	if (PlayerInfo[playerid][pDonorLevel]) {
		if (pCooldown[playerid][5] < gettime()) {
			CarSpawner(playerid, 444);
			pCooldown[playerid][5] = gettime() + 35;
			SetPlayerChatBubble(playerid, "Spawned VIP monster", X11_PINK, 120.0, 10000);
		} else {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][5] - gettime());
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vheli(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());

	if (PlayerInfo[playerid][pDonorLevel]) {
		if (pCooldown[playerid][15] < gettime()) {
			CarSpawner(playerid, 487);
			pCooldown[playerid][15] = gettime() + 35;
			SetPlayerChatBubble(playerid, "Spawned VIP helicopter", X11_PINK, 120.0, 10000);
		} else {
			SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][15] - gettime());
		}
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vskin(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);
    if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if (PlayerInfo[playerid][pDonorLevel]) {
			if (!IsValidSkin(strval(params))) return ShowSyntax(playerid, "/vskin [valid skin id]");
			if (isnull(params)) {
				SetPlayerSkin(playerid, 165);
				NotifyPlayer(playerid, "Use /vskin [ID] to choose another skin.");
			} else {
				SetPlayerSkin(playerid, strval(params));
			}
			SetPlayerChatBubble(playerid, "Changed VIP skin", X11_PINK, 120.0, 10000);
        }  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
    }
    return 1;
}

CMD:vheal(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if (PlayerInfo[playerid][pDonorLevel]) {
			if (pCooldown[playerid][1] < gettime()) {
				SetPlayerHealth(playerid, 100.0);
				pCooldown[playerid][1] = gettime() + 100;
			}
			else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][1] - gettime());
			}

			SetPlayerChatBubble(playerid, "Used VIP health refill", X11_PINK, 120.0, 10000);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	}
	return 1;
}

CMD:vammo(playerid, params[]) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if (PlayerInfo[playerid][pDonorLevel]) {
			if (pCooldown[playerid][7] < gettime()) {
				AddAmmo(playerid);
				GameTextForPlayer(playerid, "~g~ADDED AMMO", 2500, 1);
				pCooldown[playerid][7] = gettime() + 250;
			}
			else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][7] - gettime());
			}

			SetPlayerChatBubble(playerid, "Added VIP ammo", X11_PINK, 120.0, 10000);
		}
		 else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	}
	return 1;
}

CMD:vweaps(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if (PlayerInfo[playerid][pDonorLevel]) {
			if (pCooldown[playerid][11] < gettime()) {
				GivePlayerWeapon(playerid, 26, 150);
				GivePlayerWeapon(playerid, 24, 100);
				GivePlayerWeapon(playerid, 32, 100);
				GivePlayerWeapon(playerid, 35, 1);
				GivePlayerWeapon(playerid, 16, 2);

				pCooldown[playerid][11] = gettime() + 60;
			} else {
				SendGameMessage(playerid, X11_SERV_WARN, MSG_CD_LEFT, pCooldown[playerid][11] - gettime());
			}

			SetPlayerChatBubble(playerid, "Added VIP weapons", X11_PINK, 120.0, 10000);
		}
		 else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	}
	return 1;
}

CMD:vcc(playerid, params[]) {
	if (pDuelInfo[playerid][pDInMatch] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
	if (!IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);

	if (PlayerInfo[playerid][pDonorLevel]) {
		new col[2];
		if (sscanf(params, "ii", col[0], col[1])) return ShowSyntax(playerid, "/vcc [1st color] [2nd color]");
		ChangeVehicleColor(GetPlayerVehicleID(playerid), col[0], col[1]);
		SetPlayerChatBubble(playerid, "Changed vehicle color", X11_PINK, 120.0, 10000);
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
	return 1;
}

CMD:vnos(playerid) {
   if (pDuelInfo[playerid][pDInMatch] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
   if (PlayerInfo[playerid][pLoggedIn] == 1) {
		if (PlayerInfo[playerid][pDonorLevel]) {
			if (!IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
			AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
			SetPlayerChatBubble(playerid, "Added nitro", X11_PINK, 120.0, 10000);
		}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_VIP_LOW_RANK);
   }

   return 1;
}

//VIP Shop

alias:vshop("vhelp", "vinfo")
CMD:vshop(playerid) {
	inline VSub(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext, listitem
		if (!response) return PC_EmulateCommand(pid, "/vshop");
		if (PlayerInfo[pid][pCoins] < 21.00) return SendClientMessage(pid, X11_RED2, "Sorry, you must have at least 21.0 coins for this purchase.");
		if (PlayerInfo[pid][pDonorLevel]) return SendClientMessage(pid, X11_LIMEGREEN, "You are already on the VIP tier.");
		PC_EmulateCommand(pid, "/vshop");
		PlayerInfo[pid][pCoins] -= 21.00;
		PlayerInfo[pid][pCoinsSpent] += 21.00;
		PlayerInfo[pid][pPaymentsAccepted] ++;
		PlayerInfo[pid][pDonorLevel] = 1;
		PlayerPlaySound(pid, 1057, 0.0, 0.0, 0.0);
		SetPlayerChatBubble(pid, "Bought VIP", X11_ORANGE, 300.0, 10000);

		new query[450];
		mysql_format(Database, query, sizeof query, "CREATE EVENT `%d_VSUB` ON SCHEDULE AT CURRENT_TIMESTAMP() + INTERVAL 30 DAY DO UPDATE `Players` SET `DonorLevel` = `DonorLevel`-1 WHERE `ID` = '%d' LIMIT 1", PlayerInfo[pid][pAccountId], PlayerInfo[pid][pAccountId]);
		mysql_tquery(Database, query);

		mysql_format(Database, query, sizeof query, "UPDATE `Players` SET `DonorLevel` = '1' WHERE `ID` = '%d' LIMIT 1", PlayerInfo[pid][pAccountId]);
		mysql_tquery(Database, query);
	}
	inline VShop(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, inputtext
		if (response) {
			switch (listitem) {
				case 0: {
					SendClientMessage(pid, X11_LIMEGREEN, "Selecting Monthly VIP Subscription.");
					Dialog_ShowCallback(pid, using inline VSub, DIALOG_STYLE_MSGBOX,
						""RED2"SvT - Monthly VIP",
						""CYAN"How the subscription works? Pretty simple.\n\n\
						"YELLOW"You subscribe for the VIP tier for 30 days and that requires 21.00 coins a month.\n\
						"GREEN"Not only that but you can earn coins by ranking up, read /ranks for info.\n\
						You receive some coins by playing on the server for a few hours as well.", "Buy", "Back");
				}
			}
		}
	}

	Dialog_ShowCallback(playerid, using inline VShop, DIALOG_STYLE_LIST,
		""RED2"SvT - Premium Shop",
		"Monthly VIP Subscription", ">>", "X");
	return 1;
}

//EO-MODULE

/*
	EVENTS MODULE
*/

//Event Commands

CMD:elist(playerid) {
	new sub_holder[27], string[MEDIUM_STRING_LEN];

	if (EventInfo[E_STARTED]) {
		foreach (new i: ePlayers) {
			format(sub_holder, sizeof(sub_holder), "%s\n", PlayerInfo[i][PlayerName]);
			strcat(string, sub_holder);
		}
	}

	if (Iter_Count(ePlayers)) {
		Dialog_Show(playerid, DIALOG_STYLE_LIST, EventInfo[E_NAME], string, "X", "");
	}  else SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_477x);
	return 1;
}

CMD:rjoin(playerid, params[]) {
	new raceid;
	if (sscanf(params, "i", raceid)) return ShowSyntax(playerid, "/rjoin (info: join a race) [param: race id]");
	if (raceid >= MAX_RACES-1 || raceid < 0 || !RaceOpened[raceid]) return SendClientMessage(playerid, X11_RED_2, "There is not any open race with the specified ID.");
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendClientMessage(playerid, X11_RED_2, "You are not in the battlefield to join a race!");
	if (pRaceId[playerid] != -1) return SendClientMessage(playerid, X11_RED_2, "Sorry, you have an unfinished race.");

	PlayerPlaySound(playerid, 1056, 0.0, 0.0, 0.0);
	if (RaceCheckpointType[raceid][0] == 0) {
		SetPlayerRaceCheckpoint(playerid, 0, RaceCheckpoints[raceid][0][0], RaceCheckpoints[raceid][0][1], RaceCheckpoints[raceid][0][2],
		RaceCheckpoints[raceid][1][0], RaceCheckpoints[raceid][1][1], RaceCheckpoints[raceid][1][2], 10);
	} else {
		SetPlayerRaceCheckpoint(playerid, 3, RaceCheckpoints[raceid][0][0], RaceCheckpoints[raceid][0][1], RaceCheckpoints[raceid][0][2],
		RaceCheckpoints[raceid][1][0], RaceCheckpoints[raceid][1][1], RaceCheckpoints[raceid][1][2], 10);
	}

	new clear_data[E_PLAYER_ENUM];
	pEventInfo[playerid] = clear_data;

	pEventInfo[playerid][P_CP]++;

	new Float: rx = frandom(2.0, -2.0), Float: ry = frandom(2.0, -2.0), Float: rz = frandom(0.2, 0.1);
	new rspawn = random(RaceTotalSpawns[raceid]);
	SetPlayerPos(playerid, RaceSpawns[raceid][rspawn][0] + rx, RaceSpawns[raceid][rspawn][1] + ry, RaceSpawns[raceid][rspawn][2] + rz);
	SetPlayerFacingAngle(playerid, RaceSpawns[raceid][rspawn][3]);

	SetPlayerInterior(playerid, RaceInterior[raceid]);
	SetPlayerVirtualWorld(playerid, 2000 + (raceid));

	GameTextForPlayer(playerid, "~y~STARTING SOON...", 1000, 3);

	pRaceId[playerid] = raceid;

	pEventInfo[playerid][P_RACETIME] = gettime();

	SetTimerEx("PrepareRVeh", 500, false, "i", playerid);

	SetPlayerHealth(playerid, 100.0);
	SetPlayerArmour(playerid, 100.0);
	ResetPlayerWeapons(playerid);
	SetPlayerColor(playerid, 0xFFFF00FF);
	return 1;
}

CMD:join(playerid) {
	if (GetPlayerVirtualWorld(playerid) || GetPlayerInterior(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_478x);
	if (IsPlayerInAnyVehicle(playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_479x);
	if (EventInfo[E_STARTED] != 1 || EventInfo[E_OPENED] != 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_477x);
	if (EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_INVALID) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_480x);
	if (EventInfo[E_TYPE] != 2 && EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_RANDOM && EventInfo[E_SPAWNS] == 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_480x);
	if (EventInfo[E_TYPE] == 2 && !RaceTotalSpawns[MAX_RACES-1]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_480x);

	if (pDuelInfo[playerid][pDInMatch] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INDUEL);
	if (PlayerInfo[playerid][pDeathmatchId] > -1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INDM);
	if (Iter_Contains(ePlayers, playerid)) return 1;
	if (Iter_Contains(CWCLAN1, playerid) || Iter_Contains(CWCLAN2, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INCW);
	if (Iter_Contains(PUBGPlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_COMMAND_INPUBG);
	if (pRaceId[playerid] != -1) return SendClientMessage(playerid, X11_RED_2, "Sorry, you have an unfinished race.");

	new in_proto = 0;

	foreach (new i: teams_loaded) {
		if (PrototypeInfo[i][Prototype_Attacker] == playerid) {
			in_proto = 1;
			break;
		}
	}

	if (in_proto) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_479x);
	if (Iter_Count(ePlayers) >= EventInfo[E_MAX_PLAYERS]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_481x);

	if (AntiSK[playerid]) {
		EndProtection(playerid);
	}

	SetPlayerHealth(playerid, 100);
	SetPlayerArmour(playerid, 100);

	ResetPlayerWeapons(playerid);
	SetPlayerColor(playerid, 0xFFFF00FF);

	SendGameMessage(@pVerified, X11_SERV_INFO, MSG_SERVER_68x, PlayerInfo[playerid][PlayerName], EventInfo[E_NAME]);

	SetPlayerInterior(playerid, EventInfo[E_INTERIOR]);
	SetPlayerVirtualWorld(playerid, EventInfo[E_WORLD]);

	GivePlayerWeapon(playerid, EventInfo[E_WEAP1][0], EventInfo[E_WEAP1][1]);
	GivePlayerWeapon(playerid, EventInfo[E_WEAP2][0], EventInfo[E_WEAP2][1]);
	GivePlayerWeapon(playerid, EventInfo[E_WEAP3][0], EventInfo[E_WEAP3][1]);
	GivePlayerWeapon(playerid, EventInfo[E_WEAP4][0], EventInfo[E_WEAP4][1]);

	if (EventInfo[E_FREEZE] == 1) {
		TogglePlayerControllable(playerid, false);
	} else {
		TogglePlayerControllable(playerid, true);
	}

	Iter_Add(ePlayers, playerid);

	if (EventInfo[E_TYPE] == 2) {
		PlayerPlaySound(playerid, 1056, 0.0, 0.0, 0.0);
		if (RaceCheckpointType[MAX_RACES-1][0] == 0) {
			SetPlayerRaceCheckpoint(playerid, 0, RaceCheckpoints[MAX_RACES-1][0][0], RaceCheckpoints[MAX_RACES-1][0][1], RaceCheckpoints[MAX_RACES-1][0][2],
			RaceCheckpoints[MAX_RACES-1][1][0], RaceCheckpoints[MAX_RACES-1][1][1], RaceCheckpoints[MAX_RACES-1][1][2], 10);
		} else {
			SetPlayerRaceCheckpoint(playerid, 3, RaceCheckpoints[MAX_RACES-1][0][0], RaceCheckpoints[MAX_RACES-1][0][1], RaceCheckpoints[MAX_RACES-1][0][2],
			RaceCheckpoints[MAX_RACES-1][1][0], RaceCheckpoints[MAX_RACES-1][1][1], RaceCheckpoints[MAX_RACES-1][1][2], 10);
		}

		pEventInfo[playerid][P_CP]++;

		new Float: rx = frandom(10.0, -10.0), Float: ry = frandom(10.0, -10.0), Float: rz = frandom(1.0, 0.5);
		new rspawn = random(RaceTotalSpawns[MAX_RACES-1]);
		SetPlayerPos(playerid, RaceSpawns[MAX_RACES-1][rspawn][0] + rx, RaceSpawns[MAX_RACES-1][rspawn][1] + ry, RaceSpawns[MAX_RACES-1][rspawn][2] + rz);
		SetPlayerFacingAngle(playerid, RaceSpawns[MAX_RACES-1][rspawn][3]);

		SetPlayerInterior(playerid, RaceInterior[MAX_RACES-1]);
		SetPlayerVirtualWorld(playerid, 2000 + (MAX_RACES-1));
		pRaceId[playerid] = MAX_RACES-1;

		pEventInfo[playerid][P_RACETIME] = gettime();

		if (PlayerInfo[playerid][pCar] != -1) DestroyVehicle(PlayerInfo[playerid][pCar]);
		PlayerInfo[playerid][pCar] = -1;
	}
	else if (EventInfo[E_TYPE] == 1) {
		new counter[2];

		counter[0] = 0;
		counter[1] = 0;

		foreach(new i: ePlayers) {
			if (pEventInfo[i][P_TEAM] == 0) {
				counter[0]++;
			} else if (pEventInfo[i][P_TEAM] == 1) {
				counter[1]++;
			}
		}

		if (counter[0] > counter[1]) {
			pEventInfo[playerid][P_TEAM] = 1;
		} else if (counter[0] < counter[1]) {
			pEventInfo[playerid][P_TEAM] = 0;
		} else if (counter[0] == counter[1]) {
			pEventInfo[playerid][P_TEAM] = 1;
		}

		switch (pEventInfo[playerid][P_TEAM]) {
			case 0: {
				SetPlayerPos(playerid, SpawnInfo[0][S_COORDS][0], SpawnInfo[0][S_COORDS][1], SpawnInfo[0][S_COORDS][2]);
				SetPlayerFacingAngle(playerid, SpawnInfo[0][S_COORDS][3]);

				SetPlayerInterior(playerid, EventInfo[E_INTERIOR]);
				SetPlayerVirtualWorld(playerid, EventInfo[E_WORLD]);
				SetPlayerColor(playerid, 0x5274FFFF);
			}
			case 1: {
				SetPlayerPos(playerid, SpawnInfo[1][S_COORDS][0], SpawnInfo[1][S_COORDS][1], SpawnInfo[1][S_COORDS][2]);
				SetPlayerFacingAngle(playerid, SpawnInfo[1][S_COORDS][3]);

				SetPlayerInterior(playerid, EventInfo[E_INTERIOR]);
				SetPlayerVirtualWorld(playerid, EventInfo[E_WORLD]);
				SetPlayerColor(playerid, 0xFF1C2BFF);
			}
		}
	} else if (EventInfo[E_TYPE] == 0 && EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_ADMIN) {
		SetPlayerPos(playerid, SpawnInfo[0][S_COORDS][0], SpawnInfo[0][S_COORDS][1], SpawnInfo[0][S_COORDS][2]);
		SetPlayerFacingAngle(playerid, SpawnInfo[0][S_COORDS][3]);

		SetPlayerInterior(playerid, EventInfo[E_INTERIOR]);
		SetPlayerVirtualWorld(playerid, EventInfo[E_WORLD]);
	} else if (EventInfo[E_TYPE] == 0 && EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_RANDOM) {
		if (EventInfo[E_SPAWN_TYPE] == EVENT_SPAWN_RANDOM)
		{
			new Float: rx = frandom(10.0, -10.0), Float: ry = frandom(10.0, -10.0), Float: rz = frandom(1.0, 0.5);
			new rspawn = random(EventInfo[E_SPAWNS]);
			if (RaceSpawns[MAX_RACES-1][rspawn][2] >= 500.0) {
				SetPlayerPos(playerid, RaceSpawns[MAX_RACES-1][rspawn][0], RaceSpawns[MAX_RACES-1][rspawn][1], RaceSpawns[MAX_RACES-1][rspawn][2]);
				SetPlayerFacingAngle(playerid, RaceSpawns[MAX_RACES-1][rspawn][3]);
			}
			else {
				SetPlayerPos(playerid, RaceSpawns[MAX_RACES-1][rspawn][0] + rx, RaceSpawns[MAX_RACES-1][rspawn][1] + ry, RaceSpawns[MAX_RACES-1][rspawn][2] + rz);
				SetPlayerFacingAngle(playerid, RaceSpawns[MAX_RACES-1][rspawn][3]);
			}
		} else {
			new Float: rx = frandom(2.0, -2.0), Float: ry = frandom(2.0, -2.0), Float: rz = frandom(1.0, 0.5);
			if (SpawnInfo[0][S_COORDS][2] >= 500.0) {
				SetPlayerPos(playerid, SpawnInfo[0][S_COORDS][0], SpawnInfo[0][S_COORDS][1], SpawnInfo[0][S_COORDS][2]);
				SetPlayerFacingAngle(playerid, SpawnInfo[0][S_COORDS][3]);
			}
			else {
				SetPlayerPos(playerid, SpawnInfo[0][S_COORDS][0] + rx, SpawnInfo[0][S_COORDS][1] + ry, SpawnInfo[0][S_COORDS][2] + rz);
				SetPlayerFacingAngle(playerid, SpawnInfo[0][S_COORDS][3]);
			}
		}

		SetPlayerInterior(playerid, EventInfo[E_INTERIOR]);
		SetPlayerVirtualWorld(playerid, EventInfo[E_WORLD]);
	}
	return 1;
}

CMD:ewatch(playerid) {
	if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || pDuelInfo[playerid][pDInMatch] == 1) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
	if (PlayerInfo[playerid][pDeathmatchId] >= 0) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
	if (Iter_Contains(ePlayers, playerid) || Iter_Contains(PUBGPlayers, playerid)) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_436x);
	if (PlayerInfo[playerid][pLastHitTick] > gettime()) return SendGameMessage(playerid, X11_SERV_INFO, MSG_JUSTHIT, PlayerInfo[playerid][pLastHitTick] - gettime());
	if (!EventInfo[E_STARTED]) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_477x);
	if (Iter_Count(ePlayers) < 2) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_420x);
	new i = Iter_Random(ePlayers);
	TogglePlayerSpectating(playerid, true);
	PlayerInfo[playerid][pSpecId] = i;
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(i));
	SetPlayerInterior(playerid, GetPlayerInterior(i));
	if (!IsPlayerInAnyVehicle(i)) {
		PlayerSpectatePlayer(playerid, i);
	} else {
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(i));
	}
	SendGameMessage(playerid, X11_SERV_INFO, MSG_EWATCH);
	return 1;
}

//EO-MODULE

/*

	TEAMS MODULE

*/

#include "new/team.inc"

//EO-MODULE

/*

	CLASS MODULE

*/

#include "new/class.inc"

//EO-MODULE

/*

	ACHIEVEMENTS MODULE

*/

//EO-MODULE

#include "new/achievements.inc"

/*

	RANKS MODULE

*/

#include "new/ranks.inc"

//EO-MODULE

/*

	WEAPONS MODULE

*/

#include "new/weapons.inc"

//EO-MODULE

/*

	ITEMS MODULE

*/

#include "new/items.inc"

//EO-MODULE

/*

	ZONES MODULE

*/

#include "new/zones.inc"

//EO-MODULE

/*

	TRADES MODULE

*/

#include "new/trades.inc"

//EO-MODULE

/*

	PROJECTILE MODULE

*/

#include "new/projectile.inc"

//EO-MODULE

//End of File
/* (c) H2O Multiplayer 2018-2020. All rights reserved. */