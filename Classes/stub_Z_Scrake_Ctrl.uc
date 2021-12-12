class stub_Z_Scrake_Ctrl extends SawZombieController;


function EndState()
{
  if (Pawn != none)
  {
    Pawn.AccelRate = Pawn.default.AccelRate;
    Pawn.GroundSpeed = ZombieScrake(Pawn).GetOriginalGroundSpeed();
  }
}