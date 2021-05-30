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

  // replacing vanilla functions with ours
  ReplaceFunctions();
}


final function ReplaceFunctions()
{
  local uFunction A, B;
  local int i;

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
    log("> Processing: " $ List[i].Replace $ "    ---->    " $ List[i].With);
  }
}


//=============================================================================
defaultproperties{}