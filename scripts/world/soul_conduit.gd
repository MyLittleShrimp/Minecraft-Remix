class_name SoulConduit
extends Node2D
## A free, reversible spatial puzzle. Ports visibly connect source to a sealed gate.
const CENTERS: Array[Vector2]=[Vector2(96,156),Vector2(240,208),Vector2(384,172)]
const START: Array[int]=[0,1,2]
const PORTS: Array[Vector2]=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
# Each elbow uses adjacent ports n and n+1. Read the fixed pipes to find the route.
const INPUTS: Array[int]=[3,3,0]
const OUTPUTS: Array[int]=[2,0,1]
var rotations: Array[int]=START.duplicate()
var active:=false
var powered:=0
var elapsed:=0.0
var turns:=0
var ui_font: Font
var gate: StageGate
func _ready() -> void:
    gate=StageGate.new()
    gate.position=Vector2(536,288)
    add_child(gate)
    apply_state(false)
func nearby_rotor(world_at: Vector2) -> int:
    if active: return -1
    var at:=world_at-global_position
    if absf(at.y-288)>8: return -1
    for i in CENTERS.size():
        if absf(at.x-CENTERS[i].x)<40: return i
    return -1
func interact(world_at: Vector2) -> void:
    var index:=nearby_rotor(world_at)
    if index<0: return
    rotations[index]=(rotations[index]+1)%4
    turns+=1
    refresh()
    var level: Node=get_parent().get_parent().get_parent()
    if active:
        level.toast="灵魂封印已解除 · 沿亮起的线路向右前进"
        level.toast_left=3
    else: level.show_guide("旋转符文 · 让弯管两端对准固定管线，能量会逐段亮起",3)
func refresh() -> void:
    powered=0
    for i in CENTERS.size():
        var a: int=rotations[i]
        var b: int=(a+1)%4
        if INPUTS[i] not in [a,b] or OUTPUTS[i] not in [a,b]: break
        powered+=1
    active=powered==3
    gate.set_closed(not active)
    queue_redraw()
func apply_state(solved: bool) -> void:
    rotations=([2,3,0] as Array[int]) if solved else START.duplicate()
    turns=0
    refresh()
func _physics_process(delta: float) -> void:
    elapsed+=delta
    queue_redraw()
func _port(index: int,side: int) -> Vector2:
    return CENTERS[index]+PORTS[side]*24
func _wire(points: PackedVector2Array,on: bool) -> void:
    draw_polyline(points,Color("152228"),9)
    draw_polyline(points,Color("74dccc") if on else Color("6a6261"),4)
    for i in range(points.size()-1):
        var direction: Vector2=(points[i+1]-points[i]).normalized()
        var side:=Vector2(-direction.y,direction.x)
        var mid: Vector2=(points[i]+points[i+1])/2
        draw_colored_polygon(PackedVector2Array([mid+direction*4,mid-direction*3+side*3,mid-direction*3-side*3]),Color("dcfff0") if on else Color("a99a84"))
        if on:
            var distance: float=points[i].distance_to(points[i+1])
            var dot: Vector2=points[i]+direction*fmod(elapsed*55,distance)
            draw_rect(Rect2(dot-Vector2(2,2),Vector2(4,4)),Color("edfff1"))
func _draw() -> void:
    if not is_instance_valid(gate): return
    if get_node("/root/ControlSettings").guide_enabled:
        draw_rect(Rect2(4,104,480,20),Color("19252be8"))
        draw_line(Vector2(4,104),Vector2(484,104),Color("c5a67f"),2)
        draw_string(ui_font,Vector2(14,118),"灵魂导流室 · 旋转弯管，沿箭头接通封印门 · 不消耗物品",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f3dfba"))
    _wire(PackedVector2Array([Vector2(28,156),_port(0,INPUTS[0])]),true)
    _wire(PackedVector2Array([_port(0,OUTPUTS[0]),Vector2(CENTERS[0].x,CENTERS[1].y),_port(1,INPUTS[1])]),powered>=1)
    # Turn above the third housing before descending into its top socket.
    # Fixed pipes and elbows share socket coordinates so moving a rune cannot leave a gap.
    _wire(PackedVector2Array([_port(1,OUTPUTS[1]),Vector2(CENTERS[1].x,132),Vector2(CENTERS[2].x,132),_port(2,INPUTS[2])]),powered>=2)
    _wire(PackedVector2Array([_port(2,OUTPUTS[2]),Vector2(476,CENTERS[2].y),Vector2(476,216),Vector2(528,216)]),active)
    # Source furnace: blue flame and a broad base, separate from the rotary controls.
    draw_rect(Rect2(16,148,24,29),Color("504e55"))
    draw_rect(Rect2(20,141,16,18),Color("459caa"))
    draw_rect(Rect2(24,134,8,22),Color("b5f9e4"))
    var level: Node=get_parent().get_parent().get_parent()
    var nearby:=nearby_rotor(level.player.position) if is_instance_valid(level.player) else -1
    var settings: Node=get_node("/root/ControlSettings")
    var key: String=settings.hint("aim_up") if settings.gamepad_active() else "E"
    for i in CENTERS.size():
        var c: Vector2=CENTERS[i]
        var lit:=powered>i
        draw_line(Vector2(c.x,232),Vector2(c.x,280),Color("514a4f"),5)
        draw_rect(Rect2(c-Vector2(27,27),Vector2(54,54)),Color("211f2b"))
        draw_rect(Rect2(c-Vector2(25,25),Vector2(50,50)),Color("685360"),false,2)
        for port in PORTS:
            draw_rect(Rect2(c+port*24-Vector2(3,3),Vector2(6,6)),Color("bd9c76"))
        var a: Vector2=PORTS[rotations[i]]
        var b: Vector2=PORTS[(rotations[i]+1)%4]
        var col:=Color("a1f4df") if lit else Color("dfb778")
        draw_polyline(PackedVector2Array([c+a*24,c,c+b*24]),Color("131b22"),10)
        draw_polyline(PackedVector2Array([c+a*24,c,c+b*24]),col,5)
        draw_rect(Rect2(c-Vector2(4,4),Vector2(8,8)),Color("effce6") if lit else Color("9b6b45"))
        draw_rect(Rect2(c.x-12,275,24,12),Color("63786a") if lit else Color("695248"))
        draw_string(ui_font,Vector2(c.x+33,c.y+28),"%s 旋转 %s"%[key,["Ⅰ","Ⅱ","Ⅲ"][i]] if nearby==i else ["符文 Ⅰ","符文 Ⅱ","符文 Ⅲ"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("dcfff0") if lit else Color("efc98f"))
    draw_string(ui_font,Vector2(575,192),"封印门",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f0d29e"))
    draw_rect(Rect2(517,203,15,26),Color("95efce") if active else Color("804b68"))
    draw_string(ui_font,Vector2(416,273),"已解封" if active else "线路 %d / 3"%powered,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("b9f0d9"))
