class_name CampaignChapterRecap
extends Control
## Chapter recap only; this screen never completes the seven-chapter campaign.
const DURATION := 5.6
const BACKGROUNDS := [preload("res://assets/art/m3-art/forest-background.png"),
    preload("res://assets/art/m4-spiderwood/moonlit-forest.png"),
    preload("res://assets/art/m4-mine/abandoned-mine.png"),
    preload("res://assets/art/m4-tide/tidal-ruins.png")]
const TITLES := ["林地遗迹", "蛛影林径", "废弃矿道", "潮汐遗迹"]
const CHAPTERS := ["穿越林间高台", "击退女巫皇后", "突破裂岩矿厅", "平息神殿潮汐"]
const GOLD := Color("e9ca88")
const INK := Color("10272e")
var level: Node
var active := false
var summary := false
var elapsed := 0.0
var buttons: Array[Button] = []
var skip_button: Button
var retry_button: Button
var notice: Label
var modal: Control
var reveal_tween: Tween
@onready var settings: Node = get_node("/root/ControlSettings")
@onready var saves: Node = get_node("/root/SaveManager")

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    size=Vector2(640,360)
    mouse_filter=Control.MOUSE_FILTER_STOP
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    theme=MenuStyle.theme()
    buttons=[MenuStyle.button(self,"返回主菜单",Rect2(32,286,184,30),leave),
        MenuStyle.button(self,"重看章节回顾",Rect2(228,286,184,30),func() -> void: begin(false)),
        MenuStyle.button(self,"重玩第四关",Rect2(424,286,184,30),request_replay),
        MenuStyle.button(self,"前往 05 / 诡异边界",Rect2(470,286,138,30),func() -> void: level.advance_level())]
    for i in buttons.size():
        buttons[i].position.x=32+i*146
        buttons[i].size.x=138
        buttons[i].add_theme_font_size_override("font_size",10)
    skip_button=MenuStyle.button(self,"查看战绩  →",Rect2(448,312,160,28),show_summary)
    retry_button=MenuStyle.button(self,"重试保存",Rect2(516,324,92,22),level.persist_checkpoint)
    retry_button.add_theme_font_size_override("font_size",10)
    notice=MenuStyle.label(self,"",Rect2(32,324,480,18),10,GOLD)
    level.input_panel.closed.connect(_settings_closed)
    reset()

func begin(restored: bool) -> void:
    assert(not CampaignCatalog.is_final_level(str(level.campaign_level_id)),"Final campaign ending needs its own victory flow")
    active=true
    summary=restored
    elapsed=DURATION if restored else 0.0
    level.get_node("UI/HUD").hide()
    level.settings_button.hide()
    level.equipment.suspend_input()
    settings.menu_open=true
    settings.arm_release_gate()
    _refresh_controls()
    show()
    if reveal_tween: reveal_tween.kill()
    modulate.a=1.0 if restored else 0.0
    if not restored:
        reveal_tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        reveal_tween.tween_property(self,"modulate:a",1.0,0.65)
    if summary: buttons[0].grab_focus()
    else: get_viewport().gui_release_focus()
    queue_redraw()

func reset() -> void:
    if reveal_tween: reveal_tween.kill()
    active=false
    summary=false
    elapsed=0
    if is_instance_valid(modal): modal.queue_free()
    modal=null
    for button in buttons: button.focus_mode=Control.FOCUS_ALL
    hide()
    if is_instance_valid(level):
        level.get_node("UI/HUD").show()
        level.settings_button.show()
    settings.menu_open=false
    settings.arm_release_gate()

func show_summary() -> void:
    if not active or elapsed<0.5: return
    summary=true
    _refresh_controls()
    buttons[0].grab_focus()
    queue_redraw()

func _refresh_controls() -> void:
    for button in buttons: button.visible=summary
    buttons[3].disabled=level.transitioning
    skip_button.visible=not summary and elapsed>=0.5
    notice.visible=summary
    retry_button.visible=summary and saves.enabled and saves.last_error!=OK
    notice.text="通关记录未保存 · 请重试；离开会回到上次存档。" if saves.last_error!=OK else ("通关记录与余额已保存 · 可从主菜单再次查看。" if saves.enabled else "当前为演示运行，未写入远征存档。")

func _process(delta: float) -> void:
    if not active: return
    visible=not level.input_panel.visible
    if not visible: return
    if not summary:
        elapsed+=delta
        if elapsed>=DURATION: show_summary()
    _refresh_controls()
    queue_redraw()

func _settings_closed() -> void:
    if not active: return
    settings.menu_open=true
    show()
    if summary: buttons[0].grab_focus()

func leave() -> void:
    if active: saves.return_to_menu.call_deferred()

func request_replay() -> void:
    if not active or not summary or is_instance_valid(modal): return
    modal=Control.new()
    modal.size=size
    add_child(modal)
    var shade:=ColorRect.new()
    shade.size=size
    shade.color=Color(0.025,0.06,0.075,0.98)
    modal.add_child(shade)
    MenuStyle.label(modal,"重新挑战潮汐遗迹？",Rect2(96,104,460,36),24,Color("fff1cf"))
    MenuStyle.label(modal,"将覆盖当前通关记录，从第四关入口重新开始。\n生命和饱食补满，绿宝石回到进入第四关时的余额。",Rect2(96,159,470,52),12)
    for button in buttons: button.focus_mode=Control.FOCUS_NONE
    var cancel:=MenuStyle.button(modal,"保留记录",Rect2(96,232,210,32),close_modal)
    MenuStyle.button(modal,"确认重玩",Rect2(330,232,210,32),func() -> void: level.restart_course())
    cancel.grab_focus()

