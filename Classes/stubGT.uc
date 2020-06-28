class stubGT extends KFGameType
  config(KFPatcher);


// config vars
var config string sAlive, sDead, sSpectator, sReady, sNotReady, sAwaiting;
var config string sTagHP, sTagKills;
var config bool bShowPerk;
var config float fRefreshTime;

// other vars
var transient array<string> sCachedPlayersInfo;
var transient float fDelay;


//=============================================================================
//                                 SERVER INFO
//=============================================================================

// MasterServerUplink.uc
// Called when we should refresh the game state
// event Refresh()
// {
// 	if ( (!bInitialStateCached) || ( Level.TimeSeconds > CacheRefreshTime )  )
// 	{
// 		Level.Game.GetServerInfo(FullCachedServerState);
// 		Level.Game.GetServerDetails(FullCachedServerState);

// 		CachedServerState = FullCachedServerState;

// 		Level.Game.GetServerPlayers(FullCachedServerState);

// 		ServerState 		= FullCachedServerState;
// 		CacheRefreshTime 	= Level.TimeSeconds + 60;
// 		bInitialStateCached = false;
// 	}
// 	else if (Level.Game.NumPlayers != CachePlayerCount)
// 	{
// 		ServerState = CachedServerState;

// 		Level.Game.GetServerPlayers(ServerState);

// 		FullCachedServerState = ServerState;

// 	}
// 	else
// 		ServerState = FullCachedServerState;

// 	CachePlayerCount = Level.Game.NumPlayers;
// }


// show server detailed info
function GetServerDetails( out ServerResponseLine ServerState )
{
  local int l;
  local Mutator M;
  local GameRules G;
  local int i, Len, NumMutators;
  local string MutatorName;
  local bool bFound;

  // game info
  AddServerDetail( ServerState, "ServerMode", Eval(Level.NetMode == NM_ListenServer, "non-dedicated", "dedicated") );
  AddServerDetail( ServerState, "AdminName", GameReplicationInfo.AdminName );
  AddServerDetail( ServerState, "AdminEmail", GameReplicationInfo.AdminEmail );

  AddServerDetail( ServerState, "ServerVersion", Level.ROVersion );
  AddServerDetail( ServerState, "IsVacSecured", Eval(IsVACSecured(), "true", "false"));

  if ( AccessControl != None && AccessControl.RequiresPassword() )
    AddServerDetail( ServerState, "GamePassword", "True" );

  if ( AllowGameSpeedChange() && (GameSpeed != 1.0) )
    AddServerDetail( ServerState, "GameSpeed", int(GameSpeed*100)/100.0 );

  AddServerDetail( ServerState, "MaxSpectators", MaxSpectators );

  // voting
  if( VotingHandler != None )
    VotingHandler.GetServerDetails(ServerState);

  // Ask the mutators if they have anything to add.
  for (M = BaseMutator; M != None; M = M.NextMutator)
  {
    M.GetServerDetails(ServerState);
    NumMutators++;
  }

  // Ask the gamerules if they have anything to add.
  for ( G=GameRulesModifiers; G!=None; G=G.NextGameRules )
    G.GetServerDetails(ServerState);

  // make sure all the mutators were really added
  for ( i=0; i<ServerState.ServerInfo.Length; i++ )
    if ( ServerState.ServerInfo[i].Key ~= "Mutator" )
      NumMutators--;

  if ( NumMutators > 1 )
  {
    // something is missing
    for (M = BaseMutator.NextMutator; M != None; M = M.NextMutator)
    {
      MutatorName = M.GetHumanReadableName();
      for ( i=0; i<ServerState.ServerInfo.Length; i++ )
      {
        if ( (ServerState.ServerInfo[i].Value ~= MutatorName) && (ServerState.ServerInfo[i].Key ~= "Mutator") )
        {
          bFound = true;
          break;
        }

        if ( !bFound )
        {
          Len = ServerState.ServerInfo.Length;
          ServerState.ServerInfo.Length = Len+1;
          ServerState.ServerInfo[i].Key = "Mutator";
          ServerState.ServerInfo[i].Value = MutatorName;
        }
      }     
    }
  }

  // kf gametype
  l = ServerState.ServerInfo.Length;
  ServerState.ServerInfo.Length = l+1;
  ServerState.ServerInfo[l].Key = "Max runtime zombies";
  ServerState.ServerInfo[l].Value = string(MaxZombiesOnce);
  l++;
  ServerState.ServerInfo.Length = l+1;
  ServerState.ServerInfo[l].Key = "Starting cash";
  ServerState.ServerInfo[l].Value = string(StartingCash);
  l++;

  // invasion
  AddServerDetail( ServerState, "InitialWave", InitialWave );
	AddServerDetail( ServerState, "FinalWave", FinalWave );

  // teamgame
  AddServerDetail( ServerState, "BalanceTeams",  bBalanceTeams);
	AddServerDetail( ServerState, "PlayersBalanceTeams",  bPlayersBalanceTeams);
	AddServerDetail( ServerState, "FriendlyFireScale", int(FriendlyFireScale*100) $ "%" );

  // deathmatch
  AddServerDetail( ServerState, "GoalScore", GoalScore );
	AddServerDetail( ServerState, "TimeLimit", TimeLimit );
	AddServerDetail( ServerState, "Translocator", bAllowTrans );
	AddServerDetail( ServerState, "WeaponStay", bWeaponStay );
	AddServerDetail( ServerState, "ForceRespawn", bForceRespawn );

  // unreal mp game
  AddServerDetail( ServerState, "MinPlayers", MinPlayers );
	AddServerDetail( ServerState, "EndTimeDelay", EndTimeDelay );
}


