/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookRule extends GameRules;


// https://github.com/InsultingPros/KillingFloor/blob/main/Engine/Classes/GameRules.uc#L61
// no map switch if we leave from lobby
// GameRules.CheckEndGame
function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    if (Level.Game.IsInState('PendingMatch'))
        return false;

    if (NextGameRules != none)
        return NextGameRules.CheckEndGame(Winner, Reason);

    return true;
}