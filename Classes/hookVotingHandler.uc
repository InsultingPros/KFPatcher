/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class hookVotingHandler extends xVotingHandler;


// only REAL players are counted. FUCKING IGNORES SPECS AND FAKES. FINALLY!!!!!!
function TallyVotes(bool bForceMapSwitch)
{
    local int oldNumPlayers;
    local Controller c;

    // save the current player count
    oldNumPlayers = Level.Game.NumPlayers;

    // reset the player count
    Level.Game.NumPlayers = 0;

    // count real players to prevent fakes from or specs from preventing map switching
    for (c = level.ControllerList; c != none; c = c.nextController)
    {
        if (c.bIsPlayer && c.PlayerReplicationInfo != none && !c.PlayerReplicationInfo.bOnlySpectator)
            Level.Game.NumPlayers++;
    }

    super(xVotingHandler).TallyVotes(bForceMapSwitch);

    // restore the original number of players
    Level.Game.NumPlayers = oldNumPlayers;
}


// this is just here to tell spectators that they can't vote
function SubmitMapVote(int MapIndex, int GameIndex, Actor Voter)
{
    local int Index, VoteCount, PrevMapVote, PrevGameVote;
    local MapHistoryInfo MapInfo;
    local bool bAdminForce;
    // ADDITION!!! prevent shit typecasting
    local PlayerController loc_pc;
    local PlayerReplicationInfo loc_PRI;

    if (bLevelSwitchPending)
        return;

    // ADDITION!!!
    loc_pc = PlayerController(Voter);
    loc_PRI = loc_pc.PlayerReplicationInfo;
    Index = GetMVRIIndex(loc_pc);

    if (GameIndex < 0)
    {
        bAdminForce = true;
        GameIndex = (-GameIndex) - 1;
    }
    if (GameIndex >= GameConfig.Length || MapIndex < 0 || MapIndex >= MapList.Length)
        return; // Something is wrong...

    // check for invalid vote from unpatch players
    if (!IsValidVote(MapIndex, GameIndex))
        return;

    // Administrator Vote
    if (bAdminForce && (loc_PRI.bAdmin || loc_PRI.bSilentAdmin))
    {
        TextMessage = lmsgAdminMapChange;
        TextMessage = Repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")");
        Level.Game.Broadcast(self,TextMessage);

        log("Admin has forced map switch to " $ MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")",'MapVote');

        CloseAllVoteWindows();

        bLevelSwitchPending = true;
        MapInfo = History.PlayMap(MapList[MapIndex].MapName);

        ServerTravelString = SetupGameMap(MapList[MapIndex], GameIndex, MapInfo);
        log("ServerTravelString = " $ ServerTravelString ,'MapVoteDebug');

        // change the map
        Level.ServerTravel(ServerTravelString, false);

        settimer(1,true);
        return;
    }

    if (loc_PRI.bOnlySpectator)
    {
        // Spectators cant vote
        loc_pc.ClientMessage(lmsgSpectatorsCantVote);
        return;
    }

    // check for invalid map, invalid gametype, player isnt revoting same as previous vote, and map choosen isnt disabled
    if (MapIndex < 0 || MapIndex >= MapCount || GameIndex >= GameConfig.Length || (MVRI[Index].GameVote == GameIndex && MVRI[Index].MapVote == MapIndex) ||
            !MapList[MapIndex].bEnabled)
            return;

    log("___" $ Index $ " - " $ loc_PRI.PlayerName $ " voted for " $ MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")",'MapVote');

    PrevMapVote = MVRI[Index].MapVote;
    PrevGameVote = MVRI[Index].GameVote;
    MVRI[Index].MapVote = MapIndex;
    MVRI[Index].GameVote = GameIndex;

    if (bAccumulationMode)
    {
        if (bScoreMode)
        {
            VoteCount = GetAccVote(loc_pc) + int(GetPlayerScore(loc_pc));
            TextMessage = lmsgMapVotedForWithCount;
            TextMessage = repl(TextMessage, "%playername%", loc_PRI.PlayerName );
            TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
            TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
            Level.Game.Broadcast(self,TextMessage);
        }
        else
        {
            VoteCount = GetAccVote(loc_pc) + 1;
            TextMessage = lmsgMapVotedForWithCount;
            TextMessage = repl(TextMessage, "%playername%", loc_PRI.PlayerName );
            TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
            TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
            Level.Game.Broadcast(self,TextMessage);
        }
    }
    else
    {
        if (bScoreMode)
        {
            VoteCount = int(GetPlayerScore(loc_pc));
            TextMessage = lmsgMapVotedForWithCount;
            TextMessage = repl(TextMessage, "%playername%", loc_PRI.PlayerName );
            TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
            TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
            Level.Game.Broadcast(self, TextMessage);
        }
        else
        {
            VoteCount =  1;
            TextMessage = lmsgMapVotedFor;
            TextMessage = repl(TextMessage, "%playername%", loc_PRI.PlayerName );
            TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
            Level.Game.Broadcast(self, TextMessage);
        }
    }
    UpdateVoteCount(MapIndex, GameIndex, VoteCount);
    if (PrevMapVote > -1 && PrevGameVote > -1)
        UpdateVoteCount(PrevMapVote, PrevGameVote, -MVRI[Index].VoteCount); // undo previous vote
    MVRI[Index].VoteCount = VoteCount;
    TallyVotes(false);
}