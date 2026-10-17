extends Node2D
func _draw() -> void:
    var witch:=get_parent() as WitchEnemy
    if witch.state==RemixEnemy.State.DEAD: return
    var frame:=int(witch.steps)%2 if absf(witch.velocity.x)>2 else 0
    if witch.state==RemixEnemy.State.AIM: frame=2
    elif witch.throw_flash>0: frame=3
    var row:=5 if witch.queen and witch.second_phase else (1 if witch.queen else 0)
    WitchArt.actor(self,row,frame,67 if witch.queen else 54,witch.facing,Color("fff0cb") if witch.flash_left>0 else Color.WHITE)
    if not witch.queen:
        draw_rect(Rect2(-16,-61,32,3),Color("243038"))
        draw_rect(Rect2(-16,-61,32.0*witch.health.current/witch.health.max_health,3),Color("c69ad9"))
        draw_string(witch.ui_font,Vector2(-14,-65),"女巫",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f3dfbe"))
    if witch.state==RemixEnemy.State.AIM:
        var color:=Color("a8ed73") if witch.cast_poison else Color("fa8785")
        var hand:=Vector2(-witch.facing*14,-50 if witch.queen else -40)
        draw_rect(Rect2(hand-Vector2(4,5),Vector2(8,11)),Color("25323a"))
        draw_rect(Rect2(hand-Vector2(3,3),Vector2(6,8)),color)
        draw_rect(Rect2(hand-Vector2(2,7),Vector2(4,3)),Color("d6d9b5"))
        for point in witch.marks:
            var local:=to_local(point)
            var radius:=34.0 if witch.queen else 30.0
            draw_line(local-Vector2(radius,-6),local+Vector2(radius,6),Color(color,0.8),3)
            draw_line(local+Vector2(-radius,-1),local+Vector2(-radius,10),color,2)
            draw_line(local+Vector2(radius,-1),local+Vector2(radius,10),color,2)
        draw_string(witch.ui_font,Vector2(-22,-77 if witch.queen else -78),"剧毒！" if witch.cast_poison else "药水！",HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
