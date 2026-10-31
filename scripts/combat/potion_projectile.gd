class_name PotionProjectile
extends Node2D
const GRAVITY := 650.0
var velocity := Vector2.ZERO
var poisonous := false
var radius := 30.0
var source: Node
var spent := false
var lifetime := 2.2
var burst_left := 0.0
var trail: Array[Vector2] = []
func _ready() -> void:
    process_physics_priority=5
    add_to_group("projectiles")
func _physics_process(delta: float) -> void:
    if spent:
        burst_left-=delta
        if burst_left<=0: retire()
        queue_redraw()
        return
    lifetime-=delta
    trail.append(global_position)
    if trail.size()>6: trail.pop_front()
    var next:=global_position+velocity*delta+Vector2(0,0.5*GRAVITY*delta*delta)
    velocity.y+=GRAVITY*delta
    var query:=PhysicsRayQueryParameters2D.create(global_position,next,1|8)
    query.collide_with_areas=true
    query.hit_from_inside=true
    var hit:=get_world_2d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        # Keep the burst just outside the wall so cover occludes the splash.
        global_position=hit.position+hit.normal*1.5
        splash()
    else:
        global_position=next
        if lifetime<=0: splash()
    queue_redraw()
func splash() -> void:
    if spent: return
    spent=true
    burst_left=EnemyVfxArt.POTION_BURST_SECONDS
    var shape:=CircleShape2D.new()
    shape.radius=radius
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,global_position)
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var hurtbox:=hit.collider as CombatHurtbox
        if hurtbox==null: continue
        var ray:=PhysicsRayQueryParameters2D.create(global_position,hurtbox.global_position,1)
        ray.hit_from_inside=true
        if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
        var event:=DamageEvent.create(self,2,1 if poisonous else 3)
        event.set_meta("poison_impact",poisonous)
        hurtbox.receive(event)
func retire() -> void:
    hide()
    set_physics_process(false)
    queue_free()
func _draw() -> void:
    var color:=Color("9bea6a") if poisonous else Color("fb777d")
    if spent:
        EnemyVfxArt.potion_burst(self,poisonous,burst_left,radius)
        return
    for i in trail.size():
        var alpha := 0.12+float(i)/trail.size()*0.35
        draw_rect(Rect2(to_local(trail[i]).round()-Vector2.ONE,Vector2(2,2)),Color(color,alpha))
    draw_rect(Rect2(-5,-5,10,12),Color("18332c"))
    draw_rect(Rect2(-4,-3,8,9),color)
    draw_rect(Rect2(-2,-8,4,4),Color("d9dbb2"))
    draw_rect(Rect2(-2,-7,3,2),Color("967751"))
    draw_rect(Rect2(-3,-2,2,4),Color("e9f3cb"))
