/*
 * Author       : Eliot
 * Home Repo    : https://github.com/EliotVU/UnrealScript-Unflect
 * License      : https://opensource.org/license/mit/
*/
class UClass extends UState within Package;

var int				    ClassFlags;
var int					ClassUnique;
var Guid				ClassGuid;
var UClass				ClassWithin;
var name				ClassConfigName;
var array<struct RepRecord {
    var UProperty       Property;
    var int             Index;
}>	                    ClassReps;
var array<UField>		NetFields;
var array<struct Dependency {
    var UClass		    Class;
    var int		        Deep;
    var int		        ScriptTextCRC;
}>                      Dependencies;
var array<name>		    PackageImports;
var array<byte>		    Defaults;
var array<name>		    HideCategories;
var array<name>         DependentOn;

var string				DefaultPropText;