extends Control
const VICTORY := preload("res://assets/art/m4z4-theme/homecoming.png")
const TITLES := ["林地遗迹","蛛影林径","废弃矿道","潮汐遗迹","诡异边界","堡垒核心","巨龙之巢"]
const ART := [preload("res://assets/art/m3-art/forest-background.png"),preload("res://assets/art/m4-spiderwood/moonlit-forest.png"),
    preload("res://assets/art/m4-mine/abandoned-mine.png"),preload("res://assets/art/m4-tide/tidal-ruins.png"),
    preload("res://assets/art/m4-warped/warped-forest.png"),preload("res://assets/art/m4-warped/ash-citadel.png"),preload("res://assets/art/m4-portal/end.png")]
var level: Node
var elapsed := 0.0
var summary := false
var home: Button
var replay: Button
var skip: Button
func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    size=Vector2(640,360)
    theme=MenuStyle.theme()
    mouse_filter=Control.MOUSE_FILTER_STOP
    home=MenuStyle.button(self,"返回章节选择" if level.saves.single_chapter else "返回主菜单",Rect2(94,306,214,28),func() -> void: level.saves.return_to_menu.call_deferred())
    replay=MenuStyle.button(self,"重看庆典",Rect2(332,306,214,28),func() -> void: begin(false))
    skip=MenuStyle.button(self,"查看战绩 →",Rect2(450,302,158,28),show_summary)
    level.input_panel.closed.connect(func() -> void:
        level.get_node("/root/ControlSettings").menu_open=true
        if summary: home.grab_focus())
func begin(restored: bool) -> void:
    level.get_node("/root/MusicDirector").play_track("victory")
    elapsed=8.0 if restored else 0.0
    summary=restored
    level.get_node("UI/HUD").hide()
    level.settings_button.hide()
    level.get_node("UI").move_child(level.input_panel,-1)
    level.get_node("/root/ControlSettings").menu_open=true
    level.get_node("/root/ControlSettings").arm_release_gate()
    home.visible=summary
    replay.visible=summary
    skip.visible=false
    if summary: home.grab_focus()
    else: get_viewport().gui_release_focus()
    queue_redraw()
func show_summary() -> void:
    if elapsed<0.5: return
    summary=true
    home.show()
    replay.show()
    skip.hide()
    home.grab_focus()
    queue_redraw()
func _process(delta: float) -> void:
    visible=not level.input_panel.visible
    if not visible: return
    elapsed+=delta
    if not summary and elapsed>=8.0: show_summary()
    skip.visible=not summary and elapsed>=0.5
    queue_redraw()
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11: return # Global display shortcut also works inside modals.
    if not visible: return
    var settings: Node=level.get_node("/root/ControlSettings")
    if event is InputEventKey and event.pressed:
        if event.echo:
            get_viewport().set_input_as_handled()
            return
        match event.keycode:
            KEY_F1: level.input_panel.open_panel()
            KEY_F11: ScreenLayout.toggle_fullscreen()
            KEY_ESCAPE: show_summary()
            KEY_ENTER,KEY_SPACE:
                if summary: return
                show_summary()
            KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_TAB:
                if summary: return
        get_viewport().set_input_as_handled()
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        settings.release_event(event)
        if settings.event_pressed(event,"settings"): level.input_panel.open_panel()
        elif summary: MenuStyle.gamepad(event,self,func() -> void: pass)
        elif settings.event_pressed(event,"jump") or settings.event_pressed(event,"pause"): show_summary()
        get_viewport().set_input_as_handled()
func text(at: Vector2,value: String,size_px: int=12,color: Color=Color("f2e8ce")) -> void:
    draw_string(level.ui_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,24 if size_px>=18 else 12,color)
func cover(texture: Texture2D,rect: Rect2,tint: Color=Color.WHITE) -> void:
    var crop:=rect.size/maxf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height())
    draw_texture_rect_region(texture,rect,Rect2((texture.get_size()-crop)*0.5,crop),tint)
