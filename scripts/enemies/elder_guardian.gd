class_name ElderGuardian
extends RemixEnemy
signal phase_changed(phase: int)
enum Battle { DORMANT, APPROACH, BEAM_WARNING, BEAM, TIDE_WARNING, TIDE, BURST_WARNING, BURST, RECOVER, PHASE_CHANGE, DEAD }
var battle:=Battle.DORMANT
var active:=false
var second_phase:=false
var timer:=0.0
var arena_left:=364.0
var arena_right:=1236.0
var cycle:=0
var next_attack:=0
var beam_from:=Vector2.ZERO
var beam_to:=Vector2.ZERO
var safe_zone:=Rect2()
var attack_event: DamageEvent
var pending_attack:=false
var attacks_total:=0
var visual_seconds:=0.0

func tuning() -> GuardianData: return data as GuardianData
func phase_value(value: Vector2) -> float: return value.y if second_phase else value.x
func center() -> Vector2: return global_position+Vector2(0,-28)
func eye() -> Vector2: return global_position+Vector2(facing*24,-28)
func burst_charge() -> float:
    return clampf(1.0-timer/phase_value(tuning().burst_warning),0,1) if battle==Battle.BURST_WARNING else 1.0
func exposed() -> bool: return battle==Battle.RECOVER
func melee_opening_bonus(event: DamageEvent) -> int:
    return int(event.get_meta("recovery_bonus",0)) if exposed() else 0

func _ready() -> void:
    super._ready()
    for child in get_children():
        if child is CollisionShape2D:
            child.shape.size=Vector2(72,52)
            child.position.y=-28
    receiver.free()
    receiver=load("res://scripts/enemies/guardian_hurtbox.gd").new()
    receiver.health=health
    receiver.position.y=-28
    receiver.size=Vector2(72,52)
    add_child(receiver)
    receiver.collision_layer=0
    visual.set_script(load("res://scripts/enemies/guardian_visual.gd"))
    visual.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    visual.process_physics_priority=90
    visual.set_physics_process(true)

func activate() -> void:
    if active or health.current<=0: return
    active=true
    receiver.set_deferred("collision_layer",16)
    recover(1.0)

func _physics_process(delta: float) -> void:
    flash_left=maxf(0,flash_left-delta)
    visual_seconds+=delta
    if not active or health.current<=0 or not is_instance_valid(target) or target.dead: return
    timer=maxf(0,timer-delta)
    velocity=Vector2(0,minf(700,velocity.y+1500*delta))
    match battle:
        Battle.RECOVER:
            if timer<=0:
                next_attack=cycle%3
                cycle+=1
                battle=Battle.APPROACH
        Battle.APPROACH:
            var gap:=target.position.x-position.x
            var visible_enough:=is_instance_valid(view_camera) and absf(center().x-view_camera.position.x)<=270
            # Always approach an active target, including when hit from beyond
            # normal projectile range. Never become a dormant ranged target.
            facing=1 if gap>0 else -1
            if absf(gap)<=260 and visible_enough:
                begin_warning(next_attack)
            else:
                velocity.x=facing*tuning().approach_speed
        Battle.BEAM_WARNING, Battle.TIDE_WARNING, Battle.BURST_WARNING:
            if timer<=0: commit_attack()
        Battle.BEAM:
            if timer<=0: recover(phase_value(tuning().recovery))
        Battle.TIDE, Battle.BURST:
            # Reuse the cast's attack_id across the entire hazard window:
            # late entrants can be hit, but each player is hit at most once.
            pending_attack=true
            if timer<=0:
                pending_attack=false
                recover(phase_value(tuning().recovery))
        Battle.PHASE_CHANGE:
            if timer<=0: recover(1.8)
    move_and_slide()
    position.x=clampf(position.x,arena_left,arena_right)

func begin_warning(which: int) -> void:
    if not active or health.current<=0: return
    pending_attack=false
    next_attack=which
    facing=1 if target.position.x>position.x else -1
    velocity.x=0
    fuse_beep.emit()
    match which:
        0:
            battle=Battle.BEAM_WARNING
            timer=phase_value(tuning().beam_warning)
            beam_from=eye()
            var direction: Vector2=(target_center()-beam_from).normalized()
            if direction.length_squared()<0.1: direction=Vector2(facing,0)
            beam_to=beam_from+direction*1200
            var ray:=PhysicsRayQueryParameters2D.create(beam_from,beam_to,1)
            ray.hit_from_inside=true
            var hit:=get_world_2d().direct_space_state.intersect_ray(ray)
            if not hit.is_empty(): beam_to=hit.position
        1:
            battle=Battle.TIDE_WARNING
            timer=phase_value(tuning().tide_warning)
            var width:=phase_value(tuning().safe_width)
            var midpoint: float=(arena_left+arena_right)*0.5
            var safe_x:=clampf(target.position.x+(128 if target.position.x<midpoint else -128),arena_left+width/2,arena_right-width/2)
            safe_zone=Rect2(safe_x-width/2,244,width,44)
        2:
            battle=Battle.BURST_WARNING
            timer=phase_value(tuning().burst_warning)

