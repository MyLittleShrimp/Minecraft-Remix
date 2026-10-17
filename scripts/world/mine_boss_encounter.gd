class_name MineBossEncounter
extends Node2D
## Owns transient encounter state; the checkpoint before the gate is the rollback boundary.
var level: Node
var charges: Array[MineBossCharge]=[]
var guards: Array[RemixEnemy]=[]
var summons: Array[Dictionary]=[]
var generation:=0
var intro_seen:=false
var phase_locked:=false
var guard_phase:=0
@onready var settings: Node=get_node("/root/ControlSettings")

func _ready() -> void:
    for pair in [Vector2(9890,10050),Vector2(10440,10280)]:
        var charge:=MineBossCharge.new()
        charge.encounter=self
        charge.socket_x=pair.x
        charge.lever_x=pair.y
        add_child(charge)
        charges.append(charge)

func hint(message: String) -> void:
    level.toast=message
    level.toast_left=5

func reset_encounter(new_run: bool) -> void:
    clear()
    if new_run: intro_seen=false
    level.arena_active=false
    level.intro_left=0
    level.player.controls_locked=false
    level.ravager.active=false
    level.ravager.receiver.set_deferred("collision_layer",0)
    level.course.entrance.set_closed(level.checkpoint_index<4 and level.ravager.health.current>0)
    level.course.exit_gate.set_closed(level.ravager.health.current>0)
    level.camera.set_region(0,MineCourse.WIDTH)
    for charge in charges: charge.reset_charge()

func clear() -> void:
    generation+=1
    phase_locked=false
    guard_phase=0
    summons.clear()
    for charge in charges:
        charge.fuse_left=0
        charge.restock_left=0
        charge.queue_redraw()
    for guard in guards:
        if is_instance_valid(guard):
            guard.process_mode=Node.PROCESS_MODE_DISABLED
            guard.health.pending.clear()
            guard.receiver.set_deferred("collision_layer",0)
            guard.queue_free()
    guards.clear()
    level.ravager.clear_waves()
    level.ravager.pending_hit=false
    level.ravager.pending_wave=false
    queue_redraw()

func victory() -> void:
    clear()
    level.health.pending.clear()
    level.arena_active=false
    level.intro_left=0
    level.player.controls_locked=false
    level.clear_projectiles()
    level.course.entrance.set_closed(false)
    level.course.exit_gate.set_closed(false)
    level.camera.set_region_smooth(0,MineCourse.WIDTH,0.8)
    hint("裂岩劫掠兽已倒下 · 护卫撤退 · 向右走出采掘厅！")

func begin() -> void:
    level.arena_active=true
    level.intro_left=0.6 if intro_seen else 1.8
    intro_seen=true
    level.player.controls_locked=true
    level.player.velocity=Vector2.ZERO
    level.player.clear_jump_memory()
    level.equipment.suspend_input()
    level.clear_projectiles()
    level.course.entrance.set_closed(true)
    level.course.exit_gate.set_closed(true)
    level.camera.set_region_smooth(MineCourse.ARENA_LEFT,MineCourse.ARENA_RIGHT,level.intro_left*0.66)
    level.sound.play_effect(&"fuse")
    print("MINE_BOSS_INTRO seconds=%.1f" % level.intro_left)

func phase_changed(_phase: int) -> void:
    if not level.arena_active or level.ravager.health.current<=0: return
    # Only arena hazards wait for the crack animation. Preserve player motion,
    # held inputs and live attacks, including a jump already in progress.
    phase_locked=true
    for guard in guards:
        if is_instance_valid(guard): guard.process_mode=Node.PROCESS_MODE_DISABLED

func release_player() -> void:
    level.player.controls_locked=false
    level.equipment.suspend_input()
    settings.arm_release_gate()