func _draw() -> void:
    var full:=ScreenLayout.full_rect()
    var blend:=clampf(elapsed/1.8,0,1)
    cover(ART[6],full)
    cover(VICTORY,full,Color(1,1,1,blend))
    for i in 20:
        draw_rect(Rect2(full.position.x,full.position.y+i*5,full.size.x,5),Color(0.02,0.055,0.06,maxf(0,0.85-i*0.043)))
    fireworks(blend)
    var headline:="远征完成，欢迎回家" if summary else "巨龙陨落 · 远征胜利"
    var title_width: float=level.ui_font.get_string_size(headline,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
    draw_string_outline(level.ui_font,Vector2((640-title_width)*0.5,42),headline,HORIZONTAL_ALIGNMENT_LEFT,-1,24,3,Color("142c2d"))
    text(Vector2((640-title_width)*0.5,42),headline,24,Color("fff0b6"))
    text(Vector2(146,66),"七个世界的冒险，终于迎来归家的晨光。",12,Color("f1ecd3"))
    var reveal:=1.0 if summary else clampf((elapsed-3.5)/1.0,0,1)
    if reveal>0:
        for i in 7:
            var alpha:=reveal if summary else clampf((elapsed-3.5-i*0.25)/0.7,0,1)
            var x:=30+i*84.0
            draw_rect(Rect2(x-2,89,80,67),Color(0.035,0.09,0.10,0.83*alpha))
            cover(ART[i],Rect2(x,91,76,43),Color(1,1,1,alpha))
            draw_rect(Rect2(x,91,76,43),Color(0.9,0.8,0.56,alpha),false,1)
            text(Vector2(x+3,105),"%02d"%(i+1),12,Color(1,0.94,0.7,alpha))
            text(Vector2(x+2,150),TITLES[i],12,Color(0.97,0.96,0.84,alpha))
    if summary:
        draw_rect(Rect2(30,252,580,45),Color(0.035,0.095,0.10,0.93))
        draw_line(Vector2(30,252),Vector2(610,252),Color("d4b776"),1)
        var seconds:=int(level.finale.elapsed_before+level.play_seconds)
        text(Vector2(44,270),"终章战绩 · 用时 %02d:%02d · 倒下 %d 次"%[seconds/60,seconds%60,level.finale.deaths_before+level.deaths],12,Color("e5c88b"))
        text(Vector2(44,289),"绿宝石 %d   生命 %d/20   饱食 %d/20"%[level.wallet.available(),level.health.current,ceili(level.hunger.value)],12)
        draw_rect(Rect2(full.position.x,336,full.size.x,full.end.y-336),Color(0.02,0.055,0.065,0.88))
        text(Vector2(32,351),"单关挑战完成 · 原远征存档保留 · F1 设置" if level.saves.single_chapter else "通关记录已保存 · 继续远征可重看结局 · F1 设置",12,Color("c0d4bc"))
    else:
        draw_rect(Rect2(28,304,313,25),Color(0.03,0.08,0.09,0.8))
        text(Vector2(38,321),"Enter / 跳跃键 / Esc 查看战绩",12,Color("ece3bc"))

func fireworks(alpha: float) -> void:
    # Lightweight deterministic pixel sparks: no per-frame node creation,
    # no flashing full-screen overlay, and no interference with result buttons.
    for burst in 5:
        var t:=fposmod(elapsed*0.52+burst*0.71,2.5)
        if t>1.3: continue
        var center:=Vector2(50+burst*133,85+((burst*37)%70))
        var color:=Color("a4f0bf") if burst%2 else Color("f9d78d")
        color.a=alpha*(1-t/1.3)*0.8
        for ray in 12:
            var angle:=ray*TAU/12.0+burst
            var at:=center+Vector2(cos(angle),sin(angle))*t*48+Vector2(0,t*t*11)
            draw_rect(Rect2(at.round(),Vector2(2,2)),color)
    for i in 30:
        var at:=Vector2(fposmod(i*71.0+sin(elapsed+i)*6,640),fposmod(i*37.0+elapsed*9,290))
        draw_rect(Rect2(at.round(),Vector2(1+(i%2),2)),Color(0.8,0.95,0.62,alpha*0.36))
