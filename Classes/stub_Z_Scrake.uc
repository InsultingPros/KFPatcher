class stub_Z_Scrake extends ZombieScrake;


var ZombieScrake sc;


// vector HeadOffset = vect(0,0,0)
// KFMonster = M
// Poosh (c) coz i was lazy to do lame hack
function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
  local coords C;
  // we are not gonna use some local vars, sooo... lets hope it wont crash
  local vector HeadLoc, diff; // B, M, not using these two
	// local float t, DotMM, Distance;
  local int look;
  local bool bUseAltHeadShotLocation;
  local bool bWasAnimating;

  if (HeadBone == '')
    return false;

  if (Level.NetMode == NM_DedicatedServer && !bShotAnim) // addition!
  {
    // If we are a dedicated server estimate what animation is most likely playing on the client
    switch (Physics)
    {
      case PHYS_Walking:
        bWasAnimating = IsAnimating(0) || IsAnimating(1);
        if (!bWasAnimating)
        {
          if (bIsCrouched)
          {
            PlayAnim(IdleCrouchAnim, 1.0, 0.0);
          }
          else
          {
            bUseAltHeadShotLocation=true;
          }
        }
        if (bDoTorsoTwist && !bUseAltHeadShotLocation)
        {
          SmoothViewYaw = Rotation.Yaw;
          SmoothViewPitch = ViewPitch;
          look = (256 * ViewPitch) & 65535;
          if (look > 32768)
            look -= 65536;

          SetTwistLook(0, look);
        }
        break;

      case PHYS_Falling:
      case PHYS_Flying:
        PlayAnim(AirAnims[0], 1.0, 0.0);
        break;

      case PHYS_Swimming:
        PlayAnim(SwimAnims[0], 1.0, 0.0);
        break;
    }

    if (!bWasAnimating && !bUseAltHeadShotLocation)
    {
      SetAnimFrame(0.5);
    }
  }

  if (bUseAltHeadShotLocation)
  {
    HeadLoc = Location + (OnlineHeadshotOffset >> Rotation);
    AdditionalScale *= OnlineHeadshotScale;
  }
  else
  {
    diff = vect(0,0,0);
    C = GetBoneCoords(HeadBone);
    HeadLoc = C.Origin + (HeadHeight * HeadScale * AdditionalScale * C.XAxis) + diff.X * C.XAxis + diff.Y * C.YAxis + diff.Z * C.ZAxis;
  }

  log("Headshot checked!");
  return class'stub_Z_Scrake'.static.TestHitboxSphere(HitLoc, Ray, HeadLoc, HeadRadius * HeadScale * AdditionalScale);
}


// Poosh (c) coz i was lazy to do lame hack
static final function bool TestHitboxSphere(vector HitLoc, vector Ray, vector SphereLoc, float SphereRadius)
{
  local vector HitToSphere;  // vector from HitLoc to SphereLoc
  local vector P;

  SphereRadius *= SphereRadius; // square it to avoid doing sqrt()

  HitToSphere = SphereLoc - HitLoc;
  if (VSizeSquared(HitToSphere) < SphereRadius)
  {
    // HitLoc is already inside the sphere - no projection needed
    return true;
  }

  // HitToSphere dot Ray = cos(A) * VSize(HitToSphere) = VSize(P - HitLoc)
  P = HitLoc + Ray * (HitToSphere dot Ray);

  return VSizeSquared(P - SphereLoc) < SphereRadius;
}


// Getter for the Original groundspeed of the zed (adjusted for difficulty, etc)
simulated function float GetOriginalGroundSpeed()
{
  if (owner != none && owner.class.name == 'SawZombieController')
  {
    if (IsInState('RunningState'))
      return OriginalGroundSpeed *= OriginalGroundSpeed;
    else if (IsInState('SawingLoop'))
      return OriginalGroundSpeed *= AttackChargeRate;
    else if (IsInState(''))
      return OriginalGroundSpeed;
  }

  if( bZedUnderControl )
  {
    return OriginalGroundSpeed * 1.25;
  }

  else
  {
    return OriginalGroundSpeed;
  }
}


function EndState()
{
  log("FUCK YEA!");
	if( !bZapped )
	{
    SetGroundSpeed(GetOriginalGroundSpeed());
  }
	bCharging = False;
	if( Level.NetMode!=NM_DedicatedServer )
		PostNetReceive();
}