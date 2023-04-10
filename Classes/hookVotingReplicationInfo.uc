/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookVotingReplicationInfo extends VotingReplicationInfo;


function SendMapVote(int MapIndex, int p_GameIndex)
{
    local KFPlayerController kfpc;

    kfpc = KFPlayerController(Owner);
    DebugLog("MVRI.SendMapVote(" $ MapIndex $ ", " $ p_GameIndex $ ")");

    if (kfpc != none && !kfpc.PlayerReplicationInfo.bOnlySpectator)
        VH.SubmitMapVote(MapIndex,p_GameIndex,Owner);
}