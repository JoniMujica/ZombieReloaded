/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:          zombiesounds.inc
 *  Type:          Core
 *  Description:   Zombie sound effects.
 *
 *  Copyright (C) 2009-2013  Greyscale, Richard Helgeby
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

/**
 * @section Defines for min moaning, groan, death and scream sound files index.
 */
#define SOUND_MOAN_MIN 1
#define SOUND_GROAN_MIN 1
#define SOUND_DEATH_MIN 1
#define SOUND_SCREAM_MIN 1
/**
 * @endsection
 */

/**
 * Zombie sound types
 */
enum ZombieSounds
{
    Moan, /** Zombie's moan periodically */
    Groan, /** When zombie is hurt */
    Death, /** When a zombie is killed */
    Scream, /** When a zombie infects a human */
}

#include "zr/soundeffects/cvars"

/**
 * Array for storing zombie moaning timer handles per client.
 */
new Handle:tSEffectsMoan[MAXPLAYERS + 1];

/**
 * Number of sound commands executed by the player.
 */
new g_SEffectsCommandCount[MAXPLAYERS + 1];

/**
 * Timers for resetting sound command counters.
 */
new Handle:g_hSEffectsCommandTimer[MAXPLAYERS + 1];

/**
 * Client is joining the server.
 *
 * @param client    The client index.
 */
ZombieSoundsClientInit(client)
{
    // Reset timer handle.
    tSEffectsMoan[client] = INVALID_HANDLE;

    // Reset command counter and make sure there's no timer running.
    g_SEffectsCommandCount[client] = 0;
    ZREndTimer(g_hSEffectsCommandTimer[client]);
}

/**
 * Client is spawning into the game.
 *
 * @param client    The client index.
 */
ZombieSoundsOnClientSpawn(client)
{
    // If timer is running, kill it.
    if (tSEffectsMoan[client] != INVALID_HANDLE)
    {
        KillTimer(tSEffectsMoan[client]);
    }

    // Reset timer handle.
    tSEffectsMoan[client] = INVALID_HANDLE;

    // Reset command counter and kill timer.
    g_SEffectsCommandCount[client] = 0;
    ZREndTimer(g_hSEffectsCommandTimer[client]);
}

/**
 * Client has been killed.
 *
 * @param client    The client index.
 */
ZombieSoundsOnClientDeath(client)
{
    // If timer is running, kill it.
    if (tSEffectsMoan[client] != INVALID_HANDLE)
    {
        KillTimer(tSEffectsMoan[client]);
    }

    // Reset timer handle.
    tSEffectsMoan[client] = INVALID_HANDLE;

    // Reset command counter and kill timer.
    g_SEffectsCommandCount[client] = 0;
    ZREndTimer(g_hSEffectsCommandTimer[client]);

    // If player isn't a zombie, then stop.
    if (!InfectIsClientInfected(client))
    {
        return;
    }

    // If death sound cvar is disabled, then stop.
    new bool:death = SEffects_GetDeathEmission();
    if (!death)
    {
        return;
    }

    // Get random death sound.
    decl String:sound[SOUND_MAX_PATH];
    ZombieSoundsGetRandomSound(sound, Death);

    SEffectsEmitSoundFromClient(client, sound);
}

/**
 * Client has been hurt.
 *
 * @param client    The client index.
 */
ZombieSoundsOnClientHurt(client)
{
    // If player isn't a zombie, then stop.
    if (!InfectIsClientInfected(client))
    {
        return;
    }

    // Get groan factor, if 0, then stop.
    new groan = SEffects_GetGroanProbability();
    if (!groan)
    {
        return;
    }

    // 1 in 'groan' chance of groaning.
    if (GetRandomInt(1, groan) == 1)
    {
        // Get random groan sound.
        decl String:sound[SOUND_MAX_PATH];
        ZombieSoundsGetRandomSound(sound, Groan);

        SEffectsEmitSoundFromClient(client, sound);
    }
}

/**
 * Client has been infected.
 *
 * @param client    The client index.
 */
