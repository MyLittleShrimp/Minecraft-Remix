extends "res://scripts/world/movement_course.gd"
const COVER:=Rect2(592,272,24,16)
const LEDGES: Array[Rect2]=[Rect2(448,272,96,10),Rect2(784,272,112,10)]
var entry: StageGate
var exit_gate: StageGate
func _ready() -> void:
    _add_collision(Rect2(0,288,1280,224),false)
    _add_collision(Rect2(-32,0,32,512),false)
    _add_collision(Rect2(1280,0,32,512),false)
    _add_collision(COVER,false)
    for ledge in LEDGES: _add_collision(ledge,true)
    entry=StageGate.new()
    entry.position=Vector2(320,288)
    add_child(entry)
    exit_gate=StageGate.new()
    exit_gate.position=Vector2(960,288)
    add_child(exit_gate)
    reset_arena()
func reset_arena() -> void:
    entry.set_closed(false)
    exit_gate.set_closed(true)
func release_arena() -> void:
    entry.set_closed(false)
    exit_gate.set_closed(false)
func _draw() -> void:
    draw_rect(Rect2(0,288,1280,224),Color("2b2934"))
    for x in range(0,1280,24):
        for y in range(288,400,16):
            draw_rect(Rect2(x+1,y+1,22,14),Color("45404b") if posmod(x/24+y/16,3)==0 else Color("393441"))
            draw_rect(Rect2(x+3,y+3,7,2),Color("64515c"))
    draw_rect(Rect2(0,288,1280,4),Color("bb8c7b"))
    for ledge in LEDGES:
        draw_rect(ledge,Color("413640"))
        draw_rect(Rect2(ledge.position,Vector2(ledge.size.x,3)),Color("c2a997"))
        for x in range(int(ledge.position.x)+5,int(ledge.end.x),16):
            draw_rect(Rect2(x,ledge.end.y,4,20),Color("645260"))
    draw_rect(COVER,Color("574755"))
    for y in range(272,288,8):
        draw_rect(Rect2(594,y+1,20,6),Color("827080"))
    draw_rect(Rect2(592,272,24,3),Color("cfb7a2"))
    draw_string(ui_font,Vector2(552,306),"矮石挡低飞火球",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ddc8b8"))
    draw_string(ui_font,Vector2(382,242),"高空：上瞄 / 反弹    低空：跳跃近战",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ddc8b8"))
    draw_string(ui_font,Vector2(1036,252),"试炼出口 →",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ebc8a3"))
