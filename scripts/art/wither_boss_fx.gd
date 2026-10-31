class_name WitherBossFX
extends RefCounted
## Deterministic pixel effects. Visual tails never add hidden damage areas.
static func back(canvas: Node2D,boss: WitherBoss) -> void:
    for ghost in boss.ghosts:
        WitherBossArt.draw_pose(canvas,6,int(ghost.facing),Color(0.71,0.39,1,float(ghost.life)*1.7),canvas.to_local(ghost.at),-0.09*int(ghost.facing))
    if boss.battle in [WitherBoss.Battle.DASH_WARNING,WitherBoss.Battle.DASH]:
        lane(canvas,boss)
        if boss.battle==WitherBoss.Battle.DASH_WARNING: charge(canvas,boss)
        else: stream(canvas,boss)
    if boss.battle in [WitherBoss.Battle.MELEE_WARNING,WitherBoss.Battle.MELEE]: sweep(canvas,boss)
    if boss.impact_left>0: impact(canvas,boss)
static func front(canvas: Node2D,boss: WitherBoss) -> void:
    if boss.battle in [WitherBoss.Battle.DASH_WARNING,WitherBoss.Battle.DASH] and boss.dash_pillars==0:
        # A single orbiting rune is the visible one-pillar protection charge.
        var at:=Vector2(0,-43)
        canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-7),at+Vector2(6,0),at+Vector2(0,7),at+Vector2(-6,0)]),Color("ac82ef"))
        canvas.draw_line(at+Vector2(-2,0),at+Vector2(0,3),Color("fff0de"),2)
        canvas.draw_line(at+Vector2(0,3),at+Vector2(3,-3),Color("fff0de"),2)
        for i in 3:
            var angle:=boss.visual_seconds*2+i*TAU/3
            canvas.draw_arc(Vector2.ZERO,43,angle,angle+0.7,7,Color("bca4ffb0"),2)
    if boss.battle==WitherBoss.Battle.MELEE:
        var face:=boss.melee_direction
        var t:=1-boss.timer/0.20
        for i in 5:
            var p:=Vector2(face*(42+t*61-i*7),-18+i*12)
            canvas.draw_rect(Rect2(p.round(),Vector2(4,2)),Color("fff0d6"))
static func lane(canvas: Node2D,boss: WitherBoss) -> void:
    var a:=canvas.to_local(boss.dash_from)
    var b:=canvas.to_local(boss.dash_to)
    var left:=minf(a.x,b.x)-38
    var width:=absf(a.x-b.x)+76
    var warning:=boss.battle==WitherBoss.Battle.DASH_WARNING
    var pulse:=0.55+sin(boss.visual_seconds*14)*0.2
    canvas.draw_rect(Rect2(left,-24,width,48),Color(0.83,0.12,0.27,0.045 if warning else 0.025))
    # Fine broken borders keep the exact jump clearance legible without a bar.
    for x in range(int(left),int(left+width),12):
        for y in [-24,24]:
            canvas.draw_line(Vector2(x,y),Vector2(minf(x+7,left+width),y),Color(1,0.35,0.43,pulse),1)
    for x in range(int(left)+12,int(left+width)-14,32):
        var at:=Vector2(x,18)
        canvas.draw_polyline(PackedVector2Array([at+Vector2(-boss.dash_direction*4,-3),at+Vector2(boss.dash_direction*3,0),at+Vector2(-boss.dash_direction*4,3)]),Color("f4bfa3"),1)
    if warning:
        var at:=Vector2(left+width*(1-boss.timer/1.1),24)
        if boss.dash_direction<0: at.x=left+width*boss.timer/1.1
        canvas.draw_rect(Rect2(at-Vector2(2,1),Vector2(4,3)),Color("fff3c9"))
static func charge(canvas: Node2D,boss: WitherBoss) -> void:
    EnemyVfxArt.wither_charge(canvas,boss.timer)
    var t:=clampf(1-boss.timer/1.1,0,1)
    for i in 3:
        var r:=48-i*7-t*9
        var angle:=boss.visual_seconds*(2+i*0.5)+i*1.2
        canvas.draw_arc(Vector2.ZERO,r,angle,angle+PI*1.2,20,Color(0.68,0.35,1,0.13+i*0.08),2)
    for i in 16:
        var angle:=i*TAU/16+sin(float(i)*4)*0.16
        var distance:=fposmod(i*13+boss.timer*90,48)+16
        var point:=Vector2(cos(angle)*distance,sin(angle)*distance*0.65).round()
        canvas.draw_rect(Rect2(point,Vector2(2,2)),Color("debeff") if i%3==0 else Color("9366d5"))
    for side in [-1,1]:
        var points:=PackedVector2Array()
        for i in 6: points.append(Vector2(side*(22+i*4+sin(boss.visual_seconds*20+i)*3),-21+i*8).round())
        canvas.draw_polyline(points,Color(0.86,0.65,1,0.4+t*0.5),1)
