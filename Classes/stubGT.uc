class stubGT extends KFGameType;


// disable slomo!
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
        if (KFMonsterController(C)!=None)
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

    if ( (GameRulesModifiers != None) && !GameRulesModifiers.CheckEndGame(Winner, Reason) ) 
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
