class_name DragonEffects
extends RefCounted
## Render-only effects. All dangerous outlines come from the combat rectangles.
const PINK=Color("ff83c0")
const CORE=Color("ffe3ff")
const VIOLET=Color("a16bfa")

static func draw(canvas: Node2D,b: EnderDragon) -> void:
    var t:=b.visual_seconds
    canvas.draw_set_transform(-b.position)
    var mouth:=b.position+Vector2(b.facing*81,8)
    match b.battle:
        EnderDragon.Battle.BREATH_WARNING,EnderDragon.Battle.BREATH:
            var active:=b.battle==EnderDragon.Battle.BREATH
            var r:=b.breath_rect
            boundary(canvas,r,active,t)
            seal(canvas,Vector2(r.get_center().x,r.end.y-3),r.size.x*0.45,t,active)
            charge(canvas,mouth,t,active,24 if b.second_phase else 19)
            if active:
                stream(canvas,mouth,Vector2(r.get_center().x,r.end.y-30),t,b.second_phase)
                for i in 32:
                    var age:=fposmod(t*(0.55+i%4*0.1)+i*0.618,1.0)
                    var x:=r.position.x+8+fposmod(i*43.0+t*7,r.size.x-16)
                    var p:=Vector2(x+sin(t*3+i)*4,r.end.y-5-age*(r.size.y-12))
                    var size:=Vector2(4+i%3*2,10+i%4*3)*(1-age*0.6)
                    canvas.draw_rect(Rect2((p-size/2).round(),size.round()),Color(0.68,0.26,0.96,(1-age)*0.45))
                    if i%3==0: canvas.draw_rect(Rect2(p.round(),Vector2(2,4)),Color(1,0.66,0.94,(1-age)*0.85))
            else:
                for i in 12:
                    var p:=Vector2(r.position.x+12+i*(r.size.x-24)/11,r.end.y-8-absf(sin(t*3+i))*9)
                    canvas.draw_line(p,p+Vector2(0,-4),PINK,1)
        EnderDragon.Battle.BITE_WARNING,EnderDragon.Battle.BITE:
            var active:=b.battle==EnderDragon.Battle.BITE
            var r:=b.bite_rect
            boundary(canvas,r,active,t)
            charge(canvas,mouth,t,active,18)
            if active:
                for i in 5:
                    var x:=r.position.x+14+i*23
                    canvas.draw_colored_polygon(PackedVector2Array([Vector2(x,r.position.y+4),Vector2(x+10,r.position.y+8),Vector2(x+5,r.position.y+31)]),CORE)
                    canvas.draw_line(Vector2(x,r.end.y-3),Vector2(x+8,r.end.y-24),PINK,3)
                canvas.draw_line(Vector2(r.position.x+8,r.get_center().y),Vector2(r.end.x-8,r.get_center().y),Color(0.88,0.5,1,0.65),3)
        EnderDragon.Battle.TAIL_WARNING,EnderDragon.Battle.TAIL:
            var active:=b.battle==EnderDragon.Battle.TAIL
            var r:=b.tail_rect
            boundary(canvas,r,active,t)
            if active:
                var fraction:=clampf(1-b.timer/0.25,0,1)
                for i in 5:
                    var f:=clampf(fraction-float(i)*0.065,0,1)
                    var x:=lerpf(r.position.x+8,r.end.x-8,f if b.facing<0 else 1-f)
                    var points:=PackedVector2Array()
                    for j in 13:
                        var y:=r.position.y+3+j*(r.size.y-6)/12
                        points.append(Vector2(x+sin(float(j)*PI/12)*16*b.facing,y))
                    canvas.draw_polyline(points,Color(1,0.55,0.86,0.7-float(i)*0.12),3 if i==0 else 2)
            else:
                for i in 6: arrow(canvas,Vector2(r.position.x+20+i*30,r.get_center().y),-b.facing,PINK)
        EnderDragon.Battle.DIVE_WARNING,EnderDragon.Battle.DIVE:
            var active:=b.battle==EnderDragon.Battle.DIVE
            var a:=b.dive_from
            var z:=b.dive_to
            var r:=Rect2(minf(a.x,z.x)-46,a.y-17,absf(z.x-a.x)+92,34)
            boundary(canvas,r,active,t)
            for i in 16:
                var p:=Vector2(r.position.x+14+i*(r.size.x-28)/15,r.get_center().y)
                arrow(canvas,p,b.facing,Color(1,0.71,0.86,0.8 if not active else 0.3))
            if active:
                for i in 16:
                    var p:=b.position-Vector2(b.facing*(24+i*8),sin(t*19+i)*12)
                    canvas.draw_line(p,p-Vector2(b.facing*(14+i%3*5),0),Color(0.78,0.36,1,0.65*(1-float(i)/16)),2+i%2)
                for offset in [-15,15]: canvas.draw_line(b.position+Vector2(-b.facing*60,offset),b.position+Vector2(b.facing*44,offset*0.5),CORE,2)
            else: charge(canvas,b.position,t,false,34)
        EnderDragon.Battle.PHASE_CHANGE:
            var age:=clampf(1-b.timer/1.2,0,1)
            for i in 3:
                var radius:=18+fposmod(age+float(i)/3,1)*94
                var color:=Color(0.92,0.36,0.92,(1-(radius-18)/94)*0.65)
                canvas.draw_arc(b.position,radius,0,TAU,48,color,2)
            for i in 16:
                var ray:=Vector2.from_angle(i*TAU/16+age*0.8)
                var near:=b.position+ray*(36+age*20)
                var far:=b.position+ray*(68+age*48)
                canvas.draw_line(near,far,Color(0.88,0.48,1,0.5),2)
                diamond(canvas,far,3,CORE)
    canvas.draw_set_transform(Vector2.ZERO)

