class_name SpiderwoodCourse
extends "res://scripts/world/movement_course.gd"
const LAND: Array[Rect2] = [
    Rect2(-32,0,32,512),Rect2(9472,0,32,512),
    Rect2(0,288,2048,224),Rect2(2368,288,2080,224),
    Rect2(4544,264,48,248),Rect2(4688,288,592,224),Rect2(5600,288,3872,224),
    Rect2(3552,256,24,32),Rect2(6312,256,24,32)
]
const WOOD: Array[Rect2] = [Rect2(2960,224,208,12),Rect2(3856,256,112,12),
    Rect2(5040,224,112,12),Rect2(5152,176,112,12),Rect2(6864,224,112,12)]
const SEGMENTS: Array[Dictionary] = [
    {"x":0,"name":"月夜入口"},{"x":900,"name":"树影伏击"},
    {"x":1800,"name":"溪流悬桥"},{"x":3328,"name":"苔岩箭道"},
    {"x":4448,"name":"断溪石阶"},{"x":4928,"name":"树冠靶点"},
    {"x":5808,"name":"守门合围"},{"x":7680,"name":"皇后石门"},{"x":8000,"name":"药雾庭院"},{"x":9216,"name":"林径出口"}
]
const BRIDGES: Array[Dictionary] = [
    {"id":"brook_bridge","target":Vector2(2000,264),"rect":Rect2(2048,288,320,12)},
    {"id":"canopy_bridge","target":Vector2(5248,151),"rect":Rect2(5280,288,320,12)}
]
var switches: Array[ArrowSwitch] = []
var bridges: Array[StaticBody2D] = []
var bridge_progress: Array[float] = [0.0,0.0]
var entrance: StageGate
var exit_gate: StageGate
var seconds:=0.0

func _ready() -> void:
    process_physics_priority=5
    for rect in LAND: _add_collision(rect,false)
    for rect in WOOD: _add_collision(rect,true)
    for i in BRIDGES.size():
        var spec: Dictionary=BRIDGES[i]
        var target:=ArrowSwitch.new()
        target.switch_id=spec.id
        target.position=spec.target
        target.ui_font=ui_font
        add_child(target)
        switches.append(target)
        var body:=StaticBody2D.new()
        body.position=spec.rect.get_center()
        body.collision_layer=0
        body.collision_mask=0
        var collider:=CollisionShape2D.new()
        var shape:=RectangleShape2D.new()
        shape.size=spec.rect.size
        collider.shape=shape
        body.add_child(collider)
        add_child(body)
        bridges.append(body)
        target.activated.connect(func() -> void:
            var level:=get_parent().get_parent()
            level.toast="靶点命中！木桥正在放下，等桥面亮起再过溪。"
            level.toast_left=3
            level.sound.play_effect(&"block")
            print("SPIDERWOOD_SWITCH id=",spec.id))
    entrance=StageGate.new()
    entrance.position=Vector2(8000,288)
    add_child(entrance)
    entrance.set_closed(true)
    exit_gate=StageGate.new()
    exit_gate.position=Vector2(9024,288)
    add_child(exit_gate)
    exit_gate.set_closed(true)

func _physics_process(delta: float) -> void:
    for i in switches.size():
        bridge_progress[i]=move_toward(bridge_progress[i],1.0 if switches[i].active else 0.0,delta/0.7)
        bridges[i].collision_layer=1 if bridge_progress[i]>=1.0 else 0
    get_parent().get_parent().check_environment()

func mechanism_state() -> Dictionary:
    var state: Dictionary={}
    for target in switches: state[str(target.switch_id)]=target.active
    return state

func restore_mechanisms(state: Dictionary) -> void:
    for i in switches.size():
        var active: bool=state.get(str(switches[i].switch_id),false)
        switches[i].set_active(active)
        bridge_progress[i]=1.0 if active else 0.0
        bridges[i].set_deferred("collision_layer",1 if active else 0)

func _process(delta: float) -> void:
    seconds+=delta
    queue_redraw()

func _wood(rect: Rect2, lit: bool=false) -> void:
    draw_rect(rect,Color("293e40"))
    draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("99d6c0") if lit else Color("acac78"))
    for x in range(int(rect.position.x),int(rect.end.x),16):
        draw_rect(Rect2(x+1,rect.position.y+3,14,6),Color("6c9256"))
        draw_rect(Rect2(x+3,rect.position.y+4,9,1),Color("8e9970"))

