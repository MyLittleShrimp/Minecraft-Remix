class_name FragileBrick
extends StaticBody2D
## Only explicitly tagged bricks can break; terrain stays outside this layer.
signal shattered(brick: FragileBrick)
@export var brick_id: StringName
@export var drops_emerald: bool = false
var random_loot := false
var broken: bool = false
var bump_left: float = 0.0
var debris_left: float = 0.0
var wooden := false
var wood_damage := 0

func _ready() -> void:
    collision_layer = 1 | 256
    collision_mask = 0
    process_physics_priority = 120
    add_to_group("head_bump_blocks")
    add_to_group("fragile_bricks")
    var shape := RectangleShape2D.new()
    shape.size = Vector2(32, 32)
    var collider := CollisionShape2D.new()
    collider.shape = shape
    add_child(collider)

func bump(_actor: RemixPlayer) -> void:
    if not broken:
        bump_left = 0.18
        queue_redraw()

func receive_sword(event: DamageEvent) -> void:
    if event.faction == 1 and event.amount > 0:
        if wooden:
            wood_damage += int(event.get_meta("wood_power", 1))
            bump_left = 0.18
            queue_redraw()
            if wood_damage < 3: return
        break_brick()

func break_brick() -> void:
    if broken or get_tree().paused:
        return
    broken = true
    bump_left = 0
    debris_left = 0.24
    _sync_collision.call_deferred()
    shattered.emit(self)
    queue_redraw()

func apply_broken(value: bool) -> void:
    broken = value
    wood_damage = 0
    bump_left = 0
    debris_left = 0
    # Resolve using current state, so an old deferred break cannot win over R.
    _sync_collision.call_deferred()
    queue_redraw()

func _sync_collision() -> void:
    collision_layer = 0 if broken else 1 | 256

func _physics_process(delta: float) -> void:
    bump_left = maxf(0, bump_left - delta)
    debris_left = maxf(0, debris_left - delta)
    queue_redraw()

static func blast_candidates(space: PhysicsDirectSpaceState2D, center: Vector2, radius: float) -> Array[FragileBrick]:
    var shape := CircleShape2D.new()
    shape.radius = radius
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0, center)
    query.collision_mask = 256
    var result: Array[FragileBrick] = []
    for hit in space.intersect_shape(query, 128):
        var brick := hit.collider as FragileBrick
        if brick == null or brick.broken:
            continue
        var nearest := center.clamp(brick.global_position - Vector2(16,16), brick.global_position + Vector2(16,16))
        if center.distance_to(nearest) > radius:
            continue
        var ray := PhysicsRayQueryParameters2D.create(center, nearest, 1, [brick.get_rid()])
        ray.hit_from_inside = true
        if space.intersect_ray(ray).is_empty():
            result.append(brick)
    return result

func _draw() -> void:
    if broken:
        if debris_left > 0:
            var spread := (1 - debris_left / 0.24) * 18
            for offset in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
                draw_rect(Rect2(offset * (6 + spread), Vector2(5,5)), Color("bac0a0"))
        return
    draw_set_transform(Vector2(0, -roundf(sin(bump_left / 0.18 * PI) * 3)))
    if wooden:
        draw_rect(Rect2(-16,-16,32,32), Color("26272b"))
        for i in 3:
            draw_rect(Rect2(-14,-14+i*10,28,8),Color("ae7e46") if i>=wood_damage else Color("594532"))
            draw_rect(Rect2(-12,-13+i*10,24,1),Color("dab87a"))
        draw_line(Vector2(-11,12),Vector2(11,-12),Color("efd091"),3)
        for x in [-12,10]:
            for y in [-12,10]: draw_rect(Rect2(x,y,2,2),Color("cbd1c0"))
    else:
        RemixArt.block(self,10)
        if random_loot:
            draw_rect(Rect2(-13,-12,26,2),Color("d4b776"))
            draw_rect(Rect2(-3,-5,6,8),Color("352e30"))
            draw_rect(Rect2(-2,-4,4,4),Color("ffe29b"))
            draw_line(Vector2(7,-10),Vector2(3,-3),Color("201e2b"),2)
            draw_line(Vector2(3,-3),Vector2(8,3),Color("201e2b"),2)
