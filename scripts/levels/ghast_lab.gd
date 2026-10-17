extends "res://scripts/levels/campaign_level.gd"
var ghast: GhastEnemy
var arena_active:=false # Shared HUD reserves this flag for boss bars.
var encounter_started:=false
var intro_left:=0.0
func _ready() -> void:
    saves.enabled=false
    saves.pending_resume.clear()
    super._ready()
    player.z_index=2
    practice_target.position.x=232
    practice_target.label="试武木靶"
    ghast.cue.connect(_ghast_cue)
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4M1"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-M.1.1 Ghast Altitude"
    hud_title="灰烬断桥 · 恶魂试炼"
    short_stage="M4-M.1.1"
    course_width=1280
    exit_x=1136
    finished_title="恶魂试炼完成"
    toast="走入前方斗场 · 火球可用剑 / 斧 / 戟打回"
    toast_left=8
func _enter_campaign_level() -> void:
    wallet.reset_to_entry(40)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["netherite_sword","bow"])
    equipment.slot=0
func persist_checkpoint() -> void: pass
func create_enemy(_spec: Dictionary) -> RemixEnemy:
    ghast=GhastEnemy.new()
    return ghast
func enemy_specs() -> Array[Dictionary]:
    return [{"data":preload("res://resources/enemies/ghast.tres"),"x":760,"y":GhastEnemy.HIGH_Y}]
func enemy_id(_index: int) -> StringName: return &"trial_ghast"
func checkpoint_specs() -> Array[Dictionary]: return [{"id":&"ghast_trial_start","label":"灰烬武库","x":96.0,"heals":true}]
func checkpoint_requirements(_index: int) -> Array: return []
func block_specs() -> Array[Dictionary]: return []
func fragile_specs() -> Array[Dictionary]: return []
func _place_fixed_pickups() -> void: pass
func _enemy_loot(_enemy: RemixEnemy) -> void:
    course.release_arena()
    toast="恶魂已击败 · 前方出口开启"
    toast_left=4
func _ghast_cue(id: StringName) -> void:
    sound.play_effect(id)
    if id==&"ghast_reflect":
        toast="反弹成功！火球返击 12 伤害"
        toast_left=0 # Flight cues stay beside the actor, clear of its higher silhouette.
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if not encounter_started and player.position.x>=352 and player.is_on_floor():
        encounter_started=true
        course.entry.set_closed(true)
        camera.set_region_smooth(320,960,0.9)
        ghast.activate()
        toast="高空：上瞄射击 / 反弹 · 低空：跳跃攻击"
        toast_left=0
    if encounter_started and ghast.health.current<=0 and player.position.x>1000 and camera.region_right>0:
        camera.set_region_smooth(0,-1,0.7)
    super._physics_process(delta)
func _reset_encounter() -> void:
    encounter_started=false
    course.reset_arena()
    camera.set_region(0)
func restart_course() -> void:
    super.restart_course()
    _reset_encounter()
func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    _reset_encounter()
func emerald_budget() -> int: return 0
func armory_positions() -> Array[float]: return [160.0]
func segments() -> Array[Dictionary]:
    return [{"x":0,"name":"灰烬武库"},{"x":320,"name":"火球返击"},{"x":960,"name":"试炼出口"}]
func level_title() -> String: return "恶魂试炼"
func result_hint() -> String: return "反弹 %d 次 · 初始40练习宝石 · 不影响远征"%ghast.reflections
func panel_detail() -> String: return "E 五武器换装 · R 重来 · 第五关正式路线制作中"
func panel_title() -> String: return "试炼失败" if defeated else (finished_title if completed else "试炼暂停")
func check_environment() -> void: pass # Continuous floor; no lethal practice pit.
