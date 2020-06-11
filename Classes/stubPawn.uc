class stubPawn extends KFHumanPawn_Story;


// toss some of your cash away. (to help a cash-strapped ally or perhaps just to party like its 1994)
exec function TossCash( int Amount )
{
  local Vector X,Y,Z;
  local CashPickup CashPickup ;
  local Vector TossVel;
  local Actor A;

  if(Level.TimeSeconds < class'MuVariableClass'.default.varTimer2)
  {
    return;
  }
  class'MuVariableClass'.default.varTimer2 = Level.TimeSeconds + 0.3f;

  // set minimal dosh
  Amount = clamp(Amount, 30, 500000);

  Controller.PlayerReplicationInfo.Score = int(Controller.PlayerReplicationInfo.Score); // To fix issue with throwing 0 pounds.
  if( Controller.PlayerReplicationInfo.Score<=0 || Amount<=0 )
    return;
  Amount = Min(Amount,int(Controller.PlayerReplicationInfo.Score));

  GetAxes(Rotation,X,Y,Z);

  TossVel = Vector(GetViewRotation());
  TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);

  // added owner to cash pickup, 2020 finally
  CashPickup = spawn(class'CashPickup', Self,, Location + 0.8 * CollisionRadius * X - 0.5 * CollisionRadius * Y);

  if(CashPickup != none)
  {
    CashPickup.CashAmount = Amount;
    CashPickup.bDroppedCash = true;
    CashPickup.RespawnTime = 0;   // Dropped cash doesnt respawn. For obvious reasons.
    CashPickup.Velocity = TossVel;
    CashPickup.DroppedBy = Controller;
    CashPickup.InitDroppedPickupFor(None);
    Controller.PlayerReplicationInfo.Score -= Amount;

    if ( Level.Game.NumPlayers > 1 && Level.TimeSeconds - LastDropCashMessageTime > DropCashMessageDelay )
    {
      PlayerController(Controller).Speech('AUTO', 4, "");
    }

    // Hack to get Slot machines to accept dosh that's thrown inside their collision cylinder.
    ForEach CashPickup.TouchingActors(class 'Actor', A)
    {
      if(A.IsA('KF_Slot_Machine'))
      {
        A.Touch(Cashpickup);
      }
    }
  }
}


// fix for none soundgroup calls on death
function Sound GetSound(xPawnSoundGroup.ESoundType soundType)
{
  local int SurfaceTypeID;
  local actor A;
  local vector HL,HN,Start,End;
  local material FloorMat;

  // added this in case when player joins using a custom skin with a custom SoundGroupClass,
  // which not present on the server
  if ( SoundGroupClass == none )
    SoundGroupClass = class'KFMod.KFMaleSoundGroup';

  if( soundType == EST_Land || soundType == EST_Jump )
  {
    if ( (Base!=None) && (!Base.IsA('LevelInfo')) && (Base.SurfaceType!=0) )
    {
      SurfaceTypeID = Base.SurfaceType;
    }
    else
    {
      Start = Location - Vect(0,0,1)*CollisionHeight;
      End = Start - Vect(0,0,16);
      A = Trace(hl,hn,End,Start,false,,FloorMat);
      if (FloorMat !=None)
        SurfaceTypeID = FloorMat.SurfaceType;
    }
  }

  return SoundGroupClass.static.GetSound(soundType, SurfaceTypeID);
}


