class_name PiglinBrute
extends RemixEnemy
## All three roles share room isolation; attack direction is committed at windup.
var active := true
var encounter_bounds := Vector2(-INF,INF)
var strike_pending := false
var swing_flash := 0.0
var strikes := 0
var ammo := 2
var aim_duration := 0.0
var aim_vector := Vector2.RIGHT
var bolts: Array[ArrowProjectile] = []
var stats: PiglinData:
    get: return data as PiglinData
func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/piglin_visual.gd"))
    set_active(active)
func set_active(value: bool) -> void:
    active=value
    receiver.set_deferred("collision_layer",16 if value and health.current>0 else 0)
    velocity=Vector2.ZERO
    strike_pending=false
    if value:
        state=State.RECOVER
        state_left=0.65
    else: _clear_bolts()
func _physics_process(delta: float) -> void:
    if not active:
        visual.queue_redraw()
        return
    swing_flash=maxf(0,swing_flash-delta)
    super._physics_process(delta)
    global_position.x=clampf(global_position.x,encounter_bounds.x,encounter_bounds.y)
func _valid_target() -> bool:
    return is_instance_valid(target) and not target.dead and target.position.x>=encounter_bounds.x-18 and target.position.x<=encounter_bounds.y+18
func _aim(seconds: float) -> void:
    facing=1 if target_center().x>center().x else -1
    aim_vector=(target_center()-muzzle()).normalized()
    aim_duration=seconds
    state=State.AIM
    state_left=seconds
func muzzle() -> Vector2: return center()+Vector2(facing*27,-16)
func _tick_walker() -> void:
    velocity.x=0
    if state==State.AIM:
        if not _valid_target():
            state=State.RECOVER
            state_left=stats.reload_seconds
            ammo=0
        elif state_left<=0:
            state=State.RECOVER
            state_left=data.shot_recovery
            strike_pending=true
        return
    if state==State.RECOVER and state_left>0: return
    if not _valid_target(): return
    var distance:=absf(target_center().x-center().x)
    facing=1 if target_center().x>center().x else -1
    if stats.role==PiglinData.Role.CROSSBOW:
        if ammo==0: ammo=2
        if on_camera() and clear_line(target_center()) and distance<=360:
            _aim(data.aim_seconds)
        else:
            state=State.CHASE
            velocity.x=facing*data.chase_speed if safe_step(facing) else 0.0
    elif distance<stats.reach-6 and absf(target.position.y-position.y)<48 and clear_line(target_center()):
        _aim(data.aim_seconds)
    else:
        state=State.CHASE
        velocity.x=facing*data.chase_speed if safe_step(facing) else 0.0
func late_step() -> void:
    if not strike_pending: return
    strike_pending=false
    if not active or health.current<=0 or state==State.DEAD: return
    strikes+=1
    swing_flash=0.18
    if stats.role==PiglinData.Role.CROSSBOW:
        var arrow:=ArrowProjectile.new()
        arrow.position=get_parent().to_local(muzzle())
        arrow.velocity=aim_vector*data.arrow_speed
        arrow.event=DamageEvent.create(self,2,stats.damage,Vector2(facing*135,-75))
        arrow.bolt=true
        get_parent().add_child(arrow)
        bolts=bolts.filter(func(b): return is_instance_valid(b))
        bolts.append(arrow)
        fired.emit(arrow)
        ammo-=1
        if ammo>0 and _valid_target(): _aim(stats.followup_aim)
        else:
            ammo=0
            state=State.RECOVER
            state_left=stats.reload_seconds
        return
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(stats.reach,46)
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,center()+Vector2(facing*stats.reach*0.5,0))
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var victim:=hit.collider as CombatHurtbox
        if victim!=null and clear_line(victim.global_position):
            victim.receive(DamageEvent.create(self,2,stats.damage,Vector2(facing*190,-130)))
func _on_damage(event: DamageEvent) -> void:
    strike_pending=false
    if stats.role==PiglinData.Role.AXE and state==State.AIM:
        flash_left=0.25
        last_damage=event.amount
    else:
        super._on_damage(event)
        if stats.role==PiglinData.Role.CROSSBOW:
            ammo=0
            state=State.RECOVER
            state_left=stats.reload_seconds
func melee_opening_bonus(event: DamageEvent) -> int:
    if strikes>0 and state==State.RECOVER and state_left>0 and not strike_pending:
        return int(event.get_meta("recovery_bonus",0))
    return 0
func _clear_bolts() -> void:
    for bolt in bolts:
        if is_instance_valid(bolt): bolt.retire()
    bolts.clear()
func _on_death() -> void:
    strike_pending=false
    swing_flash=0
    _clear_bolts()
    super._on_death()
func reset_target() -> void:
    _clear_bolts()
    super.reset_target()
    strike_pending=false
    swing_flash=0
    strikes=0
    ammo=2
    aim_duration=0
    set_active(active)
