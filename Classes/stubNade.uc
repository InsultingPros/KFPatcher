class stubNade extends Nade;


var array<sound> BoomSounds;


simulated function Explode(vector HitLocation, vector HitNormal)
{
  local PlayerController  LocalPlayer;
  local Projectile P;
  local byte i;

  bHasExploded = True;
  BlowUp(HitLocation);

  PlaySound(class'stubNade'.default.BoomSounds[rand(3)],,2.0);

  // Shrapnel
  for( i=Rand(6); i<10; i++ )
  {
    P = Spawn(ShrapnelClass,,,,RotRand(True));
    if( P!=None )
      P.RemoteRole = ROLE_None;
  }
  if ( EffectIsRelevant(Location,false) )
  {
    Spawn(Class'KFmod.KFNadeExplosion',,, HitLocation, rotator(vect(0,0,1)));
    Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
  }

  // Shake nearby players screens
  LocalPlayer = Level.GetLocalPlayerController();
  if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
    LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

  Destroy();
}


defaultproperties
{
  BoomSounds[0]=SoundGroup'KF_GrenadeSnd.Nade_Explode_1'
  BoomSounds[1]=SoundGroup'KF_GrenadeSnd.Nade_Explode_2'
  BoomSounds[2]=SoundGroup'KF_GrenadeSnd.Nade_Explode_3'
}