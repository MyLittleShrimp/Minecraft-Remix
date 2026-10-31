extends Node2D
## Generated key poses; danger markers still follow authoritative combat state.
var animation_frame:=0
var residue_left := 0.0
var observed_teleports := -1
var previous_position := Vector2.ZERO
var departure := Vector2.ZERO

func _process(delta: float) -> void:
    var actor := get_parent() as EndermanEnemy
    residue_left=maxf(0,residue_left-delta)
    if observed_teleports>=0 and actor.teleports>observed_teleports:
        departure=previous_position
        residue_left=0.24
    elif actor.teleports<observed_teleports or actor.state==RemixEnemy.State.DEAD:
        residue_left=0
    observed_teleports=actor.teleports
    previous_position=actor.global_position
    queue_redraw()

func warp_residue(actor: EndermanEnemy) -> void:
    if residue_left<=0: return
    var alpha := residue_left/0.24*0.65
    EnemyVfxArt.warp(self,to_local(departure),0.24-residue_left,alpha*0.5)
    EnemyVfxArt.warp(self,Vector2.ZERO,0.24-residue_left,alpha)
func silhouette(at: Vector2,tint: Color,_pose: float,facing: int) -> void:
    WarpedArt.draw_actor(self,"enderman",7,facing,tint,at)

func _draw() -> void:
    var actor:=get_parent() as EndermanEnemy
    if actor.state==RemixEnemy.State.DEAD: return
    warp_residue(actor)
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
        EnemyVfxArt.warp(self,Vector2.ZERO,actor.warp_left,0.28)
        EnemyVfxArt.warp(self,at,actor.warp_left)
        silhouette(at,Color(1.8,1.3,2.0,0.45),0,actor.facing)
        EnemyVfxArt.warp_marker(self,at,actor.warp_left)
        draw_string(actor.ui_font,at+Vector2(-30,20 if actor.warp_to.y<205 else -70),"落点 %.1f"%actor.warp_left,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f1d3ff"))
    if actor.state==RemixEnemy.State.AIM or actor.strike_flash>0:
        if actor.strike_flash>0:
            EnderStrikeFX.strike(self,actor.REACH,actor.facing,actor.strike_flash)
        else:
            EnderStrikeFX.warning(self,actor.REACH,actor.facing,actor.state_left)
        if actor.state==RemixEnemy.State.AIM:
            draw_string(actor.ui_font,Vector2(-25,39 if high else -91),"挥击 %.1f"%actor.state_left,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd19e"))
