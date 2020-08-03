class stubPC extends KFPlayerController_Story;


var transient float selectDelay;


// no more "you will become %perk" spam when you join midgame
function SelectVeterancy(class<KFVeterancyTypes> VetSkill, optional bool bForceChange)
{
  if ( VetSkill == none || KFPlayerReplicationInfo(PlayerReplicationInfo) == none )
  {
    return;
  }

  if ( KFSteamStatsAndAchievements(SteamStatsAndAchievements) != none )
  {
    SetSelectedVeterancy( VetSkill );

    if ( KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress && VetSkill != KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill )
    {
      bChangedVeterancyThisWave = false;

      // wait 2 seconds for ClientVeteranSkill replication
      if(Level.TimeSeconds > class'stubPC'.default.selectDelay)
      {
        ClientMessage(Repl(YouWillBecomePerkString, "%Perk%", VetSkill.Default.VeterancyName));
      }
      class'stubPC'.default.selectDelay = Level.TimeSeconds + 2.0f;
    }

    else if ( !bChangedVeterancyThisWave || bForceChange )
    {
      if ( VetSkill != KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill )
      {
        ClientMessage(Repl(YouAreNowPerkString, "%Perk%", VetSkill.Default.VeterancyName));
      }

      if ( GameReplicationInfo.bMatchHasBegun )
      {
        bChangedVeterancyThisWave = true;
      }

      KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill = VetSkill;
      KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkillLevel = KFSteamStatsAndAchievements(SteamStatsAndAchievements).PerkHighestLevelAvailable(VetSkill.default.PerkIndex);

      if( KFHumanPawn(Pawn) != none )
      {
        KFHumanPawn(Pawn).VeterancyChanged();
      }
    }
    else
    {
      ClientMessage(PerkChangeOncePerWaveString);
    }
  }
}


function JoinedAsSpectatorOnly()
{
  if (Pawn != none)
    Pawn.Died(self, class'DamageType', Pawn.Location);

  if (PlayerReplicationInfo.Team != none)
    PlayerReplicationInfo.Team.RemoveFromTeam(self);

  PlayerReplicationInfo.Team = none;
  ServerSpectate();

  // let's fix blank messages
  class'uHelper'.static.BroadcastText(Level, "^b" $ self.PlayerOwnerName $ " ^w joined as spectator.", true);
  // BroadcastLocalizedMessage(Level.Game.GameMessageClass, 14, PlayerReplicationInfo);

  ClientBecameSpectator();
}


function BecomeSpectator()
{
  if (Role < ROLE_Authority)
    return;

  if ( !Level.Game.BecomeSpectator(self) )
    return;

  if ( Pawn != None )
    Pawn.Died(self, class'DamageType', Pawn.Location);

  if ( PlayerReplicationInfo.Team != None )
    PlayerReplicationInfo.Team.RemoveFromTeam(self);
  PlayerReplicationInfo.Team = None;
  ServerSpectate();
  // let's block this
  // BroadcastLocalizedMessage(Level.Game.GameMessageClass, 14, PlayerReplicationInfo);

  ClientBecameSpectator();
}