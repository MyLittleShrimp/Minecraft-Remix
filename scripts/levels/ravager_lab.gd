extends "res://scripts/levels/campaign_level.gd"
## Isolated encounter prototype: no campaign progress or disk save mutation.
var ravager: RavagerEnemy
var arena_active:=false
var intro_left:=0.0

func _ready() -> void:
    get_node("/root/SaveManager").enabled=false
    get_node("/root/SaveManager").pending_resume.clear()
    super._ready()
    if is_instance_valid(practice_target): practice_target.position.x=224

func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4G1"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-G.3 Ravager Practice"
    hud_title="裂岩试炼 · Boss 战斗原型"
    short_stage="M4-G.2"
    course_width=1600
    exit_x=1472
    finished_title="裂岩试炼，完成！"
    toast="E 在入口换装 · 零宝石试炼 · 跳冲撞、躲顶角、跃地波"
    toast_left=8

func _enter_campaign_level() -> void:
    wallet.reset_to_entry(0)
    hunger.restore(20,true)
    campaign_settled=true

func persist_checkpoint() -> void: pass
func enemy_specs() -> Array[Dictionary]: return [{"data":preload("res://resources/enemies/ravager.tres"),"x":896}]
func create_enemy(_spec: Dictionary) -> RemixEnemy:
    ravager=RavagerEnemy.new()
    return ravager
func enemy_id(_index: int) -> StringName: return &"trial_ravager"
func checkpoint_specs() -> Array[Dictionary]: return [{"id":&"trial_start","label":"试炼入口","x":96.0,"heals":true}]
func checkpoint_requirements(_index: int) -> Array: return []
func block_specs() -> Array[Dictionary]: return []
func fragile_specs() -> Array[Dictionary]: return []
func _place_fixed_pickups() -> void: pass
func emerald_budget() -> int: return 0
func armory_positions() -> Array[float]: return [160.0]
func segments() -> Array[Dictionary]: return [{"x":0,"name":"试炼换装"},{"x":416,"name":"裂岩斗场"},{"x":1300,"name":"试炼出口"}]
func level_title() -> String: return "裂岩试炼"
func boss_name() -> String: return "裂岩劫掠兽"
func boss_intro_title() -> String: return "矿坑斗场 · 铁闸落下"
func boss_actor() -> RemixEnemy: return ravager
func result_hint() -> String: return "独立试炼 · 不写入远征存档 · 零宝石 / 零 TNT"
func panel_detail() -> String: return "入口 E 换装 · R 重来 · 击败后向右离开斗场"

func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if intro_left>0:
        intro_left=maxf(0,intro_left-delta)
        if intro_left<=0:
            player.controls_locked=false
            player.clear_jump_memory()
            ravager.activate()
        return
    if not arena_active and ravager.health.current>0 and player.position.x>=416:
        arena_active=true
        intro_left=1.8
        player.controls_locked=true
        player.velocity=Vector2.ZERO
        equipment.suspend_input()
        clear_projectiles()
        course.entrance.set_closed(true)
        camera.set_region_smooth(320,1280,1.2)
        return
    super._physics_process(delta)

func _enemy_loot(_enemy: RemixEnemy) -> void:
    arena_active=false
    course.exit_gate.set_closed(false)
    course.entrance.set_closed(false)
    clear_projectiles()
    camera.set_region_smooth(0,1600,0.8)
    toast="裂岩劫掠兽已倒下 · 向右走出斗场完成试炼"
    toast_left=8

func _reset_arena() -> void:
    arena_active=false
    intro_left=0
    player.controls_locked=false
    course.entrance.set_closed(false)
    course.exit_gate.set_closed(true)
    camera.set_region(0,1600)
    camera.reset_to_target()
    ravager.reset_target()

func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    _reset_arena()

func restart_course() -> void:
    super.restart_course()
    _reset_arena()
