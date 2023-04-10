/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookP_Shotgun extends ShotgunBullet;


var Pawn Victim;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/ShotgunBullet.uc#L109
simulated function ProcessTouch(Actor Other, vector HitLocation)
{
  local vector X;
  local Vector TempHitLocation, HitNormal;
  local array<int>  HitPoints;
  local KFPawn HitPawn;


  if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces  )
    return;

  X = Vector(Rotation);

   if ( Instigator != none && ROBulletWhipAttachment(Other) != none )
  {
    // we touched player's auxilary collision cylinder, not let's trace to the player himself
    // Other.Base = KFPawn
    if( Other.Base == none || Other.Base.bDeleteMe )
      return;

    Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);

    // bullet didn't hit a pawn
    if( Other == none || HitPoints.Length == 0 || Other.bDeleteMe)
      return;

    HitPawn = KFPawn(Other);
    if ( HitPawn != none )
    {
      class'hookP_Shotgun'.default.Victim = HitPawn;
      // fixed point blank penetration -> X vector
      HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * X, MyDamageType,HitPoints);
    }
  }

  else
  {
    if ( Pawn(Other) != none )
      class'hookP_Shotgun'.default.Victim = Pawn(Other);

    // fixed point blank penetration -> X vector \
    if ( class'hookP_Shotgun'.default.Victim != none && Victim.IsHeadShot(HitLocation, X, 1.0))
      class'hookP_Shotgun'.default.Victim.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
    else
      Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
  }

  if ( Instigator != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
  {
     PenDamageReduction = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.GetShotgunPenetrationDamageMulti(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo),default.PenDamageReduction);
  }
  else
  {
     PenDamageReduction = default.PenDamageReduction;
  }

  // dead bodies reduce damage less
  if ( class'hookP_Shotgun'.default.Victim != none && class'hookP_Shotgun'.default.Victim.Health <= 0 )
  {
    PenDamageReduction += (1.0 - PenDamageReduction) * 0.5;
  }

  Damage *= PenDamageReduction; // Keep going, but lose effectiveness each time.

  // 10 is for tests, may be changed
  if ( Damage < 10 )
    Destroy();
}