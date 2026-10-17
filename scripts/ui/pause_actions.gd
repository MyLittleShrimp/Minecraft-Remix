extends Control
var level: Node
var save_button: Button
var menu_button: Button
var notice: Label
var next_button: Button
var reset_room_button: Button
var was_visible := false
@onready var saves: Node = get_node("/root/SaveManager")
@onready var settings: Node = get_node("/root/ControlSettings")
func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    theme=MenuStyle.theme()
    theme.default_font_size=12
    menu_button=MenuStyle.button(self,"返回主菜单",Rect2(124,279,124,27),leave)
    save_button=MenuStyle.button(self,"重试保存",Rect2(258,279,124,27),retry_save)
    MenuStyle.button(self,"退出游戏",Rect2(392,279,124,27),func() -> void: get_tree().quit())
    notice=MenuStyle.label(self,"",Rect2(124,310,480,18),9,Color("d4b776"))
    next_button=MenuStyle.button(self,level.next_level_label(),Rect2(192,60,256,29),func() -> void:
        if saves.single_chapter and level.finale==null: leave()
        else: level.advance_level())
    hide()
    reset_room_button=MenuStyle.button(self,"重置机关房 · 不回血",Rect2(224,243,192,27),func() -> void: level.reset_transport())
func _process(_delta: float) -> void:
    visible=(level.course_paused or level.defeated or level.completed) and not level.input_panel.visible and not (is_instance_valid(level.loadout_panel) and level.loadout_panel.visible)
    if level.has_method("has_campaign_ending") and level.has_campaign_ending(): visible=false
    next_button.visible=level.completed and (saves.single_chapter or not level.next_level_path().is_empty())
    next_button.text="返回章节选择" if saves.single_chapter and level.finale==null else level.next_level_label()
    next_button.disabled=level.transitioning
    reset_room_button.visible=visible and level.has_method("can_reset_transport") and level.can_reset_transport()
    if visible and not was_visible:
        (next_button if next_button.visible else save_button).grab_focus()
    if visible:
        menu_button.text="章节选择" if saves.single_chapter else "返回主菜单"
        save_button.disabled=false
        save_button.text="重试保存" if saves.enabled and saves.last_error!=OK else ("重试路标" if level.defeated else ("重玩本关" if level.completed else "继续游戏"))
        notice.text=saves.notice if saves.last_error!=OK else ("通关记录已保存，绿宝石余额保留。" if level.completed else "自动存档已保留；继续从最近路标恢复。") if saves.enabled else ("单关游玩 · 现有远征存档保留。" if saves.single_chapter else "独立练习 · 不写入远征存档。")
    was_visible=visible
func retry_save() -> void:
    if saves.enabled and saves.last_error!=OK: level.persist_checkpoint()
    elif level.defeated: level.restore_checkpoint()
    elif level.completed: level.restart_course()
    else: level.set_paused(false)
    settings.arm_release_gate()
func leave() -> void:
    saves.return_to_menu.call_deferred()
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11: return # Global display shortcut also works inside modals.
    if not visible or level.input_panel.visible or level.transitioning: return
    if event is InputEventKey and event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
        # Consume before the level's legacy Enter-to-retry shortcut. Confirmation
        # must execute the highlighted menu action, including after navigation.
        get_viewport().set_input_as_handled()
        if event.pressed and not event.echo:
            var focus:=get_viewport().gui_get_focus_owner()
            if not (focus is Button and is_ancestor_of(focus)):
                focus=next_button if next_button.visible else save_button
                focus.grab_focus()
            if focus.is_visible_in_tree() and not focus.disabled: focus.pressed.emit()
        return
    # Pause/settings/retry/restart retain the established gameplay shortcuts.
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        for action in ["pause","settings","retry","restart"]:
            if event.is_action_pressed("pad_"+action,false,true): return
        MenuStyle.gamepad(event,self,func() -> void: pass)
