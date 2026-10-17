extends "res://scripts/levels/branch_lab.gd"
## Shared campaign lifecycle. Encounter rules remain in each level controller.
@export var trophy_data: PickupData
@export var campaign_level_id: StringName = &"forest_ruins"
@export var boss_music_id := ""
const SPIDER_DATA = preload("res://resources/enemies/spider.tres")
const BREAD_DATA = preload("res://resources/items/bread.tres")
var wildlife: Array[WildlifeActor] = []
var hunger: HungerComponent
var wallet: EmeraldWallet
var campaign_ticket: int = -1
var campaign_settled := false
var input_panel: InputSettingsPanel
var settings_button: Button
var music_button: MusicToggleButton
var transitioning := false
var loadout_panel: LoadoutPanel
var practice_target: TrainingDummy
@export var finale_segment := ""
var finale: FinaleCampaign
var entry_guide_toast := ""
var guide_toast := ""
@onready var saves: Node = get_node("/root/SaveManager")

func _item_data(id: StringName) -> PickupData:
    for food in extra_item_data():
        if food.id==id: return food
    if id==BREAD_DATA.id: return BREAD_DATA
    return trophy_data if id==trophy_data.id else super._item_data(id)

func setup_content() -> void:
    MusicDirector.play_track(str(campaign_level_id))
    MusicDirector.prepare_track(boss_music_id)
    wallet = EmeraldWallet.new()
    wallet.name = "EmeraldWallet"
    player.add_child(wallet)
    equipment.wallet = wallet
    hunger=HungerComponent.new()
    hunger.name="Hunger"
    player.add_child(hunger)
    _enter_campaign_level()
    equipment.ultimate_used.connect(func(label: String) -> void:
        toast = "%s！-20 绿宝石 · 剩余 %d" % [label,wallet.available()]
        toast_left = 3
        sound.play_stream(PICKUP_SOUND)
        print("ULTIMATE_USED weapon=%s spent=%d balance=%d" % [equipment.equipped().id,wallet.spent,wallet.available()]))
    equipment.ultimate_denied.connect(func(reason: String) -> void:
        toast = reason
        toast_left = 2)
    entry_guide_toast=toast
    _setup_wildlife()
    super.setup_content()
    settings_button = Button.new()
    settings_button.text="F1 设置"
    settings_button.position=Vector2(550,324)
    settings_button.size=Vector2(72,24)
    settings_button.theme=MenuStyle.theme()
    settings_button.add_theme_font_override("font",ui_font)
    settings_button.add_theme_font_size_override("font_size",12)
    settings_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    for state in ["normal","hover","pressed","focus"]:
        var style:=StyleBoxFlat.new()
        style.bg_color=Color("304941") if state in ["hover","focus"] else Color("13272c")
        if state=="pressed": style.bg_color=Color("405b4c")
        style.border_color=Color("d4b776")
        style.set_border_width_all(1 if state in ["hover","focus"] else 0)
        style.set_content_margin_all(0)
        settings_button.add_theme_stylebox_override(state,style)
    $UI.add_child(settings_button)
    settings_button.size=Vector2(72,24) # Apply after theme, which changes the minimum size.
    settings_button.pressed.connect(func() -> void: input_panel.open_panel())
    music_button=MusicToggleButton.new()
    music_button.name="MusicToggle"
    # Inherit the settings cell's visibility when ending screens hide the dock.
    music_button.position=Vector2(-34,0)
    settings_button.add_child(music_button)
    music_button.save_failed.connect(func(error: Error) -> void:
        toast="音乐设置保存失败（%d），请重试" % error
        toast_left=3.0)
    input_panel=InputSettingsPanel.new()
    input_panel.level=self
    $UI.add_child(input_panel)
    ControlSettings.device_lost.connect(_controller_lost)
    ControlSettings.changed.connect(_controls_changed)
    ControlSettings.guide_changed.connect(_redraw_guide)
    var pause_actions := Control.new()
    pause_actions.set_script(load("res://scripts/ui/pause_actions.gd"))
    pause_actions.level=self
    $UI.add_child(pause_actions)
    # Input settings must remain above every other menu.
    $UI.move_child(input_panel,-1)
    if not armory_positions().is_empty():
        for x in armory_positions():
            var station: Node2D=load("res://scripts/world/weapon_station.gd").new()
            station.level=self
            station.ui_font=ui_font
            station.position=Vector2(x,288)
            $World.add_child(station)
        var practice:=TrainingDummy.new()
        practice_target=practice
        practice.position=Vector2(390,288)
        practice.hit_points=12
        practice.ui_font=ui_font
        practice.label="试劈木靶" if campaign_level_id==&"abandoned_mine" else "试射木靶"
        if campaign_level_id==&"tidal_ruins": practice.label="试戟木靶"
        $World.add_child(practice)
        practice.health.died.connect(func() -> void:
            await get_tree().create_timer(3.0,false).timeout
            if is_instance_valid(practice): practice.reset_target())
        loadout_panel=LoadoutPanel.new()
        loadout_panel.level=self
        $UI.add_child(loadout_panel)
    if saves.enabled and finale_segment.is_empty():
        if not saves.pending_resume.is_empty(): _restore_saved_run()
        else: persist_checkpoint()
    if campaign_level_id!=&"forest_ruins" and not completed:
        var shade:=ColorRect.new()
        shade.size=Vector2(640,360)
        shade.color=Color(0.02,0.06,0.10,1)
        shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
        $UI.add_child(shade)
        var fade:=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        fade.tween_property(shade,"color:a",0.0,0.6)
        fade.tween_callback(shade.queue_free)

