extends Node
## Only pad_* actions are rebuilt. Keyboard actions and per-player test adapters stay independent.
signal changed
signal devices_changed
signal device_lost
signal audio_changed
var music_restore_volume := 0.7
var music_volume := 0.7:
    set(value):
        music_volume=clampf(value,0.0,1.0) if is_finite(value) else 0.7
        if music_volume>0.0: music_restore_volume=music_volume
        audio_changed.emit()
const ACTIONS := ["move_left","move_right","aim_up","aim_down","jump","attack","switch_weapon","ultimate","pause","retry","restart","settings"]
const LABELS := ["向左","向右","向上瞄准","向下 / 下落","跳跃","攻击 / 拉弓","切换武器","大招","暂停 / 继续","死亡后重试","整关重来","输入设置"]
const KEYS := {"jump":"空格","attack":"J","switch_weapon":"K","ultimate":"L","pause":"Esc","retry":"Enter","restart":"R","settings":"F1"}
var mode := "keyboard"
var device := -1
var preferred_guid := ""
var deadzone := 0.25
var bindings: Dictionary = defaults()
var menu_open := false
signal guide_changed
var guide_enabled := true:
    set(value):
        if guide_enabled==value: return
        guide_enabled=value
        guide_changed.emit()
var release_gate := false
var neutral_frames := 0
var load_notice := ""
var event_latches: Dictionary = {}
var config_path := "user://input_settings.cfg"

func defaults() -> Dictionary:
    return {"move_left":[axis(0,-1),button(13)],"move_right":[axis(0,1),button(14)],
        "aim_up":[axis(1,-1),button(11)],"aim_down":[axis(1,1),button(12)],
        "jump":[button(0),{}],"attack":[button(2),axis(5,1)],"switch_weapon":[button(9),{}],
        "ultimate":[button(10),{}],"pause":[button(6),{}],"retry":[button(1),{}],
        "restart":[button(3),{}],"settings":[button(4),{}]}
func button(index: int) -> Dictionary: return {"type":"button","index":index}
func axis(index: int, direction: int) -> Dictionary: return {"type":"axis","index":index,"sign":direction}

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    process_physics_priority=-1000
    var override := OS.get_environment("REMIX_CONTROLS_PATH")
    if not override.is_empty(): config_path=override
    load_config()
    select_initial_device()
    Input.joy_connection_changed.connect(_connection_changed)
    rebuild()

func select_initial_device() -> void:
    device=-1
    for candidate in Input.get_connected_joypads():
        if device<0: device=candidate
        if Input.get_joy_guid(candidate)==preferred_guid:
            device=candidate
            break
    if device>=0: preferred_guid=Input.get_joy_guid(device)

func _connection_changed(id: int, connected: bool) -> void:
    # A stale or synthetic notification may not have an Input device record.
    var guid:=Input.get_joy_guid(id) if connected and id in Input.get_connected_joypads() else ""
    if not connected and id==device:
        device=-1
        rebuild()
        if mode=="gamepad": device_lost.emit()
    elif connected and device<0 and (preferred_guid.is_empty() or guid==preferred_guid):
        device=id
        preferred_guid=guid
        rebuild()
    devices_changed.emit()

func gamepad_active() -> bool: return mode=="gamepad" and device>=0
func action_name(action: String) -> String: return "pad_"+action if gamepad_active() else action
func choose_mode(value: String) -> void:
    if value not in ["keyboard","gamepad"]: return
    mode=value
    rebuild()
func choose_device(id: int) -> void:
    if id not in Input.get_connected_joypads(): return
    device=id
    preferred_guid=Input.get_joy_guid(id)
    rebuild()
func set_deadzone(value: float) -> void:
    deadzone=clampf(value,0.15,0.60)
    rebuild()
func snapshot() -> Dictionary:
    return {"mode":mode,"guid":preferred_guid,"deadzone":deadzone,"bindings":bindings.duplicate(true),"device":device,"guide_enabled":guide_enabled,"music_volume":music_volume,"music_restore_volume":music_restore_volume}
func restore(state: Dictionary) -> void:
    music_restore_volume=float(state.get("music_restore_volume",0.7))
    music_volume=float(state.get("music_volume",0.7))
    guide_enabled=state.get("guide_enabled",true)
    mode=state.mode
    preferred_guid=state.guid
    deadzone=state.deadzone
    bindings=state.bindings.duplicate(true)
    device=state.device if state.device in Input.get_connected_joypads() else -1
    rebuild()
func reset_defaults() -> void:
    bindings=defaults()
    deadzone=0.25
    rebuild()

