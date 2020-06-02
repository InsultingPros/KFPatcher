class stubPawn extends KFHumanPawn_Story;


// toss some of your cash away. (to help a cash-strapped ally or perhaps just to party like its 1994)
exec function TossCash( int Amount )
{
  local Vector X,Y,Z;
  local CashPickup CashPickup ;
  local Vector TossVel;
  local Actor A;

  if(Level.TimeSeconds < class'MuVariableClass'.default.varTimer2)
  {
    return;
  }
  class'MuVariableClass'.default.varTimer2 = Level.TimeSeconds + 0.3f;

  // set minimal dosh
  Amount = clamp(Amount, 30, 500000);

  Controller.PlayerReplicationInfo.Score = int(Controller.PlayerReplicationInfo.Score); // To fix issue with throwing 0 pounds.
  if( Controller.PlayerReplicationInfo.Score<=0 || Amount<=0 )
    return;
  Amount = Min(Amount,int(Controller.PlayerReplicationInfo.Score));

  GetAxes(Rotation,X,Y,Z);

  TossVel = Vector(GetViewRotation());
  TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);

  // added owner to cash pickup, 2020 finally
  CashPickup = spawn(class'CashPickup', Self,, Location + 0.8 * CollisionRadius * X - 0.5 * CollisionRadius * Y);

  if(CashPickup != none)
  {
    CashPickup.CashAmount = Amount;
    CashPickup.bDroppedCash = true;
    CashPickup.RespawnTime = 0;   // Dropped cash doesnt respawn. For obvious reasons.
    CashPickup.Velocity = TossVel;
    CashPickup.DroppedBy = Controller;
    CashPickup.InitDroppedPickupFor(None);
    Controller.PlayerReplicationInfo.Score -= Amount;

    if ( Level.Game.NumPlayers > 1 && Level.TimeSeconds - LastDropCashMessageTime > DropCashMessageDelay )
    {
      PlayerController(Controller).Speech('AUTO', 4, "");
    }

    // Hack to get Slot machines to accept dosh that's thrown inside their collision cylinder.
    ForEach CashPickup.TouchingActors(class 'Actor', A)
    {
      if(A.IsA('KF_Slot_Machine'))
      {
        A.Touch(Cashpickup);
      }
    }
  }
}


// fix for none soundgroup calls on death
function Sound GetSound(xPawnSoundGroup.ESoundType soundType)
{
  local int SurfaceTypeID;
  local actor A;
  local vector HL,HN,Start,End;
  local material FloorMat;

  // added this in case when player joins using a custom skin with a custom SoundGroupClass,
  // which not present on the server
  if ( SoundGroupClass == none )
    SoundGroupClass = class'KFMod.KFMaleSoundGroup';

  if( soundType == EST_Land || soundType == EST_Jump )
  {
    if ( (Base!=None) && (!Base.IsA('LevelInfo')) && (Base.SurfaceType!=0) )
    {
      SurfaceTypeID = Base.SurfaceType;
    }
    else
    {
      Start = Location - Vect(0,0,1)*CollisionHeight;
      End = Start - Vect(0,0,16);
      A = Trace(hl,hn,End,Start,false,,FloorMat);
      if (FloorMat !=None)
        SurfaceTypeID = FloorMat.SurfaceType;
    }
  }

  return SoundGroupClass.static.GetSound(soundType, SurfaceTypeID);
}