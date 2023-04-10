/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookZ_FP extends ZombieFleshpound;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFChar/Classes/ZombieFleshPound.uc#L105
// all this copy-paste just to fix his one hit kill ability
// ZombieFleshpound.TakeDamage
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    local int BlockSlip, OldHealth;
    local float BlockChance;//, RageChance;
    local Vector X,Y,Z, Dir;
    local bool bIsHeadShot;
    local float HeadShotCheckScale;

    GetAxes(Rotation, X,Y,Z);

    if (LastDamagedTime<Level.TimeSeconds)
        TwoSecondDamageTotal = 0;
    LastDamagedTime = Level.TimeSeconds+2;
    OldHealth = Health; // Corrected issue where only the Base Health is counted toward the FP's Rage in Balance Round 6(second attempt)

    HeadShotCheckScale = 1.0;

    // Do larger headshot checks if it is a melee attach
    if (class<DamTypeMelee>(damageType) != none)
    {
        HeadShotCheckScale *= 1.25;
    }

    bIsHeadShot = IsHeadShot(Hitlocation, normal(Momentum), 1.0);

    // He takes less damage to small arms fire (non explosives)
    // Frags and LAW rockets will bring him down way faster than bullets and shells.
    if ( DamageType != class 'DamTypeFrag' && DamageType != class 'DamTypeLaw' && DamageType != class 'DamTypePipeBomb'
        && DamageType != class 'DamTypeM79Grenade' && DamageType != class 'DamTypeM32Grenade'
        && DamageType != class 'DamTypeM203Grenade' && DamageType != class 'DamTypeMedicNade'
        && DamageType != class 'DamTypeSPGrenade' && DamageType != class 'DamTypeSealSquealExplosion'
        && DamageType != class 'DamTypeSeekerSixRocket' )
    {
        // Don't reduce the damage so much if its a high headshot damage weapon
        if (bIsHeadShot && class<KFWeaponDamageType>(damageType)!=none &&
            class<KFWeaponDamageType>(damageType).default.HeadShotDamageMult >= 1.5)
        {
            Damage *= 0.75;
        }
        else if (Level.Game.GameDifficulty >= 5.0 && bIsHeadshot && (class<DamTypeCrossbow>(damageType) != none || class<DamTypeCrossbowHeadShot>(damageType) != none))
        {
            Damage *= 0.35; // was 0.3 in Balance Round 1, then 0.4 in Round 2, then 0.3 in Round 3/4, and 0.35 in Round 5
        }
        else
        {
            Damage *= 0.5;
        }
    }
    // double damage from handheld explosives or poison
    else if (DamageType == class 'DamTypeFrag' || DamageType == class 'DamTypePipeBomb' || DamageType == class 'DamTypeMedicNade' )
    {
        Damage *= 2.0;
    }
    // A little extra damage from the grenade launchers, they are HE not shrapnel,
    // and its shrapnel that REALLY hurts the FP ;)
    else if( DamageType == class 'DamTypeM79Grenade' || DamageType == class 'DamTypeM32Grenade'
         || DamageType == class 'DamTypeM203Grenade' || DamageType == class 'DamTypeSPGrenade'
         || DamageType == class 'DamTypeSealSquealExplosion' || DamageType == class 'DamTypeSeekerSixRocket')
    {
        Damage *= 1.25;
    }

    // Shut off his "Device" when dead
    if (Damage >= Health)
        PostNetReceive();

    // Damage Berserk responses...
    // Start a charge.
    // The Lower his health, the less damage needed to trigger this response.
    //RageChance = (( HealthMax / Health * 300) - TwoSecondDamageTotal );

    // Calculate whether the shot was coming from in front.
    Dir = -Normal(Location - hitlocation);
    BlockSlip = rand(5);

    if (AnimAction == 'PoundBlock')
        Damage *= BlockDamageReduction;

    if (Dir Dot X > 0.7 || Dir == vect(0,0,0))
        BlockChance = (Health / HealthMax * 100 ) - Damage * 0.25;


    // We are healthy enough to block the attack, and we succeeded the blockslip.
    // only 40% damage is done in this circumstance.
    // bring this back?

    // Log (Damage);

    if (damageType == class 'DamTypeVomit')
    {
        Damage = 0; // nulled
    }
    else if( damageType == class 'DamTypeBlowerThrower' )
    {
       // Reduced damage from the blower thrower bile, but lets not zero it out entirely
       Damage *= 0.25;
    }

    Super(KFMonster).takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType,HitIndex) ;

    TwoSecondDamageTotal += OldHealth - Health; // Corrected issue where only the Base Health is counted toward the FP's Rage in Balance Round 6(second attempt)

    // ADDITION!!! to disallow his one hit kill ability
    if (!bDecapitated && TwoSecondDamageTotal > RageDamageThreshold && !bChargingPlayer && !bShotAnim &&
        !bZapped && (!(bCrispified && bBurnified) || bFrustrated) )
        StartCharging();
}