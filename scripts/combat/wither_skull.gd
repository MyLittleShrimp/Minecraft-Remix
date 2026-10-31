class_name WitherSkull
extends Node2D
var shooter: WitherBoss
var event: DamageEvent
var velocity:=Vector2.ZERO
var spent:=false
var life:=4.0
func _ready() -> void:
    process_physics_priority=85
    add_to_group("projectiles")
func _physics_process(delta: float) -> void:
    if spent: return
    if not is_instance_valid(shooter) or not shooter.active or shooter.health.current<=0 or shooter.target.dead:
        retire()
        return
    life-=delta
    if life<=0:
        retire()
        return
    var shape:=CircleShape2D.new()
    shape.radius=7
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.collision_mask=1|8
    query.collide_with_areas=true
    query.collide_with_bodies=true
    var count:=maxi(1,ceili(velocity.length()*delta/3))
    for i in count:
        position+=velocity*delta/count
        query.transform=Transform2D(0,global_position)
        var contacts:=get_world_2d().direct_space_state.intersect_shape(query,32)
        for hit in contacts:
            if hit.collider is PhysicsBody2D:
                if hit.collider is WitherPillar: hit.collider.absorb_skull()
                explode()
                return
        for hit in contacts:
            if hit.collider is CombatHurtbox:
                hit.collider.receive(event)
                explode()
                return
    queue_redraw()
func explode() -> void:
    if spent: return
    WitherHitBurst.spawn(get_parent(),global_position,shooter.second_phase)
    retire()
func retire() -> void:
    if spent: return
    spent=true
    hide()
    set_physics_process(false)
    queue_free()
func _draw() -> void:
    var glow:=Color("d896ff") if shooter.second_phase else Color("a1e6e2")
    for i in range(3,0,-1): draw_rect(Rect2(-velocity.normalized()*i*6-Vector2(3,3),Vector2(6,6)),Color(glow,0.15*(4-i)))
    draw_rect(Rect2(-8,-8,16,16),Color("20202c"))
    draw_rect(Rect2(-6,-6,12,12),Color("655769"))
    draw_rect(Rect2(-5,-3,4,4),glow)
    draw_rect(Rect2(2,-3,4,4),glow)
    draw_rect(Rect2(-3,4,6,3),Color("131822"))
