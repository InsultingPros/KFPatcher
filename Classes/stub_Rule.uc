class stub_Rule extends GameRules;


// no map switch if we leave from lobby
function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
  if (Level.Game.IsInState('PendingMatch'))
    return false;

  if (NextGameRules != none)
    return NextGameRules.CheckEndGame(Winner, Reason);

  return true;
}