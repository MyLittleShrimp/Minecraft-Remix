class_name EnderStrikeFX
extends RefCounted
## State-driven pixels: no full hitbox fill, no additional damage or timers.
static func bounds(reach: float,facing: int) -> Rect2:
    return Rect2(0 if facing>0 else -reach,-54,reach,48)

static func warning(canvas: CanvasItem,reach: float,facing: int,left: float,at:=Vector2.ZERO,elite:=false) -> void:
    canvas.draw_set_transform(at.round(),0,Vector2(facing,1))
    var pulse:=0.5+0.5*sin(left*24.0)
    var edge:=Color(1.0,0.57,0.55,0.65+pulse*0.25)
    # Four small corners and sparse edge ticks show the exact rectangular limits.
    for x in [0.0,reach]:
        var inward:=1.0 if x==0 else -1.0
        for y in [-54.0,-6.0]:
            canvas.draw_line(Vector2(x,y),Vector2(x+inward*7,y),edge,1)
            canvas.draw_line(Vector2(x,y),Vector2(x,y+(5 if y==-54 else -5)),edge,1)
    for x in range(12,int(reach)-8,12):
        canvas.draw_line(Vector2(x,-6),Vector2(x+4,-6),Color(edge,0.42),1)
    var tint:=Color("d38cff") if elite else Color("b798f4")
    # Gathering motes converge toward the fist while the existing countdown runs.
    for i in 5:
        var phase:=fposmod(left*1.8+i*0.2,1.0)
        var p:=Vector2(12+phase*15,-34+sin(i*2.4)*phase*12).round()
        canvas.draw_rect(Rect2(p,Vector2(2,2)),Color(tint,(1-phase)*0.8))
    var tip:=Vector2(reach,-30)
    canvas.draw_polyline(PackedVector2Array([tip+Vector2(-3,-5),tip,tip+Vector2(-3,5)]),Color(edge,0.65),1)
    canvas.draw_set_transform(Vector2.ZERO)

static func strike(canvas: CanvasItem,reach: float,facing: int,left: float,elite:=false) -> void:
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    var age:=clampf(1.0-left/0.18,0,1)
    var fade:=1-age
    var tint:=Color("d896ff") if elite else Color("b3a0fa")
    var sweep:=lerpf(0.42,0.96,sqrt(age))
    # Tapered crescent: its nose reaches the real limit, its tail stays at the fist.
    for trail in 3:
        var outer:=PackedVector2Array()
        var inner:=PackedVector2Array()
        var distance:=reach*maxf(0.12,sweep-trail*0.17)
        for i in 13:
            var t:=float(i)/12
            var arc:=sin(t*PI)
            outer.append(Vector2(10+(distance-10)*arc,-52+t*44).round())
            inner.append(Vector2(10+maxf(0,distance-15-trail*2)*arc,-52+t*44).round())
        var shape:=outer.duplicate()
        inner.reverse()
        shape.append_array(inner)
        canvas.draw_colored_polygon(shape,Color(tint,fade*(0.65-trail*0.17)))
        if trail==0: canvas.draw_polyline(outer,Color("fff0ff")*Color(1,1,1,fade),1)
    for i in 7:
        var start:=Vector2(reach*(0.35+0.08*i),-46+fposmod(i*13,35))
        var p: Vector2=(start+Vector2(age*8,sin(i*2.0)*age*7)).round()
        canvas.draw_line(p-Vector2(3+3*fade,0),p,Color(tint,fade*0.75),1)
    # The far edge flashes once so the soft crescent never understates range.
    for y in [-50,-30,-10]:
        var p:=Vector2(reach,y)
        canvas.draw_polyline(PackedVector2Array([p+Vector2(-3,-3),p,p+Vector2(-3,3)]),Color("ffe0ed")*Color(1,1,1,fade),1)
    canvas.draw_set_transform(Vector2.ZERO)
