// bot manager from hell by skaymo, feel free to use

#define SERVER_ONLY

const string[] BOT_NAMES = // please use your own names :)
{
	"Alpha 1",
	"Bravo 1",
	"Charlie 1",
	"Delta 1",
	"Echo 1",
	"Foxtrot 1",
	"Golf 1",
	"Hotel 1",
	"India 1",
	"Juliet 1",
	"Kilo 1",
	"Lima 1",
	"Mike 1",
	"November 1",
	"Oscar 1",
	"Papa 1",
	"Quebec 1",
	"Romeo 1",
	"Sierra 1",
	"Tango 1",
	"Uniform 1",
	"Victor 1",
	"X-ray 1",
	"Yankee 1",
	"Zulu 1"
};

u32 last_management_time = 0;
const u32 MANAGECOOLDOWN = 15; // ticks between bot management attempts to avoid incorrect multi addition/removal of bots

void onInit(CRules@ this)
{
	if (!isServer()) return;

	ConfigFile cfg = ConfigFile();
	if (cfg.loadFile("tdm_vars.cfg")) // change to your own cfg file if you are gonna use this
	{
		this.set_s32("max_bots", cfg.read_s32("max_bots", 8));
		this.set_s32("max_balance_bots", cfg.read_s32("max_balance_bots", 2));
	}
	else
	{
		this.set_s32("max_bots", 8);
		this.set_s32("max_balance_bots", 2);
	}

	ManageBots(this);
}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	if (!isServer()) return;
	
	if (getGameTime() - last_management_time >= MANAGECOOLDOWN)
	{
		ManageBots(this);
	}
}

