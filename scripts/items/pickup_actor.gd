class_name RemixPickup
extends CharacterBody2D

signal collected(pickup: RemixPickup, actor: RemixPlayer, amount: int)
@export var data: PickupData
var direction: int = 1
var emerge_left: float = 0.0
var origin: Vector2
var retired: bool = false
var taken: bool = false
var visual: Node2D
var anchored: bool = false
var float_anchor := Vector2.ZERO
var float_seconds := 0.0

func anchor_at(at: Vector2) -> void:
    anchored=true
    float_anchor=at
    origin=at
    global_position=at
    velocity=Vector2.ZERO
    emerge_left=0
    collision_mask=0

func _ready() -> void:
    process_physics_priority = 110 # After lethal damage; apples never revive.
    collision_layer = 64
    collision_mask = 0
    floor_snap_length = 2
    add_to_group("pickups")
    var shape := RectangleShape2D.new()
    shape.size = Vector2(18, 18)
    var collider := CollisionShape2D.new()
    collider.shape = shape
    add_child(collider)
    origin = global_position
    emerge_left = data.emerge_seconds
    visual = Node2D.new()
    visual.set_script(load("res://scripts/items/pickup_visual.gd"))
    add_child(visual)

func _physics_process(delta: float) -> void:
    if retired:
        return
    if anchored:
        float_seconds+=delta
        global_position=float_anchor+Vector2(0,sin(float_seconds*2.4+float_anchor.x)*2)
        update_art()
        _collect_overlaps()
        return
    if emerge_left > 0:
        emerge_left = maxf(0, emerge_left - delta)
        global_position = origin + Vector2(0, -25 * (1 - emerge_left / data.emerge_seconds))
        if emerge_left <= 0:
            collision_mask = 3
            velocity = Vector2(direction * data.walk_speed, 0) if data.kind == PickupData.Kind.MUSHROOM else Vector2(direction * 90, -120)
        update_art()
        return
    velocity.y = minf(650, velocity.y + 850 * delta)
    if data.kind == PickupData.Kind.MUSHROOM:
        velocity.x = direction * data.walk_speed
    elif is_on_floor():
        # Keep rewards moving across adjoining supply bricks. Their tops may be
        # above the player's jump; settle only after reaching ordinary terrain.
        velocity.x = direction * 90 if _supported_by_supply_block() else move_toward(velocity.x, 0, delta * 400)
    move_and_slide()
    if is_on_wall():
        direction *= -1
    if global_position.y > 480:
        retire()
        return
    update_art()
    _collect_overlaps()

func _collect_overlaps() -> void:
    var shape := RectangleShape2D.new()
    shape.size = Vector2(22, 22)
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0, global_position)
    query.collision_mask = 4
    var players: Array[RemixPlayer] = []
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var actor := hit.collider as RemixPlayer
        if actor != null:
            players.append(actor)
    # Future simultaneous collectors get deterministic single ownership.
    players.sort_custom(func(a: RemixPlayer, b: RemixPlayer) -> bool: return a.get_instance_id() < b.get_instance_id())
    for actor in players:
        if try_collect(actor):
            break

func _supported_by_supply_block() -> bool:
    for i in get_slide_collision_count():
        var collision := get_slide_collision(i)
        if collision.get_normal().dot(up_direction) > 0.7 and collision.get_collider() is SupplyBlock:
            return true
    return false

func update_art() -> void:
    visual.position = global_position.round() - global_position
    visual.queue_redraw()

func try_collect(actor: RemixPlayer) -> bool:
    if retired or taken or emerge_left > 0 or actor.dead or get_tree().paused:
        return false
    if not Rect2(global_position - Vector2(11, 11), Vector2(22, 22)).intersects(Rect2(actor.global_position + Vector2(-9, -44), Vector2(18, 44))):
        return false
    var items := actor.get_node_or_null("ItemEffects") as PlayerItems
    if items == null:
        return false
    # A pickup just behind a solid wall cannot be grabbed through the wall.
    var line := PhysicsRayQueryParameters2D.create(global_position, actor.global_position + Vector2(0, -22), 1)
    line.hit_from_inside = true
    if not get_world_2d().direct_space_state.intersect_ray(line).is_empty():
        return false
    var applied := items.accept(data)
    if applied <= 0:
        return false
    taken = true
    collected.emit(self, actor, applied)
    retire()
    return true

func retire() -> void:
    if retired:
        return
    retired = true
    hide()
    set_physics_process(false)
    set_deferred("collision_layer", 0)
    queue_free()
