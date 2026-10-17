extends Node2D
var level: Node
var ui_font: Font
func _draw() -> void:
    draw_rect(Rect2(-26,-36,52,7),Color("4c372c"))
    draw_rect(Rect2(-24,-34,48,3),Color("c09154"))
    for x in [-23,18]:
        draw_rect(Rect2(x,-34,5,34),Color("775138"))
        draw_rect(Rect2(x,-3,5,3),Color("b7bd9d"))
    draw_set_transform(Vector2(-8 if level.campaign_level_id==&"abandoned_mine" else 0,-20),-0.2,Vector2.ONE*0.65)
    WeaponArt.crossbow(self,true)
    if level.campaign_level_id==&"abandoned_mine":
        draw_set_transform(Vector2(15,-7),-0.25,Vector2.ONE*0.72)
        WeaponArt.axe(self)
    draw_set_transform(Vector2.ZERO)
    draw_string(ui_font,Vector2(-24,-43),"武器架",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e7d09a"))
