class hookDoor extends KFDoorMover;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFDoorMover.uc#L286
// Forces zeds to actually ignore doors instead of just standing at them if bZombiesIgnore is true
function Tick(float Delta)
{
    if (DoorPathNode != none && PathUdpTimer < Level.TimeSeconds)
    {
        PathUdpTimer = Level.TimeSeconds + 0.5;
        DoorPathNode.ExtraCost = InitExtraCost;

        if (bSealed && MyTrigger != none)
        {
            // Zeds will always ignore the path node associated with this door.
            if (bZombiesIgnore)
                DoorPathNode.ExtraCost = 9999999;
            else
                DoorPathNode.ExtraCost += 500 + MyTrigger.WeldStrength * 6;
        }
    }
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/KFDoorMover.uc#L234
// Breaks all doors with the same use trigger. Fixes the single welded door exploit.
simulated function GoBang(pawn instigatedBy, vector hitlocation,Vector momentum, class<DamageType> damageType)
{
    local int i;
    local KFDoorMover kfdm;

    for (i = 0; i < myTrigger.doorOwners.length; i++)
    {
        kfdm = myTrigger.doorOwners[i];
        if (kfdm == none)
        {
            continue;
        }

        // The usual GoBang() code.
        kfdm.SetCollision(false, false, false);
        kfdm.bHidden = true;
        kfdm.bDoorIsDead = true;
        kfdm.NetUpdateTime = level.timeSeconds - 1;

        if (level.netMode != NM_DedicatedServer)
        {
            if (kfdm.surfaceType == EST_Metal)
            {
                if ((level.timeSeconds - kfdm.lastRenderTime) < 5)
                {
                    Spawn(kfdm.metalDoorExplodeEffectClass,,, kfdm.location, Rotator(vect(0,0,1)));
                }
                PlaySound(kfdm.metalBreakSound, SLOT_None, 2.0, false, 5000,,false);
            }
            else
            {
                if ((level.timeSeconds - kfdm.lastRenderTime) < 5)
                {
                    Spawn(kfdm.woodDoorExplodeEffectClass,,, kfdm.location, Rotator(vect(0,0,1)));
                }
                PlaySound(kfdm.woodBreakSound, SLOT_None, 2.0, false, 5000,,false);
            }
        }
    }
}


defaultproperties{}