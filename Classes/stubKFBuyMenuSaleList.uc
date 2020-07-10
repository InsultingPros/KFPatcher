class stubKFBuyMenuSaleList extends KFBuyMenuSaleList;


function UpdateList()
{
  local int i;
  // local bool unlockedByAchievement, unlockedByApp;

  // Clear the arrays
  if ( ForSaleBuyables.Length < ItemPerkIndexes.Length )
  {
    ItemPerkIndexes.Remove(ForSaleBuyables.Length, ItemPerkIndexes.Length - ForSaleBuyables.Length);
    PrimaryStrings.Remove(ForSaleBuyables.Length, PrimaryStrings.Length - ForSaleBuyables.Length);
    SecondaryStrings.Remove(ForSaleBuyables.Length, SecondaryStrings.Length - ForSaleBuyables.Length);
    CanBuys.Remove(ForSaleBuyables.Length, CanBuys.Length - ForSaleBuyables.Length);
  }

  // Update the ItemCount and select the first item
  ItemCount = ForSaleBuyables.Length;

  // Update the players inventory list
  for ( i = 0; i < ItemCount; i++ )
  {
    PrimaryStrings[i] = ForSaleBuyables[i].ItemName;
    SecondaryStrings[i] = "�" @ int(ForSaleBuyables[i].ItemCost);

    //controls which icon to put up
    ItemPerkIndexes[i] = ForSaleBuyables[i].ItemPerkIndex;

    if ( ForSaleBuyables[i].ItemCost > PlayerOwner().PlayerReplicationInfo.Score ||
             ForSaleBuyables[i].ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight )
    {
      CanBuys[i] = 0;
    }
    else
    {
      CanBuys[i] = 1;
    }

    if( ForSaleBuyables[i].ItemPickupClass == class'KFMod.Potato' )
    {
      continue;
    }

        // unlockedByAchievement = false;
        // unlockedByApp = false;

        // if( KFSteamStatsAndAchievements(PlayerOwner().SteamStatsAndAchievements) != none )
        // {
        //     if( ForSaleBuyables[i].ItemWeaponClass.Default.UnlockedByAchievement != -1 )
        //     {

        //         unlockedByAchievement = KFSteamStatsAndAchievements(PlayerOwner().SteamStatsAndAchievements).Achievements[ForSaleBuyables[i].ItemWeaponClass.Default.UnlockedByAchievement].bCompleted == 1;
        //     }
        //     if( ForSaleBuyables[i].ItemWeaponClass.Default.AppID > 0 )
        //     {

        //         unlockedByApp = PlayerOwner().SteamStatsAndAchievements.PlayerOwnsWeaponDLC(ForSaleBuyables[i].ItemWeaponClass.Default.AppID);
        //     }
        // }
        // //lock the weapon if it requires an achievement that they don't have.
        // if ( ForSaleBuyables[i].ItemWeaponClass.Default.UnlockedByAchievement != -1 )
        // {
        //     if( !unlockedByAchievement && !unlockedByApp)
        //     {
        //         CanBuys[i] = 0;
        //         SecondaryStrings[i] = "LOCKED";
        //     }
        // }
        // else if ( ForSaleBuyables[i].ItemWeaponClass.Default.AppID > 0 && !unlockedByApp )
        // {
        //     if( !unlockedByAchievement )
        //     {
        //         CanBuys[i] = 0;
        //         SecondaryStrings[i] = "DLC";
        //     }
        // }
  }

  if ( bNotify )
  {
    CheckLinkedObjects(Self);
  }

  if ( MyScrollBar != none )
  {
    MyScrollBar.AlignThumb();
  }

  bNeedsUpdate = false;
}


function IndexChanged(GUIComponent Sender)
{
  if( Index >= 0 )
  {
    // used to cache the current selection so it can be displayed in the center
    // even when it isn't in the list (like when another perk filter is set)
    BuyableToDisplay = new class'GUIBuyable';
    BuyableToDisplay.ItemName           = ForSaleBuyables[Index].ItemName;
    BuyableToDisplay.ItemDescription    = ForSaleBuyables[Index].ItemDescription;
    BuyableToDisplay.ItemCategorie      = ForSaleBuyables[Index].ItemCategorie;
    BuyableToDisplay.ItemImage          = ForSaleBuyables[Index].ItemImage;
    BuyableToDisplay.ItemWeaponClass    = ForSaleBuyables[Index].ItemWeaponClass;
    BuyableToDisplay.ItemAmmoClass      = ForSaleBuyables[Index].ItemAmmoClass;
    BuyableToDisplay.ItemPickupClass    = ForSaleBuyables[Index].ItemPickupClass;
    BuyableToDisplay.ItemCost           = ForSaleBuyables[Index].ItemCost;
    BuyableToDisplay.ItemAmmoCost       = 0;
    BuyableToDisplay.ItemFillAmmoCost   = 0;
    BuyableToDisplay.ItemWeight         = ForSaleBuyables[Index].ItemWeight;
    BuyableToDisplay.ItemPower          = ForSaleBuyables[Index].ItemPower;
    BuyableToDisplay.ItemRange          = ForSaleBuyables[Index].ItemRange;
    BuyableToDisplay.ItemSpeed          = ForSaleBuyables[Index].ItemSpeed;
    BuyableToDisplay.ItemAmmoCurrent    = 0;
    BuyableToDisplay.ItemAmmoMax        = 0;
    BuyableToDisplay.ItemPerkIndex      = ForSaleBuyables[Index].ItemPerkIndex;
    BuyableToDisplay.bSaleList = true;

    if ( CanBuys[Index] == 0 )
    {
      // if ( ForSaleBuyables[Index].ItemWeaponClass.Default.AppID > 0 &&
      //            KFSteamStatsAndAchievements(PlayerOwner().SteamStatsAndAchievements) != none &&
      //           !PlayerOwner().SteamStatsAndAchievements.PlayerOwnsWeaponDLC(ForSaleBuyables[Index].ItemWeaponClass.Default.AppID) )
      //       {
      //           // TODO: Play "Purchase DLC" voice clip?
      //       }
      //       else if ( ForSaleBuyables[Index].ItemWeaponClass.Default.UnlockedByAchievement != -1 &&
      //                 KFSteamStatsAndAchievements(PlayerOwner().SteamStatsAndAchievements) != none &&
      //                 KFSteamStatsAndAchievements(PlayerOwner().SteamStatsAndAchievements).Achievements[ForSaleBuyables[index].ItemWeaponClass.Default.UnlockedByAchievement].bCompleted == 1)
      //       {

      //       }
      //       else 
      if ( ForSaleBuyables[Index].ItemCost > PlayerOwner().PlayerReplicationInfo.Score )
      {
        PlayerOwner().Pawn.DemoPlaySound(TraderSoundTooExpensive, SLOT_Interface, 2.0);
      }
      else if ( ForSaleBuyables[Index].ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight )
      {
        PlayerOwner().Pawn.DemoPlaySound(TraderSoundTooHeavy, SLOT_Interface, 2.0);
      }
    }
  }

  super(GUIVertList).IndexChanged(Sender);
}


defaultproperties{}