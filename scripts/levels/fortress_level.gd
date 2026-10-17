extends "res://scripts/levels/fortress_route.gd"
## One chapter and ledger from the outer fortress to the Wither chamber.
const ARENA_OFFSET := 13632.0
var wither_boss: WitherBoss
var reinforcements: WitherBossGuards
const TRANSPORT_GUARD := 18
var transport_warning := -1.0
var transport_awake := false
@onready var arena_course: Node2D = $World/ArenaCourse

func _ready() -> void:
    WitherBossArt.prepare()
    super._ready()
    _setup_arena()

func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4U"
    short_stage="M4-U.2"
    window_label="M4-U Fortress Campaign"
    hud_title="06 / 堡垒核心"
    course_width=ARENA_OFFSET+1280
    exit_x=ARENA_OFFSET+1152
    finished_title="堡垒核心，已平息"
    toast="突破守军与灵魂门 → 在核心门前整备 → 击败凋灵取得烈焰粉"
    toast_left=9

func enemy_specs() -> Array[Dictionary]:
    var specs:=super.enemy_specs()
    specs.append({"data":preload("res://resources/enemies/wither_boss.tres"),"x":ARENA_OFFSET+820,"y":158})
    # Append after the existing Boss so published actor IDs and indices stay stable.
    specs.append({"data":preload("res://resources/enemies/piglin_sword.tres"),"x":6904,"left":6688,"right":6952})
    for i in specs.size():
        specs[i]["id"]=enemy_id(i)
        specs[i]["no_loot"]=i==17 # Boss grants the story reward; route guards drop gems.
    return specs

func enemy_id(index: int) -> StringName:
    if index==TRANSPORT_GUARD: return &"fortress_tnt_guard"
    return &"fortress_wither" if index==17 else super.enemy_id(index)

func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.get("id")==&"fortress_wither":
        wither_boss=WitherBoss.new()
        wither_boss.arena_offset=ARENA_OFFSET
        return wither_boss
    return super.create_enemy(spec)

func _set_enemy_active(enemy: RemixEnemy,value: bool) -> void:
    if enemy is WitherBoss:
        if value: enemy.activate()
        else: enemy.stop_attacks()
    else: super._set_enemy_active(enemy,value)

func checkpoint_specs() -> Array[Dictionary]:
    var specs:=super.checkpoint_specs()
    specs.append({"id":&"fortress_boss_camp","label":"核心门前","x":ARENA_OFFSET+96,"heals":false})
    return specs

func checkpoint_requirements(index: int) -> Array:
    var required: Array=range(17) if index==10 else super.checkpoint_requirements(index)
    if index>=5: required.append(TRANSPORT_GUARD)
    return required

func mechanism_requirements(index: int) -> Array[String]:
    if index>=7: return mechanism_ids()
    return ["fortress_furnace"] if index>=5 else []

func can_activate_checkpoint(index: int) -> bool:
    var specs:=checkpoint_specs()
    if index<=checkpoint_index or index>=specs.size(): return false
    var mechanisms: Dictionary=course.mechanism_state()
    for passed in range(checkpoint_index+1,index+1):
        if player.position.x<specs[passed].x-24: return false
        for target_index in checkpoint_requirements(passed):
            if targets[target_index].health.current>0: return false
        for id in mechanism_requirements(passed):
            if not mechanisms.get(id,false): return false
    return true

func _record_passed_checkpoints() -> void:
    if arena_active or intro_left>0: return
    var furthest:=checkpoint_index
    for index in range(checkpoint_index+1,checkpoint_specs().size()):
        if not can_activate_checkpoint(index): break
        furthest=index
    # A jump can cross the marker in midair. Save its authored ground spawn,
    # and catch up a stale chain with one write, never one write per skipped marker.
    if furthest>checkpoint_index: _activate_checkpoint(furthest)

func armory_positions() -> Array[float]:
    var positions:=super.armory_positions()
    positions.append(ARENA_OFFSET+160)
    return positions

func block_specs() -> Array[Dictionary]:
    var specs:=super.block_specs()
    specs.append_array([
        {"id":&"fortress_boss_bread_1","x":ARENA_OFFSET+256,"y":208,"data":BREAD_DATA},
        {"id":&"fortress_boss_bread_2","x":ARENA_OFFSET+432,"y":208,"data":BREAD_DATA},
        {"id":&"fortress_boss_apple","x":ARENA_OFFSET+848,"y":208,"data":apple_data}])
    return specs + AdventureRewards.blocks("fortress_core")



func _setup_arena() -> void:
    if is_instance_valid(reinforcements): return
    wither_boss.pillars=arena_course.pillars
    reinforcements=WitherBossGuards.new()
    reinforcements.level=self
    reinforcements.arena_offset=ARENA_OFFSET
    $World.add_child(reinforcements)
    wither_boss.phase_changed.connect(reinforcements.request)
    var reward: Node2D=load("res://scripts/world/fortress_reward.gd").new()
    reward.level=self
    reward.position=Vector2(exit_x,288)
    $World.add_child(reward)