function ServerBuyWeapon( Class<Weapon> WClass, float ItemWeight )
{
  local Inventory I, J;
  local float Price;
  local bool bIsDualWeapon, bHasDual9mms, bHasDualHCs, bHasDualRevolvers;

  if ( !CanBuyNow() || Class<KFWeapon>(WClass) == none || Class<KFWeaponPickup>(WClass.Default.PickupClass) == none )
  {
    return;
  }

  if ( Class<KFWeapon>(WClass).Default.AppID > 0 && Class<KFWeapon>(WClass).Default.UnlockedByAchievement != -1 )
  {
    if ( KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements) == none ||
            (!KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements).PlayerOwnsWeaponDLC(Class<KFWeapon>(WClass).Default.AppID) &&
             KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements).Achievements[Class<KFWeapon>(WClass).Default.UnlockedByAchievement].bCompleted != 1 ))
        {
            return;
        }

  }

  else if ( Class<KFWeapon>(WClass).Default.AppID > 0 )
  {
        if ( KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements) == none ||
            !KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements).PlayerOwnsWeaponDLC(Class<KFWeapon>(WClass).Default.AppID))
        {
            return;
        }
  }

  else if ( Class<KFWeapon>(WClass).Default.UnlockedByAchievement != -1  )
    {
        if ( KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements) == none ||
             KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements).Achievements[Class<KFWeapon>(WClass).Default.UnlockedByAchievement].bCompleted != 1 )
        {
            return;
        }
    }

  Price = class<KFWeaponPickup>(WClass.Default.PickupClass).Default.Cost;

  if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
  {
    Price *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), WClass.Default.PickupClass);
  }

  for ( I=Inventory; I!=None; I=I.Inventory )
  {
    if( I.Class==WClass )
    {
      Return; // Already has weapon.
    }

    if ( I.Class == class'Dualies' )
    {
            bHasDual9mms = true;
    }

    else if ( I.Class == class'DualDeagle' || I.Class == class'GoldenDualDeagle' )
    {
      bHasDualHCs = true;
    }

    else if ( I.Class == class'Dual44Magnum' )
    {
      bHasDualRevolvers = true;
    }
  }

    if ( WClass == class'DualDeagle' )
    {
        for ( J = Inventory; J != None; J = J.Inventory )
        {
            if ( J.class == class'Deagle' )
            {
                Price = Price / 2;
                break;
            }
        }

        bIsDualWeapon = true;
        bHasDualHCs = true;
    }

    if ( WClass == class'GoldenDualDeagle' )
    {
        for ( J = Inventory; J != None; J = J.Inventory )
        {
            if ( J.class == class'GoldenDeagle' )
            {
                Price = Price / 2;
                break;
            }
        }

        bIsDualWeapon = true;
        bHasDualHCs = true;
    }

    if ( WClass == class'Dual44Magnum' )
    {
        for ( J = Inventory; J != None; J = J.Inventory )
        {
            if ( J.class == class'Magnum44Pistol' )
            {
                Price = Price / 2;
                break;
            }
        }

        bIsDualWeapon = true;
        bHasDualRevolvers = true;
    }

    if ( WClass == class'DualMK23Pistol' )
    {
        for ( J = Inventory; J != None; J = J.Inventory )
        {
            if ( J.class == class'MK23Pistol' )
            {
                Price = Price / 2;
                break;
            }
        }

        bIsDualWeapon = true;
    }

    if ( WClass == class'DualFlareRevolver' )
    {
        for ( J = Inventory; J != None; J = J.Inventory )
        {
            if ( J.class == class'FlareRevolver' )
            {
                Price = Price / 2;
                break;
            }
        }

        bIsDualWeapon = true;
    }

  bIsDualWeapon = bIsDualWeapon || WClass == class'Dualies';

  if ( !CanCarry(ItemWeight) )
  {
    Return;
  }

  if ( PlayerReplicationInfo.Score < Price )
  {
    Return; // Not enough CASH.
  }

  I = Spawn(WClass);

  if ( I != none )
  {
    if ( KFGameType(Level.Game) != none )
    {
      KFGameType(Level.Game).WeaponSpawned(I);
    }

    KFWeapon(I).UpdateMagCapacity(PlayerReplicationInfo);
    KFWeapon(I).FillToInitialAmmo();
    KFWeapon(I).SellValue = Price * 0.75;
    I.GiveTo(self);
    PlayerReplicationInfo.Score -= Price;

    if ( bIsDualWeapon )
    {
      KFSteamStatsAndAchievements(PlayerReplicationInfo.SteamStatsAndAchievements).OnDualsAddedToInventory(bHasDual9mms, bHasDualHCs, bHasDualRevolvers);
    }

    ClientForceChangeWeapon(I);
  }

  SetTraderUpdate();
}