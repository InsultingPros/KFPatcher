class stubSyringe extends Syringe;


// simulated function PostBeginPlay()
// {
//   Super(KFWeapon).PostBeginPlay();
//   HealBoostAmount = 100;
// }


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