void onRestart(CRules@ this)
{
	if (!isServer()) return;
	ManageBots(this);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (!isServer()) return;
	
	if (getGameTime() - last_management_time >= MANAGECOOLDOWN)
	{
		ManageBots(this);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    if (!isServer()) return;
    
    if (getGameTime() - last_management_time >= MANAGECOOLDOWN)
    {
        ManageBots(this);
    }
}

void onTick(CRules@ this)
{
	if (!isServer()) return;
	
	if (getGameTime() % 30 == 0)
	{
		ManageBots(this);
	}
}

string getUnusedBotName()
{
    Random rng(getGameTime() * 313 + Time() * 6909);
    
    // collect all bot names
    string[] currentNames;
    for (u8 i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
        if (p !is null && p.isBot())
        {
            currentNames.push_back(p.getUsername());
        }
    }
    
    // find unused names from BOT_NAMES
    string[] unusedNames;
    for (u8 i = 0; i < BOT_NAMES.length; i++)
    {
        if (currentNames.find(BOT_NAMES[i]) == -1)
        {
            unusedNames.push_back(BOT_NAMES[i]);
        }
    }
    
    // Pick a name
    string name;
    if (unusedNames.length > 0)
    {
        u32 index = rng.NextRanged(unusedNames.length);
        name = unusedNames[index];
    }
    else
    {
        u32 index = rng.NextRanged(BOT_NAMES.length);
        name = BOT_NAMES[index];
    }
    return name;
}

void ManageBots(CRules@ this)
{
	if (!isServer()) return;

	if (getGameTime() - last_management_time < MANAGECOOLDOWN)
	{
		return;
	}

	last_management_time = getGameTime();

	// fix for sv_canpause not pausing when there is bots, evil kag stuff
	// check for human players, including spectators
    u8 totalHumans = 0;
    for (u8 i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
        if (p !is null && !p.isBot())
        {
            totalHumans++;
        }
    }
    // if no human players, kick all bots and exit
    if (totalHumans == 0)
    {
        for (u8 i = 0; i < getPlayersCount(); i++)
        {
            CPlayer@ p = getPlayer(i);
            if (p !is null && p.isBot())
            {
                KickPlayer(p);
            }
        }
        return;
    }

	int MAX_BOTS = this.get_s32("max_bots");
	int MAX_BALANCE_BOTS = this.get_s32("max_balance_bots");

	u8 specteam = this.getSpectatorTeamNum();

	// only consider active teams (not spectator)
	u8[] activeTeams;
	for (u8 i = 0; i < this.getTeamsCount(); i++)
	{
		if (i != specteam)
		{
			activeTeams.push_back(i);
		}
	}

	// skip if no active teams
	if (activeTeams.length == 0) return;

	// count humans and bots on each team
	u8[] humansPerTeam(this.getTeamsCount(), 0);
	u8[] botsPerTeam(this.getTeamsCount(), 0);
	u8 totalActiveHumans = 0;
	u8 totalBots = 0;

	for (u8 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p !is null)
		{
			u8 team = p.getTeamNum();
			if (team < this.getTeamsCount())
			{
				if (p.isBot())
				{
					botsPerTeam[team]++;
					totalBots++;
				}
				else if (team != specteam)
				{
					humansPerTeam[team]++;
					totalActiveHumans++;
				}
			}
		}
	}

	// how many total bots we should have
	s8 desiredTotalBots = 0;
	if (totalActiveHumans < MAX_BOTS)
	{
		// we need bots
		desiredTotalBots = MAX_BOTS - totalActiveHumans;
	}

	// find team with most humans and team with fewest humans
	u8 maxHumansTeam = activeTeams[0];
	u8 minHumansTeam = activeTeams[0];
	u8 maxHumans = humansPerTeam[maxHumansTeam];
	u8 minHumans = humansPerTeam[minHumansTeam];

	for (u8 i = 1; i < activeTeams.length; i++)
	{
		u8 team = activeTeams[i];
		if (humansPerTeam[team] > maxHumans)
		{
			maxHumans = humansPerTeam[team];
			maxHumansTeam = team;
		}
		if (humansPerTeam[team] < minHumans)
		{
			minHumans = humansPerTeam[team];
			minHumansTeam = team;
		}
	}

	// how imbalanced are the teams
	s8 imbalance = maxHumans - minHumans;
	if (imbalance > 0 && totalActiveHumans >= MAX_BOTS)
	{
		// how many balancing bots are needed
		s8 balancingBotsNeeded = Maths::Min(imbalance, MAX_BALANCE_BOTS);

		// add to our desired total
		desiredTotalBots += balancingBotsNeeded;
	}

	if (totalBots < desiredTotalBots)
	{
		s8 botsToAdd = desiredTotalBots - totalBots;
		
		for (s8 i = 0; i < botsToAdd; i++)
		{
			// find team with fewest total players
			u8 targetTeam = FindTeamWithFewestPlayers(activeTeams, humansPerTeam, botsPerTeam);
			
			// add bot
			string botName = getUnusedBotName();
			CPlayer@ bot = AddBot(botName);
			if (bot !is null)
			{
				bot.server_setTeamNum(targetTeam);
				botsPerTeam[targetTeam]++;
				totalBots++;
			}
			else
			{
				break;
			}
		}
	}
	// remove bots if we have too many
	else if (totalBots > desiredTotalBots)
	{
		s8 botsToRemove = totalBots - desiredTotalBots;
		for (s8 i = 0; i < botsToRemove; i++)
		{
			u8 targetTeam = FindTeamWithMostPlayers(activeTeams, humansPerTeam, botsPerTeam);
			if (botsPerTeam[targetTeam] > 0)
			{
				u16[] botsOnTeam;
				for (u16 j = 0; j < getPlayersCount(); j++)
				{
					CPlayer@ p = getPlayer(j);
					if (p !is null && p.isBot() && p.getTeamNum() == targetTeam)
					{
						botsOnTeam.push_back(p.getNetworkID());
					}
				}
				
				if (botsOnTeam.length > 0)
				{
					// sort bots by network ID in descending order
					botsOnTeam.sortDesc();
					CPlayer@ botToKick = getPlayerByNetworkId(botsOnTeam[0]);
					KickPlayer(botToKick);
					botsPerTeam[targetTeam]--;
					totalBots--;
				}
				else
				{
					break;
				}
			}
		}
	}

	// if teams are still imbalanced, move bots around
	if (activeTeams.length >= 2)
	{
		// re calculate teams with most and fewest total players
		u8 maxPlayersTeam = FindTeamWithMostPlayers(activeTeams, humansPerTeam, botsPerTeam);
		u8 minPlayersTeam = FindTeamWithFewestPlayers(activeTeams, humansPerTeam, botsPerTeam);
		
		u8 maxPlayers = humansPerTeam[maxPlayersTeam] + botsPerTeam[maxPlayersTeam];
		u8 minPlayers = humansPerTeam[minPlayersTeam] + botsPerTeam[minPlayersTeam];
		
		// if teams are still imbalanced and we have at least 2 bots difference
		if (maxPlayers > minPlayers + 1 && botsPerTeam[maxPlayersTeam] > 0)
		{
			// move a bot to the team with fewest players
			for (u16 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p !is null && p.isBot() && p.getTeamNum() == maxPlayersTeam)
				{
					p.server_setTeamNum(minPlayersTeam);
					botsPerTeam[maxPlayersTeam]--;
					botsPerTeam[minPlayersTeam]++;
					break;
				}
			}
		}
	}
}

u8 FindTeamWithFewestPlayers(u8[] activeTeams, u8[] humansPerTeam, u8[] botsPerTeam)
{
	u8 minTeam = activeTeams[0];
	u8 minPlayers = humansPerTeam[minTeam] + botsPerTeam[minTeam];
	
	for (u8 i = 1; i < activeTeams.length; i++)
	{
		u8 team = activeTeams[i];
		u8 players = humansPerTeam[team] + botsPerTeam[team];
		
		if (players < minPlayers)
		{
			minPlayers = players;
			minTeam = team;
		}
	}
	
	return minTeam;
}

u8 FindTeamWithMostPlayers(u8[] activeTeams, u8[] humansPerTeam, u8[] botsPerTeam)
{
	u8 maxTeam = activeTeams[0];
	u8 maxPlayers = humansPerTeam[maxTeam] + botsPerTeam[maxTeam];
	
	for (u8 i = 1; i < activeTeams.length; i++)
	{
		u8 team = activeTeams[i];
		u8 players = humansPerTeam[team] + botsPerTeam[team];
		
		if (players > maxPlayers)
		{
			maxPlayers = players;
			maxTeam = team;
		}
	}
	
	return maxTeam;
}