#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
//#undef REQUIRE_PLUGIN
#include <external/emitsoundany>
#include <franug_zp>

// configuration parti
#define AWARDNAME "minigunzp" // Name of award
#define PRICE 60 // Award price
#define AWARDTEAM ZP_HUMANS // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_minigun.phrases" // Set translations file for this subplugin


//minigun assets
#define PLUGIN_NAME 	"ZP:Minigun CSO"
#define PLUGIN_VERSION 	"2.3.0"



#define WEAPON_NAME					"weapon_minigun"
#define WEAPON_REFERANCE			"weapon_m249"
#define WEAPON_SLOT					WEAPON_SLOT_PRIMARY

// Models
#define MODEL_WORLD 				"models/infozona-51/weapons/cso_m249/w_mach_m249para.mdl"
#define MODEL_VIEW					"models/infozona-51/weapons/cso_m249/v_mach_m249para.mdl"
#define MODEL_BEAM 					"materials/sprites/laserbeam.vmt"

// Sounds
// #define SOUND_FIRE "zombie-plague/weapons/m136_xmas/stalker_pkm_fire_f.wav"
#define SOUND_BOXIN					"zombie-plague/weapons/m136_xmas/m134_boxin.wav"
#define SOUND_BOXOUT				"zombie-plague/weapons/m136_xmas/m134_boxout.wav"
#define SOUND_CHAIN					"zombie-plague/weapons/m136_xmas/m134_chain.wav"
#define SOUND_CLIPOFF				"zombie-plague/weapons/m136_xmas/m134_clipoff.wav"
#define SOUND_CLIPON				"zombie-plague/weapons/m136_xmas/m134_clipon.wav"
#define SOUND_SPINDOWN					"zombie-plague/weapons/m136_xmas/m134_spindown.wav"
#define SOUND_FIRE					"zombie-plague/weapons/m136_xmas/stalker_pkm_fire_f.wav"
#define SOUND_DEPLOY				"weapons/RequestsStudio/UT3/AvrilDeploy.mp3"

// Beam
#define BEAM_LIFE					0.105
#define BEAM_COLOR					{100, 50, 253, 255}

// Damage
#define WEAPON_MULTIPLIER_DAMAGE 	1.5

#define UPDATE_URL	"http://godtony.mooo.com/stopsound/stopsound.txt"

new bool:g_bStopSound[MAXPLAYERS+1], bool:g_bHooked;
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Slash",
	description = "Agrega una minigun arma al servidor",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

enum
{ 
	WEAPON_SLOT_INVALID = -1, 		/** Used as return value when an weapon doens't exist. */
	
	WEAPON_SLOT_PRIMARY, 			/** Primary slot */
	WEAPON_SLOT_SECONDARY, 			/** Secondary slot */
	WEAPON_SLOT_MELEE, 				/** Melee slot */
	WEAPON_SLOT_EQUEPMENT			/** Equepment slot */
};

enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_DRAW,
    ANIM_SHOOT2
};

 
// Item index
new bool:bHasCustomWeapon[MAXPLAYERS+1];

// Weapon model indexes
new iViewModel;
new iWorldModel;
new iBeamModel;
// end configuration

// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	decl String:sGame[32];
	GetGameFolderName(sGame, sizeof(sGame));

	if (StrEqual(sGame, "cstrike"))
		AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
	else if (StrEqual(sGame, "dod"))
		AddTempEntHook("FireBullets", DODS_Hook_FireBullets);
	
	HookEvent("weapon_fire", WeaponFire);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("bullet_impact", EventBulletImpact, EventHookMode_Post);
	//HookEvent("player_spawn", EventPlayerSpawn);
}

