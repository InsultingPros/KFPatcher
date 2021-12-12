class stub_PC extends KFPlayerController_Story;


var byte MaxVoiceMsgIn10s, contsMaxMsg;


//=============================================================================
//                       slomo + voice messages fuckup fix
//=============================================================================

// all 3 functions are from ScrN
simulated function ClientEnterZedTime()
{
  // this 'xPlayer' bool is not being used anywhere so let's use it
  // we need this bool for voice messages
  autozoom = true;

  CheckZEDMessage();

  if (Pawn != none && Pawn.Weapon != none)
    Pawn.Weapon.PlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Enter', SLOT_Talk, 2.0,false,500.0,1.1/Level.TimeDilation,false);
  else
    PlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Enter', SLOT_Talk, 2.0,false,500.0,1.1/Level.TimeDilation,false);
}


simulated function ClientExitZedTime()
{
  // this 'xPlayer' bool is not being used anywhere so let's use it
  // we need this bool for voice messages
  autozoom = false;

  if (Pawn != none && Pawn.Weapon != none)
    Pawn.Weapon.PlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit', SLOT_Talk, 2.0,false,500.0,1.1/Level.TimeDilation,false);
  else
    PlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit', SLOT_Talk, 2.0,false,500.0,1.1/Level.TimeDilation,false);
}


function bool AllowVoiceMessage(name MessageType)
{
  local float TimeSinceLastMsg;

  if (Level.NetMode == NM_Standalone || (PlayerReplicationInfo != none && (PlayerReplicationInfo.bAdmin || PlayerReplicationInfo.bSilentAdmin)))
    return true;

  TimeSinceLastMsg = Level.TimeSeconds - OldMessageTime;

  if (TimeSinceLastMsg < 3)
  {
    if (MessageType == 'TAUNT' || MessageType == 'AUTOTAUNT')
      return false;
    if (TimeSinceLastMsg < 1 )
      return false;
  }

  // zed time screws up voice messages
  if (!autozoom && MessageType != 'TRADER' && MessageType != 'AUTO')
  {
    OldMessageTime = Level.TimeSeconds;
    if (TimeSinceLastMsg < 10)
    {
      if (class'stub_PC'.default.MaxVoiceMsgIn10s > 0)
        class'stub_PC'.default.MaxVoiceMsgIn10s--;
      else
      {
        ClientMessage("Keep quiet for " $ ceil(10 - TimeSinceLastMsg) $"s");
        return false;
      }
    }
    else
      class'stub_PC'.default.MaxVoiceMsgIn10s = class'stub_PC'.default.contsMaxMsg;
  }
  return true;
}


//=============================================================================
//                        no delay suicide
//=============================================================================

exec function Suicide()
{
  if (Pawn != none)
    Pawn.Suicide();
}


//=============================================================================
//                        you will become #perk spam
//=============================================================================

// simulated SendSelectedVeterancyToServer() -> to this
// no more "you will become %perk" spam when you join midgame
// can change perk unlimited amount of times
function SelectVeterancy(class<KFVeterancyTypes> VetSkill, optional bool bForceChange)
{
  local KFPlayerReplicationInfo kfpri;
  local KFSteamStatsAndAchievements kfstats;

  // ADDITION!!! fucking twi typecasting at every step
  kfpri = KFPlayerReplicationInfo(PlayerReplicationInfo);
  kfstats = KFSteamStatsAndAchievements(SteamStatsAndAchievements);

  if (VetSkill == none || kfpri == none || kfstats == none)
    return;

  // sets proper 'BuyMenuFilterIndex'
  SetSelectedVeterancy(VetSkill);

  if (KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress && VetSkill != kfpri.ClientVeteranSkill)
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
      if (VetSkill != kfpri.ClientVeteranSkill)
        ClientMessage(Repl(YouAreNowPerkString, "%Perk%", VetSkill.default.VeterancyName));

      // if (GameReplicationInfo.bMatchHasBegun)
      //   bChangedVeterancyThisWave = true;

    kfpri.ClientVeteranSkill = VetSkill;
    kfpri.ClientVeteranSkillLevel = kfstats.PerkHighestLevelAvailable(VetSkill.default.PerkIndex);

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

// worst case since repInfo creates after this function call
// should I check its existance for other parts of this function???
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
      class'o_Helper'.static.BroadcastText(Level, "^b" $ PlayerReplicationInfo.PlayerName $ "^w joined as spectator.");
      break;
    }
  }
}


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
  class'o_Helper'.static.BroadcastText(Level, "^b" $ PlayerReplicationInfo.PlayerName $ "^w moved to spectator slot.");

  ClientBecameSpectator();
}


function bool IsInInventory(class<Pickup> PickupToCheck, bool bCheckForEquivalent, bool bCheckForVariant)
{
  return false;
}


defaultproperties
{
  MaxVoiceMsgIn10s=7
  contsMaxMsg=7
}