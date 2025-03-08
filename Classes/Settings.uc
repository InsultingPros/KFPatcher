/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class Settings extends object
    config(KFPatcherSettings);


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

// dosh
var() config float fDoshThrowDelay;
var() config int iDoshThrowMinAmount;