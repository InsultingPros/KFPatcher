class stubZScrakeCtrl extends SawZombieController;


function EndState()
{
  if (Pawn != None)
  {
    Pawn.AccelRate = Pawn.Default.AccelRate;
    Pawn.GroundSpeed = ZombieScrake(Pawn).GetOriginalGroundSpeed();
  }
}