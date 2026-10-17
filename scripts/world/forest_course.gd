class_name ForestCourse
extends "res://scripts/world/movement_course.gd"

const WIDTH: float = 11264
const ARENA_LEFT: float = 9216
const ARENA_RIGHT: float = 10176
const PITS: Array[Rect2] = [Rect2(3392,288,96,224),Rect2(3536,288,112,224),Rect2(3872,288,96,224),Rect2(7328,288,96,224)]
const FIRES: Array[Rect2] = [Rect2(4904,256,48,32),Rect2(8936,256,48,32)]
const LAND: Array[Rect2] = [
    Rect2(-32,0,32,512),Rect2(11264,0,32,512),
    Rect2(0,288,3392,224),Rect2(3488,264,48,248),Rect2(3648,288,224,224),
    Rect2(3968,288,3360,224),Rect2(7424,288,3840,224),
    Rect2(576,256,64,32),Rect2(672,224,64,64),
    Rect2(4064,240,24,48),Rect2(4512,256,32,32),Rect2(6720,256,32,32),
    Rect2(5680,224,128,12),Rect2(5648,160,160,12),Rect2(5796,172,12,52),
    Rect2(9648,256,32,32)
]
const WOOD: Array[Rect2] = [
    Rect2(2624,224,128,12),Rect2(2784,176,128,12),Rect2(3032,224,128,12),
    Rect2(5536,256,96,12),Rect2(5632,224,48,12),Rect2(7008,224,96,12),
    Rect2(9344,240,96,12),Rect2(9920,240,96,12),
    Rect2(8032,224,112,12),Rect2(8464,208,128,12)
]
const SEGMENTS: Array[Dictionary] = [
    {"x":0,"name":"营地出口","hint":"A D 前进 · 长按 SPACE 跳得高"},
    {"x":1152,"name":"林地小径","hint":"J 挥剑 · 受伤后闪烁时短暂安全"},
    {"x":2432,"name":"高低平台","hint":"木台可从下方穿过 · S + SPACE 下落"},
    {"x":3712,"name":"断桥哨点","hint":"长跳跨桥 · K 切弓，蓄力后松 J"},
    {"x":4992,"name":"苔石庭院","hint":"苦力帕闪烁时远离 · 裂纹砖可剑击或爆破"},
    {"x":6272,"name":"遗迹前厅","hint":"先处理近处敌人 · 掩体可挡箭"},
    {"x":7808,"name":"密林长廊","hint":"留意蜘蛛扑击 · 面包补充饱食"},
    {"x":9216,"name":"队长大厅","hint":"躲过三连箭，利用恢复窗口反击"},
    {"x":10240,"name":"传送门","hint":"领取队长战利品，前往出口结算"}
]
var entrance: StageGate
var exit_gate: StageGate
@onready var control_settings: Node = get_node("/root/ControlSettings")

func _ready() -> void:
    process_physics_priority = 5
    for rect in LAND: _add_collision(rect,false)
    for rect in WOOD: _add_collision(rect,true)
    entrance = _gate(ARENA_LEFT)
    exit_gate = _gate(ARENA_RIGHT)
    entrance.set_closed(true)
    exit_gate.set_closed(true)

func _gate(x: float) -> StageGate:
    var gate := StageGate.new()
    gate.position = Vector2(x,288)
    add_child(gate)
    return gate

