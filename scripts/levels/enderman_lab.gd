extends "res://scripts/levels/campaign_level.gd"
## Four short terrain exercises, deliberately outside campaign progression.
var arena_active:=false
var intro_left:=0.0
var encounters_enabled:=true
var active_guard: int=-1
func _ready() -> void:
    saves.enabled=false
    saves.pending_resume.clear()
    super._ready()
    player.z_index=2
    practice_target.position.x=232
    practice_target.label="试武木靶"
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4L1A"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-L.2 Enderman Encounters"
    hud_title="诡异边界 · 末影人试炼"
    short_stage="M4-L.2"
    course_width=2304
    exit_x=2208
    finished_title="末影人试炼完成"
    toast="击败当前守卫开门 · 一段一只 · 紫框预告瞬移落点"
    toast_left=10
func _enter_campaign_level() -> void:
    wallet.reset_to_entry(40)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["netherite_sword","bow"])
    equipment.slot=0
func persist_checkpoint() -> void: pass
func create_enemy(spec: Dictionary) -> RemixEnemy:
    var enemy:=EndermanEnemy.new()
    enemy.guard_mode=true
    enemy.encounter_bounds=Vector2(spec.left+18,spec.right-18)
    return enemy
func enemy_specs() -> Array[Dictionary]:
    var data:=preload("res://resources/enemies/enderman.tres")
    return [{"data":data,"x":480,"left":288,"right":704},
        {"data":data,"x":960,"left":752,"right":1200},
        {"data":data,"x":1512,"left":1232,"right":1680},
        {"data":data,"x":1976,"left":1728,"right":2240}]
func enemy_id(index: int) -> StringName: return StringName("trial_enderman_%d"%index)
func checkpoint_specs() -> Array[Dictionary]: return [{"id":&"enderman_trial_start","label":"诡异武库","x":96.0,"heals":true}]
func checkpoint_requirements(_index: int) -> Array: return []
func block_specs() -> Array[Dictionary]: return []
func fragile_specs() -> Array[Dictionary]: return []
func _place_fixed_pickups() -> void: pass
func _enemy_loot(enemy: RemixEnemy) -> void:
    if not encounters_enabled: return
    var index:=targets.find(enemy)
    if index<0: return
    course.release_room(index)
    active_guard=-1
    toast="封印解除 · 前往下一段" if index<3 else "四段试炼完成 · 向右离开"
    toast_left=3
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if encounters_enabled and active_guard<0:
        for i in targets.size():
            var enemy: EndermanEnemy=targets[i]
            if enemy.health.current<=0: continue
            if player.position.x>=enemy_specs()[i].left+32 and player.is_on_floor():
                active_guard=i
                course.start_room(i)
                enemy.activate_guard()
                toast="第%d段守卫苏醒 · 击败后开门 · 留意紫色落点"%(i+1)
                toast_left=3
            break
    super._physics_process(delta)
func _reset_encounters() -> void:
    active_guard=-1
    if encounters_enabled: course.reset_rooms()
func restart_course() -> void:
    super.restart_course()
    _reset_encounters()
func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    _reset_encounters()
func emerald_budget() -> int: return 0
func armory_positions() -> Array[float]: return [160.0]
func segments() -> Array[Dictionary]:
    return [{"x":0,"name":"平地初见"},{"x":736,"name":"双层菌台"},{"x":1216,"name":"断隙落点"},{"x":1680,"name":"窄墙回避"}]
func level_title() -> String: return "末影人试炼"
func result_hint() -> String: return "独立练习 · 初始40宝石 · 不影响远征"
func panel_detail() -> String: return "E 五武器换装 · R 重来 · 第五关正式路线制作中"
func panel_title() -> String: return "试炼失败" if defeated else (finished_title if completed else "试炼暂停")
func check_environment() -> void:
    if defeated or completed or player.position.y<=460: return
    var fall:=DamageEvent.create(course,0,4)
    fall.bypass_invulnerability=true
    fall.protection_override=1.0
    health.queue_damage(fall)
    equipment.suspend_input()
    player.reset_at(Vector2(1320 if player.position.x<1420 else 1512,288))
    camera.reset_to_target()
