class_name ArrowSwitch
extends Area2D
signal activated
var active := false
var switch_id: StringName
var ui_font: Font
var inactive_label: String = "射中靶心"
var active_label: String = "已放桥"

func _ready() -> void:
    collision_layer=512
    collision_mask=0
    monitoring=false
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(28,34)
    var collider:=CollisionShape2D.new()
    collider.shape=shape
    add_child(collider)

func receive(_event: DamageEvent) -> void:
    pass # Melee and explosions do not activate a ranged puzzle target.

func receive_projectile(event: DamageEvent) -> void:
    if active or event.faction!=1: return
    set_active(true)
    activated.emit()

func set_active(value: bool) -> void:
    active=value
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-3,16,6,22),Color("71604b"))
    draw_rect(Rect2(-16,-19,32,38),Color("233c43"))
    draw_rect(Rect2(-14,-17,28,34),Color("64bba4") if active else Color("c49e62"))
    draw_rect(Rect2(-10,-13,20,26),Color("234657"))
    draw_rect(Rect2(-6,-8,12,16),Color("b3f4d9") if active else Color("eecd8c"))
    draw_rect(Rect2(-2,-3,4,6),Color("2b635d"))
    if ui_font:
        draw_string(ui_font,Vector2(-21,-26),active_label if active else inactive_label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("c4efdf"))
