class hookPipe extends PipeBombProjectile;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/PipeBombProjectile.uc#L46
static function PreloadAssets()
{
    // remove sound ref loading from here
    UpdateDefaultStaticMesh(StaticMesh(DynamicLoadObject(default.StaticMeshRef, class'StaticMesh', true)));
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/PipeBombProjectile.uc#L53
static function bool UnloadAssets()
{
    // remove sound ref assigning to none
    UpdateDefaultStaticMesh(none);
    return true;
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/PipeBombProjectile.uc#L485
// fix insane damage while being triggered with m1 spam
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    // added bTriggered check and moved damage check for siren scream
    if ( bTriggered || Damage < 5 || damageType == class'DamTypePipeBomb' ||
            ClassIsChildOf(damageType, class'DamTypeMelee') ||
            (Damage < 25 && damageType.IsA('SirenScreamDamage')) )
    {
        return;
    }

    // Don't let our own explosives blow this up!!!
    if ( InstigatedBy == none || InstigatedBy != none &&
            InstigatedBy.PlayerReplicationInfo != none &&
            InstigatedBy.PlayerReplicationInfo.Team != none &&
            InstigatedBy.PlayerReplicationInfo.Team.TeamIndex == PlacedTeam &&
            class<KFWeaponDamageType>(damageType) != none &&
            (class<KFWeaponDamageType>(damageType).default.bIsExplosive ||
            InstigatedBy != Instigator) )
    {
        return;
    }

    if ( damageType == class'SirenScreamDamage')
    {
        Disintegrate(HitLocation, vect(0,0,1));
    }
    else
    {
        Explode(HitLocation, vect(0,0,1));
    }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/PipeBombProjectile.uc#L111
// NPC, dead players trigger fix
function Timer()
{
    local Pawn CheckPawn;
    local float ThreatLevel;
    // still not sure about creating new local vars
    // but welp, it works fine
    local vector DetectLocation;

    // raise a detection poin half a meter up to prevent small objects on the ground bloking the trace
    DetectLocation = Location;
    DetectLocation.Z += 25;

    if (!bHidden && !bTriggered)
    {
        if (ArmingCountDown >= 0)
        {
            ArmingCountDown -= 0.1;
            if (ArmingCountDown <= 0)
            {
                SetTimer(1.0, true);
            }
        }
        else
        {
            // Check for enemies
            if (!bEnemyDetected)
            {
                bAlwaysRelevant = false;
                PlaySound(BeepSound,,0.5,,50.0);

                foreach VisibleCollidingActors( class 'Pawn', CheckPawn, DetectionRadius, DetectLocation )
                {
                    // don't trigger pipes on NPC  -- PooSH
                    if( CheckPawn == Instigator || KF_StoryNPC(CheckPawn) != none && KFGameType(Level.Game).FriendlyFireScale > 0 &&
                                    CheckPawn.PlayerReplicationInfo != none &&
                                    CheckPawn.PlayerReplicationInfo.Team.TeamIndex == PlacedTeam )
                    {
                        // Make the thing beep if someone on our team is within the detection radius
                        // This gives them a chance to get out of the way
                        ThreatLevel += 0.001;
                    }
                    else
                    {
                        // don't trigger pipes by dead bodies  -- PooSH
                        if( CheckPawn.Health > 0 && CheckPawn != Instigator && (CheckPawn.Role == ROLE_Authority) &&
                                        ((CheckPawn.PlayerReplicationInfo != none && CheckPawn.PlayerReplicationInfo.Team.TeamIndex != PlacedTeam) ||
                                        CheckPawn.GetTeamNum() != PlacedTeam))
                        {
                            if( KFMonster(CheckPawn) != none )
                            {
                                ThreatLevel += KFMonster(CheckPawn).MotionDetectorThreat;
                                if( ThreatLevel >= ThreatThreshhold )
                                {
                                    bEnemyDetected = true;
                                    SetTimer(0.15, true);
                                }
                            }
                            else
                            {
                                bEnemyDetected = true;
                                SetTimer(0.15, true);
                            }
                        }
                    }
                }

                if( ThreatLevel >= ThreatThreshhold )
                {
                    bEnemyDetected = true;
                    SetTimer(0.15, true);
                }
                else if( ThreatLevel > 0 )
                {
                    SetTimer(0.5, true);
                }
                else
                {
                    SetTimer(1.0, true);
                }
            }

            // Play some fast beeps and blow up
            else
            {
                bAlwaysRelevant = true;
                Countdown--;

                if ( CountDown > 0 )
                {
                    PlaySound(BeepSound, SLOT_Misc, 2.0,, 150.0);
                }
                else
                {
                    Explode(DetectLocation, vector(Rotation));
                }
            }
        }
    }
    else
    {
        Destroy();
    }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/PipeBombProjectile.uc#L284
// explode sounds none fix
simulated function Explode(vector HitLocation, vector HitNormal)
{
    local PlayerController  LocalPlayer;
    local Projectile P;
    local byte i;

    bHasExploded = true;
    BlowUp(HitLocation);

    bTriggered = true;

    if (Role == ROLE_Authority)
    {
        SetTimer(0.1, false);
        NetUpdateTime = Level.TimeSeconds - 1;
    }

    // PlaySound(class'hookPipe'.default.BoomSound,,2.0);
    PlaySound(sound(DynamicLoadObject("Inf_Weapons.antitankmine_explode01", class'Sound', true)),,2.0);

    // Shrapnel
    for (i = Rand(6); i < 10; i++)
    {
        P = Spawn(ShrapnelClass,,,,RotRand(true));
        if (P != none)
            P.RemoteRole = ROLE_None;
    }
    if (EffectIsRelevant(Location,false))
    {
        Spawn(class'KFMod.KFNadeLExplosion',,, HitLocation, rotator(vect(0,0,1)));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != none) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    if (Role < ROLE_Authority)
    {
        Destroy();
    }
}