class stub_Z_Husk extends ZombieHusk_HALLOWEEN;


function SpawnTwoShots()
{
  local vector X,Y,Z, FireStart;
  local rotator FireRotation;
  local KFMonsterController KFMonstControl;

  if (Controller == none || IsInState('ZombieDying') || IsInState('GettingOutOfTheWayOfShot') || Physics == PHYS_Falling)
    return;

  if (KFDoorMover(Controller.Target) != none)
  {
    Controller.Target.TakeDamage(22, Self, Location,vect(0,0,0), Class'DamTypeVomit');
    return;
  }

  GetAxes(Rotation,X,Y,Z);
  FireStart = GetBoneCoords('Barrel').Origin;

  // detect outer and change projectile class
  // since we use this function for all husk classes
  if (ClassIsChildOf(self.class, class'ZombieHusk_HALLOWEEN'))
    HuskFireProjClass = class'KFChar.HuskFireProjectile_HALLOWEEN';
  else
    HuskFireProjClass = class'KFChar.HuskFireProjectile';

  // if (self.class.name == 'ZombieHusk_HALLOWEEN')
  //   HuskFireProjClass = class'KFChar.HuskFireProjectile_HALLOWEEN';
  // else
  //   HuskFireProjClass = class'KFChar.HuskFireProjectile';

  if (!SavedFireProperties.bInitialized)
  {
    SavedFireProperties.AmmoClass = class'SkaarjAmmo';
    SavedFireProperties.ProjectileClass = HuskFireProjClass;
    SavedFireProperties.WarnTargetPct = 1;
    SavedFireProperties.MaxRange = 65535;
    SavedFireProperties.bTossed = false;
    SavedFireProperties.bTrySplash = true;
    SavedFireProperties.bLeadTarget = true;
    SavedFireProperties.bInstantHit = false;
    SavedFireProperties.bInitialized = true;
  }

  // Turn off extra collision before spawning projectile, otherwise spawn fails
  ToggleAuxCollision(false);

  FireRotation = Controller.AdjustAim(SavedFireProperties, FireStart, 600);

  // do not move fleshpounds !
  foreach DynamicActors(class'KFMonsterController', KFMonstControl)
  {
    // I gotta love this one, Jaby
    // ignore zeds that the husk can't see...
    if (KFMonstControl== none || !LineOfSightTo(KFMonstControl))
      continue;

    if (KFMonstControl != Controller && !ClassIsChildOf(KFMonstControl, class'FleshpoundZombieController'))
    {
      if (PointDistToLine(KFMonstControl.Pawn.Location, vector(FireRotation), FireStart) < 75 )
      {
        KFMonstControl.GetOutOfTheWayOfShot(vector(FireRotation),FireStart);
      }
    }
  }

  // added projectile owner...
  Spawn(HuskFireProjClass,self,,FireStart,FireRotation);

  // Turn extra collision back on
  ToggleAuxCollision(true);
}