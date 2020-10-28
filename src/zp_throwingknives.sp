#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_zp>
#include <cssthrowingknives>

// configuration part
#define AWARDNAME "throwingknives" // Name of award
#define PRICE 14 // Award price
#define AWARDTEAM ZP_BOTH // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_throwingknives.phrases" // Set translations file for this subplugin
// end configuration


// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
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
		PrintToChat(client, "\x04[Internacional ZP] \x05%t", "you bought ThrowingKnives");
		new cuchillos13 = GetClientThrowingKnives(client);
		cuchillos13 += 1;
		SetClientThrowingKnives(client, cuchillos13);
	}
}