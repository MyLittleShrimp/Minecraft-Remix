class_name InputSettingsPanel
extends Control
signal closed
## An actual focusable settings form; game is paused throughout editing and capture.
var level: Node
var original: Dictionary
var was_paused := false
var mode_choice: OptionButton
var device_choice: OptionButton
var zone: HSlider
var zone_label: Label
var status: Label
var message: Label
var cells: Dictionary = {}
var capture_action := ""
var capture_slot := 0
var capture_origins: Dictionary = {}
var capture_buttons: Dictionary = {}
var capture_axis_blocked: Dictionary = {}
var refreshing := false
var guide_button: Button

var pages: Array[Control] = []
var tabs: Array[Button] = []
var build_parent: Control
var current_page := 0
var music_slider: HSlider
var music_label: Label
var track_label: Label

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_STOP
    theme=MenuStyle.theme()
    var shade := ColorRect.new()
    shade.color=Color(0.025,0.06,0.08,0.98)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    build_parent=self
    MenuStyle.title(self,"设置",Rect2(24,12,220,36),24)
    var close := make_button("× 关闭",Rect2(544,20,72,26))
    close.pressed.connect(func() -> void: close_panel(false))
    for i in 2:
        var tab:=make_button(["游戏与声音","手柄映射"][i],Rect2(24+i*166,52,158,26))
        tab.pressed.connect(show_page.bind(i))
        tabs.append(tab)
        var page:=Control.new()
        page.mouse_filter=Control.MOUSE_FILTER_IGNORE
        add_child(page)
        pages.append(page)
    build_parent=pages[0]
    MenuStyle.panel(build_parent,Rect2(24,91,282,189))
    MenuStyle.panel(build_parent,Rect2(318,91,298,189))
    label_at("游玩偏好",Rect2(38,103,240,18),12)
    guide_button=make_button("",Rect2(38,131,254,28))
    guide_button.pressed.connect(func() -> void:
        ControlSettings.guide_enabled=not ControlSettings.guide_enabled
        refresh()
        message.text="已预览向导设置；保存保留，取消还原。")
    label_at("熟手隐藏教学；保留交互与危险预警。",Rect2(38,169,254,33),12).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    var screen_button:=make_button("F11 全屏 / 窗口",Rect2(38,212,254,28))
    screen_button.pressed.connect(ScreenLayout.toggle_fullscreen)
    label_at("向导不改变战斗难度",Rect2(38,250,254,18),12)
    music_label=label_at("",Rect2(332,103,270,18),12)
    music_slider=HSlider.new()
    music_slider.min_value=0
    music_slider.max_value=100
    music_slider.step=5
    place(music_slider,Rect2(334,135,262,24))
    music_slider.value_changed.connect(func(value: float) -> void:
        if refreshing: return
        ControlSettings.music_volume=value/100.0
        music_label.text="音乐音量  %d%%" % roundi(value))
    label_at("拖动即可试听 · 0% 静音",Rect2(332,170,268,18),12)
    track_label=label_at("",Rect2(332,207,268,44),12)
    track_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label_at("按关卡自动换曲 · 循环播放",Rect2(332,253,268,18),12)
    build_parent=pages[1]
    mode_choice=OptionButton.new()
    mode_choice.add_item("键盘",0)
    mode_choice.add_item("手柄",1)
    place(mode_choice,Rect2(24,88,112,24))
    mode_choice.item_selected.connect(func(index: int) -> void:
        if refreshing: return
        ControlSettings.choose_mode("keyboard" if index==0 else "gamepad")
        refresh())
    device_choice=OptionButton.new()
    place(device_choice,Rect2(144,88,268,24))
    device_choice.item_selected.connect(func(index: int) -> void:
        if refreshing: return
        ControlSettings.choose_device(device_choice.get_item_id(index))
        refresh())
    zone_label=label_at("摇杆死区 25%",Rect2(428,114,188,18),12)
    zone=HSlider.new()
    zone.min_value=15
    zone.max_value=60
    zone.step=5
    place(zone,Rect2(430,88,182,24))
    zone.value_changed.connect(func(value: float) -> void:
        if refreshing: return
        ControlSettings.set_deadzone(value/100.0)
        zone_label.text="摇杆死区 %d%%" % value)
    status=label_at("",Rect2(24,115,392,18),12)
    for x in [24,328]:
        label_at("动作",Rect2(x,135,84,17),12)
        label_at("主按键",Rect2(x+84,135,94,17),12)
        label_at("备用按键",Rect2(x+184,135,94,17),12)
    for i in ControlSettings.ACTIONS.size():
        var action: String = ControlSettings.ACTIONS[i]
        var x := 24.0 if i<6 else 328.0
        var y := 154.0+(i%6)*24.0
        label_at(ControlSettings.LABELS[i],Rect2(x,y+3,82,18),12)
        cells[action]=[]
        for slot in 2:
            var cell := Button.new()
            place(cell,Rect2(x+84+slot*100,y,96,23))
            cell.pressed.connect(begin_capture.bind(action,slot))
            cells[action].append(cell)
    build_parent=self
    message=label_at("",Rect2(24,301,592,19),12)
    var reset := make_button("恢复默认",Rect2(24,326,112,26))
    reset.pressed.connect(func() -> void:
        capture_action=""
        if current_page==1: ControlSettings.reset_defaults()
        else:
            ControlSettings.guide_enabled=true
            ControlSettings.music_volume=0.7
        refresh()
        message.text="本页默认设置已恢复；保存后保留。")
    var cancel := make_button("取消",Rect2(366,326,98,26))
    cancel.pressed.connect(func() -> void: close_panel(false))
    var save := make_button("保存并返回",Rect2(476,326,140,26))
    save.pressed.connect(func() -> void: close_panel(true))
    ControlSettings.devices_changed.connect(_devices_changed)
    show_page(0)
    hide()

