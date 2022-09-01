class hookVotingReplicationInfo extends VotingReplicationInfo;


function SendMapVote(int MapIndex, int p_GameIndex)
{
    local KFPlayerController kfpc;

    kfpc = KFPlayerController(Owner);
    DebugLog("MVRI.SendMapVote(" $ MapIndex $ ", " $ p_GameIndex $ ")");

    if (kfpc != none && !kfpc.PlayerReplicationInfo.bOnlySpectator)
        VH.SubmitMapVote(MapIndex,p_GameIndex,Owner);
}