func tick(delta: float) -> bool:
    if level.intro_left>0:
        level.intro_left=maxf(0,level.intro_left-delta)
        level.play_seconds+=delta
        if level.intro_left<=0:
            release_player()
            level.ravager.activate()
            request_guards(1)
        return true
    if level.arena_active:
        for charge in charges: charge.advance(delta)
    if phase_locked:
        if level.ravager.battle!=RavagerEnemy.Battle.PHASE_CHANGE:
            phase_locked=false
            for guard in guards:
                if is_instance_valid(guard): guard.process_mode=Node.PROCESS_MODE_INHERIT
            request_guards(2)
        return false
    if not level.arena_active:
        if level.ravager.health.current>0:
            level.course.entrance.set_closed(level.checkpoint_index<4)
            if level.checkpoint_index==4 and level.player.position.x>=MineCourse.ARENA_LEFT+96 and level.player.is_on_floor():
                begin()
                return true
        return false
    if not level.arena_active or level.ravager.health.current<=0: return false
    for record in summons.duplicate():
        record.left-=delta
        if record.left<=0:
            summons.erase(record)
            spawn_guard.call_deferred(record)
    queue_redraw()
    return false

func request_guards(phase: int) -> void:
    # Opening spiders persist; phase two adds one vindicator, never refills them.
    if phase<=guard_phase: return
    guard_phase=phase
    var formation: Array=[false,false] if phase==1 else [true]
    var candidates: Array[float]=[9856.0,10016.0,10208.0,10368.0,10520.0]
    for i in formation.size():
        for x in candidates:
            if absf(x-level.player.position.x)<140: continue
            if summons.any(func(p: Dictionary) -> bool: return p.x==x): continue
            if guards.any(func(g: RemixEnemy) -> bool: return is_instance_valid(g) and g.health.current>0 and absf(g.position.x-x)<48): continue
            summons.append({"x":x,"vindicator":formation[i],"left":0.9+i*0.2,"generation":generation,"phase":phase})
            break

func spawn_guard(record: Dictionary) -> void:
    if record.generation!=generation or not level.arena_active or level.defeated or level.ravager.health.current<=0: return
    var guard: RemixEnemy=VindicatorEnemy.new() if record.vindicator else SpiderEnemy.new()
    guard.data=(level.VINDICATOR_DATA if record.vindicator else level.SPIDER_DATA).duplicate()
    guard.data.label="矿坑护卫" if record.vindicator else "蜘蛛护卫"
    guard.data.awareness=480
    guard.data.patrol_radius=120
    guard.target=level.player
    guard.view_camera=level.camera
    guard.ui_font=level.ui_font
    guard.position=Vector2(record.x,288)
    level.get_node("World").add_child(guard)
    guard.hitstun=0.35
    guards.append(guard)
    print("MINE_BOSS_GUARD phase=%d kind=%s boss_hp=%d" % [record.get("phase",guard_phase),"vindicator" if record.vindicator else "spider",level.ravager.health.current])
    if phase_locked: guard.process_mode=Node.PROCESS_MODE_DISABLED
    guard.health.damaged.connect(func(_event: DamageEvent) -> void: level.sound.play_effect(&"hit"))

func handle_input(event: InputEvent) -> bool:
    if level.course_paused or level.defeated or level.completed or level.player.controls_locked: return false
    if level.input_panel.visible or level.loadout_panel.visible: return false
    var nearby: MineBossCharge=null
    for charge in charges:
        if charge.can_interact():
            nearby=charge
            break
    # event_pressed tracks axis edges. Do not consume the edge belonging to
    # the transport room or a weapon station when no arena supply is nearby.
    if nearby==null: return false
    var pressed: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not settings.gamepad_active()
    pressed=pressed or ((event is InputEventJoypadButton or event is InputEventJoypadMotion) and settings.event_pressed(event,"aim_up"))
    if not pressed: return false
    nearby.interact()
    return true

func _draw() -> void:
    for record in summons:
        draw_rect(Rect2(record.x-16,283,32,5),Color("e5b96f"))
        draw_string(level.ui_font,Vector2(record.x-26,254),"卫道士增援" if record.vindicator else "蜘蛛将至",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("ffe1a2"))
