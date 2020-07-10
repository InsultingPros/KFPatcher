class Mut extends Mutator
  config(KFPatcher);


//=============================================================================
//                              variables
//=============================================================================

struct FuncNameStruct
{
  var string Replace;
  var string With;
};
var array<FuncNameStruct> List;

// controllers
var stubPC stubPC;
// pawns
var stubPawn stubPawn;
// game info / rule
var stubGT stubGT;
var stubRule stubRule;
// zeds
var stubMonster stubMonster;
var stubZBoss stubZBoss;
var stubZBloat stubZBloat;
var stubZHusk stubZHusk;
var stubZScrake stubZScrake;
var stubZSiren stubZSiren;
var stubFPAvoidArea stubFPAvoidArea;
// weapons
var stubKFWeaponPickup stubKFWeaponPickup;
var stubFragFire stubFragFire;
var stubDualiesFire stubDualiesFire;
var stubDualPistol stubDualPistol;
var stubPipe stubPipe;
var stubNade stubNade;
// various
var stubShopVolume stubShopVolume;
var stubKFTab_BuyMenu stubKFTab_BuyMenu;
var stubKFBuyMenuSaleList stubKFBuyMenuSaleList;

// var stubKFSteamWebApi stubKFSteamWebApi;
// var stubZScrakeCtrl stubZScrakeCtrl;
// var stubPShotgun stubPShotgun;
// var stubSyringe stubSyringe;
// var stubModelSelect stubModelSelect;


//=============================================================================
//                              Logic
//=============================================================================

event PreBeginPlay()
{
  // local function f;
  // local uFunction A;

  super.PreBeginPlay();

  // foreach AllObjects(class'function', f)
  // {
  //   a = none;
  //   log("Found it! Name: " $ string(f));
  //   A = class'UFunction'.static.CastFunction(FindObject(string(f), class'function'));
  //   log(A.FunctionFlags);
  //   // if (string(f) ~= "GetOriginalGroundSpeed")
  // }

  ReplaceFunction(List);

  // set dual pistol DemoReplacement classes, thanks again TWI 
  // class'KFMod.DualDeagle'.default.DemoReplacement = class'KFMod.Deagle';
  // class'KFMod.GoldenDualDeagle'.default.DemoReplacement = class'KFMod.GoldenDeagle';
}


static final function ReplaceFunction(out array<FuncNameStruct> ReplaceArray)
{
  local uFunction A, B;
  local int i;

  for (i = 0; i < ReplaceArray.Length; i++)
  {
    if (ReplaceArray[i].Replace ~= "" || ReplaceArray[i].With ~= "")
      continue;
 
    A = class'UFunction'.static.CastFunction(FindObject(ReplaceArray[i].Replace, class'function'));
    B = class'UFunction'.static.CastFunction(FindObject(ReplaceArray[i].With, class'function'));

    if (A == none || B == none)
    {
      log("> Failed to process " $ ReplaceArray[i].Replace $ "    ---->    " $ ReplaceArray[i].With);
      continue;
    }

    A.Script = B.Script;

    log("> " $ ReplaceArray[i].Replace $ "    ---->    " $ ReplaceArray[i].With);
  }
}


//=============================================================================
//                              Default Properties
//=============================================================================

// ReplaceFunction("Engine.PlayerController.ServerSay", "KFPatcher.Mut.ReplaceTextHook");
// ReplaceFunction("KFMod.KFPlayerController.JoinedAsSpectatorOnly", "KFPatcher.stubPC.JoinedAsSpectatorOnly");
// ReplaceFunction("KFMod.KFPlayerController.BecomeSpectator", "KFPatcher.stubPC.BecomeSpectator");
// ReplaceFunction("KFMod.Syringe.PostBeginPlay", "KFPatcher.stubSyringe.PostBeginPlay");

