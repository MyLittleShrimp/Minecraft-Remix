class_name WarpedCourse
extends "res://scripts/world/movement_course.gd"
const WIDTH:=10368.0
const ROOMS: Array[Vector2]=[Vector2(512,1152),Vector2(2560,3200),Vector2(4096,4736),Vector2(5952,6592),Vector2(8256,8896),Vector2(9408,10048)]
const LAND: Array[Rect2]=[Rect2(0,288,3408,224),Rect2(3664,288,1328,224),Rect2(5080,288,2024,224),Rect2(8224,288,2144,224)]
const LEDGES: Array[Rect2]=[Rect2(1776,224,160,12),Rect2(1960,224,112,12),Rect2(2056,160,224,12),Rect2(2784,224,128,12),Rect2(3024,224,128,12),Rect2(9232,224,112,12)]
# Solid, readable landing islands; no one-way drop into an unmarked void.
const PARKOUR_STONES: Array[Rect2]=[Rect2(7184,256,176,256),Rect2(7440,208,176,304),Rect2(7696,240,208,272),Rect2(7984,256,160,256)]
const PARKOUR_GAPS: Array[Vector2]=[Vector2(7104,80),Vector2(7360,80),Vector2(7616,80),Vector2(7904,80),Vector2(8144,80)]
const LEVERS: Array[Vector2]=[Vector2(3312,288),Vector2(3380,288)]
var entries: Array[StageGate]=[]
var exits: Array[StageGate]=[]
var switches: Array[ArrowSwitch]=[]
var relic_gate: StageGate
var bridge: StaticBody2D
var bridge_fraction:=0.0
var seconds:=0.0
func _ready() -> void:
    process_physics_priority=5
    for rect in LAND: _add_collision(rect,false)
    for rect in PARKOUR_STONES: _add_collision(rect,false)
    for rect in LEDGES: _add_collision(rect,true)
    _add_collision(Rect2(-32,0,32,512),false)
    _add_collision(Rect2(WIDTH,0,32,512),false)
    for room in ROOMS:
        entries.append(_gate(room.x,false))
        exits.append(_gate(room.y,true))
    relic_gate=_gate(10240,true)
    for i in 2:
        var target:=ArrowSwitch.new()
        target.switch_id=StringName("warped_bridge_%d"%i)
        target.position=Vector2(3392,258 if i==0 else 184)
        target.ui_font=ui_font
        target.inactive_label="下靶" if i==0 else "上靶"
        target.active_label="下靶已亮" if i==0 else "上靶已亮"
        add_child(target)
        switches.append(target)
        target.activated.connect(_switch_changed)
    bridge=StaticBody2D.new()
    bridge.position=Vector2(3536,294)
    bridge.collision_layer=0
    bridge.collision_mask=0
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(256,12)
    var collision:=CollisionShape2D.new()
    collision.shape=shape
    bridge.add_child(collision)
    add_child(bridge)
func _gate(x: float,closed: bool) -> StageGate:
    var gate:=StageGate.new()
    gate.position=Vector2(x,288)
    add_child(gate)
    gate.set_closed(closed)
    return gate
func bridge_ready() -> bool: return switches.all(func(s: ArrowSwitch) -> bool: return s.active)
func _switch_changed() -> void:
    var level:=get_parent().get_parent()
    level.toast="双靶已亮 · 等桥面升起再通过" if bridge_ready() else "已点亮一靶 · 还需另一靶"
    level.toast_left=3
func operate_lever(index: int) -> void:
    var event:=DamageEvent.new()
    event.faction=1
    switches[index].receive_projectile(event)
func mechanism_state() -> Dictionary:
    return {"warped_bridge_0":switches[0].active,"warped_bridge_1":switches[1].active}
func restore_mechanisms(saved: Dictionary) -> void:
    for i in 2: switches[i].set_active(saved.get("warped_bridge_%d"%i,false))
    bridge_fraction=1.0 if bridge_ready() else 0.0
    bridge.set_deferred("collision_layer",1 if bridge_ready() else 0)
func _physics_process(delta: float) -> void:
    var level:=get_parent().get_parent()
    if level.defeated or level.completed: return
    seconds+=delta
    bridge_fraction=move_toward(bridge_fraction,1.0 if bridge_ready() else 0.0,delta/0.7)
    bridge.collision_layer=1 if bridge_fraction>=1 else 0
    level.check_environment()
    queue_redraw()
