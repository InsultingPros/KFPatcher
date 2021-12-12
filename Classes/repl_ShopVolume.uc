// imagine almost all functions of this class are bugged
// amazing, i cummed twice
class  repl_ShopVolume extends KFShopVolume_Story;


// fix for accessed nones
function Touch(Actor other)
{
  local KFPlayerController pc;

  // ADDITION!!! to prevent accessed none warnings
  if (other == none)
    return;

  if (Pawn(other) != none && PlayerController(Pawn(other).Controller) != none && KFGameType(Level.Game) != none && !KFGameType(Level.Game).bWaveInProgress )
  {
    if (!bCurrentlyOpen)
    {
      BootPlayers();
      return;
    }

    // mad type casting fix
    // and removed two unnecessary pc checks
    pc = KFPlayerController(Pawn(other).Controller);
  
    // ADDITION!!! none check
    if (MyTrader != none)
      MyTrader.SetOpen(true);

    pc.SetShowPathToTrader(false);
    pc.CheckForHint(52);
    // this was playercontroller, but well same result
    pc.ReceiveLocalizedMessage(class'KFMainMessages', 3);

    if (!pc.bHasHeardTraderWelcomeMessage)
    {
      // Have Trader say Welcome to players
      if (KFGameType(Level.Game).WaveCountDown >= 30)
      {
        pc.ClientLocationalVoiceMessage(Pawn(other).PlayerReplicationInfo, none, 'TRADER', 7);
        pc.bHasHeardTraderWelcomeMessage = true;
      }
    }
  }

  // prevent softlock of objective
  // EDIT!!! Moved the check one level higher
  else if (other.IsA('KF_StoryInventoryPickup') && !bCurrentlyOpen)
  {
    BootPlayers();
    return;
  }
}


function UnTouch(Actor other)
{
  // ADDITION!!! to prevent accessed none warnings
  if (other == none)
    return;

  // ADDITION!!! MyTrader none check
  if (MyTrader != none && Pawn(other) != none && PlayerController(Pawn(other).Controller) != none && KFGameType(Level.Game) != none)
    MyTrader.SetOpen(false);
}


function UsedBy(Pawn user)
{
  local string svtag;

  // ADDITION!!! to prevent accessed none warnings
  if (user == none || KFHumanPawn(user) == none)
    return;

  // Set the pawn to an idle anim so he wont keep making footsteps
  User.SetAnimAction(User.IdleWeaponAnim);

  // MyTrader none check
  if (MyTrader != none)
    svtag = string(MyTrader.Tag);

  if (KFPlayerController(user.Controller) != none && KFGameType(Level.Game) != none && !KFGameType(Level.Game).bWaveInProgress)
    KFPlayerController(user.Controller).ShowBuyMenu(svtag, KFHumanPawn(user).MaxCarryWeight);
}


// touching out of bounds fix
function bool BootPlayers()
{
  local KFHumanPawn Bootee;
  local int i,idx;
  local bool bResult;
  local int NumTouching,NumBooted;
  local array<Teleporter> UnusedSpots;
  local bool bBooted;

  // really wtf is this
  if (!bTelsInit)
    InitTeleports();
  if (!bHasTeles)
    return false; // Wtf?

  UnusedSpots = TelList;

  for (idx = 0; idx < Touching.Length; idx++)
  {
    // none check so we wont go out of bounds
    if (Touching[idx] == none)
      continue;

    if (Touching[idx].IsA('KFHumanPawn'))
    {
      Bootee = KFHumanPawn(Touching[idx]);
      NumTouching ++ ;

      if (PlayerController(Bootee.Controller) != none)
      {
        PlayerController(Bootee.Controller).ReceiveLocalizedMessage(class'KFMainMessages');
        PlayerController(Bootee.Controller).ClientCloseMenu(true, true);
      }

      // Teleport to a random teleporter in this local area, if more than one pick random.
      i = Rand(UnusedSpots.Length);

      // removed pawn check coz WE ALREADY CHECKED IT !
      Bootee.PlayTeleportEffect(false, true);
      bBooted = UnusedSpots[i].Accept(Bootee, self);
      if (bBooted)
      {
        NumBooted ++;
        UnusedSpots.Remove(i,1);   // someone is being teleported here. We can't have the next guy spawning on top of him.
      }
    }

    else if (Touching[idx].IsA('KF_StoryInventoryPickup'))
    {
      Touching[idx].SetLocation(TelList[Rand(TelList.length)].Location + (vect(0,0,1) * Touching[idx].CollisionHeight)) ;
      Touching[idx].SetPhysics(PHYS_Falling);
      Touching[idx].SetOwner(Touching[idx].Owner);    // to force NetDirty
    }
  }

  bResult = NumBooted >= NumTouching;
  return bResult;
}


defaultproperties{}