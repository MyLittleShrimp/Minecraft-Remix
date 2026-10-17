class_name MusicToggleButton
extends Button
## A mouse shortcut in the gameplay dock. Music keeps its playback position.
signal save_failed(error: Error)

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    focus_mode=Control.FOCUS_NONE # Clicking must not let Space toggle instead of jump.
    mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    for state in ["normal","hover","pressed","disabled"]:
        var style:=StyleBoxFlat.new()
        style.bg_color=Color("1d3538") if state=="normal" else Color("304941")
        if state=="pressed": style.bg_color=Color("405b4c")
        style.border_color=Color("d4b776") if state in ["hover","pressed"] else Color("405b55")
        style.set_border_width_all(1)
        style.set_content_margin_all(0)
        add_theme_stylebox_override(state,style)
    size=Vector2(24,24)
    ControlSettings.audio_changed.connect(_refresh)
    pressed.connect(_toggle)
    _refresh()

func _process(_delta: float) -> void:
    disabled=ControlSettings.menu_open or (get_parent() as Button).disabled

func _toggle() -> void:
    if ControlSettings.menu_open: return
    var error:=ControlSettings.toggle_music()
    if error!=OK: save_failed.emit(error)

func _refresh() -> void:
    var enabled:=ControlSettings.music_volume>0.0
    tooltip_text="音乐：开（%d%%）\n点击关闭背景音乐 · 保留音效" % roundi(ControlSettings.music_volume*100.0) if enabled else "音乐：关\n点击恢复音乐（%d%%）" % roundi(ControlSettings.music_restore_volume*100.0)
    queue_redraw()

func _draw() -> void:
    var enabled:=ControlSettings.music_volume>0.0
    var ink:=Color("aaf3cc") if enabled else Color("788e87")
    if disabled: ink.a=0.45
    # Pixel double-note, drawn without relying on a font's musical glyph coverage.
    draw_rect(Rect2(9,6,9,3),ink)
    draw_rect(Rect2(9,7,2,10),ink)
    draw_rect(Rect2(16,7,2,8),ink)
    draw_rect(Rect2(5,15,6,4),ink)
    draw_rect(Rect2(12,13,6,4),ink)
    if not enabled:
        for i in 14:
            draw_rect(Rect2(5+i,18-i,2,2),Color("13272c"))
            draw_rect(Rect2(5+i,19-i,2,2),Color("ee9b77") if not disabled else Color("8e756a"))
