#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_zp>
#include <zombiereloaded>

// configuration part
#define AWARDNAME "bombantidote" // Name of award
#define PRICE 60 // Award price
#define AWARDTEAM ZP_HUMANS // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_bombantidote.phrases" // Set translations file for this subplugin
#define NADE_COLOR2	{255,255,255,255}
#define NADE_DISTANCE 600.0

// end configuration
new nade_count[MAXPLAYERS+1] = 0;
new BeamSprite;
new maxents;
new g_beamsprite, g_halosprite;

// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	HookEvent("hegrenade_detonate", OnHeDetonate);
}
public OnMapStart()
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
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


public ZP_OnAwardBought( client, const String:awardbought[])
{
	if(StrEqual(awardbought, AWARDNAME))
	{
		// use your custom code here
		PrintToChat(client, " \x04[Internacional ZP] \x05%t", "you bought Bomb Antidote");
		nade_count[client] += 1;
		GivePlayerItem(client, "weapon_hegrenade");
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (IsValidEntity(entity))
	{
		if (!strcmp(classname, "hegrenade_projectile"))
		{
			CreateTimer(0.1, timer1345, entity);
		}
	}
}

public Action:timer1345(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if (StrEqual(classname, "hegrenade_projectile"))
		{
			new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				if(nade_count[client] > 0)
				{
					TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 10.0, 10.0, 5, NADE_COLOR2);
					TE_SendToAll();	
				}
			}
		}
	}
	return Plugin_Stop;
}  

public OnHeDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(nade_count[client] > 0)
	{
		nade_count[client]--;

		decl String:EdictName[64];

		// kill the grenade
		maxents = GetMaxEntities();
		for (new edict = MaxClients; edict <= maxents; edict++){
			if (IsValidEdict(edict))		{
				GetEdictClassname(edict, EdictName, sizeof(EdictName));
				if (!strcmp(EdictName, "hegrenade_projectile", false)){
					if (GetEntPropEnt(edict, Prop_Send, "m_hThrower") == client){
						AcceptEntityInput(edict, "Kill");
					}
				}
			}
		}
		
		// location where the grenade detonated
		new Float:DetonateOrigin[3];
		DetonateOrigin[0] = GetEventFloat(event, "x"); 
		DetonateOrigin[1] = GetEventFloat(event, "y"); 
		DetonateOrigin[2] = GetEventFloat(event, "z") + 30.0;
		
		// check each player
		for (new victim = 1; victim <= MaxClients; victim++){
			if (IsClientInGame(victim) && IsPlayerAlive(victim) && ZR_IsClientZombie(victim)){
				new Float:targetOrigin[3];
				GetClientAbsOrigin(victim, targetOrigin);

				// if zombie within distance of the infect blast
				if (GetVectorDistance(DetonateOrigin, targetOrigin) <= NADE_DISTANCE)
				{
					ZR_HumanClient(victim, false, false);


					GivePlayerItem(victim, "weapon_usp");
					GivePlayerItem(victim, "weapon_mp5navy");

					new Float:iVec[ 3 ];
					GetClientAbsOrigin( victim, Float:iVec );

					EmitAmbientSound("items/smallmedkit1.wav", iVec, victim, SNDLEVEL_NORMAL );

					// Create and send custom player_death event.
					new Handle:death_event = CreateEvent("player_death");
					if (event != INVALID_HANDLE){
						SetEventInt(death_event, "userid", GetClientUserId(victim));
						SetEventInt(death_event, "attacker", GetClientUserId(client));
						SetEventString(death_event, "weapon", "Antidote Nade");
						FireEvent(death_event, false);
					}
					
					// Give human a score point.
					new score = ToolsClientScore(client, true, false);
					ToolsClientScore(client, true, true, ++score);
					
					// Give zombie a death point.
					new deaths = ToolsClientScore(victim, false, false);
					ToolsClientScore(victim, false, true, ++deaths);
				}
			}
		}
		
		// special effects
		TE_SetupBeamRingPoint(DetonateOrigin, 10.0, NADE_DISTANCE, g_beamsprite, g_halosprite, 1, 10, 1.0, 5.0, 1.0, NADE_COLOR2, 0, 0);
		TE_SendToAll();

		new iEntity = CreateEntityByName("light_dynamic");
		DispatchKeyValue(iEntity, "inner_cone", "0");
		DispatchKeyValue(iEntity, "cone", "80");
		DispatchKeyValue(iEntity, "brightness", "1");
		DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
		DispatchKeyValue(iEntity, "pitch", "90");
		DispatchKeyValue(iEntity, "style", "1");

		DispatchKeyValue(iEntity, "_light", "255 255 255 255");
		DispatchKeyValueFloat(iEntity, "distance", NADE_DISTANCE);
		CreateTimer(1.0, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);

		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, DetonateOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iEntity, "TurnOn");
	}
}

stock ToolsClientScore(client, bool:score = true, bool:apply = true, value = 0)
{
    if (!apply)
    {
        if (score)
        {
            // If score is true, then return client's score.
            return GetEntProp(client, Prop_Data, "m_iFrags");
        }
        // Return client's deaths.
        else
        {
            return GetEntProp(client, Prop_Data, "m_iDeaths");
        }
    }
    
    // If score is true, then set client's score.
    if (score)
    {
        SetEntProp(client, Prop_Data, "m_iFrags", value);
    }
    // Set client's deaths.
    else
    {
        SetEntProp(client, Prop_Data, "m_iDeaths", value);
    }
    
    // We set the client's score or deaths.
    return -1;
}
public Action:Delete(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "kill");
	}
}
public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
	return false; 
	
	return true; 
}