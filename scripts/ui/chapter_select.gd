class_name ChapterSelect
extends Control
signal closed
signal chosen(id: String, standalone: bool)
const ART := [
    preload("res://assets/art/m3-art/forest-background.png"),
    preload("res://assets/art/m4-spiderwood/moonlit-forest.png"),
    preload("res://assets/art/m4-mine/abandoned-mine.png"),
    preload("res://assets/art/m4-tide/tidal-ruins.png"),
    preload("res://assets/art/m4-warped/warped-forest.png"),
    preload("res://assets/art/m4-warped/ash-citadel.png"),
    preload("res://assets/art/m4-portal/end.png")]
const DESCRIPTIONS := [
    "穿越断桥与林间高台，寻找遗迹深处的守军。",
    "月下蛛影与毒雾交织，女巫皇后等在庭院。",
    "运送炸药、穿越吊台，迎战裂岩劫掠兽。",
    "踏过潮汐遗迹，以雷霆挑战远古守卫者。",
    "跨过菌林裂隙，在恶魂与烈焰中夺回珍珠。",
    "突破猪灵守军，接通灵魂封印，唤醒凋灵。",
    "重访六境、合成三眼，拆除水晶并击败末影龙。"]
const BOSSES := ["骷髅队长","女巫皇后","裂岩劫掠兽","远古守卫者","裂隙守望者","凋灵","末影龙"]
var selected := 0
var chapter_buttons: Array[Button]=[]
var preview: TextureRect
var heading: Label
var description: Label
var boss_label: Label
var budget: Label
var single_button: Button
var campaign_button: Button
var back_button: Button
var confirmation: Control

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_STOP
    theme=MenuStyle.theme()
    var shade:=ColorRect.new()
    shade.color=Color("0b1c23")
    shade.size=Vector2(640,360)
    shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    MenuStyle.title(self,"选择章节",Rect2(30,19,220,34))
    MenuStyle.label(self,"七段旅程 · 自由选择你的起点",Rect2(31,55,450,20),11)
    back_button=MenuStyle.button(self,"返回",Rect2(528,27,80,28),close)
    for i in 7:
        var entry: String=CampaignCatalog.LEVELS.keys()[i]
        var button:=MenuStyle.button(self,CampaignCatalog.title(entry),Rect2(30,88+i*33,204,28),select_chapter.bind(i))
        button.alignment=HORIZONTAL_ALIGNMENT_LEFT
        button.add_theme_font_size_override("font_size",12)
        button.focus_entered.connect(select_chapter.bind(i))
        chapter_buttons.append(button)
    MenuStyle.panel(self,Rect2(250,88,358,235))
    preview=TextureRect.new()
    preview.position=Vector2(253,91)
    preview.size=Vector2(352,105)
    preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(preview)
    heading=MenuStyle.title(self,"",Rect2(265,204,332,24),12)
    description=MenuStyle.label(self,"",Rect2(265,230,329,33),10)
    description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    boss_label=MenuStyle.label(self,"",Rect2(265,260,329,20),10,MenuStyle.GOLD)
    budget=MenuStyle.label(self,"",Rect2(265,283,329,32),9)
    MenuStyle.label(self,"单关不影响存档；远征模式从所选章继续到终章。",Rect2(30,327,575,22),10)
    # Action buttons live over the bottom of the preview, keeping both modes visible.
    single_button=MenuStyle.button(self,"单关游玩",Rect2(270,156,151,30),request_start.bind(true))
    campaign_button=MenuStyle.button(self,"从本关开始远征",Rect2(433,156,151,30),request_start.bind(false))
    var last: int=CampaignCatalog.LEVELS.keys().find(get_node("/root/SaveManager").selected_chapter)
    select_chapter(maxi(last,0))
    chapter_buttons[selected].grab_focus()
    for button in chapter_buttons:
        button.focus_neighbor_right=single_button.get_path()
    single_button.focus_neighbor_left=chapter_buttons[selected].get_path()
    single_button.focus_neighbor_right=campaign_button.get_path()
    campaign_button.focus_neighbor_left=single_button.get_path()

func select_chapter(index: int) -> void:
    selected=index
    if preview==null: return
    preview.texture=ART[index]
    heading.text=CampaignCatalog.title(CampaignCatalog.LEVELS.keys()[index])
    description.text=DESCRIPTIONS[index]
    boss_label.text="关底首领  /  "+BOSSES[index]
    budget.text="满生命 / 满饱食 / 0 宝石 · 本章武器可选\n"+("自带通关所需剧情材料" if index>=5 else "沿途收集绿宝石，用于释放武器大招")
    for i in chapter_buttons.size():
        chapter_buttons[i].add_theme_color_override("font_color",MenuStyle.GOLD if i==selected else Color("a5b7ae"))
    if single_button!=null: single_button.focus_neighbor_left=chapter_buttons[selected].get_path()

func request_start(standalone: bool) -> void:
    if is_instance_valid(confirmation): return
    if standalone or not get_node("/root/SaveManager").any_file():
        chosen.emit(CampaignCatalog.LEVELS.keys()[selected],standalone)
        return
    confirmation=Control.new()
    confirmation.size=Vector2(640,360)
    confirmation.mouse_filter=Control.MOUSE_FILTER_STOP
    add_child(confirmation)
    for button in chapter_buttons+[single_button,campaign_button,back_button]: button.focus_mode=Control.FOCUS_NONE
    var shade:=ColorRect.new()
    shade.color=Color(0.02,0.04,0.05,0.93)
    shade.size=Vector2(640,360)
    shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    confirmation.add_child(shade)
    MenuStyle.panel(confirmation,Rect2(112,94,416,168))
    MenuStyle.title(confirmation,"开始新的远征？",Rect2(135,111,370,30),24)
    MenuStyle.label(confirmation,CampaignCatalog.title(CampaignCatalog.LEVELS.keys()[selected])+"\n这会替换现有远征进度。只想重玩本关，请选择单关游玩。",Rect2(135,153,368,58),11)
    var cancel:=MenuStyle.button(confirmation,"保留存档",Rect2(135,218,166,28),dismiss_confirmation)
    MenuStyle.button(confirmation,"确认开始",Rect2(313,218,192,28),func() -> void: chosen.emit(CampaignCatalog.LEVELS.keys()[selected],false))
    cancel.grab_focus()

func dismiss_confirmation() -> void:
    if not is_instance_valid(confirmation): return
    confirmation.queue_free()
    confirmation=null
    for button in chapter_buttons+[single_button,campaign_button,back_button]: button.focus_mode=Control.FOCUS_ALL
    campaign_button.grab_focus()

func close() -> void:
    if is_instance_valid(confirmation): dismiss_confirmation()
    else: closed.emit()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11: return # Global display shortcut also works inside modals.
    if not is_visible_in_tree(): return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
        close()
        get_viewport().set_input_as_handled()
    MenuStyle.gamepad(event,self,close)
