class Mut extends Mutator;


struct FuncNameStruct
{
  var string Replace;
  var string With;
};
var array<FuncNameStruct> List;

var stubPC stubPC;
var stubPawn stubPawn;
var stubGT stubGT;
var stubRule stubRule;
var stubFragFire stubFragFire;
var stubZHusk stubZHusk;
var stubZSiren stubZSiren;
var stubZBloat stubZBloat;
var stubZScrake stubZScrake;
var stubMonster stubMonster;
var stubFPAvoidArea stubFPAvoidArea;
// var stubZScrakeCtrl stubZScrakeCtrl;
// var stubPShotgun stubPShotgun;
// var stubSyringe stubSyringe;
// var stubModelSelect stubModelSelect;


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

  // TEST
  // ReplaceState("KFChar.ZombieScrake.RunningState", "KFPatcher.stubZScrake.RunningState");

  // yup, it's not set somehow, fucking TWI
  class'KFChar.ZombieHusk_HALLOWEEN'.default.HuskFireProjClass = class'KFChar.HuskFireProjectile_HALLOWEEN';
}


// static final function ReplaceState(string replace, string with)
// {
//   local UState A, B;
//   // local uFunction fA, fB;

//   A = class'UState'.static.CastState(FindObject(replace, class'state'));
//   B = class'UState'.static.CastState(FindObject(with, class'state'));

//   if (A == none || B == none)
//   {
//     log("> Failed to process");
//     return;
//   }

//   A.Script = B.Script;

//   // log("> " $ ReplaceArray[i].Replace $ "    ---->    " $ ReplaceArray[i].With);
// }


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


// ReplaceFunction("Core.Object.ReplaceText", "KFPatcher.Mut.ReplaceTextHook");
// ReplaceFunction("Core.Object.ReplaceText", "KFPatcher.stubPC.ReplaceTextHook");
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

  // ======================================= GameRule =======================================
  // no more game end when players leave the lobby
  List[5]=(Replace="Engine.GameRules.CheckEndGame",With="KFPatcher.stubRule.CheckEndGame")

  // ======================================= Pawns =======================================
  // fix for dosh exploits
  List[6]=(Replace="KFMod.KFPawn.TossCash",With="KFPatcher.stubPawn.TossCash")
  List[7]=(Replace="KFMod.KFPawn.GetSound",With="KFPatcher.stubPawn.GetSound")

  // ======================================= Controllers =======================================
  // no more 'you will become %perk' spam
  List[8]=(Replace="KFMod.KFPlayerController.SelectVeterancy",With="KFPatcher.stubPC.SelectVeterancy")
  List[14]=(Replace="KFMod.KFPlayerController.ClientWeaponSpawned",With="KFPatcher.stubPC.ClientWeaponSpawned")
  List[15]=(Replace="KFMod.KFPlayerController.ClientWeaponDestroyed",With="KFPatcher.stubPC.ClientWeaponDestroyed")

  // ======================================= Weapons =======================================
  // fix for nade exploits
  List[9]=(Replace="KFMod.FragFire.DoFireEffect",With="KFPatcher.stubFragFire.DoFireEffect")

  // ======================================= Zeds =======================================
  // Husks, fix none calls for toggleaux function
  List[10]=(Replace="KFChar.ZombieHusk_HALLOWEEN.SpawnTwoShots",With="KFPatcher.stubZHusk.SpawnTwoShots")
  List[11]=(Replace="KFChar.ZombieHusk.SpawnTwoShots",With="KFPatcher.stubZHusk.SpawnTwoShots")
  // sirens, fixed instigator call in takedamage and no more damage while dead / decapped
  List[12]=(Replace="KFChar.ZombieSiren.SpawnTwoShots",With="KFPatcher.stubZSiren.SpawnTwoShots")
  List[13]=(Replace="KFChar.ZombieSiren.HurtRadius",With="KFPatcher.stubZSiren.HurtRadius")
  
  List[16]=(Replace="KFMod.KFMonster.TakeDamage",With="KFPatcher.stubMonster.TakeDamage")
  List[17]=(Replace="KFChar.ZombieBloat.SpawnTwoShots",With="KFPatcher.stubZBloat.SpawnTwoShots")

  List[18]=(Replace="KFMod.FleshPoundAvoidArea.Touch",With="KFPatcher.stubFPAvoidArea.Touch")
  List[19]=(Replace="KFMod.FleshPoundAvoidArea.RelevantTo",With="KFPatcher.stubFPAvoidArea.RelevantTo")

  // edit server, player info
  List[20]=(Replace="Engine.GameInfo.GetServerPlayers",With="KFPatcher.stubGT.GetServerPlayers")
  // List[21]=(Replace="Engine.GameInfo.GetServerDetails",With="KFPatcher.stubGT.GetServerDetails")

  // List[20]=(Replace="KFMod.KFMonster.GetOriginalGroundSpeed",With="KFPatcher.stubZScrake.GetOriginalGroundSpeed")
  // List[21]=(Replace="KFChar.SawZombieController.WaitForAnim.EndState",With="KFPatcher.stubZScrakeCtrl.EndState")
  // List[22]=(Replace="KFChar.SawZombieController.DoorBashing.EndState",With="KFPatcher.stubZScrakeCtrl.EndState")

  // List[23]=(Replace="KFMod.ShotgunBullet.ProcessTouch",With="KFPatcher.stubPShotgun.ProcessTouch")
  // List[21]=(Replace="KFChar.ZombieScrake.SawingLoop.GetOriginalGroundSpeed",With="KFPatcher.stubFPAvoidArea.GetSpeedSawing")
}