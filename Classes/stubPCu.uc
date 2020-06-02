class stubPCu extends Object;


static function PreloadFireModeAssets(level level, class<WeaponFire> WF, optional WeaponFire SpawnedFire)
{
  local class<Projectile> P;

  if ( WF == none || WF == class'KFMod.NoFire' ) 
    return;

  if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
    class<KFFire>(WF).static.PreloadAssets(Level, KFFire(SpawnedFire));
  else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
    class<KFMeleeFire>(WF).static.PreloadAssets(KFMeleeFire(SpawnedFire));
  else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
    class<KFShotgunFire>(WF).static.PreloadAssets(Level, KFShotgunFire(SpawnedFire));

  // preload projectile assets
  P = WF.default.ProjectileClass;
  //log("Projectile =" @ P, default.class.outer.name);
  if ( P == none )
    return;
        
  if ( class<CrossbuzzsawBlade>(P) != none )
    class<CrossbuzzsawBlade>(P).static.PreloadAssets();
  else if ( class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "" )
    class<LAWProj>(P).static.PreloadAssets();
  else if ( class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "" )
    class<M79GrenadeProjectile>(P).static.PreloadAssets();
  else if ( class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "" )
    class<SPGrenadeProjectile>(P).static.PreloadAssets();
  else if ( class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "" )
    class<HealingProjectile>(P).static.PreloadAssets();
  else if ( class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "" )
    class<CrossbowArrow>(P).static.PreloadAssets();
  else if ( class<M99Bullet>(P) != none )
    class<M99Bullet>(P).static.PreloadAssets();
  else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
    class<PipeBombProjectile>(P).static.PreloadAssets();
  // More DLC
  else if ( class<SealSquealProjectile>(P) != none && class<SealSquealProjectile>(P).default.StaticMeshRef != "" )
    class<SealSquealProjectile>(P).static.PreloadAssets();
}


static function UnloadFireModeAssets(class<WeaponFire> WF)
{
	local class<Projectile> P;

	if ( WF==none || WF==Class'KFMod.NoFire' ) 
		return;

	if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
		class<KFFire>(WF).static.UnloadAssets();
	else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
		class<KFMeleeFire>(WF).static.UnloadAssets();
	else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
		class<KFShotgunFire>(WF).static.UnloadAssets();

	// Unload projectile assets only if refs aren't empty (i.e. they have been dynamically loaded)
	P = WF.default.ProjectileClass;
	if ( P == none || P.default.StaticMesh != none )
		return;

	if ( class<CrossbuzzsawBlade>(P) != none )
		class<CrossbuzzsawBlade>(P).static.UnloadAssets();
	else if ( class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "" )
		class<LAWProj>(P).static.UnloadAssets();
	else if ( class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "" )
		class<M79GrenadeProjectile>(P).static.UnloadAssets();
	else if ( class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "" )
		class<SPGrenadeProjectile>(P).static.UnloadAssets();
	else if ( class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "" )
		class<HealingProjectile>(P).static.UnloadAssets();
	else if ( class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "" )
		class<CrossbowArrow>(P).static.UnloadAssets();
	else if ( class<M99Bullet>(P) != none )
		class<M99Bullet>(P).static.UnloadAssets();
	else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
		class<PipeBombProjectile>(P).static.UnloadAssets();
	// More DLC
	else if ( class<SealSquealProjectile>(P) != none && class<SealSquealProjectile>(P).default.StaticMeshRef != "" )
		class<SealSquealProjectile>(P).static.UnloadAssets();
}