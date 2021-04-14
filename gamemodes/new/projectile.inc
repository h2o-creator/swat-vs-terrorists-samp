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

#if !defined _PROJECTILE_MODULE
    #define _PROJECTILE_MODULE
#else
    #endinput
#endif

#include <a_samp>
#include "../gamemodes/SvT.pwn"

//Airstrike
static gAirstrikePlane[MAX_AIRSTRIKES];
static gAirstrikeRocket[MAX_AIRSTRIKES];
static gAirstrikeTimer[MAX_AIRSTRIKES];
static gAirstrikeCaller[MAX_AIRSTRIKES];
static gAirstrikes;

//PlayerProjectiles
static gProjectilePlayer[MAX_PPROJECTILES];
static gProjectileObject[MAX_PPROJECTILES];
static gProjectileExtraId[MAX_PPROJECTILES];
static gProjectiles;

//Airstrike

forward OnAirstrikeForwarded(caller, callid, Smoke_Flare_ID, Float: X, Float: Y, Float: Z);
public OnAirstrikeForwarded(caller, callid, Smoke_Flare_ID, Float: X, Float: Y, Float: Z) {
	DestroyDynamicObject(Smoke_Flare_ID);
	KillTimer(gAirstrikeTimer[callid]);
	new Float: MAX_HEIGHT = 150.0, Float: DIFFERENCE = 50.0;
	Z += MAX_HEIGHT;
	gAirstrikeRocket[callid] = INVALID_OBJECT_ID;
	gAirstrikePlane[callid] = INVALID_OBJECT_ID;
	gAirstrikeCaller[callid] = caller;
	new i = CreateProjectile(X, Y, (Z - DIFFERENCE), 20.0, 20.0, -10.0, 0.0, 45.0, 180.0, .air_resistance = 1.0, .spherecol_radius = 1.5);
	if (i == -1) {
		return 0;
	}
	new j = CreateProjectile(X, Y, Z, 20.0, 20.0, -10.0, 0.0, -90.0, 0.0, .air_resistance = 1.0, .spherecol_radius = 7.5);
	if (j == -1) {
		return 0;
	}
	gAirstrikeRocket[callid] = CreateDynamicObject(3790, X, Y, (Z - DIFFERENCE), 0.0, -90.0, 0.0);
	Streamer_SetIntData(STREAMER_TYPE_OBJECT, gAirstrikeRocket[callid], E_STREAMER_EXTRA_ID, i);
	gAirstrikePlane[callid] = CreateDynamicObject(10757, X, Y, Z, 0.0, 45.0, 180.0);
	Streamer_SetIntData(STREAMER_TYPE_OBJECT, gAirstrikePlane[callid], E_STREAMER_EXTRA_ID, j);
	return 1;
}

CreateAirstrike(playerid, Float: X, Float: Y, Float: Z) {
	if (gAirstrikes == MAX_AIRSTRIKES) return 0;
	new Smoke_Flare_Object = CreateDynamicObject(18728, X, Y, Z, 0.0, 0.0, 90.0);
	gAirstrikeTimer[gAirstrikes] = SetTimerEx("OnAirstrikeForwarded", 5000, false, "iiifff", PlayerInfo[playerid][pAccountId], gAirstrikes++, Smoke_Flare_Object, X, Y, Z);
	return 1;
}

//PlayerProjectiles

CreatePProjectile(playerid, objectid, extraid, Float: x, Float: y, Float: z, Float: vx, Float: vy, Float: vz, Float: rx = 0.0, Float: ry = 0.0, Float: rz = 0.0, Float: spherecol_radius = 1.0) {
	if (gProjectiles == MAX_PPROJECTILES) return 0;
	new i = CreateProjectile(x, y, z, vx, vy, vz, rx, ry, rz, .spherecol_radius = spherecol_radius);
	if (i == -1) {
		return 0;
	}
	gProjectileObject[gProjectiles] = CreateDynamicObject(objectid, x, y, z, rx, ry, rz);
	gProjectileExtraId[gProjectiles] = extraid;
	gProjectilePlayer[gProjectiles] = PlayerInfo[playerid][pAccountId];
	Streamer_SetIntData(STREAMER_TYPE_OBJECT, gProjectileObject[gProjectiles ++], E_STREAMER_EXTRA_ID, i);
	return 1;
}

CreateMissileLauncher(playerid) {
	//https://wiki.sa-mp.com/wiki/GetPlayerCameraFrontVector
	new
		Float:fPX, Float:fPY, Float:fPZ,
		Float:fVX, Float:fVY, Float:fVZ,
		Float:object_x, Float:object_y, Float:object_z;

	const
		Float:fScale = 10.0, Float:mSpeed = 60.0;

	GetPlayerCameraPos(playerid, fPX, fPY, fPZ);
	GetPlayerCameraFrontVector(playerid, fVX, fVY, fVZ);

	object_x = fPX + floatmul(fVX, fScale);
	object_y = fPY + floatmul(fVY, fScale);
	object_z = fPZ + floatmul(fVZ, fScale);
	CreatePProjectile(playerid, 345, EXTRAID_TYPE_PLAYER, object_x, object_y, object_z, fVX * mSpeed, fVY * mSpeed, fVZ * mSpeed);
	return 1;
}

