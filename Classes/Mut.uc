class Mut extends Mutator
  config(KFPatcher);


//=============================================================================
struct FunctionRecord
{
  var config string Info, Replace, With;
};
var config array<FunctionRecord> List;


//=============================================================================
event PreBeginPlay()
{
  super.PreBeginPlay();

  // temp hack fix for tosscahs!
  class'stub_Pawn'.default.cashtimer = 0.0f;

  // replacing vanilla functions with ours
  ReplaceFunctions();
}


// 127kb ~80 array items
// server first run - 85ms
// map switch - 45ms 
final private function ReplaceFunctions()
{
  local uFunction A, B;
  local int i;

  // stopwatch(false);

  for (i = 0; i < List.Length; i++)
  {
    // This removes the need to declare variables for every new class we make.
    DynamicLoadObject(class.outer.name $ "." $ Left(List[i].With,InStr(List[i].With,".")), class'class', true);

    A = class'UFunction'.static.CastFunction(FindObject(List[i].Replace, class'function'));
    B = class'UFunction'.static.CastFunction(FindObject(List[i].With, class'function'));

    if (A == none)
    {
      log("> Failed to process " $ List[i].Replace);
      continue;
    }
    if (B == none)
    {
      log("> Failed to process " $ List[i].With);
      continue;
    }

    A.Script = B.Script;
    // ~45-55 ms 
    log("> Replacing: " $ List[i].Replace);
    log("          -> " $ List[i].With);
    // TODO: выровнять
  }

  // stopwatch(true);
}


//=============================================================================
defaultproperties{}