func music_track_id() -> String:
    if has_campaign_ending(): return "victory"
    if not defeated and not completed and get("arena_active")==true and not boss_music_id.is_empty():
        return boss_music_id
    return str(campaign_level_id)

func _restore_saved_run() -> void:
    var data: Dictionary=saves.pending_resume.duplicate(true)
    saves.pending_resume.clear()
    var restored := RunSaveCodec.unpack(data)
    if restored==null:
        saves.notice="存档无法恢复；原文件保留。"
        saves.return_to_menu.call_deferred()
        return
    snapshot=restored
    defeated=true
    restore_checkpoint()
    play_seconds=float(data.play_seconds)
    deaths=int(data.deaths)
    if data.completed:
        completed=true
        health.current=restored.player_health
        hunger.restore(restored.player_food,true)
        player.reset_at(Vector2(exit_x+6,288))
        camera.reset_to_target()
        campaign_settled=RunProgress.complete_level(campaign_level_id,campaign_ticket,wallet.available(),hunger.value,CampaignCatalog.story_reward(str(campaign_level_id)))
        get_tree().paused=true
    equipment.suspend_input()
    ControlSettings.arm_release_gate()
    toast="已恢复通关记录" if completed else "已从%s继续 · 本段未结算进度回滚" % checkpoint_specs()[checkpoint_index].label
    toast_left=6
    print("SAVE_RESTORE checkpoint=%s completed=%s balance=%d food=%.2f" % [snapshot.checkpoint_id,completed,wallet.available(),hunger.value])

func persist_checkpoint() -> void:
    if finale!=null:
        finale.save()
        return
    if not saves.enabled: return
    saves.save_level(self,_make_snapshot(checkpoint_index) if completed else snapshot,completed)
    if saves.last_error!=OK:
        toast=saves.notice
        toast_left=10

func _activate_checkpoint(index: int) -> void:
    var before := checkpoint_index
    super._activate_checkpoint(index)
    if checkpoint_index!=before:
        persist_checkpoint()
        if saves.enabled and saves.last_error==OK: toast+=" · 已保存"

func _enter_campaign_level() -> void:
    if not finale_segment.is_empty():
        if finale==null: finale=FinaleCampaign.new(self)
        finale.enter()
        return
    var entry: Dictionary = RunProgress.enter_level(campaign_level_id,true)
    assert(not entry.is_empty(),"Finish the current campaign level before changing scenes")
    campaign_ticket = entry.ticket
    wallet.reset_to_entry(entry.emeralds)
    hunger.restore(entry.food,true)
    campaign_settled = false
    if not RunProgress.travel_equipment.is_empty():
        var carried: Dictionary=RunProgress.travel_equipment
        equipment.configure_loadout(carried.ids)
        for i in equipment.weapons.size():
            if equipment.weapons[i].id==carried.selected: equipment.slot=i
        equipment.crossbow_ammo=carried.ammo
        RunProgress.travel_equipment.clear()