//Projectiles

public OnProjectileUpdate(projid) {
	for (new i = gAirstrikes - 1; i > -1; i--) {
		if (gAirstrikeRocket[i] != INVALID_OBJECT_ID && Streamer_GetIntData(STREAMER_TYPE_OBJECT, gAirstrikeRocket[i], E_STREAMER_EXTRA_ID) == projid) {
			new Float: X, Float: Y, Float: Z;
			GetProjectilePos(projid, X, Y, Z);
			SetDynamicObjectPos(gAirstrikeRocket[i], X, Y, Z);
			GetProjectileRot(projid, X, Y, Z);
			SetDynamicObjectRot(projid, X, Y, Z);
		}
		if (gAirstrikePlane[i] != INVALID_OBJECT_ID && Streamer_GetIntData(STREAMER_TYPE_OBJECT, gAirstrikePlane[i], E_STREAMER_EXTRA_ID) == projid) {
			new Float: X, Float: Y, Float: Z;
			GetProjectilePos(projid, X, Y, Z);
			SetDynamicObjectPos(gAirstrikePlane[i], X, Y, Z);
			GetProjectileRot(projid, X, Y, Z);
			SetDynamicObjectRot(projid, X, Y, Z);
			foreach (new j: Player) {
				PlayerPlaySound(j, 156, X, Y, Z);
			}
		}
	}
	for (new i = gProjectiles - 1; i > -1; i--) {
		if (gProjectileObject[i] != INVALID_OBJECT_ID && Streamer_GetIntData(STREAMER_TYPE_OBJECT, gProjectileObject[i], E_STREAMER_EXTRA_ID) == projid) {
			new Float: X, Float: Y, Float: Z;
			GetProjectilePos(projid, X, Y, Z);
			SetDynamicObjectPos(gProjectileObject[i], X, Y, Z);
			GetProjectileRot(projid, X, Y, Z);
			SetDynamicObjectRot(projid, X, Y, Z);
			foreach (new j: Player) {
				PlayerPlaySound(j, 3200, X, Y, Z);
			}
		}
	}
	return 1;
}

