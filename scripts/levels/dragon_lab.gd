extends "res://scripts/levels/campaign_level.gd"
var dragon: EnderDragon
var arena_active:=false
var intro_left:=0.0
@export var campaign_mode := false
var return_portal: Node2D
func _ready() -> void:
    if not campaign_mode:
        saves.enabled=false
        saves.pending_resume.clear()
    super._ready()
    if not campaign_mode:
        FinaleJourney.apply(self)
        snapshot=_make_snapshot(0)
    player.z_index=2
    for i in course.CRYSTAL_X.size():
        var crystal:=EndCrystal.new()
        crystal.position=course.crystal_position(i)
        crystal.dragon=dragon
        $World.add_child(crystal)
        dragon.crystals.append(crystal)
    practice_target.position.x=224
    if finale!=null:
        exit_x=100000
        return_portal=load("res://scripts/world/return_portal.gd").new()
        return_portal.level=self
        return_portal.position=Vector2(1280,288)
        $World.add_child(return_portal)
        finale.finish_setup()
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4W"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-W Ender Dragon Trial"
    hud_title="末地终战 · 末影龙试炼"
    short_stage="M4-W.2"
    course_width=1440
    exit_x=1344
    finished_title="末影龙试炼，完成！"
    toast="踏台登塔拆四晶 · 每晶回血 2/秒 · 塔顶仍需躲龙息"
    toast_left=10
    if campaign_mode:
        stage_id="M4X"
        short_stage="M4-X.1"
        window_label="M4-X Final Dragon Battle"
        hud_title="07 / 末地 · 巨龙之巢"
func _enter_campaign_level() -> void:
    if campaign_mode:
        super._enter_campaign_level()
        return
    wallet.reset_to_entry(40)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["netherite_sword","bow"])
    equipment.slot=0
func persist_checkpoint() -> void:
    if finale!=null: finale.save()
func enemy_specs() -> Array[Dictionary]: return [{"id":enemy_id(0),"no_loot":true,"data":preload("res://resources/enemies/ender_dragon.tres"),"x":720,"y":156}]
func create_enemy(_spec: Dictionary) -> RemixEnemy:
    dragon=EnderDragon.new()
    return dragon
func enemy_id(_index: int) -> StringName: return &"trial_ender_dragon"
func checkpoint_specs() -> Array[Dictionary]: return [{"id":&"dragon_start","label":"末地武库","x":96.0,"heals":not FinaleJourney.active and not campaign_mode}]
func checkpoint_requirements(_index: int) -> Array: return []
func block_specs() -> Array[Dictionary]:
    return [{"id":&"dragon_bread_left","x":372,"y":208,"data":BREAD_DATA},{"id":&"dragon_bread_right","x":1068,"y":208,"data":BREAD_DATA},
        {"id":&"dragon_apple_left","x":528,"y":208,"data":apple_data},{"id":&"dragon_apple_right","x":912,"y":208,"data":apple_data}]
func fragile_specs() -> Array[Dictionary]: return []
func _place_fixed_pickups() -> void: pass
func emerald_budget() -> int: return 0
func armory_positions() -> Array[float]: return [160.0]
func segments() -> Array[Dictionary]: return [{"x":0,"name":"末地武库"},{"x":384,"name":"四晶龙巢"},{"x":1120,"name":"返回主世界" if campaign_mode else "试炼出口"}]
func level_title() -> String: return "07 / 末地 · 巨龙之巢" if campaign_mode else "末影龙试炼"
func boss_name() -> String: return "末影龙"
func boss_intro_title() -> String: return "末地终战 · 四晶龙巢"
func boss_actor() -> RemixEnemy: return dragon
func result_hint() -> String: return "正式终章 · 击败巨龙后，从右侧传送门返回主世界" if campaign_mode else "独立练习 · 40练习宝石 · 不影响正式远征"
func panel_detail() -> String: return "E 五武器换装 · R 重来 · 暂停可返回主菜单"
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if intro_left>0:
        intro_left=maxf(0,intro_left-delta)
        if intro_left<=0: dragon.activate()
    if not arena_active and dragon.health.current>0 and player.position.x>=384:
        arena_active=true
        intro_left=1.0
        clear_projectiles()
        course.entrance.set_closed(true)
        camera.arena_view=true
        camera.set_region_smooth(320,1120,0.8)
    super._physics_process(delta)
func _enemy_loot(_enemy: RemixEnemy) -> void:
    health.pending.clear()
    arena_active=false
    intro_left=0
    course.entrance.set_closed(false)
    course.exit_gate.set_closed(false)
    clear_projectiles()
    camera.arena_view=false
    camera.set_region_smooth(0,1440,0.8)
    toast="末影龙消散 · 四晶沉寂 · 向右走出试炼"
    toast_left=6
    if finale!=null:
        open_return_portal()
        snapshot=_make_snapshot(0)
        persist_checkpoint()
func _on_death() -> void:
    dragon.stop_attacks()
    super._on_death()
func _reset_arena() -> void:
    arena_active=false
    intro_left=0
    player.controls_locked=false
    course.entrance.set_closed(false)
    course.exit_gate.set_closed(true)
    camera.arena_view=false
    camera.zoom=Vector2.ONE
    camera.set_region(0,1440)
    dragon.reset_target()
func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    if campaign_mode and snapshot.enemy_health.get(enemy_id(0),360)==0:
        open_return_portal()
    else: _reset_arena()
func restart_course() -> void:
    if finale!=null:
        finale.restart_segment()
        return
    super.restart_course()
    FinaleJourney.apply(self)
    snapshot=_make_snapshot(0)
    _reset_arena()

func open_return_portal() -> void:
    arena_active=false
    intro_left=0
    dragon.stop_attacks()
    dragon.battle=EnderDragon.Battle.DEAD
    for crystal in dragon.crystals:
        crystal.reset_crystal()
        crystal.health.current=0
        crystal.receiver.set_deferred("collision_layer",0)
    course.entrance.set_closed(false)
    course.exit_gate.set_closed(false)
    camera.arena_view=false
    camera.set_region(0,1440)
    if is_instance_valid(return_portal): return_portal.show()
    toast="末影龙已陨落 · 战果已记录 · 前往右侧返回传送门，按交互键回家"
    toast_left=10

func _unhandled_input(event: InputEvent) -> void:
    if finale!=null and not course_paused and not defeated and not completed and not input_panel.visible and not loadout_panel.visible and dragon.health.current<=0 and player.is_on_floor() and absf(player.position.x-1280)<64:
        var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
        var pad: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
        if keyboard or pad:
            finale.return_home()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)
