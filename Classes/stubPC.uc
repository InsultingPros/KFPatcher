class stubPC extends KFPlayerController_Story;


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
      if(Level.TimeSeconds > class'MuVariableClass'.default.varTimer)
      {
        ClientMessage(Repl(YouWillBecomePerkString, "%Perk%", VetSkill.Default.VeterancyName));
      }
      class'MuVariableClass'.default.varTimer = Level.TimeSeconds + 2.0f;
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


simulated function ClientWeaponSpawned(class<Weapon> WClass, Inventory Inv)
{
  local class<KFWeapon> W;
  local class<KFWeaponAttachment> Att;
  local Weapon Spawned;

  //log("ScrnPlayerController.ClientWeaponSpawned()" @ WClass $ ". Default Mesh = " $ WClass.default.Mesh, 'ScrnBalance');
  //super.ClientWeaponSpawned(WClass, Inv);

  W = class<KFWeapon>(WClass);
  // preload assets only for weapons that have no static ones
  // damned Tripwire's code doesn't bother for cheking is there ref set or not!
  if ( W != none)
  {
    //preload weapon assets
    if ( W.default.Mesh == none )
      W.static.PreloadAssets(Inv);
    Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
    // 2013/01/22 EDIT: bug fix
    if ( Att != none && Att.default.Mesh == none )
    {
      if ( Inv != none )
        Att.static.PreloadAssets(KFWeaponAttachment(Inv.ThirdPersonActor));
      else
        Att.static.PreloadAssets();
    }
    // 2014-11-23 fix
    Spawned = Weapon(Inv);
    if ( Spawned != none )
    {
      class'stubPCu'.static.PreloadFireModeAssets(level, W.default.FireModeClass[0], Spawned.GetFireMode(0));
      class'stubPCu'.static.PreloadFireModeAssets(level, W.default.FireModeClass[1], Spawned.GetFireMode(0));
    }
    else
    {
      class'stubPCu'.static.PreloadFireModeAssets(level, W.default.FireModeClass[0]);
      class'stubPCu'.static.PreloadFireModeAssets(level, W.default.FireModeClass[1]);
    }
  }
}


simulated function ClientWeaponDestroyed(class<Weapon> WClass)
{
	local class<KFWeapon> W;
	local class<KFWeaponAttachment> Att;

	// log(default.class @ "ClientWeaponDestroyed()" @ WClass, default.class.outer.name);
	// super.ClientWeaponDestroyed(WClass); 

	W = class<KFWeapon>(WClass);
	// if default mesh is set, then count that weapon has static assets, so don't unload them
	// that's lame, but not so lame as Tripwire's original code
	if ( W != none && W.default.MeshRef != "" && W.static.UnloadAssets() )
	{
		Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
		if ( Att != none && Att.default.Mesh == none )
			Att.static.UnloadAssets();
		class'stubPCu'.static.UnloadFireModeAssets(W.default.FireModeClass[0]);
		class'stubPCu'.static.UnloadFireModeAssets(W.default.FireModeClass[1]);
	}
}