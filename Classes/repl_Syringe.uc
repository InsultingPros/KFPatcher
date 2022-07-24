class repl_Syringe extends Syringe
  CacheExempt;  // do NOT include me in UCL and do NOT be discoverable in menus


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/Syringe.uc#L168
// fix syringe heal ammounts when players die
simulated function bool HackClientStartFire()
{
  if (StartFire(1))
  {
    if (Role < ROLE_Authority)
    {
      // best idea i've come to
      // at least im not running timer like Poosh
      if (Level.Game.NumPlayers == 1)
        HealBoostAmount = 50;
      else
        HealBoostAmount = default.HealBoostAmount;

      ServerStartFire(1);
    }

    FireMode[1].ModeDoFire(); // Force to start animating.
    return true;
  }
  return false;
}