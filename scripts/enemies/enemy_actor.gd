class_name RemixEnemy
extends CharacterBody2D

signal fired(arrow: ArrowProjectile)
signal exploded
signal defeated(enemy: RemixEnemy)
signal fuse_beep
enum State { PATROL, CHASE, AIM, RECOVER, FUSE, DEAD, POUNCE_WARNING, POUNCE }

@export var data: EnemyData
@export var ui_font: Font
var target: RemixPlayer
var view_camera: Camera2D
var health: HealthComponent
var receiver: CombatHurtbox
var state: State = State.PATROL
var facing: int = -1
var spawn_point: Vector2
var state_left: float = 0.0
var fuse_left: float = 0.0
var away_seconds: float = 0.0
var hitstun: float = 0.0
var flash_left: float = 0.0
var steps: float = 0.0
var beep_left: float = 0.0
var detonation_done: bool = false
var last_damage: int = 0
var visual: Node2D

func _ready() -> void:
    collision_layer = 32
    collision_mask = 3
    floor_snap_length = 3.0
    process_physics_priority = 1
    spawn_point = global_position
    add_to_group("enemies")
    var body_shape := RectangleShape2D.new()
    body_shape.size = Vector2(20, 42)
    var collider := CollisionShape2D.new()
    collider.position.y = -21
    collider.shape = body_shape
    add_child(collider)
    health = create_health()
    health.max_health = data.max_health
    health.faction = 2
    health.invulnerability_seconds = 0
    health.strongest_per_tick = false
    add_child(health)
    health.process_physics_priority = 70
    receiver = CombatHurtbox.new()
    receiver.health = health
    receiver.position.y = -22
    receiver.size = Vector2(20, 42)
    add_child(receiver)
    visual = Node2D.new()
    visual.set_script(load("res://scripts/enemies/enemy_visual.gd"))
    add_child(visual)
    var resolver := Node.new()
    resolver.set_script(load("res://scripts/enemies/enemy_late_step.gd"))
    add_child(resolver)
    health.damaged.connect(_on_damage)
    health.died.connect(_on_death)

func create_health() -> HealthComponent:
    return HealthComponent.new()

func center() -> Vector2:
    return global_position + Vector2(0, -22)

func target_center() -> Vector2:
    return target.global_position + Vector2(0, -22)

func on_camera() -> bool:
    if not is_instance_valid(view_camera):
        return false
    return Rect2(view_camera.global_position - Vector2(304, 156), Vector2(608, 312)).has_point(center())

func clear_line(to: Vector2) -> bool:
    var query := PhysicsRayQueryParameters2D.create(center(), to, 1)
    query.hit_from_inside = true
    return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func sees_target() -> bool:
    return is_instance_valid(target) and not target.dead and on_camera() and center().distance_to(target_center()) <= data.awareness and clear_line(target_center())

func safe_step(direction: float) -> bool:
    var space := get_world_2d().direct_space_state
    var ahead := direction * 17.0
    var wall := PhysicsRayQueryParameters2D.create(center(), center() + Vector2(ahead, 0), 1)
    if not space.intersect_ray(wall).is_empty():
        return false
    var floor_query := PhysicsRayQueryParameters2D.create(global_position + Vector2(ahead, -8), global_position + Vector2(ahead, 18), 3)
    return not space.intersect_ray(floor_query).is_empty()

func _physics_process(delta: float) -> void:
    flash_left = maxf(0, flash_left - delta)
    if state == State.DEAD:
        visual.queue_redraw()
        return
    hitstun = maxf(0, hitstun - delta)
    state_left = maxf(0, state_left - delta)
    velocity.y = minf(700, velocity.y + 1500 * delta)
    if not is_instance_valid(target):
        velocity.x = 0
    elif state == State.FUSE:
        _tick_fuse(delta)
        if hitstun <= 0:
            velocity.x = 0
    elif hitstun <= 0:
        if data.kind == EnemyData.Kind.SKELETON:
            _tick_skeleton()
        else:
            _tick_walker()
    if hitstun > 0:
        velocity.x = move_toward(velocity.x, 0, delta * 250)
    move_and_slide()
    steps += absf(velocity.x) * delta * 0.1
    visual.position = global_position.round() - global_position
    visual.queue_redraw()
    if global_position.y > 480:
        health.queue_damage(DamageEvent.create(self, 0, data.max_health))
    if data.contact_damage > 0 and hitstun <= 0 and on_camera():
        _contact_damage()

