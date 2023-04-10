/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookFragFire extends FragFire;


var transient float PrevAmmo;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/FragFire.uc#L123
function DoFireEffect()
{
    local float MaxAmmo, CurAmmo;
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator Aim;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local int Hand;

    // added working ammo check
    Weapon.GetAmmoCount(MaxAmmo, CurAmmo);
    if (CurAmmo == 0 && class'hookFragFire'.default.PrevAmmo == 0)
        return;
    class'hookFragFire'.default.PrevAmmo = CurAmmo;

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
    StartProj = StartTrace + X*ProjSpawnOffset.X;

    if (PlayerController(Instigator.Controller) != none)
    { // We must do this as server dosen't get a chance to set weapon handedness.
        Hand = int(PlayerController(Instigator.Controller).Handedness);
        if (Hand == -1 || Hand == 1)
            StartProj = StartProj + Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;
    }

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    if (Other != none)
        StartProj = HitLocation;

    Aim = AdjustAim(StartProj, AimError);

    SpawnProjectile(StartProj, Aim);
}