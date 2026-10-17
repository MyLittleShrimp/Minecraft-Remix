extends "res://scripts/world/movement_course.gd"
const ROOMS: Array[Vector2]=[Vector2(320,704),Vector2(960,1376)]
const GROUNDS: Array[Rect2]=[Rect2(0,288,768,224),Rect2(864,288,1248,224),Rect2(2304,288,640,224)]
const LEDGES: Array[Rect2]=[Rect2(872,236,72,10),Rect2(912,188,80,10)]
const SLOT_X: Array[float]=[1760.0,1840.0,1920.0]
var entry_gates: Array[StageGate]=[]
var exit_gates: Array[StageGate]=[]
var seconds:=0.0
func _ready() -> void:
    for rect in GROUNDS: _add_collision(rect,false)
    for rect in LEDGES: _add_collision(rect,true)
    for x in [-32,2112,2272,2944]: _add_collision(Rect2(x,0,32,512),false)
    for room in ROOMS:
        var entry:=StageGate.new()
        entry.position=Vector2(room.x,288)
        add_child(entry)
        entry_gates.append(entry)
        var gate:=StageGate.new()
        gate.position=Vector2(room.y,288)
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
func _physics_process(delta: float) -> void:
    seconds+=delta
    get_parent().get_parent().check_environment()
    queue_redraw()
func _sign_at(x: float,title: String,detail: String,width: float=240) -> void:
    if not get_node("/root/ControlSettings").guide_enabled: return
    draw_rect(Rect2(x,136,width,39),Color("142c30"))
    draw_line(Vector2(x,136),Vector2(x+width,136),Color("96c1b0"),2)
    draw_string(ui_font,Vector2(x+10,153),title,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("efe5ba"))
    draw_string(ui_font,Vector2(x+10,168),detail,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("b2cabf"))
func _draw() -> void:
    for rect in GROUNDS:
        var ending:=rect.position.x>2200
        draw_rect(rect,Color("51455e") if ending else Color("253438"))
        for x in range(int(rect.position.x),int(rect.end.x),24):
            for y in range(292,400,16):
                draw_rect(Rect2(x+1,y,22,14),Color("aba681") if ending else Color("4d6360"))
                draw_rect(Rect2(x+3,y+2,11,2),Color("d3d0a7") if ending else Color("728678"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),Color("e2dda9") if ending else Color("9ebba0"))
    for rect in LEDGES:
        draw_rect(rect,Color("455b53"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("adbd90"))
    _sign_at(388,"要塞前庭","清理守卫，寻找通往末地的古门")
    _sign_at(1040,"回廊夹击","先分开蜘蛛与射手，再进入祭坛")
    if get_node("/root/ControlSettings").guide_enabled:
        draw_string(ui_font,Vector2(774,232),"断桥 · 跳过",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f0d393"))
        draw_string(ui_font,Vector2(864,145),"高处面包",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("cce6bc"))
    _sign_at(1432,"三眼合成台","3 珍珠 + 3 烈焰粉 → 3 末影之眼",250)
    _sign_at(1708,"末地之门","古门已有九眼；补齐下方三个空槽",300)
    _sign_at(2412,"07 / 抵达末地","这里是终章入口 · 向右完成本次序章",370)
    _altar()
    _portal()
    draw_string(ui_font,Vector2(2750,236),"序章出口 →",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e7dccb"))
func _altar() -> void:
    var state: EndPortalState=get_parent().get_parent().portal
    draw_rect(Rect2(1510,258,52,30),Color("425d5a"))
    draw_rect(Rect2(1504,255,64,5),Color("c6c08f"))
    draw_rect(Rect2(1520,264,32,3),Color("7da18c"))
    var bob:=sin(seconds*2)*2
    if state.crafted: PortalItemArt.draw_item(self,1,Rect2(1522,219+bob,28,28))
    else:
        PortalItemArt.draw_item(self,0,Rect2(1508,221+bob,25,25))
        StoryItemArt.powder(self,Rect2(1538,219-bob,26,28))
func _frame(at: Vector2,filled: bool) -> void:
    draw_rect(Rect2(at-Vector2(15,12),Vector2(30,24)),Color("263e3c"))
    draw_rect(Rect2(at-Vector2(13,10),Vector2(26,20)),Color("6c8c75"))
    draw_rect(Rect2(at-Vector2(10,7),Vector2(20,14)),Color("142e32"))
    draw_line(at+Vector2(-13,-10),at+Vector2(13,-10),Color("c0c597"),2)
    if filled: PortalItemArt.draw_item(self,1,Rect2(at-Vector2(10,10),Vector2(20,20)))
func _portal() -> void:
    var state: EndPortalState=get_parent().get_parent().portal
    draw_rect(Rect2(1728,192,224,77),Color("152c32"))
    if state.is_open():
        draw_rect(Rect2(1730,194,220,70),Color("18142f"))
        for i in 40:
            var x:=1736+fposmod(i*37+seconds*(4+i%3),205)
            var y:=199+fposmod(i*23-seconds*6,60)
            var glow:=0.45+0.45*sin(seconds*2+i)
            draw_rect(Rect2(floorf(x),floorf(y),2+i%2,2+i%2),Color(0.65,0.87,0.88,glow))
        draw_rect(Rect2(1728,192,224,77),Color("84e1c5"),false,2)
    for x in SLOT_X: _frame(Vector2(x,189),true)
    for y in [207,232,257]:
        _frame(Vector2(1724,y),true)
        _frame(Vector2(1956,y),true)
    for i in 3: _frame(Vector2(SLOT_X[i],270),state.has_eye(i))
