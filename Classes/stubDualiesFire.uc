class stubDualiesFire extends DualiesFire;


var int penValue;


function DoTrace(Vector Start, Rotator Dir)
{
  local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
  local Actor Other;
  local byte HitCount,HCounter;
  local float HitDamage;
  local array<int>	HitPoints;
  local KFPawn HitPawn;
  local array<Actor>	IgnoreActors;
  local Actor DamageActor;
  local int i;

  MaxRange();

  Weapon.GetViewAxes(X, Y, Z);
  if ( Weapon.WeaponCentered() )
  {
    ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
  }
  else
  {
    ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
    Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);
  }

  X = Vector(Dir);
  End = Start + TraceRange * X;
  HitDamage = DamageMax;

  // MK23Fire, DualMK23Fire = 3
  // DeagleFire, DualDeagleFire, Magnum44Fire, Dual44MagnumFire = 10
  if (self.class.name == 'MK23Fire' || self.class.name == 'DualMK23Fire')
    default.penValue = 3;
  else
    default.penValue = 10;

  while( (HitCount++) < default.penValue ) // there was fixed value here per parent class
  {
    DamageActor = none;

    Other = Instigator.HitPointTrace(HitLocation, HitNormal, End, HitPoints, Start,, 1);
    if( Other==None )
    {
      break;
    }
    else if( Other==Instigator || Other.Base == Instigator )
    {
      IgnoreActors[IgnoreActors.Length] = Other;
      Other.SetCollision(false);
      Start = HitLocation;
      continue;
    }

    if( ExtendedZCollision(Other)!=None && Other.Owner!=None )
    {
      IgnoreActors[IgnoreActors.Length] = Other;
      IgnoreActors[IgnoreActors.Length] = Other.Owner;
      Other.SetCollision(false);
      Other.Owner.SetCollision(false);
      DamageActor = Pawn(Other.Owner);
    }

    if ( !Other.bWorldGeometry && Other!=Level )
    {
      HitPawn = KFPawn(Other);

      if ( HitPawn != none )
      {
        // Hit detection debugging
        /*log("PreLaunchTrace hit "$HitPawn.PlayerReplicationInfo.PlayerName);
         HitPawn.HitStart = Start;
         HitPawn.HitEnd = End;*/
        if(!HitPawn.bDeleteMe)
          HitPawn.ProcessLocationalDamage(int(HitDamage), Instigator, HitLocation, Momentum*X,DamageType,HitPoints);

        // Hit detection debugging
        /*if( Level.NetMode == NM_Standalone)
          HitPawn.DrawBoneLocation();*/

        IgnoreActors[IgnoreActors.Length] = Other;
        IgnoreActors[IgnoreActors.Length] = HitPawn.AuxCollisionCylinder;
        Other.SetCollision(false);
        HitPawn.AuxCollisionCylinder.SetCollision(false);
        DamageActor = Other;
      }
      else
      {
        if ( KFMonster(Other)!=None )
        {
          IgnoreActors[IgnoreActors.Length] = Other;
          Other.SetCollision(false);
          DamageActor = Other;
        }
        else if ( DamageActor == none )
        {
          DamageActor = Other;
        }
        Other.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
      }
      if ( (HCounter++) >= 4 || Pawn(DamageActor) == None )
      {
        break;
      }
      HitDamage/=2;
      Start = HitLocation;
    }
    else if ( HitScanBlockingVolume(Other) == None )
    {
      if ( KFWeaponAttachment(Weapon.ThirdPersonActor) != none )
        KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
      Break;
    }
  }

  // Turn the collision back on for any actors we turned it off
  // FIXED accessed none IgnoreActors !
  if ( IgnoreActors.Length <= 0 )
    return;

  for (i=0; i<IgnoreActors.Length; i++)
  {
    if ( IgnoreActors[i] != none )
      IgnoreActors[i].SetCollision(true);
  }
}