# KF Patcher Project

[**CoreAPI**]: https://github.com/InsultingPros/CoreAPI 'jaja'

This is an attempt to fix most game breaking [bugs](https://shtoyan.github.io/KF1066/#/) and log spam in **Killing Floor 1**. And add some additional features to make several utility mutators obsolete.

## Internals

Config files:

- [KFPatcherSettings.ini](Configs/KFPatcherSettings.ini): contains few gameplay specific settings.
- [KFPatcherFuncs.ini](Configs/KFPatcherFuncs.ini): contains all functions that we replace.

Important classes:

- A simple [mutator](Classes/Mut.uc) which uses [**CoreAPI**] functionality to hook functions.
- `hook` classes that extend the very most child class of our target. For example [hookPC](Classes/hookPC.uc) contains fixes for controllers and it extends [KFPlayerController_Story](https://github.com/InsultingPros/KillingFloor/blob/main/KFStoryGame/Classes/KFPlayerController_Story.uc).

Documentation:

- [To-Do](Docs/To-Do.md).
- [Feature List](Docs/Features.md).

## Building

- Package depends on [**CoreAPI**].
- Use [KFCompileTool](https://github.com/InsultingPros/KFCompileTool) for easy compilation.

```cpp
EditPackages=COREAPI
EditPackages=KFPatcher
```
