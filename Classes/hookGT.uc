/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookGT extends KFGameType
    CacheExempt;  // do NOT include me in UCL and do NOT be discoverable in menus;


var transient array<string> sCachedPlayersInfo;
var transient float fDelay;

// killzeds
var transient array<KFMonster> Monsters;

// InitGame
var string CmdLine;

// camera fix
var bool bBossView;
var float BossViewBackTime;
var transient ZombieBoss BossArray;

// all traders open fix
// only applied once during the server's lifespan
var bool bAllTradersOpenFixApplied;


//=============================================================================
//                      GameLength / MaxPlayers Fix
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L658
// max players limit ^, gamelenght fix, save cmdline
event InitGame(string Options, out string Error)
{
  local KFLevelRules KFLRit;
  local ShopVolume SH;
  local ZombieVolume ZZ;
  local string InOpt;

  super(Invasion).InitGame(Options, Error);

  // remove 6 player limit, yay!
  // max to 32 players
  MaxPlayers = clamp(GetIntOption( Options, "MaxPlayers", MaxPlayers ), 0, 32);
  default.MaxPlayers = clamp(default.MaxPlayers, 0, 32);

  foreach DynamicActors(class'KFLevelRules', KFLRit)
  {
    if (KFLRules == none)
      KFLRules = KFLRit;
    else Warn("MULTIPLE KFLEVELRULES FOUND!!!!!");
  }

  // add traders
  class'Utility'.static.RegisterAllTraders(self, ShopList, bUsingObjectiveMode);

  if (class'Settings'.default.bAllTradersOpen)
    log("> bAllTradersOpen = true. All traders will be open!");

  foreach DynamicActors(class'ZombieVolume', ZZ)
  {
    if (!ZZ.bObjectiveModeOnly || bUsingObjectiveMode)
    {
      ZedSpawnList[ZedSpawnList.Length] = ZZ;
    }
  }

  // provide default rules if mapper did not need custom one
  if (KFLRules == none)
    KFLRules = spawn(class'KFLevelRules');

  log("KFLRules = "$KFLRules);

  InOpt = ParseOption(Options, "UseBots");
  if (InOpt != "")
  {
    bNoBots = bool(InOpt);
  }

  // allow to set gamelength from cmdline
  KFGameLength = GetIntOption(Options, "GameLength", KFGameLength);

  // add anti idiot protection
  if (KFGameLength < 0 || KFGameLength > 3)
  {
    log("> GameLength must be in [0..3]: 0-short, 1-medium, 2-long, 3-custom");
    KFGameLength = GL_Long;
  }
  log("> Game length = "$KFGameLength);

  // added a log
  MonsterCollection = SpecialEventMonsterCollections[ GetSpecialEventType() ];
  log("> MonsterCollection = " $ MonsterCollection);

  if (KFGameLength != GL_Custom)
  {
    // Set up the default game type settings
    bUseEndGameBoss = true;
    bRespawnOnBoss = true;
    if (StandardMonsterClasses.Length > 0)
    {
      MonsterClasses = StandardMonsterClasses;
    }
    MonsterSquad = StandardMonsterSquads;
    MaxZombiesOnce = StandardMaxZombiesOnce;
    bCustomGameLength = false;
    UpdateGameLength();

    // Set difficulty based values
    if (GameDifficulty >= 7.0) // Hell on Earth
    {
      TimeBetweenWaves = TimeBetweenWavesHell;
      StartingCash = StartingCashHell;
      MinRespawnCash = MinRespawnCashHell;
    }
    else if (GameDifficulty >= 5.0) // Suicidal
    {
      TimeBetweenWaves = TimeBetweenWavesSuicidal;
      StartingCash = StartingCashSuicidal;
      MinRespawnCash = MinRespawnCashSuicidal;
    }
    else if (GameDifficulty >= 4.0) // Hard
    {
      TimeBetweenWaves = TimeBetweenWavesHard;
      StartingCash = StartingCashHard;
      MinRespawnCash = MinRespawnCashHard;
    }
    else if (GameDifficulty >= 2.0) // Normal
    {
      TimeBetweenWaves = TimeBetweenWavesNormal;
      StartingCash = StartingCashNormal;
      MinRespawnCash = MinRespawnCashNormal;
    }
    else //if ( GameDifficulty == 1.0 ) // Beginner
    {
      TimeBetweenWaves = TimeBetweenWavesBeginner;
      StartingCash = StartingCashBeginner;
      MinRespawnCash = MinRespawnCashBeginner;
    }

    InitialWave = 0;
    PrepareSpecialSquads();
  }
  else
  {
    bCustomGameLength = true;
    UpdateGameLength();
  }

  LoadUpMonsterList();

  // save options for debug and further use
  class'hookGT'.default.CmdLine = Options;
}


