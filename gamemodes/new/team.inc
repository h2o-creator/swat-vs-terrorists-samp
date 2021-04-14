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

#if !defined _TEAM_MODULE
    #define _TEAM_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include <YSI_Players\y_groups>
#include "../gamemodes/SvT.pwn"

enum E_TEAM_ENUM {
	Team_Name[45],
	Chat_Bub[17],

	Team_Color,

	Float: Team_MapArea[4],

	Team_MainSkin,

	//Non-modifiable-constants
	Team_Area,
	Team_Waypoint,
	Group: Team_Group,
    MapZone: Team_MapZone
};
static TeamInfo[MAX_TEAMS][E_TEAM_ENUM];

//Create team
Team_Create(const team_name[45])
{
	if (Iter_Count(teams_loaded) >= MAX_TEAMS) return printf("Can't create team \"%s\". Exceeded MAX_TEAMS value.", team_name);
	new file_name[45+4];
	strcat(file_name, team_name);
	strcat(file_name, ".txt");
	new File:handle = fopen(file_name, io_read),
		buf[42 * 42];
	if(handle)
	{
		while(fread(handle, buf)) {
            //Read

            new i = Iter_Free(teams_loaded);

			if (sscanf(buf, "p<,>s[45]s[17]xffffdfffffffffff",
			TeamInfo[i][Team_Name], TeamInfo[i][Chat_Bub], TeamInfo[i][Team_Color],
			TeamInfo[i][Team_MapArea][0], TeamInfo[i][Team_MapArea][1], TeamInfo[i][Team_MapArea][2], TeamInfo[i][Team_MapArea][3],
			TeamInfo[i][Team_MainSkin],
			ShopInfo[i][Shop_Pos][0], ShopInfo[i][Shop_Pos][1], ShopInfo[i][Shop_Pos][2],
			AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2], AntennaInfo[i][Antenna_Pos][3],
			PrototypeInfo[i][Prototype_Pos][0], PrototypeInfo[i][Prototype_Pos][1], PrototypeInfo[i][Prototype_Pos][2], PrototypeInfo[i][Prototype_Pos][3]))
			{
				return printf("Can't create team \"%s\". Invalid parameters.", team_name);
			}		

            //Generate
            new Float: X, Float: Y;
            GetAreaCenter(TeamInfo[i][Team_MapArea][0], TeamInfo[i][Team_MapArea][1], TeamInfo[i][Team_MapArea][2], TeamInfo[i][Team_MapArea][3], X, Y);
            TeamInfo[i][Team_MapZone] = GetMapZoneAtPoint(X, Y, 0.0);
            printf("mapzone;%d team;%d", _:TeamInfo[i][Team_MapZone], i);
            TeamInfo[i][Team_Area] = CreateDynamicRectangle(TeamInfo[i][Team_MapArea][0], TeamInfo[i][Team_MapArea][1], TeamInfo[i][Team_MapArea][2], TeamInfo[i][Team_MapArea][3]);
            new title[90];
            format(title, sizeof(title), "%s\n"IVORY"Team Shop", TeamInfo[i][Team_Name]);
            ShopInfo[i][Shop_Label] = CreateDynamic3DTextLabel(title, TeamInfo[i][Team_Color], ShopInfo[i][Shop_Pos][0], ShopInfo[i][Shop_Pos][1], ShopInfo[i][Shop_Pos][2], 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0);
            ShopInfo[i][Shop_Id] = CreatePickup(1210, 1, ShopInfo[i][Shop_Pos][0], ShopInfo[i][Shop_Pos][1], ShopInfo[i][Shop_Pos][2], -1);
            CreateDynamicMapIcon(ShopInfo[i][Shop_Pos][0], ShopInfo[i][Shop_Pos][1], ShopInfo[i][Shop_Pos][2], 6, 0, 0, 0, -1, 150.0, MAPICON_LOCAL);
            ShopInfo[i][Shop_Area] = CreateDynamicSphere(ShopInfo[i][Shop_Pos][0], ShopInfo[i][Shop_Pos][1], ShopInfo[i][Shop_Pos][2],5.0,BF_WORLD,0);
            ShopActors[i] = CreateActor(TeamInfo[i][Team_MainSkin], (ShopInfo[i][Shop_Pos][0] + 2.0 * floatsin(90.0, degrees)), ShopInfo[i][Shop_Pos][1], ShopInfo[i][Shop_Pos][2], 90.0);
            format(title, sizeof(title), "%s\n"IVORY"Radio Antenna", TeamInfo[i][Team_Name]);
            AntennaInfo[i][Antenna_Label] = CreateDynamic3DTextLabel(title, TeamInfo[i][Team_Color], AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2], 50.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0);
            CA_FindZ_For2DCoord(AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2]);
            AntennaInfo[i][Antenna_Id] = CreateDynamicObject(13758, AntennaInfo[i][Antenna_Pos][0], AntennaInfo[i][Antenna_Pos][1], AntennaInfo[i][Antenna_Pos][2], 0.0, 0.0, AntennaInfo[i][Antenna_Pos][3]);
            AntennaInfo[i][Antenna_Exists] = 1;
            AntennaInfo[i][Antenna_Hits] = 0;
            PrototypeInfo[i][Prototype_Id] = AddStaticVehicle(428, PrototypeInfo[i][Prototype_Pos][0], PrototypeInfo[i][Prototype_Pos][1], PrototypeInfo[i][Prototype_Pos][2],
            PrototypeInfo[i][Prototype_Pos][3], 1, 2);
            PrototypeInfo[i][Prototype_Attacker] = INVALID_PLAYER_ID;
            SetVehicleHealth(PrototypeInfo[i][Prototype_Id], 1500.0);
            new owner[100];
            format(owner, sizeof(owner), "%s\n"IVORY"Prototype", TeamInfo[i][Team_Name]);
            PrototypeInfo[i][Prototype_Text] = CreateDynamic3DTextLabel(owner, TeamInfo[i][Team_Color], PrototypeInfo[i][Prototype_Pos][0], PrototypeInfo[i][Prototype_Pos][1], PrototypeInfo[i][Prototype_Pos][2], 50.0, INVALID_PLAYER_ID, PrototypeInfo[i][Prototype_Id], 1, 0, 0);
            CreateDynamicMapIcon(PrototypeInfo[i][Prototype_Pos][0], PrototypeInfo[i][Prototype_Pos][1], PrototypeInfo[i][Prototype_Pos][2], 51, 0, 0, 0, -1, 150.0, MAPICON_LOCAL);
            PrototypeInfo[i][Prototype_Cooldown] = gettime();
            TeamInfo[i][Team_Group] = Group_Create(TeamInfo[i][Team_Name]);

            Iter_Add(teams_loaded, i);
		}
		fclose(handle);
	}
	else
	{
		printf("The file \"%s.txt\" does not exists, or can't be opened.", team_name);
	}
	return 1;
}

