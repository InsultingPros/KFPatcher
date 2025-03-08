/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookPawn extends KFHumanPawn_Story;


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

// https://github.com/InsultingPros/KillingFloor/blob/main/XGame/Classes/xPawn.uc#L1857
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
    SetWeaponOverlay(none, 0.f, true);

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

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPawn.uc#L2964
// toss some of your cash away. (to help a cash-strapped ally or perhaps just to party like its 1994)
exec function TossCash(int Amount)
{
  local Vector X,Y,Z;
  local CashPickup CashPickup;
  local Vector TossVel;
  local Actor A;

  // NEW check! use delay between throws
  if (Level.TimeSeconds < class'hookPawn'.default.cashtimer || PlayerReplicationInfo == none)
    return;
  class'hookPawn'.default.cashtimer = Level.TimeSeconds + class'Settings'.default.fDoshThrowDelay;

  // min dosh amount to throw
  Amount = clamp(Amount, class'Settings'.default.iDoshThrowMinAmount, int(Controller.PlayerReplicationInfo.Score));
  // if (Amount<=0)
  //   Amount = 50;

  Controller.PlayerReplicationInfo.Score = int(Controller.PlayerReplicationInfo.Score); // To fix issue with throwing 0 pounds.
  if (Controller.PlayerReplicationInfo.Score<=0 || Amount<=0)
    return;
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
    CashPickup.InitDroppedPickupFor(none);
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

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPawn.uc#L3985
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
    if ( (Base!=none) && (!Base.IsA('LevelInfo')) && (Base.SurfaceType!=0) )
    {
      SurfaceTypeID = Base.SurfaceType;
    }
    else
    {
      Start = Location - Vect(0,0,1)*CollisionHeight;
      End = Start - Vect(0,0,16);
      A = Trace(hl,hn,End,Start,false,,FloorMat);
      if (FloorMat !=none)
        SurfaceTypeID = FloorMat.SurfaceType;
    }
  }

  return SoundGroupClass.static.GetSound(soundType, SurfaceTypeID);
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPawn.uc#L3087
// allows us to buy from trader menu from anywhere
function bool CanBuyNow()
{
  local ShopVolume Sh;

  if (class'Settings'.default.bBuyEverywhere)
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

// EXPERIMENTAL
// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPawn.uc#L3159
function ServerBuyWeapon( class<Weapon> WClass, float ItemWeight )
{
  local Inventory I, J;
  local float Price;

  if ( !CanBuyNow() || class<KFWeapon>(WClass) == none || class<KFWeaponPickup>(WClass.default.PickupClass) == none || class'hookPawn'.static.HasWeaponClass(WClass) )
  {
    return;
  }

  Price = class<KFWeaponPickup>(WClass.default.PickupClass).default.Cost;

  if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
    Price *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), WClass.default.PickupClass);

  // N.B. addition !
  // ItemWeight = class<KFWeapon>(WClass).default.Weight;

  if ( class'hookPawn'.static.IsDualWeapon(WClass,SecType) )
  {
    if ( WClass != class'Dualies' && class'hookPawn'.static.HasWeaponClass(class'hookPawn'.default.SecType, J) )
    {
      // ItemWeight -= class'hookPawn'.default.SecType.default.Weight;
      Price *= 0.5f;
      class'hookPawn'.default.OtherPrice = KFWeapon(J).SellValue;
      if ( class'hookPawn'.default.OtherPrice == -1 )
      {
        class'hookPawn'.default.OtherPrice = class<KFWeaponPickup>(class'hookPawn'.default.SecType.default.PickupClass).default.Cost * 0.75;
        if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
          class'hookPawn'.default.OtherPrice *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), SecType.default.PickupClass);
      }
    }
  }
  else if ( class'hookPawn'.static.HasDualies(WClass,Inventory) )
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
    if (class'hookPawn'.default.OtherPrice > 0)
      KFWeapon(I).SellValue += class'hookPawn'.default.OtherPrice;

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

  for ( I=default.Inventory; I!=none; I=I.default.Inventory )
  {
    if( I.class == IC )
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

  if (W.default.DemoReplacement != none)
  {
    SingleType = class<KFWeapon>(W.default.DemoReplacement);
    return true;
  }

  for( i=(default.DualMap.Length-1); i>=0; --i )
  {
    if( W==default.DualMap[i].Dual )
    {
      SingleType = default.DualMap[i].Single;
      return true;
    }
  }

  return false;
}


static final function bool HasDualies( class<Weapon> W, Inventory InvList, optional out class<KFWeapon> DualType )
{
  local int i;
  local Inventory In;

  for ( In=InvList; In!=none; In=In.Inventory )
  {
    if( Weapon(In)!=none && Weapon(In).DemoReplacement==W )
    {
      DualType = class<KFWeapon>(In.class);
      return true;
    }
  }

  for ( i=(default.DualMap.Length-1); i>=0; --i )
  {
    if ( W == default.DualMap[i].Single )
    {
      DualType = default.DualMap[i].Dual;
      W = default.DualMap[i].Dual;
      for ( In=InvList; In!=none; In=In.Inventory )
      {
        if (In.class == W)
          return true;
      }
      return false;
    }
  }

  return false;
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFHumanPawn.uc#L840
// remove perk specific weapons
function AddDefaultInventory()
{
  CreateInventory("KFMod.Knife");
  CreateInventory("KFMod.Single");
  CreateInventory("KFMod.Frag");
  CreateInventory("KFMod.Syringe");
  CreateInventory("KFMod.Welder");
}


defaultproperties
{
  DualMap[0]=(Single=class'Single',Dual=class'Dualies')
  DualMap[1]=(Single=class'Magnum44Pistol',Dual=class'Dual44Magnum')
  DualMap[2]=(Single=class'Deagle',Dual=class'DualDeagle')
  DualMap[3]=(Single=class'FlareRevolver',Dual=class'DualFlareRevolver')
  DualMap[4]=(Single=class'MK23Pistol',Dual=class'DualMK23Pistol')
}