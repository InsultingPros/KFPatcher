class	stubShopVolume extends KFShopVolume_Story;


var string shopTag;

//  fix for accessed nones
function Touch( Actor Other )
{
  // to prevent accessed none warnings
  if (Other == none)
    return;

  if ( Pawn(Other) != none && PlayerController(Pawn(Other).Controller) != none && KFGameType(Level.Game) != none && !KFGameType(Level.Game).bWaveInProgress )
  {
    if( !bCurrentlyOpen )
    {
      BootPlayers();
      return;
    }

    // none check
    if (MyTrader != none)
      MyTrader.SetOpen(true);

    if( KFPlayerController(Pawn(Other).Controller) !=None )
    {
      KFPlayerController(Pawn(Other).Controller).SetShowPathToTrader(false);
      KFPlayerController(Pawn(Other).Controller).CheckForHint(52);
    }

    PlayerController(Pawn(Other).Controller).ReceiveLocalizedMessage(class'KFMainMessages',3);

    if ( KFPlayerController(Pawn(Other).Controller) != none && !KFPlayerController(Pawn(Other).Controller).bHasHeardTraderWelcomeMessage )
    {
      // Have Trader say Welcome to players
      if ( KFGameType(Level.Game).WaveCountDown >= 30 )
      {
        KFPlayerController(Pawn(Other).Controller).ClientLocationalVoiceMessage(Pawn(Other).PlayerReplicationInfo, none, 'TRADER', 7);
        KFPlayerController(Pawn(Other).Controller).bHasHeardTraderWelcomeMessage = true;
      }
    }
  }

  else if( Other.IsA('KF_StoryInventoryPickup') )
  {
    if( !bCurrentlyOpen )
    {
      BootPlayers();
      return;
    }
  }
}


function UnTouch( Actor Other )
{
  // to prevent accessed none warnings
  if (Other == none)
    return;

  // none check
  if ( MyTrader != none && Pawn(Other) != none && PlayerController(Pawn(Other).Controller) != none && KFGameType(Level.Game) != none )
    MyTrader.SetOpen(false);
}


function UsedBy( Pawn user )
{
  // to prevent accessed none warnings
  if (user == none || KFHumanPawn(user) == none)
    return;

  // Set the pawn to an idle anim so he wont keep making footsteps
  User.SetAnimAction(User.IdleWeaponAnim);

  // none check
  if (MyTrader != none)
    class'stubShopVolume'.default.shoptag = string(MyTrader.Tag);

  if ( KFPlayerController(user.Controller) != none && KFGameType(Level.Game) != none && !KFGameType(Level.Game).bWaveInProgress )
    KFPlayerController(user.Controller).ShowBuyMenu(class'stubShopVolume'.default.shoptag, KFHumanPawn(user).MaxCarryWeight);
}


function bool BootPlayers()
{
  local KFHumanPawn Bootee;
  local int i,idx;
  local bool bResult;
  local int NumTouching,NumBooted;
  local array<Teleporter> UnusedSpots;
  local bool bBooted;

  if ( !bTelsInit )
    InitTeleports();
  if ( !bHasTeles )
    Return False; // Wtf?

  UnusedSpots = TelList;

  for (idx = 0; idx < Touching.Length; idx++)
  {
    if (Touching[idx] == none)
      continue;

    if (Touching[idx].IsA('KFHumanPawn'))
    {
      Bootee = KFHumanPawn(Touching[idx]);
      NumTouching ++ ;

      if( PlayerController(Bootee.Controller)!=none )
      {
        PlayerController(Bootee.Controller).ReceiveLocalizedMessage(class'KFMainMessages');
        PlayerController(Bootee.Controller).ClientCloseMenu(true, true);
      }

      // Teleport to a random teleporter in this local area, if more than one pick random.
      i = Rand(UnusedSpots.Length);

      // removed pawn check coz WE ALREADY CHECKED IT !
      Bootee.PlayTeleportEffect(false, true);
      bBooted = UnusedSpots[i].Accept( Bootee, self );
      if(bBooted)
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