func valid_binding(value: Variant) -> bool:
    if not value is Dictionary: return false
    if value.is_empty(): return true
    if not value.get("index") is int: return false
    if value.get("type")=="button": return value.index>=0 and value.index<JOY_BUTTON_MAX
    if value.get("type")=="axis": return value.index>=0 and value.index<JOY_AXIS_MAX and value.get("sign") in [-1,1]
    return false
func binding_key(value: Dictionary) -> String:
    return "" if value.is_empty() else "%s:%d:%d" % [value.type,value.index,value.get("sign",0)]
func validate_bindings(value: Variant) -> bool:
    if not value is Dictionary or value.size()!=ACTIONS.size(): return false
    var seen: Dictionary = {}
    for action in ACTIONS:
        var slots: Variant = value.get(action)
        if not slots is Array or slots.size()!=2: return false
        if not valid_binding(slots[0]) or not valid_binding(slots[1]): return false
        if slots[0].is_empty() and slots[1].is_empty(): return false
        for binding in slots:
            var key := binding_key(binding)
            if key.is_empty(): continue
            if seen.has(key): return false
            seen[key]=true
    return true
func assign(action: String, slot: int, value: Dictionary, swap_conflict: bool = true) -> String:
    if action not in ACTIONS or slot not in [0,1] or not valid_binding(value): return "不支持这个输入"
    if value.is_empty() and bindings[action][1-slot].is_empty(): return "每个动作至少保留一个按键"
    var key := binding_key(value)
    var updated: Dictionary = bindings.duplicate(true)
    if not key.is_empty():
        for other in ACTIONS:
            for i in 2:
                if other==action and i==slot: continue
                if key==binding_key(bindings[other][i]):
                    if not swap_conflict: return "已用于「%s」" % LABELS[ACTIONS.find(other)]
                    var replacement: Dictionary = bindings[action][slot].duplicate()
                    # An empty alternate has nothing to trade. If the other action would
                    # lose its only key, trade our existing key instead, in one transaction.
                    if other!=action and replacement.is_empty() and bindings[other][1-i].is_empty():
                        replacement=bindings[action][1-slot].duplicate()
                        updated[action][1-slot]={}
                    updated[other][i]=replacement
    updated[action][slot]=value.duplicate()
    if not validate_bindings(updated): return "此映射无效，原按键已保留。"
    bindings=updated
    rebuild()
    return ""

func rebuild() -> void:
    event_latches.clear()
    for action in ACTIONS:
        var name: String = "pad_"+action
        if not InputMap.has_action(name): InputMap.add_action(name)
        Input.action_release(name)
        InputMap.action_erase_events(name)
        InputMap.action_set_deadzone(name,deadzone)
        if device<0: continue
        for binding in bindings[action]:
            if binding.is_empty(): continue
            var event: InputEvent
            if binding.type=="button":
                var key := InputEventJoypadButton.new()
                key.button_index=binding.index
                event=key
            else:
                var motion := InputEventJoypadMotion.new()
                motion.axis=binding.index
                motion.axis_value=binding.sign
                event=motion
            event.device=device
            InputMap.action_add_event(name,event)
    arm_release_gate()
    changed.emit()
func arm_release_gate() -> void:
    release_gate=true
    neutral_frames=0
func _physics_process(_delta: float) -> void:
    if not release_gate or menu_open: return
    var neutral := true
    for action in ACTIONS:
        if not gamepad_active() and InputMap.has_action(action) and Input.is_action_pressed(action): neutral=false
        if gamepad_active():
            for binding in bindings[action]:
                if binding.is_empty(): continue
                if binding.type=="button" and Input.is_joy_button_pressed(device,binding.index): neutral=false
                if binding.type=="axis" and Input.get_joy_axis(device,binding.index)*binding.sign>deadzone: neutral=false
    neutral_frames=neutral_frames+1 if neutral else 0
    if neutral_frames>=2: release_gate=false
func gameplay_blocked() -> bool: return menu_open or release_gate
func _input(event: InputEvent) -> void:
    release_event(event)
func release_event(event: InputEvent) -> void:
    if event.device!=device: return
    for action in ACTIONS:
        for binding in bindings[action]:
            if binding.is_empty(): continue
            if event is InputEventJoypadButton and binding.type=="button" and event.button_index==binding.index and not event.pressed:
                event_latches[action]=false
            # A zero axis value has no sign, so exact-match action release cannot
            # reliably match a negative-direction binding when the stick centers.
            if event is InputEventJoypadMotion and binding.type=="axis" and event.axis==binding.index and event.axis_value*binding.sign<=deadzone:
                event_latches[action]=false
