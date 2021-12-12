class repl_KFWeaponPickup extends KFWeaponPickup;


// fix accessed none Inventory for destroyed weapon pickups
function Destroyed()
{
  if (bDropped && Inventory != none && KFGameType(Level.Game) != none)
    KFGameType(Level.Game).WeaponDestroyed(class<Weapon>(Inventory.class));

  super(WeaponPickup).Destroyed();
}