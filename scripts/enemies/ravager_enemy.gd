class_name RavagerEnemy
extends RemixEnemy

signal phase_changed(phase: int)
const DEMOLITION_STUN_SECONDS := 3.0
enum Battle { DORMANT, APPROACH, RECOVER, CHARGE_WARNING, CHARGE, HORN_WARNING, HORN, STOMP_WARNING, STOMP, PHASE_CHANGE, DEAD, TURN }
var battle:=Battle.DORMANT
var active:=false
var second_phase:=false
var timer:=0.0
var arena_left:=376.0
var arena_right:=1224.0
var cycle:=0
var next_attack:=0
var charge_start:=0.0
var charge_number:=0
var attack_event: DamageEvent
var pending_hit:=false
var pending_wave:=false
var waves_left:=0
var hit_from_x:=0.0
var vulnerable:=false
var waves: Array[RavagerWave]=[]
var attacks_total:=0
var pillar_hits:=0
var turn_to_warning:=false
var turn_followup:=false
var demolition_stun:=false

func tuning() -> RavagerData: return data as RavagerData
func phase_value(values: Vector2) -> float: return values.y if second_phase else values.x
func center() -> Vector2: return global_position+Vector2(0,-28)
func exposed() -> bool: return battle==Battle.RECOVER and vulnerable
func melee_opening_bonus(event: DamageEvent) -> int:
    return int(event.get_meta("recovery_bonus",0)) if exposed() else 0

func _ready() -> void:
    super._ready()
    for child in get_children():
        if child is CollisionShape2D:
            child.shape.size=Vector2(80,56)
            child.position.y=-28
    receiver.free()
    receiver=load("res://scripts/enemies/ravager_hurtbox.gd").new()
    receiver.health=health
    receiver.size=Vector2(80,56)
    receiver.position.y=-28
    add_child(receiver)
    receiver.collision_layer=0
    visual.set_script(load("res://scripts/enemies/ravager_visual.gd"))
    RavagerArt.prepare()
    visual.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    # Read the final state after health (70) and phase/attack resolution (80).
    visual.process_physics_priority=90
    visual.set_physics_process(true)

func activate() -> void:
    if active or health.current<=0: return
    active=true
    receiver.set_deferred("collision_layer",16)
    _recover(0.8,false)

func _physics_process(delta: float) -> void:
    flash_left=maxf(0,flash_left-delta)
    visual.queue_redraw()
    if not active or health.current<=0 or not is_instance_valid(target) or target.dead: return
    timer=maxf(0,timer-delta)
    velocity.x=0
    velocity.y=minf(700,velocity.y+1500*delta)
    hit_from_x=position.x
    match battle:
        Battle.RECOVER:
            if timer<=0:
                next_attack=cycle%3
                cycle+=1
                battle=Battle.APPROACH
                vulnerable=false
        Battle.APPROACH:
            var gap:=target.position.x-position.x
            var distance:=108.0 if next_attack==1 else 260.0
            # An 80px body is fully visible at +/-280 in the 640px viewport.
            # Arena pillars clamp its center 264px from the edge camera; a
            # 250px threshold would leave it walking into that clamp forever.
            var visible_enough:=is_instance_valid(view_camera) and absf(center().x-view_camera.position.x)<=280
            if absf(gap)<=distance and visible_enough:
                _warn(next_attack)
            elif _target_direction()!=facing:
                _begin_turn(_target_direction(),false)
            else:
                velocity.x=facing*tuning().approach_speed
        Battle.TURN:
            if timer<=0:
                if turn_to_warning: _begin_warning(next_attack,turn_followup)
                else: battle=Battle.APPROACH
        Battle.CHARGE_WARNING, Battle.HORN_WARNING, Battle.STOMP_WARNING:
            if not on_camera():
                battle=Battle.APPROACH
            else:
                # A shown warning commits its direction. Crossing behind the
                # boss must not silently retarget a nearly finished windup.
                if timer<=0: _commit()
        Battle.CHARGE:
            velocity.x=facing*phase_value(tuning().charge_speed)
            pending_hit=true
        Battle.HORN:
            pending_hit=true
            if timer<=0: _recover(phase_value(tuning().horn_recovery))
        Battle.STOMP:
            if timer<=0:
                if waves_left>0:
                    pending_wave=true
                    waves_left-=1
                    if waves_left>0: timer=0.55
                    else: _recover(tuning().stomp_recovery)
                else: _recover(tuning().stomp_recovery)
        Battle.PHASE_CHANGE:
            if timer<=0: _recover(0.35,false)
    move_and_slide()
    position.x=clampf(position.x,arena_left,arena_right)
    steps+=absf(velocity.x)*delta*0.1
    if battle==Battle.CHARGE:
        var pillar:=position.x<=arena_left+0.1 or position.x>=arena_right-0.1
        if pillar:
            pillar_hits+=1
            _recover(tuning().pillar_stun)
        elif absf(position.x-charge_start)>=tuning().charge_distance:
            if second_phase and charge_number==1:
                charge_number=2
                _warn(0,true)
            else: _recover(phase_value(tuning().charge_recovery))
    visual.position=global_position.round()-global_position

func _warn(which: int, followup: bool=false) -> void:
    next_attack=which
    if _target_direction()!=facing:
        _begin_turn(_target_direction(),true,followup)
        return
    _begin_warning(which,followup)