public OnMapStart()
{
	iBeamModel  = PrecacheModel(MODEL_BEAM);
	iViewModel  = PrecacheModel(MODEL_VIEW);
	iWorldModel = PrecacheModel(MODEL_WORLD);
	
	// Precache sound
	
	decl String:sSound[128];
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_FIRE);
	AddFileToDownloadsTable(sSound);
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_BOXIN);
	AddFileToDownloadsTable(sSound); 
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_BOXOUT);
	AddFileToDownloadsTable(sSound); 
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_CHAIN);
	AddFileToDownloadsTable(sSound); 
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_CLIPOFF);
	AddFileToDownloadsTable(sSound); 
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_CLIPON);
	AddFileToDownloadsTable(sSound); 
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_SPINDOWN);
	AddFileToDownloadsTable(sSound); 
	
	
	PrecacheSound(SOUND_FIRE);
	PrecacheSound(SOUND_BOXIN);
	PrecacheSound(SOUND_BOXOUT);
	PrecacheSound(SOUND_CHAIN);
	PrecacheSound(SOUND_CLIPOFF);
	PrecacheSound(SOUND_CLIPON);
	PrecacheSound(SOUND_SPINDOWN);
	// Add models to download list
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/v_mach_m249para.dx80.vtx");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/v_mach_m249para.dx90.vtx");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/v_mach_m249para.mdl");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/v_mach_m249para.sw.vtx");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/v_mach_m249para.vvd");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/w_mach_m249para.dx80.vtx");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/w_mach_m249para.dx90.vtx");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/w_mach_m249para.mdl");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/w_mach_m249para.phy");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/w_mach_m249para.sw.vtx");
	AddFileToDownloadsTable("models/infozona-51/weapons/cso_m249/w_mach_m249para.vvd");

	// Add textures to download list
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/arms_professional.vmt");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/arms_professional.vtf");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/Frame_MG3_XMAS_Body.vmt");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/Frame_MG3_XMAS_Body_D.vtf");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/Frame_MG3_XMAS_Box.vmt");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/Frame_MG3_XMAS_Box_D.vtf");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/v_hands_cso.vmt");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/v_hands_cso_D.vtf");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/v_hands_cso_N.vtf");
	AddFileToDownloadsTable("materials/models/infozona-51/weapons/cso_m249/v_hands_cso_S.vtf");
	
	PrecacheSoundAny("franug/zombie_plague/resistencia_armadura.mp3");
	AddFileToDownloadsTable("sound/franug/zombie_plague/resistencia_armadura.mp3");
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
public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new weaponIndex;
	
	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
    // Get all required event info
	
	if(IsCustomItem(clientIndex, weaponIndex))
	{
		RequestFrame(FirePostFrame, clientIndex);
	}
}
public FirePostFrame(userid)
{
    if(!userid)
        return;
    new weapon = GetEntPropEnt(userid, Prop_Data, "m_hActiveWeapon");
    new Float:curtime = GetGameTime();
    new Float:nexttime = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
    // PrintToChatAll("%f %f", curtime, nexttime)
    nexttime -= curtime;
    nexttime *= 1.0/1.5; 	// 4.0 - multiplier
    nexttime += curtime;
    // PrintToChatAll("%f", nexttime)
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", nexttime);
    SetEntPropFloat(userid, Prop_Send, "m_flNextAttack", 0.0);
	
	decl Float:CurrentPunchAngle[3];
	GetEntPropVector(userid, Prop_Send, "m_vecPunchAngle", CurrentPunchAngle);
	SetEntProp(userid, Prop_Send, "m_iShotsFired", 0);
	CurrentPunchAngle[0] = 0.0;
	CurrentPunchAngle[1] = 0.0;
	CurrentPunchAngle[2] = 0.0;
} 


