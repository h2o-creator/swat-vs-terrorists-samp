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

#if !defined _RANKS_MODULE
    #define _RANKS_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include <a_mysql>
#include "../gamemodes/SvT.pwn"

static Iterator: ranks_loaded<MAX_RANKS>;
static rank_score[MAX_RANKS] = 0;
static p_PrevScore[MAX_PLAYERS];
static p_PrevRank[MAX_PLAYERS];

Ranks_Generate() {
    new last_rank_score = 0;
    for (new i = 0; i < MAX_RANKS; i++) {
        rank_score[i] = last_rank_score;
        Iter_Add(ranks_loaded, i);
        last_rank_score += 100;
    }
    return 1;
}

Ranks_ReturnName(rank_id) {
    new buf[SMALL_STRING_LEN];
    if (!Iter_Contains(ranks_loaded, rank_id)) return buf;
    format(buf, sizeof(buf), "Level %d", rank_id);
    return buf;
}

Ranks_IsHigher(playerid) {
    if (GetPlayerScore(playerid) > p_PrevScore[playerid]) {
        new i = 0;
        foreach (new x: ranks_loaded) {
            if (p_PrevScore[playerid] >= rank_score[x]) {
                i = x;
            }
        }
        if (i > Ranks_GetPlayer(playerid)) {
            Ranks_GetPlayer(playerid);
            return 1;
        }
    }
    return 0;
}

Ranks_GetPlayer(playerid) {
    new i = 0;
    foreach (new x: ranks_loaded) {
        if (p_PrevScore[playerid] >= rank_score[x]) {
            i = x;
        }
    }
    p_PrevRank[playerid] = i;
    p_PrevScore[playerid] = GetPlayerScore(playerid);
    return i;
}

Ranks_GetScore(rank_id) {
    if (Iter_Contains(ranks_loaded, rank_id)) {
        return rank_score[rank_id];
    }
    return 0;
}

Ranks_ResetPlayer(playerid) {
    p_PrevScore[playerid] = 0;
    p_PrevRank[playerid] = 0;
    return 1;
}

//End of File
/* (c) H2O Multiplayer 2018-2020. All rights reserved. */