//=============================================================================
//                      Player Camera Fix
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L2126
// N.B. i edited whole timer, fixed some random fuckups
// like last zed killing
state MatchInProgress
{
  // https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L2196
  function OpenShops()
  {
    local int i;
    local Controller C;

    bTradingDoorsOpen = true;

    for (i=0; i<ShopList.Length; i++)
    {
      if (ShopList[i].bAlwaysClosed)
        continue;
      if (ShopList[i].bAlwaysEnabled)
        ShopList[i].OpenShop();
    }

    if (KFGameReplicationInfo(GameReplicationInfo).CurrentShop == none)
    {
      SelectShop();
    }

    KFGameReplicationInfo(GameReplicationInfo).CurrentShop.OpenShop();

    // Tell all players to start showing the path to the trader
    for (C=Level.ControllerList; C!=none; C=C.NextController)
    {
      if (C.Pawn != none && C.Pawn.Health > 0)
      {
        // Disable pawn collision during trader time
        C.Pawn.bBlockActors = false;

        if (KFPlayerController(C) != none)
        {
          KFPlayerController(C).SetShowPathToTrader(true);
          // Have Trader tell players that the Shop's Open
          if (WaveNum < FinalWave)
            KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 2);
          else
            KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 3);

          // send message if eveything is open
          if (class'Settings'.default.bAllTradersOpen)
            class'Utility'.static.SendMessage(PlayerController(C), class'Settings'.default.bAllTradersMessage, false);

          // Hints
          KFPlayerController(C).CheckForHint(31);
          HintTime_1 = Level.TimeSeconds + 11;
        }
      }
    }
  }

  // https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L2250
  function CloseShops()
  {
    local int i;
    local Controller C;
    local Pickup Pickup;

    bTradingDoorsOpen = false;
    for( i=0; i<ShopList.Length; i++ )
    {
      if( ShopList[i].bCurrentlyOpen )
        ShopList[i].CloseShop();
    }

    SelectShop();

    // changed from AllActors
    foreach DynamicActors(class'Pickup', Pickup)
    {
      // do not touch dosh
      if (Pickup == none || Pickup.IsA('CashPickup'))
        continue;

      // trying not to destroy them imidiately
      if (Pickup.bDropped)
        Pickup.LifeSpan = 3.0;
    }

    // Tell all players to stop showing the path to the trader
    for ( C = Level.ControllerList; C != none; C = C.NextController )
    {
      if ( C.Pawn != none && C.Pawn.Health > 0 )
      {
        // Restore pawn collision during trader time
        C.Pawn.bBlockActors = C.Pawn.default.bBlockActors;

        if ( KFPlayerController(C) != none )
        {
          KFPlayerController(C).SetShowPathToTrader(false);
          // disable Garbage Collection!
          // DO NOT FORGET TO ENABLE IT ON SERVERTRAVEL !!
          // KFPlayerController(C).ClientForceCollectGarbage();

          if ( WaveNum < FinalWave - 1 )
          {
            // Have Trader tell players that the Shop's Closed
            KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 6);
          }
        }
      }
    }
  }

  // https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L2296
  function nTimer()
  {
    local Controller C;
    local bool bOneMessage;
    local Bot B;

    Global.Timer();

    if ( Level.TimeSeconds > HintTime_1 && bTradingDoorsOpen && bShowHint_2 )
    {
      for ( C = Level.ControllerList; C != none; C = C.NextController )
      {
        // added player ctrl check
        if( KFPlayerController(C) != none && C.Pawn != none && C.Pawn.Health > 0 )
        {
          KFPlayerController(C).CheckForHint(32);
          HintTime_2 = Level.TimeSeconds + 11;
        }
      }

      bShowHint_2 = false;
    }

    if ( Level.TimeSeconds > HintTime_2 && bTradingDoorsOpen && bShowHint_3 )
    {
      for ( C = Level.ControllerList; C != none; C = C.NextController )
      {
        // added player ctrl check
        if (KFPlayerController(C) != none && C.Pawn != none && C.Pawn.Health > 0 )
        {
          KFPlayerController(C).CheckForHint(33);
        }
      }
      bShowHint_3 = false;
    }

    if ( !bFinalStartup )
    {
      bFinalStartup = true;
      PlayStartupMessage();
    }

    if ( NeedPlayers() && AddBot() && (RemainingBots > 0) )
      RemainingBots--;
    ElapsedTime++;
    GameReplicationInfo.ElapsedTime = ElapsedTime;

    if( !UpdateMonsterCount() )
    {
      EndGame(none,"TimeLimit");
      return;
    }

    if( bUpdateViewTargs )
      UpdateViews();

    if (!bNoBots && !bBotsAdded)
    {
      if(KFGameReplicationInfo(GameReplicationInfo) != none)

      if((NumPlayers + NumBots) < MaxPlayers && KFGameReplicationInfo(GameReplicationInfo).PendingBots > 0 )
      {
        AddBots(1);
        KFGameReplicationInfo(GameReplicationInfo).PendingBots --;
      }

      if (KFGameReplicationInfo(GameReplicationInfo).PendingBots == 0)
      {
        bBotsAdded = true;
        return;
      }
    }

    // Close Trader doors
    // added bWaveInProgress check
    if( bWaveBossInProgress || bWaveInProgress)
    {
      if( bTradingDoorsOpen )
      {
        CloseShops();
        TraderProblemLevel = 0;
      }

      if( TraderProblemLevel<4 )
      {
        if( BootShopPlayers() )
          TraderProblemLevel = 0;
        else
          TraderProblemLevel++;
      }
    }

    // set camera for midgame boss's
    // check DoBossDeath()
    if (class'hookGT'.default.bBossView && !bWaveBossInProgress && class'hookGT'.default.BossViewBackTime < Level.TimeSeconds)
    {
      class'hookGT'.default.bBossView = false;

      for ( C = Level.ControllerList; C != none; C = C.NextController )
      {
        if( PlayerController(C)!=none )
        {
          if ( C.Pawn == none && !C.PlayerReplicationInfo.bOnlySpectator && bRespawnOnBoss )
            C.ServerReStartPlayer();
          if ( C.Pawn != none )
          {
            PlayerController(C).SetViewTarget(C.Pawn);
            PlayerController(C).ClientSetViewTarget(C.Pawn);
          }
          else
          {
            PlayerController(C).SetViewTarget(C);
            PlayerController(C).ClientSetViewTarget(C);
          }
          PlayerController(C).bBehindView = false;
          PlayerController(C).ClientSetBehindView(false);
        }
      }
    }

    // boss wave
    if (bWaveBossInProgress)
    {
      // set camera on boss when he spawns
      if ( !bHasSetViewYet && NumMonsters > 0 )
      {
        bHasSetViewYet = true;
        for ( C = Level.ControllerList; C != none; C = C.NextController )
        {
          if ( KFMonster(C.Pawn)!=none && KFMonster(C.Pawn).MakeGrandEntry() )
          {
            ViewingBoss = KFMonster(C.Pawn);
            break;
          }
        }

        if ( ViewingBoss != none )
        {
          class'hookGT'.default.bBossView = true;
          ViewingBoss.bAlwaysRelevant = true;

          for ( C = Level.ControllerList; C != none; C = C.NextController )
          {
            if ( PlayerController(C) != none )
            {
              PlayerController(C).SetViewTarget(ViewingBoss);
              PlayerController(C).ClientSetViewTarget(ViewingBoss);
              PlayerController(C).bBehindView = true;
              PlayerController(C).ClientSetBehindView(true);
              PlayerController(C).ClientSetMusic(BossBattleSong,MTRAN_FastFade);
            }
            if ( C.PlayerReplicationInfo!=none && bRespawnOnBoss )
            {
              C.PlayerReplicationInfo.bOutOfLives = false;
              C.PlayerReplicationInfo.NumLives = 0;
              if ( (C.Pawn == none) && !C.PlayerReplicationInfo.bOnlySpectator && PlayerController(C)!=none )
                C.GotoState('PlayerWaiting');
            }
          }
        }
      }

      // remove camera from boss
      else if ( class'hookGT'.default.bBossView && (ViewingBoss==none || (ViewingBoss!=none && !ViewingBoss.bShotAnim) ) )
      {
        class'hookGT'.default.bBossView = false;
        ViewingBoss = none;

        for ( C = Level.ControllerList; C != none; C = C.NextController )
        {
          if( PlayerController(C)!=none )
          {
            if ( C.Pawn == none && !C.PlayerReplicationInfo.bOnlySpectator && bRespawnOnBoss )
              C.ServerReStartPlayer();
            if( C.Pawn != none )
            {
              PlayerController(C).SetViewTarget(C.Pawn);
              PlayerController(C).ClientSetViewTarget(C.Pawn);
            }
            else
            {
              PlayerController(C).SetViewTarget(C);
              PlayerController(C).ClientSetViewTarget(C);
            }
            PlayerController(C).bBehindView = false;
            PlayerController(C).ClientSetBehindView(false);
          }
        }
      }

      // all dead
      if ( (TotalMaxMonsters<=0 || Level.TimeSeconds > WaveEndTime) && NumMonsters <= 0 )
        DoWaveEnd();
      // if we can spawn more
      else if (MaxMonsters - NumMonsters > 0)
        AddBoss();
    }

    // usual wave
    else if (bWaveInProgress)
    {
      WaveTimeElapsed += 1.0;
      // trader door part moved up

      if (!MusicPlaying)
        StartGameMusic(true);

      if (TotalMaxMonsters <= 0)
      {
        // TWI's Check for STUCK monsters was bugged, killed zeds imidiately
        if ( NumMonsters <= 5 && WaveTimeElapsed > 10.0)
        {
          for ( C = Level.ControllerList; C != none; C = C.NextController )
          {
            if ( KFMonsterController(C) != none && KFMonster(C.Pawn) != none && (Level.TimeSeconds - KFMonster(C.Pawn).LastSeenOrRelevantTime > 8) )
            {
              C.Pawn.KilledBy( C.Pawn );
              break;
            }
          }
        }
        // if everyone's spawned and they're all dead
        if ( NumMonsters <= 0 )
          DoWaveEnd();
      }

      // all monsters spawned
      else if ( NextMonsterTime < Level.TimeSeconds && (NumMonsters+NextSpawnSquad.Length <= MaxMonsters) )
      {
        WaveEndTime = Level.TimeSeconds + 160;
        if (!bDisableZedSpawning)
          AddSquad(); // Comment this out to prevent zed spawning

        if (nextSpawnSquad.length > 0)
          NextMonsterTime = Level.TimeSeconds + 0.2;
        else
          NextMonsterTime = Level.TimeSeconds + CalcNextSquadSpawnTime();
      }
    }

    else if ( NumMonsters <= 0 )
    {
      // apply the 'All Traders Open' fix only during the initial wave, if enabled
      if ( WaveNum == InitialWave && !class'hookGT'.default.bAllTradersOpenFixApplied && class'Settings'.default.bAllTradersOpen ) 
      {
        class'hookGT'.default.bAllTradersOpenFixApplied = true;
        class'Utility'.static.RegisterAllTraders(self, ShopList, bUsingObjectiveMode);
      }

      if ( WaveNum == FinalWave && !bUseEndGameBoss )
      {
        if( bDebugMoney )
          log("$$$$$$$$$$$$$$$$ Final TotalPossibleMatchMoney = "$TotalPossibleMatchMoney,'Debug');
        EndGame(none,"TimeLimit");
        return;
      }

      else if( WaveNum == (FinalWave + 1) && bUseEndGameBoss )
      {
        if( bDebugMoney )
          log("$$$$$$$$$$$$$$$$ Final TotalPossibleMatchMoney = "$TotalPossibleMatchMoney,'Debug');
        EndGame(none,"TimeLimit");
        return;
      }

      WaveCountDown--;
      if ( !CalmMusicPlaying )
      {
        InitMapWaveCfg();
        StartGameMusic(false);
      }

      // Open Trader doors
      if ( !bTradingDoorsOpen && WaveNum != InitialWave )
      {
        bTradingDoorsOpen = true;
        OpenShops();
      }

      // Select a shop if one isn't open
      if ( KFGameReplicationInfo(GameReplicationInfo).CurrentShop == none )
        SelectShop();

      KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;

      // Have Trader tell players that they've got 30 seconds
      if ( WaveCountDown == 30 )
      {
        for ( C = Level.ControllerList; C != none; C = C.NextController )
        {
          if ( KFPlayerController(C) != none )
            KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 4);
        }
      }

      // Have Trader tell players that they've got 10 seconds
      else if ( WaveCountDown == 10 )
      {
        for ( C = Level.ControllerList; C != none; C = C.NextController )
        {
          if ( KFPlayerController(C) != none )
            KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 5);
        }
      }

      else if ( WaveCountDown == 5 )
      {
        KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn = false;
        InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
      }

      else if ( (WaveCountDown > 0) && (WaveCountDown < 5) )
      {
        if( WaveNum == FinalWave && bUseEndGameBoss )
          BroadcastLocalizedMessage(class'KFMod.WaitingMessage', 3);
        else
          BroadcastLocalizedMessage(class'KFMod.WaitingMessage', 1);
      }
      else if ( WaveCountDown <= 1 )
      {
        bWaveInProgress = true;
        KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = true;

        // Randomize the ammo pickups again
        if( WaveNum > 0 )
          SetupPickups();

        if ( WaveNum == FinalWave && bUseEndGameBoss )
          StartWaveBoss();

        else
        {
          SetupWave();

          for ( C = Level.ControllerList; C != none; C = C.NextController )
          {
            if ( PlayerController(C) != none )
            {
              PlayerController(C).LastPlaySpeech = 0;
              if ( KFPlayerController(C) != none )
                KFPlayerController(C).bHasHeardTraderWelcomeMessage = false;
            }

            if ( Bot(C) != none )
            {
              B = Bot(C);
              InvasionBot(B).bDamagedMessage = false;
              B.bInitLifeMessage = false;

              if ( !bOneMessage && (FRand() < 0.65) )
              {
                bOneMessage = true;
                if ( (B.Squad.SquadLeader != none) && B.Squad.CloseToLeader(C.Pawn) )
                {
                  B.SendMessage(B.Squad.SquadLeader.PlayerReplicationInfo, 'OTHER', B.GetMessageIndex('INPOSITION'), 20, 'TEAM');
                  B.bInitLifeMessage = false;
                }
              }
            }
          }
        }
      }
    }
  }
}


