class stub_Door extends KFDoorMover;


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


defaultproperties{}