class o_Settings extends object
  config(KFPatcher);


var() config bool bBuyEverywhere;

// player info
var() config string sAlive, sDead, sSpectator, sReady, sNotReady, sAwaiting;
var() config string sTagHP, sTagKills;
var() config bool bShowPerk;
var() config float fRefreshTime;

// zedtime
var() config bool bAllowZedTime;

// all traders
var() config bool bAllTradersOpen;
var() config string bAllTradersMessage;


defaultproperties{}