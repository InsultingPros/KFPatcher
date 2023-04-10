/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookZ_Scrake_Ctrl extends SawZombieController;


// EXPERIMENTAL
function EndState()
{
    if (Pawn != none)
    {
        Pawn.AccelRate = Pawn.default.AccelRate;
        Pawn.GroundSpeed = ZombieScrake(Pawn).GetOriginalGroundSpeed();
    }
}