extends Node2D
## Generated key poses; danger markers still follow authoritative combat state.
var animation_frame:=0
func silhouette(at: Vector2,tint: Color,_pose: float,facing: int) -> void:
    WarpedArt.draw_actor(self,"enderman",7,facing,tint,at)

func _draw() -> void:
    var actor:=get_parent() as EndermanEnemy
    if actor.state==RemixEnemy.State.DEAD: return
    var tint:=Color(1.7,1.5,1.9) if actor.flash_left>0 else Color.WHITE
    animation_frame=WarpedArt.enderman_pose(actor)
    WarpedArt.draw_actor(self,"enderman",animation_frame,actor.facing,tint)
    for i in 6:
        var at:=Vector2(-24+posmod(i*17,48),-8-fposmod(actor.steps*3+i*13,64))
        draw_rect(Rect2(at,Vector2(2,2)),Color("a66aca"))
    var high:=actor.global_position.y<205
    var bar_y:=10 if high else -75
    draw_rect(Rect2(-19,bar_y,38,3),Color("291e36"))
    draw_rect(Rect2(-19,bar_y,38.0*actor.health.current/actor.health.max_health,3),Color("bf87e2"))
    var label: String="末影人" if actor.provoked else ("封印守卫 · 待入场" if actor.guard_mode else "末影人 · 中立")
    draw_string(actor.ui_font,Vector2(-26,26 if high else -81),label,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e2c9f3"))
    if not actor.encounter_enabled:
        draw_rect(Rect2(-22,-68,44,68),Color("8470a5"),false,1)
        draw_line(Vector2(-16,-9),Vector2(16,-9),Color("c3a4e1"),2)
    if actor.warp_left>=0:
        var at:=actor.warp_to-actor.global_position
        silhouette(at,Color(1.8,1.3,2.0,0.45),0,actor.facing)
        draw_rect(Rect2(at+Vector2(-24,-65),Vector2(48,65)),Color("c985ff"),false,1)
        draw_line(at+Vector2(-24,-2),at+Vector2(24,-2),Color("e4a9ff"),3)
        draw_string(actor.ui_font,at+Vector2(-30,20 if actor.warp_to.y<205 else -70),"落点 %.1f"%actor.warp_left,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f1d3ff"))
    if actor.state==RemixEnemy.State.AIM or actor.strike_flash>0:
        if actor.strike_flash>0:
            EnderStrikeFX.strike(self,actor.REACH,actor.facing,actor.strike_flash)
        else:
            EnderStrikeFX.warning(self,actor.REACH,actor.facing,actor.state_left)
        if actor.state==RemixEnemy.State.AIM:
            draw_string(actor.ui_font,Vector2(-25,39 if high else -91),"挥击 %.1f"%actor.state_left,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd19e"))
