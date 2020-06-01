class stubSyringe extends Syringe;

simulated function PostBeginPlay()
{
	Super(KFWeapon).PostBeginPlay();

	HealBoostAmount = 100;
}
