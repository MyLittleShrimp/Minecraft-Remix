extends "res://scripts/world/movement_course.gd"
const ROOMS: Array[Vector2]=[Vector2(320,960),Vector2(1184,1824),Vector2(2048,2688),Vector2(2912,3552),Vector2(3776,4416),Vector2(4640,5280),Vector2(5504,6144),Vector2(6368,7008)]
const TITLES: Array[String]=["林地旧敌","蛛林药雾","矿坑斧阵","潮汐投矛","诡异双影","堡垒火骨","猪灵近卫","连弩终哨"]
const HINTS: Array[String]=["分开僵尸与射手 · 苦力帕闪烁时退开","避开药水落点 · 别被蜘蛛逼入毒区","诱出斧击再反攻 · 留意后排箭矢","两名溺尸轮流投矛 · 跳躲后反击","末影人落点有预警 · 恶魂火球可以反弹","先避开长剑 · 烈焰人低空时可近战","金剑追击快 · 金斧蓄力时不要贪刀","跳过弩箭 · 趁装填清理最后的守军"]
var entry_gates: Array[StageGate]=[]
var exit_gates: Array[StageGate]=[]
func _ready() -> void:
    _add_collision(Rect2(0,288,7360,224),false)
    for x in [-32,7360]: _add_collision(Rect2(x,0,32,512),false)
    for room in ROOMS:
        var a:=StageGate.new()
        a.position=Vector2(room.x,288)
        add_child(a)
        entry_gates.append(a)
        var b:=StageGate.new()
        b.position=Vector2(room.y,288)
        add_child(b)
        exit_gates.append(b)
    reset_rooms()
func reset_rooms() -> void:
    for g in entry_gates: g.set_closed(false)
    for g in exit_gates: g.set_closed(true)
func start_room(i: int) -> void: entry_gates[i].set_closed(true)
func release_room(i: int) -> void:
    entry_gates[i].set_closed(false)
    exit_gates[i].set_closed(false)
func _draw() -> void:
    draw_rect(Rect2(0,288,7360,224),Color("263138"))
    for x in range(0,7360,24):
        for y in range(292,416,16):
            draw_rect(Rect2(x+1,y,22,14),Color("4e5c63"))
            draw_rect(Rect2(x+3,y+2,12,2),Color("71817a"))
    draw_rect(Rect2(0,288,7360,4),Color("a9b79b"))
    if not get_node("/root/ControlSettings").guide_enabled: return
    for i in 8:
        var x:=ROOMS[i].x+96
        draw_rect(Rect2(x,145,440,37),Color("17292e"))
        draw_line(Vector2(x,145),Vector2(x+440,145),Color("b5a57f"),2)
        draw_string(ui_font,Vector2(x+10,161),"回响 %d / 8 · %s"%[i+1,TITLES[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f1e0b4"))
        draw_string(ui_font,Vector2(x+10,175),HINTS[i],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("b1c8c0"))
