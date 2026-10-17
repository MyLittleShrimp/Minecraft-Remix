class_name RavagerWave
extends Node2D

var boss: RavagerEnemy
var direction := 1
var event: DamageEvent
var retired := false

func _ready() -> void:
    add_to_group("projectiles")
    process_physics_priority=85 # Enemy health resolves at 70; player at 100.
    event=DamageEvent.create(boss,2,3,Vector2(direction*120,-100))

func _physics_process(delta: float) -> void:
    if retired: return
    if not is_instance_valid(boss) or not boss.active or boss.health.current<=0:
        retire()
        return
    var distance:=direction*boss.tuning().wave_speed*delta
    var old_x:=position.x
    position.x+=distance
    if position.x<boss.arena_left-40 or position.x>boss.arena_right+40:
        retire()
        return
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(18+absf(distance),14)
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,Vector2((old_x+position.x)/2,position.y-7))
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        if hit.collider is CombatHurtbox: hit.collider.receive(event)
    queue_redraw()

func retire() -> void:
    retired=true
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    draw_rect(Rect2(-13,-4,26,4),Color("f4bd63"))
    draw_rect(Rect2(-8,-13,16,9),Color("775c48"))
    draw_rect(Rect2(-4,-18,8,7),Color("dfa469"))
    draw_rect(Rect2(-6,-12,4,3),Color("fff0ba"))
