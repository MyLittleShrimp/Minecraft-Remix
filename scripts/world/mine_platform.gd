class_name MinePlatform
extends AnimatableBody2D
var start:=Vector2(4128,294)
var finish:=Vector2(4512,294)
var phase:=0.0
const PERIOD:=10.0
func _ready() -> void:
    process_physics_priority=-10
    collision_layer=2
    collision_mask=0
    sync_to_physics=true
    add_to_group("one_way")
    position=start
    var collider:=CollisionShape2D.new()
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(112,12)
    collider.shape=shape
    collider.one_way_collision=true
    collider.one_way_collision_margin=6
    add_child(collider)
func _physics_process(delta: float) -> void:
    phase=fmod(phase+delta,PERIOD)
    # One second dwell at each bank, four seconds each crossing.
    var fraction:=clampf((phase-1)/4,0,1) if phase<5 else 1.0-clampf((phase-6)/4,0,1)
    position=start.lerp(finish,fraction)
func reset_route() -> void:
    phase=0
    position=start
func _draw() -> void:
    draw_rect(Rect2(-56,-6,112,12),Color("4b3b32"))
    draw_rect(Rect2(-56,-6,112,3),Color("e2c084"))
    for x in range(-54,54,16): draw_rect(Rect2(x,-2,14,6),Color("a77f4c"))
    for x in [-47,44]:
        draw_rect(Rect2(x,4,5,6),Color("617e83"))
