class_name MeleeHitbox
extends Node2D

var hit_targets: Dictionary = {}

func begin() -> void:
    hit_targets.clear()

func sweep(origin: Vector2, facing: int, weapon: WeaponData, event: DamageEvent) -> void:
    var shape := RectangleShape2D.new()
    shape.size = Vector2(weapon.reach + 10.0, weapon.hit_height)
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0.0, origin + Vector2(facing * (weapon.reach - 10.0) * 0.5, 0))
    query.collision_mask = 16 if event.faction == 1 else 8
    query.collide_with_areas = true
    query.collide_with_bodies = false
    var space := get_world_2d().direct_space_state
    if event.faction == 1:
        _sweep_reflectable(query, origin, event, space)
    var contacts:=space.intersect_shape(query,64)
    contacts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        var first:=a.collider as CombatHurtbox
        var second:=b.collider as CombatHurtbox
        return (first.hit_priority if first!=null else 0)>(second.hit_priority if second!=null else 0))
    for contact in contacts:
        var receiver := contact.collider as CombatHurtbox
        if receiver == null or hit_targets.has(receiver.health.get_instance_id()):
            continue
        var ray := PhysicsRayQueryParameters2D.create(origin, receiver.global_position, 1)
        ray.hit_from_inside = true
        if not space.intersect_ray(ray).is_empty():
            continue
        hit_targets[receiver.health.get_instance_id()] = true
        var victim := receiver.get_parent()
        var bonus: int = victim.melee_opening_bonus(event) if victim.has_method("melee_opening_bonus") else 0
        receiver.receive(event.with_amount(event.amount + bonus) if bonus > 0 else event)
    if event.faction == 1:
        _sweep_fragile(query, origin, event, space)

func _sweep_reflectable(query: PhysicsShapeQueryParameters2D, origin: Vector2, event: DamageEvent, space: PhysicsDirectSpaceState2D) -> void:
    var old_mask:=query.collision_mask
    query.collision_mask=1024
    for contact in space.intersect_shape(query,64):
        var ball: Object=contact.collider
        if not ball.has_method("reflect_attack") or hit_targets.has(ball.get_instance_id()): continue
        var ray:=PhysicsRayQueryParameters2D.create(origin,ball.global_position,1)
        ray.hit_from_inside=true
        if space.intersect_ray(ray).is_empty() and ball.reflect_attack(event,origin):
            hit_targets[ball.get_instance_id()]=true
    query.collision_mask=old_mask

func _sweep_fragile(query: PhysicsShapeQueryParameters2D, origin: Vector2, event: DamageEvent, space: PhysicsDirectSpaceState2D) -> void:
    query.collision_mask = 256
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var visible: Array[FragileBrick] = []
    # Sample all occlusion first; a wall broken by this sweep still shields
    # whatever is behind it during the same query.
    for contact in space.intersect_shape(query, 64):
        var brick := contact.collider as FragileBrick
        if brick == null or brick.broken or hit_targets.has(brick.get_instance_id()):
            continue
        var ray := PhysicsRayQueryParameters2D.create(origin, brick.global_position, 1, [brick.get_rid()])
        ray.hit_from_inside = true
        if space.intersect_ray(ray).is_empty():
            visible.append(brick)
    for brick in visible:
        hit_targets[brick.get_instance_id()] = true
        brick.receive_sword(event)
