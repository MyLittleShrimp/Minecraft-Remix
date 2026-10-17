class_name TideBossEncounter
extends Node2D
## The temple checkpoint is the rollback boundary for supplies and the whole fight.
var level: Node
var guards: Array[RemixEnemy]=[]
var summons: Array[Dictionary]=[]
var generation:=0
var intro_seen:=false
var guards_requested:=false

func reset_encounter(new_run: bool) -> void:
    clear()
    if new_run: intro_seen=false
    guards_requested=false
    level.arena_active=false
    level.intro_left=0
    level.last_hurt_left=0
    level.last_hurt_label=""
    level.player.controls_locked=false
    level.guardian.active=false
    level.guardian.receiver.set_deferred("collision_layer",0)
    level.course.entrance.set_closed(level.checkpoint_index<4 and level.guardian.health.current>0)
    level.course.exit_gate.set_closed(level.guardian.health.current>0)
    level.camera.set_region(0,TideCourse.WIDTH)

func clear() -> void:
    generation+=1
    summons.clear()
    for guard in guards:
        if is_instance_valid(guard):
            guard.process_mode=Node.PROCESS_MODE_DISABLED
            guard.health.pending.clear()
            guard.receiver.set_deferred("collision_layer",0)
            guard.queue_free()
    guards.clear()
    level.guardian.stop_attacks()
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
    level.camera.set_region_smooth(0,TideCourse.WIDTH,0.8)
    level.toast="神殿核心平息 · 护卫退去 · 向右走出遗迹，完成远征！"
    level.toast_left=6

func begin() -> void:
    level.arena_active=true
    level.intro_left=0.6 if intro_seen else 1.5
    intro_seen=true
    level.player.controls_locked=true
    level.player.velocity=Vector2.ZERO
    level.player.clear_jump_memory()
    level.equipment.suspend_input()
    level.clear_projectiles()
    level.course.entrance.set_closed(true)
    level.course.exit_gate.set_closed(true)
    level.camera.set_region_smooth(TideCourse.ARENA_LEFT,TideCourse.ARENA_RIGHT,level.intro_left*0.66)
    level.sound.play_effect(&"fuse")

func tick(delta: float) -> bool:
    level.last_hurt_left=maxf(0,level.last_hurt_left-delta)
    if level.intro_left>0:
        level.intro_left=maxf(0,level.intro_left-delta)
        level.play_seconds+=delta
        if level.intro_left<=0:
            level.player.controls_locked=false
            level.player.clear_jump_memory()
            level.equipment.suspend_input()
            level.get_node("/root/ControlSettings").arm_release_gate()
            level.guardian.activate()
        return true
    if not level.arena_active:
        if level.guardian.health.current>0:
            level.course.entrance.set_closed(level.checkpoint_index<4)
            if level.checkpoint_index==4 and level.player.position.x>=TideCourse.ARENA_LEFT+96 and level.player.is_on_floor():
                begin()
                return true
        return false
    if level.guardian.battle!=ElderGuardian.Battle.PHASE_CHANGE:
        for request in summons.duplicate():
            request.left-=delta
            if request.left<=0:
                summons.erase(request)
                spawn_guard.call_deferred(request)
    queue_redraw()
    return false

func request_guards(_phase: int) -> void:
    if guards_requested or not level.arena_active: return
    guards_requested=true
    var candidates: Array[float]=[7640.0,7784.0,7928.0,8072.0,8216.0,8360.0]
    candidates.sort_custom(func(a: float,b: float) -> bool: return absf(a-level.player.position.x)>absf(b-level.player.position.x))
    for x in candidates:
        if absf(x-level.player.position.x)<140: continue
        summons.append({"x":x,"left":1.0+summons.size()*0.35,"generation":generation})
        if summons.size()==3: break

func spawn_guard(request: Dictionary) -> void:
    if request.generation!=generation or not level.arena_active or level.defeated or level.completed or level.guardian.health.current<=0: return
    var guard:=DrownedEnemy.new()
    guard.data=level.DROWNED.duplicate()
    guard.data.label="潮汐护卫"
    guard.data.awareness=420
    guard.target=level.player
    guard.view_camera=level.camera
    guard.ui_font=level.ui_font
    guard.position=Vector2(request.x,288)
    level.get_node("World").add_child(guard)
    guard.hitstun=0.6
    guard.fired.connect(level._enemy_fired)
    guard.health.damaged.connect(func(_event: DamageEvent) -> void: level.sound.play_effect(&"hit"))
    guards.append(guard)

func _draw() -> void:
    for request in summons:
        draw_rect(Rect2(request.x-19,283,38,5),Color("f1cf85"))
        draw_string(level.ui_font,Vector2(request.x-24,224),"溺尸将至",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f1cf85"))