public ZP_OnAwardBought( clientIndex, const String:awardbought[])
{
	if(StrEqual(awardbought, AWARDNAME))
	{
		// use your custom code here
		if(!IsPlayerExist(clientIndex))
		{
			return Plugin_Handled;
		}
		
		new iSlot = GetPlayerWeaponSlot(clientIndex, WEAPON_SLOT_PRIMARY);

		// If weapon is valid, then drop
		if (iSlot != WEAPON_SLOT_INVALID)
		{
			CS_DropWeapon(clientIndex, iSlot, true, false);
		}
		
		// Give item
		bHasCustomWeapon[clientIndex] = true;
		GivePlayerItem(clientIndex, WEAPON_REFERANCE);
		FakeClientCommandEx(clientIndex, "use %s", WEAPON_REFERANCE);
		PrintToChat(clientIndex, "\x04[Internacional ZP] \x05%t", "you bought minigun");
	}
}

public OnClientDisconnect_Post(client)
{
	g_bStopSound[client] = false;
	CheckHooks();
}

public Action:OnPlayerDeath(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
    //Find the dead client
	new weaponIndex;
    new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
    //If this client die
    if(iVictim) {
		if(IsCustomItem(attacker, weaponIndex))
		{
        //Here we set the hEvent death as a deflected rocket
			SetEventString(hEvent, "weapon", "cso_minigun");
		}
    }
    //Done
} 

public Action:EventBulletImpact(Handle:gEventHook, const String:name[], bool:dontBroadcas) 
{
	// Initialize weapon index
	int weaponIndex;

	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));
	
	// If weapon isn't custom
	if(!IsCustomItem(clientIndex, weaponIndex))
	{
		return;
	}

	// Initialize vector variables
	float flStart[3];
	float flEnd[3];
	
	// Get start position
	GetClientEyePosition(clientIndex, flStart); 
	
	// Get end position
	flEnd[0] = GetEventFloat(gEventHook, "x");
	flEnd[1] = GetEventFloat(gEventHook, "y");
	flEnd[2] = GetEventFloat(gEventHook, "z");
	
	// Calculate weapon pos
	float flDistance = GetVectorDistance(flStart, flEnd); 
	float flPercent = (0.4 / (flDistance / 100.0)); 
	flStart[0] = flStart[0] + ((flEnd[0] - flStart[0]) * flPercent); 
	flStart[1] = flStart[1] + ((flEnd[1] - flStart[1]) * flPercent) - 0.08; 
	flStart[2] = flStart[2] + ((flEnd[2] - flStart[2]) * flPercent); 
	
	// Sent a beam
	TE_SetupBeamPoints(flStart, flEnd, iBeamModel, 0 , 0, 0, BEAM_LIFE, 2.0, 2.0, 10, 1.0, BEAM_COLOR, 30);
	TE_SendToAll();
}
public Action:WeaponTakeDamage(victim, &iAttacker, &inflictor, &Float:flDamage, &damagetype)
{
	// Initialize weapon index
	new weaponIndex;

	// If weapon isn't custom
	if(!IsCustomItem(iAttacker, weaponIndex))
	{
		return Plugin_Continue;
	}
	
	// Change damage
	flDamage *= WEAPON_MULTIPLIER_DAMAGE; 
	return Plugin_Changed;
}

