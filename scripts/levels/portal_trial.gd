extends "res://scripts/levels/wither_lab.gd"
## Chapter seven prologue; isolated until the dragon/campaign package is ready.
var portal:=EndPortalState.new()
var portal_transition:=false
var transport_elapsed:=0.0
var shade: ColorRect
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4V"
    window_label="M4-V End Portal Prologue"
    hud_title="第七关序章 · 三眼之门"
    short_stage="M4-V.1"
    course_width=2944
    exit_x=2832
    finished_title="末地序章完成"
    toast="独立试玩 · 携带 3 珍珠 / 3 烈焰粉 · 清理要塞，开启古门"
    toast_left=8
func _ready() -> void:
    super._ready()
    if not campaign_mode:
        FinaleJourney.apply(self)
        snapshot=_make_snapshot(0)
    camera.set_region(0,2112)
    shade=ColorRect.new()
    shade.size=Vector2(640,360)
    shade.color=Color(0.03,0.02,0.08,0)
    shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    $UI.add_child(shade)
    $UI.move_child(shade,0)
    # Menus remain usable above the transport fade.
    $UI.move_child(input_panel,-1)
    if finale!=null:
        finale.finish_setup()
        show_guide("三眼祭坛 · 合成三颗末影之眼，逐一嵌入门槽")
func encounter_groups() -> Array: return [[0],[1,2]]
func encounter_hint(room: int) -> String:
    return "先清理僵尸 · 门后有断桥，靠近边缘再跳" if room==0 else "蜘蛛与射手夹击 · 清场后前往三眼合成台"
func create_enemy(spec: Dictionary) -> RemixEnemy:
    return SpiderEnemy.new() if spec.data.kind==EnemyData.Kind.SPIDER else RemixEnemy.new()
func enemy_specs() -> Array[Dictionary]:
    var specs: Array[Dictionary]=[{"data":zombie_data,"x":560},{"data":SPIDER_DATA,"x":1136},{"data":skeleton_data,"x":1296}]
    for i in specs.size():
        specs[i]["id"]=enemy_id(i)
        specs[i]["no_loot"]=specs[i].data.kind==EnemyData.Kind.SPIDER
    return specs
func enemy_id(index: int) -> StringName: return StringName("portal_guard_%d"%index)
func checkpoint_specs() -> Array[Dictionary]:
    return [{"id":&"portal_start","label":"要塞入口","x":96.0,"heals":false},
        {"id":&"portal_bridge","label":"断桥前沿","x":736.0,"heals":false},
        {"id":&"portal_altar","label":"三眼祭坛","x":1456.0,"heals":false},
        {"id":&"portal_end","label":"末地落脚点","x":2392.0,"heals":false}]
func checkpoint_requirements(index: int) -> Array: return [0] if index==1 else ([0,1,2] if index>=2 else [])
func block_specs() -> Array[Dictionary]:
    return [{"id":&"portal_apple","x":712,"y":208,"data":apple_data},
        {"id":&"portal_high_bread","x":944,"y":116,"data":BREAD_DATA}]
func armory_positions() -> Array[float]: return [160.0]
func segments() -> Array[Dictionary]:
    return [{"x":0,"name":"要塞前庭"},{"x":704,"name":"断桥补给"},{"x":960,"name":"回廊夹击"},{"x":1408,"name":"三眼之门"},{"x":2304,"name":"末地落脚点"}]
func can_activate_checkpoint(index: int) -> bool:
    if not super.can_activate_checkpoint(index): return false
    if index==3 and not portal.entered: return false
    for i in checkpoint_requirements(index):
        if targets[i].health.current>0: return false
    return true
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if portal_transition:
        transport_elapsed+=delta
        shade.color.a=clampf(transport_elapsed/0.45,0,1) if transport_elapsed<=0.45 else clampf((0.95-transport_elapsed)/0.50,0,1)
        if transport_elapsed>=0.45 and not portal.entered:
            portal.arrive()
            player.reset_at(Vector2(2392,288))
            player.controls_locked=true
            camera.set_region(2304,2944)
            _activate_checkpoint(3)
        if transport_elapsed>=0.95:
            _cancel_transport()
            ControlSettings.arm_release_gate()
            toast="已抵达末地 · 向右完成序章，准备进入末影龙巢"
            toast_left=7
        return
    # Authored safe respawns; a jump past a sign still records the cleared room.
    while checkpoint_index<2:
        var next:=checkpoint_index+1
        if player.position.x<checkpoint_specs()[next].x or not can_activate_checkpoint(next): break
        _activate_checkpoint(next)
    super._physics_process(delta)
func interaction_kind() -> int:
    if defeated or completed or course_paused or portal_transition or portal.entered or not player.is_on_floor(): return -1
    if is_instance_valid(input_panel) and input_panel.visible: return -1
    if is_instance_valid(loadout_panel) and loadout_panel.visible: return -1
    if cleared_count()!=targets.size() or checkpoint_index<2 or absf(player.position.y-288)>8: return -1
    if absf(player.position.x-1536)<40: return 0
    if portal.is_open() and absf(player.position.x-1840)<68: return 4
    for i in 3:
        if absf(player.position.x-course.SLOT_X[i])<36: return i+1
    return -1