defaultproperties
{
  // ======================================= KFGameType =======================================
  // Allows players to move after game ends
  List[0]=(Replace="KFMod.KFGameType.CheckEndGame",With="KFPatcher.stubGT.CheckEndGame")
  // disable gametype tick that calls zed time
  List[1]=(Replace="KFMod.KFGameType.Tick",With="KFPatcher.stubGT.Tick")
  // main function that controlls zed time
  List[2]=(Replace="KFMod.KFGameType.DramaticEvent",With="KFPatcher.stubGT.DramaticEvent")
  // altered so it won't call zed time
  List[3]=(Replace="KFMod.KFGameType.DoBossDeath",With="KFPatcher.stubGT.DoBossDeath")
  // no more late joiner text shit
  List[4]=(Replace="KFMod.KFGameType.PreLogin",With="KFPatcher.stubGT.PreLogin")
  // fix killzeds log spam
  List[5]=(Replace="KFMod.KFGameType.KillZeds",With="KFPatcher.stubGT.KillZeds")
  // fix gamelength from cmdline, log monstercollection
  List[6]=(Replace="KFMod.KFGameType.InitGame",With="KFPatcher.stubGT.InitGame")
  // camera fix after pat kills
  List[7]=(Replace="KFMod.KFGameType.MatchInProgress.Timer",With="KFPatcher.stubGT.newMatchInProgress.nTimer")
  // no more wave switch lags
  List[8]=(Replace="KFMod.KFGameType.MatchInProgress.CloseShops",With="KFPatcher.stubGT.newMatchInProgress.nCloseShops")

  // ======================================= GameRule =======================================
  // no more game end when players leave the lobby
  List[9]=(Replace="Engine.GameRules.CheckEndGame",With="KFPatcher.stubRule.CheckEndGame")

  // ======================================= Pawns =======================================
  // fix for dosh exploits
  List[10]=(Replace="KFMod.KFPawn.TossCash",With="KFPatcher.stubPawn.TossCash")
  List[11]=(Replace="KFMod.KFPawn.GetSound",With="KFPatcher.stubPawn.GetSound")
  List[45]=(Replace="KFMod.KFPawn.ThrowGrenade",With="KFPatcher.stubPawn.ThrowGrenade")
  

  // ======================================= Controllers =======================================
  // no more 'you will become %perk' spam
  List[12]=(Replace="KFMod.KFPlayerController.SelectVeterancy",With="KFPatcher.stubPC.SelectVeterancy")

  // ======================================= Weapons =======================================

  // fix for nade exploits
  List[13]=(Replace="KFMod.FragFire.DoFireEffect",With="KFPatcher.stubFragFire.DoFireEffect")
  // fix sounds array errors
  List[14]=(Replace="KFMod.Nade.Explode",With="KFPatcher.stubNade.Explode")

  // fix accessed none Inventory for destroyed weapon pickups
  List[15]=(Replace="KFMod.KFWeaponPickup.Destroyed",With="KFPatcher.stubKFWeaponPickup.Destroyed")

  // fix accessed none IgnoreActors ! and replace all copy paste code with 1
  List[16]=(Replace="KFMod.MK23Fire.DoTrace",With="KFPatcher.stubDualiesFire.DoTrace")
  List[17]=(Replace="KFMod.DualMK23Fire.DoTrace",With="KFPatcher.stubDualiesFire.DoTrace")
  List[18]=(Replace="KFMod.DeagleFire.DoTrace",With="KFPatcher.stubDualiesFire.DoTrace")
  List[19]=(Replace="KFMod.DualDeagleFire.DoTrace",With="KFPatcher.stubDualiesFire.DoTrace")
  List[20]=(Replace="KFMod.Magnum44Fire.DoTrace",With="KFPatcher.stubDualiesFire.DoTrace")
  List[21]=(Replace="KFMod.Dual44MagnumFire.DoTrace",With="KFPatcher.stubDualiesFire.DoTrace")

  // fix accessed none from DropFrom and replace all copy paste code with 1
  List[22]=(Replace="KFMod.DualDeagle.DropFrom",With="KFPatcher.stubDualPistol.DropFrom")

  // fix uber damage exlpoit
  List[23]=(Replace="KFMod.PipeBombProjectile.TakeDamage",With="KFPatcher.stubPipe.TakeDamage")
  // no detonation on dead players, npc
  List[24]=(Replace="KFMod.PipeBombProjectile.Timer",With="KFPatcher.stubPipe.Timer")
  // fix sounds array errors
  List[25]=(Replace="KFMod.PipeBombProjectile.Explode",With="KFPatcher.stubPipe.Explode")
  List[26]=(Replace="KFMod.PipeBombProjectile.PreloadAssets",With="KFPatcher.stubPipe.PreloadAssets")
  List[27]=(Replace="KFMod.PipeBombProjectile.UnloadAssets",With="KFPatcher.stubPipe.UnloadAssets")

  // ======================================= Zeds =======================================

  // Husks, fix none calls for toggleaux function
  List[28]=(Replace="KFChar.ZombieHusk_HALLOWEEN.SpawnTwoShots",With="KFPatcher.stubZHusk.SpawnTwoShots")
  List[29]=(Replace="KFChar.ZombieHusk.SpawnTwoShots",With="KFPatcher.stubZHusk.SpawnTwoShots")

  // sirens, fixed instigator call in takedamage and no more damage while dead / decapped
  List[30]=(Replace="KFChar.ZombieSiren.SpawnTwoShots",With="KFPatcher.stubZSiren.SpawnTwoShots")
  List[31]=(Replace="KFChar.ZombieSiren.HurtRadius",With="KFPatcher.stubZSiren.HurtRadius")
  
  List[32]=(Replace="KFMod.KFMonster.TakeDamage",With="KFPatcher.stubMonster.TakeDamage")
  List[33]=(Replace="KFChar.ZombieBloat.SpawnTwoShots",With="KFPatcher.stubZBloat.SpawnTwoShots")

  // do not let fp's to spin
  List[34]=(Replace="KFMod.FleshPoundAvoidArea.Touch",With="KFPatcher.stubFPAvoidArea.Touch")
  List[35]=(Replace="KFMod.FleshPoundAvoidArea.RelevantTo",With="KFPatcher.stubFPAvoidArea.RelevantTo")

  // no burn skin
  List[36]=(Replace="KFChar.ZombieBoss.FireMissile.AnimEnd",With="KFPatcher.stubZBoss.nFireMissile.AnimEnd")

  //////////////////////
  List[37]=(Replace="KFGui.KFTab_BuyMenu.IsLocked",With="KFPatcher.stubKFTab_BuyMenu.IsLocked")
  List[38]=(Replace="KFGui.KFTab_BuyMenu.SetInfoText",With="KFPatcher.stubKFTab_BuyMenu.SetInfoText")

  List[39]=(Replace="KFGui.KFBuyMenuSaleList.UpdateList",With="KFPatcher.stubKFBuyMenuSaleList.UpdateList")
  List[40]=(Replace="KFGui.KFBuyMenuSaleList.IndexChanged",With="KFPatcher.stubKFBuyMenuSaleList.IndexChanged")

  // List[47]=(Replace="KFMod.KFPawn.ServerBuyWeapon",With="KFPatcher.stubPawn.ServerBuyWeapon")

  // edit server, player info
  // List[20]=(Replace="Engine.GameInfo.GetServerPlayers",With="KFPatcher.stubGT.GetServerPlayers")

  // ======================================= Shop Volume =======================================
  // fix accessed none MyTrader
  List[41]=(Replace="KFMod.ShopVolume.Touch",With="KFPatcher.stubShopVolume.Touch")
  List[42]=(Replace="KFMod.ShopVolume.UnTouch",With="KFPatcher.stubShopVolume.UnTouch")
  List[43]=(Replace="KFMod.ShopVolume.UsedBy",With="KFPatcher.stubShopVolume.UsedBy")
  // fix bound check for Touching
  List[44]=(Replace="KFMod.ShopVolume.BootPlayers",With="KFPatcher.stubShopVolume.BootPlayers")

  // List[23]=(Replace="KFChar.ZombieBoss.UsedBy",With="KFPatcher.stubZBoss.UsedBy")

  // List[21]=(Replace="KFMod.KFSteamWebApi.Timer",With="KFPatcher.stubKFSteamWebApi.Timer")
  // List[22]=(Replace="KFMod.KFSteamWebApi.HasAchievement",With="KFPatcher.stubKFSteamWebApi.HasAchievement")

  // List[21]=(Replace="Engine.GameInfo.GetServerDetails",With="KFPatcher.stubGT.GetServerDetails")

  // List[20]=(Replace="KFMod.KFMonster.GetOriginalGroundSpeed",With="KFPatcher.stubZScrake.GetOriginalGroundSpeed")
  // List[21]=(Replace="KFChar.ZombieScrake.RunningState.EndState",With="KFPatcher.stubZScrake.EndState")
  // List[22]=(Replace="KFChar.SawZombieController.DoorBashing.EndState",With="KFPatcher.stubZScrakeCtrl.EndState")

  // List[23]=(Replace="KFMod.ShotgunBullet.ProcessTouch",With="KFPatcher.stubPShotgun.ProcessTouch")
  // List[21]=(Replace="KFChar.ZombieScrake.SawingLoop.GetOriginalGroundSpeed",With="KFPatcher.stubFPAvoidArea.GetSpeedSawing")
}