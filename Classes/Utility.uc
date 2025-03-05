/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class Utility extends object;


// colors and tags, maybe later I will convert this to a config array
struct ColorStruct
{
    var string Name;           // color name, for comfort
    var string Tag;            // color tag
    var Color Color;           // RGBA values
};
var array<ColorStruct> ColorList;   // color list


// converts color tags to colors
final static function string ParseTags(out string input)
{
    local int i;
    local array<ColorStruct> Temp;
    local string strTemp;

    Temp = default.ColorList;
    for (i=0; i<Temp.Length; i++)
    {
        strTemp = class'GameInfo'.static.MakeColorCode(Temp[i].Color);
        ReplaceText(input, Temp[i].Tag, strTemp);
    }
    return input;
}


// removes color tags
final static function string StripTags(out string input)
{
    local int i;

    for (i=0; i<default.ColorList.Length; i++)
    {
        ReplaceText(input, default.ColorList[i].Tag, "");
    }
    return input;
}


// removes colors from a string
final static function string StripColor(out string s)
{
    local int p;

    p = InStr(s,chr(27));
    while ( p>=0 )
    {
        s = left(s,p)$mid(S,p+4);
        p = InStr(s,Chr(27));
    }
    return s;
}


final static function string ParsePlayerName(PlayerController pc)
{
    if (pc != none || pc.playerReplicationInfo != none)
        return "^b" $ StripTags(pc.playerReplicationInfo.PlayerName) $ "^w";
}


final static function SendMessage(PlayerController pc, coerce string msg, bool bAlreadyColored)
{
    if (pc == none || msg == "")
        return;

    if (!bAlreadyColored)
        msg = ParseTags(msg);

    pc.teamMessage(none, msg, 'KFPatcher');
}


// broadcasts a global message
final static function BroadcastText(levelInfo level, string message, optional bool bBroadcastToCenter)
{
    local Controller C;
    local PlayerController PC;

    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        // only proceed on PlayerControllers, but skip bots.
        PC = PlayerController(C);
        if (PC == none || KFFriendlyAI(C) != none)
            continue;

        // Remove color tags for WebAdmin and Log.
        if (MessagingSpectator(C) != none)
        {
            message = StripColor(message);
            // log(message, class.Outer.Name);
        }
        else
            message = ParseTags(message);

        // broadcast text to the center like admin say. WebAdmin ignores this so make it use the usual TeamMessage.
        if (bBroadcastToCenter && MessagingSpectator(C) == none)
        {
            PC.ClearProgressMessages();
            PC.SetProgressTime(4);
            PC.SetProgressMessage(0, message, class'Canvas'.static.MakeColor(255,255,255));
        }
        else
            PC.TeamMessage(none, message, 'Say');
    }
}


final static function ShowPatHP(PlayerController pc, ZombieBoss pat)
{
    SendMessage(pc, "^wThe ^b" $ pat.MenuName $ "^w's health is ^r" $ pat.health $ " ^w/ ^r" $ pat.HealthMax $ "^w. Syringes used - ^r " $ pat.SyringeCount $ "^w.", false);
}


// register all available traders to the game shop list
final static function RegisterAllTraders(Actor game, out array<ShopVolume> ShopList, bool bUsingObjectiveMode) {
    local ShopVolume SH;

    foreach game.AllActors(class'ShopVolume', SH) {
        if (SH == none) {
            continue;
        }
        // open everything
        if (class'Settings'.default.bAllTradersOpen) {
            SH.bAlwaysClosed = false;
            SH.bAlwaysEnabled = true;
        }
        // now fill the array ;d
        if (!SH.bObjectiveModeOnly || bUsingObjectiveMode) {
            ShopList[ShopList.Length] = SH;
        }
    }

    if (class'Settings'.default.bAllTradersOpen) {
        log("> bAllTradersOpen = true. All traders will be open!");
    }
}


