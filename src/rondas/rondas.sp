
#undef REQUIRE_PLUGIN
#include <franug_zp>
#define REQUIRE_PLUGIN


#define DMG_GENERIC									0
#define DMG_CRUSH										(1 << 0)
#define DMG_BULLET									(1 << 1)
#define DMG_SLASH										(1 << 2)
#define DMG_BURN										(1 << 3)
#define DMG_VEHICLE									(1 << 4)
#define DMG_FALL										(1 << 5)
#define DMG_BLAST										(1 << 6)
#define DMG_CLUB										(1 << 7)
#define DMG_SHOCK										(1 << 8)
#define DMG_SONIC										(1 << 9)
#define DMG_ENERGYBEAM							(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE		(1 << 11)
#define DMG_NEVERGIB								(1 << 12)
#define DMG_ALWAYSGIB								(1 << 13)
#define DMG_DROWN										(1 << 14)
#define DMG_TIMEBASED								(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE								(1 << 15)
#define DMG_NERVEGAS								(1 << 16)
#define DMG_POISON									(1 << 17)
#define DMG_RADIATION								(1 << 18)
#define DMG_DROWNRECOVER						(1 << 19)
#define DMG_ACID										(1 << 20)
#define DMG_SLOWBURN								(1 << 21)
#define DMG_REMOVENORAGDOLL					(1 << 22)
#define DMG_PHYSGUN									(1 << 23)
#define DMG_PLASMA									(1 << 24)
#define DMG_AIRBOAT									(1 << 25)
#define DMG_DISSOLVE								(1 << 26)
#define DMG_BLAST_SURFACE						(1 << 27)
#define DMG_DIRECT									(1 << 28)
#define DMG_BUCKSHOT								(1 << 29)

#define FFADE_IN		0x0001	


// Handles
new Handle:cvarInterval;
new Handle:AmmoTimer;
new Handle:AmmoTimer3;
new Handle:cvarInterval3;
new Handle:dorada = INVALID_HANDLE;
//new Handle:hTimer;
//new Handle:hTimer2;
new Handle:hPush;
new Handle:hHeight;

// Bools
new bool:g_AmmoInfi[MAXPLAYERS+1] = {false, ...};


new VelocityOffset_0;
new VelocityOffset_1;
new BaseVelocityOffset;
//new Nemesis = 0;
new Survivor = 0;
new inmunidad[MAXPLAYERS+1];
new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

