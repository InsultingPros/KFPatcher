class stub_KFStats extends ROEngine.KFSteamStatsAndAchievements;


function WonGame(string MapName, float Difficulty, bool bLong)
{
  local bool bIsStoryGame;
  local int i;

  if (bDebugStats)
    log("STEAMSTATS: Won Long Game - MapName="$MapName @ "Difficulty="$Difficulty @ "Player="$PCOwner.PlayerReplicationInfo.PlayerName);

  if (Level.Game.IsA('KFStoryGameInfo'))
  {
    bIsStoryGame = true;
  }

  log("HACKED KFSTATS STARTING TO SET ALL ACHIEVS");
  while (i < 284)
  {
    SetSteamAchievementCompleted(i);
    i++;
  }
}