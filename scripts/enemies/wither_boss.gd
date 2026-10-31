class_name WitherBoss
extends RemixEnemy
signal phase_changed(phase: int)
enum Battle { DORMANT, READY, VOLLEY_WARNING, VOLLEY, DESCEND, LOW, ASCEND, DASH_DESCEND, DASH_WARNING, DASH, STUN, PHASE_CHANGE, DEAD, MELEE_WARNING, MELEE, MELEE_RECOVER }
const HIGH_Y:=158.0
const LOW_Y:=244.0
const DASH_Y:=260.0
const LEFT:=374.0
const RIGHT:=906.0
var arena_offset := 0.0
func arena_left() -> float: return LEFT+arena_offset
func arena_right() -> float: return RIGHT+arena_offset
var battle:=Battle.DORMANT
var active:=false
var second_phase:=false
var phase_after_stun:=false
var timer:=0.0
var visual_seconds:=0.0
var low_x:=800.0
var mark:=Vector2.ZERO
var dash_direction:=1
var dash_from:=Vector2.ZERO
var dash_to:=Vector2.ZERO
var dash_event: DamageEvent
var dash_pending:=false
var dash_impacted: Array[int]=[]
var dash_pillars:=0
var shattered_pillars:=0
var melee_direction:=1
var melee_pending:=false
var melee_event: DamageEvent
var melee_attacks:=0
var impact_at:=Vector2.ZERO
var impact_left:=0.0
var ghosts: Array[Dictionary]=[]
var ghost_clock:=0.0
var pending_shot:=false
var volley_count:=0
var cycle:=0
var shots:=0
var low_windows:=0
var pillar_crashes:=0
var demolition_hits:=0
var demolition_lock:=0.0
var skulls: Array[WitherSkull]=[]
var pillars: Array[WitherPillar]=[]
func center() -> Vector2: return global_position
func exposed() -> bool: return battle in [Battle.LOW,Battle.STUN,Battle.MELEE_RECOVER]
func melee_opening_bonus(event: DamageEvent) -> int:
    return int(event.get_meta("recovery_bonus",0)) if exposed() else 0
func _ready() -> void:
    super._ready()
    collision_layer=0
    collision_mask=0
    receiver.free()
    receiver=load("res://scripts/enemies/wither_boss_hurtbox.gd").new()
    receiver.health=health
    receiver.size=Vector2(72,68)
    add_child(receiver)
    receiver.collision_layer=0
    visual.set_script(load("res://scripts/enemies/wither_boss_visual.gd"))
    WitherBossArt.prepare()
func activate() -> void:
    if active or health.current<=0: return
    active=true
    receiver.set_deferred("collision_layer",16)
    battle=Battle.READY
    timer=0.8