func interaction_hint() -> String:
    var kind:=interaction_kind()
    if kind==0: return "三眼已合成 · 向右补齐门槽" if portal.crafted else "合成 3 末影之眼 · 消耗 3 珍珠 + 3 烈焰粉"
    if kind==4: return "进入末地 · 已记录门槽进度"
    if kind>0:
        if portal.has_eye(kind-1): return "此门槽已点亮 · 寻找下一个空槽"
        return "放入末影之眼 · 门槽 %d / 3"%kind if portal.crafted else "缺少末影之眼 · 先到左侧合成台"
    return ""
func interact() -> bool:
    var kind:=interaction_kind()
    var before:=portal.record()
    var old_snapshot:=snapshot
    var changed:=false
    if kind==0: changed=portal.craft()
    elif kind==4:
        portal_transition=true
        transport_elapsed=0
        player.controls_locked=true
        player.velocity=Vector2.ZERO
        player.clear_jump_memory()
        equipment.suspend_input()
        clear_projectiles()
        return true
    elif kind>0: changed=portal.insert(kind-1)
    if changed:
        snapshot=_make_snapshot(checkpoint_index)
        if finale!=null:
            persist_checkpoint()
            if saves.last_error!=OK:
                portal.restore(before)
                snapshot=old_snapshot
                return false
        toast="末地之门已苏醒 · 走到中央交互进入" if portal.is_open() else ("三眼已合成 · 向右分别放入三个空槽" if kind==0 else "门槽 %d / 3 已点亮 · 重试保留进度"%portal.count())
        toast_left=5
        sound.play_stream(PICKUP_SOUND)
    return changed
func _unhandled_input(event: InputEvent) -> void:
    var key_press: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
    var pad_press: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
    if (key_press or pad_press) and interaction_kind()>=0:
        interact()
        get_viewport().set_input_as_handled()
        return
    super._unhandled_input(event)
func _make_snapshot(index: int) -> CheckpointSnapshot:
    var saved:=super._make_snapshot(index)
    saved.mechanisms=portal.record()
    return saved
func _cancel_transport() -> void:
    portal_transition=false
    transport_elapsed=0
    player.controls_locked=false
    player.clear_jump_memory()
    if is_instance_valid(shade): shade.color.a=0
func restore_checkpoint() -> void:
    if not defeated or snapshot==null: return
    _cancel_transport()
    assert(portal.restore(snapshot.mechanisms),"Invalid trial portal snapshot")
    camera.set_region(2304 if portal.entered else 0,2944 if portal.entered else 2112)
    super.restore_checkpoint()
func restart_course() -> void:
    if finale!=null:
        finale.restart_segment()
        return
    _cancel_transport()
    portal=EndPortalState.new()
    camera.set_region(0,2112)
    super.restart_course()
    FinaleJourney.apply(self)
    snapshot=_make_snapshot(0)
    toast="序章重来 · 练习材料已重置为 3 珍珠 / 3 烈焰粉"
func _on_death() -> void:
    _cancel_transport()
    super._on_death()
func check_environment() -> void:
    if defeated or completed or portal_transition or player.position.y<=460: return
    var fall:=DamageEvent.create(course,0,4)
    fall.bypass_invulnerability=true
    fall.protection_override=1.0
    health.queue_damage(fall)
    equipment.suspend_input()
    clear_projectiles()
    player.reset_at(Vector2(736,288) if checkpoint_index>=1 and not portal.entered else snapshot.spawn)
    camera.reset_to_target()
func level_title() -> String: return "第七关序章 · 三眼之门"
func panel_title() -> String: return "要塞试炼失败" if defeated else (finished_title if completed else "序章暂停")
func result_hint() -> String: return "门槽 %d / 3 · %s"%[portal.count(),"正式材料合成 · 门槽自动保存" if campaign_mode else "独立练习，不消耗远征材料"]
func next_level_path() -> String:
    return "res://scenes/levels/end_dragon.tscn" if campaign_mode else ("res://scenes/levels/dragon_lab.tscn" if FinaleJourney.active else "")
func next_level_label() -> String: return "进入龙巢 · 末影龙"
func advance_level() -> void:
    if finale!=null: finale.advance()
    else: FinaleJourney.advance(self,next_level_path())
func panel_detail() -> String:
    if campaign_mode: return "正式终章 · 合成与门槽保留 · R 仅重来本段，恢复本段入场资源"
    if defeated: return "返回%s · 合成与已插入的眼保留"%checkpoint_specs()[checkpoint_index].label
    return ("继续进入末影龙巢 · 保留当前血食、宝石与装备" if FinaleJourney.active else "主菜单可进入末影龙试炼") if completed else "E 交互 · 三眼开门 · R 重来重置练习材料"

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("portal")
func fixed_pickup_specs() -> Array[Dictionary]: return ExplorationRewards.specs("portal")
func _place_fixed_pickups() -> void:
    for spec in fixed_pickup_specs(): _spawn_identified(spec.data,spec.at,1,run_id,spec.id)
