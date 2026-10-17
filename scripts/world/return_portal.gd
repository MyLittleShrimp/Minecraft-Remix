extends Node2D
var level: Node
var elapsed := 0.0
func _ready() -> void: hide()
func _process(delta: float) -> void:
    if not visible: return
    elapsed+=delta
    queue_redraw()
func _draw() -> void:
    for i in 8:
        var a:=i*TAU/8
        draw_rect(Rect2(Vector2(cos(a)*34-6,sin(a)*10-5),Vector2(12,8)),Color("555b61"))
    draw_set_transform(Vector2(0,-14),0,Vector2(1,0.3))
    draw_circle(Vector2.ZERO,28,Color("191d35"))
    for r in [12,20,27]: draw_arc(Vector2.ZERO,r,elapsed,elapsed+TAU*0.86,32,Color("83e6d7"),2)
    draw_set_transform(Vector2.ZERO)
    for i in 16:
        var y: float=fmod(elapsed*18+i*11,66)
        draw_rect(Rect2(sin(i*7+elapsed)*24,-12-y,2,2),Color(0.6,1,0.88,1-y/80))
    draw_rect(Rect2(-94,-112,188,30),Color("132b30"))
    var hint: String=level.get_node("/root/ControlSettings").hint("aim_up") if level.get_node("/root/ControlSettings").gamepad_active() else "E"
    draw_string(level.ui_font,Vector2(-78,-93),hint+" 返回主世界 · 完成远征",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ecdfba"))