func _wood(rect: Rect2) -> void:
    draw_rect(rect,Color("203438"))
    draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("8cd6b3"))
    for x in range(int(rect.position.x)+4,int(rect.end.x)-5,16):
        draw_rect(Rect2(x,rect.position.y+4,11,6),Color("41645e"))
        draw_rect(Rect2(x+1,rect.position.y+5,8,1),Color("789482"))
        draw_rect(Rect2(x+2,rect.position.y+8,5,1),Color("2d4e4c"))
    for x in [rect.position.x+6,rect.end.x-9]:
        draw_rect(Rect2(x,rect.position.y+4,2,2),Color("c6b285"))
func _plaque(at: Vector2,title: String,subtitle: String,view_x: float) -> void:
    if not get_node("/root/ControlSettings").guide_enabled: return
    if absf(at.x-view_x)>580: return
    var width:=maxf(ui_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x,ui_font.get_string_size(subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x)+20
    draw_rect(Rect2(at-Vector2(8,17),Vector2(width,43)),Color("112d32"))
    draw_rect(Rect2(at-Vector2(8,17),Vector2(width,2)),Color("aeab7d"))
    draw_string(ui_font,at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f2dfad"))
    draw_string(ui_font,at+Vector2(0,17),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("b5d8c5"))
func _draw() -> void:
    var level:=get_parent().get_parent()
    if not level.is_node_ready(): return
    var view_x: float=level.camera.position.x
    var visible:=Rect2(Vector2(view_x-get_viewport_rect().size.x*0.5-30,-200),get_viewport_rect().size+Vector2(60,400))
    for rect in LAND:
        if not visible.intersects(rect): continue
        var clip:=rect.intersection(visible)
        draw_rect(clip,Color("253c40"))
        for x in range(maxi(int(rect.position.x),floori(visible.position.x/32)*32),mini(int(rect.end.x),int(visible.end.x)+32),32):
            for y in range(288,384,16):
                var ash:=x>3700
                draw_rect(Rect2(x+1,y+1,30,14),Color("4b3943") if ash else Color("2e5354"))
                draw_rect(Rect2(x+5,y+4,12,3),Color("77606b") if ash else Color("49786e"))
                var variant:=posmod(int(x/32)+int(y/16)*7,5)
                draw_line(Vector2(x+1,y+14),Vector2(x+30,y+14),Color("302931") if ash else Color("213f41"),1)
                if variant<2:
                    draw_polyline(PackedVector2Array([Vector2(x+23,y+2),Vector2(x+19,y+7),Vector2(x+23,y+10),Vector2(x+20,y+14)]),Color("352b35") if ash else Color("203e42"),1)
                elif variant==3:
                    draw_rect(Rect2(x+23,y+6,3,2),Color("9c775f") if ash else Color("73afa1"))
        draw_rect(Rect2(clip.position,Vector2(clip.size.x,4)),Color("bf9782") if rect.position.x>3600 else Color("77c9af"))
        for x in range(ceili(clip.position.x/24)*24,int(clip.end.x)-12,24):
            if x<3700:
                draw_rect(Rect2(x,292,8,2),Color("467d70"))
                draw_rect(Rect2(x+4,294,3,3),Color("3b6c62"))
            else:
                draw_rect(Rect2(x,292,10,1),Color("8a6d65"))
    for rect in LEDGES:
        if visible.intersects(rect): _wood(rect)
    for rect in PARKOUR_STONES:
        if not visible.intersects(rect): continue
        var clip:=rect.intersection(visible)
        draw_rect(clip,Color("283c46"))
        for y in range(int(rect.position.y),384,16):
            for x in range(int(rect.position.x),int(rect.end.x),32):
                draw_rect(Rect2(x+1,y+1,30,14),Color("4b5360"))
                draw_rect(Rect2(x+5,y+4,15,2),Color("73777d"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),Color("cfb582"))
        for x in [rect.position.x+5,rect.end.x-9]:
            draw_rect(Rect2(x,rect.position.y-7,4,7),Color("f0ce80"))
    if bridge_fraction>0: _wood(Rect2(3408,288,256*bridge_fraction,12))
    for gap in [Vector2(3408,256),Vector2(4992,88)]+PARKOUR_GAPS:
        if absf(gap.x-view_x)>500: continue
        draw_rect(Rect2(gap.x,342,gap.y,50),Color("663642"))
        for i in 8:
            draw_rect(Rect2(gap.x+fposmod(seconds*14+i*29,gap.y-10),348+i%3*8,10,2),Color("d78771"))
        for x in [gap.x-7,gap.x+gap.y+3]: draw_rect(Rect2(x,274,4,14),Color("f0ce80"))
    for i in 2:
        var at:=LEVERS[i]
        if absf(at.x-view_x)>370: continue
        draw_rect(Rect2(at+Vector2(-10,-7),Vector2(20,7)),Color("527073"))
        draw_line(at+Vector2(0,-7),at+Vector2(9 if switches[i].active else -9,-27),Color("e6c57f"),3)
        draw_string(ui_font,at+Vector2(-17,-38),"%s %d"%["已亮" if switches[i].active else "操作",i+1],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("d8dcc0"))
    for i in range(1,level.checkpoint_specs().size()):
        var spec: Dictionary=level.checkpoint_specs()[i]
        if absf(spec.x-view_x)>370: continue
        draw_rect(Rect2(spec.x-2,244,4,44),Color("998f74"))
        draw_rect(Rect2(spec.x+2,244,22,14),Color("8edbb5") if level.checkpoint_index>=i else Color("566d72"))
    _plaque(Vector2(80,164),"05 · 诡异边界 / 正式远征" if level.campaign_mode else "05 · 诡异边界 / 路线试玩",
        "E 换装 · 路标自动保存 · 可退出后继续" if level.campaign_mode else "E 换装 · 本次路标可重试 · 不写远征档",view_x)
    _plaque(Vector2(652,170),"菌林封印","进门唤醒守卫 · 紫框出现后及时移位",view_x)
    _plaque(Vector2(1720,117),"上层可选挑战","中立末影人：击败奖 3 宝石 + 面包",view_x)
    _plaque(Vector2(1960,268),"主路 → 可直接绕过","中立守护者不计通行目标",view_x)
    _plaque(Vector2(2640,143),"双层菌台","高处也会被追击 · 看清瞬移落点",view_x)
    _plaque(Vector2(3252,124),"双靶放桥","射击双靶 / 两杆旁 E 或手柄向上",view_x)
    if level.active_room!=2: _plaque(Vector2(4012,165),"灰烬空域","高空上瞄 / 反弹 · 低空跳攻",view_x)
    _plaque(Vector2(4860,166),"断桥冲刺","留意缺口 · 跳过后再对付地面怪",view_x)
    _plaque(Vector2(5530,155),"残破的路牌","前往堡垒的路，被两只恶魂封锁了",view_x)
    if level.active_room!=3:
        _plaque(Vector2(6028,181),"灰烬双影","两只同时参战 · 看蓄火先后，转身返击",view_x)
    _plaque(Vector2(6670,155),"断垣前哨 · 整备再出发","跳过裂谷，击退残垣上的射手",view_x)
    if level.player.position.x<7104:
        _plaque(Vector2(6980,170),"断垣突围","长按跳远 · 先看箭，再选落脚点",view_x)
    _plaque(Vector2(8952,145),"裂隙前哨 · 整备后迎战","路标不回血 · 苹果 / 高处面包 · E 换装",view_x)
    if level.active_room!=4:
        _plaque(Vector2(8320,166),"烈焰桥头 · 空地夹击","先清地面 · 拉开返击 / 降身近战",view_x)
    if not level.arena_active:
        _plaque(Vector2(9472,157),"裂隙守门者","亮框是真身 · 避开红区，收招时反击",view_x)
    if absf(10160-view_x)<400:
        draw_rect(Rect2(10140,276,40,12),Color("53646b"))
        draw_rect(Rect2(10146,266,28,10),Color("807996"))
        var unlocked: bool=level.elite!=null and level.elite.health.current<=0
        if level.story_pearls==0:
            for i in 3:
                var at:=Vector2(10147+i*13,252+sin(seconds*2+i)*3)
                draw_circle(at,6,Color("79edd7") if unlocked else Color("465467"))
                draw_rect(Rect2(at-Vector2(2,3),Vector2(3,3)),Color("d0fff0") if unlocked else Color("71677f"))
        _plaque(Vector2(10090,177),"珍珠 %d / 3"%level.story_pearls,
            "线索已得 · 向右前进" if level.story_pearls>0 else ("按 E / 手柄↑ 领取" if unlocked else "击败守门者解封"),view_x)
    if absf(10288-view_x)<370:
        draw_rect(Rect2(10280,224,8,64),Color("988b8d"))
        draw_rect(Rect2(10288,224,38,20),Color("77cbb0"))
