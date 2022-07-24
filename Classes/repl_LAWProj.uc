class repl_LAWProj extends LAWProj;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/LAWProj.uc#L218
// removed SirenScream damage type check since 90% of the time they don't disentigrate anyway...
// also prevents detonation from fire or other explosives
function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
  if(!bDud
  && DamageType != class'DamTypeFlamethrower'
  && DamageType != class'DamTypeFrag'
  && DamageType != class'DamTypeLaw'
  && DamageType != class'DamTypeM203Grenade'
  && DamageType != class'DamTypeM32Grenade'
  && DamageType != class'DamTypeM79Grenade'
  && DamageType != class'DamTypePipeBomb'
  && DamageType != class'DamTypeSealSquealExplosion'
  && DamageType != class'DamTypeSeekerSixRocket'
  && DamageType != class'DamTypeSPGrenade'
  && DamageType != class'SirenScreamDamage'
  && !ClassIsChildOf(damageType, class'DamTypeBurned'))
  {
    Explode(HitLocation, vect(0,0,0));
  }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/LAWProj.uc#L392
// RepInfo == none fix
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
  // Don't let it hit this player, or blow up on another player
  // added bBlockHitPointTraces check
  if (Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces)
    return;

  // Don't collide with bullet whip attachments
  if (KFBulletWhipAttachment(Other) != none)
    return;

  // Don't allow hits on poeple on the same team
  // fixing RepInfo == none error, and using KFPawn instead of KFHumanPawn
  if (KFPawn(Other) != none && Instigator != none && KFPawn(Other).GetTeamNum() == Instigator.GetTeamNum())
    return;

  // Use the instigator's location if it exists. This fixes issues with
  // the original location of the projectile being really far away from
  // the real Origloc due to it taking a couple of milliseconds to
  // replicate the location to the client and the first replicated location has
  // already moved quite a bit.
  if (Instigator != none)
    OrigLoc = Instigator.Location;

  if (!bDud && ((VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0)))
  {
    if( Role == ROLE_Authority )
    {
      AmbientSound = none;
      PlaySound(sound'ProjectileSounds.PTRD_deflect04',,2.0);
      Other.TakeDamage(ImpactDamage, Instigator, HitLocation, Normal(Velocity), ImpactDamageType);
    }

    bDud = true;
    Velocity = vect(0,0,0);
    LifeSpan = 1.0;
    SetPhysics(PHYS_Falling);
  }

  if (!bDud)
    Explode(HitLocation,Normal(HitLocation-Other.Location));
}


defaultproperties{}