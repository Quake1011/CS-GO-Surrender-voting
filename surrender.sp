#include <sourcemod>
#include <cstrike>
#include <csgo_colors>

int g_iVotes, iTotalVotes, iNeedVotes, iMaxR;
bool g_bPlayerVote[MAXPLAYERS+1];

ConVar hCvar,hCvar1;

OnConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == hCvar) iNeedVotes = GetConVarInt(convar);
	else if(convar == hCvar1) iMaxR = GetConVarInt(convar);
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_surrender", SurrenderCallback);
	
	HookConVarChange(hCvar = CreateConVar("sm_sur_need_votes", "50"), OnConvarChanged);
	HookConVarChange(hCvar1 = CreateConVar("sm_sur_max_round", "13"), OnConvarChanged);
}

public void OnMapStart()
{
	g_iVotes = 0;
	iTotalVotes = 0;
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
	int iScoreT = CS_GetTeamScore(2);
	int iScoreCT = CS_GetTeamScore(3);
	int iMaxRounds = GetConVarInt(FindConVar("mp_maxrounds"));
	if(iMaxR>(RoundToFloor(float(iScoreT+iScoreCT)/iMaxRounds*100)))
	{
		char buffer[256];
		int teams = GetCountPlayers();
		iTotalVotes = RoundToFloor(float(g_iVotes/teams)*100);
		if(g_bPlayerVote[client] == false)
		{
			g_bPlayerVote[client] = true;
			g_iVotes++;
			Format(buffer,sizeof(buffer), "Игрок %N проголосовал за сдачу. %s из %s проголосовали!", client, g_iVotes, teams);
			CGOPrintToChatAll(buffer);
		}
		else
		{
			Format(buffer,sizeof(buffer), "Вы уже проголосовали за сдачу!");
			CGOPrintToChatAll(buffer);
		}
		
		if(iTotalVotes<=iNeedVotes)
		{
			ConVarChanger("mp_timelimit");
			ConVarChanger("mp_maxrounds");
			ConVarChanger("mp_ignore_round_win_conditions");
			CS_TerminateRound(1.0, "Команда %s сдалась")
		}
	}
}

int GetCountPlayers()
{
	int count = 0;
	for(int i = 0;i<MaxClients;i++)
	{
		if(IsClientInGame(i)&&!IsFakeClient(i)&&!IsClientSourceTV(i)) count++;
	}
	return count;
}

int ConVarChanger(char[] buffer)
{
	SetConVarInt(FindConVar(buffer),0);
	return 0;
}