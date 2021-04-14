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

#if !defined _ITEMS_MODULE
    #define _ITEMS_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include "../gamemodes/SvT.pwn"

enum InvData {
	Item_Name[20],
	Item_Info[128],
	Item_Max,
	Item_Object,
	Item_Cost
};

/*
	RULE OF COST:
		WORKS IN WAR: +5000
		DESTRUCTIVE EFFECT: +5000
*/

static const ItemsInfo[MAX_ITEMS][InvData] =
{
	{	"Helmet", "Protects against headshot.", 		 		 		 2, 19102, 5000		  }, //19102
	{   "Gasmask", "Protects against tear-gas effect.", 		 		 2, 19472, 5000		  }, //19472
	{	"Medkit", "Regenerate health by using /mk",		 		  	     2, 11738, 5000	 	  }, //11738
	{   "Armour Kit", "Fix armour by using /ak", 	 			 		 2, 19515, 5000	 	  }, //19515
	{	"Landmine", "Plant landmine with /pmine",      			 		 3, 19602, 10000	  }, //19602
	{	"Dynamite", "Suicide with /suicide or plant bomb with /pb",      1, 1654,  10000	  } //1654
};

static Iterator: PlayerItems[MAX_PLAYERS]<MAX_ITEMS>;
static PlayerItemsQty[MAX_PLAYERS][MAX_ITEMS];

Items_GetMax(item) {
    if (0 > item > MAX_ITEMS) return 0;
    return ItemsInfo[item][Item_Max];
}

Items_GetObject(item) {
    if (0 > item > MAX_ITEMS) return 0;
    return ItemsInfo[item][Item_Object];
}

Items_GetPrice(item) {
    if (0 > item > MAX_ITEMS) return 0;
    return ItemsInfo[item][Item_Cost];
}

string:Items_GetInfo(item) {
    new buf[128];
    if (0 > item > MAX_ITEMS) return buf;
    strcat(buf, ItemsInfo[item][Item_Info]);
    return buf;
}

string:Items_GetName(item) {
    new string:buf[20];
    if (0 > item > MAX_ITEMS) return buf;
    strcat(buf, ItemsInfo[item][Item_Name]);
    return buf;
}

Items_IsValidName(string:item_name[]) {
    for (new i = 0; i < MAX_ITEMS; i++) {
        new string:buf[20];
        buf = Items_GetName(i);
        if (!isnull(item_name) && !isnull(buf) && !strcmp(buf, item_name, true)) return i;
    }
    return -1;
}

forward Items_OnPlayerSave(playerid, item, qty);
public Items_OnPlayerSave(playerid, item, qty) {
    Items_AddPlayer(playerid, item, qty);
    return 1;
}

forward Items_OnPlayerLoad(playerid);
public Items_OnPlayerLoad(playerid) {
    if (!cache_num_rows()) return 0;
    for (new i = 0, j = cache_num_rows(); i != j; i++) {
        new item, qty;
        cache_get_value_int(i, "Item", item);
        cache_get_value_int(i, "Qty", qty);
        Iter_Add(PlayerItems[playerid], item);
        PlayerItemsQty[playerid][item] = qty;
    }
    return 1;
}

forward Items_OnPlayerHave(playerid, item, qty);
public Items_OnPlayerHave(playerid, item, qty) {
    new query[MEDIUM_STRING_LEN];
    if (cache_num_rows()) {
        mysql_format(Database, query, sizeof(query), "UPDATE `PlayersItems` SET `Qty` = `Qty`+'%d' WHERE `Item` = '%d' AND `Player` = '%d' LIMIT 1", qty, item, PlayerInfo[playerid][pAccountId]);
        mysql_tquery(Database, query);
        Items_AddPlayer(playerid, item, qty);
    } else {
        mysql_format(Database, query, sizeof(query), "INSERT INTO `PlayersItems` (`Player`,`Item`,`Qty`,`Time`) VALUES ('%d','%d','%d','%d')",
            PlayerInfo[playerid][pAccountId], item, qty, gettime());
        mysql_tquery(Database, query, "Items_OnPlayerSave", "iii", playerid, item, qty);
    }
    return 1;
}

