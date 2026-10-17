extends Node2D
## Generated hover/charge/low poses with unchanged aiming and range cues.
var animation_frame:=0
func _draw() -> void:
    var actor:=get_parent() as GhastEnemy
    if actor.flight==GhastEnemy.Flight.DEAD: return
    var hot:=actor.flight==GhastEnemy.Flight.CHARGE
    var low:=actor.flight==GhastEnemy.Flight.LOW
    animation_frame=WarpedArt.ghast_pose(actor)
    WarpedArt.draw_actor(self,"airborne",animation_frame,actor.facing,Color(1.5,1.4,1.3) if actor.flash_left>0 else Color.WHITE)
    if hot:
        var charge:=1.0-actor.timer/GhastEnemy.CHARGE_SECONDS
        draw_rect(Rect2(-29,-30,58,58),Color(1,0.43,0.22,0.25+charge*0.55),false,2)
        var direction: Vector2=(actor.mark-actor.center()).normalized()
        for i in 4:
            var at: Vector2=(direction*(35+i*9)).round()
            draw_rect(Rect2(at-Vector2(1,1),Vector2(3,3)),Color("ffa659"))
    var y: float=54 if actor.position.y<160 else -51
    draw_rect(Rect2(-25,y,50,3),Color("3c3046"))
    draw_rect(Rect2(-25,y,50.0*actor.health.current/actor.health.max_health,3),Color("e8b879"))
    var label: String="恶魂 · 待入场" if not actor.active else ("蓄火 %.1f"%actor.timer if hot else ("低空 · 跳跃攻击" if low else "高空 · 上瞄 / 反弹"))
    if actor.flight in [GhastEnemy.Flight.DESCEND,GhastEnemy.Flight.ASCEND]: label="下降 · 准备起跳" if actor.flight==GhastEnemy.Flight.DESCEND else "升空中"
    var label_width:=actor.ui_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
    draw_string(actor.ui_font,Vector2(-label_width*0.5,y+15),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe7b3") if hot else Color("e5e6df"))
