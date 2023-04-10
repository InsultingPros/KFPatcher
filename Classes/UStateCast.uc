/*
 * Author       : Eliot
 * Home Repo    : https://github.com/EliotVU/UnrealScript-Unflect
 * License      : https://opensource.org/license/mit/
*/
class UStateCast extends Object;

var UState NativeType;

final function UState Cast(State type)
{
    super(TypeCast).NativeCast(type);
    return NativeType;
}