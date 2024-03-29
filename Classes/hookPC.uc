/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookPC extends KFPlayerController_Story;


// TODO 1. fix voice messages in slomo

//=============================================================================
//                        no delay suicide
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/Engine/Classes/PlayerController.uc#L3689
// Engine.PlayerController
exec function Suicide()
{
    // keep the local variable, just in case it decides to crash...
    local float MinSuicideInterval;

    MinSuicideInterval = 0;
    if (Pawn != none)
      Pawn.Suicide();
}


//=============================================================================
//                        you will become #perk spam
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPlayerController.uc#L1405
// simulated SendSelectedVeterancyToServer() -> to this
// no more "you will become %perk" spam when you join midgame
// can change perk unlimited amount of times
// KFMod.KFPlayerController
function SelectVeterancy(class<KFVeterancyTypes> VetSkill, optional bool bForceChange)
{
  // NOTE!!! local variables CRASH here!!!

  if (VetSkill == none || KFPlayerReplicationInfo(PlayerReplicationInfo) == none || KFSteamStatsAndAchievements(SteamStatsAndAchievements) == none)
    return;

  // sets proper 'BuyMenuFilterIndex'
  SetSelectedVeterancy(VetSkill);

  if (KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress && VetSkill != KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill)
  {
    // FIX!
    // this 'xPlayer' float is not being used anywhere so let's use it
    // wait 2 seconds for ClientVeteranSkill replication
    if (Level.TimeSeconds > MinAdrenalineCost)
    {
      // moved this aswell so message and perk switch will happen at the same time
      // and let perks be switched without limits
      // bChangedVeterancyThisWave = false;
      ClientMessage(Repl(YouWillBecomePerkString, "%Perk%", VetSkill.default.VeterancyName));
    }

    MinAdrenalineCost = Level.TimeSeconds + 2.0f;
  }

  else // if (!bChangedVeterancyThisWave || bForceChange)
  {
      if (VetSkill != KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill)
        ClientMessage(Repl(YouAreNowPerkString, "%Perk%", VetSkill.default.VeterancyName));

      // if (GameReplicationInfo.bMatchHasBegun)
      //   bChangedVeterancyThisWave = true;

    KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill = VetSkill;
    KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkillLevel = KFSteamStatsAndAchievements(SteamStatsAndAchievements).PerkHighestLevelAvailable(VetSkill.default.PerkIndex);

    // recalcs weight and ammo
    if (KFHumanPawn(Pawn) != none)
      KFHumanPawn(Pawn).VeterancyChanged();
  }

  // else
  //   ClientMessage(PerkChangeOncePerWaveString);
}


//=============================================================================
//                    blank spectator join message fix
//=============================================================================

// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPlayerController.uc#L3004
// worst case since repInfo creates after this function call
// should I check its existance for other parts of this function???
// KFMod.KFPlayerController
function JoinedAsSpectatorOnly()
{
  if (Pawn != none)
    Pawn.Died(self, class'DamageType', Pawn.Location);

  if (PlayerReplicationInfo.Team != none)
    PlayerReplicationInfo.Team.RemoveFromTeam(self);

  PlayerReplicationInfo.Team = none;
  ServerSpectate();

  ClientBecameSpectator();
  // let's fix blank messages
  // this 'xPlayer' float is not being used anywhere so let's use it
  MinAdrenalineCost = Level.TimeSeconds + 10.0f;

  // start a loop and wait 10 secs for repInfo to appear
  while (Level.TimeSeconds <= MinAdrenalineCost)
  {
    if (PlayerReplicationInfo != none)
    {
      // BroadcastLocalizedMessage(Level.Game.GameMessageClass, 14, PlayerReplicationInfo);
      class'Utility'.static.BroadcastText(Level, "^b" $ PlayerReplicationInfo.PlayerName $ "^w joined as spectator.");
      break;
    }
  }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPlayerController.uc#L928
// KFMod.KFPlayerController
function BecomeSpectator()
{
  if (Role < ROLE_Authority)
    return;

  if (!Level.Game.BecomeSpectator(self))
    return;

  if (Pawn != none)
    Pawn.Died(self, class'DamageType', Pawn.Location);

  if (PlayerReplicationInfo.Team != none)
    PlayerReplicationInfo.Team.RemoveFromTeam(self);
  PlayerReplicationInfo.Team = none;
  ServerSpectate();

  // no repInfo checks since player is not leaving atm, just moving around
  // change the text a bit, this is an other case
  class'Utility'.static.BroadcastText(Level, "^b" $ PlayerReplicationInfo.PlayerName $ "^w moved to spectator slot.");

  ClientBecameSpectator();
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFPlayerController.uc#L3080
function bool IsInInventory(class<Pickup> PickupToCheck, bool bCheckForEquivalent, bool bCheckForVariant)
{
  return false;
}

// Prevent clients IP address leak.
//
// Target: `XGame.xPlayer.ServerRequestPlayerInfo`
// Original code: https://github.com/InsultingPros/KillingFloor/blob/main/XGame/Classes/xPlayer.uc#L870-L885
function ServerRequestPlayerInfo() {
    local Controller C;
    local xPlayer xPC;

    for (C = Level.ControllerList; C != none; C = C.NextController) {
        xPC = XPlayer(C);
        if (xPC != none) {
            // REMOVE `GetPlayerNetworkAddress()`
            ClientReceiveRule(
                xPC.PlayerReplicationInfo.PlayerName $
                chr(27) $
                xPC.GetPlayerIDHash() $
                chr(27) $
                "NONE"
            );
        } else {
            // REMOVE `GetPlayerNetworkAddress()`
            ClientReceiveRule(
                C.PlayerReplicationInfo.PlayerName $
                chr(27) $
                "AI Controlled" $
                chr(27) $
                "BOT"
            );
        }
    }
    ClientReceiveRule("Done");
}

// Prevent clients IP address leak.
//
// Target: `XGame.xPlayer.ServerRequestBanInfo`
// Original code: https://github.com/InsultingPros/KillingFloor/blob/main/XGame/Classes/xPlayer.uc#L925-L948
function ServerRequestBanInfo(int PlayerID) {
    local array<PlayerController> CArr;
    local int i;

    if (Level != none && Level.Game != none) {
        Level.Game.GetPlayerControllerList(CArr);
        for (i = 0; i < CArr.Length; i++) {
            if (CArr[i] == self) {
                continue;
            }
            if (PlayerID == -1 || CArr[i].PlayerReplicationInfo.PlayerID == PlayerID) {
                // REMOVE `GetPlayerNetworkAddress()`
                log(
                    Name @
                    "Sending BanInfo To Client PlayerID:" $
                    CArr[i].PlayerReplicationInfo.PlayerID @
                    "Hash:" $
                    CArr[i].GetPlayerIDHash() @
                    "Address:" $
                    "NONE",
                    'ChatManager'
                );
                // REMOVE `GetPlayerNetworkAddress()`
                ChatManager.TrackNewPlayer(
                    CArr[i].PlayerReplicationInfo.PlayerID,
                    CArr[i].GetPlayerIDHash(),
                    "NONE"
                );
                // REMOVE `GetPlayerNetworkAddress()`
                ClientReceiveBan(
                    CArr[i].PlayerReplicationInfo.PlayerID $
                    chr(27) $
                    CArr[i].GetPlayerIDHash() $
                    chr(27) $
                    "NONE"
                );
            }
        }
    }
}