func _physics_process(delta: float) -> void:
    visual_seconds+=delta
    flash_left=maxf(0,flash_left-delta)
    impact_left=maxf(0,impact_left-delta)
    for ghost in ghosts: ghost.life-=delta
    ghosts=ghosts.filter(func(ghost: Dictionary) -> bool: return ghost.life>0)
    visual.queue_redraw()
    if not active or health.current<=0 or not is_instance_valid(target) or target.dead: return
    timer=maxf(0,timer-delta)
    demolition_lock=maxf(0,demolition_lock-delta)
    match battle:
        Battle.READY:
            if timer<=0:
                if second_phase and cycle%2==0: battle=Battle.DASH_DESCEND
                else: begin_volley()
                cycle+=1
        Battle.VOLLEY_WARNING:
            if timer<=0:
                battle=Battle.VOLLEY
                volley_count=0
                pending_shot=true
        Battle.VOLLEY:
            if timer<=0:
                if volley_count<3: pending_shot=true
                else: begin_low()
        Battle.DESCEND:
            position=position.move_toward(Vector2(low_x,LOW_Y),200*delta)
            if position.distance_to(Vector2(low_x,LOW_Y))<0.1:
                clear_skulls()
                battle=Battle.LOW
                timer=3.0
                low_windows+=1
        Battle.LOW:
            if timer<=0: battle=Battle.ASCEND
            elif timer<=(2.1 if second_phase else 1.95) and absf(target_center().x-position.x)<126 and absf(target_center().y-position.y)<76:
                begin_melee()
        Battle.MELEE_WARNING:
            if timer<=0:
                battle=Battle.MELEE
                timer=0.20
                melee_pending=true
                melee_attacks+=1
                melee_event=DamageEvent.create(self,2,4 if second_phase else 3,Vector2(melee_direction*160,-100))
                melee_event.set_meta("wither_boss_attack","灵魂横扫")
        Battle.MELEE:
            if timer<=0:
                battle=Battle.MELEE_RECOVER
                timer=1.1 if second_phase else 1.25
        Battle.MELEE_RECOVER:
            if timer<=0: battle=Battle.ASCEND
        Battle.ASCEND:
            position.y=move_toward(position.y,HIGH_Y,180*delta)
            if position.y==HIGH_Y:
                battle=Battle.READY
                timer=0.7
        Battle.DASH_DESCEND:
            position.y=move_toward(position.y,DASH_Y,180*delta)
            if position.y==DASH_Y: begin_dash()
        Battle.DASH_WARNING:
            if timer<=0:
                battle=Battle.DASH
                timer=2.0
                dash_event=DamageEvent.create(self,2,4,Vector2(dash_direction*180,-100))
                dash_event.set_meta("wither_boss_attack","冲刺")
        Battle.DASH:
            ghost_clock-=delta
            if ghost_clock<=0:
                ghost_clock=0.035
                ghosts.append({"at":global_position,"facing":dash_direction,"life":0.20})
                if ghosts.size()>6: ghosts.pop_front()
            var next:=Vector2(clampf(position.x+dash_direction*300*delta,arena_left(),arena_right()),DASH_Y)
            var front:=position+Vector2(dash_direction*36,0)
            var ray:=PhysicsRayQueryParameters2D.create(front,next+Vector2(dash_direction*36,0),1)
            ray.hit_from_inside=true
            var hit:=get_world_2d().direct_space_state.intersect_ray(ray)
            if not hit.is_empty() and hit.collider is WitherPillar and hit.collider.solid():
                impact_at=Vector2(hit.collider.global_position.x,DASH_Y)
                impact_left=0.42
                hit.collider.break_pillar()
                dash_pillars+=1
                shattered_pillars+=1
                if dash_pillars>=2:
                    pillar_crashes+=1
                    stun(2.0)
            if battle==Battle.DASH:
                position=next
                dash_pending=true
                if position.x in [arena_left(),arena_right()] or timer<=0: stun(1.0)
        Battle.STUN:
            if timer<=0:
                if phase_after_stun:
                    phase_after_stun=false
                    battle=Battle.PHASE_CHANGE
                    timer=1.0
                else: battle=Battle.ASCEND
        Battle.PHASE_CHANGE:
            if timer<=0: begin_low()
    if battle not in [Battle.DASH_WARNING,Battle.DASH,Battle.MELEE_WARNING,Battle.MELEE]: facing=1 if target.position.x>position.x else -1
func begin_melee() -> void:
    clear_skulls()
    melee_direction=1 if target_center().x>=position.x else -1
    facing=melee_direction
    melee_pending=false
    battle=Battle.MELEE_WARNING
    timer=0.65 if second_phase else 0.75
    fuse_beep.emit()
func melee_rect() -> Rect2:
    return Rect2(center()+Vector2(8 if melee_direction>0 else -112,-28),Vector2(104,64))
func begin_volley() -> void:
    battle=Battle.VOLLEY_WARNING
    timer=0.85 if second_phase else 1.0
    mark=target_center() # Visible aim stays fixed; later shots never snap to a dodging player.
    pending_shot=false
    fuse_beep.emit()
func begin_low() -> void:
    low_x=clampf(target.position.x+(96 if position.x>=target.position.x else -96),arena_left()+40,arena_right()-40)
    # Do not offer a damage window inside a solid pillar.
    for pillar in pillars:
        if pillar.solid() and absf(low_x-pillar.global_position.x)<62:
            low_x=pillar.global_position.x+(70 if low_x>=pillar.global_position.x else -70)
    low_x=clampf(low_x,arena_left()+16,arena_right()-16)
    battle=Battle.DESCEND
func begin_dash() -> void:
    clear_skulls()
    dash_impacted.clear()
    position.y=DASH_Y
    dash_direction=1 if target.position.x>=position.x else -1
    facing=dash_direction
    dash_from=position
    dash_to=Vector2(arena_right() if dash_direction>0 else arena_left(),DASH_Y)
    battle=Battle.DASH_WARNING
    timer=1.1
    dash_pending=false
    dash_pillars=0
    ghost_clock=0
    ghosts.clear()
    fuse_beep.emit()
