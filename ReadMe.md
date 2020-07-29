# KF Patcher Project

## Goal

This is an attempt to fix most game breaking bugs and log spam in **Killing Floor 1**. And some additional features to make some utility mutators 'OBSOLOTE' :innocent:

## Internals

At the moment of 29.07.2020 consists of 1 package and 1 **config** file that allows you to choose what fixes to enable.

Package contains:
- A simple *mutator* which uses [**CoreAPI**](https://github.com/Insulting-Pros/CoreAPI) functionality to hooks functions.
- *stub*'s that extend the very most child class of target. E.G. *stubPC* contains fixes for controllers and it extends *KFPlayerController_Story*.


## Dependancies

At the moment of 29.07.2020 only from **CoreAPI**.
For compilation copy-paste to *EditPackages*

```
EditPackages=COREAPI
EditPackages=KFPatcher
```

## To-Do

#### Zeds

##### Pat

- [ ] Fix instand rockets at your face and other NOT smooth animations-actions.

#### GamePlay

- [ ] Fix the whole projectile class and end teamkilling bullshit.
- [ ] Add configurable server info.
- [ ] Polish player info.
- [ ] Remake player counting functions for native faked feature.