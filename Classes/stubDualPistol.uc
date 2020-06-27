class stubDualPistol extends DualDeagle;


function DropFrom(vector StartLocation)
{
  local int m;
  local KFWeaponPickup Pickup;
  local int AmmoThrown, OtherAmmo;
  local KFWeapon SinglePistol;

  if ( !bCanThrow )
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

  if( Instigator.Health > 0 )
  {
    OtherAmmo = AmmoThrown / 2;
    AmmoThrown -= OtherAmmo;
    SinglePistol = KFWeapon(Spawn(DemoReplacement));
    SinglePistol.SellValue = SellValue / 2;
    SinglePistol.GiveTo(Instigator);
    SinglePistol.Ammo[0].AmmoAmount = OtherAmmo;
    SinglePistol.MagAmmoRemaining = MagAmmoRemaining / 2;
    MagAmmoRemaining = Max(MagAmmoRemaining-SinglePistol.MagAmmoRemaining,0);

    Pickup = KFWeaponPickup(Spawn(SinglePistol.PickupClass,,, StartLocation));
  }
  else
    Pickup = KFWeaponPickup(Spawn(class<KFWeapon>(DemoReplacement).default.PickupClass,,, StartLocation));

  if ( Pickup != None )
  {
    Pickup.InitDroppedPickupFor(self);
    Pickup.DroppedBy = PlayerController(Instigator.Controller);
    Pickup.Velocity = Velocity;
    // fixing dropping exploit
    Pickup.SellValue = SellValue / 2;
    Pickup.Cost = Pickup.SellValue / 0.75;
    Pickup.AmmoAmount[0] = AmmoThrown;
    Pickup.MagAmmoRemaining = MagAmmoRemaining;
    if (Instigator.Health > 0)
      Pickup.bThrown = true;
  }

  Destroyed();
  Destroy();
}


defaultproperties
{

}