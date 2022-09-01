class hookMonster extends KFMonster;


var transient float fLastAttackTime;


//=============================================================================
//                            controller == none fix
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L1242
// when you kill zeds before they fall into stun
// should i check it before whole function body??
function bool FlipOver()
{
  if (Physics == PHYS_Falling)
    SetPhysics(PHYS_Walking);

  bShotAnim = true;
  SetAnimAction('KnockDown');
  Acceleration = vect(0, 0, 0);
  Velocity.X = 0;
  Velocity.Y = 0;

  // fix!
  if (Controller != none && KFMonsterController(Controller) != none)
  {
    Controller.GoToState('WaitForAnim');
    KFMonsterController(Controller).bUseFreezeHack = true;
  }

  return true;
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L2527
// fix ctrl nonelog spam
simulated function HandleBumpGlass()
{
  Acceleration = vect(0,0,0);
  Velocity = vect(0,0,0);

  SetAnimAction(MeleeAnims[0]);
  bShotAnim = true;

  // fix!
  if (Controller != none)
    controller.GotoState('WaitForAnim');
}

//=============================================================================
//                            instigatedBy == none fix
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L2631
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType, optional int HitIndex )
{
  local bool bIsHeadshot;
  local KFPlayerReplicationInfo KFPRI;
  local float HeadShotCheckScale;

  // if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)

  LastDamagedBy = instigatedBy;
  LastDamagedByType = damageType;
  HitMomentum = VSize(momentum);
  LastHitLocation = hitlocation;
  LastMomentum = momentum;

  if ( instigatedBy != none && KFPawn(instigatedBy) != none && instigatedBy.PlayerReplicationInfo != none )
    KFPRI = KFPlayerReplicationInfo(instigatedBy.PlayerReplicationInfo);

  // Scale damage if the Zed has been zapped
  if ( bZapped )
    Damage *= ZappedDamageMod;

  // Zeds and fire dont mix.
  if ( class<KFWeaponDamageType>(damageType) != none && class<KFWeaponDamageType>(damageType).default.bDealBurningDamage )
  {
    if( BurnDown<=0 || Damage > LastBurnDamage )
    {
      // LastBurnDamage variable is storing last burn damage (unperked) received,
      // which will be used to make additional damage per every burn tick (second).
      LastBurnDamage = Damage;

      // FireDamageClass variable stores damage type, which started zed's burning
      // and will be passed to this function again every next burn tick (as damageType argument)
      if ( class<DamTypeTrenchgun>(damageType) != none ||
         class<DamTypeFlareRevolver>(damageType) != none ||
         class<DamTypeMAC10MPInc>(damageType) != none)
      {
        FireDamageClass = damageType;
      }
      else
      {
        FireDamageClass = class'DamTypeFlamethrower';
      }
    }

    if ( class<DamTypeMAC10MPInc>(damageType) == none )
      Damage *= 1.5; // Increase burn damage 1.5 times, except MAC10.

    // BurnDown variable indicates how many ticks are remaining for zed to burn.
    // It is 0, when zed isn't burning (or stopped burning).
    // So all the code below will be executed only, if zed isn't already burning
    if ( BurnDown <= 0 )
    {
      if( HeatAmount > 4 || Damage >= 15 )
      {
        bBurnified = true;
        BurnDown = 10; // Inits burn tick count to 10
        SetGroundSpeed(GroundSpeed *= 0.80); // Lowers movement speed by 20%
        BurnInstigator = instigatedBy;
        SetTimer(1.0,false); // Sets timer function to be executed each second
      }
      else
        HeatAmount++;
    }
  }

  if ( !bDecapitated && class<KFWeaponDamageType>(damageType)!=none &&
    class<KFWeaponDamageType>(damageType).default.bCheckForHeadShots )
  {
    HeadShotCheckScale = 1.0;

    // Do larger headshot checks if it is a melee attach
    if( class<DamTypeMelee>(damageType) != none )
      HeadShotCheckScale *= 1.25;

    bIsHeadShot = IsHeadShot(hitlocation, normal(momentum), HeadShotCheckScale);
    bLaserSightedEBRM14Headshotted = bIsHeadshot && M14EBRBattleRifle(instigatedBy.Weapon) != none && M14EBRBattleRifle(instigatedBy.Weapon).bLaserActive;
  }

  else
  {
    bLaserSightedEBRM14Headshotted = bLaserSightedEBRM14Headshotted && bDecapitated;
  }

  if ( KFPRI != none  )
  {
    if ( KFPRI.ClientVeteranSkill != none )
    {
      Damage = KFPRI.ClientVeteranSkill.Static.AddDamage(KFPRI, self, KFPawn(instigatedBy), Damage, DamageType);
    }
  }

  if ( LastDamagedBy != none && damageType != none && LastDamagedBy.IsPlayerPawn() && LastDamagedBy.Controller != none )
  {
    if ( KFMonsterController(Controller) != none )
    {
      KFMonsterController(Controller).AddKillAssistant(LastDamagedBy.Controller, FMin(Health, Damage));
    }
  }

  if ( (bDecapitated || bIsHeadShot) && class<DamTypeBurned>(DamageType) == none && class<DamTypeFlamethrower>(DamageType) == none )
  {
    if(class<KFWeaponDamageType>(damageType)!=none)
      Damage = Damage * class<KFWeaponDamageType>(damageType).default.HeadShotDamageMult;

    if ( class<DamTypeMelee>(damageType) == none && KFPRI != none &&
       KFPRI.ClientVeteranSkill != none )
    {
      Damage = float(Damage) * KFPRI.ClientVeteranSkill.Static.GetHeadShotDamMulti(KFPRI, KFPawn(instigatedBy), DamageType);
    }

    LastDamageAmount = Damage;

    if( !bDecapitated )
    {
      if( bIsHeadShot )
      {
        // Play a sound when someone gets a headshot TODO: Put in the real sound here
        if( bIsHeadShot )
        {
          PlaySound(sound'KF_EnemyGlobalSndTwo.Impact_Skull', SLOT_None,2.0,true,500);
        }
        HeadHealth -= LastDamageAmount;
        if( HeadHealth <= 0 || Damage > Health )
        {
          RemoveHead();
        }
      }

      // Award headshot here, not when zombie died.
      if( bDecapitated && class<KFWeaponDamageType>(damageType) != none && instigatedBy != none && KFPlayerController(instigatedBy.Controller) != none )
      {
        bLaserSightedEBRM14Headshotted = M14EBRBattleRifle(instigatedBy.Weapon) != none && M14EBRBattleRifle(instigatedBy.Weapon).bLaserActive;
        class<KFWeaponDamageType>(damageType).Static.ScoredHeadshot(KFSteamStatsAndAchievements(PlayerController(instigatedBy.Controller).SteamStatsAndAchievements), self.class, bLaserSightedEBRM14Headshotted);
      }
    }
  }

  // Client check for Gore FX
  // BodyPartRemoval(Damage,instigatedBy,hitlocation,momentum,damageType);

  if( Health-Damage > 0 && DamageType!=class'DamTypeFrag' && DamageType!=class'DamTypePipeBomb'
    && DamageType!=class'DamTypeM79Grenade' && DamageType!=class'DamTypeM32Grenade'
        && DamageType!=class'DamTypeM203Grenade' && DamageType!=class'DamTypeDwarfAxe'
        && DamageType!=class'DamTypeSPGrenade' && DamageType!=class'DamTypeSealSquealExplosion'
        && DamageType!=class'DamTypeSeekerSixRocket')
  {
    Momentum = vect(0,0,0);
  }

  if(class<DamTypeVomit>(DamageType) != none) // Same rules apply to zombies as players.
  {
    BileCount=7;
    if (instigatedBy != none)
      BileInstigator = instigatedBy;
    else
      BileInstigator = self;
    LastBileDamagedByType=class<DamTypeVomit>(DamageType);
    if(NextBileTime< Level.TimeSeconds )
      NextBileTime = Level.TimeSeconds+BileFrequency;
  }

  if ( KFPRI != none && Health-Damage <= 0 && KFPRI.ClientVeteranSkill != none && KFPRI.ClientVeteranSkill.static.KilledShouldExplode(KFPRI, KFPawn(instigatedBy)) )
  {
    Super(Monster).takeDamage(Damage + 600, instigatedBy, hitLocation, momentum, damageType);
    HurtRadius(500, 1000, class'DamTypeFrag', 100000, Location);
  }
  else
  {
    Super(Monster).takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);
  }

  // if (Damage*1.5 >= default.Health || (Damage > 200 && KFDamType != none && KFDamType.default.bSniperWeapon && ZedVictim.IsA('ZombieHusk') ))
  // {
  //   ZedVictim.Controller.Focus = none;
  //   ZedVictim.Controller.FocalPoint = ZedVictim.Location + 512 * vector(ZedVictim.Rotation);
  // }

  // block yet another zed time call
  // if( bIsHeadShot && Health <= 0 )
  // {
  //   KFGameType(Level.Game).DramaticEvent(0.03);
  // }

  bBackstabbed = false;
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L3688
// attempt to fix ground speed bugs
function TakeFireDamage(int Damage,pawn Instigator)
{
  local Vector DummyHitLoc,DummyMomentum;

  TakeDamage(Damage, BurnInstigator, DummyHitLoc, DummyMomentum, FireDamageClass);

  if ( BurnDown > 0 )
  {
    // Decrement the number of FireDamage calls left before our Zombie is extinguished :)
    BurnDown --;
  }

  // Melt em' :)
  if ( BurnDown < CrispUpThreshhold )
  {
    ZombieCrispUp();
  }

  if ( BurnDown == 0 )
  {
    bBurnified = false;
    if( !bZapped )
    {
      // was `default.GroundSpeed`
      SetGroundSpeed(GetOriginalGroundSpeed());
    }
  }
}


