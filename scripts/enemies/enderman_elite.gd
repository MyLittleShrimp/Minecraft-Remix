class_name EndermanElite
extends EndermanEnemy
## Two committed, readable warp patterns. No contact damage or arrow immunity.
var technique:=0
var cycles:=0
var decoy:=Vector2.INF
var locked_facing:=1
var second_phase:=false
var waking:=true
var attack_reach:=88.0
var recovery_seconds:=1.25
var materialize_seconds:=0.35
var strike_damage:=3
var phase_casts:=0
var support: WardenSupport

func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/enderman_elite_visual.gd"))
    support=WardenSupport.new()
    add_child(support)

func activate_guard() -> void:
    super.activate_guard()
    if health.current>0:
        state_left=1.1
        support.request_guard(1)

func start_teleport() -> bool:
    if not encounter_enabled or not provoked or warp_cooldown>0 or health.current<=0: return false
    if not is_instance_valid(target) or target.dead or not inside_encounter(target.position) or not on_camera(): return false
    technique=cycles%2
    attack_reach=88.0 if technique==0 else 112.0
    materialize_seconds=0.30 if technique==0 else 0.35
    recovery_seconds=(0.9 if second_phase else 1.05) if technique==0 else (1.1 if second_phase else 1.2)
    var distance:=76.0 if technique==0 else 100.0
    var preferred:= -1.0 if cycles%4<2 else 1.0
    var chosen:=Vector2.INF
    decoy=Vector2.INF
    for direction in [preferred,-preferred]:
        var at:=Vector2(target.position.x+direction*distance,288)
        if at.distance_to(position)<=MAX_TELEPORT_DISTANCE and landing_valid(at) and absf(at.x-view_camera.global_position.x)<280:
            if not chosen.is_finite(): chosen=at
            elif technique==1: decoy=at
    warp_cooldown=2.4 if second_phase else 2.65
    if not chosen.is_finite():
        recover()
        return false
    waking=false
    cycles+=1
    if second_phase: phase_casts+=1
    strike_damage=4 if second_phase else 3
    warp_to=chosen
    locked_facing=1 if target.position.x>chosen.x else -1
    warp_left=(0.65 if second_phase else 0.75) if technique==0 else (0.75 if second_phase else 0.85)
    velocity=Vector2.ZERO
    state=State.CHASE
    return true

func recover() -> void:
    super.recover()
    state_left=recovery_seconds
    decoy=Vector2.INF

func _tick_walker() -> void:
    velocity.x=0
    if not encounter_enabled:
        state=State.PATROL
        return
    if not is_instance_valid(target) or target.dead or not inside_encounter(target.position):
        recover()
        return
    if warp_left>=0:
        warp_left=maxf(0,warp_left-get_physics_process_delta_time())
        if warp_left<=0:
            warp_left=-1
            if not landing_valid(warp_to) or not on_camera():
                recover()
                return
            position=warp_to
            velocity=Vector2.ZERO
            facing=locked_facing
            teleports+=1
            state=State.AIM
            state_left=materialize_seconds
        return
    if state==State.AIM:
        if state_left<=0:
            recover()
            strike_pending=true
        return
    if state==State.RECOVER and state_left>0: return
    waking=false
    if second_phase and phase_casts%3==0 and start_rift(): return
    if start_teleport(): return
    # Distant arrows never leave a living guard idle. Chase until a legal warp
    # is available, retaining the same fixed warning and materialization tell.
    facing=1 if target.position.x>position.x else -1
    state=State.CHASE
    if absf(target.position.x-position.x)>96 and safe_step(facing) and inside_encounter(position+Vector2(facing*24,0)):
        velocity.x=facing*data.chase_speed

func late_step() -> void:
    if not strike_pending: return
    strike_pending=false
    if not encounter_enabled or health.current<=0 or target.dead: return
    strikes+=1
    strike_flash=0.18
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(attack_reach,48)
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,center()+Vector2(facing*attack_reach/2,0))
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    var event:=DamageEvent.create(self,2,strike_damage,Vector2(facing*140,-100))
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var victim:=hit.collider as CombatHurtbox
        if victim!=null and clear_line(victim.global_position): victim.receive(event)

func _on_damage(event: DamageEvent) -> void:
    if not encounter_enabled: return
    provoked=true
    flash_left=0.25
    last_damage=event.amount
    # Half health changes subsequent attacks, never the current tell or input.
    if not second_phase and health.current>0 and health.current<=health.max_health/2:
        second_phase=true
        phase_casts=0
        support.phase_banner=2.2
        support.request_guard(2)
    hitstun=0

func _on_death() -> void:
    if is_instance_valid(support): support.clear_all()
    decoy=Vector2.INF
    super._on_death()

func reset_target() -> void:
    super.reset_target()
    if is_instance_valid(support): support.clear_all()
    phase_casts=0
    strike_damage=3
    technique=0
    cycles=0
    decoy=Vector2.INF
    second_phase=false
    waking=true
    attack_reach=88
    recovery_seconds=1.25
    materialize_seconds=0.35

func phase_label() -> String:
    if support.rift_left>0:
        return "裂隙爆发 · 离开红柱" if support.rift_age<support.RIFT_WARNING else "裂隙爆发 · 等红柱熄灭"
    if waking: return "封印苏醒 · 看地面亮框"
    if warp_left>=0: return "侧移挥击 · 离开亮框前方" if technique==0 else "双影突袭 · 亮框是真身，虚线是残影"
    if state==State.AIM: return "挥击将至 · 跳起或退开"
    if state==State.RECOVER: return "收招破绽 · 靠近反击"
    return "逼近中 · 保持移动"

func start_rift() -> bool:
    if not encounter_enabled or not second_phase or health.current<=0 or warp_cooldown>0: return false
    if not is_instance_valid(target) or target.dead or not inside_encounter(target.position) or not on_camera(): return false
    technique=2
    waking=false
    phase_casts+=1
    cycles+=1
    decoy=Vector2.INF
    warp_left=-1
    strike_pending=false
    velocity=Vector2.ZERO
    support.begin_rift()
    state=State.RECOVER
    state_left=support.RIFT_WARNING+support.RIFT_ACTIVE+1.0
    warp_cooldown=state_left
    return true