func _physics_process(_delta: float) -> void:
    get_parent().get_parent().check_environment()

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var level := get_parent().get_parent()
    var view_x: float = level.camera.position.x if is_instance_valid(level) and level.is_node_ready() else 320
    var visible := Rect2(Vector2(view_x-get_viewport_rect().size.x*0.5-30,-200),get_viewport_rect().size+Vector2(60,400))
    for x in range(6400,10240,256):
        if absf(x-view_x)>380: continue
        draw_rect(Rect2(x,144,30,144),Color("425952"))
        draw_rect(Rect2(x-7,136,44,10),Color("70806c"))
        draw_rect(Rect2(x+3,148,4,138),Color("617361"))
        for y in range(162,282,24):
            draw_line(Vector2(x,y),Vector2(x+30,y),Color("354d49"),2)
        RemixArt.icon(self,15,Rect2(x+5,138,28,54),Color("80996b"))
        draw_rect(Rect2(x+11,204,7,14),Color("674f36"))
        draw_rect(Rect2(x+10,196,9,9),Color("d89949"))
        draw_rect(Rect2(x+12,193,4,10),Color("ffda89"))
    for rect in LAND:
        if rect.size.y>=400 or not visible.intersects(rect): continue
        var stone := rect.position.x>=6272 or (rect.position.y<288 and rect.position.x>4000)
        _terrain(rect,stone,visible)
    for rect in WOOD:
        if not visible.intersects(rect): continue
        draw_rect(rect,Color("3a342b"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("c9aa65"))
        for x in range(int(rect.position.x),int(rect.end.x),16):
            draw_rect(Rect2(x+1,rect.position.y+3,14,6),Color("8f7147"))
            draw_line(Vector2(x+3,rect.position.y+5),Vector2(x+11,rect.position.y+5),Color("b18c53"),1)
        for x in [rect.position.x+5,rect.end.x-8]:
            draw_rect(Rect2(x,rect.position.y+3,3,8),Color("b8b48b"))
            draw_rect(Rect2(x,rect.end.y,3,9),Color("5c6950"))
    for x in range(50,11224,137):
        if absf(x-view_x)>370: continue
        var near_pit := false
        for pit in PITS:
            if x>pit.position.x-42 and x<pit.end.x+24: near_pit=true
        if near_pit: continue
        var item := 12+posmod(x/137,3)
        var size := Vector2(25,19) if item==12 else (Vector2(36,23) if item==13 else Vector2(28,17))
        RemixArt.icon(self,item,Rect2(Vector2(x,289-size.y),size),Color("a8bc8b") if x>=6272 else Color.WHITE)
    _plaque(Vector2(156,140),"向林地出发","方向移动 / %s 跳跃" % control_settings.hint("jump") if control_settings.gamepad_active() else "A D 移动  /  SPACE 跳跃",view_x)
    _plaque(Vector2(2576,115),"高台补给 · 面包 +6","先躲箭，再顶开最高处箱子",view_x)
    _plaque(Vector2(2180,148),"蜘蛛会扑击","压低身体时准备躲避",view_x)
    _plaque(Vector2(6880,125),"高处面包箱","跳上木台，顶箱补充饱食",view_x)
    _plaque(Vector2(7840,138),"密林长廊","蜘蛛不掉宝石 · 战斗消耗饱食",view_x)
    _plaque(Vector2(3290,146),"连续断桥","落稳中间石台，再起跳",view_x)
    _plaque(Vector2(5430,143),"遗迹宝库 · 宝石 +5","跳跃挥剑，击碎裂纹砖",view_x)
    _plaque(Vector2(940,124),"绿宝石大招 · L","攒够20颗：巨剑暴击 / 五箭齐射",view_x)
    _plaque(Vector2(5925,150),"裂纹藏宝砖","挥剑破开，等待奖励落下",view_x)
    _plaque(Vector2(8914,174),"篝火会灼伤","跳过火焰，再挑战队长",view_x)
    _plaque(Vector2(4870,174),"篝火障碍","长按%s，跳过火焰" % control_settings.hint("jump"),view_x)
    for summon in level.pending_summons:
        var at: Vector2 = summon.at
        if absf(at.x-view_x)<370:
            draw_arc(at+Vector2(0,-3),23,PI,TAU,16,Color("dba265"),2)
            draw_line(at+Vector2(-17,-2),at+Vector2(17,-2),Color("f1c885"),2)
            draw_string(ui_font,at+Vector2(-22,-35),"援兵将至",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f5d493"))
    for fire in FIRES:
        if absf(fire.get_center().x-view_x)>370: continue
        # World obstacles sit on the ground; UI icon centering leaves a gap.
        var source: Rect2 = RemixArt.info("items",11).rect
        var ratio := minf(56.0/source.size.x,42.0/source.size.y)
        var flame_size := (source.size*ratio).round()
        draw_texture_rect_region(RemixArt.SHEETS.items,Rect2(Vector2(fire.get_center().x-flame_size.x/2,fire.end.y-flame_size.y),flame_size),source)
    if not is_instance_valid(level) or not level.is_node_ready(): return
    for index in [1,2]:
        var spec: Dictionary = level.checkpoint_specs()[index]
        if absf(spec.x-view_x)>370: continue
        var lit: bool = level.checkpoint_index>=index
        draw_rect(Rect2(spec.x-2,248,4,40),Color("9c8156"))
        draw_colored_polygon(PackedVector2Array([Vector2(spec.x+2,248),Vector2(spec.x+31,251),Vector2(spec.x+24,263),Vector2(spec.x+2,263)]),Color("73b7a7") if lit else Color("657879"))
        var title: String = spec.label+(" · 已记录" if lit else " · 不回血")
        var width := ui_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
        draw_rect(Rect2(spec.x-width/2-6,228,width+12,16),Color("1a3030"))
        draw_string(ui_font,Vector2(spec.x-width/2,239),title,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f0cf82") if lit else Color("bacbb4"))
    if absf(11019-view_x)<380:
        var open: bool = level.captain.health.current<=0
        draw_rect(Rect2(10988,181,76,107),Color("222331"))
        for y in range(185,288,16):
            for x in [10992,11050]:
                draw_rect(Rect2(x,y,10,14),Color("555062"))
                draw_rect(Rect2(x+1,y,3,5),Color("817287"))
        draw_rect(Rect2(11003,194,45,94),Color("664584") if open else Color("323642"))
        for i in 24:
            var x := 11006+posmod(i*19,39)
            var y := 196+posmod(i*13,90)
            draw_rect(Rect2(x,y,3,5),Color("ba8fd1") if open else Color("4c4c62"))
        draw_rect(Rect2(10997,184,58,8),Color("8b758a"))

func _terrain(rect: Rect2, stone: bool, visible: Rect2) -> void:
    var left := maxi(int(rect.position.x),floori(visible.position.x/32)*32)
    var right := mini(int(rect.end.x),int(visible.end.x)+32)
    var bottom := mini(int(rect.end.y),ceili(180+get_viewport_rect().size.y*0.5))
    draw_rect(rect.intersection(visible),Color("3d4943") if stone else Color("493c2f"))
    for y in range(int(rect.position.y),bottom,16):
        for x in range(left,right,32):
            var width := minf(31,rect.end.x-x)
            var height := minf(15,rect.end.y-y)
            var variation := posmod(x/32+y/16,3)
            var color := Color("65705b") if stone else Color("765438")
            if variation==1: color=color.darkened(0.09)
            draw_rect(Rect2(x,y,width,height),color)
            draw_rect(Rect2(x+2,y+2,minf(12,width-2),2),Color("818a6b") if stone else Color("957347"))
            if width>16: draw_rect(Rect2(x+17,y+9,5,3),Color("475747") if stone else Color("59402f"))
    draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("b1ba80") if stone else Color("afcd69"))
    draw_rect(Rect2(rect.position+Vector2(0,3),Vector2(rect.size.x,3)),Color("6a854d"))
    for x in range(left,right,13):
        var length := 3+posmod(x,5)
        draw_rect(Rect2(x,rect.position.y+5,minf(5,rect.end.x-x),length),Color("587442"))

func _plaque(at: Vector2, title: String, hint: String, view_x: float) -> void:
    if not get_node("/root/ControlSettings").guide_enabled: return
    if absf(at.x-view_x)>430: return
    var width := maxf(ui_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x,ui_font.get_string_size(hint,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x)+18
    draw_rect(Rect2(at+Vector2(0,0),Vector2(width,36)),Color("253935"))
    draw_rect(Rect2(at+Vector2(1,1),Vector2(width-2,2)),Color("95845b"))
    draw_rect(Rect2(at+Vector2(1,34),Vector2(width-2,2)),Color("121f23"))
    draw_string(ui_font,at+Vector2(9,15),title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f3ddaa"))
    draw_string(ui_font,at+Vector2(9,28),hint,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("b6c5a6"))