func _draw() -> void:
    var level:=get_parent().get_parent()
    if not level.is_node_ready(): return
    var view_x: float=level.camera.position.x
    var visible:=Rect2(Vector2(view_x-get_viewport_rect().size.x*0.5-30,-200),get_viewport_rect().size+Vector2(60,400))
    for rect in LAND:
        if rect.size.y>=400 or not visible.intersects(rect): continue
        _terrain(rect,rect.position.x>=3328,visible)
    for rect in WOOD:
        if visible.intersects(rect): _wood(rect)
    for i in BRIDGES.size():
        var rect: Rect2=BRIDGES[i].rect
        if not visible.intersects(Rect2(rect.position-Vector2(0,100),rect.size+Vector2(0,100))): continue
        # Fixed river below the route, with readable bank edges and ropes.
        draw_rect(Rect2(rect.position+Vector2(0,52),Vector2(rect.size.x,170)),Color("123344"))
        for n in 12:
            var x:=rect.position.x+posmod(int(n*39+seconds*18),int(rect.size.x)-20)
            draw_rect(Rect2(x,346+posmod(n*17,28),18,2),Color("487a82"))
        for x in [rect.position.x-7,rect.end.x+3]:
            draw_rect(Rect2(x,240,5,48),Color("a5a178"))
        draw_line(rect.position+Vector2(0,-45),Vector2(rect.end.x,243),Color("737f70"),1)
        var fraction: float=bridge_progress[i] if bridges.size()>i else 0
        if fraction>0:
            _wood(Rect2(rect.position,Vector2(rect.size.x*fraction,12)),fraction>=1)
    for x in [1120,2880,4800,6470]:
        if absf(x-view_x)>380: continue
        draw_rect(Rect2(x+35,112,20,176),Color("2d3f43"))
        draw_rect(Rect2(x+36,113,4,172),Color("516455"))
        for y in range(118,285,17):
            draw_rect(Rect2(x+43,y,3,12),Color("1d333b"))
            draw_rect(Rect2(x+48,y+5,5,2),Color("65705b"))
        draw_rect(Rect2(x+37,237,7,23),Color("627d65"))
        draw_rect(Rect2(x+35,256,10,4),Color("8c9a71"))
        draw_line(Vector2(x-28,124),Vector2(x+37,124),Color("abbdb5"),1)
        draw_line(Vector2(x+37,124),Vector2(x+37,180),Color("abbdb5"),1)
        for j in [1,2,3]:
            draw_line(Vector2(x+37-j*17,124),Vector2(x+37,124+j*17),Color(0.66,0.79,0.77,0.5),1)
    for x in range(100,9400,159):
        if absf(x-view_x)>380: continue
        var grounded:=false
        for rect in LAND:
            if rect.position.y==288 and x>=rect.position.x and x<rect.end.x: grounded=true
        if grounded: RemixArt.icon(self,12+posmod(x/159,3),Rect2(x,267,27,21),Color("9abbb6"))
    _plaque(Vector2(138,155),"02 · 蛛影林径","留意树上伏击；弓箭可启动木桥",view_x)
    _plaque(Vector2(955,116),"蛛丝预警","落点亮起后闪开，再回身反击",view_x)
    _plaque(Vector2(1810,151),"溪流靶点","切弓，射中靶心后等木桥放平",view_x)
    _plaque(Vector2(2960,103),"溪畔补给","跳上木台，顶箱领取面包",view_x)
    _plaque(Vector2(4320,139),"断溪石阶","长跳落稳石台，再跳向对岸",view_x)
    _plaque(Vector2(4992,88),"树冠靶点","沿两级木台向上，站稳后射靶",view_x)
    _plaque(Vector2(5900,147),"守门合围","射手与蜘蛛交错；利用平台躲箭",view_x)
    _plaque(Vector2(1220,118),"女巫药水","红瓶直接伤害；绿瓶持续中毒",view_x)
    _plaque(Vector2(2650,133),"林间小动物","剑弓可获得食物 · 不计入清怪",view_x)
    _plaque(Vector2(7720,133),"女巫皇后","护卫合围 · 双瓶药水 · 半血加速三连",view_x)
    for summon in level.pending_summons:
        var at: Vector2=summon.at
        if absf(at.x-view_x)<370:
            draw_arc(at+Vector2(0,-3),24,PI,TAU,16,Color("cd94d9"),2)
            draw_line(at+Vector2(-18,-2),at+Vector2(18,-2),Color("f1cfec"),2)
            draw_string(ui_font,at+Vector2(-24,-36),"蜘蛛将至" if summon.kind==EnemyData.Kind.SPIDER else "射手将至",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f0cae9"))
    if absf(view_x-8512)<820:
        for x in [8160,8352,8544,8736,8928]:
            draw_rect(Rect2(x,278,40,10),Color("4d3f52"))
            draw_rect(Rect2(x+4,276,32,3),Color("8e6b98"))
        for x in [8070,8960]:
            draw_rect(Rect2(x,267,24,21),Color("322e40"))
            draw_rect(Rect2(x-2,262,28,8),Color("787085"))
            draw_rect(Rect2(x+3,260,18,4),Color("88c487"))
    for i in [1,2]:
        var spec: Dictionary=level.checkpoint_specs()[i]
        if absf(spec.x-view_x)>360: continue
        var lit: bool=level.checkpoint_index>=i
        draw_rect(Rect2(spec.x-2,247,4,41),Color("968a63"))
        draw_rect(Rect2(spec.x+2,247,25,14),Color("73caba") if lit else Color("586e75"))
        _plaque(Vector2(spec.x-55,192),spec.label,"已保存" if lit else "清除前段后记录 · 不回血",view_x)
    if absf(9280-view_x)<370:
        draw_rect(Rect2(9256,180,60,108),Color("233540"))
        draw_rect(Rect2(9263,187,46,101),Color("486c78"))
        draw_rect(Rect2(9269,194,34,94),Color("487e80") if level.cleared_count()==level.targets.size() else Color("263a44"))
        for i in 12:
            draw_rect(Rect2(9271+posmod(i*13,29),198+posmod(i*17+int(seconds*8),84),2,4),Color("b5e0d3"))

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
