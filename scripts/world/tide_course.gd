class_name TideCourse
extends "res://scripts/world/spiderwood_course.gd"
const WIDTH:=8800.0
const ARENA_LEFT:=7520.0
const ARENA_RIGHT:=8480.0
const TIDE_LAND: Array[Rect2]=[Rect2(-32,0,32,512),Rect2(WIDTH,0,32,512),Rect2(0,288,1920,224),Rect2(2016,288,1568,224),Rect2(3680,288,1472,224),Rect2(5408,288,3392,224)]
const TIDE_WOOD: Array[Rect2]=[Rect2(1248,224,176,12),Rect2(3296,224,176,12),Rect2(4384,224,144,12),Rect2(6016,224,112,12),Rect2(7376,224,128,12)]
const TIDE_SEGMENTS: Array[Dictionary]=[{"x":0,"name":"潮岸武库"},{"x":900,"name":"溺尸投手"},{"x":1664,"name":"退潮石阶"},{"x":2304,"name":"潮纹长廊"},{"x":3520,"name":"断堤跳跃"},{"x":4608,"name":"沉桥闸口"},{"x":6144,"name":"雷鸣守门战"},{"x":6976,"name":"神殿前哨"},{"x":7520,"name":"潮汐神殿"},{"x":8480,"name":"遗迹出口"}]
var sentry_gate: StageGate
var jets: Array[TideJet]=[]
var bridge_target: ArrowSwitch
var bridge: StaticBody2D
var bridge_fraction:=0.0

func _ready() -> void:
    process_physics_priority=5
    var level:=get_parent().get_parent()
    for rect in TIDE_LAND: _add_collision(rect,false)
    for rect in TIDE_WOOD: _add_collision(rect,true)
    for x in [1700,4110]:
        var jet:=TideJet.new()
        jet.level=level
        jet.position=Vector2(x,288)
        add_child(jet)
        jets.append(jet)
    bridge_target=ArrowSwitch.new()
    bridge_target.switch_id=&"tide_bridge"
    bridge_target.position=Vector2(5120,258)
    bridge_target.ui_font=ui_font
    add_child(bridge_target)
    bridge_target.activated.connect(func() -> void:
        level.toast="沉桥升起 · 等桥面完全亮起再通过"
        level.toast_left=4)
    bridge=StaticBody2D.new()
    bridge.position=Vector2(5280,294)
    bridge.collision_layer=0
    bridge.collision_mask=0
    var collision:=CollisionShape2D.new()
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(256,12)
    collision.shape=shape
    bridge.add_child(collision)
    add_child(bridge)
    sentry_gate=_gate(6976)
    entrance=_gate(ARENA_LEFT)
    exit_gate=_gate(ARENA_RIGHT)

func _gate(x: float) -> StageGate:
    var gate:=StageGate.new()
    gate.position=Vector2(x,288)
    add_child(gate)
    gate.set_closed(true)
    return gate

func _physics_process(delta: float) -> void:
    var level:=get_parent().get_parent()
    if level.defeated or level.completed: return
    bridge_fraction=move_toward(bridge_fraction,1 if bridge_target.active else 0,delta/0.7)
    bridge.collision_layer=1 if bridge_fraction>=1 else 0
    var sentries_cleared: bool=level.targets.slice(0,18).all(func(e: RemixEnemy) -> bool: return e.health.current<=0)
    sentry_gate.set_closed(not (sentries_cleared and level.checkpoint_index>=3 and bridge_target.active))
    exit_gate.set_closed(not (level.guardian.health.current<=0 and level.checkpoint_index==4))
    level.check_environment()

func mechanism_state() -> Dictionary: return {"tide_bridge":bridge_target.active}
func restore_mechanisms(state: Dictionary) -> void:
    bridge_target.set_active(state.get("tide_bridge",false))
    bridge_fraction=1.0 if bridge_target.active else 0.0
    bridge.set_deferred("collision_layer",1 if bridge_target.active else 0)
    for jet in jets: jet.reset_cycle()

