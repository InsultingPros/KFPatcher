class	stubShopVolume extends KFShopVolume_Story;


var string shopTag;


//  fix for accessed nones
function Touch( Actor Other )
{
  // to prevent accessed none warnings
  if (Other == none)
    return;

  if( Pawn(Other)!=None && PlayerController(Pawn(Other).Controller)!=None && KFGameType(Level.Game)!=None && !KFGameType(Level.Game).bWaveInProgress )
  {
    if( !bCurrentlyOpen )
    {
      BootPlayers();
      return;
    }

    if (MyTrader != none)
      MyTrader.SetOpen(true);

    if( KFPlayerController(Pawn(Other).Controller) !=None )
    {
      KFPlayerController(Pawn(Other).Controller).SetShowPathToTrader(false);
      KFPlayerController(Pawn(Other).Controller).CheckForHint(52);
    }

    PlayerController(Pawn(Other).Controller).ReceiveLocalizedMessage(Class'KFMainMessages',3);

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

  if (MyTrader != none)
    default.shoptag = string(MyTrader.Tag);
  else
    default.shoptag = "";

	if ( KFPlayerController(user.Controller)!=None && KFGameType(Level.Game)!=None && !KFGameType(Level.Game).bWaveInProgress )
		KFPlayerController(user.Controller).ShowBuyMenu(default.shoptag, KFHumanPawn(user).MaxCarryWeight);
}