func _tick_walker() -> void:
    var aware := sees_target()
    if aware and absf(target.position.y - position.y) < 60:
        state = State.CHASE
        if not is_zero_approx(target.global_position.x - global_position.x):
            facing = 1 if target.global_position.x > global_position.x else -1
        if data.kind == EnemyData.Kind.CREEPER and center().distance_to(target_center()) <= data.ignition_distance:
            state = State.FUSE
            fuse_left = data.fuse_seconds
            away_seconds = 0
            beep_left = 0
            velocity.x = 0
            return
        velocity.x = facing * data.chase_speed if safe_step(facing) else 0.0
    else:
        state = State.PATROL
        if not on_camera():
            velocity.x = 0
            return
        if absf(global_position.x - spawn_point.x) >= data.patrol_radius:
            facing = 1 if global_position.x < spawn_point.x else -1
        if not safe_step(facing):
            facing *= -1
        velocity.x = facing * data.patrol_speed if safe_step(facing) else 0.0

func _tick_skeleton() -> void:
    velocity.x = 0
    if not sees_target():
        if state == State.AIM:
            state = State.RECOVER
            state_left = 0.35
        return
    facing = 1 if target.global_position.x > global_position.x else -1
    if absf(target.global_position.x - global_position.x) < data.retreat_distance and safe_step(-facing):
        if absf(global_position.x - facing * 2 - spawn_point.x) <= data.patrol_radius:
            velocity.x = -facing * 40.0
    if state == State.RECOVER and state_left > 0:
        return
    if state != State.AIM:
        state = State.AIM
        state_left = data.aim_seconds
    elif state_left <= 0:
        var direction := (target_center() - center()).normalized()
        var arrow := ArrowProjectile.new()
        arrow.position = get_parent().to_local(center())
        arrow.velocity = direction * data.arrow_speed
        arrow.event = DamageEvent.create(self, 2, 2, Vector2(facing * 130, -100))
        get_parent().add_child(arrow)
        state = State.RECOVER
        state_left = data.shot_recovery
        fired.emit(arrow)

func _tick_fuse(delta: float) -> void:
    fuse_left = maxf(0, fuse_left - delta)
    if fuse_left > data.committed_seconds:
        var escaped := target.dead or center().distance_to(target_center()) > data.extinguish_distance or not clear_line(target_center()) or not on_camera()
        away_seconds = away_seconds + delta if escaped else 0.0
        if away_seconds >= data.extinguish_seconds:
            state = State.PATROL
            fuse_left = 0
            away_seconds = 0
            return
    beep_left = maxf(0, beep_left - delta)
    if beep_left <= 0:
        fuse_beep.emit()
        beep_left = lerpf(0.08, 0.30, fuse_left / data.fuse_seconds)

func _contact_damage() -> void:
    var shape := RectangleShape2D.new()
    shape.size = Vector2(22, 42)
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0, center())
    query.collision_mask = 8
    query.collide_with_areas = true
    query.collide_with_bodies = false
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var victim := hit.collider as CombatHurtbox
        if victim != null and clear_line(victim.global_position):
            var direction := signf(victim.global_position.x - global_position.x)
            if direction == 0:
                direction = facing
            victim.receive(DamageEvent.create(self, 2, data.contact_damage, Vector2(direction * 160, -150)))

func late_step() -> void:
    # Weapon/arrow damage has resolved at 70 before this phase at 80.
    if state == State.FUSE and fuse_left <= 0 and health.current > 0 and not detonation_done:
        detonate()

func detonate() -> void:
    if detonation_done or health.current <= 0 or state != State.FUSE:
        return
    detonation_done = true
    var blast_center := center()
    var impacts := BlastQuery.actors(self,blast_center,data.blast_radius,data.inner_radius,data.inner_damage,data.outer_damage,health)
    var fragile_impacts := FragileBrick.blast_candidates(get_world_2d().direct_space_state, blast_center, data.blast_radius)
    health.current = 0
    health.pending.clear()
    health.health_changed.emit(0, health.max_health)
    health.died.emit()
    BlastQuery.apply(impacts)
    for brick in fragile_impacts:
        brick.break_brick()
    var effect := BlastEffect.new()
    effect.creeper = true
    effect.position = get_parent().to_local(blast_center)
    effect.radius = data.blast_radius
    get_parent().add_child(effect)
    exploded.emit()

func _on_damage(event: DamageEvent) -> void:
    flash_left = 0.35
    last_damage = event.amount
    hitstun = float(event.get_meta("stagger", 0.18))
    velocity = Vector2(clampf(event.impulse.x, -150, 150), maxf(-130, event.impulse.y))
    if state == State.AIM:
        state = State.RECOVER
        state_left = 0.35

func _on_death() -> void:
    if state == State.DEAD:
        return
    state = State.DEAD
    velocity = Vector2.ZERO
    fuse_left = 0
    state_left = 0
    receiver.set_deferred("collision_layer", 0)
    defeated.emit(self)

func reset_target() -> void:
    global_position = spawn_point
    velocity = Vector2.ZERO
    state = State.PATROL
    facing = -1
    state_left = 0
    fuse_left = 0
    away_seconds = 0
    hitstun = 0
    flash_left = 0
    steps = 0
    detonation_done = false
    health.reset_health()
    receiver.set_deferred("collision_layer", 16)
    visual.queue_redraw()