func _draw() -> void:
    var level:=get_parent().get_parent()
    if not level.is_node_ready(): return
    var view_x: float=level.camera.position.x
    var visible:=Rect2(Vector2(view_x-get_viewport_rect().size.x*0.5-30,-200),get_viewport_rect().size+Vector2(60,400))
    for rect in TIDE_LAND:
        if rect.size.y>=400 or not visible.intersects(rect): continue
        var clip:=rect.intersection(visible)
        draw_rect(clip,Color("213e46"))
        for y in range(288,384,16):
            for x in range(maxi(int(rect.position.x),floori(visible.position.x/32)*32),mini(int(rect.end.x),int(visible.end.x)+32),32):
                draw_rect(Rect2(x+1,y+1,30,14),Color("3c686a") if posmod(x/32+y/16,3)==0 else Color("345559"))
                draw_rect(Rect2(x+4,y+3,12,2),Color("698b81"))
                if posmod(x/32,5)==0: draw_rect(Rect2(x+21,y+8,4,4),Color("558a72"))
        draw_rect(Rect2(clip.position,Vector2(clip.size.x,4)),Color("c5d9ae"))
        draw_rect(Rect2(clip.position+Vector2(0,4),Vector2(clip.size.x,3)),Color("678f7f"))
    for rect in TIDE_WOOD:
        if visible.intersects(rect): _wood(rect,true)
    for span in [Vector2(1920,96),Vector2(3584,96),Vector2(5152,256)]:
        if absf(view_x-span.x)>550: continue
        draw_rect(Rect2(span.x,335,span.y,85),Color("163e54"))
        for n in 8:
            draw_rect(Rect2(span.x+fposmod(seconds*20+n*23,span.y-12),340+n%4*11,12,2),Color("72b2b1"))
        for x in [span.x-8,span.x+span.y+3]: draw_rect(Rect2(x,272,5,16),Color("f0d593"))
    if bridge_fraction>0: _wood(Rect2(5152,288,256*bridge_fraction,12),bridge_fraction>=1)
    for x in range(580,6900,576):
        if absf(x-view_x)>360: continue
        draw_rect(Rect2(x,150,14,138),Color("294a53"))
        draw_rect(Rect2(x+2,151,3,136),Color("547777"))
        for y in range(158,278,20): draw_rect(Rect2(x+6,y,6,2),Color("1c3543"))
        draw_rect(Rect2(x-3,148,20,5),Color("839e85"))
        draw_line(Vector2(x+7,155),Vector2(x+27,172),Color("968a64"),1)
        draw_rect(Rect2(x+23,172,9,13),Color("453f35"))
        draw_rect(Rect2(x+25,175,5,7),Color("efc982"))
    _plaque(Vector2(114,149),"04 · 潮汐遗迹","E 武器架领取三叉戟 · 木靶安全试用",view_x)
    _plaque(Vector2(886,135),"看预警，闪投戟","投掷前锁定方向 · 跳跃或打断",view_x)
    _plaque(Vector2(1596,144),"喷涌水道","金色水花是预警 · 等退潮再过",view_x)
    _plaque(Vector2(4936,145),"沉桥闸口","投戟 / 射箭命中靶点 · E 也可开闸",view_x)
    _plaque(Vector2(6280,142),"雷鸣守门战","多目标同时落雷 · 留意后排投手",view_x)
    _plaque(Vector2(7048,134),"神殿补给 · 前方 Boss","苹果回血 · 高处面包 · E 换装",view_x)
    if not level.arena_active:
        _plaque(Vector2(7670,156),"潮汐神殿","光束跳开 · 潮汐进绿框 · 棘刺退红圈",view_x)
    for x in range(7576,8450,64):
        if absf(x-view_x)>360: continue
        draw_rect(Rect2(x,282,22,4),Color("6fbab4"))
        draw_rect(Rect2(x+7,273,8,8),Color("416d6a"))
    for i in range(1,level.checkpoint_specs().size()):
        var spec: Dictionary=level.checkpoint_specs()[i]
        if absf(spec.x-view_x)>360: continue
        draw_rect(Rect2(spec.x-2,247,4,41),Color("978767"))
        draw_rect(Rect2(spec.x+2,247,25,14),Color("89d4c2") if level.checkpoint_index>=i else Color("62777d"))
        _plaque(Vector2(spec.x-48,180),spec.label,"已保存" if level.checkpoint_index>=i else "清除前段记录 · 不回血",view_x)
    if absf(8672-view_x)<370:
        draw_rect(Rect2(8640,170,64,118),Color("718f85"))
        draw_rect(Rect2(8648,178,48,110),Color("163440"))
        draw_rect(Rect2(8655,186,34,102),Color("68b7b4"))
        draw_string(ui_font,Vector2(8642,165),"远征完成",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("eff1cd"))
