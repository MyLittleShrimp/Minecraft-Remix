extends Control
const FOREST := preload("res://assets/art/m4z4-theme/departure.png")
const LOGO := preload("res://assets/art/m4z4-theme/title.png")
var theme_seconds:=0.0
var course_paused := true
var defeated := false
var completed := false
var input_panel: InputSettingsPanel
var continue_button: Button
var new_button: Button
var stage_label: Label
var record_label: Label
var notice_label: Label
var modal: Control
var menu_buttons: Array[Button] = []
var launching := false
var chapters: ChapterSelect
var guide_label: Label
var fortress_trial_button: Button
var fortress_route_button: Button
var wither_boss_button: Button
var modal_return_index:=1
@onready var saves: Node = get_node("/root/SaveManager")
@onready var settings: Node = get_node("/root/ControlSettings")

func _ready() -> void:
    MusicDirector.play_track("menu")
    process_mode=Node.PROCESS_MODE_ALWAYS
    get_tree().paused=false
    get_window().title="Minecraft Remix | 方块远征"
    get_window().min_size=Vector2i(640,360)
    theme=MenuStyle.theme()
    MenuStyle.label(self,"从林地启程，向巨龙之巢。",Rect2(32,132,305,22),12,Color("fff0cf"))
    var journey:=MenuStyle.panel(self,Rect2(430,123,188,73))
    journey.modulate.a=0.88
    MenuStyle.label(self,"你的旅程",Rect2(441,129,165,16),10,MenuStyle.GOLD)
    stage_label=MenuStyle.label(self,"",Rect2(441,148,165,18),14,Color("f7ebc7"))
    record_label=MenuStyle.label(self,"",Rect2(441,174,165,18),10)
    stage_label.clip_text=true
    record_label.clip_text=true
    record_label.tooltip_text="路标自动保存；继续会恢复上次保存的位置。"
    continue_button=MenuStyle.button(self,"继续远征",Rect2(430,203,188,27),continue_run)
    new_button=MenuStyle.button(self,"开始新远征",Rect2(430,235,188,27),request_new)
    menu_buttons=[continue_button,new_button,
        MenuStyle.button(self,"选择章节",Rect2(430,267,188,27),show_chapters),
        MenuStyle.button(self,"设置",Rect2(430,301,53,25),open_settings),
        MenuStyle.button(self,"操作手册",Rect2(487,301,75,25),show_help),
        MenuStyle.button(self,"退出",Rect2(566,301,52,25),func() -> void: get_tree().quit())]
    for button in menu_buttons:
        button.add_theme_font_override("font",MenuStyle.TITLE_FONT)
        button.add_theme_font_size_override("font_size",12)
    notice_label=MenuStyle.label(self,"",Rect2(35,314,360,20),9,Color("ecd095"))
    notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    guide_label=MenuStyle.label(self,"",Rect2(35,293,360,18),10,MenuStyle.GOLD)
    MenuStyle.label(self,"方向键 选择 · Enter 确认 · F1 设置",Rect2(36,339,350,17),9)
    MenuStyle.label(self,"非官方同人作品",Rect2(508,339,110,17),9)
    input_panel=InputSettingsPanel.new()
    input_panel.level=self
    add_child(input_panel)
    input_panel.closed.connect(on_input_settings_closed)
    refresh()
    if saves.menu_return_chapters:
        saves.menu_return_chapters=false
        show_chapters.call_deferred()
    print("M4G_MENU_READY version=",ProjectSettings.get_setting("application/config/version"))
    if "--capture-and-exit" in OS.get_cmdline_user_args(): capture_and_exit()

func _process(delta: float) -> void:
    theme_seconds+=delta
    queue_redraw()

func _draw() -> void:
    var rect:=ScreenLayout.full_rect()
    MenuStyle.cover(self,FOREST,rect)
    # Local shading leaves the hero and the distant portal luminous.
    for i in 40:
        draw_rect(Rect2(rect.position.x,rect.position.y+i*6,rect.size.x,6),Color(0.015,0.04,0.045,maxf(0,0.58-i*0.016)))
    draw_texture_rect(LOGO,Rect2(22,24,317,106),false)
    draw_rect(Rect2(22,132,315,25),Color(0.035,0.085,0.08,0.56))
    draw_rect(Rect2(rect.position.x,286,rect.size.x,rect.end.y-286),Color(0.025,0.065,0.07,0.48))
    for i in 18:
        var at:=Vector2(fposmod(i*43.0+sin(theme_seconds*0.3+i)*7,340),208+fposmod(i*29.0-theme_seconds*4,92))
        draw_rect(Rect2(at,Vector2.ONE*(1 if i%3 else 2)),Color(0.94,0.85,0.45,0.25+0.2*sin(theme_seconds+i)))

