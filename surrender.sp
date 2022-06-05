#include <sourcemod>
#include <cstrike>
#include <csgo_colors>
#include <multicolors>

int 
	g_iVotes, 
	iTotalVotes, 
	iNeedVotes, 
	iMaxR;
bool 
	g_bPlayerVote[MAXPLAYERS+1];
int 
	iSurrendingTeam; //3 - CT | 2 - T
ConVar 
	hCvar, 
	hCvar1;

OnConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == hCvar) iNeedVotes = GetConVarInt(convar);
	else if(convar == hCvar1) iMaxR = GetConVarInt(convar);
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_surrender", SurrenderCallback);
	RegConsoleCmd("sm_sur", SurrenderCallback);
	RegConsoleCmd("sm_s", SurrenderCallback);
	
	HookConVarChange(hCvar = CreateConVar("sm_sur_need_votes", "50"), OnConvarChanged);
	HookConVarChange(hCvar1 = CreateConVar("sm_sur_max_round", " 2"), OnConvarChanged);
	
	HookEvent("round_end", EventRound);
	HookEvent("round_start", EventRound);
}

public Action EventRound(Event hEvent, char[] event, bool bdb)
{
	g_iVotes = 0;
	iTotalVotes = 0;
	iSurrendingTeam = 0;
	for(int i = 0;i<=MaxClients;i++)
	{
		if(g_bPlayerVote[i] == true)
		{
			g_bPlayerVote[i] = false;
		}
	}
	
}

public void OnMapStart()
{
	g_iVotes = 0;
	iTotalVotes = 0;
	iSurrendingTeam = 0;
}

public void OnClientPutInServer(int client)
{
	g_bPlayerVote[client] = false;
}

public void OnClientDisconnect(int client)
{
	g_bPlayerVote[client] = false;
	g_iVotes--;
}

public Action SurrenderCallback(int client, int args)
{
	int ClientTeam = GetClientTeam(client);
	int iScoreT = CS_GetTeamScore(2);
	int iScoreCT = CS_GetTeamScore(3);
	int iMaxRounds = GetConVarInt(FindConVar("mp_maxrounds"));
	char map[64];
	if(iSurrendingTeam == 0)
	{
		iSurrendingTeam = ClientTeam;
	}
	
	GetNextMap(map, sizeof(map));
	
	if(!StrContains(map,"dust"))
	{
		SetNextMap("de_dust2");
	}
	if(ClientTeam == iSurrendingTeam)
	{
		if(iMaxR >= (RoundToFloor(float(iScoreT + iScoreCT) / iMaxRounds * 100)))
		{
			char buffer[256];
			int teams = GetCountPlayers(iSurrendingTeam);
			iTotalVotes = RoundToFloor(float(g_iVotes / teams) * 100);
			if(g_bPlayerVote[client] == false)
			{
				g_bPlayerVote[client] = true;
				g_iVotes++;
				char symb[] = "%%"
				int perc = RoundToFloor(float((g_iVotes/teams)*100));
				Format(buffer,sizeof(buffer), "Игрок %N проголосовал за сдачу. %i из %i игроков проголосовали! (%i%s)", client, g_iVotes, teams,perc,symb);
				if(GetEngineVersion() == Engine_CSGO) CGOPrintToChatAll(buffer);
				else if(GetEngineVersion() == Engine_CSS) CPrintToChatAll(buffer);
				else PrintToChatAll(buffer);
			}
			else
			{
				Format(buffer,sizeof(buffer), "Вы уже проголосовали за сдачу!");
				if(GetEngineVersion() == Engine_CSGO) CGOPrintToChatAll(buffer);
				else if(GetEngineVersion() == Engine_CSS) CPrintToChatAll(buffer);
				else PrintToChatAll(buffer);
			}
			
			if(iTotalVotes <= iNeedVotes)
			{
/* 				ConVarChanger("mp_timelimit");
				ConVarChanger("mp_maxrounds");
				ConVarChanger("mp_ignore_round_win_conditions"); */
				CS_TerminateRound(1.0, (iSurrendingTeam == 3) ? CSRoundEnd_CTSurrender : CSRoundEnd_TerroristsSurrender)
			}
		}
	}
}

int GetCountPlayers(int team)
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i))
		{
			if(GetClientTeam(i) == team) count++;
		}
	}
	return count;
}
/* 
int ConVarChanger(char[] buffer)
{
	SetConVarInt(FindConVar(buffer),0);
	return 0;
} */