Items_SavePlayer(playerid, item, qty) {
    if (!pVerified[playerid] || qty <= 0 || item >= MAX_ITEMS || item < 0) return 0;
    new query[MEDIUM_STRING_LEN];
    mysql_format(Database, query, sizeof(query), "SELECT * FROM `PlayersItems` WHERE `Player` = '%d' AND `Item` = '%d'", PlayerInfo[playerid][pAccountId], item);
    mysql_tquery(Database, query, "Items_OnPlayerHave", "iii", playerid, item, qty);
    return 1;
}

Items_LoadPlayer(playerid) {
    if (!pVerified[playerid]) return 0;
    new query[MEDIUM_STRING_LEN];
    mysql_format(Database, query, sizeof(query), "SELECT * FROM `PlayersItems` WHERE `Player` = '%d' AND `Qty` != '0'", PlayerInfo[playerid][pAccountId]);
    mysql_tquery(Database, query, "Items_OnPlayerLoad", "i", playerid);
    return 1;
}

Items_ExitPlayer(playerid) {
    foreach (new i: PlayerItems[playerid]) {
        if (PlayerItemsQty[playerid][i] > 0) {
            new query[MEDIUM_STRING_LEN];
            mysql_format(Database, query, sizeof(query), "UPDATE `PlayersItems` SET `Qty` = '%d' WHERE `Item` = '%d' AND `Player` = '%d'", PlayerItemsQty[playerid][i], i, PlayerInfo[playerid][pAccountId]);
            mysql_tquery(Database, query);
        }
    }
    Items_ResetPlayer(playerid);
    return 1;
}

Items_ResetPlayer(playerid) {
	if (IsPlayerAttachedObjectSlotUsed(playerid, 2))
	{
		RemovePlayerAttachedObject(playerid, 2);
	}

	if (IsPlayerAttachedObjectSlotUsed(playerid, 3))
	{
		RemovePlayerAttachedObject(playerid, 3);
	}

	if (IsPlayerAttachedObjectSlotUsed(playerid, 5))
	{
		RemovePlayerAttachedObject(playerid, 5);
	}
    Iter_Clear(PlayerItems[playerid]);
    for (new i = 0; i < MAX_ITEMS; i++) {
        PlayerItemsQty[playerid][i] = 0;
    }
	return 1;
}

Items_AddPlayer(playerid, item, amount) {
    if (0 > amount) {
        PlayerItemsQty[playerid][item] += amount;
        if (PlayerItemsQty[playerid][item] <= 0) {
            PlayerItemsQty[playerid][item] = 0;
            Iter_Remove(PlayerItems[playerid], item);
        }
        return 1;
    }
	new maximum = ItemsInfo[item][Item_Max];
	if ((PlayerItemsQty[playerid][item] + amount) > maximum || PlayerItemsQty[playerid][item] == maximum) {
		SendGameMessage(playerid, X11_SERV_ERR, MSG_ERR_IT_NT_ADD, ItemsInfo[item][Item_Name]);
		return 0;
	}
    PlayerItemsQty[playerid][item] += amount;
    Iter_Add(PlayerItems[playerid], item);
	switch (item) {
		case HELMET: AttachHelmet(playerid);
		case MASK: AttachMask(playerid);
		case DYNAMITE: AttachDynamite(playerid);
	}
	return 1;
}

Items_RemovePlayer(playerid, item) {
	if (Iter_Contains(PlayerItems[playerid], item)) Iter_Remove(PlayerItems[playerid], item);
    PlayerItemsQty[playerid][item] = 0;
	switch (item) {
		case HELMET: AttachHelmet(playerid);
		case MASK: AttachMask(playerid);
		case DYNAMITE: AttachDynamite(playerid);
	}
	return 1;
}

Items_GetPlayer(playerid, item) {
    if (Iter_Contains(PlayerItems[playerid], item)) {
        return PlayerItemsQty[playerid][item];
    } else {
        return 0;
    }
}

/* (c) H2O Multiplayer 2018-2020. All rights reserved. */