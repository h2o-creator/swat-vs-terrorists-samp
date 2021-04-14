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

#if !defined _ZONES_MODULE
    #define _ZONES_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include "../gamemodes/SvT.pwn"

enum e_zones {
    e_zones_team_id,
    e_zones_zone_id,
    e_zones_investment,
    e_zones_expiry,
    e_zones_date
}

static zones_transactions[MAX_TRANSACTIONS][e_zones];
static Iterator: Zones<MAX_ZONES>;
static zones_transactions_loaded = 0;
static ZonesGangZone[MAX_ZONES];

forward LoadZoneTransactions(zone_id);
public LoadZoneTransactions(zone_id) {
    if (cache_num_rows()) {
        for (new i, j = cache_num_rows(); i != j; i++) {
            new get_zone_id, get_team_id, get_investment, get_expiry, get_date;
            cache_get_value_int(i, "ZoneId", get_zone_id);
            cache_get_value_int(i, "TeamId", get_team_id);
            cache_get_value_int(i, "Investment", get_investment);
            cache_get_value_int(i, "Expiry", get_expiry);
            cache_get_value_int(i, "Date", get_date);
            zones_transactions[zones_transactions_loaded][e_zones_team_id] = get_team_id;
            zones_transactions[zones_transactions_loaded][e_zones_zone_id] = get_zone_id;
            zones_transactions[zones_transactions_loaded][e_zones_investment] = get_investment;
            zones_transactions[zones_transactions_loaded][e_zones_expiry] = get_expiry;
            zones_transactions[zones_transactions_loaded][e_zones_date] = get_date;
            zones_transactions_loaded ++;
            if (zones_transactions_loaded == MAX_TRANSACTIONS) {
                break;
            }
        }
    }
    return 1;
}

Zones_Generate() {
    Iter_Clear(Zones);
    zones_transactions_loaded = 0;
    for (new i = 0; i < GetMapZoneCount(); i++) {
        if (IsValidMapZone(MapZone:i)) {
            new query[MEDIUM_STRING_LEN];
            mysql_format(Database, query, sizeof(query), "SELECT * FROM `ZonesTransactions` WHERE `ZoneId` = '%d' ORDER BY `ID` DESC LIMIT 100000", i);
            mysql_tquery(Database, query, "LoadZoneTransactions", "i", i);
            new Float:minx, Float:miny, Float:maxx, Float:maxy, unused;
            GetMapZoneAreaPos(MapZone:i, minx, miny, Float:unused, maxx, maxy, Float:unused);
            ZonesGangZone[i] = GangZoneCreate(minx, miny, maxx, maxy);
            Iter_Add(Zones, i);
        }
    }
    return 1;
}

stock Zones_GetPlayer(playerid) {
    foreach (new i: Zones) {
        if (GetPlayerMapZone(playerid) == MapZone:i) {
            return i;
        }
    }
    return -1;
}

Zones_GetValueForTeam(zone, forteam) {
    if (!Iter_Contains(Zones, zone)) return 0;
    new value = 0;
    for (new i = 0; i < zones_transactions_loaded; i++) {
        if (zones_transactions[i][e_zones_zone_id] == zone && zones_transactions[i][e_zones_team_id] == forteam
            && zones_transactions[i][e_zones_expiry] > gettime()) {
            value += zones_transactions[i][e_zones_investment];
        }
    }
    return value;
}

Zones_AddValueForTeam(zone, forteam, value) {
    if (!Iter_Contains(Zones, zone) || zones_transactions_loaded == MAX_TRANSACTIONS) return 0;
    Zones_GetValueForTeam(zone, forteam);
    zones_transactions[zones_transactions_loaded][e_zones_zone_id] = zone;
    zones_transactions[zones_transactions_loaded][e_zones_team_id] = forteam;
    zones_transactions[zones_transactions_loaded][e_zones_investment] = value;
    zones_transactions[zones_transactions_loaded][e_zones_expiry] = gettime() + ZONE_VALUE_PERIOD;
    zones_transactions[zones_transactions_loaded][e_zones_date] = gettime();
    zones_transactions_loaded ++;

    new query[MEDIUM_STRING_LEN];
    mysql_format(Database, query, sizeof(query), "INSERT INTO `ZonesTransactions`(`ZoneId`,`TeamId`,`Investment`,`Expiry`,`Date`) \
        VALUES('%d','%d','%d','%d','%d')", zone, forteam, value, gettime() + ZONE_VALUE_PERIOD, gettime());
    mysql_tquery(Database, query);
    return 1;
}

