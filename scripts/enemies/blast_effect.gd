class_name BlastEffect
extends Node2D

var radius: float = 80.0
var remaining: float = 0.32

func _ready() -> void:
    add_to_group("transient_effects")

func _physics_process(delta: float) -> void:
    remaining -= delta
    queue_redraw()
    if remaining <= 0:
        queue_free()

func retire() -> void:
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    var progress := 1.0 - remaining / 0.32
    var color := Color("ffd88b")
    color.a = 1.0 - progress
    draw_arc(Vector2.ZERO, radius * (0.3 + progress * 0.7), 0, TAU, 16, color, 4)
    for i in 12:
        var point := Vector2.from_angle(i * TAU / 12) * radius * progress
        draw_rect(Rect2(point.round() - Vector2(4, 4), Vector2(8, 8)), color)
