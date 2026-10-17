class_name LoadoutPanel
extends Control
var level: Node
var draft: Array[String] = []
var slots: Array[Button] = []
var selected := 1
var summary: Label
var apply_button: Button
var tutorial: Label
var was_paused := false

var weapon_buttons: Dictionary = {}
var slot_icons: Array[TextureRect] = []
var slot_names: Array[Label] = []
var card_tags: Dictionary = {}
var detail_title: Label
var detail_icon: TextureRect
var preview_id := ""
const ROLES := {"netherite_sword":"近战 · 连斩", "bow":"远程 · 蓄力", "crossbow":"远程 · 双发", "axe":"近战 · 破绽", "trident":"近远 · 回收"}

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_STOP
    theme=MenuStyle.theme()
    var shade:=ColorRect.new()
    shade.color=Color("10252b")
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    MenuStyle.title(self,"行军武器架",Rect2(24,12,430,32),24)
    text_at(self,"先选槽位，再选武器 · 重复装备自动交换",Rect2(24,48,592,20),12)
    for i in 2:
        var button:=MenuStyle.button(self,"",Rect2(24+i*302,77,290,44),select_slot.bind(i))
        slots.append(button)
        slot_icons.append(WeaponPortraits.picture(button,"bow",Rect2(10,3,38,38)))
        slot_names.append(text_at(button,"",Rect2(57,13,225,20),12,Color("fff0cd")))
    var ids := CampaignCatalog.weapon_ids(str(level.campaign_level_id))
    var width := 120.0
    var start := 320.0-(ids.size()*width-8.0)*0.5
    for i in ids.size():
        var id: String=ids[i]
        var data: WeaponData = load("res://resources/weapons/%s.tres" % id)
        var button:=MenuStyle.button(self,"",Rect2(start+i*width,136,112,101),choose.bind(id))
        weapon_buttons[id]=button
        button.tooltip_text=data.label+" · "+ROLES[id]
        button.focus_entered.connect(show_weapon.bind(id))
        button.mouse_entered.connect(show_weapon.bind(id))
        WeaponPortraits.picture(button,id,Rect2(30,8,52,52))
        var name_label:=text_at(button,data.label,Rect2(4,64,104,17),12,Color("fff0cd"))
        name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        var tag:=text_at(button,ROLES[id],Rect2(4,83,104,17),12)
        tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        card_tags[id]=tag
    MenuStyle.panel(self,Rect2(24,247,592,63))
    detail_icon=WeaponPortraits.picture(self,"bow",Rect2(31,255,45,45))
    detail_title=text_at(self,"",Rect2(86,251,521,18),12,MenuStyle.GOLD)
    tutorial=text_at(self,"",Rect2(86,271,521,36),12)
    summary=text_at(self,"",Rect2(24,327,305,23),12)
    MenuStyle.button(self,"取消 / Esc",Rect2(344,324,112,28),close_panel)
    apply_button=MenuStyle.button(self,"应用并返回",Rect2(468,324,148,28),apply)
    hide()

func text_at(parent: Control, text: String, rect: Rect2, size: int=12, color: Color=Color("b6c3b2")) -> Label:
    var node:=MenuStyle.label(parent,text,rect,size,color)
    node.size=rect.size
    return node

func show_weapon(id: String) -> void:
    if tutorial==null: return
    preview_id=id
    var data: WeaponData=load("res://resources/weapons/%s.tres" % id)
    var power:=data.ultimate
    detail_icon.texture=WeaponPortraits.texture(id)
    detail_title.text=data.label+"  /  "+ROLES[id]
    var attack: String
    var ability: String
    match id:
        "netherite_sword":
            attack="%s 连续挥砍 %d · 跳劈 %d 伤害" % [ControlSettings.hint("attack"),data.damage,data.damage+data.airborne_damage_bonus]
            ability="巨剑暴击 · %.0f秒伤害×%.0f，攻击距离增加" % [power.duration,power.damage_multiplier]
        "bow":
            attack="%s 轻射 %d · 蓄满 %.2f秒造成 %d 伤害" % [ControlSettings.hint("attack"),data.damage,data.charge_seconds,data.charged_damage]
            ability="五箭齐射 · 同时射出 %d 支箭" % power.arrow_count
        "crossbow":
            attack="%s 装填 %.2f秒存两发 · 松开再按，每发 %d" % [ControlSettings.hint("attack"),data.charge_seconds,data.damage]
            ability="穿云重矢 · %d伤害，最多贯穿 %d 名敌人" % [power.arrow_damage,power.pierce_targets]
        "axe":
            attack="%s 重击 %d · 敌人收招时追击 +%d · 一斧破木板" % [ControlSettings.hint("attack"),data.damage,data.recovery_bonus]
            ability="裂地重劈 · 前方 %d伤害，起手可被打断" % power.melee_damage
        "trident":
            attack="%s 短按松手突刺 %d · 蓄投 %d，自动回收" % [ControlSettings.hint("attack"),data.damage,data.charged_damage]
            ability="天降雷霆 · 索敌至多 %d目标，落雷附带范围伤害" % power.lightning_targets
    tutorial.text=attack+"\n%s %s · %d宝石" % [ControlSettings.hint("ultimate"),ability,power.emerald_cost]

func open_panel() -> void:
    if visible or not level.can_use_armory(): return
    was_paused=level.course_paused
    draft=level.equipment.loadout_ids()
    selected=1
    level.set_paused(true)
    level.settings_button.disabled=true
    ControlSettings.menu_open=true
    refresh()
    show()
    slots[selected].grab_focus()

func select_slot(index: int) -> void:
    selected=index
    refresh()

func choose(id: String) -> void:
    if id not in CampaignCatalog.weapon_ids(str(level.campaign_level_id)): return
    var other:=1-selected
    if draft[other]==id: draft[other]=draft[selected]
    draft[selected]=id
    refresh()

func refresh() -> void:
    for i in 2:
        var data: WeaponData=load("res://resources/weapons/%s.tres" % draft[i])
        slot_names[i].text="%s 槽位%d · %s" % ["▶" if i==selected else "",i+1,data.label]
        slot_icons[i].texture=WeaponPortraits.texture(draft[i])
        slots[i].modulate=Color.WHITE if i==selected else Color("8daba4")
    for id in card_tags:
        var slot:=draft.find(id)
        card_tags[id].text="已装备 · 槽位%d" % (slot+1) if slot>=0 else ROLES[id]
        card_tags[id].modulate=MenuStyle.GOLD if slot>=0 else Color.WHITE
    summary.text="%s 切换武器 · 配装单独保存" % ControlSettings.hint("switch_weapon")
    show_weapon(draft[selected])

func apply() -> void:
    level.apply_loadout(draft)
    close_panel()

func close_panel() -> void:
    if not visible: return
    hide()
    level.settings_button.disabled=false
    ControlSettings.menu_open=false
    ControlSettings.arm_release_gate()
    level.equipment.suspend_input()
    level.player.clear_jump_memory()
    if not was_paused: level.set_paused(false)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11: return # Global display shortcut also works inside modals.
    if not visible: return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode in [KEY_ESCAPE,KEY_F1]:
            close_panel()
            get_viewport().set_input_as_handled()
        elif event.keycode in [KEY_R,KEY_Q,KEY_M,KEY_E,KEY_J,KEY_K,KEY_L]:
            get_viewport().set_input_as_handled()
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        MenuStyle.gamepad(event,self,close_panel)