func refresh() -> void:
    guide_label.text="向导开启 · 沿途显示操作提示" if settings.guide_enabled else "向导关闭 · 专注探索与战斗"
    var data: Dictionary = saves.inspect_save()
    continue_button.disabled=data.is_empty()
    continue_button.text="查看通关记录" if not data.is_empty() and data.completed else "继续远征"
    stage_label.text=CampaignCatalog.title("forest_ruins" if data.is_empty() else data.level_id)
    if data.is_empty(): record_label.text="准备启程 · 七个世界"
    else:
        var s: Dictionary=data.snapshot
        var place: String={"ruins_start":"营地入口","ruins_camp_a":"断桥路标","ruins_camp_b":"队长前哨","spider_start":"月夜入口","spider_camp_a":"溪畔路标","spider_camp_b":"守门前哨","mine_start":"矿道入口","mine_camp_a":"爆破后哨","mine_camp_b":"深矿路标","mine_transport_entry":"搬运室路标","mine_boss_camp":"裂岩前哨","tide_start":"潮岸武库","tide_camp_a":"潮纹路标","tide_camp_b":"沉桥前哨","tide_camp_c":"雷鸣前哨","tide_boss_camp":"神殿前哨","warped_start":"边界武库","warped_forest":"菌林路标","warped_bridge":"断桥前哨","warped_ash":"灰烬路标","warped_duet":"双影前哨","warped_ramparts":"断垣前哨","warped_warden":"裂隙前哨"}.get(s.checkpoint_id,"营地入口")
        if data.level_id=="fortress_core":
            for checkpoint in RunSaveCodec._catalog("fortress_core").checkpoints:
                if checkpoint.id==s.checkpoint_id: place="堡垒路标 %02d"%(RunSaveCodec._catalog("fortress_core").checkpoints.find(checkpoint)+1)
        if data.level_id=="the_end":
            place={"reunion":"六境回响","portal":"三眼之门","dragon":"巨龙之巢"}.get(data.finale.segment,"终章")
        record_label.text="%s · %d 宝石"%["本关已通关" if data.completed else place,int(data.entry_balance+s.emeralds-s.emeralds_spent)]
    notice_label.text=saves.notice if not saves.notice.is_empty() else "路标自动保存 · 离开后未结算进度回滚"
    if saves.last_error!=OK: notice_label.text="本次保存未成功；继续只能恢复上次存档，当前文件已保留。"
    settings.menu_open=true
    (new_button if continue_button.disabled else continue_button).grab_focus()

func continue_run() -> void:
    if launching: return
    if not saves.prepare_continue():
        refresh()
        return
    launch()

func request_new() -> void:
    if launching: return
    if saves.any_file():
        show_modal("开始新的远征？","当前进度槽将替换为新远征。\n已有按键设置会保留。",true)
    else: start_new()

func start_new() -> void:
    if launching: return
    saves.prepare_new()
    launch()

func launch() -> void:
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    var id: String=saves.pending_resume.get("level_id",saves.selected_chapter)
    get_tree().change_scene_to_file.call_deferred(CampaignCatalog.scene_path(id,saves.pending_resume.get("finale",{}).get("segment","reunion")))

func set_paused(_value: bool) -> void: pass
func launch_trial() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/ravager_lab.tscn")

func open_settings() -> void: input_panel.open_panel()
func launch_trident() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/trident_lab.tscn")

func launch_guardian() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/guardian_lab.tscn")

func launch_enderman() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/enderman_lab.tscn")

func launch_ghast() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/ghast_lab.tscn")

func on_input_settings_closed() -> void:
    settings.menu_open=true
    refresh()
    menu_buttons[3].grab_focus()

func show_help() -> void:
    modal_return_index=4
    show_modal("出发前，记住这些", "A/D 移动 · 空格长短跳 · S+空格下落\nJ 攻击 · 弩按住装填，松开再按发射\nK 换武器 · L 消耗20宝石释放大招\n跳劈 +2伤害 · 面包 +6饱食 · 苹果 +4生命\n饱食为零：每10秒扣1生命\n路标自动保存 · R重开 · E交互 · F1设置\n手柄可在设置中映射；交互使用映射向上",false)

func show_modal(title: String, body: String, confirm: bool) -> void:
    if is_instance_valid(modal): return
    for button in menu_buttons: button.focus_mode=Control.FOCUS_NONE
    modal=Control.new()
    modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal.mouse_filter=Control.MOUSE_FILTER_STOP
    add_child(modal)
    var shade:=ColorRect.new()
    shade.color=Color(0.015,0.035,0.045,0.96)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    modal.add_child(shade)
    MenuStyle.title(modal,title,Rect2(92,65,460,40),24)
    MenuStyle.label(modal,body,Rect2(92,116,460,144),12)
    var cancel:=MenuStyle.button(modal,"取消" if confirm else "返回",Rect2(92,280,210,30),close_modal)
    if confirm: MenuStyle.button(modal,"开始新远征",Rect2(330,280,210,30),start_new)
    cancel.grab_focus()

