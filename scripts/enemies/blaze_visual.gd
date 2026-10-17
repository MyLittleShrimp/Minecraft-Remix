extends Node2D
var animation_frame:=0
func _draw() -> void:
    var actor:=get_parent() as BlazeEnemy
    if actor.health.current<=0: return
    var burning: bool=actor.flight in [BlazeEnemy.Flight.CHARGE,BlazeEnemy.Flight.BURST]
    animation_frame=WarpedArt.blaze_pose(actor)
    WarpedArt.draw_actor(self,"airborne",animation_frame,actor.facing,Color(1.5,1.4,1.2) if actor.flash_left>0 else Color.WHITE)
    for i in 6:
        var at:=Vector2(-16+i*6,-20-fposmod(actor.steps*5+i*11,30))
        draw_rect(Rect2(at,Vector2(3,5)),Color("ffce60") if burning else Color("746253"))
    draw_rect(Rect2(-18,-43,36,3),Color("402a29"))
    draw_rect(Rect2(-18,-43,36.0*actor.health.current/actor.health.max_health,3),Color("eac276"))
    var label: String="烈焰人 · 双火弹" if burning else ("降身冷却 · 近战" if actor.flight==BlazeEnemy.Flight.LOW else "烈焰人")
    draw_string(actor.ui_font,Vector2(-34,-50),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe3a3"))
    if burning:
        draw_arc(Vector2.ZERO,31,-PI/2,-PI/2+TAU*clampf(1-actor.timer/0.9,0,1),20,Color("ffb260"),2)
        if actor.flight==BlazeEnemy.Flight.CHARGE:
            draw_line(Vector2(0,10),actor.mark-actor.position,Color(1,0.55,0.23,0.6),1)
            draw_string(actor.ui_font,Vector2(-25,42),"蓄火 %.1f"%actor.timer,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffcf95"))