Group: Team_GetGroup(team) {
    if (!Iter_Contains(teams_loaded, team)) return Group:0;
    return TeamInfo[team][Team_Group];
}

stock Group: Team_GetPlayerGroup(playerid)
{
    if (!Iter_Contains(teams_loaded, team)) return Group:0;
    foreach (new i: teams_loaded)
    {
        if (Group_GetPlayer(TeamInfo[i][Team_Group], playerid))
        {
            return TeamInfo[i][Team_Group];
        }
    }
    return Group:0;
}

Team_GetPlayer(playerid)
{
    if (!Iter_Count(teams_loaded)) return 0;
    foreach (new i: teams_loaded)
    {
        if (Group_GetPlayer(TeamInfo[i][Team_Group], playerid))
        {
            return i;
        }
    }
    return -1;
}

Team_SetPlayer(playerid, team)
{
    if (!Iter_Contains(teams_loaded, team)) return 0;
    Team_ResetPlayer(playerid);
    if (!Group_GetPlayer(TeamInfo[team][Team_Group], playerid))
    {
        Group_SetPlayer(TeamInfo[team][Team_Group], playerid, true);
    }
    return 1;
}

Team_AddPlayerToBalanced(playerid)
{
    if (!Iter_Count(teams_loaded)) return 0;
    if (Iter_Count(teams_loaded) == 1) {
        Team_SetPlayer(playerid, Iter_Random(teams_loaded));
        return 1;
    }
    if (Team_GetPlayer(playerid) != -1) {
        new old = Team_GetPlayer(playerid);
        Team_SetPlayer(playerid, Team_NicestTeam(Team_GetPlayer(playerid)));
        if (Team_GetPlayer(playerid) != old) {
            Class_Reprocess(playerid);
        }
    } else {
        Team_SetPlayer(playerid, Team_NicestTeam(-1));
        Class_Reprocess(playerid);
    }
    return 1;
}

