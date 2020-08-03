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

```cpp
EditPackages=COREAPI
EditPackages=KFPatcher
```