func commit_attack() -> void:
    attacks_total+=1
    match battle:
        Battle.BEAM_WARNING:
            battle=Battle.BEAM
            timer=0.24
            attack_event=DamageEvent.create(self,2,tuning().beam_damage,Vector2(facing*90,-100))
            attack_event.set_meta("guardian_attack","光束")
        Battle.TIDE_WARNING:
            battle=Battle.TIDE
            timer=0.85
            attack_event=DamageEvent.create(self,2,tuning().tide_damage,Vector2(0,-160))
            attack_event.set_meta("guardian_attack","潮汐")
        Battle.BURST_WARNING:
            battle=Battle.BURST
            timer=tuning().burst_duration
            attack_event=DamageEvent.create(self,2,tuning().burst_damage,Vector2(facing*150,-90))
            attack_event.set_meta("guardian_attack","棘刺")
    pending_attack=true

func recover(seconds: float) -> void:
    battle=Battle.RECOVER
    timer=seconds
    pending_attack=false
    state=State.RECOVER

func tide_safe_x(world_x: float) -> bool:
    # The displayed corridor is authoritative: a player's center inside its
    # inclusive edges is safe even if their hurtbox overlaps the outer water.
    return world_x>=safe_zone.position.x and world_x<=safe_zone.end.x

func tide_danger_regions() -> Array[Rect2]:
    return [Rect2(arena_left-38,244,safe_zone.position.x-(arena_left-38),44),Rect2(safe_zone.end.x,244,arena_right+38-safe_zone.end.x,44)]

func hit_shape(shape: Shape2D,at: Vector2,angle: float=0,exclude_tide_safe: bool=false) -> void:
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(angle,at)
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        if hit.collider is CombatHurtbox:
            if exclude_tide_safe and tide_safe_x(hit.collider.global_position.x): continue
            hit.collider.receive(attack_event)

func late_step() -> void:
    if not active or health.current<=0: return
    if not second_phase and health.current<=health.max_health/2:
        second_phase=true
        battle=Battle.PHASE_CHANGE
        timer=0.9
        pending_attack=false
        velocity=Vector2.ZERO
        phase_changed.emit(2)
        fuse_beep.emit()
        return
    if not pending_attack: return
    pending_attack=false
    match battle:
        Battle.BEAM:
            var shape:=RectangleShape2D.new()
            shape.size=Vector2(beam_from.distance_to(beam_to),tuning().beam_width)
            hit_shape(shape,(beam_from+beam_to)*0.5,(beam_to-beam_from).angle())
        Battle.TIDE:
            for rect in tide_danger_regions():
                if rect.size.x<=0: continue
                var shape:=RectangleShape2D.new()
                shape.size=rect.size
                hit_shape(shape,rect.get_center(),0,true)
        Battle.BURST:
            var shape:=CircleShape2D.new()
            shape.radius=tuning().burst_radius
            hit_shape(shape,center())

func _on_damage(event: DamageEvent) -> void:
    flash_left=0.18
    last_damage=event.amount

func stop_attacks() -> void:
    active=false
    pending_attack=false
    timer=0
    if health.current>0: battle=Battle.DORMANT
    visual.queue_redraw()

func _on_death() -> void:
    stop_attacks()
    battle=Battle.DEAD
    super._on_death()

func reset_target() -> void:
    super.reset_target()
    active=false
    second_phase=false
    battle=Battle.DORMANT
    timer=0
    cycle=0
    attacks_total=0
    pending_attack=false
    beam_from=Vector2.ZERO
    beam_to=Vector2.ZERO
    safe_zone=Rect2()
    receiver.set_deferred("collision_layer",0)

func phase_label() -> String:
    match battle:
        Battle.BEAM_WARNING: return "光束锁定 · 离开金色瞄准线"
        Battle.BEAM: return "光束发射！"
        Battle.TIDE_WARNING: return "潮汐预警 · 进入绿色避潮区"
        Battle.TIDE: return "潮汐喷涌 · 留在绿框内直到退潮"
        Battle.BURST_WARNING: return "棘刺蓄力 · 退到红圈外"
        Battle.BURST: return "棘刺持续 · 红圈内危险！"
        Battle.RECOVER: return "核心虚弱 · 现在反击"
        Battle.PHASE_CHANGE: return "核心觉醒 · 溺尸护卫即将加入"
        Battle.APPROACH: return "正在逼近 · 观察独眼蓄力"
    return "进入神殿，迎战远古守卫者"
