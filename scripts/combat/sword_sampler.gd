extends Node
## Query after player movement so moving attacks follow the physics pose.
@onready var weapon: WeaponController = get_parent()

func _ready() -> void:
    process_physics_priority = 5

func _physics_process(_delta: float) -> void:
    if weapon.sword_time >= 0.0 and not weapon.sword_event.has_meta("airborne"):
        # Sample once AFTER player movement, so jump + attack on the same tick
        # also qualifies. Landing or jumping later cannot change this swing.
        var airborne := not weapon.actor.is_on_floor() or (weapon.actor.jump_active and weapon.actor.velocity.y < 0)
        weapon.sword_event.set_meta("airborne", airborne)
        if airborne:
            # Flat bonus after buffs: normal 6 -> 8, giant 12 -> 14.
            weapon.sword_event.amount += weapon.sword_weapon.airborne_damage_bonus
    if weapon.sword_time >= 0.0 and weapon.sword_time >= weapon.sword_weapon.windup and weapon.sword_time < weapon.sword_weapon.windup + weapon.sword_weapon.active_seconds:
        weapon.hitbox.sweep(weapon.actor.global_position + Vector2(0, -23), weapon.sword_facing, weapon.sword_weapon, weapon.sword_event)
