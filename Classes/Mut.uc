class Mut extends Mutator
    config(KFPatcherFuncs);


//=============================================================================
var config array<CoreAPI.FunctionRecord> List;

// only allowed players can use mutate commands
var private array<string> AllowedSteamID;


//=============================================================================
event PreBeginPlay()
{
    super.PreBeginPlay();

    // TMP!!! hack fix for tosscahs!
    class'repl_Pawn'.default.cashtimer = 0.0f;

    // replacing vanilla functions with ours
    class'CoreAPI'.static.replaceFunctionArray(self, List);
}


function Mutate(string MutateString, PlayerController Sender)
{
    // don't break the chain
    super.Mutate(MutateString, Sender);

    // only let allowed people
    if (!bAllowExecute(Sender))
        return;

    if (MutateString ~= "zedtime" || MutateString ~= "slomo" || MutateString ~= "sm")
    {
        class'o_Settings'.default.bAllowZedTime = !class'o_Settings'.default.bAllowZedTime;
        sendMsg(Sender, "Zed time status: " $ class'o_Settings'.default.bAllowZedTime);
    }
    else if (MutateString ~= "alltrader" || MutateString ~= "at")
    {
        class'o_Settings'.default.bAllTradersOpen = !class'o_Settings'.default.bAllTradersOpen;
        sendMsg(Sender, "All traders open status: " $ class'o_Settings'.default.bAllTradersOpen);
    }
    else if (MutateString ~= "buyeverywhere")
    {
        class'o_Settings'.default.bBuyEverywhere = !class'o_Settings'.default.bBuyEverywhere;
        sendMsg(Sender, "All traders open status: " $ class'o_Settings'.default.bBuyEverywhere);
    }
    else if (MutateString ~= "saveconfig")
    {
        class'o_Settings'.static.StaticSaveConfig();
        sendMsg(Sender, "Config saved!");
    }
}


// for future use
// function ServerTraveling(string URL, bool bItems)
// {
//     super.ServerTraveling(URL, bItems);
// }


final private function bool bAllowExecute(PlayerController Sender)
{
    local int i;
    local string SenderID;

    if (Sender == none)
        return False;

    SenderID = Sender.GetPlayerIDHash();

    for (i = 0; i < AllowedSteamID.length; i++)
    {
        if (AllowedSteamID[i] ~= SenderID)
            return true;
    }
}


final private function sendMsg(PlayerController Sender, coerce string Msg)
{
    Sender.TeamMessage(Sender.PlayerReplicationInfo, Msg, 'KFPatcher');
}


//=============================================================================
defaultproperties
{
    AllowedSteamID[0]="76561198027407094"   // joabyy
    AllowedSteamID[1]="76561198044316328"   // nikc
    AllowedSteamID[2]="76561198025127722"   // dkanus
    AllowedSteamID[3]="76561198003353515"   // chaos
    AllowedSteamID[4]="76561198019079140"   // bibibi
}