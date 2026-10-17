class_name FortressCourse
extends "res://scripts/world/movement_course.gd"
const WIDTH:=13952.0
@export var campaign_arena := false
const ROOMS: Array[Vector2]=[Vector2(320,1248),Vector2(1728,2464),Vector2(2784,3296),Vector2(3488,4000),Vector2(4256,4896),Vector2(5184,5824),Vector2(7424,8384),Vector2(10112,11072),Vector2(11648,12800)]
const GAPS: Array[Vector2]=[Vector2(1488,1584),Vector2(2640,2720),Vector2(4960,5056),Vector2(6400,6656),Vector2(9568,9648),Vector2(9792,9888),Vector2(11504,11600)]
const FLOORS: Array[Vector2]=[Vector2(0,1488),Vector2(1584,2640),Vector2(2720,4960),Vector2(5056,6400),Vector2(6656,9568),Vector2(9648,9792),Vector2(9888,11504),Vector2(11600,13952)]
const COVERS: Array[Rect2]=[Rect2(672,216,32,72),Rect2(848,232,32,56)]
const LEDGES: Array[Rect2]=[Rect2(1584,248,64,10),Rect2(1656,208,64,10),Rect2(7088,248,64,10),Rect2(7160,208,96,10),Rect2(9360,248,64,10),Rect2(9432,208,96,10),Rect2(13376,248,64,10),Rect2(13448,208,96,10)]
var entry_gates: Array[StageGate]=[]
var exit_gates: Array[StageGate]=[]
var furnace: TNTTransportRoom
var conduit: SoulConduit
func _ready() -> void:
    process_physics_priority=5
    for floor_span in FLOORS: _add_collision(Rect2(floor_span.x,288,floor_span.y-floor_span.x,224),false)
    _add_collision(Rect2(-32,0,32,512),false)
    if not campaign_arena: _add_collision(Rect2(WIDTH,0,32,512),false)
    for cover in COVERS: _add_collision(cover,false)
    for ledge in LEDGES: _add_collision(ledge,true)
    for room in ROOMS:
        var gate:=StageGate.new()
        gate.position=Vector2(room.x,288)
        add_child(gate)
        entry_gates.append(gate)
        gate=StageGate.new()
        gate.position=Vector2(room.y,288)
        add_child(gate)
        exit_gates.append(gate)
    furnace=TNTTransportRoom.new()
    furnace.mechanism_id="fortress_furnace"
    furnace.source_point=Vector2(6104,276)
    furnace.plate_x=6256
    furnace.bridge_start=6400
    furnace.bridge_width=256
    furnace.lock_x=6688
    furnace.wall_x=6982
    furnace.lever_x=6816
    furnace.socket_label_y=178
    furnace.ui_font=ui_font
    add_child(furnace)
    conduit=SoulConduit.new()
    conduit.position.x=8672
    conduit.ui_font=ui_font
    add_child(conduit)
    reset_rooms()
func _physics_process(_delta: float) -> void:
    get_parent().get_parent().check_environment()
func reset_rooms() -> void:
    for gate in entry_gates: gate.set_closed(false)
    for gate in exit_gates: gate.set_closed(true)
func start_room(index: int) -> void: entry_gates[index].set_closed(true)
func release_room(index: int) -> void:
    entry_gates[index].set_closed(false)
    exit_gates[index].set_closed(false)
func mechanism_state() -> Dictionary: return {"fortress_furnace":furnace.active,"fortress_conduit":conduit.active}
func restore_mechanisms(saved: Dictionary) -> void:
    furnace.apply_state(saved.get("fortress_furnace",false))
    conduit.apply_state(saved.get("fortress_conduit",false))
func safe_floor(at: Vector2) -> bool:
    if campaign_arena and at.x>13632 and at.x<14888: return true
    if at.y<287: return true
    for floor_span in FLOORS:
        if at.x>floor_span.x+24 and at.x<floor_span.y-24: return true
    return false
func _draw() -> void:
    for floor_span in FLOORS:
        draw_rect(Rect2(floor_span.x,288,floor_span.y-floor_span.x,224),Color("2c222d"))
        draw_line(Vector2(floor_span.x,289),Vector2(floor_span.y,289),Color("bd9070"),3)
        for x in range(int(floor_span.x),int(floor_span.y),24):
            for y in range(294,400,16):
                draw_rect(Rect2(x+1,y,22,14),Color("483039"))
                draw_rect(Rect2(x+3,y+2,12,2),Color("62434a"))
    for gap in GAPS:
        draw_rect(Rect2(gap.x,352,gap.y-gap.x,160),Color("aa4024"))
        draw_line(Vector2(gap.x,352),Vector2(gap.y,352),Color("ffd373"),3)
        for x in range(int(gap.x)+6,int(gap.y),16): draw_rect(Rect2(x,361,8,3),Color("e58c3b"))
        for edge in [gap.x-8,gap.y]: draw_rect(Rect2(edge,278,8,10),Color("f0bc6f"))
    for cover in COVERS:
        draw_rect(cover,Color("5a4b51"))
        draw_rect(Rect2(cover.position,Vector2(cover.size.x,5)),Color("d1b58a"))
        for y in range(int(cover.position.y)+9,288,12):
            draw_rect(Rect2(cover.position.x+3,y,26,9),Color("74616b"))
        if get_node("/root/ControlSettings").guide_enabled: draw_string(ui_font,cover.position+Vector2(-5,-8),"掩体",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f4d49d"))
    for ledge in LEDGES:
        draw_rect(ledge,Color("6d5052"))
        draw_rect(Rect2(ledge.position,Vector2(ledge.size.x,3)),Color("ceb588"))
    var labels: Array[String]=["烈焰桥头 · 躲火后反击","骸骨长廊 · 跳背避长剑","金剑武库 · 留意追击","金斧守卫 · 诱出重劈","连弩封锁 · 两箭后装填","武库夹击 · 留意后排","灰烬交锋 · 空地夹击","骸骨防线 · 先拆后排","熔心突围 · 最后一道防线"]
    for i in ROOMS.size():
        var at:=Vector2(ROOMS[i].x+90,116)
        if get_node("/root/ControlSettings").guide_enabled:
            draw_rect(Rect2(at,Vector2(240,30)),Color("19252b"))
            draw_line(at,at+Vector2(240,0),Color("c9a37c"),2)
            draw_string(ui_font,at+Vector2(9,21),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f2deba"))
        for x in [ROOMS[i].x+58,ROOMS[i].y-52]:
            draw_rect(Rect2(x,250,5,34),Color("504146"))
            draw_rect(Rect2(x-2,239,9,12),Color("e99b53"))
            draw_rect(Rect2(x,236,4,11),Color("ffe1a0"))
    _sign(Vector2(5968,132),"熔炉检修 · 用同一箱 TNT 开桥与爆破","搬运时不能战斗 · 暂停菜单可重置")
    _sign(Vector2(7104,116),"外堡已破 · 守军退往灵魂门","前方空地夹击 · 先在路标整备")
    _sign(Vector2(9360,112),"断桥在前 · 看清落点再跳","前方两道裂隙 · 高台面包可先取")
    _sign(Vector2(13088,128),"守军已退 · 灵魂前哨就在前方","收集最后补给，准备迎接凋灵")
    if not campaign_arena: _sign(Vector2(13712,212),"灵魂前哨 →","本次路线终点 · 凋灵 Boss 后续开放")