func show_page(index: int) -> void:
    if not capture_action.is_empty(): cancel_capture()
    current_page=index
    for i in pages.size():
        pages[i].visible=i==index
        tabs[i].modulate=Color.WHITE if i==index else Color("9baea2")
    message.text="音量即时预览；保存保留，取消还原。" if index==0 else "点击按键格录入 · Esc 取消录入 · Delete 清除 · F1 返回"
    tabs[index].grab_focus()

func place(control: Control, rect: Rect2) -> void:
    control.position=rect.position
    control.size=rect.size
    build_parent.add_child(control)
    control.size=rect.size # Reset the inherited fallback theme's earlier minimum size.
func label_at(value: String, rect: Rect2, size: int) -> Label:
    var label := Label.new()
    label.text=value
    label.add_theme_font_size_override("font_size",maxi(12,size))
    label.add_theme_color_override("font_color",Color("dfdfbe"))
    label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
    place(label,rect)
    return label
func make_button(value: String, rect: Rect2) -> Button:
    var button := Button.new()
    button.text=value
    place(button,rect)
    return button

func open_panel() -> void:
    if visible: return
    original=ControlSettings.snapshot()
    was_paused=level.course_paused or level.defeated or level.completed
    level.set_paused(true)
    ControlSettings.menu_open=true
    capture_action=""
    refresh()
    message.text=ControlSettings.load_notice if not ControlSettings.load_notice.is_empty() else "点按键格后按手柄键 / 拨摇杆；Esc取消录入，Delete清除。F1返回。"
    show()
    show_page(0)
func close_panel(save: bool) -> void:
    if save:
        var error: Error = ControlSettings.save_config()
        if error!=OK:
            message.text="保存失败（%d）；设置仍可编辑，请重试或取消。" % error
            return
        ControlSettings.load_notice=""
    else:
        ControlSettings.restore(original)
    capture_action=""
    hide()
    ControlSettings.menu_open=false
    ControlSettings.arm_release_gate()
    if not level.has_method("on_input_settings_closed"):
        level.equipment.suspend_input()
        level.player.clear_jump_memory()
    if not was_paused: level.set_paused(false)
    closed.emit()
func refresh() -> void:
    refreshing=true
    music_slider.value=ControlSettings.music_volume*100.0
    music_label.text="音乐音量  %d%%" % roundi(music_slider.value)
    track_label.text="正在播放\n《%s》" % MusicDirector.TITLES.get(MusicDirector.current_id,"方块远征")
    guide_button.text="向导：开启 · 新手" if ControlSettings.guide_enabled else "向导：关闭 · 熟手"
    mode_choice.select(0 if ControlSettings.mode=="keyboard" else 1)
    device_choice.clear()
    var connected := Input.get_connected_joypads()
    if connected.is_empty():
        device_choice.add_item("未连接手柄",-1)
        device_choice.disabled=true
    else:
        device_choice.disabled=false
        for id in connected:
            device_choice.add_item(ControlSettings.device_name(id),id)
            if id==ControlSettings.device: device_choice.select(device_choice.item_count-1)
    zone.value=ControlSettings.deadzone*100
    zone_label.text="摇杆死区 %d%%" % roundi(zone.value)
    status.text="键盘固定映射；下方可自定义手柄按键"
    if ControlSettings.device>=0:
        status.text="标准布局 · 点下方按键格重新映射" if Input.is_joy_known(ControlSettings.device) else "非标准布局 · 逐项按键录入，编号以实际识别为准"
    elif ControlSettings.mode=="gamepad": status.text="手柄已断开，临时使用键盘；重连后保持暂停，确认就绪再继续。"
    for action in ControlSettings.ACTIONS:
        for slot in 2:
            cells[action][slot].text=ControlSettings.binding_label(ControlSettings.bindings[action][slot])
            cells[action][slot].disabled=ControlSettings.device<0
    refreshing=false
