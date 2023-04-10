/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookKFWeaponPickup extends KFWeaponPickup;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFWeaponPickup.uc#L412
// fix accessed none Inventory for destroyed weapon pickups
function Destroyed()
{
    if (bDropped && Inventory != none && KFGameType(Level.Game) != none)
        KFGameType(Level.Game).WeaponDestroyed(class<Weapon>(Inventory.class));

    super(WeaponPickup).Destroyed();
}