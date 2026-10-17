extends "res://scripts/levels/campaign_level.gd"
## Boss prototype isolated from the four-level campaign and its wallet/save.
var guardian: ElderGuardian
var arena_active:=false
var intro_left:=0.0
var trial_guards: Array[RemixEnemy]=[]
var pending_guards: Array[Dictionary]=[]
var guards_requested:=false
var encounter_epoch:=0
var last_hurt_label:=""
var last_hurt_left:=0.0

func _ready() -> void:
    saves.enabled=false
    saves.pending_resume.clear()
    GuardianArt.prepare()
    super._ready()
    # Bodies can overlap without contact damage; keep Steve and his weapon
    # visible in front of the guardian's much larger silhouette.
    player.z_index=1
    guardian.phase_changed.connect(_request_guards)
    health.damaged.connect(_show_hurt_source)
    if is_instance_valid(practice_target): practice_target.position.x=232

func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4J1"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-J.1 Elder Guardian Trial"
    hud_title="潮汐神殿 · 远古守卫者试炼"
    short_stage="M4-J.1"
    course_width=1600
    exit_x=1472
    finished_title="潮汐神殿试炼，完成！"
    toast="E 换装 · 光束跳开，潮汐进绿框等退潮，棘刺退到红圈外。"
    toast_left=10

func _enter_campaign_level() -> void:
    wallet.reset_to_entry(40)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["trident","bow"])
    equipment.slot=0
func persist_checkpoint() -> void: pass
func enemy_specs() -> Array[Dictionary]: return [{"data":preload("res://resources/enemies/elder_guardian.tres"),"x":896}]
func create_enemy(_spec: Dictionary) -> RemixEnemy:
    guardian=ElderGuardian.new()
    return guardian
func enemy_id(_index: int) -> StringName: return &"trial_elder_guardian"
func checkpoint_specs() -> Array[Dictionary]: return [{"id":&"guardian_trial_start","label":"神殿入口","x":96.0,"heals":true}]
func checkpoint_requirements(_index: int) -> Array: return []
func block_specs() -> Array[Dictionary]: return []
func fragile_specs() -> Array[Dictionary]: return []
func _place_fixed_pickups() -> void: pass
func emerald_budget() -> int: return 0
func armory_positions() -> Array[float]: return [160.0]
func segments() -> Array[Dictionary]: return [{"x":0,"name":"神殿换装"},{"x":416,"name":"潮汐斗场"},{"x":1300,"name":"试炼出口"}]
func level_title() -> String: return "远古守卫者试炼"
func boss_name() -> String: return "潮汐远古守卫者"
func boss_intro_title() -> String: return "潮汐神殿 · 独眼苏醒"
func boss_actor() -> RemixEnemy: return guardian
func result_hint() -> String: return "独立练习 · 初始40宝石 · 不影响远征"
func panel_detail() -> String: return "E 五武器换装 · R 重来 · 暂停可返回主菜单"

func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    last_hurt_left=maxf(0,last_hurt_left-delta)
    if intro_left>0:
        intro_left=maxf(0,intro_left-delta)
        if intro_left<=0:
            player.controls_locked=false
            player.clear_jump_memory()
            equipment.suspend_input()
            guardian.activate()
        return
    if not arena_active and guardian.health.current>0 and player.position.x>=416:
        arena_active=true
        intro_left=1.5
        player.controls_locked=true
        player.velocity=Vector2.ZERO
        player.clear_jump_memory()
        equipment.suspend_input()
        clear_projectiles()
        course.entrance.set_closed(true)
        camera.set_region_smooth(320,1280,1.0)
        return
    if arena_active and guardian.battle!=ElderGuardian.Battle.PHASE_CHANGE:
        for request in pending_guards.duplicate():
            request.left-=delta
            if request.left<=0:
                pending_guards.erase(request)
                _spawn_guard.call_deferred(request)
    course.queue_redraw()
    super._physics_process(delta)

func _show_hurt_source(event: DamageEvent) -> void:
    var label: String=event.get_meta("guardian_attack","")
    var source:=instance_from_id(event.source_id)
    if source is DrownedEnemy: label="护卫投戟"
    elif event.get_meta("starvation",false): label="饥饿"
    if label.is_empty(): return
    last_hurt_label="受到%s -%d生命" % [label,event.amount]
    last_hurt_left=2.0

func _request_guards(_phase: int) -> void:
    if guards_requested or not arena_active: return
    guards_requested=true
    # Six spaced slots guarantee three distinct, distant summons even when
    # Steve stands in the middle; no guard appears directly on top of him.
    var candidates: Array[float]=[440.0,584.0,728.0,872.0,1016.0,1160.0]
    candidates.sort_custom(func(a: float,b: float) -> bool: return absf(a-player.position.x)>absf(b-player.position.x))
    for x in candidates:
        if absf(x-player.position.x)<140: continue
        pending_guards.append({"x":x,"left":1.0+pending_guards.size()*0.35,"epoch":encounter_epoch})
        if pending_guards.size()==3: break

func _spawn_guard(request: Dictionary) -> void:
    if request.epoch!=encounter_epoch or not arena_active or defeated or completed or guardian.health.current<=0: return
    var guard:=DrownedEnemy.new()
    guard.data=preload("res://resources/enemies/drowned.tres").duplicate()
    guard.data.label="潮汐护卫"
    guard.data.awareness=420
    guard.target=player
    guard.view_camera=camera
    guard.ui_font=ui_font
    guard.position=Vector2(request.x,288)
    $World.add_child(guard)
    guard.hitstun=0.6
    guard.fired.connect(_enemy_fired)
    guard.health.damaged.connect(func(_event: DamageEvent) -> void: sound.play_effect(&"hit"))
    trial_guards.append(guard)

func _clear_guards() -> void:
    encounter_epoch+=1
    pending_guards.clear()
    for guard in trial_guards:
        if is_instance_valid(guard):
            guard.process_mode=Node.PROCESS_MODE_DISABLED
            guard.health.pending.clear()
            guard.receiver.set_deferred("collision_layer",0)
            guard.queue_free()
    trial_guards.clear()

func _enemy_loot(_enemy: RemixEnemy) -> void:
    _clear_guards()
    health.pending.clear()
    arena_active=false
    player.controls_locked=false
    course.exit_gate.set_closed(false)
    course.entrance.set_closed(false)
    clear_projectiles()
    camera.set_region_smooth(0,1600,0.8)
    toast="神殿核心平息 · 护卫退去 · 向右走出试炼"
    toast_left=6

func _on_death() -> void:
    _clear_guards()
    guardian.stop_attacks()
    super._on_death()

func _reset_arena() -> void:
    last_hurt_left=0
    last_hurt_label=""
    _clear_guards()
    guards_requested=false
    arena_active=false
    intro_left=0
    player.controls_locked=false
    course.entrance.set_closed(false)
    course.exit_gate.set_closed(true)
    camera.set_region(0,1600)
    camera.reset_to_target()
    guardian.reset_target()

func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    _reset_arena()
func restart_course() -> void:
    super.restart_course()
    _reset_arena()
