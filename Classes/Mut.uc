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
var config array<FuncNameStruct> List;

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
var stubSyringe stubSyringe;
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

  ReplaceFunction(default.List);
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

// ("Engine.PlayerController.ServerSay", "KFPatcher.Mut.ReplaceTextHook");
// ("KFMod.KFPlayerController.JoinedAsSpectatorOnly", "KFPatcher.stubPC.JoinedAsSpectatorOnly");
// ("KFMod.KFPlayerController.BecomeSpectator", "KFPatcher.stubPC.BecomeSpectator");

defaultproperties{}