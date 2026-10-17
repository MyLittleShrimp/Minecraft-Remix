extends Node2D
const SHEET=preload("res://assets/art/m4-dragon/dragon.png")
func _draw() -> void:
    var b: EnderDragon=get_parent()
    if b.battle==EnderDragon.Battle.DEAD:
        for i in 22:
            var p:=Vector2(sin(i*9.7)*110,-24+cos(i*13.1)*64)
            draw_rect(Rect2(p,Vector2(2,4)),Color("c9a3ff"))
        return
    DragonEffects.draw(self,b)
    for crystal in b.crystals:
        if not b.active or crystal.health.current<=0: continue
        var p:=crystal.global_position-b.global_position
        draw_line(p,Vector2.ZERO,Color(0.69,0.32,1,0.22),7)
        draw_line(p,Vector2.ZERO,Color("ba8be8"),1)
        var spark:=p.lerp(Vector2.ZERO,fposmod(b.visual_seconds*0.7,1))
        draw_rect(Rect2(spark-Vector2(2,2),Vector2(4,4)),Color("f7d3ff"))
    var pose:=0 if int(b.visual_seconds*5)%2==0 else 1
    if b.second_phase: pose=4 if pose==0 else 5
    if b.battle in [EnderDragon.Battle.DESCEND,EnderDragon.Battle.LOW,EnderDragon.Battle.BITE_WARNING,EnderDragon.Battle.BITE,EnderDragon.Battle.RECOVER,EnderDragon.Battle.TAIL_WARNING,EnderDragon.Battle.TAIL]: pose=6 if b.second_phase else 3
    if b.battle in [EnderDragon.Battle.BREATH_WARNING,EnderDragon.Battle.BREATH]: pose=5 if b.second_phase else 2
    if b.battle==EnderDragon.Battle.PHASE_CHANGE: pose=7
    var cell:=Vector2(SHEET.get_width()/4.0,SHEET.get_height()/2.0)
    var region:=Rect2(Vector2(pose%4,pose/4)*cell,cell)
    var anchor_y:=0.72 if pose in [3,6] else 0.67
    var height:=260.0 if pose in [3,6] else 176.0
    if b.battle==EnderDragon.Battle.DIVE:
        for i in range(3,0,-1):
            draw_set_transform(Vector2(-b.facing*i*38,0),0,Vector2(b.facing,1))
            draw_texture_rect_region(SHEET,Rect2(-150,-height*anchor_y,260,height),region,Color(0.8,0.38,1,0.32/float(i)))
    draw_set_transform(Vector2.ZERO,0,Vector2(b.facing,1))
    var tint:=Color(1.45,1.25,1.5) if b.flash_left>0 else Color.WHITE
    draw_texture_rect_region(SHEET,Rect2(-150,-height*anchor_y,260,height),region,tint)
    if b.exposed():
        draw_arc(Vector2(81,8),24,-2.5,1.9,18,Color("b9f2cd"),1)
        draw_line(Vector2(68,29),Vector2(95,29),Color("b9f2cd"),2)
    draw_set_transform(Vector2.ZERO)