//=============================================================================
//                                 SERVER INFO
//=============================================================================

// MasterServerUplink.uc
// Called when we should refresh the game state
// event Refresh()
// {
//   if ( (!bInitialStateCached) || ( Level.TimeSeconds > CacheRefreshTime )  )
//   {
//     Level.Game.GetServerInfo(FullCachedServerState);
//     Level.Game.GetServerDetails(FullCachedServerState);

//     CachedServerState = FullCachedServerState;

//     Level.Game.GetServerPlayers(FullCachedServerState);

//     ServerState     = FullCachedServerState;
//     CacheRefreshTime   = Level.TimeSeconds + 60;
//     bInitialStateCached = false;
//   }
//   else if (Level.Game.NumPlayers != CachePlayerCount)
//   {
//     ServerState = CachedServerState;

//     Level.Game.GetServerPlayers(ServerState);

//     FullCachedServerState = ServerState;

//   }
//   else
//     ServerState = FullCachedServerState;

//   CachePlayerCount = Level.Game.NumPlayers;
// }


// https://github.com/InsultingPros/KillingFloor/blob/main/Engine/Classes/GameInfo.uc#L515
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

  if ( AccessControl != none && AccessControl.RequiresPassword() )
    AddServerDetail( ServerState, "GamePassword", "true" );

  if ( AllowGameSpeedChange() && (GameSpeed != 1.0) )
    AddServerDetail( ServerState, "GameSpeed", int(GameSpeed*100)/100.0 );

  AddServerDetail( ServerState, "MaxSpectators", MaxSpectators );

  // voting
  if( VotingHandler != none )
    VotingHandler.GetServerDetails(ServerState);

  // Ask the mutators if they have anything to add.
  for (M = BaseMutator; M != none; M = M.NextMutator)
  {
    M.GetServerDetails(ServerState);
    NumMutators++;
  }

  // Ask the gamerules if they have anything to add.
  for ( G=GameRulesModifiers; G!=none; G=G.NextGameRules )
    G.GetServerDetails(ServerState);

  // make sure all the mutators were really added
  for ( i=0; i<ServerState.ServerInfo.Length; i++ )
    if ( ServerState.ServerInfo[i].Key ~= "Mutator" )
      NumMutators--;

  if ( NumMutators > 1 )
  {
    // something is missing
    for (M = BaseMutator.NextMutator; M != none; M = M.NextMutator)
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


// https://github.com/InsultingPros/KillingFloor/blob/main/Engine/Classes/GameInfo.uc#L591
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
      if (Level.TimeSeconds >= class'hookGT'.default.fDelay)
      {
        class'hookGT'.default.sCachedPlayersInfo[i] = class'hookGT'.static.ParsePlayerName(PRI, C, bWaitingToStartMatch);
        ServerState.PlayerInfo[i].PlayerName = class'hookGT'.default.sCachedPlayersInfo[i]; // PRI.PlayerName;
        class'hookGT'.default.fDelay = Level.TimeSeconds + class'Settings'.default.fRefreshTime;
      }
      else
        ServerState.PlayerInfo[i].PlayerName = class'hookGT'.default.sCachedPlayersInfo[i];
      ServerState.PlayerInfo[i].Score      = PRI.Score;
      ServerState.PlayerInfo[i].Ping       = 4 * PRI.Ping;
      // do we need this?
      // if (bTeamGame && PRI.Team != none)
      // ServerState.PlayerInfo[i].StatsID = class'hookGT'.static.GetPerkInfo(PRI); // ServerState.PlayerInfo[i].StatsID | TeamFlag[PRI.Team.TeamIndex];
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
  local string sfinal;

  if (C == none || PRI == none || KFPlayerReplicationInfo(PRI) == none)
    return "NULL PRI";

  // in case we are in
  if (C.IsInState('PlayerWaiting'))
  {
    if (bWaitingToStartMatch)
    {
      if(PRI.bReadyToPlay)
        status = class'Settings'.default.sReady;
      else
        status = class'Settings'.default.sNotReady;
    }
    else
      status = class'Settings'.default.sAwaiting;
  }

  // if we are spectator, do not check perk, kills, etc
  else if (PRI.bOnlySpectator)
  {
    return class'Utility'.static.StripTags(PRI.PlayerName) @ class'Utility'.static.ParseTags(class'Settings'.default.sSpectator);
  }

  else if (PRI.bOutOfLives && !PRI.bOnlySpectator)
    status = class'Settings'.default.sDead;

  // else we are alive and need more info
  else
    status = class'Settings'.default.sAlive;

  // parse kills, health
  status = repl(status, class'Settings'.default.sTagHP, KFPlayerReplicationInfo(PRI).PlayerHealth);
  status = repl(status, class'Settings'.default.sTagKills, PRI.Kills);
  // status ready !

  // parse perk if we want it
  if (class'Settings'.default.bShowPerk)
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

  sfinal = perk @ PRI.PlayerName @ status;
  return class'Utility'.static.ParseTags(sfinal);
}


