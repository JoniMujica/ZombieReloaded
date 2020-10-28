#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <external/emitsoundany>
#include <zombiereloaded>
#include <franug_zp>

// configuration part
#define AWARDNAME "antidote" // Name of award
#define PRICE 18 // Award price
#define AWARDTEAM ZP_ZOMBIES // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_antidote.phrases" // Set translations file for this subplugin
// end configuration
new bool:NoCurar = false;
new bool:infectado[MAXPLAYERS+1] = {false, ...};


// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	HookEvent("round_freeze_end", EventRoundFreezeEnd);
	HookEvent("player_spawn", EventPlayerSpawn);
}
public Action:Lateload(Handle:timer)
{
	LoadTranslations(TRANSLATIONS); // translations to the local plugin
	ZP_LoadTranslations(TRANSLATIONS); // sent translations to the main plugin
	
	ZP_AddAward(AWARDNAME, PRICE, AWARDTEAM); // add award to the main plugin
}
public OnPluginEnd()
{
	ZP_RemoveAward(AWARDNAME); // remove award when the plugin is unloaded
}
// END dont touch part
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
	infectado[index] = false;
}

public Action:EventRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	NoCurar = true;
	CreateTimer(60.0, Pasado);
}

public Action:Pasado(Handle:timer)
{
	NoCurar = false;
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if (!IsValidClient(attacker))
	return Plugin_Continue;
	infectado[attacker] = true;
	return Plugin_Continue;
}

public ZP_OnAwardBought( client, const String:awardbought[])
{
	if(StrEqual(awardbought, AWARDNAME))
	{
		new val = ZP_GetCredits(client);
		val += PRICE;
		if(NoCurar)
		{
			ZP_SetCredits(client, val);
			PrintToChat(client,"\x04[Internacional ZM] \x05No puedes curarte al empezar la ronda hasta que no pase 1 minuto");
			return;
		}
		if(!infectado[client])
		{
			ZP_SetCredits(client, val);
			PrintToChat(client,"\x04[Internacional ZM] \x05No puedes curarte siendo mother zombie o no habiendo infectado a alguien primero");
			return;
		}
		// use your custom code here
		PrintToChat(client, "\x04[Internacional ZP] \x05%t", "you bought antidote");
		ZR_HumanClient(client, false, false);
						
		GivePlayerItem(client, "weapon_glock");
		GivePlayerItem(client, "weapon_mp5navy");
		new Float:iVec[ 3 ];
		GetClientAbsOrigin( client, Float:iVec );
		EmitAmbientSoundAny("items/smallmedkit1.wav", iVec, client, SNDLEVEL_NORMAL );
		decl String:nombre[32];
		GetClientName(client, nombre, sizeof(nombre));
		PrintToChatAll("\x04%t","a vuelto a ser humano con un antidoto", nombre);
	}
}

public OnMapStart()
{
	PrecacheSound("items/smallmedkit1.wav");
}

public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
	return false; 
	
	return true; 
}