Zones_GetValue(zone) {
    if (!Iter_Contains(Zones, zone)) return 0;
    new value = 0;
    for (new i = 0; i < zones_transactions_loaded; i++) {
        if (zones_transactions[i][e_zones_zone_id] == zone && zones_transactions[i][e_zones_expiry] > gettime()) {
            value += zones_transactions[i][e_zones_investment];
        }
    }
    return value;
}

Zones_GetOwner(zone) {
    if (!Iter_Contains(Zones, zone)) return -1;
    if (Zones_IsPerm(zone) != -1) return Zones_IsPerm(zone);

    new value = -1;
    new order_teams[MAX_TEAMS][2];
    foreach(new i: teams_loaded) {
        order_teams[i][0] = Zones_GetValueForTeam(zone, i);
        order_teams[i][1] = i;
    }
    QuickSort_Pair(order_teams, true, 0, Iter_Count(teams_loaded));
    if (order_teams[0][0] >= MIN_ZONE_VALUE) {
        value = order_teams[0][1];
    }
    return value;
}

Zones_ShowForPlayer(playerid) {
    if (!Iter_Count(Zones)) return 0;
    foreach (new i: Zones) {
        if (Zones_GetOwner(i) == -1) {
            GangZoneShowForPlayer(playerid, ZonesGangZone[i], ALPHA(-1, 100));
        } else {
            GangZoneShowForPlayer(playerid, ZonesGangZone[i], ALPHA(Team_GetColor(Zones_GetOwner(i)), 100));
        }
    }
    return 1;
}

Zones_IsPerm(zone) {
    foreach (new i: teams_loaded) {
        if (Team_GetMapZone(i) == zone) {
            return i;
        }
    }
    return -1;
}

Zones_GetTeamGangZone(team) {
    if (!Iter_Contains(teams_loaded, team)) return 0;
    new gz;
    foreach (new i: Zones) {
        if (Zones_IsPerm(i) && Zones_GetOwner(i) == team) {
            gz = ZonesGangZone[i];
        }
    }
    return gz;
}

