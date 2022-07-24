class repl_Z_Boss extends ZombieBoss;


//=============================================================================
//                              ammo class == none fix
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieBoss.uc#L957
state FireMissile
{
  // https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieBoss.uc#L971
  function AnimEnd(int Channel)
  {
    local vector Start;
    local Rotator R;

    Start = GetBoneCoords('tip').Origin;

    // at least shoot at someone, not walls
    if (Controller.Target == none)
      Controller.Target = Controller.Enemy;

    // fix MyAmmo none logs
    if (!SavedFireProperties.bInitialized)
    {
      // ADDITION!!!
      SavedFireProperties.AmmoClass = class'SkaarjAmmo';
      SavedFireProperties.ProjectileClass = class'BossLAWProj';
      SavedFireProperties.WarnTargetPct = 0.15;
      SavedFireProperties.MaxRange = 10000;
      SavedFireProperties.bTossed = false;
      SavedFireProperties.bTrySplash = false;
      SavedFireProperties.bLeadTarget = true;
      SavedFireProperties.bInstantHit = true;
      SavedFireProperties.bInitialized = true;
    }

    R = AdjustAim(SavedFireProperties,Start,100);
    PlaySound(RocketFireSound,SLOT_Interact,2.0,,TransientSoundRadius,,false);
    // ADDITION!!! proper projectile owner...
    spawn(class'BossLAWProj',self,,Start,R);

    bShotAnim = true;
    Acceleration = vect(0,0,0);
    SetAnimAction('FireEndMissile');
    HandleWaitForAnim('FireEndMissile');

    // Randomly send out a message about Patriarch shooting a rocket(5% chance)
    if ( FRand() < 0.05 && Controller.Enemy != none && PlayerController(Controller.Enemy.Controller) != none )
    {
      PlayerController(Controller.Enemy.Controller).Speech('AUTO', 10, "");
    }

    GoToState('');
  }
}


//=============================================================================
//                              ctrl == none fixes
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieBoss.uc#L1016
function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
  // ADDITION!!! 'Controller != none' check
  if (Controller != none && Controller.Target != none && Controller.Target.IsA('NetKActor'))
    pushdir = Normal(Controller.Target.Location-Location)*100000;

  return super(KFMonster).MeleeDamageTarget(hitdamage, pushdir);
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieBoss.uc#L1768
// non-state one
function ClawDamageTarget()
{
  local vector PushDir;
  local name Anim;
  local float frame,rate;
  local float UsedMeleeDamage;
  local bool bDamagedSomeone;
  local KFHumanPawn P;
  local Actor OldTarget;

  // ADDITION!!! check this from the very start to prevent any log spam
  if (Controller == none || IsInState('ZombieDying'))
    return;

  if (MeleeDamage > 1)
    UsedMeleeDamage = (MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1));
  else
    UsedMeleeDamage = MeleeDamage;

  GetAnimParams(1, Anim,frame,rate);

  if (Controller.Target != none)
    PushDir = (damageForce * Normal(Controller.Target.Location - Location));
  else
    PushDir = damageForce * vector(Rotation);

  // merging 2 similar checks
  // dick animation
  if (Anim == 'MeleeImpale')
  {
    MeleeRange = ImpaleMeleeDamageRange;
    bDamagedSomeone = MeleeDamageTarget(UsedMeleeDamage, PushDir);
  }
  // the hand animation
  else
  {
    MeleeRange = ClawMeleeDamageRange;
    OldTarget = Controller.Target;

    foreach DynamicActors(class'KFHumanPawn', P)
    {
      if ( (P.Location - Location) dot PushDir > 0.0 ) // Added dot Product check in Balance Round 3
      {
        Controller.Target = P;
        bDamagedSomeone = bDamagedSomeone || MeleeDamageTarget(UsedMeleeDamage, damageForce * Normal(P.Location - Location)); // Always pushing players away added in Balance Round 3
      }
    }

    Controller.Target = OldTarget;
  }

  MeleeRange = default.MeleeRange;

  if (bDamagedSomeone)
  {
    if (Anim == 'MeleeImpale')
      PlaySound(MeleeImpaleHitSound, SLOT_Interact, 2.0);
    else
      PlaySound(MeleeAttackHitSound, SLOT_Interact, 2.0);
  }
}


//=============================================================================
//                   headshot fix while he is machinegunning
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieBoss.uc#L734
state FireChaingun
{
  // https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieBoss.uc#L748
  function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
  {
    local float EnemyDistSq, DamagerDistSq;

    // changed vect(0,0,0) with Momentum
    global.TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);

    // if someone close up is shooting us, just charge them
    if (InstigatedBy != none)
    {
      DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);

      if ( (ChargeDamage > 200 && DamagerDistSq < (500 * 500)) || DamagerDistSq < (100 * 100) )
      {
        SetAnimAction('transition');
        GoToState('Charging');
        return;
      }
    }

    if (Controller.Enemy != none && InstigatedBy != none && InstigatedBy != Controller.Enemy)
    {
      EnemyDistSq = VSizeSquared(Location - Controller.Enemy.Location);
      DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
    }

    if (InstigatedBy != none && (DamagerDistSq < EnemyDistSq || Controller.Enemy == none) )
    {
      MonsterController(Controller).ChangeEnemy(InstigatedBy,Controller.CanSee(InstigatedBy));
      Controller.Target = InstigatedBy;
      Controller.Focus = InstigatedBy;

      if( DamagerDistSq < (500 * 500) )
      {
        SetAnimAction('transition');
        GoToState('Charging');
      }
    }
  }
}


defaultproperties{}