//=============================================================================
//                              Disable slomo!
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L258
// TO-DO add a bool to controll it !
// tick will be called constantly but now it does nothing :3
event Tick(float DeltaTime)
{
  local float TrueTimeFactor;
  local Controller C;

  // global switch
  if (!class'Settings'.default.bAllowZedTime)
    return;

  if ( bZEDTimeActive )
  {
    TrueTimeFactor = 1.1/Level.TimeDilation;
    CurrentZEDTimeDuration -= DeltaTime * TrueTimeFactor;

    if( CurrentZEDTimeDuration < (ZEDTimeDuration*0.166) && CurrentZEDTimeDuration > 0 )
    {
      if ( !bSpeedingBackUp )
      {
        bSpeedingBackUp = true;

        for ( C=Level.ControllerList;C!=none;C=C.NextController )
        {
          if (KFPlayerController(C)!= none)
          {
            KFPlayerController(C).ClientExitZedTime();
          }
        }
      }

      SetGameSpeed(Lerp( (CurrentZEDTimeDuration/(ZEDTimeDuration*0.166)), 1.0, 0.2 ));
    }

    if ( CurrentZEDTimeDuration <= 0 )
    {
      bZEDTimeActive = false;
      bSpeedingBackUp = false;
      SetGameSpeed(1.0);
      ZedTimeExtensionsUsed = 0;
    }
  }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L350
function DramaticEvent(float BaseZedTimePossibility, optional float DesiredZedTimeDuration)
{
  local float RandChance;
  local float TimeSinceLastEvent;
  local Controller C;

  // global switch
  if (!class'Settings'.default.bAllowZedTime)
    return;

  TimeSinceLastEvent = Level.TimeSeconds - LastZedTimeEvent;

  // Don't go in slomo if we were just IN slomo
  if( TimeSinceLastEvent < 10.0 && BaseZedTimePossibility != 1.0 )
  {
    return;
  }

  if( TimeSinceLastEvent > 60 )
  {
    BaseZedTimePossibility *= 4.0;
  }
  else if( TimeSinceLastEvent > 30 )
  {
    BaseZedTimePossibility *= 2.0;
  }

  RandChance = FRand();

  //log("TimeSinceLastEvent = "$TimeSinceLastEvent$" RandChance = "$RandChance$" BaseZedTimePossibility = "$BaseZedTimePossibility);

  if( RandChance <= BaseZedTimePossibility )
  {
    bZEDTimeActive =  true;
    bSpeedingBackUp = false;
    LastZedTimeEvent = Level.TimeSeconds;

    if ( DesiredZedTimeDuration != 0.0 )
    {
      CurrentZEDTimeDuration = DesiredZedTimeDuration;
    }
    else
    {
      CurrentZEDTimeDuration = ZEDTimeDuration;
    }

    SetGameSpeed(ZedTimeSlomoScale);

    for ( C = Level.ControllerList; C != none; C = C.NextController )
    {
      if (KFPlayerController(C)!= none)
      {
        KFPlayerController(C).ClientEnterZedTime();
      }

      if ( C.PlayerReplicationInfo != none && KFSteamStatsAndAchievements(C.PlayerReplicationInfo.SteamStatsAndAchievements) != none )
      {
        KFSteamStatsAndAchievements(C.PlayerReplicationInfo.SteamStatsAndAchievements).AddZedTime(ZEDTimeDuration);
      }
    }
  }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L486
// DO NOT Force slomo for a longer period of time when the boss dies
function DoBossDeath()
{
  class'hookGT'.default.bBossView = true;

  // global switch
  if (class'Settings'.default.bAllowZedTime)
  {
    bZEDTimeActive =  true;
    bSpeedingBackUp = false;
    LastZedTimeEvent = Level.TimeSeconds;
    CurrentZEDTimeDuration = ZEDTimeDuration*2;
    SetGameSpeed(ZedTimeSlomoScale);

    class'hookGT'.default.BossViewBackTime = Level.Timeseconds + ZEDTimeDuration*1.1;
  }

  // changed controller disabling to directly killing zeds
  Killzeds();
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L4489
// remove latejoiner shit, GameInfo code
event PreLogin( string Options, string Address, string PlayerID, out string Error, out string FailCode )
{
  super(GameInfo).PreLogin( Options, Address, PlayerID, Error, FailCode );
}


// adding garbage collection to here since wave swith doesn't trigger it anymore
// function Logout(Controller Exiting)
// {
//   local Inventory Inv;

//   if (Exiting != none && MessagingSpectator(Exiting) == none )
//   {
//     Exiting.ConsoleCommand("obj garbage");
//     log("Triggered GC for KFPC named: " $ Exiting);
//   }

//   if (Exiting.Pawn != none)
//   {
//     for (Inv = Exiting.Pawn.Inventory; Inv != none; Inv = Inv.Inventory)
//     {
//       if (class<Weapon>(Inv.class) != none)
//         WeaponDestroyed(class<Weapon>(Inv.class));
//     }
//   }

//   super(DeathMatch).Logout(Exiting);
// }


//=============================================================================
//                      LET SPECS TO FLY AFTER GAME ENDS
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L4678
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
      // Get the MapName out of the URL
      MapName = GetCurrentMapName(Level);
    }
  }
  else
  {
    KFGameReplicationInfo(GameReplicationInfo).EndGameType = 1;
  }

  if ( (GameRulesModifiers != none) && !GameRulesModifiers.CheckEndGame(Winner, Reason) )
  {
    KFGameReplicationInfo(GameReplicationInfo).EndGameType = 0;
    return false;
  }

  for (P = Level.ControllerList; P != none; P = P.nextController)
  {
    Player = PlayerController(P);
    if (Player != none)
    {
      Player.ClientSetBehindView(true);
      // disable this so players can move freely after the game ends
      // Player.ClientGameEnded();

      if (bSetAchievement && KFSteamStatsAndAchievements(Player.SteamStatsAndAchievements) != none)
        KFSteamStatsAndAchievements(Player.SteamStatsAndAchievements).WonGame(MapName, GameDifficulty, KFGameLength == GL_Long);

      if (KFGameReplicationInfo(GameReplicationInfo).EndGameType == 1)
      {
        foreach DynamicActors(class'ZombieBoss', class'hookGT'.default.BossArray)
        {
          if (class'hookGT'.default.BossArray == none || class'hookGT'.default.BossArray.Health <= 0)
            continue;
          class'Utility'.static.ShowPatHP(Player, class'hookGT'.default.BossArray);
        }
      }
    }

    // and this
    // P.GameHasEnded();
  }

  // If we won the match
  if ( KFGameReplicationInfo(GameReplicationInfo).EndGameType == 2 )
  {
    CheckHarchierAchievement();
  }

  if ( CurrentGameProfile != none )
  {
    CurrentGameProfile.bWonMatch = false;
  }

  return true;
}


