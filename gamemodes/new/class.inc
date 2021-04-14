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

#if !defined _CLASS_MODULE
    #define _CLASS_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include <YSI_Players\y_groups>
#include <YSI_Visual\y_classes>
#include <map-zones>
#include "../gamemodes/SvT.pwn"

static c_ClassAbilities[MAX_SUB_CLASSES];
static c_Advanced[MAX_SUB_CLASSES] = 0;
static c_Weapon[MAX_SUB_CLASSES] = 0; //Primary
static c_OtherWeapons[MAX_SUB_CLASSES][3]; //Secondary, Grenade, Melee
static c_Skin[MAX_SUB_CLASSES] = 0;
static c_Team[MAX_SUB_CLASSES] = 0;
static c_Type[MAX_SUB_CLASSES] = 0;
static c_AreaName[MAX_SUB_CLASSES][28];
static pClass[MAX_PLAYERS];

enum e_CADefinitions {
    eCA_Ability,
    eCA_AbilityName1[30],
    eCA_AbilityName2[30],
    eCA_AbilityFeature1[128],
    eCA_AbilityFeature2[128]
};

static const c_abilities_definition[][e_CADefinitions] = {
    {
        GROUNDUNIT,
		"Ground Unit",
		"Rifleman",
		"Spawns with sufficient weapons to protect base",
		"Unlock Rhino tanks & get +150 Rhino HP"
	},
	{
        SNIPER,
		"Sniper",
		"Ghost",
		"Headshot enemies",
		"Invisible off the radar"
	},
	{
        MECHANIC,
		"Mechanic",
		"Veteran Mechanic",
		"Repair damaged vehicles using the spraycan",
		"+5 VHP on repairing vehicles & rebuild destroyed radio antennas [/rebuildantenna]"
	},
	{
        JETTROOPER,
		"Jet-Trooper",
		"Veteran Trooper",
		"Unlock jetpack [CMD: /jp]",
		"Pilot seasparrows"
	},
	{
        MEDIC,
		"Paramedic",
		"Medic",
		"In-range teammate healing at 7.5m [/heal]",
		"Out-range teammate healing at 15.0m & automatic self-healing"
	},
	{
        SPY,
		"Spy",
		"Veteran Spy",
		"Disguise enemy teams [/spy or /nospy]",
		"Backstab enemies in their vehicle when at backseat [/stab]"
	},
	{
        DEMOLISHER,
		"Pyroman",
		"Veteran Pyroman",
		"Plant dynamite on ground/in vehicles [/pb or /ex]",
		"Bburn nearby enemy vehicles [CMD: /fr]"
	},
	{
        SCOUT,
		"Scout",
		"Elite Scout",
		"Flashbang [y key], unlock submarines & +7 damage points with sniper",
		"Larger flashbang radius & double sawn-off shotgun"
	},
	{
        SUICIDER,
		"Suicider",
		"Bomber",
		"Suicide [/suicide]",
		"Extra (+4.50m) explosion radius on suicide"
	},
	{
        PILOT,
		"Pilot",
		"Veteran Pilot",
		"Drive air vehicles (seasparrow, hydra, hunter, cropduster, rustler and nevada [/dcp to drop carepack])",
		"Extra (+500hp) on air vehicles (seasparrow, hydra, hunter, cropduster, rustler and nevada)"
	},
	{
        RECON,
		"Recon",
		"Veteran Recon",
		"Invisible off the radar, can find players [/locate] & +7 damage points with sniper",
		"Spawn drone [/drone] and explode it [n key]"
	},
	{
        CUSTODIAN,
		"Sentinel",
		"Custodian",
		"Vest all the nearby teammates in a 10 meters range with +25 AR [/vest]",
		"Vest all the nearby teammates in a 15 meters range with +50 AR [/vest]"
	},
	{
        KAMIKAZE,
		"Kamikaze",
		"Veteran Kamikaze",
		"Rustler self-destruction at a range of 10 meters [r key]",
		"Rustler self-destruction at a range of 15 meters [r key]"
	},
	{
        SUPPORT,
		"Supporter",
		"Veteran Supporter",
		"Support teammates in range of 10 meters [y key]",
		"+5 meters support range & unlock Anti-Air Vehicles"
    },
	{
        NUKEMASTER,
		"Nukemaster",
		"N/A",
		"This guy can use nuclear capabilities and /airstrike",
		"N/A"
	}
};

