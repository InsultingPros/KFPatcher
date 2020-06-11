class stubMonster extends KFMonster;


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
      if( bDecapitated && Class<KFWeaponDamageType>(damageType) != none && instigatedBy != none && KFPlayerController(instigatedBy.Controller) != none )
      {
        bLaserSightedEBRM14Headshotted = M14EBRBattleRifle(instigatedBy.Weapon) != none && M14EBRBattleRifle(instigatedBy.Weapon).bLaserActive;
        Class<KFWeaponDamageType>(damageType).Static.ScoredHeadshot(KFSteamStatsAndAchievements(PlayerController(instigatedBy.Controller).SteamStatsAndAchievements), self.Class, bLaserSightedEBRM14Headshotted);
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

  // block yet another zed time call
  // if( bIsHeadShot && Health <= 0 )
  // {
  //   KFGameType(Level.Game).DramaticEvent(0.03);
  // }

  bBackstabbed = false;
}


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
      SetGroundSpeed(GetOriginalGroundSpeed());
    }
	}
}