Zones_ShowOffer(playerid) {
    //Time to process all these functions at this point: Show the offer for the zone that the player is in
    //Say the player enters a zone; that is valid, they will be displayed a dialog that includes the following:
    //Percentage of ownership of each team separately, current owner, and the value that is to be invested in (by the player)
    //The platform of this module supports too many things already, such as getting owner and displaying borders
    //What should be there is calculating asset value per the designated period of time
    //So, every 5 minutes, a player will get $250 per zone that is owned by their team
    //That sums up to $90,000 per hour for owning 30 zones!
    new MapZone: i, zone_name[28];
    i = GetPlayerMapZone(playerid);
    GetMapZoneName(i, zone_name);
    if (!Iter_Contains(Zones, _:i)) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NON_EXISTENT_ZONE);
    if (Zones_IsPerm(_:i) != -1) return 0;

    //The player is inside a zone now, proceed
    new proposed_value;

    inline ProposeValueDialog(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused dialogid, listitem
        if (!response) return 0;
        if (!IsNumeric(inputtext)) return SendGameMessage(pid, X11_SERV_ERR, ERR_NON_NUMERIC_VALUE);
        proposed_value = strval(inputtext);
        if (MIN_TRANSC_VALUE > proposed_value > MAX_TRANSC_VALUE || GetPlayerCash(pid) < proposed_value) return SendGameMessage(pid, X11_SERV_ERR, ERR_OUT_OF_RANGE_VALUE, MIN_TRANSC_VALUE, MAX_TRANSC_VALUE);
        if (Zones_GetLastTransactionDate(_:i) != 0 && Zones_GetLastTransactionDate(_:i) > gettime() && (Zones_GetLastTransactionDate(_:i) - gettime()) > ZONE_PEACE_PERIOD) return SendGameMessage(pid, X11_SERV_ERR, PEACE_UNREACHED, Zones_GetLastTransactionDate(_:i) - gettime());
        GivePlayerCash(pid, -proposed_value);
        Zones_AddValueForTeam(_:i, Team_GetPlayer(pid), proposed_value);
        if (Zones_GetOwner(_:i) == -1) {
            GangZoneShowForAll(ZonesGangZone[_:i], ALPHA(-1, 100));
            PlayerInfo[playerid][pCaptureAssists] ++;
            if (PlayerInfo[playerid][pCaptureAssists] > PlayerInfo[playerid][pHighestCaptureAssists]) {
                PlayerInfo[playerid][pHighestCaptureAssists] = PlayerInfo[playerid][pCaptureAssists];
            }
        } else {
            GangZoneShowForAll(ZonesGangZone[_:i], ALPHA(Team_GetColor(Zones_GetOwner(_:i)), 100));
            PlayerInfo[playerid][pZonesCaptured] ++;
            PlayerInfo[playerid][pCaptureStreak] ++;
            if (PlayerInfo[playerid][pCaptureStreak] > PlayerInfo[playerid][pHighestCaptures]) {
                PlayerInfo[playerid][pHighestCaptures] = PlayerInfo[playerid][pCaptureStreak];
            }
            SuccessAlert(playerid);
        }
        SendGameMessage(pid, X11_SERV_SUCCESS, INVEST_SUCCESSFUL, proposed_value, zone_name);
        SendGameMessage(@pVerified, X11_SERV_SUCCESS, INVEST_SUCCESSFUL_FORALL, PlayerInfo[pid][PlayerName], pid, proposed_value, zone_name);
    }

    //The main interface (introduction) to the investment feature
    new buf[LARGE_STRING_LEN];
    format(buf, sizeof(buf), "You are now trying to invest in %s which is worth $%d.\n\
    This zone is property of %s, with an investment of $%d.\n\
    Your team invested $%d. Invest more? Write a value between %d and %d.\n\n\
    This investment will expire in approx. 24 hours, automatically.\n\
    The team that invests more, manages to acquire the zone for longer periods of time.\n\
    You will earn $250 per zone owned by your team once in 5 minutes.\n\
    There's a minimum investment of 1 million to successfully own an area!",
    zone_name,
    Zones_GetValue(_:i),
    Zones_GetOwner(_:i) == -1 ? "None" : Team_GetName(Zones_GetOwner(_:i)),
    Zones_GetOwner(_:i) == -1 ? 0 : Zones_GetValueForTeam(_:i, Zones_GetOwner(_:i)),
    Zones_GetValueForTeam(_:i, Team_GetPlayer(playerid)),
    MIN_TRANSC_VALUE,
    MAX_TRANSC_VALUE);
    Dialog_ShowCallback(playerid, using inline ProposeValueDialog, DIALOG_STYLE_INPUT,
        "Invest in zone", buf, ">>", "X");
    return 1;
}

task Zones_Ensure[300000]() {
    foreach (new i: Zones) {
        foreach (new x: Player) {
            new player_reward = 0, player_zones = 0;
            if (Team_GetPlayer(x) == Zones_GetOwner(i)) {
                player_reward += 250;
                player_zones ++;
            }
            if (player_reward > 0) {
                GivePlayerCash(x, player_reward);
                SendGameMessage(x, X11_SERV_SUCCESS, ZONES_REWARD_250, player_zones, formatInt(player_reward));
            }
        }
    }
    return 1;
}

Zones_GetLastTransactionDate(zone) {
    if (!Iter_Contains(Zones, zone)) return 0;
    new value = 0;
    for (new i = zones_transactions_loaded; i > -1; i--) {
        if (zones_transactions[i][e_zones_zone_id] == zone && zones_transactions[i][e_zones_expiry] > gettime()) {
            value = zones_transactions[i][e_zones_date];
            break;
        }
    }
    return value;
}


/* (c) H2O Multiplayer 2018-2020. All rights reserved. */