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

#if !defined _TRADES_MODULE
    #define _TRADES_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include "../gamemodes/SvT.pwn"

enum e_trades {
    e_trades_merchant,
    e_trades_receiver,
    e_trades_itemtype,
    e_trades_item,
    e_trades_qty,
    e_trades_price,
    e_trades_time
};
static trades[MAX_TRADES][e_trades];
static Iterator: Trades<MAX_TRADES>;

Trades_OfferItem(playerid, targetid, item_type, item, quantity, price) {
    if (Iter_Free(Trades) == -1) return 0;
    if (MIN_TRADE_PRICE > price > MAX_TRADE_PRICE) return SendGameMessage(playerid, X11_SERV_ERR, ERR_OUT_OF_RANGE_TRADE, formatInt(MIN_TRADE_PRICE), formatInt(MAX_TRADE_PRICE));
    if (!IsPlayerStreamedIn(playerid, targetid) || targetid == playerid) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_STREAMED);
    switch (item_type) {
        case ITEM_TYPE_WEAP: {
            if (Weapons_PlayerHas(playerid, item) < quantity) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_HAVING_TRADE, ReturnWeaponName(item));
            new i = Iter_Free(Trades);
            Iter_Add(Trades, i);
            trades[i][e_trades_merchant] = playerid;
            trades[i][e_trades_receiver] = targetid;
            trades[i][e_trades_itemtype] = item_type;
            trades[i][e_trades_item] = item;
            trades[i][e_trades_qty] = quantity;
            trades[i][e_trades_price] = price;
            trades[i][e_trades_time] = gettime();
            SendGameMessage(playerid, X11_SERV_INFO, TRADE_SENT);
            SendGameMessage(targetid, X11_SERV_INFO, TRADE_RECEIVED, PlayerInfo[playerid][PlayerName], playerid);
        }
        case ITEM_TYPE_ITEM: {
            if (Items_GetPlayer(playerid, item) < quantity) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_HAVING_TRADE, Items_GetName(item));
            new i = Iter_Free(Trades);
            Iter_Add(Trades, i);
            trades[i][e_trades_merchant] = playerid;
            trades[i][e_trades_receiver] = targetid;
            trades[i][e_trades_itemtype] = item_type;
            trades[i][e_trades_item] = item;
            trades[i][e_trades_qty] = quantity;
            trades[i][e_trades_price] = price;
            trades[i][e_trades_time] = gettime();
            SendGameMessage(playerid, X11_SERV_INFO, TRADE_SENT);
            SendGameMessage(targetid, X11_SERV_INFO, TRADE_RECEIVED, PlayerInfo[playerid][PlayerName], playerid);
        }
    }
    return 1;
}

Trades_DisplayPanel(playerid, targetid) {
    if (!IsPlayerStreamedIn(playerid, targetid) || targetid == playerid) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_STREAMED);
    new i = Trades_GetOne(playerid, targetid);
    if (i == -1) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NO_TRADE);
    
    inline TradePanelDialog(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused dialogid, listitem, inputtext
        if (!response) {
            Trades_ResetOne(i);
            return 1;
        }
        if (GetPlayerCash(pid) < trades[i][e_trades_price]) return SendGameMessage(pid, X11_SERV_ERR, ERR_INSUFFICIENT_FUNDS);
        switch (trades[i][e_trades_itemtype]) {
            case ITEM_TYPE_ITEM: {
                if (Items_GetPlayer(targetid, i) < trades[i][e_trades_qty]) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_HAVING_TRADE_2, Items_GetName(i));
                if (Items_AddPlayer(pid, trades[i][e_trades_item], trades[i][e_trades_qty])) {
                    GivePlayerCash(pid, -trades[i][e_trades_price]);
                    GivePlayerCash(targetid, trades[i][e_trades_price]);
                    SendGameMessage(pid, X11_SERV_SUCCESS, TRADE_SUCCESSFUL);
                    SendGameMessage(targetid, X11_SERV_SUCCESS, TRADE_SUCCESSFUL);
                    Items_AddPlayer(targetid, trades[i][e_trades_item], -trades[i][e_trades_qty]);
                    Trades_ResetOne(i);
                }
            }
            case ITEM_TYPE_WEAP: {
                    if (Weapons_PlayerHas(targetid, i) < trades[i][e_trades_qty]) return SendGameMessage(playerid, X11_SERV_ERR, ERR_NOT_HAVING_TRADE_2, ReturnWeaponName(i));
                    Weapons_SavePlayer(pid, trades[i][e_trades_item], trades[i][e_trades_qty]);
                    GivePlayerCash(pid, -trades[i][e_trades_price]);
                    GivePlayerCash(targetid, trades[i][e_trades_price]);
                    SendGameMessage(pid, X11_SERV_SUCCESS, TRADE_SUCCESSFUL);
                    SendGameMessage(targetid, X11_SERV_SUCCESS, TRADE_SUCCESSFUL);
                    Weapons_ReduceAmmo(targetid, trades[i][e_trades_item], trades[i][e_trades_qty]);
                    Trades_ResetOne(i);
            }
        }
    }

    new buf[LARGE_STRING_LEN], string:item[SMALL_STRING_LEN];
    switch (trades[i][e_trades_itemtype]) {
        case ITEM_TYPE_ITEM: {
            item = Items_GetName(trades[i][e_trades_item]);
        }
        case ITEM_TYPE_WEAP: {
            item = ReturnWeaponName(trades[i][e_trades_item]);
        }
    }
    format(buf, sizeof(buf), "The player %s[%d] is trading their %s with you. The quantity is %d.\n\
    The offer is %s for this item. If you can have it, you will get it and pay this cash value.\n\n\
    This action cannot be undone. Do you wish to continue?", PlayerInfo[targetid][PlayerName], targetid, item, trades[i][e_trades_qty],
    formatInt(trades[i][e_trades_price]));
    Dialog_ShowCallback(playerid, using inline TradePanelDialog, DIALOG_STYLE_MSGBOX, "Trade Panel", buf, ">>", "X");
    return 1;
}

Trades_ResetPlayer(playerid) {
    foreach (new i: Trades) {
        if (trades[i][e_trades_receiver] == playerid || trades[i][e_trades_merchant] == playerid) {
            new trades_reset[e_trades];
            trades[i] = trades_reset;
            Iter_SafeRemove(Trades, i, i);
        }
    }
    return 1;
}

Trades_ResetOne(trade_id) {
    new trades_reset[e_trades];
    trades[trade_id] = trades_reset;
    Iter_Remove(Trades, trade_id);
    return 1;
}

Trades_GetOne(playerid, targetid) {
    foreach (new i: Trades) {
        if (trades[i][e_trades_receiver] == playerid && trades[i][e_trades_merchant] == targetid) {
            return i;
        }
    }
    return -1;
}

/* (c) H2O Multiplayer 2018-2020. All rights reserved. */