func close_modal() -> void:
    if is_instance_valid(modal):
        modal.queue_free()
        modal=null
        for button in menu_buttons: button.focus_mode=Control.FOCUS_ALL
        menu_buttons[modal_return_index].grab_focus()
        modal_return_index=1

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11: return # Global display shortcut also works inside modals.
    if launching or input_panel.visible or is_instance_valid(chapters): return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_ESCAPE and is_instance_valid(modal):
            close_modal()
            get_viewport().set_input_as_handled()
        elif event.keycode==KEY_F1 and not is_instance_valid(modal): open_settings()
        elif event.keycode==KEY_F11: ScreenLayout.toggle_fullscreen()
    if (event is InputEventJoypadButton or event is InputEventJoypadMotion) and not is_instance_valid(modal) and settings.event_pressed(event,"settings"):
        open_settings()
        get_viewport().set_input_as_handled()
        return
    MenuStyle.gamepad(event,self,close_modal)

func capture_and_exit() -> void:
    await get_tree().create_timer(0.6).timeout
    await RenderingServer.frame_post_draw
    var directory:=OS.get_environment("REMIX_CAPTURE_DIR")
    if directory.is_empty(): directory="user://captures"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
    var error:=get_viewport().get_texture().get_image().save_png(directory.path_join("m4t-wither-boss-menu.png"))
    print("M4G_CAPTURE result=",error)
    get_tree().quit()

func launch_warped() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/warped_route.tscn")

func launch_wither() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/wither_lab.tscn")

func show_fortress() -> void:
    if is_instance_valid(modal): return
    show_modal("第六关 · 堡垒核心", "正式远征：从第五关结算页继续。\n以下独立试玩不改存档；完整路线已包含凋灵战。",false)
    modal_return_index=2
    fortress_route_button=MenuStyle.button(modal,"完整第六关 · 守军 / 机关 / 凋灵",Rect2(92,168,448,30),launch_fortress_preview)
    wither_boss_button=MenuStyle.button(modal,"凋灵 Boss · 三首齐射 / 狂暴冲刺",Rect2(92,204,448,30),launch_wither_boss)
    fortress_trial_button=MenuStyle.button(modal,"基础试炼 · 凋灵骷髅与三种猪灵",Rect2(92,240,448,30),launch_wither)
    fortress_route_button.grab_focus()
func launch_fortress() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/fortress_route.tscn")

func launch_wither_boss() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/wither_boss_lab.tscn")

func launch_fortress_preview() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/fortress_preview.tscn")

func launch_portal() -> void:
    if launching: return
    launching=true
    FinaleJourney.reset()
    settings.menu_open=false
    settings.arm_release_gate()
    saves.enabled=false
    saves.pending_resume.clear()
    get_tree().change_scene_to_file("res://scenes/levels/portal_trial.tscn")

func show_end() -> void:
    if is_instance_valid(modal): return
    show_modal("第七关 · 末地终章", "回顾战 → 三眼之门 → 末影龙，保留段间血食。\n正式远征已接通七关；这里保留独立练习入口。",false)
    modal_return_index=2
    var first:=MenuStyle.button(modal,"完整试玩 · 六境回响 → 古门 → 龙巢",Rect2(92,168,448,30),launch_reunion)
    MenuStyle.button(modal,"三眼之门 · 合成 / 插眼 / 穿门",Rect2(92,204,448,30),launch_portal)
    MenuStyle.button(modal,"末影龙试炼 · 拆晶 / 连冲 / 扫尾",Rect2(92,240,448,30),launch_dragon)
    first.grab_focus()
func launch_dragon() -> void:
    if launching: return
    launching=true
    FinaleJourney.reset()
    settings.menu_open=false
    settings.arm_release_gate()
    saves.enabled=false
    saves.pending_resume.clear()
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/dragon_lab.tscn")

func launch_reunion() -> void:
    if launching: return
    launching=true
    settings.menu_open=false
    settings.arm_release_gate()
    saves.enabled=false
    saves.pending_resume.clear()
    FinaleJourney.reset(true)
    get_tree().change_scene_to_file.call_deferred("res://scenes/levels/reunion_route.tscn")

func show_chapters() -> void:
    if launching or is_instance_valid(chapters): return
    for button in menu_buttons: button.focus_mode=Control.FOCUS_NONE
    chapters=ChapterSelect.new()
    add_child(chapters)
    chapters.closed.connect(func() -> void:
        chapters.queue_free()
        chapters=null
        for button in menu_buttons: button.focus_mode=Control.FOCUS_ALL
        menu_buttons[2].grab_focus())
    chapters.chosen.connect(start_chapter)

func start_chapter(id: String, standalone: bool) -> void:
    if launching: return
    if not saves.prepare_chapter(id,standalone): return
    launch()
