extends Node2D
var clock := 0.0
var death_time := 0.0
var animation_frame := 0
func _process(delta: float) -> void:
    clock+=delta
    death_time=death_time+delta if get_parent().health.current<=0 else 0.0
    queue_redraw()
func _draw() -> void:
    var actor := get_parent() as SkeletonCaptain
    var base := 8 if actor.second_phase else 0
    var frame := int(clock*3)%2
    if absf(actor.velocity.x)>5: frame=2+posmod(int(actor.steps*0.7),2)
    var aiming := actor.battle in [SkeletonCaptain.Battle.AIM,SkeletonCaptain.Battle.BURST]
    if actor.battle==SkeletonCaptain.Battle.AIM: frame=4 if actor.timer>0.45 else 5
    elif actor.battle==SkeletonCaptain.Battle.BURST: frame=6 if actor.timer>0.12 else 5
    elif actor.flash_left>0.2: frame=7
    animation_frame=base+frame
    if actor.health.current<=0:
        var decay := clampf(death_time/0.45,0,1)
        if decay<1: ActionArt.actor(self,"captain",base+7,68,actor.facing,Color(1,1,1,1-decay),Vector2(1+0.2*decay,1-0.7*decay))
        else:
            for i in 5: draw_rect(Rect2(-18+i*8,-6+i%2*2,6,5),Color("d4cfb4"))
            draw_rect(Rect2(-12,-10,22,4),Color("e7be6a"))
        return
    draw_rect(Rect2(-17,-2,34,4),Color(0.03,0.10,0.12,0.35))
    ActionArt.actor(self,"captain",animation_frame,68,actor.facing,Color(1.45,1.45,1.45) if actor.flash_left>0.2 else Color.WHITE)
    if aiming: draw_line(Vector2(0,-27),Vector2(0,-27)+actor.aim_direction*540,Color(1,0.81,0.40,0.85),1)
    if actor.battle==SkeletonCaptain.Battle.SHIFT_WARNING: draw_arc(Vector2(0,-30),43,0,TAU,24,Color("f1b477"),2)
    if actor.ui_font!=null and actor.flash_left>0: draw_string(actor.ui_font,Vector2(22,-51),"-%d" % actor.last_damage,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffe4a1"))
