class_name SkeletonCaptain
extends RemixEnemy

signal reinforcement_requested(at: Vector2)
signal phase_changed(phase: int)
enum Battle { DORMANT, AIM, BURST, RECOVER, SHIFT_WARNING, SHIFT, DEAD, APPROACH }
var battle: Battle = Battle.DORMANT
var active: bool = false
var second_phase: bool = false
var timer: float = 0
var shots_left: int = 0
var shot_due: bool = false
var aim_direction: Vector2 = Vector2.LEFT
var shift_goal: float = 8400
var arena_left: float = 8192
var arena_right: float = 9152
var shots_total: int = 0
var summons_total: int = 0

func tuning() -> CaptainData:
    return data as CaptainData

func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/captain_visual.gd"))
    receiver.position.y = -27
    receiver.get_child(0).shape.size = Vector2(28,54)
    receiver.collision_layer = 0

func center() -> Vector2:
    return global_position + Vector2(0,-27)

func activate() -> void:
    if active or health.current <= 0:
        return
    active = true
    receiver.set_deferred("collision_layer",16)
    battle = Battle.RECOVER
    timer = 0.8

func _physics_process(delta: float) -> void:
    flash_left = maxf(0, flash_left - delta)
    visual.queue_redraw()
    if not active or state == State.DEAD:
        return
    if not is_instance_valid(target) or target.dead:
        velocity = Vector2.ZERO
        return
    # Visibility limits firing, not encounter awareness. Otherwise a long-range
    # player arrow can damage an active captain whose entire AI is frozen.
    if not on_camera() and battle in [Battle.RECOVER, Battle.AIM, Battle.BURST]:
        _begin_approach()
    timer = maxf(0,timer-delta)
    velocity.y = minf(700,velocity.y+1500*delta)
    velocity.x = 0
    match battle:
        Battle.APPROACH:
            var distance := target.global_position.x-global_position.x
            var comfortably_visible := on_camera() and absf(center().x-view_camera.global_position.x) <= 320.0-tuning().camera_inset
            if comfortably_visible and absf(distance)<=tuning().approach_distance and is_on_floor():
                _recover(0.25)
            else:
                _approach_target(distance)
        Battle.RECOVER:
            if timer <= 0: _begin_aim()
        Battle.AIM:
            if timer <= 0:
                battle = Battle.BURST
                shots_left = tuning().burst_count
                shot_due = true
        Battle.BURST:
            if timer <= 0: shot_due = true
        Battle.SHIFT_WARNING:
            if timer <= 0:
                battle = Battle.SHIFT
                shift_goal = arena_left + 208 if global_position.x > (arena_left+arena_right)*0.5 else arena_right-208
                velocity.y = -420
                summons_total += 1
                reinforcement_requested.emit(spawn_point)
        Battle.SHIFT:
            var distance := shift_goal-global_position.x
            facing = 1 if distance > 0 else -1
            velocity.x = clampf(distance*8,-tuning().shift_speed,tuning().shift_speed)
            if is_on_floor() and not safe_step(facing) and absf(distance)>10:
                velocity.y = -420
            if absf(distance)<6 and is_on_floor():
                velocity.x = 0
                _recover(tuning().recovery_seconds)
    move_and_slide()
    steps += absf(velocity.x)*delta*0.1
    visual.position = global_position.round()-global_position

func _begin_approach() -> void:
    _recover(0)
    battle = Battle.APPROACH
    state = State.CHASE

func _approach_target(distance: float) -> void:
    if absf(distance)<6: return
    facing = 1 if distance>0 else -1
    var goal := clampf(target.global_position.x,arena_left+32,arena_right-32)
    velocity.x = clampf((goal-global_position.x)*8,-tuning().approach_speed,tuning().approach_speed)
    if is_on_floor() and not safe_step(facing):
        velocity.y = -420

func _begin_aim() -> void:
    if not is_instance_valid(target) or target.dead or not on_camera():
        return
    aim_direction = (target_center()-center()).normalized()
    facing = 1 if aim_direction.x > 0 else -1
    battle = Battle.AIM
    timer = tuning().warning_seconds * (0.8 if second_phase else 1.0)
    state = State.AIM

func _recover(seconds: float) -> void:
    battle = Battle.RECOVER
    state = State.RECOVER
    timer = seconds
    shot_due = false
    shots_left = 0

func late_step() -> void:
    # Resolve health at priority 70 first: a lethal hit cancels a due volley.
    if not active or health.current <= 0 or state == State.DEAD:
        return
    if not second_phase and health.current <= floori(health.max_health*tuning().phase_two_ratio):
        second_phase = true
        battle = Battle.SHIFT_WARNING
        state = State.RECOVER
        timer = tuning().shift_warning
        shot_due = false
        shots_left = 0
        phase_changed.emit(2)
        return
    if shot_due and on_camera() and is_instance_valid(target) and not target.dead:
        shot_due = false
        var arrow := ArrowProjectile.new()
        arrow.position = get_parent().to_local(center())
        arrow.velocity = aim_direction*data.arrow_speed
        arrow.event = DamageEvent.create(self,2,tuning().arrow_damage,Vector2(facing*130,-100))
        get_parent().add_child(arrow)
        shots_total += 1
        fired.emit(arrow)
        shots_left -= 1
        if shots_left <= 0:
            _recover(tuning().recovery_seconds * (0.82 if second_phase else 1.0))
        else:
            timer = tuning().burst_interval * (0.75 if second_phase else 1.0)

func _on_damage(event: DamageEvent) -> void:
    # Hits do not restart the telegraph or shove the boss outside the arena.
    flash_left = 0.35
    last_damage = event.amount

func _on_death() -> void:
    battle = Battle.DEAD
    active = false
    shot_due = false
    shots_left = 0
    super._on_death()

func reset_target() -> void:
    super.reset_target()
    active = false
    second_phase = false
    battle = Battle.DORMANT
    timer = 0
    shots_left = 0
    shot_due = false
    shots_total = 0
    summons_total = 0
    receiver.set_deferred("collision_layer",0)

func phase_label() -> String:
    match battle:
        Battle.APPROACH: return "队长逼近 · 准备躲避抬弓预警"
        Battle.AIM: return "抬弓预警 · 离开金色箭道"
        Battle.BURST: return "三连箭 · 跳跃或躲到掩体后"
        Battle.RECOVER: return "恢复窗口 · 靠近挥剑或蓄力射击"
        Battle.SHIFT_WARNING: return "半血换边 · 留意援兵"
        Battle.SHIFT: return "正在换边 · 追击或重新找掩体"
    return "走入大厅，挑战队长"