func _restore_saved_run() -> void:
    # The common lifecycle resumes during setup_content, before _ready returns.
    _setup_arena()
    super._restore_saved_run()

func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    _tick_transport_guard(delta)
    _record_passed_checkpoints()
    if intro_left>0:
        intro_left=maxf(0,intro_left-delta)
        if intro_left<=0: wither_boss.activate()
    if not arena_active and wither_boss.health.current>0 and player.position.x>=ARENA_OFFSET+384 and checkpoint_index==10:
        arena_active=true
        intro_left=1.0
        equipment.suspend_input()
        clear_projectiles()
        arena_course.entrance.set_closed(true)
        camera.set_region_smooth(ARENA_OFFSET+320,ARENA_OFFSET+960,0.8)
    elif not arena_active and wither_boss.health.current>0 and player.position.x>=ARENA_OFFSET+384:
        toast="尚有守军或封印未完成 · 清除后核心会自动开启"
        toast_left=2
    super._physics_process(delta)

func _tick_transport_guard(delta: float) -> void:
    queue_redraw()
    var guard: PiglinBrute=targets[TRANSPORT_GUARD]
    if transport_awake or guard.health.current<=0: return
    if transport_warning<0:
        # No harassment during the timed crossing. The latched bridge stays open.
        if player.position.x<6688 or not player.is_on_floor(): return
        if not course.furnace.bridge_latched and not course.furnace.active: return
        transport_warning=1.0
        toast="桥已锁定 · 前方猪灵警戒！按交互键放下 TNT，再迎战"
        toast_left=4
        return
    transport_warning=maxf(0,transport_warning-delta)
    if transport_warning<=0:
        transport_awake=true
        _set_enemy_active(guard,true)

func _draw() -> void:
    if transport_warning>0 and is_instance_valid(player):
        var at: Vector2=targets[TRANSPORT_GUARD].position+Vector2(-38,-42)
        draw_arc(at,9,0,TAU,24,Color("ffc779"),2)
        draw_string(ui_font,at+Vector2(-2,3),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff0b4"))

func _enemy_loot(enemy: RemixEnemy) -> void:
    if enemy!=wither_boss:
        super._enemy_loot(enemy)
        return
    reinforcements.clear()
    health.pending.clear()
    wither.clear()
    arena_active=false
    intro_left=0
    _stop_charges()
    arena_course.exit_gate.set_closed(false)
    arena_course.entrance.set_closed(false)
    clear_projectiles()
    camera.set_region_smooth(ARENA_OFFSET,course_width,0.8)
    toast="凋灵消散 · 护卫退去 · 向右取回烈焰粉 ×3，完成第六关"
    toast_left=8

func _stop_charges() -> void:
    for charge in arena_course.charges: charge.stop()

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
    arena_course.entrance.set_closed(false)
    arena_course.exit_gate.set_closed(wither_boss.health.current>0)
    for pillar in arena_course.pillars: pillar.reset_pillar()
    for charge in arena_course.charges: charge.reset_charge()
    wither.clear()
    transport_warning=-1.0
    transport_awake=false

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
            for charge in arena_course.charges:
                if charge.interact():
                    get_viewport().set_input_as_handled()
                    return
    super._unhandled_input(event)

func segments() -> Array[Dictionary]:
    var entries:=super.segments()
    entries.append_array([{"x":ARENA_OFFSET,"name":"核心门前"},{"x":ARENA_OFFSET+384,"name":"三首苏醒"},{"x":ARENA_OFFSET+960,"name":"烈焰余烬"}])
    return entries

func level_title() -> String: return "06 / 堡垒核心"
func next_level_path() -> String: return CampaignCatalog.scene_path("the_end") if campaign_mode else ""
func boss_name() -> String: return "凋灵"
func boss_intro_title() -> String: return "堡垒核心 · 三首苏醒"
func boss_actor() -> RemixEnemy: return wither_boss
func result_hint() -> String:
    return "烈焰粉 3/3 · 末影珍珠 %d/3"%RunProgress.story_items.get("ender_pearl",0) if completed and campaign_mode else "九场守军战 · 灵魂封印 · 凋灵核心"
func panel_detail() -> String:
    if not campaign_mode: return "完整第六关试玩 · 不写正式存档" if not completed else "试玩完成 · 正式远征可保存烈焰粉，终章制作中"
    if completed:
        return "材料保存失败，请重试保存" if saves.last_error!=OK else "烈焰粉 3/3 已保存 · 前往第七关，开启末地之门"
    return "返回%s · 本段战斗与补给回滚"%checkpoint_specs()[checkpoint_index].label if defeated else "路标自动保存 · 绿宝石可跨关使用 · 路标不回血"

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("fortress_core")
func fixed_pickup_specs() -> Array[Dictionary]: return ExplorationRewards.specs("fortress_core")
func _place_fixed_pickups() -> void:
    for spec in fixed_pickup_specs(): _spawn_identified(spec.data,spec.at,1,run_id,spec.id)

func fragile_specs() -> Array[Dictionary]: return AdventureRewards.chests("fortress_core")
