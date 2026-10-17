extends "res://scripts/enemies/enderman_visual.gd"

func silhouette(at: Vector2,tint: Color,_pose: float,facing: int) -> void:
    var elite:=get_parent() as EndermanElite
    WarpedArt.draw_actor(self,"rift-warden",4 if elite.second_phase else 0,facing,tint,at)

func _draw() -> void:
    var actor:=get_parent() as EndermanElite
    if actor.state==RemixEnemy.State.DEAD: return
    var tint:=Color(1.7,1.5,1.9) if actor.flash_left>0 else Color.WHITE
    animation_frame=WarpedArt.warden_pose(actor)
    if actor.second_phase:
        draw_arc(Vector2(0,-35),39,0,TAU,32,Color(0.79,0.4,1,0.40),1)
    WarpedArt.draw_actor(self,"rift-warden",animation_frame,actor.facing,tint)
    for i in 7:
        draw_rect(Rect2(-27+posmod(i*19,54),-7-fposmod(actor.steps*3+i*11,65),2,2),Color("b67ede"))
    if not actor.encounter_enabled:
        draw_rect(Rect2(-24,-70,48,70),Color("a68abb"),false,1)
        draw_string(actor.ui_font,Vector2(-32,-80),"裂隙守门者",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ead3ff"))
    if actor.warp_left>=0:
        var at:=actor.warp_to-actor.position
        var color:=Color("edb4ff")
        silhouette(at,Color(1.8,1.3,2.0,0.55),0,actor.locked_facing)
        draw_rect(Rect2(at+Vector2(-24,-67),Vector2(48,67)),color,false,2)
        EnderStrikeFX.warning(self,actor.attack_reach,actor.locked_facing,actor.warp_left,at,true)
        draw_string(actor.ui_font,at+Vector2(-28,-73),"真身 %.1f"%actor.warp_left,HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
        if actor.decoy.is_finite():
            var fake:=actor.decoy-actor.position
            silhouette(fake,Color(1.2,1.1,1.3,0.25),0,-actor.locked_facing)
            for y in range(-64,0,12):
                draw_line(fake+Vector2(-24,y),fake+Vector2(-24,y+5),Color("87748e"),1)
                draw_line(fake+Vector2(24,y),fake+Vector2(24,y+5),Color("87748e"),1)
            draw_string(actor.ui_font,fake+Vector2(-22,-73),"残影",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ac9db5"))
    if actor.state==RemixEnemy.State.AIM or actor.strike_flash>0:
        if actor.strike_flash>0:
            EnderStrikeFX.strike(self,actor.attack_reach,actor.facing,actor.strike_flash,true)
        else:
            EnderStrikeFX.warning(self,actor.attack_reach,actor.facing,actor.state_left,Vector2.ZERO,true)
        if actor.state==RemixEnemy.State.AIM:
            draw_string(actor.ui_font,Vector2(-26,-79),"挥击 %.1f"%actor.state_left,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd4af"))
