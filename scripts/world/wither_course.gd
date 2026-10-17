extends "res://scripts/world/movement_course.gd"
const ROOMS: Array[Vector2]=[Vector2(320,832),Vector2(960,1472),Vector2(1600,2240),Vector2(2336,2848),Vector2(2976,3488),Vector2(3616,4256),Vector2(4384,5024)]
var entry_gates: Array[StageGate]=[]
var exit_gates: Array[StageGate]=[]
func _ready() -> void:
    _add_collision(Rect2(0,288,5248,224),false)
    _add_collision(Rect2(-32,0,32,512),false)
    _add_collision(Rect2(5248,0,32,512),false)
    for room in ROOMS:
        var entry:=StageGate.new()
        entry.position=Vector2(room.x,288)
        add_child(entry)
        entry_gates.append(entry)
        var exit_gate:=StageGate.new()
        exit_gate.position=Vector2(room.y,288)
        add_child(exit_gate)
        exit_gates.append(exit_gate)
    reset_rooms()
func reset_rooms() -> void:
    for gate in entry_gates: gate.set_closed(false)
    for gate in exit_gates: gate.set_closed(true)
func start_room(index: int) -> void: entry_gates[index].set_closed(true)
func release_room(index: int) -> void:
    entry_gates[index].set_closed(false)
    exit_gates[index].set_closed(false)
func _draw() -> void:
    draw_rect(Rect2(0,288,5248,224),Color("252431"))
    for x in range(0,5248,24):
        for y in range(292,400,16):
            var offset:=12 if (y/16)%2 else 0
            draw_rect(Rect2(x+offset+1,y,22,14),Color("3b3542"))
            draw_rect(Rect2(x+offset+3,y+2,10,2),Color("524655"))
    draw_rect(Rect2(0,288,5248,4),Color("b9a285"))
    var labels: Array[String]=["01 试刀 · 退开再反击","02 越刃 · 跳到背后","03 骨阵 · 先分开敌人","04 金剑 · 追击与抢攻","05 金斧 · 诱招再反击","06 连弩 · 跳躲两支箭","07 夹击 · 留意后排弩手"]
    for i in ROOMS.size():
        var x: float=ROOMS[i].x+100
        draw_rect(Rect2(x,116,220,31),Color("18232c"))
        draw_line(Vector2(x,116),Vector2(x+220,116),Color("be9b6c"),2)
        draw_string(ui_font,Vector2(x+9,136),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("eddbb8"))
        for torch_x in [ROOMS[i].x+58,ROOMS[i].y-58]:
            draw_rect(Rect2(torch_x,250,6,34),Color("504446"))
            draw_rect(Rect2(torch_x-2,239,10,11),Color("d39a5d"))
            draw_rect(Rect2(torch_x+1,236,4,12),Color("fae4a0"))
    draw_string(ui_font,Vector2(5076,250),"试炼出口 →",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("eddbb8"))