func _devices_changed() -> void:
    if not visible: return
    capture_action=""
    refresh()
    message.text="设备连接已变化，请重新选择要设置的手柄。"
func begin_capture(action: String, slot: int) -> void:
    if ControlSettings.device<0: return
    capture_action=action
    capture_slot=slot
    capture_origins.clear()
    capture_buttons.clear()
    capture_axis_blocked.clear()
    for i in JOY_AXIS_MAX: capture_origins[i]=Input.get_joy_axis(ControlSettings.device,i)
    for i in JOY_BUTTON_MAX:
        if Input.is_joy_button_pressed(ControlSettings.device,i): capture_buttons[i]=true
    message.text="录入「%s」：松开再按新键 / 拨摇杆 · Esc取消" % ControlSettings.LABELS[ControlSettings.ACTIONS.find(action)]
    cells[action][slot].text="等待输入…"
func finish_capture(value: Dictionary) -> void:
    var result: String = ControlSettings.assign(capture_action,capture_slot,value)
    if not result.is_empty():
        if not value.is_empty():
            if value.type=="button": capture_buttons[value.index]=true
            else: capture_axis_blocked[value.index]=true
        message.text=result
        return
    var cell: Button = cells[capture_action][capture_slot]
    capture_action=""
    refresh()
    cell.grab_focus()
    message.text="映射已更新，占用的按键已自动交换；保存并返回即可保留。"

func cancel_capture() -> void:
    capture_action=""
    capture_origins.clear()
    capture_buttons.clear()
    capture_axis_blocked.clear()
    refresh()
    message.text="已取消本次录入，原按键保留。"

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11: return # Global display shortcut also works inside modals.
    if not visible: return
    # This modal consumes events before other nodes; releases must still clear menu latches.
    ControlSettings.release_event(event)
    if not capture_action.is_empty():
        # Mouse events must reach the actual GUI: never trap Cancel/Save behind capture.
        if event is InputEventMouse:
            if event is InputEventMouseButton and event.pressed: cancel_capture()
            return
        if event is InputEventKey and event.pressed and not event.echo:
            if event.keycode==KEY_F1: close_panel(false)
            elif event.keycode==KEY_ESCAPE: cancel_capture()
            elif event.keycode==KEY_DELETE: finish_capture({})
        elif event.device==ControlSettings.device:
            if event is InputEventJoypadButton:
                if not event.pressed: capture_buttons.erase(event.button_index)
                elif not capture_buttons.has(event.button_index): finish_capture(ControlSettings.button(event.button_index))
            elif event is InputEventJoypadMotion:
                if absf(event.axis_value)<0.25: capture_origins[event.axis]=0.0
                var from_rest: float = absf(event.axis_value-float(capture_origins.get(event.axis,0)))
                if from_rest<0.25: capture_axis_blocked.erase(event.axis)
                if not capture_axis_blocked.has(event.axis) and absf(event.axis_value)>=0.65 and from_rest>=0.55:
                    finish_capture(ControlSettings.axis(event.axis,1 if event.axis_value>0 else -1))
        get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_F1]:
        close_panel(false)
        get_viewport().set_input_as_handled()
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        # Mapped directions / jump navigate even non-standard pads. Ignore other devices.
        if event.device==ControlSettings.device:
            if ControlSettings.event_pressed(event,"pause",true) or ControlSettings.event_pressed(event,"settings",true):
                close_panel(false)
            elif ControlSettings.event_pressed(event,"jump",true):
                var focused := get_viewport().gui_get_focus_owner()
                if focused is Button and not focused is OptionButton: focused.pressed.emit()
                elif focused is OptionButton and not focused.disabled:
                    var index: int = (focused.selected+1)%focused.item_count
                    focused.select(index)
                    focused.item_selected.emit(index)
            else:
                for action in ["move_left","move_right","aim_up","aim_down"]:
                    if ControlSettings.event_pressed(event,action,true):
                        var key := InputEventKey.new()
                        key.keycode={"move_left":KEY_LEFT,"move_right":KEY_RIGHT,"aim_up":KEY_UP,"aim_down":KEY_DOWN}[action]
                        key.pressed=true
                        Input.parse_input_event(key)
                        key=key.duplicate()
                        key.pressed=false
                        Input.parse_input_event(key)
        get_viewport().set_input_as_handled()
