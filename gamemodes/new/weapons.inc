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

#if !defined _WEAPONS_MODULE
    #define _WEAPONS_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include "../gamemodes/SvT.pwn"

#define MELEE_FORMULA   (1 * 1000)
#define BULLET_COST_FORMULA(%0)  (floatround(s_WeaponDamage[%0], floatround_round) * 10)
#define BULLET_FORMULA(%0)  (floatround(s_WeaponDamage[%0], floatround_round) * 1000)

enum e_weapons {
    e_weapons_ammo,
    e_weapons_price
};
static weapons[MAX_WEAPONS][e_weapons];
static p_weapons[MAX_PLAYERS][MAX_WEAPONS];

//weapon-config
static Float:s_WeaponDamage[] = {
	1.0, // 0 - Fist
	1.0, // 1 - Brass knuckles
	1.0, // 2 - Golf club
	1.0, // 3 - Nitestick
	1.0, // 4 - Knife
	1.0, // 5 - Bat
	1.0, // 6 - Shovel
	1.0, // 7 - Pool cue
	1.0, // 8 - Katana
	1.0, // 9 - Chainsaw
	1.0, // 10 - Dildo
	1.0, // 11 - Dildo 2
	1.0, // 12 - Vibrator
	1.0, // 13 - Vibrator 2
	1.0, // 14 - Flowers
	1.0, // 15 - Cane
	82.5, // 16 - Grenade
	0.0, // 17 - Teargas
	1.0, // 18 - Molotov
	9.9, // 19 - Vehicle M4 (custom)
	46.2, // 20 - Vehicle minigun (custom)
	0.0, // 21
	8.25, // 22 - Colt 45
	13.2, // 23 - Silenced
	46.2, // 24 - Deagle
	3.3, // 25 - Shotgun
	3.3, // 26 - Sawed-off
	4.95, // 27 - Spas
	6.6, // 28 - UZI
	8.25, // 29 - MP5
	9.9, // 30 - AK47
	9.9, // 31 - M4
	6.6, // 32 - Tec9
	24.75, // 33 - Cuntgun
	41.25, // 34 - Sniper
	82.5, // 35 - Rocket launcher
	82.5, // 36 - Heatseeker
	1.0, // 37 - Flamethrower
	46.2, // 38 - Minigun
	82.5, // 39 - Satchel
	0.0, // 40 - Detonator
	0.33, // 41 - Spraycan
	0.33, // 42 - Fire extinguisher
	0.0, // 43 - Camera
	0.0, // 44 - Night vision
	0.0, // 45 - Infrared
	0.0, // 46 - Parachute
	0.0, // 47 - Fake pistol
	2.64, // 48 - Pistol whip (custom)
	9.9, // 49 - Vehicle
	330.0, // 50 - Helicopter blades
	82.5, // 51 - Explosion
	1.0, // 52 - Car park (custom)
	1.0, // 53 - Drowning
	165.0  // 54 - Splat
};

Weapons_Generate() {
    for (new i = 1; i < MAX_WEAPONS; i++) {
        if (IsBulletWeapon(i)) {
            weapons[i][e_weapons_ammo] = BULLET_COST_FORMULA(i);
            weapons[i][e_weapons_price] = BULLET_FORMULA(i);
            Iter_Add(allowed_weapons, i);
        } else if (IsValidWeapon(i)) {
            weapons[i][e_weapons_ammo] = 1;
            weapons[i][e_weapons_price] = MELEE_FORMULA;
            Iter_Add(allowed_weapons, i);
        }
    }
    return 1;
}

Weapons_GetAmmo(weaponid) {
    if (Iter_Contains(allowed_weapons, weaponid)) {
        return weapons[weaponid][e_weapons_ammo];
    } else {
        return 0;
    }
}

Weapons_GetPrice(weaponid) {
    if (Iter_Contains(allowed_weapons, weaponid)) {
        return weapons[weaponid][e_weapons_price];
    } else {
        return 0;
    }
}

forward Weapons_OnPlayerSave(playerid, weaponid, ammo);
public Weapons_OnPlayerSave(playerid, weaponid, ammo) {
    p_weapons[playerid][weaponid] = ammo;
    return 1;
}

forward Weapons_OnPlayerLoad(playerid);
public Weapons_OnPlayerLoad(playerid) {
    if (!cache_num_rows()) return 0;
    for (new i = 0, j = cache_num_rows(); i != j; i++) {
        new weaponid, ammo;
        cache_get_value_int(i, "Weapon", weaponid);
        cache_get_value_int(i, "Ammo", ammo);
        p_weapons[playerid][weaponid] = ammo;
    }
    return 1;
}