static func stream(canvas: Node2D,boss: WitherBoss) -> void:
    EnemyVfxArt.wither_stream(canvas,boss.visual_seconds,boss.dash_direction)
    for lane_index in 3:
        var points:=PackedVector2Array()
        for i in 9:
            points.append(Vector2(-boss.dash_direction*(12+i*9),-16+lane_index*16+sin(i*1.7-boss.visual_seconds*36)*3).round())
        canvas.draw_polyline(points,Color(0.47,0.22,0.81,0.15),5)
        canvas.draw_polyline(points,Color("aa78eb90"),1)
        if lane_index==1: canvas.draw_polyline(points,Color("e6d4ff"),1)
    for i in 14:
        var travel:=fposmod(boss.visual_seconds*260+i*11,100)
        var at:=Vector2(-boss.dash_direction*(travel+14),-28+posmod(i*17,54)).round()
        canvas.draw_rect(Rect2(at,Vector2(2+posmod(i,3),2)),Color("d7b2f7") if i%3==0 else Color("8052ad"))
    var dir:=boss.dash_direction
    canvas.draw_polyline(PackedVector2Array([Vector2(dir*27,-23),Vector2(dir*41,-8),Vector2(dir*44,0),Vector2(dir*41,8),Vector2(dir*27,23)]),Color("b274f588"),5)
    canvas.draw_polyline(PackedVector2Array([Vector2(dir*31,-20),Vector2(dir*41,0),Vector2(dir*31,20)]),Color("f0d9ff"),2)
static func sweep(canvas: Node2D,boss: WitherBoss) -> void:
    var rect:=boss.melee_rect()
    rect.position-=boss.global_position
    var face:=boss.melee_direction
    var warning:=boss.battle==WitherBoss.Battle.MELEE_WARNING
    # Corner strokes match the actual forward-only rectangle, the curved soul
    # ribbons read as the attack, and the back side remains visually clear.
    for y in [rect.position.y,rect.end.y]:
        canvas.draw_line(Vector2(face*16,y),Vector2(face*30,y),Color("ff9f89"),1)
        canvas.draw_line(Vector2(face*98,y),Vector2(face*112,y),Color("ff9f89"),1)
    var count:=1 if warning else 3
    for band in count:
        var points:=PackedVector2Array()
        var radius: float=92 if warning else 90-(1-boss.timer/0.20)*-10-band*13
        for i in 19:
            var angle: float=-1.2+i*2.4/18
            points.append(Vector2(face*(12+cos(angle)*radius),4+sin(angle)*29).round())
        var accent:=Color("ecb7ff") if boss.second_phase else Color("a9eee0")
        canvas.draw_polyline(points,Color(1,0.34,0.35,0.55) if warning else Color(accent,0.22),2 if warning else 8)
        if not warning:
            canvas.draw_polyline(points,accent,3)
            canvas.draw_polyline(points,Color("fff2d1"),1)
    if warning:
        for i in 6:
            var at:=Vector2(face*(24+i*13),4+sin(boss.visual_seconds*15+i)*8).round()
            canvas.draw_rect(Rect2(at,Vector2(2,2)),Color("f5bc95"))
static func impact(canvas: Node2D,boss: WitherBoss) -> void:
    var at:=canvas.to_local(boss.impact_at)
    EnemyVfxArt.wither_burst(canvas,at,boss.impact_left,boss.second_phase)
    var t:=1-boss.impact_left/0.42
    canvas.draw_arc(at,8+t*36,PI,TAU,18,Color(0.94,0.78,1,1-t),2)
    for i in 12:
        var speed:=24+posmod(i*13,40)
        var angle: float=PI+i*PI/11
        var offset:=Vector2(cos(angle)*speed*t,sin(angle)*speed*t+18*t*t).round()
        canvas.draw_rect(Rect2(at+offset,Vector2(3+posmod(i,3),3)),Color(Color("b9adbf") if i%2==0 else Color("9867d5"),1-t))
