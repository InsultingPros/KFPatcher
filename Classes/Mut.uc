/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/KFPatcher
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class Mut extends Mutator
    config(KFPatcherFuncs);


//=============================================================================
struct FunctionRecord {
    var string Info;    // why we replace this function
    var string Replace; // original function with format "package.class.target_function"
    var string With;    // replacement function with format "class.new_function"
};
var private config array<FunctionRecord> List;

var private UFunctionCast FunctionCaster;

// only allowed players can use mutate commands
var private array<string> AllowedSteamID;

// used in level cleanup
var private transient bool bCleanedUp;
struct sFunctionBackup {
    var private uFunction originalFunction;
    var private array<byte> originalScript;
};
var private transient array<sFunctionBackup> ProcessedFunctions;

//=============================================================================
event PreBeginPlay() {
    super.PreBeginPlay();

    // TMP!!! hack fix for tosscash!
    class'hookPawn'.default.cashtimer = 0.0f;

    // replacing vanilla functions with ours
    ReplaceFunctionArray(List);
}

// function replacement
private final function ReplaceFunctionArray(array<FunctionRecord> functionList) {
    local int idx;

    for (idx = 0; idx < functionList.length; idx++) {
        ReplaceFunction(functionList[idx].Replace, functionList[idx].With);
    }
}

private final function ReplaceFunction(string Replace, string With) {
    local uFunction A, B;
    local sFunctionBackup functionBackup;

    // This removes the need to declare variables for every new class we make
    // vanilla classes or 3rd party mutator classes
    DynamicLoadObject(GetClassName(Replace), class'class', true);
    // classes with our edited functions
    // `caller.class.outer.name` returns caller's package name
    DynamicLoadObject(self.class.outer.name $ "." $ Left(With, InStr(With,".")), class'class', true);

    A = default.FunctionCaster.Cast(function(FindObject(Replace, class'function')));
    B = default.FunctionCaster.Cast(function(FindObject(With, class'function')));

    if (A == none) {
        warn("Failed to process " $ Replace);
        return;
    }
    if (B == none) {
        warn("Failed to process " $ With);
        return;
    }

    // create a backup
    functionBackup.originalFunction = A;
    functionBackup.originalScript = A.Script;
    ProcessedFunctions[ProcessedFunctions.length] = functionBackup;

    // switch functions
    A.Script = B.Script;

    log("> Processing " $ Replace $ "    ---->    " $ With);
}

// get the "package + dot + class" string for DynamicLoadObject()
private final function string GetClassName(string input) {
    local array<string> parts;

    // create an array
    split(input, ".", parts);

    // state functions
    if (parts.length == 4) {
        ReplaceText(input, "." $ parts[2], "");
        ReplaceText(input, "." $ parts[3], "");
    }
    // non-state functions
    else {
        ReplaceText(input, "." $ parts[2], "");
    }

    return input;
}

// cleanup
function ServerTraveling(string URL, bool bItems) {
    SafeCleanup();
    super.ServerTraveling(URL, bItems);
}

function Destroyed() {
    SafeCleanup();
    super.Destroyed();
}

private final function SafeCleanup() {
    local int i;

    if (bCleanedUp || ProcessedFunctions.length == 0) {
        return;
    }
    for (i = 0; i < ProcessedFunctions.length; i++) {
        ProcessedFunctions[i].originalFunction.Script = ProcessedFunctions[i].originalScript;
    }
    bCleanedUp = true;
    warn("All functions reverted to original state!");
}

//=============================================================================
defaultproperties {
    GroupName="KF-DarkMagic"
    FriendlyName="KF1 Patcher"
    Description="Directly replace TWI's bullshit functions for easy fixes (or trolls)."

    begin object class=UFunctionCast name=SubFunctionCaster
    end object
    FunctionCaster=SubFunctionCaster
}