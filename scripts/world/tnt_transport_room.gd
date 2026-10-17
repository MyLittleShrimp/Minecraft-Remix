class_name TNTTransportRoom
extends MineTNT
## One recoverable crate. Only the socket accepts ignition; terrain is immutable.
const SOURCE := Vector2(7544,276)
const PLATE_X := 7896.0
const BRIDGE_GRACE := 6.0
# Defaults preserve the original mine room; chapter-specific courses configure these.
var source_point := SOURCE
var plate_x := PLATE_X
var bridge_start := 8064.0
var bridge_width := 256.0
var lock_x := 8352.0
var bridge_grace := BRIDGE_GRACE
var socket_label_y := 210.0
var crate: CharacterBody2D
var bridge: StaticBody2D
var carried := false
var docked := false
var bridge_latched := false
var bridge_left := 0.0

func level_node() -> Node: return get_parent().get_parent().get_parent()

func _ready() -> void:
    super._ready()
    crate=CharacterBody2D.new()
    crate.collision_layer=0
    crate.collision_mask=3
    var shape:=CollisionShape2D.new()
    var rect:=RectangleShape2D.new()
    rect.size=Vector2(26,24)
    shape.shape=rect
    crate.add_child(shape)
    add_child(crate)
    bridge=StaticBody2D.new()
    bridge.position=Vector2(bridge_start+bridge_width/2,294)
    bridge.collision_mask=0
    shape=CollisionShape2D.new()
    rect=RectangleShape2D.new()
    rect.size=Vector2(bridge_width,12)
    shape.shape=rect
    bridge.add_child(shape)
    add_child(bridge)
    apply_state(false)

func bomb_center() -> Vector2:
    return Vector2(wall_x-38,276)

func can_interact() -> bool:
    if active: return false
    var player: RemixPlayer=level_node().player
    return carried or player.position.distance_to(crate.position+Vector2(0,12))<52 or absf(player.position.x-lever_x)<48

func interact() -> void:
    if active: return
    var level: Node=level_node()
    var player: RemixPlayer=level.player
    if absf(player.position.x-lever_x)<48 and not carried:
        if docked: super.interact()
        else: _hint("先把 TNT 搬到石墙前的金色爆破槽。")
        return
    if fuse_left>0:
        _hint("引信已点燃，先回引爆杆取消。")
        return
    if carried:
        carried=false
        player.carrying_tool=false
        crate.position=player.position+Vector2(player.facing*24,-12)
        if absf(player.position.x-plate_x)<48:
            crate.position=Vector2(plate_x,276)
        elif absf(player.position.x-bomb_center().x)<52:
            docked=true
            crate.position=bomb_center()
        crate.velocity=Vector2.ZERO
        _hint("TNT 已入槽 · 返回引爆杆，点燃后保持距离。" if docked else "已放下 TNT · 空手才能使用武器。")
    elif player.position.distance_to(crate.position+Vector2(0,12))<52:
        carried=true
        docked=false
        player.carrying_tool=true
        level.equipment.suspend_input()
        _hint("正在搬运 · E 放下 · 压板开桥，取回后有 6 秒通过。")

func _hint(message: String) -> void:
    level_node().toast=message
    level_node().toast_left=4

func recover_crate() -> void:
    carried=false
    docked=false
    fuse_left=0
    if is_instance_valid(level_node().player): level_node().player.carrying_tool=false
    crate.position=source_point
    crate.velocity=Vector2.ZERO

func apply_state(open: bool) -> void:
    super.apply_state(open)
    if not is_instance_valid(crate): return
    recover_crate()
    bridge_latched=open
    bridge_left=0
    bridge.collision_layer=1 if open else 0

func _physics_process(delta: float) -> void:
    if not active:
        var player: RemixPlayer=level_node().player
        if carried:
            if player.dead:
                recover_crate()
            else:
                crate.position=player.position+Vector2(player.facing*22,-27)
                crate.velocity=Vector2.ZERO
                if player.position.x>=lock_x and player.is_on_floor(): bridge_latched=true
        elif not docked:
            crate.velocity.y=minf(600,crate.velocity.y+1000*delta)
            crate.move_and_slide()
            if crate.position.y>480:
                recover_crate()
                _hint("TNT 已送回入口补给座，可重新搬运。")
        var pressed: bool=not carried and not docked and absf(crate.position.x-plate_x)<22 and absf(crate.position.y-276)<3
        bridge_left=bridge_grace if pressed else maxf(0,bridge_left-delta)
        bridge.collision_layer=1 if bridge_latched or bridge_left>0 else 0
    super._physics_process(delta)

