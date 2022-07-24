> [go back to README](../ReadMe.md)

# Implemented Features and Fixes

## KFGameType

- Print **Pat** health after a team wipe.
- Allow players move after team wipe / win.
- Zed time switch. Much more efficent one than you can imagine.
- No more latejoiner text.
- Fixed `KillZeds` command. Now it wont break zed spawns and spam in logs.
- You can set `GameLength` from cmdline.
- `Monstercollection` logs itself. So you can easily know what seasonal zeds are on.
- Player cameras wont break after you kill the pat.
- Pre-wave garbage collection is disabled (no lags!). It was meaningless anyways.
- All traders feature + fancy broadcast.
- Disabled 4 idiotic functions in `KFGameType` that were causing greylist. Blame my ocd.

## GameRule

- Game doesnt end when players / spectators leave lobby.

## Pawns

- You can shop at ANY spot. Pst, don't ask why.
- Dosh fix.
- `SoundGroup == none` fix.
- `weapon == none` fix for xPawn.serverchangedweapon().

## Controllers

- No more 'you will become %perk' spam in players console.
- Unlimited perk switches during trader time.
- Spectator messages are now fixed, visible and fancy.
- 0 delay suicide.
- Voice messages doesn't break during zed time, admins can spam to death. And usual spammer players will be punished for ~2-12secs of SILENCE.

## Weapons

- Dual_pistol_fire: fixed `accessed none IgnoreActors`.
- Dual_pistol: fixed `accessed none DropFrom`.
- KFWeaponPickup: fixed `accessed none Inventory` for destroyed weapon pickups.
- Nade: sounds log spam fix.
- Pipes: no more uber damage glitch.
- Pipes: no more detonation on NPC's and dead players.
- Pipes: sounds log spam fix.
- Pipes: assest now are loaded properly without trader buy.
- Syringe: 50 heals when last alive player.
- LAWProj: `RepInfo none` fixes.
- `M79GrenadeProjectile` and `LAWProj` now can't be detonated by teammates. No more fun.
- Allow players to use double variants of skins.

## Zeds

- Husks: doesnt spam `toggleaux ctrl none` anymore.
- Husks: do NOT move zeds that they can NOT see physically.
- Husks: do NOT move FP's. Finally!
- Husks: do NOT start to shoot when other Husk moves him with projectile.
- Husks: do NOT start to shoot while in falling `Physics` mode.
- Sirens: do NOT damage players with no head / after death.
- Sirens: shit tons of `takedamage instigator none` log spam fixes.
- FP: now they do not spin. At all.
- Boss: he doesn't burn at all. He is chOnky.
- Boss: `controller == none` fixes.
- Boss: now you can actually headshot him during his machine gun animation.
- KFMonster: new headshot calculation method for tests.
- KFMonster: `controller == none` fix when you kill zeds before they fall into stun.
- KFMonster: zeds disable their collisions after death. Now steves and other zeds wont block your movement after you killed them.
- KFMonster: added 0.3 secs delay before any melee attack. Hopefully it will fix FP one shot kills and steves attack spam during jumps.

## Shop Volume

- Fixed shit tons of `MyTrader: fix accessed none` errors.
- Fixed player teleportation functions. Now log is completely clean.

## Doors

- Forces zeds to actually ignore `DoorMoover` pathnodes. Thanks TWI!

## Voting Handler

- Spectators can NOT vote.
- Added a message to warn spectators that they suck.
