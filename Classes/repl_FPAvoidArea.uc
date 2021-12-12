class repl_FPAvoidArea extends FleshPoundAvoidArea;


// added KFMonsterController check
function Touch(actor Other)
{
  if ((Pawn(Other) != none) && KFMonsterController(Pawn(Other).Controller) != none && RelevantTo(Pawn(Other)))
    KFMonsterController(Pawn(Other).Controller).AvoidThisMonster(KFMonst);
}


// added health check, 1500 is FP's base health
function bool RelevantTo(Pawn P)
{
  if (KFMonster(p) != none && KFMonster(p).default.Health >= 1500) //  || KFMonster(p).IsInState('')) )
    return false;

  return (KFMonst != none && VSizeSquared(KFMonst.Velocity) >= 75 && super(AvoidMarker).RelevantTo(P)
     && KFMonst.Velocity dot (P.Location - KFMonst.Location) > 0  );
}