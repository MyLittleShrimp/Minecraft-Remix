class_name StageGate
extends StaticBody2D
var closed: bool = false
var closure := 0.0

func _ready() -> void:
    collision_mask = 0
    var shape := RectangleShape2D.new()
    shape.size = Vector2(12,240)
    var collider := CollisionShape2D.new()
    collider.position.y = -120
    collider.shape = shape
    add_child(collider)
    _sync()

func set_closed(value: bool) -> void:
    closed = value
    _sync.call_deferred()
    queue_redraw()

func _sync() -> void:
    collision_layer = 1 if closed else 0

func _process(delta: float) -> void:
    closure=move_toward(closure,1.0 if closed else 0.0,delta/0.65)
    queue_redraw()

func _draw() -> void:
    # Stone arch stays visible while iron bars slide up/down through it.
    for side in [-1,1]:
        var x: float = side*25.0-7
        draw_rect(Rect2(x,-170,14,170),Color("334844"))
        for y in range(-168,0,16):
            draw_rect(Rect2(x+1,y,12,14),Color("70806b"))
            draw_rect(Rect2(x+2,y+1,3,11),Color("8d9676"))
        draw_rect(Rect2(x-3,-178,20,10),Color("acac80"))
    draw_rect(Rect2(-32,-187,64,12),Color("445d54"))
    draw_rect(Rect2(-30,-186,60,3),Color("b7ba8a"))
    var height := 174*closure
    if height<1: return
    for x in [-16,-8,0,8,16]:
        draw_rect(Rect2(x-2,-174,4,height),Color("263532"))
        draw_rect(Rect2(x-1,-174,1,height),Color("8f9b85"))
    for y in range(0,int(height),28):
        draw_rect(Rect2(-20,-174+y,40,4),Color("686b54"))
    draw_rect(Rect2(-20,-174+height-4,40,4),Color("b19b61"))
