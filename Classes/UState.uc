/*
 * Author       : Eliot
 * Home Repo    : https://github.com/EliotVU/UnrealScript-Unflect
 * License      : https://opensource.org/license/mit/
*/
class UState extends UStruct
    dependson(Unflect);

var Unflect.Int64   ProbeMask;
var Unflect.Int64   IgnoreMask;
var int             StateFlags;
var Unflect.Int16   LabelTableOffset;
var UField          VfHash[256];