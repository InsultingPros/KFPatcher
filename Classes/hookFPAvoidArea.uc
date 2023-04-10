/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookFPAvoidArea extends FleshPoundAvoidArea;


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/FleshPoundAvoidArea.uc#L33
// FleshPoundAvoidArea.Touch
function Touch(actor Other)
{
    // added KFMonsterController check
    if ((Pawn(Other) != none) && KFMonsterController(Pawn(Other).Controller) != none && RelevantTo(Pawn(Other)))
        KFMonsterController(Pawn(Other).Controller).AvoidThisMonster(KFMonst);
}


// https://github.com/InsultingPros/KillingFloor/blob/main/KFMod/Classes/FleshPoundAvoidArea.uc#L41
// FleshPoundAvoidArea.RelevantTo
function bool RelevantTo(Pawn P)
{
    // added health check, 1500 is FP's base health
    if (KFMonster(p) != none && KFMonster(p).default.Health >= 1500)
        return false;

    return (KFMonst != none && VSizeSquared(KFMonst.Velocity) >= 75 && super(AvoidMarker).RelevantTo(P)
            && KFMonst.Velocity dot (P.Location - KFMonst.Location) > 0  );
}