extends Node2D
func _draw() -> void:
    var boss:=get_parent() as WitherBoss
    if boss.health.current<=0: return
    var accent:=Color("d899ff") if boss.second_phase else Color("94e9e2")
    WitherBossFX.back(self,boss)
    if boss.battle==WitherBoss.Battle.VOLLEY_WARNING:
        var point:=to_local(boss.mark)
        for origin in [Vector2(-24,-14),Vector2(0,-28),Vector2(24,-14)]:
            draw_line(origin,point,Color(1,0.4,0.35,0.55),1)
        draw_arc(point,12,0,TAU,20,Color("ffad91"),2)
        draw_line(point-Vector2(17,0),point+Vector2(17,0),Color("ffad91"),1)
        draw_line(point-Vector2(0,17),point+Vector2(0,17),Color("ffad91"),1)
    if boss.battle==WitherBoss.Battle.PHASE_CHANGE:
        draw_arc(Vector2.ZERO,46+sin(boss.visual_seconds*16)*4,0,TAU,32,accent,2)
    if boss.battle==WitherBoss.Battle.STUN:
        for i in 3:
            var angle:=boss.visual_seconds*3+i*TAU/3
            draw_rect(Rect2(Vector2(cos(angle)*29,-48+sin(angle)*4),Vector2(4,3)),Color("ffdc92"))
    WitherBossArt.draw_actor(self,boss)
    WitherBossFX.front(self,boss)
    if boss.exposed():
        draw_line(Vector2(-22,43),Vector2(22,43),Color("a7e6c0"),2)