// show perk, health in player info
function GetServerPlayers( out ServerResponseLine ServerState )
{
  local Mutator M;
  local Controller C;
  local PlayerReplicationInfo PRI;
  local int i; // , TeamFlag[2];

  i = ServerState.PlayerInfo.Length;
  // TeamFlag[0] = 1 << 29;
  // TeamFlag[1] = TeamFlag[0] << 1;

  for( C=Level.ControllerList; C != none; C=C.NextController )
  {
    PRI = C.PlayerReplicationInfo;
    if( (PRI != none) && !PRI.bBot && MessagingSpectator(C) == none )
    {
      ServerState.PlayerInfo.Length = i+1;
      ServerState.PlayerInfo[i].PlayerNum  = C.PlayerNum;
      // our new functions might be a bit heavy, so limit its execution
      // and use cached string
      if (Level.TimeSeconds >= class'stubGT'.default.fDelay)
      {
        class'stubGT'.default.sCachedPlayersInfo[i] = class'stubGT'.static.ParsePlayerName(PRI, C, bWaitingToStartMatch);
        ServerState.PlayerInfo[i].PlayerName = class'stubGT'.default.sCachedPlayersInfo[i]; // PRI.PlayerName;
        class'stubGT'.default.fDelay = Level.TimeSeconds + class'stubGT'.default.fRefreshTime;
      }
      else
        ServerState.PlayerInfo[i].PlayerName = class'stubGT'.default.sCachedPlayersInfo[i];
      ServerState.PlayerInfo[i].Score      = PRI.Score;
      ServerState.PlayerInfo[i].Ping       = 4 * PRI.Ping;
      // do we need this?
      // if (bTeamGame && PRI.Team != none)
      // ServerState.PlayerInfo[i].StatsID = class'stubGT'.static.GetPerkInfo(PRI); // ServerState.PlayerInfo[i].StatsID | TeamFlag[PRI.Team.TeamIndex];
      i++;
    }
  }

  // Ask the mutators if they have anything to add.
  for (M = BaseMutator.NextMutator; M != none; M = M.NextMutator)
    M.GetServerPlayers(ServerState);
}