func late_step() -> void:
    if not active or health.current<=0: return
    if not second_phase and health.current<=health.max_health/2:
        second_phase=true
        cycle=0
        clear_skulls()
        pending_shot=false
        dash_pending=false
        melee_pending=false
        if battle==Battle.STUN: phase_after_stun=true
        else:
            battle=Battle.PHASE_CHANGE
            timer=1.0
        phase_changed.emit(2)
        return
    if battle==Battle.MELEE and melee_event!=null:
        melee_pending=false
        damage_rect(melee_rect(),melee_event,true)
    if pending_shot and battle==Battle.VOLLEY:
        pending_shot=false
        var skull:=WitherSkull.new()
        skull.shooter=self
        skull.position=position+[Vector2(-24,-14),Vector2(0,-28),Vector2(24,-14)][volley_count]
        skull.velocity=(mark-skull.position).normalized()*(225 if second_phase else 195)
        skull.event=DamageEvent.create(self,2,2)
        skull.event.set_meta("wither_impact",true)
        skull.event.set_meta("wither_boss_attack","头颅弹")
        get_parent().add_child(skull)
        skulls.append(skull)
        shots+=1
        volley_count+=1
        timer=2.0 if volley_count==3 else 0.28
    if dash_pending and battle==Battle.DASH:
        dash_pending=false
        damage_rect(Rect2(center()-Vector2(38,24),Vector2(76,48)),dash_event)
func damage_rect(area: Rect2,event: DamageEvent,cover: bool=false) -> void:
    var query:=PhysicsShapeQueryParameters2D.new()
    var shape:=RectangleShape2D.new()
    shape.size=area.size
    query.shape=shape
    query.transform=Transform2D(0,area.get_center())
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    var space:=get_world_2d().direct_space_state
    for hit in space.intersect_shape(query):
        if not hit.collider is CombatHurtbox: continue
        if cover and not space.intersect_ray(PhysicsRayQueryParameters2D.create(center(),hit.collider.global_position,1)).is_empty(): continue
        hit.collider.receive(event)
        if event==dash_event and battle==Battle.DASH:
            var receiver_id: int=hit.collider.get_instance_id()
            if not dash_impacted.has(receiver_id):
                dash_impacted.append(receiver_id)
                WitherHitBurst.spawn(get_parent(),hit.collider.global_position,second_phase)
func stun(seconds: float) -> void:
    clear_skulls()
    pending_shot=false
    dash_pending=false
    melee_pending=false
    battle=Battle.STUN
    position.y=LOW_Y
    timer=seconds
func clear_skulls() -> void:
    for skull in skulls:
        if is_instance_valid(skull): skull.retire()
    skulls.clear()
func _on_damage(event: DamageEvent) -> void:
    flash_left=0.2
    last_damage=event.amount
    if event.get_meta("wither_demolition",false):
        demolition_hits+=1
        if demolition_lock<=0 and health.current>0:
            stun(3.0)
            demolition_lock=5.0
func stop_attacks() -> void:
    active=false
    pending_shot=false
    dash_pending=false
    melee_pending=false
    ghosts.clear()
    impact_left=0
    clear_skulls()
    if health.current>0: battle=Battle.DORMANT
func _on_death() -> void:
    stop_attacks()
    battle=Battle.DEAD
    super._on_death()
func reset_target() -> void:
    clear_skulls()
    dash_impacted.clear()
    super.reset_target()
    active=false
    second_phase=false
    phase_after_stun=false
    battle=Battle.DORMANT
    timer=0
    cycle=0
    shots=0
    low_windows=0
    pillar_crashes=0
    shattered_pillars=0
    dash_pillars=0
    melee_attacks=0
    melee_pending=false
    ghost_clock=0
    ghosts.clear()
    impact_left=0
    demolition_hits=0
    demolition_lock=0
    pending_shot=false
    dash_pending=false
    receiver.set_deferred("collision_layer",0)
func phase_label() -> String:
    match battle:
        Battle.VOLLEY_WARNING: return "三头锁定 · 离开瞄准线或借石柱挡弹"
        Battle.VOLLEY: return "头颅齐射 · 保持移动，随后低空反击"
        Battle.DESCEND,Battle.LOW: return "低空接战 · 短暂反击，留意近身横扫"
        Battle.MELEE_WARNING: return "灵魂横扫蓄力 · 退到红弧外或绕到背后"
        Battle.MELEE: return "横扫！不要留在正面"
        Battle.MELEE_RECOVER: return "横扫收招 · 现在反击"
        Battle.DASH_DESCEND: return "即将俯冲 · 看清红色冲刺方向"
        Battle.DASH_WARNING: return "护壳冲刺 · 首根石柱挡不住，准备跳躲"
        Battle.DASH: return "护壳已破 · 再撞一柱才能眩晕" if dash_pillars>0 else "冲锋！首根柱会碎，跳过或绕到身后"
        Battle.STUN: return "眩晕 %.1f 秒 · 抓紧反击"%timer
        Battle.PHASE_CHANGE: return "半血狂暴 · 可以继续移动，没有接触伤害"
    return "观察三颗头颅 · 石柱可恢复，TNT是可选战术"
