class stub_KFSteamWebApi extends KFSteamWebApi;


event Timer()
{
  local string text;
  local string command;
  local int count;

  if(myLink != None)
  {
    if ( myLink.ServerIpAddr.Port != 0)
    {
      if(myLink.IsConnected())
      {
        if(sendGet)
        {
          command = getRequestLeft$appid$getRequestSteamID$steamID$getRequestRight$myLink.CRLF$"Host: "$steamAPIAddr$myLink.CRLF$myLink.CRLF;
          myLink.SendCommand(command);

          pageWait = true;
          myLink.WaitForCount(1,20,1); // 20 sec timeout
          sendGet = false;
        }
        else
        {
          if(pageWait)
          {
            // log("waiting");
          }
        }
      }
      else
      {
        if(sendGet)
        {
          log("could not connect");
        }
      }
    }
    else
    {
      if (myRetryCount++ > myRetryMax)
      {
        log("too many retries!");
      }
    }

    if(myLink.PeekChar() != 0)
    {
      pageWait = false;

      // data waiting
      //these two while statements get all the data we need.
      while(myLink.ReadBufferedLine(text))
      {
        playerStats = playerStats$text;
      }

      // get json
      playerStats = myLink.InputBuffer;

      count = InStr(playerStats, "\"success\":true" );
      if(count == -1 )
      {
        log("webapi*********** still need to wait", 'DevNet');                
        SetTimer(0.250000, true);
        return;
      }
      else
      {
        log("webapi EOF reached", 'DevNet');
      }

      log(playerStats, 'DevNet');
      log("webapi********playerstats", 'DevNet');
      HasAchievement("NotAWarhammer");

      myLink.DestroyLink();
      myLink = none;

      return;
    }
  }

  SetTimer(0.250000, true);
}


function bool HasAchievement(string achievement)
{
  local int position;
  local string rhs;
  local string findString;

  findString = "\"apiname\":\""$achievement$"\",";
  position = InStr(playerStats, findString );
  // we found it!
  if( position != -1 )
  {
    rhs = Mid(playerStats, position +Len(FindString), 20 );//- Len(findString) );
    position = InStr(rhs,"achieved\":1");
  }

  AchievementReport( position != -1, achievement, appID, steamID);
  if( position != -1 )
  {
    return true;
  }

  return false;
}