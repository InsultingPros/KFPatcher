# KF Patcher Project

[**CoreAPI**]: https://github.com/InsultingPros/CoreAPI 'jaja'

This is an attempt to fix most game breaking bugs and log spam in **Killing Floor 1**. And some additional features to make some utility mutators 'OBSOLOTE' :innocent:

You can check the [To-Do](Docs/To-Do.md) and [Feature List](Docs/Features.md) for more details.

## Internals

Config files:

- [KFPatcherSettings.ini](Configs/KFPatcherSettings.ini): contains few gameplay specific settings.
- [KFPatcherFuncs.ini](Configs/KFPatcherFuncs.ini): contains all functions that we replace.

Important classes:

- A simple [mutator](Classes/Mut.uc) which uses [**CoreAPI**] functionality to hook functions.
- `repl_` classes that extend the very most child class of our target. For example [repl_PC](Classes/repl_PC.uc) contains fixes for controllers and it extends [KFPlayerController_Story](https://github.com/InsultingPros/KillingFloor/blob/main/KFStoryGame/Classes/KFPlayerController_Story.uc).

## Building

- Package depends on [**CoreAPI**].
- Use [KFCompileTool](https://github.com/InsultingPros/KFCompileTool) for easy compilation.

```cpp
EditPackages=COREAPI
EditPackages=KFPatcher
```