func event_pressed(event: InputEvent, action: String, allow_inactive: bool = false) -> bool:
    if (not allow_inactive and not gamepad_active()) or device<0 or event.device!=device: return false
    if not event.is_action_pressed("pad_"+action,false,true) or event_latches.get(action,false): return false
    event_latches[action]=true
    return true

func toggle_music() -> Error:
    var previous_volume:=music_volume
    var previous_restore:=music_restore_volume
    music_volume=0.0 if music_volume>0.0 else music_restore_volume
    var error:=save_config()
    if error!=OK:
        music_restore_volume=previous_restore
        music_volume=previous_volume
    return error

func save_config() -> Error:
    var cfg := ConfigFile.new()
    cfg.set_value("controls","version",1)
    cfg.set_value("controls","mode",mode)
    cfg.set_value("controls","guid",preferred_guid)
    cfg.set_value("controls","deadzone",deadzone)
    cfg.set_value("controls","bindings",bindings)
    cfg.set_value("interface","guide_enabled",guide_enabled)
    cfg.set_value("audio","music_volume",music_volume)
    cfg.set_value("audio","music_restore_volume",music_restore_volume)
    var error := cfg.save(config_path+".tmp")
    if error!=OK: return error
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(config_path+".tmp"),ProjectSettings.globalize_path(config_path))
func load_config() -> void:
    var cfg := ConfigFile.new()
    var error := cfg.load(config_path)
    if error==ERR_FILE_NOT_FOUND: return
    if error!=OK:
        load_notice="设置文件无效，已使用默认按键；保存后可修复。"
        return
    var saved_mode: Variant = cfg.get_value("controls","mode","")
    var saved_zone: Variant = cfg.get_value("controls","deadzone",-1)
    var saved_bindings: Variant = cfg.get_value("controls","bindings",{})
    if error!=OK or cfg.get_value("controls","version",0)!=1 or saved_mode not in ["keyboard","gamepad"] or not (saved_zone is float or saved_zone is int) or not is_finite(float(saved_zone)) or float(saved_zone)<0.15 or float(saved_zone)>0.6 or not validate_bindings(saved_bindings):
        load_notice="设置文件无效，已使用默认按键；保存后可修复。"
        return
    mode=saved_mode
    deadzone=float(saved_zone)
    bindings=saved_bindings.duplicate(true)
    preferred_guid=str(cfg.get_value("controls","guid",""))
    var guide: Variant=cfg.get_value("interface","guide_enabled",true)
    guide_enabled=guide if guide is bool else true
    var volume: Variant=cfg.get_value("audio","music_volume",0.7)
    var resume_volume: Variant=cfg.get_value("audio","music_restore_volume",0.7)
    music_restore_volume=clampf(float(resume_volume),0.01,1.0) if (resume_volume is float or resume_volume is int) and is_finite(float(resume_volume)) and float(resume_volume)>0.0 else 0.7
    music_volume=float(volume) if (volume is float or volume is int) else 0.7

func device_name(id: int) -> String:
    var value := Input.get_joy_name(id)
    # Some legacy Windows drivers return mojibake before the readable product name.
    if value.contains("BETOP"): value=value.substr(value.find("BETOP"))
    return value
func binding_label(binding: Dictionary) -> String:
    if binding.is_empty(): return "＋ 添加"
    var known := device>=0 and Input.is_joy_known(device)
    if binding.type=="axis":
        if known:
            if binding.index==0: return "左摇杆←" if binding.sign<0 else "左摇杆→"
            if binding.index==1: return "左摇杆↑" if binding.sign<0 else "左摇杆↓"
            if binding.index==4 and binding.sign>0: return "LT / L2"
            if binding.index==5 and binding.sign>0: return "RT / R2"
        return "轴%d %s" % [binding.index+1,"−" if binding.sign<0 else "+"]
    var names := {0:"A / ×",1:"B / ○",2:"X / □",3:"Y / △",4:"View",6:"Start",7:"L3",8:"R3",9:"LB / L1",10:"RB / R1",11:"十字↑",12:"十字↓",13:"十字←",14:"十字→"}
    return names.get(binding.index,"键%d" % (binding.index+1)) if known else "按钮%d" % (binding.index+1)
func hint(action: String) -> String:
    if not gamepad_active(): return KEYS.get(action,action)
    var binding: Dictionary = bindings[action][0] if not bindings[action][0].is_empty() else bindings[action][1]
    return binding_label(binding)

func compact_hint(action: String) -> String:
    # Only presentation changes; the settings table retains both platform names.
    var text:=hint(action)
    if text=="＋ 添加": return "未设"
    return text.replace("按钮","键").replace(" / ","/").get_slice("/",0).replace("左摇杆","杆").replace(" ","")
