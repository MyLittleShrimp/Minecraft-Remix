extends ArrowProjectile
func _draw() -> void:
    draw_set_transform(Vector2(-26,0))
    WeaponArt.trident(self,Color("a1d9c5"))
