class_name MineCourse
extends "res://scripts/world/spiderwood_course.gd"
const WIDTH:=11008.0
const ARENA_LEFT:=9680.0
const ARENA_RIGHT:=10640.0
const MINE_LAND: Array[Rect2]=[Rect2(-32,0,32,512),Rect2(WIDTH,0,32,512),Rect2(0,288,4096,224),Rect2(4544,288,3520,224),Rect2(8320,288,2688,224)]
# Keep the bread platform outside the entrance; the arena itself stays flat.
const MINE_WOOD: Array[Rect2]=[Rect2(2376,224,224,12),Rect2(3896,224,168,12),Rect2(4960,256,112,12),Rect2(6784,224,224,12),Rect2(9528,224,128,12)]
const MINE_SEGMENTS: Array[Dictionary]=[
    {"x":0,"name":"矿道入口"},{"x":850,"name":"抬斧重击"},{"x":1700,"name":"封堵石墙"},
    {"x":2688,"name":"矿车箭道"},{"x":3900,"name":"悬轨吊台"},{"x":4760,"name":"深矿巡卫"},
    {"x":5568,"name":"掠夺营地"},{"x":7360,"name":"TNT 搬运室"},
    {"x":9312,"name":"斗场前哨"},{"x":ARENA_LEFT,"name":"裂岩采掘厅"}]
var bombs: Array[MineTNT]=[]
var lift: MinePlatform

func _ready() -> void:
    process_physics_priority=5
    for rect in MINE_LAND: _add_collision(rect,false)
    for rect in MINE_WOOD: _add_collision(rect,true)
    for spec in [{"id":"mine_wall_a","wall":1984.0,"lever":1752.0},{"id":"mine_exit_wall","wall":9056.0,"lever":8820.0}]:
        var bomb: MineTNT=MineTNT.new() if spec.id=="mine_wall_a" else TNTTransportRoom.new()
        bomb.mechanism_id=spec.id
        bomb.wall_x=spec.wall
        bomb.lever_x=spec.lever
        bomb.ui_font=ui_font
        add_child(bomb)
        bombs.append(bomb)
    lift=MinePlatform.new()
    add_child(lift)
    entrance=StageGate.new()
    entrance.position=Vector2(ARENA_LEFT,288)
    add_child(entrance)
    entrance.set_closed(true)
    exit_gate=StageGate.new()
    exit_gate.position=Vector2(ARENA_RIGHT,288)
    add_child(exit_gate)
    exit_gate.set_closed(true)
func _physics_process(_delta: float) -> void:
    get_parent().get_parent().check_environment()
func mechanism_state() -> Dictionary:
    var result: Dictionary={}
    for bomb in bombs: result[bomb.mechanism_id]=bomb.active
    return result
func restore_mechanisms(state: Dictionary) -> void:
    for bomb in bombs: bomb.apply_state(state.get(bomb.mechanism_id,false))
    lift.reset_route()

