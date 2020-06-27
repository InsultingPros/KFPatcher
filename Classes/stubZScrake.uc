class stubZScrake extends ZombieScrake;


var ZombieScrake sc;


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