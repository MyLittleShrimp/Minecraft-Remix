class_name EnderDragon
extends RemixEnemy
signal phase_changed(phase: int)
enum Battle { DORMANT, READY, BREATH_WARNING, BREATH, DESCEND, LOW, BITE_WARNING, BITE, RECOVER, ASCEND, DIVE_WARNING, DIVE, DIVE_RECOVER, PHASE_CHANGE, DEAD, TAIL_WARNING, TAIL }
var battle:=Battle.DORMANT
var active:=false
var second_phase:=false
var timer:=0.0
var visual_seconds:=0.0
var head: CombatHurtbox
var crystals: Array[EndCrystal]=[]
var heal_clock:=0.0
var healed:=0
var beam_index:=-1
var all_broken_reward:=false
var extra_low:=false
var breath_rect:=Rect2()
var bite_rect:=Rect2()
var dive_from:=Vector2.ZERO
var dive_to:=Vector2.ZERO
var dive_duration:=0.65
var low_goal:=Vector2.ZERO
var attack_event: DamageEvent
var low_windows:=0
var dives:=0
var breaths:=0
var tail_rect:=Rect2()
var tail_sweeps:=0
var dive_chain:=0
func center() -> Vector2: return global_position
func create_health() -> HealthComponent: return load("res://scripts/enemies/dragon_health.gd").new()
func exposed() -> bool: return battle in [Battle.LOW,Battle.RECOVER]
func melee_opening_bonus(event: DamageEvent) -> int:
    return int(event.get_meta("recovery_bonus",0)) if exposed() else 0
func _ready() -> void:
    super._ready()
    collision_layer=0
    collision_mask=0
    receiver.free()
    receiver=load("res://scripts/enemies/dragon_hurtbox.gd").new()
    receiver.health=health
    receiver.size=Vector2(84,38)
    add_child(receiver)
    receiver.collision_layer=0
    head=load("res://scripts/enemies/dragon_hurtbox.gd").new()
    head.health=health
    head.size=Vector2(48,32)
    head.head=true
    head.hit_priority=1
    add_child(head)
    head.collision_layer=0
    visual.set_script(load("res://scripts/enemies/dragon_visual.gd"))
    _sync_head()
func _sync_head() -> void: head.position=Vector2(facing*81,8)
func activate() -> void:
    if active or health.current<=0: return
    active=true
    for box in [receiver,head]: box.set_deferred("collision_layer",16)
    for crystal in crystals: crystal.set_active(true)
    battle=Battle.READY
    timer=1.0
func _physics_process(delta: float) -> void:
    visual_seconds+=delta
    flash_left=maxf(0,flash_left-delta)
    visual.queue_redraw()
    if not active or health.current<=0 or target.dead: return
    timer=maxf(0,timer-delta)
    heal_clock+=delta
    _sync_head()
    match battle:
        Battle.READY:
            if timer<=0 and not crystal_warning(): begin_breath()
        Battle.BREATH_WARNING:
            if timer<=0 and not crystal_warning():
                battle=Battle.BREATH
                timer=2.0
                breaths+=1
                attack_event=DamageEvent.create(self,2,4 if second_phase else 3)
        Battle.BREATH:
            if timer<=0: begin_low()
        Battle.DESCEND:
            position=position.move_toward(low_goal,420*delta)
            if position.distance_to(low_goal)<0.1:
                battle=Battle.LOW
                timer=(2.1 if second_phase else 3.5)+(3.5 if extra_low else 0.0)
                extra_low=false
                low_windows+=1
        Battle.LOW:
            if timer<=0 and not crystal_warning(): begin_bite()
        Battle.BITE_WARNING:
            if timer<=0 and not crystal_warning():
                battle=Battle.BITE
                timer=0.2
                attack_event=DamageEvent.create(self,2,4 if second_phase else 3)
        Battle.BITE:
            if timer<=0:
                if second_phase: begin_tail()
                else:
                    battle=Battle.RECOVER
                    timer=1.0
        Battle.TAIL_WARNING:
            if timer<=0 and not crystal_warning():
                battle=Battle.TAIL
                timer=0.25
                tail_sweeps+=1
                attack_event=DamageEvent.create(self,2,4)
        Battle.TAIL:
            if timer<=0:
                battle=Battle.RECOVER
                timer=0.65
        Battle.RECOVER:
            if timer<=0: battle=Battle.ASCEND
        Battle.ASCEND:
            position=position.move_toward(Vector2(720,156),420*delta)
            if position.distance_to(Vector2(720,156))<0.1:
                if low_windows%2==0:
                    battle=Battle.READY
                    timer=0.9 if second_phase else 1.3
                else: begin_dive()
        Battle.DIVE_WARNING:
            position=position.move_toward(dive_from,650*delta)
            if timer<=0 and not crystal_warning():
                battle=Battle.DIVE
                dive_duration=0.55 if second_phase else 0.65
                timer=dive_duration
                dives+=1
                attack_event=DamageEvent.create(self,2,4)
        Battle.DIVE:
            position=dive_from.lerp(dive_to,1.0-timer/dive_duration)
            if timer<=0:
                battle=Battle.DIVE_RECOVER
                timer=0.7
        Battle.DIVE_RECOVER:
            if timer<=0:
                if second_phase and dive_chain==0:
                    dive_chain=1
                    begin_dive(true)
                else: begin_low()
        Battle.PHASE_CHANGE:
            if timer<=0: begin_dive()