func result_hint() -> String:
    return "本关收集 %d · 大招花费 %d · 剩余 %d" % [items.emeralds,wallet.spent,wallet.available()]

func _picked_up(pickup: RemixPickup, actor: RemixPlayer, amount: int) -> void:
    super._picked_up(pickup,actor,amount)
    if pickup.data.kind == PickupData.Kind.EMERALD:
        toast = "绿宝石 +%d · 余额 %d / 20 · %s %s" % [amount,wallet.available(),ControlSettings.hint("ultimate"),equipment.equipped().ultimate.label]

func _block_opened(block: SupplyBlock, actor: RemixPlayer) -> void:
    super._block_opened(block,actor)
    toast = "%s已弹出 · 到路标结算收集" % block.content.label

func _controls_changed() -> void:
    equipment.suspend_input()
    player.clear_jump_memory()

func _controller_lost() -> void:
    set_paused(true)
    toast="手柄已断开，游戏暂停；F1切换设置，键盘可临时使用。"
    toast_left=8

func _unhandled_input(event: InputEvent) -> void:
    if is_instance_valid(loadout_panel) and loadout_panel.visible: return
    if transitioning:
        get_viewport().set_input_as_handled()
        return
    if is_instance_valid(input_panel) and input_panel.visible: return
    if is_instance_valid(loadout_panel) and can_use_armory():
        var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
        var pad: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
        if keyboard or pad:
            loadout_panel.open_panel()
            get_viewport().set_input_as_handled()
            return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F1:
        input_panel.open_panel()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        if ControlSettings.event_pressed(event,"settings",true): input_panel.open_panel()
        elif ControlSettings.event_pressed(event,"pause"):
            set_paused(not course_paused)
            ControlSettings.arm_release_gate()
        elif defeated and ControlSettings.event_pressed(event,"retry"):
            restore_checkpoint()
            ControlSettings.arm_release_gate()
        elif (course_paused or defeated or completed) and ControlSettings.event_pressed(event,"restart"):
            restart_course()
            ControlSettings.arm_release_gate()
        return
    # F1 / Esc and window / exit commands remain a keyboard escape hatch.
    if ControlSettings.gamepad_active() and event is InputEventKey and event.keycode not in [KEY_ESCAPE,KEY_F11,KEY_F12,KEY_Q,KEY_M]: return
    super._unhandled_input(event)

func panel_controls() -> String:
    if not ControlSettings.gamepad_active():
        return ("Enter 重试 · R 重来" if defeated else ("R 重来" if completed else "Esc 继续 · R 重来"))+" · F1 设置 · Q 退出"
    if defeated: return "%s 重试 · %s 重来 · F1 设置" % [ControlSettings.hint("retry"),ControlSettings.hint("restart")]
    if completed: return "%s 重来 · %s 设置" % [ControlSettings.hint("restart"),ControlSettings.hint("settings")]
    return "%s 继续 · %s 设置 · %s 重来" % [ControlSettings.hint("pause"),ControlSettings.hint("settings"),ControlSettings.hint("restart")]
func panel_detail() -> String:
    if completed and saves.single_chapter and finale==null: return "单关完成 · 可重玩本关，或返回章节选择"
    if defeated: return "返回%s · 生命%d · 饱食%d · 本段回滚" % [checkpoint_specs()[checkpoint_index].label,clampi(snapshot.player_health,10,20),ceili(maxf(8,snapshot.player_food))]
    return "%s 释放武器大招 · 每次 20 绿宝石" % ControlSettings.hint("ultimate") if not completed else "余额保留 · 下关饱食回满 · 选择前往下一关，继续远征"

func _physics_process(delta: float) -> void:
    if transitioning: return
    super._physics_process(delta)
    if completed and not campaign_settled:
        if finale!=null:
            finale.on_stage_completed()
            return
        campaign_settled = RunProgress.complete_level(campaign_level_id,campaign_ticket,wallet.available(),hunger.value,CampaignCatalog.story_reward(str(campaign_level_id)))
        print("CAMPAIGN_SETTLED level=%s balance=%d once=%s" % [campaign_level_id,RunProgress.balance,campaign_settled])
        persist_checkpoint()