static final function string ParsePlayerName(out PlayerReplicationInfo PRI, out Controller C, bool bWaitingToStartMatch)
{
  local string status, perk;

  if (C == none || PRI == none || KFPlayerReplicationInfo(PRI) == none)
    return "NULL PRI";

  // in case we are in
  if (C.IsInState('PlayerWaiting'))
  {
    if (bWaitingToStartMatch)
    {
      if(PRI.bReadyToPlay)
        status = default.sReady;
      else
        status = default.sNotReady;
    }
    else
      status = default.sAwaiting;
  }

  // if we are spectator, do not check perk, kills, etc
  else if (PRI.bOnlySpectator)
  {
    return class'uHelper'.static.StripTags(PRI.PlayerName) @ class'uHelper'.static.ParseTags(default.sSpectator);
  }

  else if (PRI.bOutOfLives && !PRI.bOnlySpectator)
    status = default.sDead;

  // else we are alive and need more info
  else
    status = default.sAlive;

  // parse kills, health
  status = repl(status, default.sTagHP, KFPlayerReplicationInfo(PRI).PlayerHealth);
  status = repl(status, default.sTagKills, PRI.Kills);
  // status ready !

  // parse perk if we want it
  if (default.bShowPerk)
  {
    switch (string(KFPlayerReplicationInfo(PRI).ClientVeteranSkill))
    {
      case "KFMod.KFVetSharpshooter":
      case "ServerPerksP.SRVetSharpshooter":
      case "ScrnBalanceSrv.ScrnVetSharpshooter":
        perk = "Sharp";
        break;
      case "KFMod.KFVetFieldMedic":
      case "ServerPerksP.SRVetFieldMedic":
      case "ScrnBalanceSrv.ScrnVetFieldMedic":
        perk = "Medic";
        break;
      case "KFMod.KFVetBerserker":
      case "ServerPerksP.SRVetBerserker":
      case "ScrnBalanceSrv.ScrnVetBerserker":
        perk = "Zerk";
        break;
      case "KFMod.KFVetCommando":
      case "ServerPerksP.SRVetCommando":
      case "ScrnBalanceSrv.ScrnVetCommando":
        perk = "Mando";
        break;
      case "KFMod.KFVetDemolitions":
      case "ServerPerksP.SRVetDemolitions":
      case "ScrnBalanceSrv.ScrnVetDemolitions":
        perk = "Demo";
        break;
      case "KFMod.KFVetFirebug":
      case "ServerPerksP.SRVetFirebug":
      case "ScrnBalanceSrv.ScrnVetFirebug":
        perk = "Pyro";
        break;
      case "KFMod.KFVetSupportSpec":
      case "ServerPerksP.SRVetSupportSpec":
      case "ScrnBalanceSrv.ScrnVetSupportSpec":
        perk = "Sup";
        break;
      case "ScrnBalanceSrv.ScrnVetGunslinger":
        perk = "Slinger";
        break;
      default:
        perk = "NULL perk";
    }

    perk @= KFPlayerReplicationInfo(PRI).ClientVeteranSkillLevel;
    perk = "^r[" $ perk $ "]^w";
  }

  return class'uHelper'.static.ParseTags(perk @ PRI.PlayerName @ status);
}


//=============================================================================
//                              Disable slomo!
//=============================================================================

// TO-DO add a bool to controll it !
// tick will be called constantly but now it does nothing :3
event Tick(float DeltaTime){}
function DramaticEvent(float BaseZedTimePossibility, optional float DesiredZedTimeDuration){}


// DO NOT Force slomo for a longer period of time when the boss dies
function DoBossDeath()
{
  local Controller C;
  local Controller nextC;
  local int num;

  // bZEDTimeActive =  true;
  // bSpeedingBackUp = false;
  // LastZedTimeEvent = Level.TimeSeconds;
  // CurrentZEDTimeDuration = ZEDTimeDuration*2;
  // SetGameSpeed(ZedTimeSlomoScale);

  num = NumMonsters;
  c = Level.ControllerList;

  // turn off all the other zeds so they don't attack the player
  while (c != none && num > 0)
  {
    nextC = c.NextController;
    if (KFMonsterController(C)!=none)
    {
      C.GotoState('GameEnded');
      --num;
    }
    c = nextC;
  }
}


// remove latejoiner shit, GameInfo code
event PreLogin( string Options, string Address, string PlayerID, out string Error, out string FailCode )
{
  super(GameInfo).PreLogin( Options, Address, PlayerID, Error, FailCode );
}


//=============================================================================
//                      LET SPECS TO FLY AFTER GAME ENDS
//=============================================================================

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
  local Controller P;
  local PlayerController Player;
  local bool bSetAchievement;
  local string MapName;

  EndTime = Level.TimeSeconds + EndTimeDelay;

  if ( WaveNum > FinalWave )
  {
    GameReplicationInfo.Winner = Teams[0];
    KFGameReplicationInfo(GameReplicationInfo).EndGameType = 2;

    if ( GameDifficulty >= 2.0 )
    {
      bSetAchievement = true;

      //Get the MapName out of the URL
      MapName = GetCurrentMapName(Level);
    }
  }
  else
    KFGameReplicationInfo(GameReplicationInfo).EndGameType = 1;

  if ( (GameRulesModifiers != none) && !GameRulesModifiers.CheckEndGame(Winner, Reason) ) 
  {
    KFGameReplicationInfo(GameReplicationInfo).EndGameType = 0;
    return false;
  }

  for ( P = Level.ControllerList; P != none; P = P.nextController )
  {
    Player = PlayerController(P);
    if ( Player != none )
    {
      Player.ClientSetBehindView(true);
      
      //Player.ClientGameEnded(); //disable this so players can move freely after the game ends
      if ( bSetAchievement && KFSteamStatsAndAchievements(Player.SteamStatsAndAchievements) != none )
        KFSteamStatsAndAchievements(Player.SteamStatsAndAchievements).WonGame(MapName, GameDifficulty, KFGameLength == GL_Long);
    }
    //P.GameHasEnded(); //and this
  }
  if ( CurrentGameProfile != none )
    CurrentGameProfile.bWonMatch = false;

  return true;
}