class Mut extends Mutator;


struct FuncNameStruct
{
  var string Replace;
  var string With;
};
var array<FuncNameStruct> FList;

var stubPC stubPC;
var stubPawn stubPawn;
var stubGT stubGT;
var stubRule stubRule;
var stubFrag stubFrag;
var stubZHusk stubZHusk;
var stubZSiren stubZSiren;
// var stubSyringe stubSyringe;
// var stubModelSelect stubModelSelect;


event PreBeginPlay()
{
  local int i;

  super.PreBeginPlay();

  for (i = 0; i < FList.Length; i++)
  {
    if (FList[i].Replace ~= "" || FList[i].With ~= "")
      continue;
    ReplaceFunction(FList[i].Replace, FList[i].With);
  }

  class'KFChar.ZombieHusk_HALLOWEEN'.default.HuskFireProjClass = class'KFChar.HuskFireProjectile_HALLOWEEN';
}


static final function bool ReplaceFunction(string Replace, string With)
{
  local uFunction A, B;

  A = class'UFunction'.static.CastFunction(FindObject(Replace, class'Function'));
  B = class'UFunction'.static.CastFunction(FindObject(With, class'Function'));

  if(A == None || B == None)
  {
    log("KF Patcher: wasn't able to hook " $ Replace $ ". Some of the string arguments are wrong!");
    return false;
  }

  A.Script = B.Script;

  log("KF Patcher: function " $ Replace $ " replaced with " $ With);
  return true;
}


function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
  // if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
  //   super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
  // else
  //   super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
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
  FList[0]=(Replace="KFMod.KFGameType.CheckEndGame",With="KFPatcher.stubGT.CheckEndGame")
  // disable gametype tick that calls zed time
  FList[1]=(Replace="KFMod.KFGameType.Tick",With="KFPatcher.stubGT.Tick")
  // main function that controlls zed time
  FList[2]=(Replace="KFMod.KFGameType.DramaticEvent",With="KFPatcher.stubGT.DramaticEvent")
  // altered so it won't call zed time
  FList[3]=(Replace="KFMod.KFGameType.DoBossDeath",With="KFPatcher.stubGT.DoBossDeath")
  // no more late joiner text shit
  FList[4]=(Replace="KFMod.KFGameType.PreLogin",With="KFPatcher.stubGT.PreLogin")

  // ======================================= GameRule =======================================
  // no more game end when players leave the lobby
  FList[5]=(Replace="Engine.GameRules.CheckEndGame",With="KFPatcher.stubRule.CheckEndGame")

  // ======================================= Pawns =======================================
  // fix for dosh exploits
  FList[6]=(Replace="KFMod.KFPawn.TossCash",With="KFPatcher.stubPawn.TossCash")

  // ======================================= Controllers =======================================
  // no more 'you will become %perk' spam
  FList[7]=(Replace="KFMod.KFPlayerController.SelectVeterancy",With="KFPatcher.stubPC.SelectVeterancy")

  // ======================================= Weapons =======================================
  // fix for nade exploits
  FList[8]=(Replace="KFMod.FragFire.DoFireEffect",With="KFPatcher.stubFrag.DoFireEffect")

  // ======================================= Zeds =======================================
  // Husks, fix none calls for toggleaux function
  FList[9]=(Replace="KFChar.ZombieHusk_HALLOWEEN.SpawnTwoShots",With="KFPatcher.stubZHusk.SpawnTwoShots")
  FList[10]=(Replace="KFChar.ZombieHusk.SpawnTwoShots",With="KFPatcher.stubZHusk.SpawnTwoShots")
  // sirens, fixed instigator call in takedamage and no more damage while dead / decapped
  FList[11]=(Replace="KFChar.ZombieSiren.SpawnTwoShots",With="KFPatcher.stubZSiren.SpawnTwoShots")
  FList[12]=(Replace="KFChar.ZombieSiren.HurtRadius",With="KFPatcher.stubZSiren.HurtRadius")
  FList[13]=(Replace="",With="")
  FList[14]=(Replace="",With="")
  FList[15]=(Replace="",With="")
  FList[16]=(Replace="",With="")
}