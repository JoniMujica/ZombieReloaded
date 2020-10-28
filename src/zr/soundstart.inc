new Handle:sound_array;
new Sounds_Count;
new CurrPos = -1;

public OnPuginStartSound(){
    new Handle:dir = OpenDirectory("sound/zp/round start");
	if (dir == INVALID_HANDLE)
		SetFailState("No se pudo abrir el directorio \"sound/zp/round start\"");

	sound_array = CreateArray(150);
	decl String:SoundName[150], FileType:type;
	while (ReadDirEntry(dir, SoundName, 150, type))
	{
		if (type == FileType_File && StrContains(SoundName, ".ztmp") == -1)
		{
			if (StrContains(SoundName, ".mp3") > 0 || StrContains(SoundName, ".wav") > 0)
			{
				Format(SoundName, 150, "zp/round start/%s", SoundName);
				PushArrayString(sound_array, SoundName);
			}
		}
	}
	CloseHandle(dir);

	if ((Sounds_Count = GetArraySize(sound_array)) < 1)
		SetFailState("No se encontraron sonidos en el directorio \"sound/zp/round start\"");
}

public OnMapStartSound()
{
	decl String:SoundName[150];
	for (new i = 0; i < Sounds_Count; i++)
	{
		GetArrayString(sound_array, i, SoundName, 150); PrecacheSound(SoundName, true);
		Format(SoundName, 150, "sound/%s", SoundName); AddFileToDownloadsTable(SoundName);
	}
}

FreezeEndSound()
{
	if (++CurrPos >= Sounds_Count) CurrPos = 0;
	decl String:SoundName[150]; GetArrayString(sound_array, CurrPos, SoundName, 150);
	for (new i = 1; i <= MaxClients; i++)
	{
		if(barricada)
		{
			EmitSoundToAll(SoundName, _, _, 5, _, 10.0);
		}
	}
}