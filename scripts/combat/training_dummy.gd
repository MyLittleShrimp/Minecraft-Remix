class_name TrainingDummy
extends Node2D

@export var ui_font: Font
@export var label: String = "木靶"
@export var hit_points: int = 18
var health: HealthComponent
var receiver: CombatHurtbox
var flash_left: float = 0.0
var last_damage: int = 0
var sway: float = 0.0

func _ready() -> void:
    add_to_group("training_targets")
    health = HealthComponent.new()
    health.max_health = hit_points
    health.faction = 2
    health.invulnerability_seconds = 0.0
    health.strongest_per_tick = false
    add_child(health)
    receiver = CombatHurtbox.new()
    receiver.health = health
    receiver.size = Vector2(24, 44)
    receiver.position = Vector2(0, -23)
    add_child(receiver)
    health.damaged.connect(_on_damage)
    health.died.connect(func() -> void: receiver.set_deferred("collision_layer", 0))

func reset_target() -> void:
    health.reset_health()
    receiver.set_deferred("collision_layer", 16)
    flash_left = 0.0
    sway = 0.0

func _on_damage(event: DamageEvent) -> void:
    flash_left = 0.5
    last_damage = event.amount
    sway = signf(event.impulse.x) * 5.0

func _physics_process(delta: float) -> void:
    flash_left = maxf(0, flash_left - delta)
    sway = move_toward(sway, 0.0, delta * 20)
    queue_redraw()

func _draw() -> void:
    if health == null:
        return
    draw_rect(Rect2(-16, -4, 32, 4), Color("5c493c"))
    draw_rect(Rect2(-3, -18, 6, 18), Color("977242"))
    if health.current > 0:
        var wood := Color("f5eac4") if flash_left > 0.35 else Color("c79b61")
        draw_set_transform(Vector2(roundf(sway), 0))
        draw_rect(Rect2(-12, -44, 24, 31), Color("694e39"))
        draw_rect(Rect2(-10, -42, 20, 27), wood)
        draw_rect(Rect2(-6, -36, 12, 15), Color("be6955"))
        draw_rect(Rect2(-3, -32, 6, 7), Color("f0dda4"))
        draw_rect(Rect2(-20, -30, 8, 6), wood)
        draw_rect(Rect2(12, -30, 8, 6), wood)
        draw_set_transform(Vector2.ZERO)
        draw_rect(Rect2(-18, -53, 36, 4), Color("243f3b"))
        draw_rect(Rect2(-18, -53, 36.0 * health.current / health.max_health, 4), Color("e5b775"))
    else:
        draw_rect(Rect2(-18, -10, 15, 6), Color("8e724a"))
        draw_rect(Rect2(5, -12, 12, 8), Color("ba9359"))
        draw_line(Vector2(-6, -34), Vector2(-1, -29), Color("bee58c"), 3)
        draw_line(Vector2(-1, -29), Vector2(9, -40), Color("bee58c"), 3)
    if ui_font != null:
        draw_string(ui_font, Vector2(-27, -62), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("edf1ce"))
        if flash_left > 0:
            draw_string(ui_font, Vector2(15, -40 - (0.5 - flash_left) * 24), "-%d" % last_damage, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffdfa0"))
