class stubDualPistol extends DualDeagle;


var KFWeaponPickup WPickup;
var KFWeapon SingleKFW;
var class<KFWeapon> SingleClass;


function DropFrom(vector StartLocation)
{
  local int m;
  local Pickup Pickup;
  local Inventory I;
  local int AmmoThrown, OtherAmmo;

  if (!bCanThrow)
    return;

  AmmoThrown = AmmoAmount(0);
  ClientWeaponThrown();

  for (m = 0; m < NUM_FIRE_MODES; m++)
  {
    if (FireMode[m].bIsFiring)
      StopFire(m);
  }

  if ( Instigator != None )
    DetachFromPawn(Instigator);

  // TEST !
  class'stubDualPistol'.static.GetSingleWeaponClass(self);

  if( Instigator.Health > 0 )
  {
    OtherAmmo = AmmoThrown / 2;
    AmmoThrown -= OtherAmmo;
    I = Spawn(Class'Deagle');
    I.GiveTo(Instigator);
    Weapon(I).Ammo[0].AmmoAmount = OtherAmmo;
    Deagle(I).MagAmmoRemaining = MagAmmoRemaining / 2;
    MagAmmoRemaining = Max(MagAmmoRemaining-Deagle(I).MagAmmoRemaining,0);
  }

  // Pickup = Spawn(Class'DeaglePickup',,, StartLocation);
  Pickup = KFWeaponPickup(spawn(class'stubDualPistol'.default.SingleClass.default.PickupClass,,, StartLocation));

  if ( Pickup != None )
  {
    Pickup.InitDroppedPickupFor(self);
    Pickup.Velocity = Velocity;
    WeaponPickup(Pickup).AmmoAmount[0] = AmmoThrown;
    if( KFWeaponPickup(Pickup)!=None )
      KFWeaponPickup(Pickup).MagAmmoRemaining = MagAmmoRemaining;
    if (Instigator.Health > 0)
      WeaponPickup(Pickup).bThrown = true;
  }

  Destroyed();
  Destroy();
}

// Pickup = KFWeaponPickup(Spawn(class<KFWeapon>(DemoReplacement).default.PickupClass,,, StartLocation));

static final function GetSingleWeaponClass(KFWeapon KFWeapon)
{
  switch (KFWeapon.class.name)
  {
    case 'DualDeagle':
      class'stubDualPistol'.default.SingleClass = class'Deagle';
      break;
    case 'GoldenDualDeagle':
      class'stubDualPistol'.default.SingleClass = class'GoldenDeagle';
      break;
    case 'Dual44Magnum':
      class'stubDualPistol'.default.SingleClass = class'Magnum44Pistol';
      break;
    case 'DualMK23Pistol':
      class'stubDualPistol'.default.SingleClass = class'MK23Pistol';
      break;
  }  
}


defaultproperties{}