//=============================================================================
//                              Killzeds fix
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L429
exec function KillZeds()
{
  local KFMonster Monster;

  // do not directly kill zeds in this loop
  // it leads to log spam
  foreach DynamicActors(class 'KFMonster', Monster)
  {
    // failsafe
    if (Monster == none || Monster.Health <= 0 && Monster.bDeleteMe)
      continue;
    // fill our array
    class'hookGT'.default.Monsters[class'hookGT'.default.Monsters.length] = Monster;
  }

  // and i have to do this hacky hack to avoid crashes
  // pass it to our new kill function
  class'hookGT'.static.MowZeds(class'hookGT'.default.Monsters);
}


final static function MowZeds(out array<KFMonster> Monsters)
{
  local int i;

  // suicide is the easiest solution
  // + I don't want to add kills to executer
  for (i=0; i<Monsters.length; ++i)
  {
    if (Monsters[i] != none)
      Monsters[i].Suicide();
  }

  Monsters.length = 0;
}


//=============================================================================
//                    Garbage Collection on Server Travel
//=============================================================================

// function ProcessServerTravel( string URL, bool bItems )
// {
//   local playercontroller P, LocalPlayer;

//   // Pass it along
//   BaseMutator.ServerTraveling(URL,bItems);

//   EndLogging("mapchange");