//Load classes
Class_Load(const class_file[45])
{
    for (new i = 0; i < sizeof(c_abilities_definition); i++) {
        SetSVarInt(c_abilities_definition[i][eCA_AbilityName1], c_abilities_definition[i][eCA_Ability]);
    }
	new File:handle = fopen(class_file, io_read), buf[100];
	if (handle)
	{
		while (fread(handle, buf))
		{
            new team, skin, weapon, secondary, grenade, melee, Float: X, Float: Y, Float: Z, Float: A, ability_profile[25], advanced, type;
			if (sscanf(buf, "p<,>ddddddffffs[25]dd", team, skin, weapon, secondary, grenade, melee, X, Y, Z, A, ability_profile, advanced, type))
			{
				printf("Class (id:%d) failed to load.", Iter_Count(classes_loaded));
			}
            new i = Class_AddForGroup(Team_GetGroup(team), skin, X, Y, Z, A);
            Iter_Add(classes_loaded, i);
            Class_GrantAbility(i, GetSVarInt(ability_profile), advanced);
            c_Weapon[i] = weapon;
            c_OtherWeapons[i][0] = secondary;
            c_OtherWeapons[i][1] = grenade;
            c_OtherWeapons[i][2] = melee;
            c_Skin[i] = skin;
            c_Team[i] = team;
            c_Type[i] = type;

            new MapZone:zone;
            zone = GetMapZoneAtPoint(X, Y, Z);
            GetMapZoneName(zone, c_AreaName[i]);
		}
		printf("Read %d Classes from %s", Iter_Count(classes_loaded), class_file);
		fclose(handle);
	} else printf("File %s does not exist", class_file);
	return 1;
}

Class_Unload()
{
    if (!Iter_Count(classes_loaded)) return 0;
    foreach (new i: classes_loaded) {
        c_ClassAbilities[i] = 0;
        Class_Delete(i);
        Iter_SafeRemove(classes_loaded, i, i);
    }
    return 1;
}

Class_GrantAbility(class_idx, ability_idx, advanced) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    c_ClassAbilities[class_idx] = ability_idx;
    c_Advanced[class_idx] = advanced;
    return 1;
}

Class_GetAbilities(class_idx) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    return c_ClassAbilities[class_idx];
}

Class_GetAbilityNames(class_idx) {
    new buf[MEDIUM_STRING_LEN];
    if (!Iter_Contains(classes_loaded, class_idx)) return buf;
    if (!Class_IsAdvanced(class_idx)) {
        for (new i = 0; i < sizeof(c_abilities_definition); i++) {
            if ((c_ClassAbilities[class_idx] == c_abilities_definition[i][eCA_Ability])) {
                strcat(buf, c_abilities_definition[i][eCA_AbilityName1]);
            }
        }
    } else {
        for (new i = 0; i < sizeof(c_abilities_definition); i++) {
            if ((c_ClassAbilities[class_idx] == c_abilities_definition[i][eCA_Ability])) {
                strcat(buf, c_abilities_definition[i][eCA_AbilityName2]);
            }
        }
    }
    return buf;
}

Class_GetAbilityFeatures(class_idx) {
    new buf[MEDIUM_STRING_LEN];
    if (!Iter_Contains(classes_loaded, class_idx)) return buf;
    for (new i = 0; i < sizeof(c_abilities_definition); i++) {
        if ((c_ClassAbilities[class_idx] == c_abilities_definition[i][eCA_Ability])) {
            if (Class_IsAdvanced(class_idx)) {
                strcat(buf, c_abilities_definition[i][eCA_AbilityFeature2]);
            } else {
                strcat(buf, c_abilities_definition[i][eCA_AbilityFeature1]);
            } 
        }
    }
    return buf;
}

Class_IsAdvanced(class_idx) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    return c_Advanced[class_idx];
}

Class_GetWeapon(class_idx) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    return c_Weapon[class_idx];
}

Class_GetOtherWeapon(class_idx, weapon_idx) {
    if (!Iter_Contains(classes_loaded, class_idx) || 0 > weapon_idx > 2) return 0;
    return c_OtherWeapons[class_idx][weapon_idx];
}

Class_GetSkin(class_idx) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    return c_Skin[class_idx];
}

Class_GetTeam(class_idx) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    return c_Team[class_idx];
}

Class_GetType(class_idx) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    return c_Type[class_idx];
}

Class_LinkToPlayer(playerid, class_idx) {
    if (!Iter_Contains(classes_loaded, class_idx)) return 0;
    pClass[playerid] = class_idx;
    return 1;
}

Class_GetPlayerClass(playerid) { //Not Class_GetPlayer so that it doesn't collide with y_classes
    return pClass[playerid];
}

Class_GetAreaName(class_idx) {
    new buf[MEDIUM_STRING_LEN];
    if (!Iter_Contains(classes_loaded, class_idx)) return buf;
    strcat(buf, c_AreaName[class_idx]);
    return buf;
}

/* (c) H2O Multiplayer 2018-2020. All rights reserved. */