func restart_course() -> void:
    if transitioning: return
    if finale!=null:
        finale.restart_segment()
        return
    for animal in wildlife: animal.reset_target()
    if is_instance_valid(wallet): _enter_campaign_level()
    super.restart_course()
    if is_instance_valid(practice_target): practice_target.reset_target()
    persist_checkpoint()

func _enemy_loot(enemy: RemixEnemy) -> void:
    if enemy.data.kind != EnemyData.Kind.SPIDER: super._enemy_loot(enemy)

func fixed_pickup_specs() -> Array[Dictionary]:
    return []

func wildlife_specs() -> Array[Dictionary]:
    return []

func extra_item_data() -> Array[PickupData]:
    return WildlifeContent.FOODS + AdventureRewards.ITEMS

func _apply_pickup_layout(pickup: RemixPickup) -> void:
    for spec in fixed_pickup_specs():
        if spec.id==pickup.get_meta("object_id") and spec.get("floating",false):
            # Layout belongs to authored content, not saved falling velocities.
            # Old uncollected IDs move to the new anchor; consumed IDs stay absent.
            pickup.anchor_at(spec.at)
            return

func optional_enemy_specs() -> Array[Dictionary]: return []

func extra_drop_specs() -> Array[Dictionary]: return []

func mechanism_ids() -> Array[String]:
    return []

func mechanism_requirements(_index: int) -> Array[String]:
    return []

func emerald_budget() -> int:
    return 26

func next_level_path() -> String:
    return ""

func next_level_label() -> String:
    for entry in CampaignCatalog.LEVELS.values():
        if entry.scene==next_level_path(): return "前往 "+entry.title
    return "前往下一关"

func completion_mechanisms() -> Array[String]:
    return mechanism_requirements(2)

func armory_positions() -> Array[float]:
    if campaign_level_id==&"spiderwood": return [160.0,3392.0,5872.0]
    return []

func advance_level() -> void:
    if saves.single_chapter and finale==null: return
    if transitioning or not completed or not campaign_settled or next_level_path().is_empty(): return
    if saves.enabled:
        persist_checkpoint()
        if saves.last_error!=OK: return
    transitioning=true
    equipment.suspend_input()
    ControlSettings.arm_release_gate()
    # SceneTree timers/tweens run while the completed world remains frozen.
    var shade:=ColorRect.new()
    shade.color=Color(0.02,0.06,0.10,0)
    shade.size=Vector2(640,360)
    shade.mouse_filter=Control.MOUSE_FILTER_STOP
    $UI.add_child(shade)
    var tween:=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(shade,"color:a",1.0,0.55)
    await tween.finished
    RunProgress.travel_equipment={"ids":equipment.loadout_ids(),"selected":equipment.equipped().id,"ammo":equipment.crossbow_ammo}
    saves.pending_resume.clear()
    ControlSettings.menu_open=false
    get_tree().paused=false
    get_tree().change_scene_to_file(next_level_path())

func _make_snapshot(index: int) -> CheckpointSnapshot:
    var saved:=super._make_snapshot(index)
    if course.has_method("mechanism_state"): saved.mechanisms=course.mechanism_state()
    for animal in wildlife: saved.wildlife_health[animal.get_meta("object_id")]=animal.health.current
    saved.loadout_ids=equipment.loadout_ids()
    saved.crossbow_ammo=equipment.crossbow_ammo
    saved.story_items=RunProgress.entry_story_items.duplicate(true)
    if completed:
        for key in CampaignCatalog.story_reward(str(campaign_level_id)):
            saved.story_items[key]=int(saved.story_items.get(key,0))+int(CampaignCatalog.story_reward(str(campaign_level_id))[key])
    if finale!=null:
        var spent: bool=finale_segment=="dragon" or (finale_segment=="portal" and get("portal").crafted)
        saved.story_items={"ender_pearl":0 if spent else 3,"blaze_powder":0 if spent else 3}
    return saved

func has_campaign_ending() -> bool:
    return finale!=null and is_instance_valid(finale.ending) and finale.returned

