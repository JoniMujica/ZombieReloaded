#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>
#include <sdkhooks>
#include <franug_zp>

// configuration part
#define AWARDNAME "knifebomb" // Name of award
#define PRICE 30 // Award price
#define AWARDTEAM ZP_HUMANS // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_kboom.phrases" // Set translations file for this subplugin
// end configuration


#pragma semicolon 1

#define WEAPONS_MAX_LENGTH 32
#define DATA "1.1"

new bool:g_ZombieExplode[MAXPLAYERS+1] = false;
new knifeboom[MAXPLAYERS+1] = 0;
new Handle:tiempo;


#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"

new g_ExplosionSprite;
new g_SmokeSprite;
new Float:iNormal[ 3 ] = { 0.0, 0.0, 1.0 };


new flameAmount[MAXPLAYERS+1] = 0;
// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	HookEvent("player_spawn", EventPlayerSpawn);
	 CreateConVar("sm_kboom_version", DATA, "version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    HookEvent("player_hurt", EnDamage);

    tiempo = CreateConVar("sm_kboom_time", "3.0", "Seconds that zombie have for catch to humans");
}
public Action:Lateload(Handle:timer)
{
	LoadTranslations(TRANSLATIONS); // translations to the local plugin
	ZP_LoadTranslations(TRANSLATIONS); // sent translations to the main plugin
	
	ZP_AddAward(AWARDNAME, PRICE, AWARDTEAM); // add award to the main plugin
}

public OnConfigsExecuted()
{
	PrecacheSound(EXPLODE_SOUND, true);
	g_ExplosionSprite = PrecacheModel( "sprites/blueglow2.vmt" );
	g_SmokeSprite = PrecacheModel( "sprites/steam1.vmt" );
}
public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}


public EnDamage(Handle:event, const String:name[], bool:dontBroadcast)
{

        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsValidClient(attacker))
		return;

	if (IsPlayerAlive(attacker))
	{
           new client = GetClientOfUserId(GetEventInt(event, "userid"));


           if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client))
           {
             decl String:weapon[WEAPONS_MAX_LENGTH];
             GetEventString(event, "weapon", weapon, sizeof(weapon));
    
             if(StrEqual(weapon, "knife", false))
             {
				if(knifeboom[attacker]>0)
				{
                        g_ZombieExplode[client] = true;

                        PrintToChat(client, "\x04[Cuchibomba] \x05tenes %f segundos para infectar a un humano o moriras!!", GetConVarFloat(tiempo),attacker);

                        CreateTimer(GetConVarFloat(tiempo), ByeZM, client);
						knifeboom[attacker]--;
						PrintToChat(client, "\x04[Cuchibomba] \x05Tenes %i cuchibombas disponibles", knifeboom[client]);
				}
             }
            }
    }

}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{

	    if (!IsValidClient(attacker))
		      return Plugin_Continue;

            if(g_ZombieExplode[attacker])
            {
                        g_ZombieExplode[attacker] = false;
                        PrintToChat(attacker, "\x04[Cuchibomba] \x05Infectaste a un humano, te salvaste de explotar!");
            }
            return Plugin_Continue;
}



public Action:ByeZM(Handle:timer, any:client)
{
 if (IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_ZombieExplode[client])
 {
                        g_ZombieExplode[client] = false;

            		new Float:iVec[ 3 ];
		        GetClientAbsOrigin( client, Float:iVec );

			TE_SetupExplosion( iVec, g_ExplosionSprite, 5.0, 1, 0, 50, 40, iNormal );
			TE_SendToAll();
			
			TE_SetupSmoke( iVec, g_SmokeSprite, 10.0, 3 );
			TE_SendToAll();
	
			EmitAmbientSound( EXPLODE_SOUND, iVec, client, SNDLEVEL_NORMAL );

                        ForcePlayerSuicide(client);
 }
}


public OnPluginEnd()
{
	ZP_RemoveAward(AWARDNAME); // remove award when the plugin is unloaded
}
// END dont touch part


public ZP_OnAwardBought( client, const String:awardbought[])
{
	if(StrEqual(awardbought, AWARDNAME))
	{
		// use your custom code here
		knifeboom[client] += 1;
		PrintToChat(client, "\x04[Internacional ZP] \x05Compraste cuchibomba! usa el cuchillo contra los zombis");
	}
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_ZombieExplode[client] = false;
	flameAmount[client] = 0;
}

public OnClientPostAdminCheck(client)
{
  g_ZombieExplode[client] = false;
  flameAmount[client] = 0;
}