func _target_direction() -> int:
    var gap:=target.position.x-position.x
    return facing if absf(gap)<8 else (1 if gap>0 else -1)

func _begin_turn(direction: int, then_warn: bool, followup: bool=false) -> void:
    battle=Battle.TURN
    facing=direction
    timer=tuning().turn_seconds
    velocity.x=0
    vulnerable=false
    turn_to_warning=then_warn
    turn_followup=followup
    fuse_beep.emit()

func _begin_warning(which: int, followup: bool=false) -> void:
    vulnerable=false
    fuse_beep.emit()
    match which:
        0:
            battle=Battle.CHARGE_WARNING
            timer=phase_value(tuning().charge_warning)
            if not followup: charge_number=1
        1:
            battle=Battle.HORN_WARNING
            timer=phase_value(tuning().horn_warning)
        2:
            battle=Battle.STOMP_WARNING
            timer=phase_value(tuning().stomp_warning)

func _commit() -> void:
    attacks_total+=1
    match battle:
        Battle.CHARGE_WARNING:
            battle=Battle.CHARGE
            charge_start=position.x
            attack_event=DamageEvent.create(self,2,4,Vector2(facing*220,-160))
        Battle.HORN_WARNING:
            battle=Battle.HORN
            timer=0.12
            attack_event=DamageEvent.create(self,2,3,Vector2(facing*160,-130))
        Battle.STOMP_WARNING:
            battle=Battle.STOMP
            waves_left=2 if second_phase else 1
            timer=0

func _recover(seconds: float, opening: bool=true) -> void:
    battle=Battle.RECOVER
    state=State.RECOVER
    timer=seconds
    vulnerable=opening

func late_step() -> void:
    if not active or health.current<=0: return
    if not second_phase and health.current<=health.max_health/2:
        second_phase=true
        battle=Battle.PHASE_CHANGE
        timer=0.8
        velocity.x=0
        vulnerable=false
        pending_hit=false
        pending_wave=false
        clear_waves()
        phase_changed.emit(2)
        fuse_beep.emit()
        return
    if demolition_stun and battle!=Battle.PHASE_CHANGE:
        demolition_stun=false
        _recover(DEMOLITION_STUN_SECONDS)
    if pending_hit:
        pending_hit=false
        var horn: bool=attack_event.amount==3
        var shape:=RectangleShape2D.new()
        shape.size=Vector2(76,42) if horn else Vector2(80+absf(position.x-hit_from_x),48)
        var at:=center()+Vector2(facing*38,3) if horn else Vector2((position.x+hit_from_x)/2,position.y-24)
        var query:=PhysicsShapeQueryParameters2D.new()
        query.shape=shape
        query.transform=Transform2D(0,at)
        query.collision_mask=8
        query.collide_with_areas=true
        query.collide_with_bodies=false
        for hit in get_world_2d().direct_space_state.intersect_shape(query):
            if hit.collider is CombatHurtbox: hit.collider.receive(attack_event)
    if pending_wave:
        pending_wave=false
        exploded.emit()
        for direction in [-1,1]:
            var wave:=RavagerWave.new()
            wave.boss=self
            wave.direction=direction
            wave.position=position+Vector2(direction*42,0)
            get_parent().add_child(wave)
            waves.append(wave)

func clear_waves() -> void:
    for wave in waves:
        if is_instance_valid(wave): wave.retire()
    waves.clear()

func _on_damage(event: DamageEvent) -> void:
    flash_left=0.18
    last_damage=event.amount
    if event.get_meta("ravager_demolition",false):
        demolition_stun=true
        pending_hit=false
        pending_wave=false
        clear_waves()
        if health.current>0 and battle!=Battle.PHASE_CHANGE: _recover(DEMOLITION_STUN_SECONDS)

func _on_death() -> void:
    active=false
    battle=Battle.DEAD
    pending_hit=false
    pending_wave=false
    clear_waves()
    super._on_death()

func reset_target() -> void:
    clear_waves()
    super.reset_target()
    active=false
    second_phase=false
    battle=Battle.DORMANT
    timer=0
    cycle=0
    charge_number=0
    attacks_total=0
    pillar_hits=0
    pending_hit=false
    pending_wave=false
    vulnerable=false
    turn_to_warning=false
    turn_followup=false
    demolition_stun=false
    receiver.set_deferred("collision_layer",0)

func phase_label() -> String:
    match battle:
        Battle.TURN: return "回身蓄势 · 拉开距离，准备躲避"
        Battle.CHARGE_WARNING: return "再次冲撞！准备跳跃" if charge_number==2 else "低头蓄力 · 准备跳过冲撞"
        Battle.CHARGE: return "冲撞！跳过躯干 · 引向石柱"
        Battle.HORN_WARNING, Battle.HORN: return "抬角横扫 · 退后或绕到背后"
        Battle.STOMP_WARNING, Battle.STOMP: return "震地波 · 看准石浪再跳"
        Battle.RECOVER: return "撞柱 / 收招破绽 · 现在反击" if vulnerable else "保持距离 · 观察起手"
        Battle.PHASE_CHANGE: return "岩甲开裂 · 二阶段：连冲与双地波"
        Battle.APPROACH: return "正在逼近 · 注意下一招"
    return "裂岩试炼"