func living_crystals() -> int:
    var count:=0
    for crystal in crystals: count+=int(crystal.health.current>0)
    return count
func crystal_warning() -> bool:
    for crystal in crystals:
        if crystal.warning_left>0: return true
    return false
func begin_breath() -> void:
    battle=Battle.BREATH_WARNING
    timer=1.0 if second_phase else 0.9
    var width:=192.0 if second_phase else 168.0
    # Keep the mark centered at the locked player position even at a gate.
    # Clamping the entire rectangle inside the arena doubles the edge player's
    # escape distance and can make a .9-second warning impossible to evade.
    # Cover raised tower tops too; these are access routes, not safe camping spots.
    breath_rect=Rect2(clampf(target.position.x,336,1104)-width*0.5,112,width,176)
    facing=1 if target.position.x>position.x else -1
    _sync_head()
func begin_low() -> void:
    battle=Battle.DESCEND
    var x:=clampf(target.position.x+(115 if target.position.x<720 else -115),490,950)
    low_goal=Vector2(x,250)
    facing=1 if target.position.x>x else -1
    _sync_head()
func begin_bite() -> void:
    battle=Battle.BITE_WARNING
    timer=0.75
    bite_rect=Rect2(position.x+(25 if facing>0 else -155),218,130,70)
func begin_tail() -> void:
    battle=Battle.TAIL_WARNING
    timer=0.8
    # Fixed rear zone with enough time to jump or step out; turning itself is safe.
    tail_rect=Rect2(position.x+(-165 if facing>0 else -35),240,200,48)
func begin_dive(follow_up: bool=false) -> void:
    if not follow_up: dive_chain=0
    battle=Battle.DIVE_WARNING
    timer=1.0
    var direction:=1 if target.position.x<720 else -1
    var y:=clampf(target.position.y-22,214,264)
    dive_from=Vector2(462 if direction>0 else 978,y)
    dive_to=Vector2(978 if direction>0 else 462,y)
    facing=direction
    _sync_head()
func late_step() -> void:
    if not active or health.current<=0 or target.dead: return
    if health.current<=health.max_health/2 and not second_phase:
        second_phase=true
        battle=Battle.PHASE_CHANGE
        timer=1.2
        phase_changed.emit(2)
        return
    if not all_broken_reward and crystals.all(func(c: EndCrystal) -> bool: return c.health.current<=0):
        all_broken_reward=true
        extra_low=true
        if battle==Battle.LOW: timer+=3.5; extra_low=false
    heal_tick()
    if battle==Battle.BREATH: damage_rect(breath_rect,attack_event)
    if battle==Battle.BITE: damage_rect(bite_rect,attack_event)
    if battle==Battle.TAIL: damage_rect(tail_rect,attack_event)
    if battle==Battle.DIVE: damage_rect(Rect2(position-Vector2(46,17),Vector2(92,34)),attack_event)
func heal_tick() -> void:
    beam_index=-1
    for i in crystals.size():
        if crystals[i].health.current>0:
            beam_index=i
            break
    if heal_clock<0.5: return
    heal_clock=fmod(heal_clock,0.5)
    if beam_index>=0 and health.current<health.max_health:
        # Each intact crystal contributes 1 HP every half second, in both phases.
        for crystal in crystals:
            if crystal.health.current>0:
                var restored:=health.heal(1)
                crystal.healing_used+=restored
                healed+=restored
func damage_rect(rect: Rect2,event: DamageEvent) -> void:
    if event==null: return
    var shape:=RectangleShape2D.new()
    shape.size=rect.size
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,rect.get_center())
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var victim:=hit.collider as CombatHurtbox
        if victim!=null: victim.receive(event)
func stop_attacks() -> void:
    active=false
    attack_event=null
    beam_index=-1
    for crystal in crystals: crystal.set_active(false)
func _on_death() -> void:
    stop_attacks()
    battle=Battle.DEAD
    head.set_deferred("collision_layer",0)
    super._on_death()
func reset_target() -> void:
    super.reset_target()
    stop_attacks()
    for box in [receiver,head]: box.set_deferred("collision_layer",0)
    for crystal in crystals: crystal.reset_crystal()
    battle=Battle.DORMANT
    second_phase=false
    timer=0
    heal_clock=0
    healed=0
    all_broken_reward=false
    extra_low=false
    low_windows=0
    dives=0
    breaths=0
    tail_sweeps=0
    dive_chain=0
func phase_label() -> String:
    match battle:
        Battle.DORMANT: return "进入龙巢 · 水晶可以用近战或远程摧毁"
        Battle.BREATH_WARNING: return "龙息预警 · 离开紫红地带"
        Battle.BREATH: return "龙息持续中 · 留在地带之外"
        Battle.DIVE_WARNING: return "俯冲预警 · 看红线，起跳或绕到龙身后"
        Battle.DIVE: return "俯冲！避开龙身所在高度"
        Battle.LOW,Battle.RECOVER: return "低空反击 · 头部伤害 +25%"
        Battle.BITE_WARNING,Battle.BITE: return "噬咬预警 · 退开红弧或绕后"
        Battle.TAIL_WARNING,Battle.TAIL: return "回身扫尾 · 跳起或退出后方红区"
        Battle.PHASE_CHANGE: return "半血狂暴 · 连续俯冲；水晶仍在治疗"
    return "留意下次落地 · 拆完四晶，额外反击3.5秒"
