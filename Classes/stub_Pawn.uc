class stub_Pawn extends KFHumanPawn_Story;


struct FDualList
{
	var class<KFWeapon> Single,Dual;
};
var array<FDualList> DualMap;

var int OtherPrice;
var class<KFWeapon> SecType;

var transient float cashtimer;
var transient byte CashCount;


//=============================================================================
//                             weapon == none fix
//=============================================================================

function ServerChangedWeapon(Weapon OldWeapon, Weapon NewWeapon)
{
	local float InvisTime;

	if (bInvis)
	{
	  if ( (OldWeapon != none) && (OldWeapon.OverlayMaterial == InvisMaterial) )
		  InvisTime = OldWeapon.ClientOverlayCounter;
	  else
		  InvisTime = 20000;
	}
  if (HasUDamage() || bInvis)
    SetWeaponOverlay(None, 0.f, true);

  super(Pawn).ServerChangedWeapon(OldWeapon, NewWeapon);

  if (bInvis)
    SetWeaponOverlay(InvisMaterial, InvisTime, true);
  else if (HasUDamage())
    SetWeaponOverlay(UDamageWeaponMaterial, UDamageTime - Level.TimeSeconds, false);

  // the fix
  if (weapon == none)
    return;

  if (bBerserk)
    Weapon.StartBerserk();
  else if ( Weapon.bBerserk )
		Weapon.StopBerserk();
}


//=============================================================================
//                             Dosh shit
//=============================================================================

// toss some of your cash away. (to help a cash-strapped ally or perhaps just to party like its 1994)
exec function TossCash(int Amount)
{
  local Vector X,Y,Z;
  local CashPickup CashPickup;
  local Vector TossVel;
  local Actor A;

  // NEW check!
  if (PlayerReplicationInfo == none)
    return;
  // why it is defined as float in a first place?
  PlayerReplicationInfo.Score = int(PlayerReplicationInfo.Score);
  if (PlayerReplicationInfo.Score <= 0) // Controller.
    return;

  // 0.3 sec delay between throws
  if (Level.TimeSeconds < class'stub_Pawn'.default.cashtimer)
    return;
  class'stub_Pawn'.default.cashtimer = Level.TimeSeconds + 0.3f;

  
  // set minimal throw cash = 30
  if (Amount < 30)
    Amount = clamp(Amount, 30, int(Controller.PlayerReplicationInfo.Score));

  // and check if we have THAT much dosh to throw or not
  Amount = Min(Amount, int(Controller.PlayerReplicationInfo.Score));

  GetAxes(Rotation,X,Y,Z);

  TossVel = Vector(GetViewRotation());
  TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);

  // added owner to cash pickup, 2020 finally
  CashPickup = spawn(class'CashPickup', self,, Location + 0.8 * CollisionRadius * X - 0.5 * CollisionRadius * Y);

  if (CashPickup != none)
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
    foreach CashPickup.TouchingActors(class 'Actor', A)
    {
      if(A.IsA('KF_Slot_Machine'))
      {
        A.Touch(Cashpickup);
      }
    }
  }
}


//=============================================================================
//                             Sound none on player death
//=============================================================================

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


// allows us to buy from trader menu from anywhere
function bool CanBuyNow()
{
  local ShopVolume Sh;

  if (class'o_Settings'.default.bBuyEverywhere)
    return true;

  if (KFGameType(Level.Game) == none || KFGameType(Level.Game).bWaveInProgress || PlayerReplicationInfo == none)
    return false;
  foreach TouchingActors(class'ShopVolume', Sh)
    return true;
  return false;
}

//=============================================================================
//                             Dualies Print Fix
//=============================================================================

