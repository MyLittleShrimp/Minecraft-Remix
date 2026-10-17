class_name ArrowProjectile
extends Node2D

var velocity: Vector2
var event: DamageEvent
var lifetime: float = 3.0
var spent: bool = false
var empowered: bool = false
var bolt := false
var targets_remaining := 1
var pierced: Array[RID] = []
var hit_health: Dictionary = {}

func _ready() -> void:
    process_physics_priority = 5
    add_to_group("projectiles")
    rotation = velocity.angle()

func _physics_process(delta: float) -> void:
    if spent:
        return
    lifetime -= delta
    var next := global_position + velocity * delta
    var space := get_world_2d().direct_space_state
    var wall_query := PhysicsRayQueryParameters2D.create(global_position, next, 1)
    wall_query.hit_from_inside = true
    var wall := space.intersect_ray(wall_query)
    var target_query := PhysicsRayQueryParameters2D.create(global_position, next, 16 | 512 | 1024 if event.faction == 1 else 8)
    target_query.collide_with_areas = true
    target_query.collide_with_bodies = false
    target_query.hit_from_inside = true
    # Sweep in distance order, including multiple hits in a single fast frame.
    # A pierced hurtbox stays excluded on later frames; cover always wins ties.
    for step in 16:
        target_query.exclude=pierced
        var target:=space.intersect_ray(target_query)
        if not wall.is_empty() and (target.is_empty() or global_position.distance_squared_to(wall.position)<=global_position.distance_squared_to(target.position)):
            retire()
            return
        if target.is_empty(): break
        pierced.append(target.rid)
        if target.collider.has_method("receive_projectile") and not target.collider is ArrowSwitch:
            target.collider.receive_projectile(event)
            retire()
            return
        if target.collider is ArrowSwitch:
            target.collider.receive_projectile(event)
            retire()
            return
        if target.collider is CombatHurtbox:
            var id: int=target.collider.health.get_instance_id()
            if not hit_health.has(id):
                hit_health[id]=true
                target.collider.receive(event)
                targets_remaining-=1
        if targets_remaining<=0:
            retire()
            return
    if lifetime<=0.0: retire()
    else: global_position=next

func retire() -> void:
    spent = true
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    if empowered:
        draw_line(Vector2(-25,0),Vector2(-6,0),Color(0.38,1.0,0.74,0.45),5)
        draw_rect(Rect2(-20,-2,3,3),Color("c5ffe5"))
    draw_line(Vector2(-14, 0), Vector2(0, 0), Color("a5e3e4") if bolt else Color("edcf8c"), 3 if bolt else 2)
    draw_line(Vector2(-14, -3), Vector2(-9, 0), Color("dce4d0"), 2)
    draw_line(Vector2(-14, 3), Vector2(-9, 0), Color("dce4d0"), 2)
    draw_colored_polygon(PackedVector2Array([Vector2(4, 0), Vector2(-2, -3), Vector2(-2, 3)]), Color("c4ded4"))