public WeaponDeployPost(clientIndex,weaponIndex) 
{
	// If client just buy this custom weapon
	if(bHasCustomWeapon[clientIndex])
	{
		// Reset bool
		bHasCustomWeapon[clientIndex] = false;
		
		// Verify that the weapon is valid
		if(!IsValidEdict(weaponIndex))
		{
			return;
		}

		// Set custom name
		DispatchKeyValue(weaponIndex, "globalname", WEAPON_NAME);
	}
	
	// If weapon isn't valid, then stop
	if(!IsCustomItemEntity(weaponIndex))
	{
		return;
	}
	
	// Verify that the client is connected and alive
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}

	// Set weapon models
	// new sequence = GetEntProp(iViewModel, Prop_Data, "m_nSequence"); 
	// SetViewmodelAnimation(clientIndex, sequence);
	SetWeaponAnimation(clientIndex, ANIM_IDLE); 
	SetViewModel(clientIndex, weaponIndex, iViewModel);
	SetWorldModel(weaponIndex, iWorldModel);
} 
public OnClientPutInServer(clientIndex)
{
	SDKHook(clientIndex, SDKHook_WeaponDropPost, 	WeaponDropPost);
	SDKHook(clientIndex, SDKHook_WeaponSwitchPost,  WeaponDeployPost);
	SDKHook(clientIndex, SDKHook_OnTakeDamage,   	WeaponTakeDamage);
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	if(IsCustomItem(client, weaponIndex))
	{
		CreateTimer(0.0, Timer_SetWorldModel, weaponIndex);
	}
}
public Action:Timer_SetWorldModel(Handle:timer, any:weaponIndex) // address: 1521604
{
	SetEntProp(weaponIndex, Prop_Send, "m_iWorldModelIndex", iWorldModel);
	return Plugin_Stop;
}

stock void SetWorldModel(int weaponIndex, int modelIndex)
{
	// Set model for the entity
	SetEntProp(weaponIndex, Prop_Send, "m_iWorldModelIndex", modelIndex);
}

public Action:WeaponDropPost(clientIndex,weaponIndex)
{
	// Set dropped model on next frame
	RequestFrame(view_as<RequestFrameCallback>(SetDroppedModel), weaponIndex);
}


public SetDroppedModel(weaponIndex)
{
	// If weapon isn't custom
	if(!IsCustomItemEntity(weaponIndex))
	{
		return;
	}
	
	// Set dropped model
	SetEntityModel(weaponIndex, MODEL_WORLD);
}
bool IsCustomItem(clientIndex, &weaponIndex)
{
	// Validate client
	if (!IsPlayerExist(clientIndex))
	{
		return false;
	}
	
	// Get weapon index
	weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");
	
	// Verify that the weapon is valid
	if(!IsValidEdict(weaponIndex))
	{
		return false;
	}
	
	
	// Get weapon classname
	decl String:sClassname[32];
	GetEntityClassname(weaponIndex, sClassname, sizeof(sClassname));
	
	// If weapon classname isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_REFERANCE))
	{
		return false;
	}
	
	// Get weapon global name
	GetEntPropString(weaponIndex, Prop_Data, "m_iGlobalname", sClassname, sizeof(sClassname));

	// If weapon key isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_NAME))
	{
		 return false;
	}
	
	// If it is custom weapon
	return true;
}

bool:IsCustomItemEntity(weaponIndex)
{
	// Verify that the weapon is valid
	if(!IsValidEdict(weaponIndex))
	{
		return false;
	}
	
	// Get weapon classname
	decl String:sClassname[32];
	GetEntityClassname(weaponIndex, sClassname, sizeof(sClassname));
	
	// If weapon classname isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_REFERANCE))
	{
		return false;
	}
	
	// Get weapon global name
	GetEntPropString(weaponIndex, Prop_Data, "m_iGlobalname", sClassname, sizeof(sClassname));

	// If weapon key isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_NAME))
	{
		 return false;
	}
	
	// If it is custom weapon
	return true;
}

bool:IsPlayerExist(const clientIndex, const bool:aliveness = true)
{
    // If client isn't valid, then stop
    if(clientIndex <= 0 || clientIndex > MaxClients)
    {
        return false;
    }

    // If client isn't connected, then stop
    if(!IsClientConnected(clientIndex))
    {
        return false;
    }

    // If client isn't in game, then stop
    if(!IsClientInGame(clientIndex) || IsClientInKickQueue(clientIndex))
    {
        return false;
    }

    // If client is TV, then stop
    if(IsClientSourceTV(clientIndex))
    {
        return false;
    }

    // If client isn't alive, then stop
    if(aliveness && !IsPlayerAlive(clientIndex))
    {
        return false;
    }

    // If client exist
    return true;
}


