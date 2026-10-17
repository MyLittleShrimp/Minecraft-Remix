class_name MenuStyle
extends RefCounted
const TITLE_FONT := preload("res://resources/title_font.tres")
const GOLD := Color("ddc28b")
const INK := Color("13262a")

static func lines(font: Font, text: String, width: float, size: int=12) -> PackedStringArray:
    var result:=PackedStringArray()
    for paragraph in text.split("\n"):
        var line:=""
        for letter in paragraph:
            if not line.is_empty() and font.get_string_size(line+letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:
                result.append(line)
                line=""
            line+=letter
        result.append(line)
    return result

static func theme() -> Theme:
    var result := Theme.new()
    result.default_font=load("res://resources/ui_font.tres")
    result.default_font_size=12
    for state in ["normal","hover","pressed","focus","disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color=Color("304941") if state in ["hover","focus"] else Color("192f32")
        if state=="pressed": style.bg_color=Color("3f5e4f")
        style.border_color=GOLD if state in ["focus","hover"] else Color("53695d")
        style.set_border_width_all(1)
        style.border_width_left=3 if state=="focus" else 1
        style.shadow_color=Color(0.015,0.025,0.025,0.6)
        style.shadow_size=2
        style.shadow_offset=Vector2(0,2)
        style.set_content_margin_all(4)
        for type in ["Button","OptionButton"]: result.set_stylebox(state,type,style)
    result.set_color("font_color","Button",Color("f7ebc7"))
    result.set_color("font_focus_color","Button",Color("fff4d5"))
    result.set_color("font_disabled_color","Button",Color("697c75"))
    var track:=StyleBoxFlat.new()
    track.bg_color=Color("30473f")
    track.content_margin_top=2
    track.content_margin_bottom=2
    result.set_stylebox("slider","HSlider",track)
    var fill:=track.duplicate() as StyleBoxFlat
    fill.bg_color=GOLD
    result.set_stylebox("grabber_area","HSlider",fill)
    result.set_stylebox("grabber_area_highlight","HSlider",fill)
    result.set_icon("grabber","HSlider",load("res://assets/ui/slider-grabber.svg"))
    result.set_icon("grabber_highlight","HSlider",load("res://assets/ui/slider-grabber.svg"))
    return result

static func cover(canvas: CanvasItem, texture: Texture2D, rect: Rect2, tint: Color=Color.WHITE) -> void:
    var crop:=rect.size/maxf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height())
    canvas.draw_texture_rect_region(texture,rect,Rect2((texture.get_size()-crop)*0.5,crop),tint)

static func title(parent: Control, text: String, rect: Rect2, size: int=24) -> Label:
    var node:=label(parent,text,rect,size,Color("fff0cd"))
    node.add_theme_font_override("font",TITLE_FONT)
    node.add_theme_color_override("font_shadow_color",Color("12232a"))
    node.add_theme_constant_override("shadow_offset_y",2)
    return node

static func panel(parent: Control, rect: Rect2) -> Panel:
    var node:=Panel.new()
    var style:=StyleBoxFlat.new()
    style.bg_color=INK
    style.border_color=Color("647468")
    style.set_border_width_all(1)
    style.border_width_top=2
    style.shadow_color=Color(0.01,0.02,0.03,0.45)
    style.shadow_size=4
    style.shadow_offset=Vector2(2,4)
    node.add_theme_stylebox_override("panel",style)
    node.mouse_filter=Control.MOUSE_FILTER_IGNORE
    node.position=rect.position
    node.size=rect.size
    parent.add_child(node)
    return node

static func label(parent: Control, text: String, rect: Rect2, size: int = 12, color: Color = Color("b6c3b2")) -> Label:
    var node := Label.new()
    node.text=text
    node.position=rect.position
    node.size=rect.size
    node.add_theme_font_size_override("font_size",size if size>=24 else 12)
    node.add_theme_color_override("font_color",color)
    node.mouse_filter=Control.MOUSE_FILTER_IGNORE
    parent.add_child(node)
    return node

static func button(parent: Control, text: String, rect: Rect2, callback: Callable) -> Button:
    var node := Button.new()
    node.text=text
    node.position=rect.position
    node.size=rect.size
    node.pressed.connect(callback)
    parent.add_child(node)
    node.size=rect.size
    return node

static func gamepad(event: InputEvent, owner: Control, cancel: Callable) -> bool:
    if not (event is InputEventJoypadButton or event is InputEventJoypadMotion): return false
    var settings: Node = owner.get_node("/root/ControlSettings")
    settings.release_event(event)
    if settings.event_pressed(event,"pause"):
        cancel.call()
    elif settings.event_pressed(event,"jump"):
        var focus := owner.get_viewport().gui_get_focus_owner()
        if focus is Button and focus.is_visible_in_tree() and not focus.disabled: focus.pressed.emit()
    else:
        for action in ["aim_up","aim_down","move_left","move_right"]:
            if settings.event_pressed(event,action):
                var key := InputEventKey.new()
                key.keycode={"aim_up":KEY_UP,"aim_down":KEY_DOWN,"move_left":KEY_LEFT,"move_right":KEY_RIGHT}[action]
                key.pressed=true
                Input.parse_input_event(key)
                key=key.duplicate()
                key.pressed=false
                Input.parse_input_event(key)
    # Unselected devices may not reach Godot's default ui_accept mappings.
    owner.get_viewport().set_input_as_handled()
    return true
