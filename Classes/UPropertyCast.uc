/*
 * Author       : Eliot
 * Home Repo    : https://github.com/EliotVU/UnrealScript-Unflect
 * License      : https://opensource.org/license/mit/
*/
class UPropertyCast extends Object;

var UProperty NativeType;

final function UProperty Cast(Property type)
{
    super(TypeCast).NativeCast(type);
    return NativeType;
}