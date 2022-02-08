class repl_FPAvoidArea extends FleshPoundAvoidArea;


// FleshPoundAvoidArea.Touch
function Touch(actor Other)
{
    // added KFMonsterController check
    if ((Pawn(Other) != none) && KFMonsterController(Pawn(Other).Controller) != none && RelevantTo(Pawn(Other)))
        KFMonsterController(Pawn(Other).Controller).AvoidThisMonster(KFMonst);
}


// FleshPoundAvoidArea.RelevantTo
function bool RelevantTo(Pawn P)
{
    // added health check, 1500 is FP's base health
    if (KFMonster(p) != none && KFMonster(p).default.Health >= 1500)
        return false;

    return (KFMonst != none && VSizeSquared(KFMonst.Velocity) >= 75 && super(AvoidMarker).RelevantTo(P)
            && KFMonst.Velocity dot (P.Location - KFMonst.Location) > 0  );
}