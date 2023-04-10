/*
 * Author       : Eliot
 * Home Repo    : https://github.com/EliotVU/UnrealScript-Unflect
 * License      : https://opensource.org/license/mit/
*/
class UStructCast extends Object;

var UStruct NativeType;

final function UStruct Cast(/*Core.Struct*/Object type)
{
    super(TypeCast).NativeCast(type);
    return NativeType;
}