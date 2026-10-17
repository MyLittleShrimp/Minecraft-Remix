class_name BlastQuery
extends RefCounted
## Capture targets and cover before the caller mutates any destructible wall.
static func actors(source: Node2D, at: Vector2, radius: float, inner: float, inner_damage: int, outer_damage: int, excluded: HealthComponent=null) -> Array[Dictionary]:
    var space:=source.get_world_2d().direct_space_state
    var shape:=CircleShape2D.new()
    shape.radius=radius
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,at)
    query.collision_mask=8|16
    query.collide_with_areas=true
    query.collide_with_bodies=false
    var result: Array[Dictionary]=[]
    var seen: Dictionary={}
    for hit in space.intersect_shape(query,64):
        var victim:=hit.collider as CombatHurtbox
        if victim==null or victim.health==excluded or seen.has(victim.health): continue
        var distance:=at.distance_to(victim.global_position)
        var ray:=PhysicsRayQueryParameters2D.create(at,victim.global_position,1)
        ray.hit_from_inside=true
        if distance>radius or not space.intersect_ray(ray).is_empty(): continue
        seen[victim.health]=true
        var damage:=inner_damage if distance<=inner else outer_damage
        var impulse:=Vector2(signf(victim.global_position.x-at.x)*210,-180)
        result.append({"health":victim.health,"event":DamageEvent.create(source,0,damage,impulse)})
    return result

static func apply(impacts: Array[Dictionary]) -> void:
    for impact in impacts:
        var victim: HealthComponent=impact.health
        victim.queue_damage(impact.event)
        if victim.faction==2: victim.resolve_pending()
