class stubPC extends KFPlayerController_Story;


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
  // glorious admins can spam voice every time
  if (Level.NetMode == NM_Standalone || (PlayerReplicationInfo != none && PlayerReplicationInfo.bAdmin))
    return true;

  // this 'xPlayer' float is not being used anywhere so let's use it
  gibwatchtime = Level.TimeSeconds - OldMessageTime;

  if (gibwatchtime < 3)
  {
    if ((MessageType == 'TAUNT') || (MessageType == 'AUTOTAUNT'))
      return false;
    if (gibwatchtime < 1)
      return false;
  }

  // zed time screws up voice messages
  if (!autozoom && MessageType != 'TRADER' && MessageType != 'AUTO')
  {
    OldMessageTime = Level.TimeSeconds;
    if (gibwatchtime < 10)
    {
      // this 'xPlayer' int is not being used anywhere so let's use it
      if (numcams > 0)
        numcams--;
      else
      {
        ClientMessage("Keep quiet for " $ ceil(10-gibwatchtime) $"s");
        return false;
      }
    }
    else
      // 7 must be not too many, not too few. Was 10 for ScrN
      numcams = 7;
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
function SelectVeterancy(class<KFVeterancyTypes> VetSkill, optional bool bForceChange)
{
  if (VetSkill == none || KFPlayerReplicationInfo(PlayerReplicationInfo) == none)
    return;

  if (KFSteamStatsAndAchievements(SteamStatsAndAchievements) != none)
  {
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
        bChangedVeterancyThisWave = false;
        ClientMessage(Repl(YouWillBecomePerkString, "%Perk%", VetSkill.Default.VeterancyName));
      }

      MinAdrenalineCost = Level.TimeSeconds + 2.0f;
    }

    else if (!bChangedVeterancyThisWave || bForceChange)
    {
      if (VetSkill != KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill)
        ClientMessage(Repl(YouAreNowPerkString, "%Perk%", VetSkill.Default.VeterancyName));

      if (GameReplicationInfo.bMatchHasBegun)
        bChangedVeterancyThisWave = true;

      KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill = VetSkill;
      KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkillLevel = KFSteamStatsAndAchievements(SteamStatsAndAchievements).PerkHighestLevelAvailable(VetSkill.default.PerkIndex);

      // recalcs weight and ammo
      if (KFHumanPawn(Pawn) != none)
        KFHumanPawn(Pawn).VeterancyChanged();
    }

    else
      ClientMessage(PerkChangeOncePerWaveString);
  }
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

  // let's fix blank messages
  // this 'xPlayer' float is not being used anywhere so let's use it
  MinAdrenalineCost = Level.TimeSeconds + 10.0f;

  // start a loop and wait 10 secs for repInfo to appear
  while (Level.TimeSeconds <= MinAdrenalineCost)
  {
    if (PlayerReplicationInfo != none)
    {
      // BroadcastLocalizedMessage(Level.Game.GameMessageClass, 14, PlayerReplicationInfo);
      class'uHelper'.static.BroadcastText(Level, "^b" $ PlayerReplicationInfo.PlayerName $ "^w joined as spectator.");
      break;
    }
  }

  ClientBecameSpectator();
}


function BecomeSpectator()
{
  if (Role < ROLE_Authority)
    return;

  if (Level.Game.BecomeSpectator(self))
    return;

  if (Pawn != none)
    Pawn.Died(self, class'DamageType', Pawn.Location);

  if (PlayerReplicationInfo.Team != none)
    PlayerReplicationInfo.Team.RemoveFromTeam(self);
  PlayerReplicationInfo.Team = none;
  ServerSpectate();

  // no repInfo checks since player is not leaving atm, just moving around
  // change the text a bit, this is an other case
  class'uHelper'.static.BroadcastText(Level, "^b" $ PlayerReplicationInfo.PlayerName $ "^w moved to spectator slot.");

  ClientBecameSpectator();
}


defaultproperties{}