static func boundary(canvas: Node2D,r: Rect2,active: bool,t: float) -> void:
    canvas.draw_rect(r,Color(0.72,0.12,0.6,0.13 if active else 0.045))
    var color:=PINK if active else Color(1,0.5,0.7,0.55+0.2*sin(t*7))
    canvas.draw_rect(r,color,false,1)
    canvas.draw_line(Vector2(r.position.x,r.end.y),r.end,CORE if active else PINK,2)
    for x in [r.position.x,r.end.x]:
        var inward:=1 if x==r.position.x else -1
        for y in [r.position.y,r.end.y]:
            canvas.draw_line(Vector2(x,y),Vector2(x+inward*10,y),CORE,2)
    if not active:
        for i in range(8,int(r.size.x)-8,22):
            var p:=Vector2(r.position.x+i,r.end.y-5)
            canvas.draw_line(p,p+Vector2(5,-5),PINK,1)

static func charge(canvas: Node2D,at: Vector2,t: float,active: bool,radius: float) -> void:
    canvas.draw_circle(at,radius,Color(0.74,0.2,1,0.12))
    for i in 2:
        var a:=t*(2 if i==0 else -3)+i*PI
        canvas.draw_arc(at,radius-i*5,a,a+PI*1.4,20,PINK if i==0 else VIOLET,2)
    for i in 6:
        var p:=at+Vector2.from_angle(t*2+i*TAU/6)*(radius+3)
        diamond(canvas,p,2,CORE)
    if active: diamond(canvas,at,7,CORE)

static func stream(canvas: Node2D,a: Vector2,z: Vector2,t: float,rage: bool) -> void:
    # The luminous delivery stream is decoration; only the marked zone damages.
    for layer in 3:
        var points:=PackedVector2Array()
        for i in 21:
            var f:=float(i)/20
            var p:=a.lerp(z,f)+Vector2(sin(f*16-t*9+layer)*8*f,-sin(f*PI)*26)
            points.append(p.round())
        canvas.draw_polyline(points,Color(0.74,0.27,0.98,0.1) if layer==0 else (Color(0.94,0.44,1,0.26) if layer==1 else Color(1,0.83,1,0.65)),(16 if rage else 13) if layer==0 else (6 if layer==1 else 2))

static func seal(canvas: Node2D,at: Vector2,radius: float,t: float,active: bool) -> void:
    for ring in [1.0,0.72]:
        var points:=PackedVector2Array()
        for i in 33:
            var a:=float(i)*TAU/32
            points.append(at+Vector2(cos(a)*radius*ring,sin(a)*9*ring))
        canvas.draw_polyline(points,Color(0.91,0.43,1,0.5 if active else 0.28),1)
    for i in 9:
        var a:=t*0.7+i*TAU/9
        diamond(canvas,at+Vector2(cos(a)*radius*0.85,sin(a)*7),2,PINK)

static func arrow(canvas: Node2D,at: Vector2,direction: int,color: Color) -> void:
    canvas.draw_line(at-Vector2(direction*5,5),at,color,1)
    canvas.draw_line(at-Vector2(direction*5,-5),at,color,1)

static func diamond(canvas: Node2D,at: Vector2,size: float,color: Color) -> void:
    canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-size),at+Vector2(size,0),at+Vector2(0,size),at+Vector2(-size,0)]),color)