//=============================================================================
//                      fix for zed corpse collision shit
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L1566
// Stops the green shit when a player dies.
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
  local float frame, rate;
  local name seq;
  local LavaDeath LD;
  local MiscEmmiter BE;

  AmbientSound = none;
  bCanTeleport = false; // sjs - fix karma going crazy when corpses land on teleporters
  bReplicateMovement = false;
  bTearOff = true;
  bPlayedDeath = true;
  StopBurnFX();

  if (CurrentCombo != none)
    CurrentCombo.Destroy();

  HitDamageType = DamageType; // these are replicated to other clients
  TakeHitLocation = HitLoc;

  bSTUNNED = false;
  bMovable = true;

  if ( class<DamTypeBurned>(DamageType) != none || class<DamTypeFlamethrower>(DamageType) != none )
  {
    ZombieCrispUp();
  }

  ProcessHitFX() ;

  if ( DamageType != none )
  {
    if ( DamageType.default.bSkeletize )
    {
      SetOverlayMaterial(DamageType.default.DamageOverlayMaterial, 4.0, true);
      if (!bSkeletized)
      {
        if ( (Level.NetMode != NM_DedicatedServer) && (SkeletonMesh != none) )
        {
          if ( DamageType.default.bLeaveBodyEffect )
          {
            BE = spawn(class'MiscEmmiter',self);
            if ( BE != none )
            {
              BE.DamageType = DamageType;
              BE.HitLoc = HitLoc;
              bFrozenBody = true;
            }
          }
          GetAnimParams( 0, seq, frame, rate );
          LinkMesh(SkeletonMesh, true);
          Skins.Length = 0;
          PlayAnim(seq, 0, 0);
          SetAnimFrame(frame);
        }
        if (Physics == PHYS_Walking)
          Velocity = Vect(0,0,0);
        SetTearOffMomemtum(GetTearOffMomemtum() * 0.25);
        bSkeletized = true;
        if ( (Level.NetMode != NM_DedicatedServer) && (DamageType == class'FellLava') )
        {
          LD = spawn(class'LavaDeath', , , Location + vect(0, 0, 10), Rotation );
          if ( LD != none )
            LD.SetBase(self);
          //PlaySound( sound'WeaponSounds.BExplosion5', SLOT_None, 1.5*TransientSoundVolume );
        }
      }
    }
    else if ( DamageType.default.DeathOverlayMaterial != none )
      SetOverlayMaterial(DamageType.default.DeathOverlayMaterial, DamageType.default.DeathOverlayTime, true);
    else if ( (DamageType.default.DamageOverlayMaterial != none) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
      SetOverlayMaterial(DamageType.default.DamageOverlayMaterial, 2*DamageType.default.DamageOverlayTime, true);
  }

  // stop shooting
  AnimBlendParams(1, 0.0);
  FireState = FS_None;

  // Try to adjust around performance
  //log(Level.DetailMode);

  LifeSpan = RagdollLifeSpan;

  GotoState('ZombieDying');
  if ( BE != none )
    return;
  PlayDyingAnimation(DamageType, HitLoc);

  // ADDITION for collision fix
  bBlockActors = false;
  bBlockPlayers = false;
  bBlockProjectiles = false;
  bProjTarget = false;
  bBlockZeroExtentTraces = false;
  bBlockNonZeroExtentTraces = false;
  bBlockHitPointTraces = false;
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L1656
state ZombieDying
{
  // https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L1716
  simulated function BeginState()
  {
    // ADDITION for collision fix
    bBlockActors = false;
    bBlockPlayers = false;
    bBlockProjectiles = false;
    bProjTarget = false;
    bBlockZeroExtentTraces = false;
    bBlockNonZeroExtentTraces = false;
    bBlockHitPointTraces = false;

    if (bDestroyNextTick)
    {
      // If we've flagged this character to be destroyed next tick, handle that
      if (TimeSetDestroyNextTickTime < Level.TimeSeconds)
        Destroy();
      else
        SetTimer(0.01, false);
    }
    else
    {
      if (bTearOff && (Level.NetMode == NM_DedicatedServer) || class'GameInfo'.static.UseLowGore())
        LifeSpan = 1.0;
      else
        SetTimer(2.0, false);
    }

    SetPhysics(PHYS_Falling);
    if (Controller != none)
      Controller.Destroy();
  }
}


//=============================================================================
//                    lets limit some zeds attack abilities
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFMonster.uc#L3164
function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
  local vector HitLocation, HitNormal;
  local actor HitActor;
  local Name TearBone;
  local float dummy;
  local Emitter BloodHit;
  // local vector TraceDir;

  // Never should be done on client.
  if (Level.NetMode == NM_Client || Controller == none)
    return false;

  // try to limit some zeds
  if ((ClassIsChildOf(self.class, class'ZombieCrawler') || ClassIsChildOf(self.class, class'ZombieFleshpound')) && (Level.TimeSeconds < class'hookMonster'.default.fLastAttackTime))
    return false;

  // ATTENTION!!! is 0.3 secs ok?
  class'hookMonster'.default.fLastAttackTime = Level.TimeSeconds + 0.3f;

  if (Controller.Target!=none && Controller.Target.IsA('KFDoorMover'))
  {
    Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType);
    return true;
  }

  // need to uncomment this and check :D
  // ClearStayingDebugLines();
  // TraceDir = Normal(Controller.Target.Location - Location);
  // DrawStayingDebugLine(Location, Location + (TraceDir * (MeleeRange * 1.4 + Controller.Target.CollisionRadius + CollisionRadius)) , 255,255,0);

  // check if still in melee range
  if ( (Controller.target != none) && (bSTUNNED == false) && (DECAP == false) && (VSize(Controller.Target.Location - Location) <= MeleeRange * 1.4 + Controller.Target.CollisionRadius + CollisionRadius)
    && ((Physics == PHYS_Flying) || (Physics == PHYS_Swimming) || (Abs(Location.Z - Controller.Target.Location.Z)
      <= FMax(CollisionHeight, Controller.Target.CollisionHeight) + 0.5 * FMin(CollisionHeight, Controller.Target.CollisionHeight))) )
  {
    // See if a trace would hit a pawn (Have to turn of hit point collision so trace doesn't hit the Human Pawn's bullet whiz cylinder)
    bBlockHitPointTraces = false;
    HitActor = Trace(HitLocation, HitNormal, Controller.Target.Location , Location + EyePosition(), true);
    bBlockHitPointTraces = true;

    // If the trace wouldn't hit a pawn, do the old thing of just checking if there is something blocking the trace
    if (Pawn(HitActor) == none)
    {
      // Have to turn of hit point collision so trace doesn't hit the Human Pawn's bullet whiz cylinder
      bBlockHitPointTraces = false;
      HitActor = Trace(HitLocation, HitNormal, Controller.Target.Location, Location, false);
      bBlockHitPointTraces = true;

      if (HitActor != none)
        return false;
    }

    if (KFHumanPawn(Controller.Target) != none)
    {
      //TODO - line below was KFPawn. Does this whole block need to be KFPawn, or is it OK as KFHumanPawn?
      KFHumanPawn(Controller.Target).TakeDamage(hitdamage, Instigator ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');

      if (KFHumanPawn(Controller.Target).Health <=0)
      {
        if (!class'GameInfo'.static.UseLowGore())
        {
          BloodHit = Spawn(class'KFMod.FeedingSpray',self,,Controller.Target.Location,rotator(pushdir));   //
          KFHumanPawn(Controller.Target).SpawnGibs(rotator(pushdir), 1);
          TearBone=KFPawn(Controller.Target).GetClosestBone(HitLocation,Velocity,dummy);
          KFHumanPawn(Controller.Target).HideBone(TearBone);
        }

        // Give us some Health back
        if (Health <= (1.0-FeedThreshold)*HealthMax)
        {
          Health += FeedThreshold*HealthMax * Health/HealthMax;
        }
      }

    }
    else if (Controller.target != none)
    {
      // Do more damage if you are attacking another zed so that zeds don't just stand there whacking each other forever! - Ramm
      if (KFMonster(Controller.Target) != none)
        hitdamage *= DamageToMonsterScale;

      Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');
    }

    return true;
  }

  return false;
}