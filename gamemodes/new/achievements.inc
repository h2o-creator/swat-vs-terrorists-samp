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

#if !defined _ACHIEVEMENTS_MODULE
    #define _ACHIEVEMENTS_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include <a_mysql>
#include "../gamemodes/SvT.pwn"

#define MAX_ACHIEVEMENTS (25) // I think this is sufficient for the current setup
//This limit MIGHT be hardcoded below, so make sure it's changed as well

enum ach_intrnl_enum
{
    AchId,
    AchName[25],
    AchDesc[255],
    AchScore,
    AchCash,
    AchValue
}

static ach_intrnl_arr[MAX_ACHIEVEMENTS][ach_intrnl_enum];
static _achs_loaded;
static player_ach_data[MAX_PLAYERS][MAX_ACHIEVEMENTS];

forward Achievements_OnLoad();
public Achievements_OnLoad()
{
    if (cache_num_rows())
    {
        for (new i, j = cache_num_rows(); i != j; i++)
        {
            ach_intrnl_arr[_achs_loaded][AchName][0] = EOS;
            ach_intrnl_arr[_achs_loaded][AchDesc][0] = EOS;
            cache_get_value_int(i, "ID", ach_intrnl_arr[_achs_loaded][AchId]);
            cache_get_value(i, "AchName", ach_intrnl_arr[_achs_loaded][AchName], 25);
            cache_get_value(i, "AchDesc", ach_intrnl_arr[_achs_loaded][AchDesc], 255);
            cache_get_value_int(i, "AchScore", ach_intrnl_arr[_achs_loaded][AchScore]);
            cache_get_value_int(i, "AchCash", ach_intrnl_arr[_achs_loaded][AchCash]);
            cache_get_value_int(i, "AchValue", ach_intrnl_arr[_achs_loaded][AchValue]);
            _achs_loaded ++;
        }
    }
    return 1;
}

forward Achievements_OnPlayerInit(playerid);
public Achievements_OnPlayerInit(playerid)
{
    if (cache_num_rows())
    {
        for (new i, j = cache_num_rows(); i != j; i++)
        {
            new ach_id;
            cache_get_value_int(i, "AchId", ach_id);
            for (new x = 0; x < _achs_loaded; x++) {
                if (ach_intrnl_arr[x][AchId] == ach_id){
                    cache_get_value_int(i, "AchValue", player_ach_data[playerid][x]);
                    break;
                }
            }
        }
        return 1;
    }
    for (new i = 0; i < _achs_loaded; i++)
    {
        new query[SMALL_STRING_LEN];
        mysql_format(Database, query, sizeof(query), "INSERT INTRO `PlayerAchievements` (`PlayerId`, `AchId`) VALUES ('%d', '%d')", 
            PlayerInfo[playerid][pAccountId], ach_intrnl_arr[i][AchId]);
        mysql_tquery(Database, query);
    }
    return 1;
}

Achievements_Load()
{
    if (Database == MYSQL_INVALID_HANDLE) return 0;
    _achs_loaded = 0;
    mysql_tquery(Database, "SELECT * FROM `Achievements` LIMIT 25", "Achievements_OnLoad");
    return 1;
}

Achievements_InitializePlayer(playerid)
{
    if (Database == MYSQL_INVALID_HANDLE) return 0;
    if (!_achs_loaded) return 0;
    for (new i = 0; i < MAX_ACHIEVEMENTS; i++)
    {
        player_ach_data[playerid][i] = 0;
    }
    new query[SMALL_STRING_LEN];
    mysql_format(Database, query, sizeof(query), "SELECT * FROM `PlayerAchievements` WHERE `PlayerId` = '%d' LIMIT 1", PlayerInfo[playerid][pAccountId]);
    mysql_tquery(Database, query, "Achievements_OnPlayerInit", "i", playerid);
    return 1;
}

Achievements_GivePlayer(playerid, const ach[25], value)
{
    if (Database == MYSQL_INVALID_HANDLE) return 0;
    if (!_achs_loaded) return 0;
    if (value <= 0) return 0;
    for (new i = 0; i < _achs_loaded; i++)
    {
        if (ach_intrnl_arr[i][AchName][0] == ach[0] && player_ach_data[playerid][i] < ach_intrnl_arr[i][AchValue])
        {
            player_ach_data[playerid][i] ++;
            if (player_ach_data[playerid][i] >= ach_intrnl_arr[i][AchValue])
            {
                Achievements_OnAchieve(playerid, i);
            }
            new query[SMALL_STRING_LEN];
            mysql_format(Database, query, sizeof(query), "UPDATE `PlayerAchievements` SET `AchValue`=`AchValue`+%d WHERE `AchId` = '%d' AND `PlayerId` = '%d' LIMIT 1", value, ach_intrnl_arr[i][AchId], PlayerInfo[playerid][pAccountId]);
            mysql_tquery(Database, query);
            break;
        }
    }
    return 1;
}

Achievements_OnAchieve(playerid, achidx)
{
    new _display[SMALL_STRING_LEN];
    format(_display, sizeof(_display), MSG_ACH_PLAYER, ach_intrnl_arr[achidx][AchName], ach_intrnl_arr[achidx][AchScore], formatInt(ach_intrnl_arr[achidx][AchCash]));
    SendClientMessage(playerid, X11_SERV_INFO, _display);
    GivePlayerScore(playerid, ach_intrnl_arr[achidx][AchScore]);
    GivePlayerCash(playerid, ach_intrnl_arr[achidx][AchCash]);
    return 1;
}

Achievements_List()
{
    new array[1024];
    if (!_achs_loaded) return array;
    format(array, 1024, "Achievement\tDescription\tScore\tCash ($)\n");
    for (new i = 0; i < _achs_loaded; i++)
    {
        format(array, 1024, "%s%s\t%s\t%d\t$%d\n", array, ach_intrnl_arr[i][AchName], ach_intrnl_arr[i][AchDesc],
        ach_intrnl_arr[i][AchScore], ach_intrnl_arr[i][AchCash]);
    }
    return array;
}

//End of File
/* (c) H2O Multiplayer 2018-2020. All rights reserved. */