extends Node2D
func _draw() -> void:
    var actor:=get_parent() as VindicatorEnemy
    if actor.state==RemixEnemy.State.DEAD: return
    var frame:=1+int(actor.steps)%2 if absf(actor.velocity.x)>2 else 0
    if actor.state==RemixEnemy.State.AIM: frame=3
    elif actor.swing_flash>0: frame=4
    elif actor.state==RemixEnemy.State.RECOVER: frame=5
    MineArt.actor(self,frame,actor.facing,Color("ffe5ba") if actor.flash_left>0 else Color.WHITE)
    draw_rect(Rect2(-17,-63,34,3),Color("1b262b"))
    draw_rect(Rect2(-17,-63,34.0*actor.health.current/actor.health.max_health,3),Color("edaa6e"))
    draw_string(actor.ui_font,Vector2(-17,-67),"卫道士",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f3dfbe"))
    if actor.state==RemixEnemy.State.AIM:
        var origin:=Vector2(0,-2)
        var end:=Vector2(actor.facing*VindicatorEnemy.REACH,-2)
        draw_line(origin,end,Color("ef9363"),3)
        draw_line(end-Vector2(0,5),end+Vector2(0,3),Color("ffda95"),2)
        draw_string(actor.ui_font,Vector2(-13,-80),"重击！",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd397"))
    elif actor.swing_flash>0:
        draw_arc(Vector2(0,-24),56,-1.0 if actor.facing>0 else PI-1.0,1.0 if actor.facing>0 else PI+1.0,10,Color("ffe3ad"),3)
