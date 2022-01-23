class repl_DualPistol extends DualDeagle
  CacheExempt;  // do NOT include me in UCL and do NOT be discoverable in menus


var KFWeaponPickup WPickup;
var KFWeapon SingleKFW;
var class<KFWeapon> SingleClass;


function DropFrom(vector StartLocation)
{
  local int m;
  local Pickup Pickup;
  // local Inventory I;
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

  if (Instigator != none)
    DetachFromPawn(Instigator);

  if (Instigator.Health > 0)
  {
    OtherAmmo = AmmoThrown / 2;
    AmmoThrown -= OtherAmmo;
    // CHANGED HERE
    class'repl_DualPistol'.default.SingleKFW = Instigator.spawn(class'repl_DualPistol'.static.GetSingleWC(self));
    if (class'repl_DualPistol'.default.SingleKFW != none)
    {
      class'repl_DualPistol'.default.SingleKFW.GiveTo(Instigator);
      class'repl_DualPistol'.default.SingleKFW.Ammo[0].AmmoAmount = OtherAmmo;
      // cursed TWI does this check only for left ammo
      MagAmmoRemaining = max(MagAmmoRemaining / 2, 0);
      class'repl_DualPistol'.default.SingleKFW.MagAmmoRemaining = MagAmmoRemaining;
    }
    else
      log("ALERT!!!!! WEAPON NOT SPAWNED FOR PAWN!!!");
    // I = spawn(class'repl_DualPistol'.static.GetSingleWC(self));
    // if (I == none)
    //   log("ALERT!! NO INVENTORY!!!");
    // I.GiveTo(Instigator);
    // if (Weapon(I) == none)
    //   log("ALERT!! NO Weapon(I)!!!");
    // Weapon(I).Ammo[0].AmmoAmount = OtherAmmo;
    // CHANGED HERE
    // OLD: Deagle(I).MagAmmoRemaining = MagAmmoRemaining / 2;
    // if (KFWeapon(I) == none)
    //   log("ALERT!! NO KFWeapon(I)!!!");
    // KFWeapon(I).MagAmmoRemaining = MagAmmoRemaining / 2;
    // CHANGED HERE
    // OLD: MagAmmoRemaining = Max(MagAmmoRemaining - Deagle(I).MagAmmoRemaining, 0);
    // MagAmmoRemaining = Max(MagAmmoRemaining - KFWeapon(I).MagAmmoRemaining, 0);
  }

  // CHANGE HERE
  // OLD: Pickup = spawn(class'DeaglePickup',,, StartLocation);
  Pickup = spawn(class'repl_DualPistol'.default.SingleKFW.default.PickupClass,,, StartLocation);

  if (Pickup != none)
  {
    Pickup.InitDroppedPickupFor(self);
    Pickup.Velocity = Velocity;
    WeaponPickup(Pickup).AmmoAmount[0] = AmmoThrown;
    if (KFWeaponPickup(Pickup) != none)
      KFWeaponPickup(Pickup).MagAmmoRemaining = MagAmmoRemaining;
    if (Instigator.Health > 0)
      WeaponPickup(Pickup).bThrown = true;
  }

  class'repl_DualPistol'.default.SingleKFW = none;
  // class'repl_DualPistol'.default.SingleKFW.Destroy();
  Destroyed();
  Destroy();
}


// static final function class<KFWeapon> GetSingleWC(KFWeapon KFWeapon)
// {
//   if (KFWeapon == none)
//   {
//     log("Something is VERY WRONG, couldn't find single weapon class for pistol " $ KFWeapon);
//     // drop beretas as a fail safe
//     return class'Single';
//   }

//   switch (KFWeapon.class.name)
//   {
//     case 'Dualies':
//       return class'Single';
//     case 'DualDeagle':
//       return class'Deagle';
//     case 'GoldenDualDeagle':
//       return class'GoldenDeagle';
//     case 'Dual44Magnum':
//       return class'Magnum44Pistol';
//     case 'DualMK23Pistol':
//       return class'MK23Pistol';
//     case 'DualFlareRevolver':
//       return class'FlareRevolver';
//   }
// }

static final function class<KFWeapon> GetSingleWC(KFWeapon KFWeapon)
{
  if (KFWeapon == none)
  {
    log("Something is VERY WRONG, couldn't find single weapon class for pistol " $ KFWeapon);
    // drop beretas as a fail safe
    return class'Single';
  }

  switch (KFWeapon.class.name)
  {
    case 'Dualies':
      return class'Single';
    case 'DualDeagle':
      return class'Deagle';
    case 'GoldenDualDeagle':
      return class'GoldenDeagle';
    case 'Dual44Magnum':
      return class'Magnum44Pistol';
    case 'DualMK23Pistol':
      return class'MK23Pistol';
    case 'DualFlareRevolver':
      return class'FlareRevolver';
  }
}


// allow variants of weapons to be picked up
function bool HandlePickupQuery(pickup Item)
{
  return super(Weapon).HandlePickupQuery(Item);
}


defaultproperties{}