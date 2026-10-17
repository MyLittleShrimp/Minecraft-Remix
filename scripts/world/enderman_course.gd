extends "res://scripts/world/movement_course.gd"
const FLOORS: Array[Rect2]=[Rect2(0,288,1376,224),Rect2(1464,288,840,224)]
const LEDGES: Array[Rect2]=[Rect2(752,224,176,10),Rect2(936,160,192,10),Rect2(1824,216,152,10),Rect2(2064,216,152,10)]
const WALL:=Rect2(2016,224,32,64)
var entry_gates: Array[StageGate]=[]
var exit_gates: Array[StageGate]=[]
func _ready() -> void:
    process_physics_priority=5
    for rect in FLOORS: _add_collision(rect,false)
    for rect in LEDGES: _add_collision(rect,true)
    _add_collision(WALL,false)
    _add_collision(Rect2(-32,0,32,512),false)
    _add_collision(Rect2(2304,0,32,512),false)
    for x in [288.0,752.0,1232.0,1728.0]:
        var gate:=StageGate.new()
        gate.position=Vector2(x,288)
        add_child(gate)
        entry_gates.append(gate)
    for x in [704.0,1200.0,1680.0,2240.0]:
        var gate:=StageGate.new()
        gate.position=Vector2(x,288)
        add_child(gate)
        exit_gates.append(gate)
    reset_rooms()
func reset_rooms() -> void:
    for gate in entry_gates: gate.set_closed(false)
    for gate in exit_gates: gate.set_closed(true)
func start_room(index: int) -> void: entry_gates[index].set_closed(true)
func release_room(index: int) -> void:
    entry_gates[index].set_closed(false)
    exit_gates[index].set_closed(false)
func open_all_rooms() -> void:
    for i in entry_gates.size(): release_room(i)
func _physics_process(_delta: float) -> void:
    get_parent().get_parent().check_environment()
func _draw() -> void:
    for rect in FLOORS:
        draw_rect(rect,Color("1d343f"))
        for x in range(int(rect.position.x),int(rect.end.x),24):
            for y in range(292,400,16):
                draw_rect(Rect2(x+1,y,22,14),Color("304453") if posmod(x/24+y/16,3)==0 else Color("293945"))
                draw_rect(Rect2(x+4,y+3,6,2),Color("45646a"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),Color("63c6b3"))
        draw_rect(Rect2(rect.position+Vector2(0,4),Vector2(rect.size.x,4)),Color("285d64"))
    for rect in LEDGES:
        draw_rect(rect,Color("284a51"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("8be0c4"))
        for x in range(int(rect.position.x)+8,int(rect.end.x)-8,16):
            draw_rect(Rect2(x,rect.end.y,2,14+posmod(x,13)),Color("458c85"))
    draw_rect(WALL,Color("383249"))
    for y in range(224,288,16):
        draw_rect(Rect2(2018,y+1,28,13),Color("594a6e"))
        draw_rect(Rect2(2021,y+3,10,2),Color("9c7bad"))
    for spec in [{"x":342,"text":"01 守路 · 击败后开门"},{"x":802,"text":"02 高台 · 留意紫色落点"},{"x":1270,"text":"03 断隙 · 起跳越过"},{"x":1800,"text":"04 窄墙 · 绕行反击"}]:
        draw_rect(Rect2(spec.x,116,194,23),Color("102b36"))
        draw_string(ui_font,Vector2(spec.x+8,132),spec.text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d0e6d8"))
    draw_string(ui_font,Vector2(2168,266),"出口 →",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d0e6d8"))