public OnPluginStartZM()
{
	LoadTranslations ("zpround.phrases");
	// ======================================================================
	
	// ======================================================================
	
	RegAdminCmd("sm_nemesis", NemesisA, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_zplague", Ronda_PlagueA, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_survivor", SurvivorA, ADMFLAG_CUSTOM2);

	RegAdminCmd("sm_municionall", municionall, ADMFLAG_CUSTOM2);
	
	// ======================================================================
	
	// ======================================================================
	
	dorada = CreateConVar("zombieplague_dorada", "15.0", "Multipliear of damage for golden weapons");
	
	cvarInterval = CreateConVar("ammo_interval", "5", "How often to reset ammo (in seconds).", _, true, 1.0);
	cvarInterval3 = CreateConVar("hp_interval", "1", "Show HP of survivor/nemesis each X second.", _, true, 1.0);
	activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	
	clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
	priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
	secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");

	VelocityOffset_0=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	if(VelocityOffset_0==-1)
	SetFailState("[BunnyHop] Error: Failed to find Velocity[0] offset, aborting");
	VelocityOffset_1=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	if(VelocityOffset_1==-1)
	SetFailState("[BunnyHop] Error: Failed to find Velocity[1] offset, aborting");
	BaseVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	if(BaseVelocityOffset==-1)
	SetFailState("[BunnyHop] Error: Failed to find the BaseVelocity offset, aborting");
	
	// Create cvars
	hPush=CreateConVar("bunnyhop_push","1.0","The forward push when you jump (for nemesis)");
	hHeight=CreateConVar("bunnyhop_height","5.0","The upward push when you jump (for nemesis)");
	
	AutoExecConfig(true, "zombiereloaded/zombie_plague");	
}
public OnMapStartZM()
{	
	PrecacheModel("models/props/de_train/barrel.mdl");
	PrecacheSound("franug/zombie_plague/survivor1.wav");
	PrecacheSound("franug/zombie_plague/survivor2.wav");
	//PrecacheSound("franug/zombie_plague/es_survivor.wav");
	PrecacheSound("franug/zombie_plague/nemesis1.wav");
	PrecacheSound("franug/zombie_plague/nemesis2.wav");
	//PrecacheSound("franug/zombie_plague/es_nemesis.wav");
	PrecacheSound("items/smallmedkit1.wav");
	//PrecacheSound("medicsound/medic.wav");
	//AddFileToDownloadsTable("sound/medicsound/medic.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/survivor1.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/survivor2.wav");
	//AddFileToDownloadsTable("sound/franug/zombie_plague/es_survivor.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis_pain1.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis_pain2.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis_pain3.wav");
	PrecacheSound("franug/zombie_plague/nemesis_pain1.wav");
	PrecacheSound("franug/zombie_plague/nemesis_pain2.wav");
	PrecacheSound("franug/zombie_plague/nemesis_pain3.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis1.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis2.wav");
	//AddFileToDownloadsTable("sound/franug/zombie_plague/es_nemesis.wav");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.dx80.vtx");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.dx90.vtx");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.phy");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.sw.vtx");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.vvd");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_00.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_00.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_00n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_01.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_01.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_01n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_02.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_02.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_02n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_04.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_04.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_04n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_05.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_05.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_05n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_06.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_06.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_06n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_07.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_07.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_07n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_08.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_08.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_08n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_09.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_09.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_09n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_10.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens2_pipea.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens2_pipeb.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens2_pipec.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/iris.vtf");
	PrecacheModel("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt_phong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_body.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_body.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_body_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_boots.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_boots.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_boots_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_eyes.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_fingers.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hands.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hands.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hands_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hat.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hat.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hat_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_head.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_head.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_head_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_belts.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_light.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_phong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_plastic.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_necklace.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_pants.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_pants.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_pants_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_phong.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades_glass.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades_glass_phong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades_nophong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_teeth.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest_nocull.vmt");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.dx80.vtx");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.dx90.vtx");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.phy");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.sw.vtx");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.vvd");
	PrecacheModel("models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	PrecacheSound("franug/zombie_plague/resistencia_armadura.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/resistencia_armadura.wav");

	if (AmmoTimer != INVALID_HANDLE) {
		KillTimer(AmmoTimer);
	}
	
	new Float:interval = GetConVarFloat(cvarInterval);
	AmmoTimer = CreateTimer(interval, ResetAmmo, _, TIMER_REPEAT);

	if (AmmoTimer3 != INVALID_HANDLE) {
		KillTimer(AmmoTimer3);
	}
	
	new Float:interval3 = GetConVarFloat(cvarInterval3);
	AmmoTimer3 = CreateTimer(interval3, ResetAmmo3, _, TIMER_REPEAT);

	/* OnMapStart20();
	OnMapStart2();
	OnMapStartbomba(); */
}
public PlayerSpawnZM(any:client)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
		return;
	}
	
	g_AmmoInfi[client] = false;
	Es_Nemesis[client] = false;
	inmunidad[client] = 0;
}