func _draw() -> void:
    if not is_instance_valid(crate): return
    var gold:=Color("efcb82")
    var teal:=Color("8fdfbf")
    var settings: Node=get_node("/root/ControlSettings")
    var key: String=settings.hint("aim_up") if settings.gamepad_active() else "E"
    draw_rect(Rect2(source_point.x-20,282,40,6),Color("79684e"))
    draw_string(ui_font,Vector2(source_point.x-36,219),key+" 搬起 / 放下",HORIZONTAL_ALIGNMENT_LEFT,-1,10,gold)
    draw_rect(Rect2(plate_x-24,283,48,5),teal if bridge_left>0 else gold)
    draw_line(Vector2(plate_x,286),Vector2(bridge_start,286),Color("a06450"),2)
    if get_node("/root/ControlSettings").guide_enabled: draw_string(ui_font,Vector2(plate_x-60,197),"① 放上 TNT 压住开桥",HORIZONTAL_ALIGNMENT_LEFT,-1,10,gold)
    if get_node("/root/ControlSettings").guide_enabled: draw_string(ui_font,Vector2(plate_x-60,214),"② 取回，6 秒内运过桥",HORIZONTAL_ALIGNMENT_LEFT,-1,10,gold)
    draw_rect(Rect2(bridge_start,344,bridge_width,60),Color("0b1722"))
    var open: bool=bridge_latched or bridge_left>0
    if open:
        draw_rect(Rect2(bridge_start,288,bridge_width,12),Color("6b8584"))
        draw_rect(Rect2(bridge_start,288,bridge_width,3),teal)
        for x in range(int(bridge_start),int(bridge_start+bridge_width),32): draw_rect(Rect2(x+3,292,25,4),Color("314a52"))
    else: draw_line(Vector2(bridge_start,290),Vector2(bridge_start+bridge_width,290),Color("536777"),1)
    for x in [bridge_start-8,bridge_start+bridge_width]: draw_rect(Rect2(x,263,8,25),gold)
    draw_string(ui_font,Vector2(bridge_start+32,232),"桥梁已锁定" if bridge_latched else ("剩余 %.1f 秒"%bridge_left if open else "需要 TNT 压板"),HORIZONTAL_ALIGNMENT_LEFT,-1,11,teal if open else gold)
    draw_rect(Rect2(wall_x-56,281,38,7),gold)
    if get_node("/root/ControlSettings").guide_enabled: draw_string(ui_font,Vector2(wall_x-110,socket_label_y),"③ TNT 放入爆破槽",HORIZONTAL_ALIGNMENT_LEFT,-1,10,gold)
    draw_line(Vector2(lever_x,282),Vector2(wall_x-38,282),Color("773f3d"),2)
    draw_rect(Rect2(lever_x-10,277,20,11),Color("676e69"))
    draw_line(Vector2(lever_x,278),Vector2(lever_x+(7 if fuse_left>0 else -7),261),gold,3)
    draw_string(ui_font,Vector2(lever_x-40,229),key+(" 取消引信" if fuse_left>0 else " 引爆"),HORIZONTAL_ALIGNMENT_LEFT,-1,10,gold)
    if active:
        draw_string(ui_font,Vector2(wall_x-60,248),"爆破完成 · 通路已开",HORIZONTAL_ALIGNMENT_LEFT,-1,10,teal)
        return
    for y in range(64,288,16):
        draw_rect(Rect2(wall_x-16,y,32,15),Color("5e666a"))
        draw_line(Vector2(wall_x+5,y),Vector2(wall_x-3,y+14),Color("272f38"),2)
    var at:=crate.position
    draw_rect(Rect2(at-Vector2(14,13),Vector2(28,26)),Color("3f2b29"))
    draw_rect(Rect2(at-Vector2(13,12),Vector2(26,24)),Color("cf654c") if fuse_left<=0 or int(fuse_left*10)%2==0 else gold)
    for x in [-10,-3,4,11]: draw_rect(Rect2(at+Vector2(x,-11),Vector2(2,22)),Color("9b4439"))
    draw_line(at+Vector2(-11,-11),at+Vector2(10,-11),gold,1)
    draw_line(at+Vector2(0,-13),at+Vector2(3,-17),Color("9c9780"),2)
    draw_rect(Rect2(at-Vector2(13,4),Vector2(26,10)),Color("e7d7af"))
    draw_string(ui_font,at+Vector2(-10,4),"TNT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("422e2d"))
    if docked:
        draw_line(Vector2(at.x-RADIUS,284),Vector2(at.x-RADIUS,267),gold,2)
    if fuse_left>0:
        draw_arc(at,RADIUS,PI,TAU,32,Color(1,0.5,0.25,0.6),2)
        draw_string(ui_font,at+Vector2(-12,-26),"%.1fs"%fuse_left,HORIZONTAL_ALIGNMENT_LEFT,-1,11,gold)
