class repl_Z_Siren extends ZombieSiren;


// if decapped no scream
simulated function SpawnTwoShots()
{
  // added bDecapitated check
  // headless chickens can't cry
  if (bZapped || bDecapitated)
    return;

  DoShakeEffect();

  if (Level.NetMode != NM_Client)
  {
    if (Controller != none && KFDoorMover(Controller.Target) != none)
      Controller.Target.TakeDamage(ScreamDamage*0.6,self,Location,vect(0,0,0),ScreamDamageType);
    else
      HurtRadius(ScreamDamage ,ScreamRadius, ScreamDamageType, ScreamForce, Location);
  }
}


simulated function HurtRadius(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
  local actor Victims;
  local float damageScale, dist;
  local vector dir;
  local float UsedDamageAmount;

  // DEBUG!!!
  // StopWatch(false);

  if (bHurtEntry)
    return;

  bHurtEntry = true;

  // was VisibleCollidingActors
  foreach CollidingActors(class'Actor', Victims, DamageRadius, HitLocation)
  {
    // some optimizations
    // https://wiki.beyondunreal.com/Legacy:Code_Optimization#Optimize_iterator_use
    if (Victims.bStatic || Victims.Physics == PHYS_None || !FastTrace(Victims.Location, Location) )
        continue; // skip this actor

    // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
    // Or Karma actors in this case. self inflicted Death due to flying chairs is uncool for a zombie of your stature.
    if ((Victims != self) && !Victims.IsA('FluidSurfaceInfo') && !Victims.IsA('KFMonster') && !Victims.IsA('ExtendedZCollision'))
    {
      Momentum = ScreamForce; // bugfix, when pull wasn't applied always  -- PooSH
      dir = Victims.Location - HitLocation;
      dist = FMax(1,VSize(dir));
      dir = dir/dist;
      damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

      if (!Victims.IsA('KFHumanPawn')) // If it aint human, don't pull the vortex crap on it.
        Momentum = 0;

      if (Victims.IsA('KFGlassMover'))   // Hack for shattering in interesting ways.
      {
        UsedDamageAmount = 100000; // Siren always shatters glass
      }
      else
      {
        UsedDamageAmount = DamageAmount;
      }

      // fixed instigator not set to self!
      Victims.TakeDamage(damageScale * UsedDamageAmount, self, Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),DamageType);

      if (Instigator != none && Vehicle(Victims) != none && Vehicle(Victims).Health > 0)
        Vehicle(Victims).DriverRadiusDamage(UsedDamageAmount, DamageRadius, Instigator.Controller, DamageType, Momentum, HitLocation);
    }
  }

  bHurtEntry = false;

  // StopWatch(true);
}