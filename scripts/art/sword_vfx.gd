extends Node2D
## Render the narrow arc over targets, without moving the weapon or actor layers.
@onready var weapon: WeaponController = get_parent()
func _ready() -> void:
    z_index = 5
    process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
    queue_redraw()
func _draw() -> void:
    if weapon.sword_time < 0 or weapon.sword_weapon == null: return
    if weapon.equipped().kind != WeaponData.Kind.SWORD: return
    if weapon.health.current <= 0 or weapon.actor.carrying_tool: return
    var giant: bool = weapon.sword_event != null and weapon.sword_event.get_meta("critical", false)
    PixelVfxArt.sword(self,weapon.sword_time,weapon.sword_weapon,weapon.sword_facing,giant)
