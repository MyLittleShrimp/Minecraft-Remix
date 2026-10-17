extends "res://scripts/world/movement_course.gd"
var entrance: StageGate
var exit_gate: StageGate

func _ready() -> void:
    _add_collision(Rect2(0,288,1600,224),false)
    _add_collision(Rect2(-32,0,32,512),false)
    _add_collision(Rect2(1600,0,32,512),false)
    entrance=StageGate.new()
    entrance.position=Vector2(320,288)
    add_child(entrance)
    exit_gate=StageGate.new()
    exit_gate.position=Vector2(1280,288)
    add_child(exit_gate)
    exit_gate.set_closed(true)

func _draw() -> void:
    draw_rect(Rect2(0,288,1600,224),Color("37424b"))
    for x in range(0,1600,32):
        for y in range(288,384,16):
            draw_rect(Rect2(x+1,y+1,30,14),Color("54616a") if posmod(x/32+y/16,3)==0 else Color("44525b"))
            draw_rect(Rect2(x+3,y+3,11,2),Color("7c8583"))
    draw_rect(Rect2(0,288,1600,3),Color("b6b399"))
    for x in [326,1250]:
        draw_rect(Rect2(x,217,24,71),Color("293e48"))
        for y in range(220,287,16):
            draw_rect(Rect2(x+2,y,20,13),Color("87908c"))
            draw_rect(Rect2(x+3,y+1,16,2),Color("d3c69f"))
    for x in range(448,1232,96):
        draw_rect(Rect2(x,284,28,3),Color("bf9c60"))
    for spec in sign_specs():
        draw_rect(Rect2(spec.x,165,180,29),Color("182e36"))
        draw_string(ui_font,Vector2(spec.x+8,184),spec.title,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e0c98a"))

func sign_specs() -> Array[Dictionary]:
    return [{"x":80,"title":"裂岩试炼 · E 换装"},{"x":504,"title":"跳过冲撞 · 收招反击"},{"x":1320,"title":"试炼出口 →"}]