func _draw() -> void:
    var level:=get_parent().get_parent()
    if not level.is_node_ready(): return
    var view_x: float=level.camera.position.x
    var visible:=Rect2(Vector2(view_x-get_viewport_rect().size.x*0.5-30,-200),get_viewport_rect().size+Vector2(60,400))
    for rect in MINE_LAND:
        if rect.size.y>=400 or not visible.intersects(rect): continue
        var clip:=rect.intersection(visible)
        draw_rect(clip,Color("333e48"))
        for y in range(int(rect.position.y),384,16):
            for x in range(maxi(int(rect.position.x),floori(visible.position.x/32)*32),mini(int(rect.end.x),int(visible.end.x)+32),32):
                var w:=minf(31,rect.end.x-x)
                draw_rect(Rect2(x,y,w,15),Color("586773") if posmod(x/32+y/16,3)==0 else Color("495861"))
                draw_rect(Rect2(x+3,y+3,minf(w-4,10),2),Color("74868b"))
                if posmod(x/32+y/16,7)==0: draw_rect(Rect2(x+15,y+6,5,4),Color("b58d5b"))
        draw_rect(Rect2(clip.position,Vector2(clip.size.x,3)),Color("bec0a0"))
        draw_rect(Rect2(clip.position+Vector2(0,3),Vector2(clip.size.x,3)),Color("808d81"))
    for rect in MINE_WOOD:
        if visible.intersects(rect): _wood(rect)
    # Rails are decorative; only the golden platform top is a landing surface.
    for x in range(32,9440,64):
        if absf(x-view_x)>380 or (x>4096 and x<4544) or (x>8064 and x<8320): continue
        draw_rect(Rect2(x,281,24,5),Color("795d43"))
        draw_rect(Rect2(x-20,281,64,2),Color("92a9ad"))
    for x in range(280,9400,448):
        if absf(x-view_x)>380: continue
        draw_rect(Rect2(x,94,8,170),Color("5a493b"))
        draw_rect(Rect2(x+2,96,2,164),Color("aa8354"))
        draw_rect(Rect2(x-37,92,80,9),Color("7d664c"))
        draw_line(Vector2(x+4,102),Vector2(x+4,117),Color("9e976d"),1)
        draw_rect(Rect2(x-1,117,10,15),Color("322c2a"))
        draw_rect(Rect2(x+1,120,6,9),Color("f1bd70"))
    if absf(view_x-4320)<650:
        draw_rect(Rect2(4096,344,448,72),Color("0b1722"))
        draw_line(Vector2(4080,172),Vector2(4560,172),Color("617982"),3)
        for x in [-43,43]: draw_line(Vector2(lift.position.x+x,174),Vector2(lift.position.x+x,lift.position.y-7),Color("b0aa84"),1)
        for x in [4072,4552]:
            draw_rect(Rect2(x,267,8,21),Color("e4bd75"))
    _plaque(Vector2(128,143),"03 · 废弃矿道","武器架换重斧 · 前方木靶可试劈",view_x)
    _plaque(Vector2(834,126),"先闪避，再反击","抬斧会锁定方向 · 收招时有空隙",view_x)
    _plaque(Vector2(1704,158),"引爆教学","操作引爆杆 · 金色标线外更安全",view_x)
    _plaque(Vector2(2360,105),"矿工补给","跳上木台，顶箱拿面包",view_x)
    _plaque(Vector2(3880,109),"悬轨吊台","等吊台靠岸再跳 · 落稳后随台移动",view_x)
    _plaque(Vector2(5700,136),"掠夺营地","先处理远处射手，再对付斧兵",view_x)
    _plaque(Vector2(4936,112),"标记木封板","一记重斧或三次挥剑 · 可选宝石",view_x)
    _plaque(Vector2(7312,155),"TNT 搬运室","E 搬放 · 压板开桥 · 运到爆破槽",view_x)
    for i in range(1,level.checkpoint_specs().size()):
        var spec: Dictionary=level.checkpoint_specs()[i]
        if absf(spec.x-view_x)>360: continue
        draw_rect(Rect2(spec.x-2,247,4,41),Color("978767"))
        draw_rect(Rect2(spec.x+2,247,25,14),Color("89d4c2") if level.checkpoint_index>=i else Color("62777d"))
        _plaque(Vector2(spec.x-48,180),spec.label,"已保存" if level.checkpoint_index>=i else "清除前段后记录 · 不回血",view_x)
    _plaque(Vector2(9384,140),"最后的补给","苹果 +4 · 高台面包 +6",view_x)
    _plaque(Vector2(9920,160),"裂岩采掘厅","跳冲撞 · 回身先预警 · 撞柱后反击",view_x)
    for x in [ARENA_LEFT+6,ARENA_RIGHT-30]:
        if absf(x-view_x)>380: continue
        draw_rect(Rect2(x,217,24,71),Color("293e48"))
        for y in range(220,287,16):
            draw_rect(Rect2(x+2,y,20,13),Color("87908c"))
            draw_rect(Rect2(x+3,y+1,16,2),Color("d3c69f"))
    if absf(10912-view_x)<370:
        draw_rect(Rect2(10880,168,64,120),Color("947553"))
        draw_rect(Rect2(10888,176,48,112),Color("101d25"))
        draw_rect(Rect2(10894,184,36,104),Color("517b7d") if level.cleared_count()==level.targets.size() else Color("273b45"))
        draw_string(ui_font,Vector2(10894,165),"出口",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f3dfba"))