//   // Notify clients we're switching level and give them time to receive.
//   // We call PreClientTravel directly on any local PlayerPawns (ie listen server)
//   log("ProcessServerTravel:"@URL);

//   foreach DynamicActors(class'PlayerController', P)
//   {
//     if ( NetConnection( P.Player) != none )
//     {
//       P.ClientTravel( Eval( Instr(URL,"?") > 0, Left(URL,Instr(URL,"?")), URL), TRAVEL_Relative, bItems );
//       class'hookGT'.static.TriggerGC(p);
//     }
//     else
//     {
//       LocalPlayer = P;
//       P.PreClientTravel();
//       class'hookGT'.static.TriggerGC(p);
//     }
//   }

//   if ( (Level.NetMode == NM_ListenServer) && (LocalPlayer != none) )
//         Level.NextURL = Level.NextURL
//                      $"?Team="$LocalPlayer.GetDefaultURL("Team")
//                      $"?Name="$LocalPlayer.GetDefaultURL("Name")
//                      $"?class="$LocalPlayer.GetDefaultURL("class")
//                      $"?Character="$LocalPlayer.GetDefaultURL("Character");

//   // Switch immediately if not networking.
//   if( Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer )
//     Level.NextSwitchCountdown = 0.0;
// }


final static function TriggerGC(PlayerController p)
{
  if (p == none || KFPlayerController(p) == none)
    return;

  KFPlayerController(p).ClientForceCollectGarbage();
  log("Ayyy, ClientForceCollectGarbage triggered for " $ KFPlayerController(p).PlayerOwnerName);
}