forward Weapons_OnPlayerHave(playerid, weaponid, ammo);
public Weapons_OnPlayerHave(playerid, weaponid, ammo) {
    new query[MEDIUM_STRING_LEN];
    if (cache_num_rows()) {
        mysql_format(Database, query, sizeof(query), "UPDATE `PlayersWeapons` SET `Ammo` = `Ammo`+'%d' WHERE `Weapon` = '%d' AND `Player` = '%d' LIMIT 1", ammo, weaponid, PlayerInfo[playerid][pAccountId]);
        mysql_tquery(Database, query);
        p_weapons[playerid][weaponid] += ammo;
    } else {
        mysql_format(Database, query, sizeof(query), "INSERT INTO `PlayersWeapons` (`Player`,`Weapon`,`Ammo`,`Time`) VALUES ('%d','%d','%d','%d')",
            PlayerInfo[playerid][pAccountId], weaponid, ammo, gettime());
        mysql_tquery(Database, query, "Weapons_OnPlayerSave", "iii", playerid, weaponid, ammo);
    }
    return 1;
}

Weapons_SavePlayer(playerid, weaponid, ammo) {
    if (!pVerified[playerid] || !Iter_Contains(allowed_weapons, weaponid) || ammo <= 0) return 0;
    new query[MEDIUM_STRING_LEN];
    mysql_format(Database, query, sizeof(query), "SELECT * FROM `PlayersWeapons` WHERE `Player` = '%d' AND `Weapon` = '%d'", PlayerInfo[playerid][pAccountId], weaponid);
    mysql_tquery(Database, query, "Weapons_OnPlayerHave", "iii", playerid, weaponid, ammo);
    return 1;
}

Weapons_LoadPlayer(playerid) {
    if (!pVerified[playerid]) return 0;
    new query[MEDIUM_STRING_LEN];
    mysql_format(Database, query, sizeof(query), "SELECT * FROM `PlayersWeapons` WHERE `Player` = '%d' AND `Ammo` != '0'", PlayerInfo[playerid][pAccountId]);
    mysql_tquery(Database, query, "Weapons_OnPlayerLoad", "i", playerid);
    return 1;
}

Weapons_ExitPlayer(playerid) {
    for (new i = 0; i < MAX_WEAPONS; i++) {
        if (p_weapons[playerid][i] > 0) {
            new query[MEDIUM_STRING_LEN];
            mysql_format(Database, query, sizeof(query), "UPDATE `PlayersWeapons` SET `Ammo` = '%d' WHERE `Weapon` = '%d' AND `Player` = '%d'", p_weapons[playerid][i], i, PlayerInfo[playerid][pAccountId]);
            mysql_tquery(Database, query);
        }
    }
    return 1;
}

Weapons_LowerAmmo(playerid, weaponid) {
    if (Iter_Contains(allowed_weapons, weaponid) && p_weapons[playerid][weaponid] > 0 && IsPlayerInMode(playerid, MODE_BATTLEFIELD)) {
        new weap, ammo;
        GetPlayerWeaponData(playerid, GetWeaponSlot(weaponid), weap, ammo);
        if (weap != weaponid || ammo > p_weapons[playerid][weaponid]) return 0;
        p_weapons[playerid][weaponid]--;
    }
    return 1;
}

Weapons_ResetAmmo(playerid, weaponid) {
    if (Iter_Contains(allowed_weapons, weaponid) && p_weapons[playerid][weaponid] > 0) {
        p_weapons[playerid][weaponid] = 0;
    }
    return 1;
}

Weapons_ReduceAmmo(playerid, weaponid, amount) {
    if (Iter_Contains(allowed_weapons, weaponid) && p_weapons[playerid][weaponid] > 0) {
        p_weapons[playerid][weaponid] -= amount;
        if (p_weapons[playerid][weaponid] < 0) {
            p_weapons[playerid][weaponid] = 0;
        }
    }
    return 1;
}

Weapons_GiveWeapons(playerid) {
    for (new i = 0; i < MAX_WEAPONS; i++) {
        if (p_weapons[playerid][i] > 0) {
			new weapon, ammo;
			GetPlayerWeaponData(playerid, GetWeaponSlot(i), weapon, ammo);
			if (weapon && weapon != i) return 0;
            GivePlayerWeapon(playerid, i, p_weapons[playerid][i]);
        }
    }
    return 1;
}

Weapons_PlayerHas(playerid, weaponid) {
    if (p_weapons[playerid][weaponid] > 0) {
        return p_weapons[playerid][weaponid];
    }
    return 0;
}

Weapons_IsValid(string:weapon_name[]) {
    foreach (new i: allowed_weapons) {
        if (!strcmp(ReturnWeaponName(i), weapon_name, true) && !isnull(weapon_name)) {
            return i;
        }
    }
    return -1;
}

/* (c) H2O Multiplayer 2018-2020. All rights reserved. */