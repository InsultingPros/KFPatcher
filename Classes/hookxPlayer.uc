class hookxPlayer extends xPlayer;

function ServerRequestPlayerInfo()
{
	local Controller C;
    local xPlayer xPC;

    for (C=Level.ControllerList;C!=None;C=C.NextController)
    {
    	xPC = XPlayer(C);
        if (xPC!=None)
			ClientReceiveRule(xPC.PlayerReplicationInfo.PlayerName$chr(27)$xPC.GetPlayerIDHash()$chr(27)$"NONE");
		else
        	ClientReceiveRule(C.PlayerReplicationInfo.PlayerName$chr(27)$"AI Controlled"$chr(27)$"BOT");
	}

	ClientReceiveRule("Done");
}

function ServerRequestBanInfo(int PlayerID)
{
	local array<PlayerController> CArr;
	local int i;

	if ( Level != None && Level.Game != None )
	{
		Level.Game.GetPlayerControllerList(CArr);
		for (i = 0; i < CArr.Length; i++)
		{
			if ( CArr[i] == Self )
				continue;

			if ( PlayerID == -1 || CArr[i].PlayerReplicationInfo.PlayerID == PlayerID )
			{
				log(Name@"Sending BanInfo To Client PlayerID:"$CArr[i].PlayerReplicationInfo.PlayerID@"Hash:"$CArr[i].GetPlayerIDHash()@"Address:"$"NONE",'ChatManager');
				ChatManager.TrackNewPlayer(CArr[i].PlayerReplicationInfo.PlayerID, CArr[i].GetPlayerIDHash(), "NONE");
				ClientReceiveBan(CArr[i].PlayerReplicationInfo.PlayerID$Chr(27)$CArr[i].GetPlayerIDHash()$chr(27)$"NONE");
			}
		}
	}
}