public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
	return false; 
	
	return true; 
}
public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if (!IsValidClient(attacker))
	return Plugin_Continue;

	if(Es_Nemesis[attacker])
	{
		DealDamage(client,3000,attacker,DMG_SLASH,"zombie_claws_of_death");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:OnClientDisconnectZM(client)
{
	if (!client || IsFakeClient(client))
	return;
	if(Nemesis == client)
	{
		ServerCommand("mp_restartgame 2");
		Nemesis = 0;
		PrintToChatAll("\x04[SM_Franug-ZombiePlague] \x05%t","El jugador NEMESIS se ha desconectado");
	}
	else if(Survivor == client)
	{
		ServerCommand("mp_restartgame 2");
		Survivor = 0;
		PrintToChatAll("\x04[SM_Franug-ZombiePlague] \x05%t","El jugador SURVIVOR se ha desconectado");
	}
}
public Action:municionall(client, args)
{
	for (new i = 1; i < GetMaxClients(); i++)
	{
		if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			g_AmmoInfi[i] = true;
		}
	}
	PrintToChatAll("\x04[SM_Franug-ZombiePlague] \x05%t", "Activada MUNICION INFINITA");
} 
public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt2(client, activeOffset);
	if (clip1Offset != -1 && zomg != -1)
	SetEntData(zomg, clip1Offset, 999, 4, true);
	if (clip2Offset != -1 && zomg != -1)
	SetEntData(zomg, clip2Offset, 999, 4, true);
	if (priAmmoTypeOffset != -1 && zomg != -1)
	SetEntData(zomg, priAmmoTypeOffset, 999, 4, true);
	if (secAmmoTypeOffset != -1 && zomg != -1)
	SetEntData(zomg, secAmmoTypeOffset, 999, 4, true);
}
public Action:OnClientPostAdminCheckZM(client)
{
	g_AmmoInfi[client] = false;
}
public Action:ResetAmmo(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client) && (g_AmmoInfi[client]))
		{
			Client_ResetAmmo(client);
		}
	}
}
public Action:ResetAmmo3(Handle:timer)
{
	if(IsValidClient(Nemesis) && IsPlayerAlive(Nemesis) && rondanemesis)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i) && Nemesis != i)
			{
				ZR_HumanClient(i);
			}
		}
		new vida_nemesiss = GetClientHealth(Nemesis);
		PrintCenterTextAll("%t","Vida del NEMESIS", vida_nemesiss);
	}
	else if(IsValidClient(Survivor) && IsPlayerAlive(Survivor) && rondasurvivor)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i) && Survivor != i)
			{
				ZR_InfectClient(i);
			}
		}
		new vida_survivors = GetClientHealth(Survivor);
		PrintCenterTextAll("%t","Vida del SURVIVOR", vida_survivors);
	}
}
JugadorAleatorio()
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
} 
Event_RoundStartZM()
{
	Nemesis = 0;
	Survivor = 0;
	new maxent = GetMaxEntities();
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			if(bIsGoldenGun[i])
			{
				bIsGoldenGun[i]=false;
				
			}
			
		}
	}
	
	for(new client=1; client <= MaxClients; client++)
	{
		ZP_SetSpecial(client, false);
	}
	
	rondaplague = false;
	rondasurvivor = false;
	rondanemesis = false;
	new random = GetRandomInt(10, 15);
	new Float:numeroR = random * 1.0;
	CreateTimer(numeroR, RondaQ);
	
	if(barricada)
		ServerCommand("zr_respawn 1");

	ServerCommand("zr_zspawn 1");
}
public Action:RondaQ(Handle:timer)
{
	if (barricada)
	{
		new zombi = 0;
		for(new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
			{
				zombi++;
			}
		}
		if (zombi == 0)
		{
			new random = GetRandomInt(1, 21);
			
			switch(random)
			{
			case 1:
				{
					Ronda_Nemesis(); 
				}
			case 2:
				{
					Ronda_Survivor();
				}
			case 3:
				{
					Ronda_Plague();
				}
			}
		}
	}
}
Ronda_Plague()
{
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			jugadores++;
		}
	}  
	new vida_total = (jugadores * 1000);
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == 2)
			{
				ZR_InfectClient(i);
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_T);
				SetEntityModel(i, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
				Es_Nemesis[i] = true;
				#if defined _zp_included_
				if(g_zombieplague)
				{
					ZP_SetSpecial(i, true);
				}
				#endif
			}
			else if(GetClientTeam(i) == 3)
			{
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_CT);
				bZombie[i] = false;
				g_AmmoInfi[i] = true;
				new wepIdx;
				// strip all weapons
				for (new s = 0; s < 4; s++)
				{
					if ((wepIdx = GetPlayerWeaponSlot(i, s)) != -1)
					{
						RemovePlayerItem(i, wepIdx);
						RemoveEdict(wepIdx);
					}
				}
				GivePlayerItem(i, "weapon_knife");
				new ent = GivePlayerItem(i,"weapon_deagle");
				bIsGoldenGun[ent]=true;
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, 255, 215, 0);
				new ent2 = GivePlayerItem(i,"weapon_m249");
				bIsGoldenGun[ent2]=true;
				SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent2, 255, 215, 0);
				#if defined _zp_included_
				if(g_zombieplague)
				{
					ZP_SetSpecial(i, true);
				}
				#endif
				SetEntityModel(i, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
				
			}
		}
	}    
	PrintToChatAll("\x04[InternacionalZP] \x05%RONDA Plague!");
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondaplague = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
public Action:Ronda_PlagueA(client, args)
{
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			//ZR_InfectClient(i, -1, true, false, false);
			//ZR_InfectClient(i);
			jugadores++;
		}
	}  
	new vida_total = (jugadores * 1000);
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == 2)
			{
				ZR_InfectClient(i);
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_T);
				SetEntityModel(i, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
				Es_Nemesis[i] = true;
				#if defined _zp_included_
				if(g_zombieplague)
				{
					ZP_SetSpecial(i, true);
				}
				#endif
			}
			else if(GetClientTeam(i) == 3)
			{
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_CT);
				bZombie[i] = false;
				g_AmmoInfi[i] = true;
				new wepIdx;
				// strip all weapons
				for (new s = 0; s < 4; s++)
				{
					if ((wepIdx = GetPlayerWeaponSlot(i, s)) != -1)
					{
						RemovePlayerItem(i, wepIdx);
						RemoveEdict(wepIdx);
					}
				}
				GivePlayerItem(i, "weapon_knife");
				new ent = GivePlayerItem(i,"weapon_deagle");
				bIsGoldenGun[ent]=true;
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, 255, 215, 0);
				new ent2 = GivePlayerItem(i,"weapon_m249");
				bIsGoldenGun[ent2]=true;
				SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent2, 255, 215, 0);
				SetEntityModel(i, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
				#if defined _zp_included_
				if(g_zombieplague)
				{
					ZP_SetSpecial(i, true);
				}
				#endif
				
			}
		}
	}    
	PrintToChatAll("\x04[InternacionalZP] RONDA Plague!");
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondaplague = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
Ronda_Survivor()
{
	Survivor = JugadorAleatorio(); 
	if(Survivor < 0)
	return;
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && Survivor != i)
		{
			
			ZR_InfectClient(i);
			jugadores++;
		}
	}   
	PrintToChatAll("\x04[InternacionalZP] \x05RONDA SURVIVOR!");
	new vida_survivor = jugadores * 100;
	SetEntityHealth(Survivor, vida_survivor);
	CS_SwitchTeam(Survivor, CS_TEAM_CT);
	bZombie[Survivor] = false;
	inmunidad[Survivor] = 5;
	g_AmmoInfi[Survivor] = true;
	new wepIdx;
	// strip all weapons
	for (new s = 0; s < 4; s++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(Survivor, s)) != -1)
		{
			RemovePlayerItem(Survivor, wepIdx);
			RemoveEdict(wepIdx);
		}
	}
	GivePlayerItem(Survivor, "weapon_knife");
	new ent = GivePlayerItem(Survivor,"weapon_deagle");
	bIsGoldenGun[ent]=true;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 255, 215, 0);
	new ent2 = GivePlayerItem(Survivor,"weapon_m249");
	bIsGoldenGun[ent2]=true;
	SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent2, 255, 215, 0);
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/survivor1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/survivor2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Survivor)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_T);
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	SetEntityModel(Survivor, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	#if defined _zp_included_
	if(g_zombieplague)
	{
		ZP_SetSpecial(Survivor, true);
	}
	#endif
	rondasurvivor = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
Ronda_Nemesis()
{
	Nemesis = JugadorAleatorio();
	if(Nemesis < 0)
	return;
	//ServerCommand("zr_hitgroups 0");
	//ZR_InfectClient(Nemesis, -1, true, false, false);
	ZR_InfectClient(Nemesis);
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			jugadores++;
		}
	}
	PrintToChatAll("\x04[InternacionalZP] \x05RONDA NEMESIS!");
	new vida_nemesis = (jugadores * 1000);
	SetEntityHealth(Nemesis, vida_nemesis);
	
	CS_SwitchTeam(Nemesis, CS_TEAM_T);
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Nemesis)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_CT);
		bZombie[x] = false;
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	SetEntityModel(Nemesis, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	Es_Nemesis[Nemesis] = true;
	#if defined _zp_included_
	if(g_zombieplague)
	{
		ZP_SetSpecial(Nemesis, true);
	}
	#endif
	rondanemesis = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
public Action:NemesisA(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_nemesis <#userid|nombre>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	new target;
	if((target = FindTarget(client, arg)) == -1)
	{
		PrintToChat(client, "\x04[InternacionalZP] Objetivo no encontrado");
		return Plugin_Handled; // Target not found...
	}
	Nemesis = target;
	if(Nemesis < 0)
	return Plugin_Continue;
	//ServerCommand("zr_hitgroups 0");
	//ZR_InfectClient(Nemesis, -1, true, false, false);
	ZR_InfectClient(Nemesis);
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			jugadores++;
		}
	}
	PrintToChatAll("\x04[InternacionalZP] \x05RONDA NEMESIS!");
	new vida_nemesis = (jugadores * 1000);
	SetEntityHealth(Nemesis, vida_nemesis);
	CS_SwitchTeam(Nemesis, CS_TEAM_T);
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Nemesis)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_CT);
		bZombie[x] = false;
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondanemesis = true;
	SetEntityModel(Nemesis, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	Es_Nemesis[Nemesis] = true;
	#if defined _zp_included_
	if(g_zombieplague)
	{
		ZP_SetSpecial(Nemesis, true);
	}
	#endif
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
	return Plugin_Continue;
}
public Action:SurvivorA(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_survivor <#userid|nombre>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	new target;
	if((target = FindTarget(client, arg)) == -1)
	{
		PrintToChat(client, "\x04[InternacionalZP] Objetivo no encontrado");
		return Plugin_Handled; // Target not found...
	}
	Survivor = target;
	if(Survivor < 0)
	return Plugin_Continue;
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && Survivor != i)
		{
			//ZR_InfectClient(i, -1, true, false, false);
			ZR_InfectClient(i);
			jugadores++;
		}
	}   
	PrintToChatAll("\x04[InternacionalZP] RONDA SURVIVOR!");
	new vida_survivor = jugadores * 100;
	SetEntityHealth(Survivor, vida_survivor);
	CS_SwitchTeam(Survivor, CS_TEAM_CT);
	bZombie[Survivor] = false;
	g_AmmoInfi[Survivor] = true;
	new wepIdx;
	// strip all weapons
	for (new s = 0; s < 4; s++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(Survivor, s)) != -1)
		{
			RemovePlayerItem(Survivor, wepIdx);
			RemoveEdict(wepIdx);
		}
	}
	GivePlayerItem(Survivor, "weapon_knife");
	new ent = GivePlayerItem(Survivor,"weapon_deagle");
	bIsGoldenGun[ent]=true;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 255, 215, 0);
	new ent2 = GivePlayerItem(Survivor,"weapon_m249");
	bIsGoldenGun[ent2]=true;
	SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent2, 255, 215, 0);
	
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/survivor1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/survivor2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Survivor)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_T);
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondasurvivor = true;
	SetEntityModel(Survivor, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	#if defined _zp_included_
	if(g_zombieplague)
	{
		ZP_SetSpecial(Survivor, true);
	}
	#endif
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
	
	return Plugin_Continue;
}
stock DealDamage(nClientVictim, nDamage, nClientAttacker = 0, nDamageType = DMG_GENERIC, String:sWeapon[] = "")
// ----------------------------------------------------------------------------
{
	// taken from: http://forums.alliedmods.net/showthread.php?t=111684
	// thanks to the authors!
	if(	nClientVictim > 0 &&
			IsValidEdict(nClientVictim) &&
			IsClientInGame(nClientVictim) &&
			IsPlayerAlive(nClientVictim) &&
			nDamage > 0)
	{
		new EntityPointHurt = CreateEntityByName("point_hurt");
		if(EntityPointHurt != 0)
		{
			new String:sDamage[16];
			IntToString(nDamage, sDamage, sizeof(sDamage));
			new String:sDamageType[32];
			IntToString(nDamageType, sDamageType, sizeof(sDamageType));
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"DamageTarget",	"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"Damage",				sDamage);
			DispatchKeyValue(EntityPointHurt,		"DamageType",		sDamageType);
			if(!StrEqual(sWeapon, ""))
			DispatchKeyValue(EntityPointHurt,	"classname",		sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt,	"Hurt",					(nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt,		"classname",		"point_hurt");
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_donthurtme");
			RemoveEdict(EntityPointHurt);
		}
	}
}
public Action:PlayerJumpZM(any:client)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (Es_Nemesis[client]) saltoalto13(client);
}
saltoalto13(client)
{
	new Float:finalvec[3];
	finalvec[0]=GetEntDataFloat(client,VelocityOffset_0)*GetConVarFloat(hPush)/2.0;
	finalvec[1]=GetEntDataFloat(client,VelocityOffset_1)*GetConVarFloat(hPush)/2.0;
	finalvec[2]=GetConVarFloat(hHeight)*50.0;
	SetEntDataVector(client,BaseVelocityOffset,finalvec,true);
	new Float:pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	new number = GetRandomInt(1, 3);
	switch (number)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis_pain1.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis_pain2.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	case 3:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis_pain3.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	}
}
public OnClientPutInServerD(client)
{  
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidClient(attacker))
	{
		//PrintToChat(attacker, "atacado");
		new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (WeaponIndex < 0) return Plugin_Continue;
		if(IsValidEntity(WeaponIndex) && bIsGoldenGun[WeaponIndex])  
		{ 
			//PrintToChat(attacker, "atacado con dorada");
			if (GetClientTeam(attacker) != GetClientTeam(victim))
			{
				IgniteEntity(victim, 1.0);
				damage = (damage * GetConVarFloat(dorada));
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}