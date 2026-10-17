extends EndermanEnemy
## An optional upper-branch resident: the ground route never enters its territory.
func inside_encounter(at: Vector2,margin: float=0) -> bool:
    return super.inside_encounter(at,margin) and at.y<=225
func landing_valid(at: Vector2) -> bool:
    return at.y<=225 and super.landing_valid(at)
