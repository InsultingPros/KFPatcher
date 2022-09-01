class repl_KFWeaponPickup extends KFWeaponPickup;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFWeaponPickup.uc#L412
// fix accessed none Inventory for destroyed weapon pickups
function Destroyed()
{
    if (bDropped && Inventory != none && KFGameType(Level.Game) != none)
        KFGameType(Level.Game).WeaponDestroyed(class<Weapon>(Inventory.class));

    super(WeaponPickup).Destroyed();
}