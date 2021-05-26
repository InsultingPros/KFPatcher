class stub_KFTab_BuyMenu extends KFTab_BuyMenu;


function bool IsLocked(GUIBuyable buyable)
{
  return false;
}


function SetInfoText()
{
  local string TempString;

  if ( TheBuyable == none && !bDidBuyableUpdate )
  {
    InfoScrollText.SetContent(InfoText[0]);
    bDidBuyableUpdate = true;
    return;
  }

  if ( TheBuyable != none && OldPickupClass != TheBuyable.ItemPickupClass )
  {
    // Unowned Weapon DLC
    // if ( TheBuyable.ItemWeaponClass.Default.AppID > 0 && !PlayerOwner().SteamStatsAndAchievements.PlayerOwnsWeaponDLC(TheBuyable.ItemWeaponClass.Default.AppID) )
    // {
    //   InfoScrollText.SetContent(Repl(InfoText[4], "%1", PlayerOwner().SteamStatsAndAchievements.GetWeaponDLCPackName(TheBuyable.ItemWeaponClass.Default.AppID)));
    // }

    // Too expensive
    // else if
    if ( TheBuyable.ItemCost > PlayerOwner().PlayerReplicationInfo.Score && TheBuyable.bSaleList )
    {
      InfoScrollText.SetContent(InfoText[2]);
    }

    // Too heavy
    else if ( TheBuyable.ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight && TheBuyable.bSaleList )
    {
      TempString = Repl(Infotext[1], "%1", int(TheBuyable.ItemWeight));
      TempString = Repl(TempString, "%2", int(KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight - KFHumanPawn(PlayerOwner().Pawn).CurrentWeight));
      InfoScrollText.SetContent(TempString);
    }

    // default
    else
    {
      InfoScrollText.SetContent(TheBuyable.ItemDescription);
    }

    bDidBuyableUpdate = false;
    OldPickupClass = TheBuyable.ItemPickupClass;
  }
}


defaultproperties{}