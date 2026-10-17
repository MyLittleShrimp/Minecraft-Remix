class_name ReturningTrident
extends Node2D
## One outbound hit. Return travel is visual only and cannot hurt through walls.
var wielder: RemixPlayer
var event: DamageEvent
var velocity:=Vector2.ZERO
var max_distance:=320.0
var return_speed:=720.0
var travelled:=0.0
var age:=0.0
var returning:=false
var spent:=false

func _ready() -> void:
    process_physics_priority=5
    add_to_group("projectiles")
    rotation=velocity.angle()

func _physics_process(delta: float) -> void:
    if spent: return
    if not is_instance_valid(wielder) or wielder.dead:
        retire()
        return
    age+=delta
    if age>=2.0:
        retire()
        return
    var hand:=wielder.global_position+Vector2(0,-24)
    if returning:
        var distance:=global_position.distance_to(hand)
        if distance<=return_speed*delta+8:
            retire()
            return
        rotation=(hand-global_position).angle()
        global_position=global_position.move_toward(hand,return_speed*delta)
    else:
        var step:=minf(velocity.length()*delta,maxf(0,max_distance-travelled))
        var next:=global_position+velocity.normalized()*step
        var space:=get_world_2d().direct_space_state
        var wall_query:=PhysicsRayQueryParameters2D.create(global_position,next,1)
        wall_query.hit_from_inside=true
        var wall:=space.intersect_ray(wall_query)
        var target_query:=PhysicsRayQueryParameters2D.create(global_position,next,16 | 512 | 1024)
        target_query.collide_with_areas=true
        target_query.collide_with_bodies=false
        target_query.hit_from_inside=true
        var target:=space.intersect_ray(target_query)
        if not wall.is_empty() and (target.is_empty() or global_position.distance_squared_to(wall.position)<=global_position.distance_squared_to(target.position)):
            global_position=wall.position
            returning=true
        elif not target.is_empty() and target.collider.has_method("receive_projectile"):
            global_position=target.position
            target.collider.receive_projectile(event)
            returning=true
        elif not target.is_empty() and target.collider is CombatHurtbox:
            global_position=target.position
            target.collider.receive(event)
            returning=true
        else:
            global_position=next
            travelled+=step
            returning=travelled>=max_distance-0.01
    queue_redraw()

func retire() -> void:
    spent=true
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    if returning: draw_line(Vector2(-32,0),Vector2(-5,0),Color(0.4,0.95,1,0.45),3)
    draw_set_transform(Vector2(-25,0))
    WeaponArt.trident(self,Color(0.65,0.92,1,0.7) if returning else Color.WHITE)