function ServerBuyWeapon( class<Weapon> WClass, float ItemWeight )
{
  local Inventory I, J;
  local float Price;

  if ( !CanBuyNow() || class<KFWeapon>(WClass) == none || class<KFWeaponPickup>(WClass.Default.PickupClass) == none || class'stub_Pawn'.static.HasWeaponClass(WClass) )
  {
    return;
  }

  Price = class<KFWeaponPickup>(WClass.default.PickupClass).default.Cost;

  if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
    Price *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), WClass.Default.PickupClass);

  // N.B. addition !
  // ItemWeight = class<KFWeapon>(WClass).default.Weight;

  if ( class'stub_Pawn'.static.IsDualWeapon(WClass,SecType) )
	{
		if ( WClass != class'Dualies' && class'stub_Pawn'.static.HasWeaponClass(class'stub_Pawn'.default.SecType, J) )
		{
			// ItemWeight -= class'stub_Pawn'.default.SecType.default.Weight;
			Price *= 0.5f;
			class'stub_Pawn'.default.OtherPrice = KFWeapon(J).SellValue;
			if ( class'stub_Pawn'.default.OtherPrice == -1 )
			{
				class'stub_Pawn'.default.OtherPrice = class<KFWeaponPickup>(class'stub_Pawn'.default.SecType.Default.PickupClass).Default.Cost * 0.75;
				if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
					class'stub_Pawn'.default.OtherPrice *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), SecType.Default.PickupClass);
			}
		}
	}
	else if ( class'stub_Pawn'.static.HasDualies(WClass,Inventory) )
		return;

  // add
  Price = int(Price); // Truncuate price.

  if ( !CanCarry(ItemWeight) )
  {
    return;
  }

  if ( PlayerReplicationInfo.Score < Price )
  {
    ClientMessage("Error: "$WClass.Name$" is too expensive ("$int(Price)$">"$int(PlayerReplicationInfo.Score)$")");
    return; // Not enough CASH.
  }

  I = Spawn(WClass);

  if ( I != none )
  {
    if ( KFGameType(Level.Game) != none )
      KFGameType(Level.Game).WeaponSpawned(I);

    KFWeapon(I).UpdateMagCapacity(PlayerReplicationInfo);
    KFWeapon(I).FillToInitialAmmo();
    KFWeapon(I).SellValue = Price * 0.75;
    if (class'stub_Pawn'.default.OtherPrice > 0)
			KFWeapon(I).SellValue += class'stub_Pawn'.default.OtherPrice;

    I.GiveTo(self);
    PlayerReplicationInfo.Score -= Price;
    ClientForceChangeWeapon(I);
  }
  else
    ClientMessage("Error: "$WClass.Name$" failed to spawn.");

  SetTraderUpdate();
}


static final function bool HasWeaponClass( class<Inventory> IC, optional out Inventory Res )
{
	local Inventory I;
	
	for ( I=default.Inventory; I!=None; I=I.default.Inventory )
  {
    if( I.Class == IC )
		{
			Res = I;
			return true;
		}
  }

	return false;
}


static final function bool IsDualWeapon(class<Weapon> W, optional out class<KFWeapon> SingleType )
{
	local int i;
	
	if (W.Default.DemoReplacement != none)
	{
		SingleType = class<KFWeapon>(W.Default.DemoReplacement);
		return true;
	}

	for( i=(Default.DualMap.Length-1); i>=0; --i )
  {
    if( W==Default.DualMap[i].Dual )
		{
			SingleType = Default.DualMap[i].Single;
			return true;
		}
  }

	return false;
}


static final function bool HasDualies( class<Weapon> W, Inventory InvList, optional out class<KFWeapon> DualType )
{
	local int i;
	local Inventory In;
	
	for ( In=InvList; In!=None; In=In.Inventory )
  {
    if( Weapon(In)!=None && Weapon(In).DemoReplacement==W )
		{
			DualType = class<KFWeapon>(In.Class);
			return true;
		}
  }

	for ( i=(Default.DualMap.Length-1); i>=0; --i )
  {
    if ( W == Default.DualMap[i].Single )
		{
			DualType = Default.DualMap[i].Dual;
			W = Default.DualMap[i].Dual;
			for ( In=InvList; In!=None; In=In.Inventory )
      {
        if (In.Class == W)
					return true;
      }
			return false;
		}
  }

	return false;
}


defaultproperties
{
  DualMap[0]=(Single=class'Single',Dual=class'Dualies')
	DualMap[1]=(Single=class'Magnum44Pistol',Dual=class'Dual44Magnum')
	DualMap[2]=(Single=class'Deagle',Dual=class'DualDeagle')
	DualMap[3]=(Single=class'FlareRevolver',Dual=class'DualFlareRevolver')
	DualMap[4]=(Single=class'MK23Pistol',Dual=class'DualMK23Pistol')
}