public OnProjectileCollide(projid, type, Float:x, Float:y, Float:z, extraid) {
	for (new i = gAirstrikes - 1; i > -1; i--) {
		if (gAirstrikeRocket[i] != INVALID_OBJECT_ID && Streamer_GetIntData(STREAMER_TYPE_OBJECT, gAirstrikeRocket[i], E_STREAMER_EXTRA_ID) == projid) {
			CreateExplosion(x, y, z, 12, 300.0);
			CreateExplosion(x, y, z, 11, 300.0);
			CreateExplosion(x, y, z, 10, 300.0);
			CreateExplosion(x, y, z, 7, 300.0);
			DestroyDynamicObject(gAirstrikeRocket[i]);
			DestroyProjectile(projid);
			gAirstrikeRocket[i] = INVALID_OBJECT_ID;
			new caller_playerid = INVALID_PLAYER_ID;
			if (type == PROJECTILE_COLLIDE_PLAYER) {
				if (gAirstrikeCaller[i] != -1) {
					foreach (new j: Player) {
						if (PlayerInfo[j][pAccountId] == gAirstrikeCaller[i]) {
							caller_playerid = j;
						}
					}
				}
			}
			if (caller_playerid != INVALID_PLAYER_ID) {
				foreach (new j: Player) {
					if (IsPlayerInMode(j, MODE_BATTLEFIELD) && IsPlayerInRangeOfPoint(j, 300.0, x, y, z) && j != caller_playerid &&
						Team_GetPlayer(j) != Team_GetPlayer(caller_playerid)) {
						new Float: burnx, Float: burny, Float: burnz;
						GetPlayerPos(j, burnx, burny, burnz);
						CreateExplosion(burnx, burny, burnz, 7, 10.0);
						CreateExplosion(burnx, burny + 5, burnz, 7, 10.0);
						CreateExplosion(burnx - 5, burny, burnz, 7, 10.0);
						SetPlayerPos(j, burnx + 5, burny + 5, burnz + 10);
						SetPlayerHealth(j, 0.0);
						SendGameMessage(j, X11_SERV_INFO, MSG_NUKED);
						PlayerInfo[caller_playerid][pKills] ++;
						PlayerInfo[j][pDeaths] ++;
						SendGameMessage(caller_playerid, X11_SERV_INFO, MSG_NUKE_KILLED, PlayerInfo[j][PlayerName], j);
						SuccessAlert(caller_playerid);
					}
				}	
			}
			gAirstrikeCaller[i] = -1;
		}
		if (gAirstrikePlane[i] != INVALID_OBJECT_ID && Streamer_GetIntData(STREAMER_TYPE_OBJECT, gAirstrikePlane[i], E_STREAMER_EXTRA_ID) == projid) {
			CreateExplosion(x, y, z, 7, 300.0);
			DestroyDynamicObject(gAirstrikePlane[i]);
			DestroyProjectile(projid);
			gAirstrikePlane[i] = INVALID_OBJECT_ID;
			foreach (new j: Player) {
				PlayerPlaySound(j, 0, x, y, z);
			}
		}
		if (gAirstrikePlane[i] == INVALID_OBJECT_ID && gAirstrikeRocket[i] == INVALID_OBJECT_ID) {
			gAirstrikes--;
		}
	}
	for (new i = gProjectiles - 1; i > -1; i--) {
		if (gProjectileObject[i] != INVALID_OBJECT_ID && Streamer_GetIntData(STREAMER_TYPE_OBJECT, gProjectileObject[i], E_STREAMER_EXTRA_ID) == projid) {
			CreateExplosion(x, y, z, 7, 10.0);
			DestroyDynamicObject(gProjectileObject[i]);
			DestroyProjectile(projid);
			gProjectileObject[i] = INVALID_OBJECT_ID;
			switch (gProjectileExtraId[i]) {
				case EXTRAID_TYPE_PLAYER: {
					new caller_playerid = INVALID_PLAYER_ID;
					if (type == PROJECTILE_COLLIDE_PLAYER) {
						if (gProjectilePlayer[i] != -1) {
							foreach (new j: Player) {
								if (PlayerInfo[j][pAccountId] == gProjectilePlayer[i]) {
									caller_playerid = j;
								}
							}
						}
					}
					if (caller_playerid != INVALID_PLAYER_ID) {
						foreach (new j: Player) {
							if (IsPlayerInMode(j, MODE_BATTLEFIELD) && IsPlayerInRangeOfPoint(j, 300.0, x, y, z) && j != caller_playerid &&
								Team_GetPlayer(j) != Team_GetPlayer(caller_playerid)) {
								new Float: burnx, Float: burny, Float: burnz;
								DamagePlayer(j, 0.0, caller_playerid, WEAPON_EXPLOSION, BODY_PART_UNKNOWN, false);
								CreateExplosion(burnx, burny, burnz, 7, 7.5);
								SendGameMessage(j, X11_SERV_INFO, MSG_NUKED);
								SendGameMessage(caller_playerid, X11_SERV_INFO, MSG_NUKE_KILLED, PlayerInfo[j][PlayerName], j);
								SuccessAlert(caller_playerid);
								if (IsPlayerInAnyVehicle(caller_playerid) && GetVehicleModel(GetPlayerVehicleID(caller_playerid)) == 476) {
									PlayerInfo[caller_playerid][pRustlerRocketsHit] ++;
								}
							}
						}	
					}
				}	
			}
			gProjectileExtraId[i] = -1;
		}
		if (gProjectileObject[i] == INVALID_OBJECT_ID) {
			gProjectiles --;
		}
	}
	return 1;
}
 
public OnProjectileStop(projid, Float:x, Float:y, Float:z) {
	return 1;
}

//Airstrike

CMD:airstrike(playerid) {
	if (!IsPlayerInMode(playerid, MODE_BATTLEFIELD)) return SendGameMessage(playerid, X11_SERV_ERR, MSG_MAIN_WORLD_ONLY);

	if (!p_ClassAbilities(playerid, NUKEMASTER)) {
		return PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0), SendGameMessage(playerid, X11_SERV_ERR, MSG_CLIENT_343x);
	}
	if (Team_GetPlayer(playerid) != gAnthraxOwner) return SendGameMessage(playerid, X11_SERV_ERR, MSG_CLIENT_295x);

	if (pCooldown[playerid][30] > gettime()) {
		 SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_340x, pCooldown[playerid][30] - gettime());
		 return 1;
	}

	new Float: Checkpos[3], Float: Check_X;
	GetPlayerPos(playerid, Checkpos[0], Checkpos[1], Checkpos[2]);

	CA_FindZ_For2DCoord(Checkpos[0], Checkpos[1], Check_X);
	if (Checkpos[2] < Check_X) return SendGameMessage(playerid, X11_SERV_INFO, MSG_CLIENT_339x);

	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);
	CA_FindZ_For2DCoord(X, Y, Z);
	CreateAirstrike(playerid, X, Y, Z);
	pCooldown[playerid][30] = gettime() + 45;
	PlayerInfo[playerid][pAirstrikesCalled] ++;
	return 1;
}

/* (c) H2O Multiplayer 2018-2020. All rights reserved. */