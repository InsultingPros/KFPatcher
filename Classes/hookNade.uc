/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookNade extends Nade;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/Nade.uc#L48
// EXPERIMENTAL!! NOT IN A USE!!!
// fixes nade crashes, but obviously we can't use this :yoba:
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex){}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/Nade.uc#L79
// fix sound ref none log spam
simulated function Explode(vector HitLocation, vector HitNormal)
{
    local PlayerController LocalPlayer;
    local Projectile P;
    local byte i;

    bHasExploded = true;
    BlowUp(HitLocation);

    // null reference fix
    if (ExplodeSounds.length > 0)
        PlaySound(ExplodeSounds[rand(ExplodeSounds.length)],,2.0);

    // Shrapnel
    for (i = Rand(6); i < 10; i++)
    {
        P = Spawn(ShrapnelClass,,,,RotRand(true));
        if (P != none)
            P.RemoteRole = ROLE_None;
    }

    if (EffectIsRelevant(Location, false))
    {
        Spawn(class'KFmod.KFNadeExplosion',,, HitLocation, rotator(vect(0,0,1)));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != none) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    Destroy();
}


defaultproperties{}