ZombieSoundsOnClientInfected(client)
{
    // If interval is set to 0, then stop.
    new Float:interval = SEffects_GetMoanTime();
    if (!interval)
    {
        return;
    }

    // If timer is currently running, kill it.
    if (tSEffectsMoan[client] != INVALID_HANDLE)
    {
        KillTimer(tSEffectsMoan[client]);
    }

    // Start repeating timer.
    tSEffectsMoan[client] = CreateTimer(interval, ZombieSoundsMoanTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

/**
 * Round ended.
 */
ZombieSoundsOnRoundEnd()
{
    ZombieSoundsResetCmdCounters();
    ZombieSoundsResetCmdTimers();
}

ZombieSoundsOnMapEnd()
{
    ZombieSoundsOnRoundEnd();
}

ZombieSoundsOnCommandsCreate()
{
    RegConsoleCmd("scream", ZombieSoundsScreamCommand, "Emits a scream sound, if the player is a zombie.");
    RegConsoleCmd("moan", ZombieSoundsMoanCommand, "Emits a moan sound, if the player is a zombie.");
}

/**
 * Gets a random zombie sound from hl2 folder.
 *
 * @param sound     The randomly picked sound.
 * @param soundtype The type of sound to get. (See enum ZombieSounds)
 * @return          True if sound was successfully picked, false otherwise.
 */
bool:ZombieSoundsGetRandomSound(String:sound[], ZombieSounds:soundtype)
{
    new soundmin;
    new soundmax;
    decl String:soundpath[SOUND_MAX_PATH];

    switch(soundtype)
    {
        // Find moan sound.
        case Moan:
        {
            // Copy min and max
            soundmin = SOUND_MOAN_MIN;
            soundmax = SEffects_GetMax(Moan);

            // Read path
            SEffects_GetPath(soundpath, Moan);
        }
        // Find groan sound. (zombie shot)
        case Groan:
        {
            // Copy min and max
            soundmin = SOUND_GROAN_MIN;
            soundmax = SEffects_GetMax(Groan);

            // Read path
            SEffects_GetPath(soundpath, Groan);
        }
        // Find death sound.
        case Death:
        {
            // Copy min and max
            soundmin = SOUND_DEATH_MIN;
            soundmax = SEffects_GetMax(Death);

            // Read path
            SEffects_GetPath(soundpath, Death);
        }
        // Find scream sound.
        case Scream:
        {
            // Copy min and max
            soundmin = SOUND_SCREAM_MIN;
            soundmax = SEffects_GetMax(Scream);

            // Read path
            SEffects_GetPath(soundpath, Scream);
        }
        // Invalid case given.
        default:
        {
            // No handled case was given.
            return false;
        }
    }

    // Pick a random integer between min and max sound file index.
    new randsound = GetRandomInt(soundmin, soundmax);

    // Format random index into sound path.
    Format(sound, SOUND_MAX_PATH, soundpath, randsound);

    // Found sound.
    return true;
}

/**
 * Timer callback, repeats a moaning sound on zombies.
 *
 * @param timer     The timer handle.
 * @param client    The client index.
 */
public Action:ZombieSoundsMoanTimer(Handle:timer, any:client)
{
    // If client isn't in-game or client is no longer a zombie, then stop.
    if (!IsClientInGame(client) || !InfectIsClientInfected(client))
    {
        // Reset timer handle.
        tSEffectsMoan[client] = INVALID_HANDLE;

        // Stop timer.
        return Plugin_Stop;
    }

    // Emit moan sound.
    ZombieSoundsMoan(client);

    // Allow timer to continue.
    return Plugin_Continue;
}

/**
 * Emits a moan sound from the specified client.
 *
 * @param client    Client index.
 */
ZombieSoundsMoan(client)
{
    // Get random moan sound.
    decl String:sound[SOUND_MAX_PATH];
    ZombieSoundsGetRandomSound(sound, Moan);

    // Emit sound from client.
    SEffectsEmitSoundFromClient(client, sound, SNDLEVEL_SCREAMING);
}

/**
 * Emits the scream sound (on infection) from the specified client.
 *
 * @param client    Client index.
 */
ZombieSoundsScream(client)
{
    new Float:delayTimer = 0.0;

    // If the game is CSGO, we need to add delay
    if (g_Game == Game_CSGO)
        delayTimer = 0.1;
    
    // Emit infect sound with delay
    CreateTimer(delayTimer, ZombieSoundsScreamTimer, client, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Emits the scream sound (on infection) with delay.
 *
 * @param client    Client index.
 */
public Action:ZombieSoundsScreamTimer(Handle:timer, any client)
{
    // Get random scream sound.
    decl String:sound[SOUND_MAX_PATH];

    GetConVarString(g_hCvarsList[CVAR_INFECT_SOUND], sound, sizeof(sound));

    // If cvar not contains path, get random scream sound.
    if (!sound[0]) {
        ZombieSoundsGetRandomSound(sound, Scream);
    }

    if (sound[0])
    {
        // Emit infect sound from infected client.
        SEffectsEmitSoundFromClient(client, sound, SNDLEVEL_SCREAMING);
    }
}

/**
 * Starts a reset timer for the client's command counter if not already started.
 *
 * @param client    Client index.
 */
ZombieSoundsCmdTimerCheck(client)
{
    // Only create timer if it doesn't exist.
    if (g_hSEffectsCommandTimer[client] == INVALID_HANDLE)
    {
        new Float:timespan = SEffects_GetCommandTimespan();

        // Only create timer if time span is enabled.
        if (timespan > 0.0)
        {
            g_hSEffectsCommandTimer[client] = CreateTimer(timespan, ZombieSoundsCmdTimer, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
        }
    }
}

/**
 * Resets all command counters.
 */
ZombieSoundsResetCmdCounters()
{
    for (new client = 0; client <= MAXPLAYERS; client++)
    {
        g_SEffectsCommandCount[client] = 0;
    }
}

/**
 * Stops all command counter timers.
 */
ZombieSoundsResetCmdTimers()
{
    for (new client = 0; client <= MAXPLAYERS; client++)
    {
        ZREndTimer(g_hSEffectsCommandTimer[client]);
    }
}

/**
 * Returns whether a player is allowed to play a zombie sound or not.
 *
 * @param client    Client index.
 * @return          True if allowed, false otherwise.
 */
bool:ZombieSoundsCommandAllowed(client)
{
    new limit = SEffects_GetCommandLimit();

    if (limit <= 0 ||
        g_SEffectsCommandCount[client] < limit)
    {
        return true;
    }

    return false;
}

/**
 * Scream command handler.
 */
public Action:ZombieSoundsScreamCommand(client, argc)
{
    if (IsClientInGame(client) &&
        IsPlayerAlive(client) &&
        InfectIsClientInfected(client) &&
        ZombieSoundsCommandAllowed(client))
    {
        ZombieSoundsScream(client);
        g_SEffectsCommandCount[client]++;
        ZombieSoundsCmdTimerCheck(client);
    }

    return Plugin_Handled;
}

/**
 * Moan command handler.
 */
public Action:ZombieSoundsMoanCommand(client, argc)
{
    if (IsClientInGame(client) &&
        IsPlayerAlive(client) &&
        InfectIsClientInfected(client) &&
        ZombieSoundsCommandAllowed(client))
    {
        ZombieSoundsMoan(client);
        g_SEffectsCommandCount[client]++;
        ZombieSoundsCmdTimerCheck(client);
    }

    return Plugin_Handled;
}

/**
 * Command counter reset timer.
 */
public Action:ZombieSoundsCmdTimer(Handle:timer, any:client)
{
    g_SEffectsCommandCount[client] = 0;
}

/**
 * Precache zombie sounds
 */
ZombieSoundsLoad()
{
    decl String:soundpath[SOUND_MAX_PATH];
    //Moan
    for (int i = SOUND_MOAN_MIN; i <= SEffects_GetMax(Moan); i++) {
        SEffects_GetPath(soundpath, Moan);
        // Format random index into sound path.
        Format(soundpath, SOUND_MAX_PATH, soundpath, i);
        PrecacheSound(soundpath, false);
    }
    //Groan
    for (int i = SOUND_GROAN_MIN; i <= SEffects_GetMax(Groan); i++) {
        SEffects_GetPath(soundpath, Groan);
        // Format random index into sound path.
        Format(soundpath, SOUND_MAX_PATH, soundpath, i);
        PrecacheSound(soundpath, false);
    }
    //Death
    for (int i = SOUND_DEATH_MIN; i <= SEffects_GetMax(Death); i++) {
        SEffects_GetPath(soundpath, Death);
        // Format random index into sound path.
        Format(soundpath, SOUND_MAX_PATH, soundpath, i);
        PrecacheSound(soundpath, false);
    }
    //Scream
    for (int i = SOUND_SCREAM_MIN; i <= SEffects_GetMax(Scream); i++) {
        SEffects_GetPath(soundpath, Scream);
        // Format random index into sound path.
        Format(soundpath, SOUND_MAX_PATH, soundpath, i);
        PrecacheSound(soundpath, false);
    }
}