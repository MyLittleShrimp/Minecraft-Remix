extends Node2D
func _draw() -> void:
    var actor:=get_parent() as WitherSkeleton
    if actor.state==RemixEnemy.State.DEAD: return
    WitherArt.draw_actor(self,actor)
    draw_rect(Rect2(-20,-72,40,3),Color("1c242c"))
    draw_rect(Rect2(-20,-72,40.0*actor.health.current/actor.health.max_health,3),Color("c6a777"))
    draw_string(actor.ui_font,Vector2(-24,-77),"凋灵骷髅",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("edddbc"))
    if not actor.active:
        draw_string(actor.ui_font,Vector2(-20,-88),"未入战",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("9e9ba1"))
        return
    draw_set_transform(Vector2.ZERO,0,Vector2(actor.facing,1))
    if actor.state==RemixEnemy.State.AIM:
        var progress:=1.0-clampf(actor.state_left/actor.data.aim_seconds,0,1)
        var color:=Color("ff9b77").lerp(Color("ffe2a3"),progress)
        # Ground ticks show the actual 72px range; no opaque hitbox rectangle.
        for x in range(8,73,8): draw_line(Vector2(x,-1),Vector2(x,-4),Color(color,0.6),1)
        draw_line(Vector2(0,-2),Vector2(WitherSkeleton.REACH*progress,-2),color,2)
        draw_line(Vector2(72,-8),Vector2(72,0),color,2)
        draw_line(Vector2(68,-5),Vector2(72,-8),color,1)
        draw_arc(Vector2(2,-27),22,-2.4,-2.4+progress*2.8,10,Color(color,0.8),2)
    if actor.swing_flash>0:
        var alpha:=clampf(actor.swing_flash/0.22,0,1)
        for layer in 3:
            var points:=PackedVector2Array()
            for i in 15:
                var t: float=-PI*0.5+i*PI/14.0
                points.append(Vector2(cos(t)*(72-layer*5),-22+sin(t)*22))
            draw_polyline(points,Color(Color("fff0c7").lerp(Color("c8926b"),layer/2.0),alpha*(1-layer*0.25)),2)
        for i in 6:
            var x: float=30+i*7+(1-alpha)*12
            draw_line(Vector2(x,-34+i*5),Vector2(x+5,-36+i*5),Color("e2c791",alpha),1)
    draw_set_transform(Vector2.ZERO)
    if actor.state==RemixEnemy.State.AIM:
        draw_string(actor.ui_font,Vector2(-26,-90),"长剑蓄力！",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd59a"))
    elif actor.state==RemixEnemy.State.RECOVER and actor.swing_flash<=0 and actor.strikes>0:
        draw_string(actor.ui_font,Vector2(-22,-89),"反击窗口",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("b5e2c0"))