stock void SetWeaponAnimation(int client, int nSequence)
{
    // Gets client viewmodel
    int view = GetEntPropEnt(client, Prop_Send, "m_hViewModel"); /// Play anims on the original model 

    // Validate viewmodel
    if (view != -1)
    {
        // Sets animation
        SetEntProp(view, Prop_Send, "m_nSequence", nSequence);
    }
}

stock void SetViewModel(int clientIndex, int weaponIndex, int modelIndex)
{
	// Get view index
	int viewIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hViewModel");

	// Verify that the entity is valid
	if(IsValidEdict(viewIndex))
	{
		// Delete default model index
		SetEntProp(weaponIndex, Prop_Send, "m_nModelIndex", 0);
		
		// Set new view model index for the weapon
		// SetEntProp(viewIndex, Prop_Send, "m_nSequence", sequence);
		SetEntProp(viewIndex, Prop_Send, "m_nModelIndex", modelIndex);
		
	}
}

/**
 * @brief Sets the world weapon's model.
 *
 * @param weaponIndex		The weapon index.
 * @param modelIndex		The model index. (Must be precached)
 *
 * @noreturn
 **/

CheckHooks()
{
	new bool:bShouldHook = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bStopSound[i])
		{
			bShouldHook = true;
			break;
		}
	}
	
	// Fake (un)hook because toggling actual hooks will cause server instability.
	g_bHooked = bShouldHook;
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	PrintToServer("Hook_NormalSound = %s", sample);
	
	/*return Plugin_Stop;
	
	// Ignore non-weapon sounds.
	if (!g_bHooked || !(strncmp(sample, "weapons", 7) == 0 || strncmp(sample[1], "weapons", 7) == 0))
		return Plugin_Continue;
	
	decl i, j;
	
	for (i = 0; i < numClients; i++)
	{
		if (g_bStopSound[clients[i]])
		{
			// Remove the client from the array.
			for (j = i; j < numClients-1; j++)
			{
				clients[j] = clients[j+1];
			}
			
			numClients--;
			i--;
		}
	}
	
	return (numClients > 0) ? Plugin_Changed : Plugin_Stop;*/
}

public Action:CSS_Hook_ShotgunShot(const String:te_name[], const Players[], numClients, Float:delay)
{
	int weaponIndex;
	PrintToServer("CSS_Hook_ShotgunShot = %s", te_name);
	
	int clientIndex = TE_ReadNum("m_iPlayer") + 1;
	if(IsCustomItem(clientIndex, weaponIndex))
	{
		EmitSoundToAll(SOUND_FIRE, clientIndex, SNDCHAN_WEAPON, SNDLEVEL_ROCKET);
		EmitSoundToAll(SOUND_FIRE, clientIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
		return Plugin_Stop;
	}
	return Plugin_Continue;
	
	if (!g_bHooked)
		return Plugin_Continue;
	
	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	new newTotal = 0;
	
	for (i = 0; i < numClients; i++)
	{
		client = Players[i];
		
		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}
	
	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;
	
	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;
	

	// Re-broadcast to clients that still need it.
	decl Float:vTemp[3];
	TE_Start("Shotgun Shot");
	/* TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread")); */
	TE_Send(newClients, newTotal, delay);
	
	return Plugin_Continue;
}

public Action:DODS_Hook_FireBullets(const String:te_name[], const Players[], numClients, Float:delay)
{
	if (!g_bHooked)
		return Plugin_Continue;
	
	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	new newTotal = 0;
	
	for (i = 0; i < numClients; i++)
	{
		client = Players[i];
		
		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}
	
	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;
	
	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;
	
	// Re-broadcast to clients that still need it.
	decl Float:vTemp[3];
	/* TE_Start("FireBullets");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_flSpread", TE_ReadFloat("m_flSpread"));
	TE_Send(newClients, newTotal, delay); */
	
	return Plugin_Stop;
}
