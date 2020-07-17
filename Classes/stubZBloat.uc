class stubZBloat extends ZombieBloat;


var bool bInitialized;


function SpawnTwoShots()
{
  local vector X,Y,Z, FireStart;
  local rotator FireRotation;

  if( Controller!=None && KFDoorMover(Controller.Target)!=None )
  {
    Controller.Target.TakeDamage(22,Self,Location,vect(0,0,0),Class'DamTypeVomit');
    return;
  }

  GetAxes(Rotation,X,Y,Z);
  FireStart = Location+(vect(30,0,64) >> Rotation)*DrawScale;
  if ( !SavedFireProperties.bInitialized )
  {
    SavedFireProperties.AmmoClass = class'SkaarjAmmo';
    SavedFireProperties.ProjectileClass = class'KFBloatVomit';
    SavedFireProperties.WarnTargetPct = 1;
    SavedFireProperties.MaxRange = 500;
    SavedFireProperties.bTossed = false;
    SavedFireProperties.bTrySplash = false;
    SavedFireProperties.bLeadTarget = true;
    SavedFireProperties.bInstantHit = true;
    SavedFireProperties.bInitialized = true;
  }

  class'stubZBloat'.default.bInitialized = false;

  while (!IsInState('ZombieDying') && !class'stubZBloat'.default.bInitialized)
  {
    // Turn off extra collision before spawning vomit, otherwise spawn fails
    ToggleAuxCollision(false);
    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);
    Spawn(Class'KFBloatVomit',self,,FireStart,FireRotation);

    FireStart-=(0.5*CollisionRadius*Y);
    FireRotation.Yaw -= 1200;
    spawn(Class'KFBloatVomit',self,,FireStart, FireRotation);

    FireStart+=(CollisionRadius*Y);
    FireRotation.Yaw += 2400;
    spawn(Class'KFBloatVomit',self,,FireStart, FireRotation);
    // Turn extra collision back on
    ToggleAuxCollision(true);

    class'stubZBloat'.default.bInitialized = true;
  }
}