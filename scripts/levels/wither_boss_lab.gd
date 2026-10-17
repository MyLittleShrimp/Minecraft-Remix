extends "res://scripts/levels/campaign_level.gd"
## Independent chapter-six Boss trial; never settles campaign progress or gems.
var wither_boss: WitherBoss
var wither: WitherComponent
var arena_active:=false
var intro_left:=0.0
var reinforcements: WitherBossGuards
func _ready() -> void:
    saves.enabled=false
    saves.pending_resume.clear()
    WitherBossArt.prepare()
    super._ready()
    wither=WitherComponent.new()
    wither.name="Wither"
    player.add_child(wither)
    player.z_index=2
    wither_boss.pillars=course.pillars
    reinforcements=WitherBossGuards.new()
    reinforcements.level=self
    $World.add_child(reinforcements)
    wither_boss.phase_changed.connect(reinforcements.request)
    practice_target.position.x=232
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4T3"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-T.3 Wither Boss Trial"
    hud_title="堡垒灾厄 · 凋灵试炼"
    short_stage="M4-T.3"
    course_width=1280
    exit_x=1152
    finished_title="凋灵试炼，完成！"
    toast="E 换装 · 低空留意横扫；狂暴首撞破柱，再撞才眩晕。"
    toast_left=10
func _enter_campaign_level() -> void:
    wallet.reset_to_entry(40)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["netherite_sword","bow"])
    equipment.slot=0
func persist_checkpoint() -> void: pass
func enemy_specs() -> Array[Dictionary]: return [{"data":preload("res://resources/enemies/wither_boss.tres"),"x":820,"y":158}]
func create_enemy(_spec: Dictionary) -> RemixEnemy:
    wither_boss=WitherBoss.new()
    return wither_boss
func enemy_id(_index: int) -> StringName: return &"trial_wither_boss"
func checkpoint_specs() -> Array[Dictionary]: return [{"id":&"wither_boss_start","label":"凋灵武库","x":96.0,"heals":true}]
func checkpoint_requirements(_index: int) -> Array: return []
func block_specs() -> Array[Dictionary]:
    return [{"id":&"wither_boss_bread_1","x":256,"y":208,"data":BREAD_DATA},
        {"id":&"wither_boss_bread_2","x":432,"y":208,"data":BREAD_DATA},
        {"id":&"wither_boss_apple","x":848,"y":208,"data":apple_data}]
func fragile_specs() -> Array[Dictionary]: return []
func _place_fixed_pickups() -> void: pass
func emerald_budget() -> int: return 0
func armory_positions() -> Array[float]: return [160.0]
func segments() -> Array[Dictionary]: return [{"x":0,"name":"堡垒武库"},{"x":384,"name":"凋灵核心"},{"x":960,"name":"试炼出口"}]
func level_title() -> String: return "凋灵试炼"
func boss_name() -> String: return "凋灵"
func boss_intro_title() -> String: return "堡垒核心 · 三首苏醒"
func boss_actor() -> RemixEnemy: return wither_boss
func result_hint() -> String: return "独立练习 · 初始40宝石 · 不影响正式远征"
func panel_detail() -> String: return "E 五武器换装 / 引爆杆 · R 重来 · 暂停可返回主菜单"
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if intro_left>0:
        intro_left=maxf(0,intro_left-delta)
        if intro_left<=0: wither_boss.activate()
    if not arena_active and wither_boss.health.current>0 and player.position.x>=384:
        arena_active=true
        intro_left=1.0
        equipment.suspend_input()
        clear_projectiles()
        course.entrance.set_closed(true)
        camera.set_region_smooth(320,960,0.8)
    super._physics_process(delta)
func _enemy_loot(_enemy: RemixEnemy) -> void:
    reinforcements.clear()
    health.pending.clear()
    wither.clear()
    arena_active=false
    intro_left=0
    _stop_charges()
    course.exit_gate.set_closed(false)
    course.entrance.set_closed(false)
    clear_projectiles()
    camera.set_region_smooth(0,1280,0.8)
    toast="凋灵消散 · 护卫退去 · 向右走出试炼"
    toast_left=6
func _stop_charges() -> void:
    for charge in course.charges: charge.stop()
func _on_death() -> void:
    reinforcements.clear()
    wither_boss.stop_attacks()
    wither.clear()
    _stop_charges()
    super._on_death()
func _reset_arena() -> void:
    reinforcements.clear()
    arena_active=false
    intro_left=0
    player.controls_locked=false
    course.entrance.set_closed(false)
    course.exit_gate.set_closed(true)
    for pillar in course.pillars: pillar.reset_pillar()
    for charge in course.charges: charge.reset_charge()
    wither.clear()
    camera.set_region(0,1280)
    camera.reset_to_target()
    wither_boss.reset_target()
func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    _reset_arena()
func restart_course() -> void:
    super.restart_course()
    _reset_arena()
func _unhandled_input(event: InputEvent) -> void:
    if not course_paused and not defeated and not completed and not input_panel.visible and not loadout_panel.visible:
        var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
        var pad: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
        if keyboard or pad:
            for charge in course.charges:
                if charge.interact():
                    get_viewport().set_input_as_handled()
                    return
    super._unhandled_input(event)
