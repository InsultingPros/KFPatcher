// imagine almost all functions of this class are bugged
class repl_ShopVolume extends KFShopVolume_Story;


// used to replace broken trader tags in UsedBy()
var string TraderTag;


// fix for accessed nones
// KFMod.ShopVolume
function Touch(Actor other)
{
  // NOTE!!! local variables CRASH here!!!

  // ADDITION!!! to prevent accessed none warnings
  if (other == none)
    return;

  if (Pawn(other) != none && PlayerController(Pawn(other).Controller) != none && KFGameType(Level.Game) != none && !KFGameType(Level.Game).bWaveInProgress)
  {
    if (!bCurrentlyOpen)
    {
      BootPlayers();
      return;
    }
  
    // ADDITION!!! none check
    if (MyTrader != none)
      MyTrader.SetOpen(true);

    // NOTE!!! removed all KFPC checks, coz we check it at the very start
    KFPlayerController(Pawn(other).Controller).SetShowPathToTrader(false);
    KFPlayerController(Pawn(other).Controller).CheckForHint(52);
    // this was playercontroller, but well same result
    PlayerController(Pawn(other).Controller).ReceiveLocalizedMessage(class'KFMainMessages', 3);

    if (!KFPlayerController(Pawn(Other).Controller).bHasHeardTraderWelcomeMessage)
    {
      // Have Trader say Welcome to players
      if (KFGameType(Level.Game).WaveCountDown >= 30)
      {
        KFPlayerController(Pawn(Other).Controller).ClientLocationalVoiceMessage(Pawn(other).PlayerReplicationInfo, none, 'TRADER', 7);
        KFPlayerController(Pawn(Other).Controller).bHasHeardTraderWelcomeMessage = true;
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


// KFMod.ShopVolume
function UnTouch(Actor other)
{
  // ADDITION!!! to prevent accessed none warnings
  if (other == none)
    return;

  // ADDITION!!! MyTrader none check
  if (MyTrader != none && Pawn(other) != none && PlayerController(Pawn(other).Controller) != none && KFGameType(Level.Game) != none)
    MyTrader.SetOpen(false);
}


// KFMod.ShopVolume
function UsedBy(Pawn user)
{
  // NOTE!!! local variables CRASH here!!!

  // ADDITION!!! to prevent accessed none warnings
  if (user == none || KFHumanPawn(user) == none)
    return;

  // Set the pawn to an idle anim so he wont keep making footsteps
  User.SetAnimAction(User.IdleWeaponAnim);

  if (KFPlayerController(user.Controller) != none && KFGameType(Level.Game) != none && !KFGameType(Level.Game).bWaveInProgress)
  {
    // ADDITION!!! MyTrader none check
    if (MyTrader != none)
      class'repl_ShopVolume'.default.TraderTag = MyTrader.Tag;
    KFPlayerController(user.Controller).ShowBuyMenu(class'repl_ShopVolume'.default.TraderTag, KFHumanPawn(user).MaxCarryWeight);
  }
}


// touching out of bounds fix
// KFMod.ShopVolume
function bool BootPlayers()
{
  local KFHumanPawn Bootee;
  local int i, idx;
  local bool bResult;
  local int NumTouching, NumBooted;
  local array<Teleporter> UnusedSpots;
  local bool bBooted;

  // really wtf is this
  if (!bTelsInit)
    InitTeleports();
  if (!bHasTeles)
    return false; // Wtf?!!

  UnusedSpots = TelList;

  // NOTE!!! made this human readable
  for (idx = 0; idx < Touching.Length; idx++)
  {
    // ADDITION!!! none check so we wont go out of bounds
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