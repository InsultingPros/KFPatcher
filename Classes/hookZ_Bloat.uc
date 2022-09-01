class hookZ_Bloat extends ZombieBloat;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieBloat.uc#L207
// ZombieBloat.SpawnTwoShots
function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;

    // check this from the very start to prevent any log spam
    if (Controller == none || IsInState('ZombieDying'))
        return;

    if (KFDoorMover(Controller.Target) != none)
    {
        Controller.Target.TakeDamage(22, self, Location, vect(0,0,0), class'DamTypeVomit');
        return;
    }

    GetAxes(Rotation,X,Y,Z);
    FireStart = Location+(vect(30,0,64) >> Rotation)*DrawScale;
    if (!SavedFireProperties.bInitialized)
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

    // Turn off extra collision before spawning vomit, otherwise spawn fails
    ToggleAuxCollision(false);
    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);
    Spawn(class'KFBloatVomit',self,,FireStart,FireRotation);

    FireStart -= (0.5*CollisionRadius*Y);
    FireRotation.Yaw -= 1200;
    spawn(class'KFBloatVomit',self,,FireStart, FireRotation);

    FireStart += (CollisionRadius*Y);
    FireRotation.Yaw += 2400;
    spawn(class'KFBloatVomit', self,, FireStart, FireRotation);
    // Turn extra collision back on
    ToggleAuxCollision(true);
}