func close_modal() -> void:
    if not is_instance_valid(modal): return
    modal.queue_free()
    modal=null
    for button in buttons: button.focus_mode=Control.FOCUS_ALL
    buttons[2].grab_focus()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11: return # Global display shortcut also works inside modals.
    if level.transitioning:
        get_viewport().set_input_as_handled()
        return
    if not active or level.input_panel.visible: return
    if event is InputEventKey and event.echo:
        get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_F11:
                ScreenLayout.toggle_fullscreen()
            KEY_F12: level.capture_frame()
            KEY_F1:
                if not is_instance_valid(modal): level.input_panel.open_panel()
            KEY_ESCAPE:
                if is_instance_valid(modal): close_modal()
                elif not summary: show_summary()
            KEY_ENTER, KEY_SPACE:
                if summary: return # Let the focused button process GUI confirmation.
                show_summary()
            KEY_R:
                if summary: request_replay()
            _:
                if summary and event.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_TAB]: return
        get_viewport().set_input_as_handled()
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        settings.release_event(event)
        if not is_instance_valid(modal) and settings.event_pressed(event,"settings"):
            level.input_panel.open_panel()
        elif not summary:
            # Consume early presses too, requiring a fresh press after the entry guard.
            if settings.event_pressed(event,"jump") or settings.event_pressed(event,"pause"): show_summary()
        else:
            MenuStyle.gamepad(event,self,close_modal)
        get_viewport().set_input_as_handled()

func _text(at: Vector2, text: String, font_size: int, color: Color=Color("eef0d9")) -> void:
    draw_string(level.ui_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _image_cover(texture: Texture2D, rect: Rect2, tint: Color=Color.WHITE) -> void:
    var source:=Rect2(Vector2.ZERO,texture.get_size())
    var scale_factor:=maxf(rect.size.x/source.size.x,rect.size.y/source.size.y)
    var crop:=rect.size/scale_factor
    source=Rect2((source.size-crop)*0.5,crop)
    draw_texture_rect_region(texture,rect,source,tint)

func _draw() -> void:
    if not active: return
    _image_cover(BACKGROUNDS[3],Rect2(0,0,640,360),Color(0.52,0.66,0.7))
    draw_rect(Rect2(0,0,640,360),Color(0.02,0.06,0.08,0.84 if summary else 0.63))
    if summary:
        _text(Vector2(32,24),"M I N E C R A F T   R E M I X",9,GOLD)
        _text(Vector2(30,60),"潮汐遗迹完成",30)
        _text(Vector2(33,79),"第五关已开放 · 带着配装穿过下界传送门",11,Color("b8d3cb"))
        RemixArt.icon(self,0,Rect2(463,26,24,34))
        _text(Vector2(494,51),str(level.wallet.available()),27,Color("a5f0c9"))
        _text(Vector2(463,79),"绿宝石余额",10,Color("b8d3cb"))
        for i in 4: _card(i,1.0,96)
        draw_rect(Rect2(32,205,576,67),INK)
        draw_line(Vector2(32,205),Vector2(608,205),Color("748d80"),1)
        _text(Vector2(46,226),"第四关战绩 · 潮汐遗迹",12,GOLD)
        _text(Vector2(46,252),"用时 %02d:%02d · 倒下 %d 次" % [int(level.play_seconds)/60,int(level.play_seconds)%60,level.deaths],12)
        _text(Vector2(266,252),"收集 %d / %d · 花费 %d" % [level.items.emeralds,level.emerald_budget(),level.wallet.spent],12)
        _text(Vector2(478,225),"生命 %d / 20"%level.health.current,10)
        _text(Vector2(478,252),"饱食 %d / 20"%ceili(level.hunger.value),10)
        _text(Vector2(32,349),"方向键 / 摇杆选择 · Enter / 跳跃键确认 · F1 设置",9,Color("94b4ae"))
    else:
        var reveal:=clampf(elapsed/0.65,0,1)
        _text(Vector2(32,43),"第四章 / 潮汐之后",12,Color(GOLD,reveal))
        _text(Vector2(30,84),"神殿重归宁静",30,Color(Color("fff1cf"),reveal))
        _text(Vector2(32,108),"潮汐已经平息。下一站：下界的诡异边界。",12,Color(Color("c6ddd1"),reveal))
        for i in 4: _card(i,clampf((elapsed-0.65-i*0.65)/0.55,0,1),147)
        for i in 18:
            var at:=Vector2(24+fmod(i*71.0,592),310-fmod(elapsed*14+i*17,260))
            draw_rect(Rect2(at,Vector2(2,2)),Color(0.65,0.95,0.86,0.18+0.16*sin(elapsed+i)))
        draw_rect(Rect2(32,289,576,2),Color("29474a"))
        draw_rect(Rect2(32,289,576*clampf(elapsed/DURATION,0,1),2),GOLD)
        _text(Vector2(32,330),"Enter / 跳跃键 / Esc 跳过",10,Color("b8d3cb"))

func _card(index: int, amount: float, y: float) -> void:
    if amount<=0: return
    var x:=32.0+index*146
    y+=10*(1-amount)
    _image_cover(BACKGROUNDS[index],Rect2(x,y,138,60),Color(1,1,1,amount))
    draw_rect(Rect2(x,y,138,60),Color(GOLD,amount*0.75),false,1)
    draw_rect(Rect2(x,y,25,16),Color(INK,amount))
    _text(Vector2(x+5,y+12),"%02d"%(index+1),9,Color(GOLD,amount))
    _text(Vector2(x,y+78),TITLES[index],13,Color(Color("eef0d9"),amount))
    _text(Vector2(x,y+93),CHAPTERS[index],9,Color(Color("99b9ae"),amount))