defaultproperties
{
    ColorList(00)=(Name="Red",tag="^r",Color=(B=0,G=0,R=255,A=0))
    ColorList(01)=(Name="Orange",tag="^o",Color=(B=0,G=77,R=200,A=0))
    ColorList(02)=(Name="Yellow",tag="^y",Color=(B=0,G=255,R=255,A=0))
    ColorList(03)=(Name="Green",tag="^g",Color=(B=0,G=255,R=0,A=0))
    ColorList(04)=(Name="Blue",tag="^b",Color=(B=200,G=100,R=0,A=0))
    ColorList(05)=(Name="Neon Blue",tag="^nb",Color=(B=200,G=150,R=0,A=0))
    ColorList(06)=(Name="Cyan",tag="^c",Color=(B=255,G=255,R=0,A=0))
    ColorList(07)=(Name="Violet",tag="^v",Color=(B=139,G=0,R=255,A=0))
    ColorList(08)=(Name="Pink",tag="^p",Color=(B=203,G=192,R=255,A=0))
    ColorList(09)=(Name="Purple",tag="^p",Color=(B=128,G=0,R=128,A=0))
    ColorList(10)=(Name="White",tag="^w",Color=(B=255,G=255,R=255,A=0))
    ColorList(11)=(Name="Gray",tag="$g",Color=(B=96,G=96,R=96,A=0))
    ColorList(12)=(Name="ScrN 1",tag="^0",Color=(B=1,G=1,R=1,A=0))
    ColorList(13)=(Name="ScrN 2",tag="^1",Color=(B=1,G=1,R=200,A=0))
    ColorList(14)=(Name="ScrN 3",tag="^2",Color=(B=1,G=200,R=1,A=0))
    ColorList(15)=(Name="ScrN 4",tag="^3",Color=(B=1,G=200,R=200,A=0))
    ColorList(16)=(Name="ScrN 5",tag="^4",Color=(B=1,G=1,R=255,A=0))
    ColorList(17)=(Name="ScrN 6",tag="^5",Color=(B=255,G=255,R=1,A=0))
    ColorList(18)=(Name="ScrN 7",tag="^6",Color=(B=200,G=1,R=200,A=0))
    ColorList(19)=(Name="ScrN 8",tag="^7",Color=(B=200,G=200,R=200,A=0))
    ColorList(20)=(Name="ScrN 9",tag="^8",Color=(B=0,G=127,R=255,A=0))
    ColorList(21)=(Name="ScrN 10",tag="^9",Color=(B=128,G=128,R=128,A=0))
    // ColorList=(Name="ScrN 11",tag="^w$",Color=(B=,G=,R=,A=0)"255,255,255")
    // ColorList=(Name="ScrN 12",tag="^r$",Color=(B=,G=,R=,A=0)"255,1,1")
    // ColorList=(Name="ScrN 13",tag="^g$",Color=(B=,G=,R=,A=0)"1,255,1")
    // ColorList=(Name="ScrN 14",tag="^b$",Color=(B=,G=,R=,A=0)"1,1,255")
    // ColorList=(Name="ScrN 15",tag="^y$",Color=(B=,G=,R=,A=0)"255,255,1")
    // ColorList=(Name="ScrN 16",tag="^c$",Color=(B=,G=,R=,A=0)"1,255,255")
    // ColorList=(Name="ScrN 17",tag="^o$",Color=(B=,G=,R=,A=0)"255,140,1")
    // ColorList=(Name="ScrN 18",tag="^u$",Color=(B=,G=,R=,A=0)"255,20,147")
    // ColorList=(Name="ScrN 19",tag="^s$",Color=(B=,G=,R=,A=0)"1,192,255")
    // ColorList=(Name="ScrN 20",tag="^n$",Color=(B=,G=,R=,A=0)"139,69,19")
    // ColorList=(Name="ScrN 21",tag="^w$",Color=(B=,G=,R=,A=0)"112,138,144")
    // ColorList=(Name="ScrN 22",tag="^R$",Color=(B=,G=,R=,A=0)"132,1,1")
    // ColorList=(Name="ScrN 23",tag="^G$",Color=(B=,G=,R=,A=0)"1,132,1")
    // ColorList=(Name="ScrN 24",tag="^B$",Color=(B=,G=,R=,A=0)"1,1,132")
    // ColorList=(Name="ScrN 25",tag="^y$",Color=(B=,G=,R=,A=0)"255,192,1")
    // ColorList=(Name="ScrN 26",tag="^c$",Color=(B=,G=,R=,A=0)"1,160,192")
    // ColorList=(Name="ScrN 27",tag="^O$",Color=(B=,G=,R=,A=0)"255,69,1")
    // ColorList=(Name="ScrN 28",tag="^U$",Color=(B=,G=,R=,A=0)"160,32,240")
    // ColorList=(Name="ScrN 29",tag="^s$",Color=(B=,G=,R=,A=0)"65,105,225")
    // ColorList=(Name="ScrN 30",tag="^n$",Color=(B=,G=,R=,A=0)"80,40,20")
    // ColorList=(Name="Misc 1",tag="%1$",Color=(B=,G=,R=,A=0)"109,64,255")
    // ColorList=(Name="Misc 2",tag="%2$",Color=(B=,G=,R=,A=0)"204,64,255")
    // ColorList=(Name="Misc 3",tag="%3$",Color=(B=,G=,R=,A=0)"64,166,25)
}