extends Node2D
func _draw() -> void:
    var actor:=get_parent() as PiglinBrute
    if actor.state==RemixEnemy.State.DEAD: return
    PiglinArt.draw_actor(self,actor)
    var ranged:=actor.stats.role==PiglinData.Role.CROSSBOW
    var color:=Color("edc76d") if not ranged else Color("9bdce5")
    draw_rect(Rect2(-20,-64,40,3),Color("1c242c"))
    draw_rect(Rect2(-20,-64,40.0*actor.health.current/actor.health.max_health,3),color)
    draw_string(actor.ui_font,Vector2(-24,-69),actor.data.label,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("edddbc"))
    var status: String="未入战"
    if actor.active:
        status=""
        if actor.state==RemixEnemy.State.AIM:
            status=("连弩 %d/2"%actor.ammo) if ranged else ("重劈！" if actor.stats.role==PiglinData.Role.AXE else "挥剑！")
        elif actor.state==RemixEnemy.State.RECOVER and actor.strikes>0:
            status="装填中 · 进攻" if ranged else "收招 · 反击"
    if not status.is_empty(): draw_string(actor.ui_font,Vector2(-27,-82),status,HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)
    if not actor.active: return
    if ranged:
        if actor.state==RemixEnemy.State.AIM:
            var p:=1.0-clampf(actor.state_left/actor.aim_duration,0,1)
            var origin:=actor.muzzle()-actor.global_position
            for i in range(0,9):
                draw_line(origin+actor.aim_vector*(12+i*9),origin+actor.aim_vector*(15+i*9),Color("ffb07e",0.35+p*0.5),1)
            draw_circle(origin+actor.aim_vector*96,3,Color("ffd4a0"),false,1)
            draw_line(Vector2(-20,-58),Vector2(-20+40*p,-58),Color("ffb07e"),2)
        elif actor.state==RemixEnemy.State.RECOVER and actor.ammo==0:
            draw_line(Vector2(-20,-58),Vector2(-20+40*(1-clampf(actor.state_left/actor.stats.reload_seconds,0,1)),-58),color,2)
        return
    draw_set_transform(Vector2.ZERO,0,Vector2(actor.facing,1))
    var reach:=actor.stats.reach
    if actor.state==RemixEnemy.State.AIM:
        var p:=1.0-clampf(actor.state_left/actor.aim_duration,0,1)
        for x in range(8,int(reach)+1,8): draw_line(Vector2(x,-1),Vector2(x,-4),Color("ff9b77",0.65),1)
        draw_line(Vector2(0,-2),Vector2(reach*p,-2),Color("ffd69b"),2)
        draw_line(Vector2(reach,-9),Vector2(reach,0),Color("ff9b77"),2)
        draw_arc(Vector2(0,-29),20,-2.5,-2.5+p*2.7,12,Color("ffce8c"),2)
    if actor.swing_flash>0:
        var points:=PackedVector2Array()
        for i in 16:
            var t: float=-PI*0.5+i*PI/15
            points.append(Vector2(cos(t)*reach,-22+sin(t)*22))
        draw_polyline(points,Color("ffe0a4",actor.swing_flash/0.18),3)
    draw_set_transform(Vector2.ZERO)
