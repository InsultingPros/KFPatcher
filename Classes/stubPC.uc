class stubPC extends KFMod.KFPlayerController;

// var MuVariableClass MuVariableClass;

function bool nCharacterAvailable(string CharName)
{
    return true;
}

function bool nPurchaseCharacter(string CharName)
{
    return true;
}


// Called by the server when the game enters zed time. Used to play the effects
simulated function ClientEnterZedTime()
{
    CheckZEDMessage();

    // if we have a weapon, play the zed time sound from it so it is higher priority and doesn't get cut off
    // if( Pawn != none && Pawn.Weapon != none )
    // {
    //     Pawn.Weapon.PlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Enter', SLOT_Talk, 2.0,false,500.0,1.1/Level.TimeDilation,false);
    // }
    // else
    // {
    //     PlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Enter', SLOT_Talk, 2.0,false,500.0,1.1/Level.TimeDilation,false);
    // }
}


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


// won't work serverside, obviously
exec function SpawnTargets()
{
    local KFHumanPawn p;

    if( !class'ROEngine.ROLevelInfo'.static.RODebugMode() )
        return;

    p = Spawn( class 'KFHumanPawn',,,Pawn.Location + 72 * Vector(Rotation) + vect(0,0,1) * 15 );

    p.LoopAnim('Idle_Bullpup');

    p.setphysics(PHYS_Falling);
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

simulated static function ReplaceTextHook(out string Text, string Replace, string With)
{
  log("Dark Magic Mut: I'VE CHANGED I SWEAR!!!!");
}