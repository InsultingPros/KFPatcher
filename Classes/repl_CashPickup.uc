class repl_CashPickup extends CashPickup;


function GiveCashTo( Pawn Other )
{
    // mental-mad typecasting one love from TWI
    if (!bDroppedCash)
        CashAmount = (rand(0.5 * default.CashAmount) + default.CashAmount) * (KFGameReplicationInfo(Level.GRI).GameDiff  * 0.5) ;

    // FIX!
    // added DroppedBy none check
    else if ( Other.PlayerReplicationInfo != none && DroppedBy != none && DroppedBy.PlayerReplicationInfo != none &&
                ((DroppedBy.PlayerReplicationInfo.Score + float(CashAmount)) / Other.PlayerReplicationInfo.Score) >= 0.50 &&
                PlayerController(DroppedBy) != none && KFSteamStatsAndAchievements(PlayerController(DroppedBy).SteamStatsAndAchievements) != none )
    {
        if (Other.PlayerReplicationInfo != DroppedBy.PlayerReplicationInfo)
        KFSteamStatsAndAchievements(PlayerController(DroppedBy).SteamStatsAndAchievements).AddDonatedCash(CashAmount);
    }

    if (Other.Controller != none && Other.Controller.PlayerReplicationInfo != none)
        Other.Controller.PlayerReplicationInfo.Score += CashAmount;

    AnnouncePickup(Other);
    SetRespawn();
}