class_name RemixPlayer
extends CharacterBody2D

signal jumped
signal landed
signal ceiling_bumped
signal block_bumped(block: Node2D)

@export var tuning: MovementTuning
@export var input_provider: PlayerInputProvider
@onready var visual: Node2D = $Visual

var facing: int = 1
var coyote_left: float = 0.0
var buffer_left: float = 0.0
var drop_left: float = 0.0
var jump_active: bool = false
var just_respawned: bool = true
var steps: float = 0.0
var movement_scale: float = 1.0
var hitstun_left: float = 0.0
var dead: bool = false
var controls_locked: bool = false
var carrying_tool: bool = false

func _ready() -> void:
    if tuning == null:
        tuning = MovementTuning.new()
    if input_provider == null:
        input_provider = $InputProvider

func _physics_process(delta: float) -> void:
    if dead or controls_locked:
        velocity = Vector2.ZERO
        return
    hitstun_left = maxf(0.0, hitstun_left - delta)
    var grounded := is_on_floor() and not just_respawned
    just_respawned = false
    var axis := clampf(input_provider.movement_axis(), -1.0, 1.0)
    var pressed := input_provider.jump_pressed()
    var held := input_provider.jump_held()
    if hitstun_left > 0.0:
        axis = 0.0
        pressed = false
        buffer_left = 0.0
    coyote_left = tuning.coyote_seconds if grounded else maxf(0.0, coyote_left - delta)
    buffer_left = tuning.buffer_seconds if pressed else maxf(0.0, buffer_left - delta)
    drop_left = maxf(0.0, drop_left - delta)
    set_collision_mask_value(2, drop_left <= 0.0)
    if grounded:
        jump_active = false
    if not is_zero_approx(axis):
        facing = 1 if axis > 0.0 else -1
    var acceleration := tuning.ground_acceleration if grounded else tuning.air_acceleration
    if grounded and is_zero_approx(axis):
        acceleration = tuning.ground_deceleration
    if hitstun_left <= 0.0:
        velocity.x = move_toward(velocity.x, axis * tuning.run_speed * movement_scale, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 350.0 * delta)
    if not grounded:
        var gravity := tuning.rise_gravity if velocity.y < 0.0 else tuning.fall_gravity
        velocity.y = minf(velocity.y + gravity * delta, tuning.max_fall_speed)
    elif velocity.y > 0.0:
        velocity.y = 0.0
    if pressed and grounded and input_provider.down_held() and _on_one_way():
        drop_left = tuning.drop_seconds
        set_collision_mask_value(2, false)
        global_position.y += 2.0
        velocity.y = 70.0
        clear_jump_memory()
    elif buffer_left > 0.0 and coyote_left > 0.0:
        _jump(held)
    if jump_active and not held and velocity.y < -tuning.jump_cut_speed:
        velocity.y = -tuning.jump_cut_speed
    var rising_jump := velocity.y < 0 and jump_active and hitstun_left <= 0
    move_and_slide()
    if is_on_ceiling():
        if rising_jump:
            _report_block_bump()
        jump_active = false
        ceiling_bumped.emit()
    if is_on_floor() and not grounded:
        landed.emit()
        if buffer_left > 0.0 and drop_left <= 0.0:
            _jump(held)
    if is_on_floor():
        steps += absf(velocity.x) * delta * 0.1
    visual.position = global_position.round() - global_position
    visual.queue_redraw()

func _report_block_bump() -> void:
    # Query the full head width: slide contacts alone may report just one of
    # two adjoining blocks. Only bottoms at the actual ceiling height count.
    var shape := RectangleShape2D.new()
    shape.size = Vector2(18, 2)
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0, global_position + Vector2(0, -44.5))
    query.collision_mask = 1
    var nearest: Node2D
    var distance := INF
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var body := hit.collider as Node2D
        if body == null or not (body.is_in_group("supply_blocks") or body.is_in_group("head_bump_blocks")):
            continue
        if absf(body.global_position.y + 16 - (global_position.y - 44)) > 2:
            continue
        var candidate := absf(body.global_position.x - global_position.x)
        if candidate < distance or (is_equal_approx(candidate, distance) and (nearest == null or body.global_position.x < nearest.global_position.x)):
            nearest = body
            distance = candidate
    if nearest != null:
        block_bumped.emit(nearest)

func _jump(held: bool) -> void:
    velocity.y = -tuning.jump_speed if held else -tuning.jump_cut_speed
    coyote_left = 0.0
    buffer_left = 0.0
    jump_active = true
    jumped.emit()

func _on_one_way() -> bool:
    for index in get_slide_collision_count():
        var contact := get_slide_collision(index)
        if contact.get_normal().y < -0.5 and contact.get_collider().is_in_group("one_way"):
            return true
    return false

func clear_jump_memory() -> void:
    coyote_left = 0.0
    buffer_left = 0.0
    jump_active = false

func reset_at(at: Vector2) -> void:
    dead = false
    controls_locked = false
    carrying_tool = false
    hitstun_left = 0.0
    movement_scale = 1.0
    global_position = at
    velocity = Vector2.ZERO
    facing = 1
    steps = 0.0
    clear_jump_memory()
    drop_left = 0.0
    set_collision_mask_value(2, true)
    just_respawned = true
    visual.position = Vector2.ZERO

func receive_knockback(impulse: Vector2) -> void:
    hitstun_left = 0.16
    clear_jump_memory()
    velocity = impulse
    just_respawned = true
