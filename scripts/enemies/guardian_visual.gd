extends Node2D
var animation_frame:=0
func _physics_process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
    var boss:=get_parent() as ElderGuardian
    var gold:=Color("f3cd78")
    var cyan:=Color("74e5de")
    var origin: Vector2=boss.global_position
    if boss.battle in [ElderGuardian.Battle.TIDE_WARNING,ElderGuardian.Battle.TIDE]:
        var active:=boss.battle==ElderGuardian.Battle.TIDE
        var danger:=Color("ff977a")
        for rect in boss.tide_danger_regions():
            rect.position-=origin
            if active:
                draw_rect(rect,Color(0.85,0.24,0.13,0.38))
                for x in range(int(rect.position.x),int(rect.end.x),16):
                    draw_rect(Rect2(x,rect.position.y+int(boss.visual_seconds*12)%5,8,3),danger)
            else:
                draw_rect(Rect2(rect.position.x,244-origin.y,rect.size.x,40),Color(0.85,0.24,0.13,0.12))
                draw_rect(Rect2(rect.position.x,284-origin.y,rect.size.x,4),danger)
                for x in range(int(rect.position.x),int(rect.end.x),20):
                    draw_line(Vector2(x,280-origin.y),Vector2(x+5,272-origin.y),danger,2)
        var safe: Rect2=boss.safe_zone
        safe.position-=origin
        draw_rect(Rect2(safe.position.x,214-origin.y,safe.size.x,70),Color(0.24,0.9,0.45,0.12))
    if boss.battle in [ElderGuardian.Battle.BEAM_WARNING,ElderGuardian.Battle.BEAM]:
        var a: Vector2=boss.beam_from-origin
        var b: Vector2=boss.beam_to-origin
        if boss.battle==ElderGuardian.Battle.BEAM:
            draw_line(a,b,Color(0.25,0.86,0.85,0.35),14)
            draw_line(a,b,cyan,boss.tuning().beam_width)
            draw_line(a,b,Color("f7fff3"),3)
        else:
            draw_line(a,b,Color(0.9,0.67,0.3,0.2),8)
            draw_dashed_line(a,b,gold,1,8)
    if boss.battle in [ElderGuardian.Battle.BURST_WARNING,ElderGuardian.Battle.BURST]:
        var center:=Vector2(0,-28)
        var radius:=boss.tuning().burst_radius
        var active:=boss.battle==ElderGuardian.Battle.BURST
        var charge:=boss.burst_charge()
        var pulse:=0.5+0.5*sin(charge*TAU*2.5)
        # The outer edge is the actual damage radius from the first tell frame.
        # Only the INNER charge ring expands; it never implies a smaller range.
        draw_circle(center,radius,Color(0.95,0.12,0.16,0.26 if active else 0.12+0.08*pulse))
        draw_arc(center,radius,0,TAU,64,Color("ff4b55"),3)
        if not active:
            draw_arc(center,lerpf(40,radius-5,charge),0,TAU,48,Color(1,0.37,0.38,0.55+charge*0.4),2)
        for i in 16:
            var direction:=Vector2.RIGHT.rotated(i*TAU/16.0)
            var side:=direction.orthogonal()*4
            var tip: float=radius if active else lerpf(58,radius-7,charge)
            var base:=center+direction*(tip-(34 if active else 14))
            draw_colored_polygon(PackedVector2Array([base-side,center+direction*tip,base+side]),Color("ffe3c8") if active else Color("ff7176"))
            draw_line(center+direction*(radius-9),center+direction*radius,Color("ff9a96"),2)
    var pose:=0
    if boss.battle in [ElderGuardian.Battle.BEAM_WARNING,ElderGuardian.Battle.TIDE_WARNING,ElderGuardian.Battle.BURST_WARNING,ElderGuardian.Battle.PHASE_CHANGE]: pose=1
    elif boss.battle in [ElderGuardian.Battle.BEAM,ElderGuardian.Battle.TIDE,ElderGuardian.Battle.BURST]: pose=2
    elif boss.battle in [ElderGuardian.Battle.RECOVER,ElderGuardian.Battle.DEAD]: pose=3
    animation_frame=pose+(4 if boss.second_phase else 0)
    GuardianArt.draw_actor(self,animation_frame,boss.facing,Color(1.6,1.5,1.4) if boss.flash_left>0 else Color.WHITE,boss.health.current<=0)
    if boss.battle in [ElderGuardian.Battle.BURST_WARNING,ElderGuardian.Battle.BURST]:
        var radius:=boss.tuning().burst_radius
        var label:=Rect2(-53,-radius,106,18)
        draw_rect(label,Color("351b24"))
        draw_rect(label,Color("ff4b55"),false,1)
        var message: String=("棘刺 %.1f秒 · 远离" if boss.battle==ElderGuardian.Battle.BURST_WARNING else "危险 %.1f秒 · 勿近") % (ceilf(boss.timer*10)/10)
        draw_string(boss.ui_font,label.position+Vector2(6,13),message,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ffd6cf"))
        # Outward chevrons above the weapon HUD reinforce the retreat direction.
        for side in [-1,1]:
            var at:=Vector2(side*(radius-12),-34)
            draw_polyline(PackedVector2Array([at+Vector2(-side*7,-6),at,at+Vector2(-side*7,6)]),Color("fff1db"),2)
    if boss.battle in [ElderGuardian.Battle.TIDE_WARNING,ElderGuardian.Battle.TIDE]:
        # Draw the upper boundary and label after the large boss sprite, above
        # the foot-level weapon HUD; neither may hide the refuge indicator.
        var mint:=Color("8dffa5")
        var safe: Rect2=boss.safe_zone
        safe.position-=origin
        draw_rect(Rect2(safe.position.x,214-origin.y,safe.size.x,66),mint,false,2)
        var label:=Rect2(safe.get_center().x-39,195-origin.y,78,17)
        draw_rect(label,Color("122d28"))
        draw_string(boss.ui_font,label.position+Vector2(6,12),"避潮安全区",HORIZONTAL_ALIGNMENT_LEFT,-1,11,mint)
    if boss.exposed():
        draw_rect(Rect2(-10,-72,20,3),cyan)
        draw_rect(Rect2(-5,-77,10,3),cyan)
