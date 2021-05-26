class stub_Z_Scrake_Ctrl extends SawZombieController;


function EndState()
{
  if (Pawn != None)
  {
    Pawn.AccelRate = Pawn.Default.AccelRate;
    Pawn.GroundSpeed = ZombieScrake(Pawn).GetOriginalGroundSpeed();
  }
}