func restore_checkpoint() -> void:
    if not defeated or snapshot==null: return
    if course.has_method("restore_mechanisms"): course.restore_mechanisms(snapshot.mechanisms)
    equipment.configure_loadout(snapshot.loadout_ids)
    super.restore_checkpoint()
    equipment.crossbow_ammo=snapshot.crossbow_ammo
    for animal in wildlife:
        animal.reset_target()
        animal.health.current=int(snapshot.wildlife_health.get(animal.get_meta("object_id"),6))
        if animal.health.current<=0:
            animal.state=RemixEnemy.State.DEAD
            animal.receiver.set_deferred("collision_layer",0)

func can_use_armory() -> bool:
    if armory_positions().is_empty() or defeated or completed or transitioning or player.controls_locked: return false
    if is_instance_valid(input_panel) and input_panel.visible: return false
    if get("arena_active")==true or not player.is_on_floor(): return false
    var nearby:=false
    var positions: Array[float]=armory_positions()
    for i in positions.size():
        if i<=checkpoint_index and absf(player.position.x-positions[i])<=72 and absf(player.position.y-288)<8: nearby=true
    if not nearby: return false
    for enemy in targets:
        if enemy.health.current>0 and enemy.position.distance_to(player.position)<240: return false
    return true

func apply_loadout(ids: Array) -> void:
    if not can_use_armory() or ids.size()!=2 or ids[0]==ids[1]: return
    for id in ids:
        if id not in CampaignCatalog.weapon_ids(str(campaign_level_id)): return
    equipment.configure_loadout(ids)
    # Save only the equipment decision, never bank unsaved loot or restore food.
    snapshot.loadout_ids=equipment.loadout_ids()
    snapshot.weapon_id=equipment.equipped().id
    snapshot.crossbow_ammo=equipment.crossbow_ammo
    persist_checkpoint()
    toast="重斧已装备 · 慢重击，抓住卫道士收招的破绽" if "axe" in ids else "配装已应用 · 弩：按住装填，松开再按发射"
    if "trident" in ids: toast="三叉戟已装备 · 短按松手突刺，蓄力0.5秒松手投掷，L 天降雷霆"
    if not ControlSettings.guide_enabled: toast="装备已更换 · "+equipment.weapons[0].label+" / "+equipment.weapons[1].label
    toast_left=7


func _setup_wildlife() -> void:
    for spec in wildlife_specs():
        var animal:=WildlifeActor.new()
        animal.species=spec.species
        animal.food=spec.food
        animal.data=EnemyData.new()
        animal.data.max_health=6
        animal.data.contact_damage=0
        animal.data.label=spec.label
        animal.position=Vector2(spec.x,spec.get("y",288))
        animal.roam_left=spec.x-spec.get("roam",40)
        animal.roam_right=spec.x+spec.get("roam",40)
        animal.ui_font=ui_font
        animal.view_camera=camera
        animal.target=player
        animal.set_meta("object_id",spec.id)
        $World.add_child(animal)
        wildlife.append(animal)
        animal.defeated.connect(_wildlife_loot)

func _wildlife_loot(animal: WildlifeActor) -> void:
    _queue_drop(animal.food,animal.center(),1,StringName("wildlife/"+str(animal.get_meta("object_id"))))

func visible_toast() -> bool:
    return toast!=entry_guide_toast and (ControlSettings.guide_enabled or toast!=guide_toast)

func session_detail() -> String:
    if saves.single_chapter:
        return "本次路标可重试 · 关内保留资源 · 不覆盖远征存档" if finale!=null else "单关游玩 · 本次路标可重试 · 不覆盖远征存档"
    return panel_detail()

func _redraw_guide() -> void:
    _redraw_guide_branch($World)

func _redraw_guide_branch(node: Node) -> void:
    if node is CanvasItem: node.queue_redraw()
    for child in node.get_children(): _redraw_guide_branch(child)

func show_guide(message: String, seconds: float=4) -> void:
    guide_toast=message
    toast=message
    toast_left=seconds

func configure_view() -> void:
    super.configure_view()
    get_window().title="方块远征 | "+CampaignCatalog.title(str(campaign_level_id))