function bool SetPause( BOOL bPause, PlayerController P )
{
  if (bPauseable || (bAdminCanPause && (P.IsA('Admin') || P.PlayerReplicationInfo.bAdmin || P.PlayerReplicationInfo.bSilentAdmin)) || Level.Netmode==NM_Standalone)
  {
    if (bPause)
      Level.Pauser=P.PlayerReplicationInfo;
    else
      Level.Pauser=none;
    return true;
  }
  else return false;
}


//=============================================================================
//                    remove UpdateGameLength() / greylist
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L852
function UpdateGameLength(){}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L1886
exec function AddNamedBot(string botname)
{
  super(Invasion).AddNamedBot(botname);
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L1901
exec function AddBots(int num)
{
  num = Clamp(num, 0, MaxPlayers - (NumPlayers + NumBots));

  while (--num >= 0)
  {
    if (Level.NetMode != NM_Standalone)
      MinPlayers = Max(MinPlayers + 1, NumPlayers + NumBots + 1);
    AddBot();
  }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFGameType.uc#L3118
event PostLogin( PlayerController NewPlayer )
{
  local int i;

  NewPlayer.SetGRI(GameReplicationInfo);
  NewPlayer.PlayerReplicationInfo.PlayerID = CurrentID++;

  super(Invasion).PostLogin(NewPlayer);

  if (UnrealPlayer(NewPlayer) != none)
    UnrealPlayer(NewPlayer).ClientReceiveLoginMenu(LoginMenuClass, bAlwaysShowLoginMenu);
  if (NewPlayer.PlayerReplicationInfo.Team != none)
    GameEvent("TeamChange",""$NewPlayer.PlayerReplicationInfo.Team.TeamIndex,NewPlayer.PlayerReplicationInfo);

  if (NewPlayer != none && Level.NetMode == NM_ListenServer && Level.GetLocalPlayerController() == NewPlayer)
    NewPlayer.InitializeVoiceChat();

  if (KFPlayerController(NewPlayer) != none)
  {
    for (i = 0; i < InstancedWeaponClasses.Length; i++)
    {
      KFPlayerController(NewPlayer).ClientWeaponSpawned(InstancedWeaponClasses[i], none);
    }
  }

  if (NewPlayer.PlayerReplicationInfo.bOnlySpectator) // must not be a spectator
  {
    KFPlayerController(NewPlayer).JoinedAsSpectatorOnly();
  }
  else
  {
    NewPlayer.GotoState('PlayerWaiting');
  }

  if (KFPlayerController(NewPlayer) != none)
    StartInitGameMusic(KFPlayerController(NewPlayer));

  // if (bCustomGameLength && NewPlayer.SteamStatsAndAchievements != none)
  // {
  //    NewPlayer.SteamStatsAndAchievements.bUsedCheats = true;
  // }
}


defaultproperties
{
  GameName="Dummy Floor"
  Description="Dummy GT for dark magic."
  Acronym="DF"
}