Team_ResetPlayer(playerid)
{
    if (!Iter_Count(teams_loaded)) return 0;
    foreach (new i: teams_loaded)
    {
        if (Group_GetPlayer(TeamInfo[i][Team_Group], playerid))
        {
            Group_SetPlayer(TeamInfo[i][Team_Group], playerid, false);
        }
    }
    return 1;
}

Team_NicestTeam(ex) {
    new order_teams[MAX_TEAMS][2], Iterator:even_teams<MAX_TEAMS>;
    foreach(new i: teams_loaded) {
        foreach (new x: Player) {
            if (Team_GetPlayer(x) == i) {
                order_teams[i][0] ++;
            }
        }
        order_teams[i][1] = i;
    }
    QuickSort_Pair(order_teams, false, 0, Iter_Count(teams_loaded));
    foreach (new i: teams_loaded) {
        if (i != ex && order_teams[i][0] == order_teams[0][0]) {
            Iter_Add(even_teams, i);
        }
    }
    if (!Iter_Count(even_teams)) {
        Iter_Add(even_teams, order_teams[0][1]);
    }
    return Iter_Random(even_teams);
}

string:Team_GetName(team) {
    new buf[45];
    if (!Iter_Contains(teams_loaded, team)) return buf;
    strcat(buf, TeamInfo[team][Team_Name]);
    return buf;
}

Team_GetColor(team) {
    if (!Iter_Contains(teams_loaded, team)) return 0;
    return TeamInfo[team][Team_Color];
}

string:Team_GetGTColor(team) {
    new buf[17];
    if (!Iter_Contains(teams_loaded, team)) return buf;
    strcat(buf, TeamInfo[team][Chat_Bub]);
    return buf;
}

Team_GetMapZone(team) {
    if (!Iter_Contains(teams_loaded, team)) return 0;
    return _:TeamInfo[team][Team_MapZone];
}

Team_GetArea(team) {
    if (!Iter_Contains(teams_loaded, team)) return 0;
    return TeamInfo[team][Team_Area];
}

Float: Team_GetMapArea(team, point) {
    if (!Iter_Contains(teams_loaded, team) || 0 > point > 3) return 0.0;
    return TeamInfo[team][Team_MapArea][point];
}

Team_GetWaypoint(team) {
    if (!Iter_Contains(teams_loaded, team)) return 0;
    return TeamInfo[team][Team_Waypoint];
}

Team_SetWaypoint(team, wp) {
    if (!Iter_Contains(teams_loaded, team) || 0 > wp > 1) return 0;
    TeamInfo[team][Team_Waypoint] = wp;
    return 1;
}

Team_GetDefSkin(team) {
    if (!Iter_Contains(teams_loaded, team)) return 0;
    return TeamInfo[team][Team_MainSkin];
}

/* (c) H2O Multiplayer 2018-2020. All rights reserved. */