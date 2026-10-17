extends HealthComponent
## Resolve the shield for every queued hit, including multipart/ultimate batches.
func damage_floor() -> int:
    return 1 if get_parent().living_crystals()>0 else 0
