class_name GhastFireball
extends Area2D
## Only this projectile opts into reflection. Queries resolve after melee/enemy death.
const RADIUS := 9.0
const HOSTILE_SPEED := 165.0
const RETURN_SPEED := 340.0
var shooter: Node2D
var event: DamageEvent
var velocity := Vector2.ZERO
var arena_bounds := Vector2(320,960)
var spent := false
var reflected := false
var lifetime := 4.5
var age := 0.0

func _ready() -> void:
    process_physics_priority=85
    collision_layer=1024
    collision_mask=0
    monitoring=false
    var collider:=CollisionShape2D.new()
    var circle:=CircleShape2D.new()
    circle.radius=RADIUS
    collider.shape=circle
    add_child(collider)
    add_to_group("projectiles")

func reflect_attack(attack: DamageEvent, origin: Vector2) -> bool:
    if spent or reflected or attack.faction!=1: return false
    var caster:=instance_from_id(attack.source_id) as Node2D
    if not is_instance_valid(caster): return false
    reflected=true
    collision_layer=0
    event=DamageEvent.create(caster,1,12)
    event.set_meta("ghast_reflection",true)
    var direction:=global_position-origin
    if is_instance_valid(shooter) and shooter.health.current>0 and shooter.on_camera(): direction=shooter.center()-global_position
    if direction.length_squared()<1: direction=Vector2.RIGHT
    velocity=direction.normalized()*RETURN_SPEED
    lifetime=2.5
    if is_instance_valid(shooter): shooter.ball_reflected()
    queue_redraw()
    return true

func receive_projectile(attack: DamageEvent) -> void:
    if not spent and not reflected and attack.faction==1:
        if is_instance_valid(shooter): shooter.ball_destroyed()
        retire()

func _physics_process(delta: float) -> void:
    if spent: return
    if not is_instance_valid(shooter) or shooter.health.current<=0 or shooter.target.dead:
        retire()
        return
    age+=delta
    lifetime-=delta
    if lifetime<=0:
        retire()
        return
    # Short swept circle steps include the visible radius, walls and starts inside.
    var shape:=CircleShape2D.new()
    shape.radius=RADIUS
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.collision_mask=1 | (16 if reflected else 8)
    query.collide_with_areas=true
    query.collide_with_bodies=true
    var count:=maxi(1,ceili(velocity.length()*delta/4.0))
    var step:=velocity*delta/count
    for i in count:
        global_position+=step
        if global_position.x<arena_bounds.x or global_position.x>arena_bounds.y or global_position.y<84 or global_position.y>300:
            retire()
            return
        query.transform=Transform2D(0,global_position)
        var contacts:=get_world_2d().direct_space_state.intersect_shape(query,32)
        # Cover wins simultaneous contacts; no blast through a wall or lingering fire.
        if contacts.any(func(hit) -> bool: return hit.collider is PhysicsBody2D):
            retire()
            return
        for hit in contacts:
            if hit.collider is CombatHurtbox:
                hit.collider.receive(event)
                retire()
                return
    queue_redraw()

func retire() -> void:
    if spent: return
    spent=true
    collision_layer=0
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    var direction:=velocity.normalized()
    var rim:=Color("7effec") if reflected else Color("ff623e")
    for i in range(4,0,-1):
        var at:=(-direction*(i*6.0)).round()
        draw_rect(Rect2(at-Vector2(3,3),Vector2(6,6)),Color(rim,0.15+0.1*(4-i)))
    draw_colored_polygon(PackedVector2Array([Vector2(-9,-4),Vector2(-4,-9),Vector2(4,-9),Vector2(9,-4),Vector2(9,4),Vector2(4,9),Vector2(-4,9),Vector2(-9,4)]),rim)
    draw_rect(Rect2(-6,-6,12,12),Color("e9fff0") if reflected else Color("ffc05c"))
    draw_rect(Rect2(-3,-4,6,7),Color("fff6cd"))
    if reflected:
        draw_line(Vector2(-5,-11),Vector2(5,-11),Color("a5fff4"),2)
