extends Node2D
func _draw() -> void:
    var animal:=get_parent() as WildlifeActor
    if animal.state==RemixEnemy.State.DEAD: return
    var frame:=int(animal.steps)%4 if absf(animal.velocity.x)>1 else 0
    var tint:=Color("ffe0c4") if animal.flash_left>0 else Color.WHITE
    if animal.species<3:
        WitchArt.actor(self,animal.species+2,frame,30 if animal.species==0 else 28,animal.facing,tint)
    else:
        WildlifeArt.actor(self,animal.species,frame,24 if animal.species==3 else (34 if animal.species==5 else 30),animal.facing,tint)
    if animal.food!=null and animal.target.position.distance_to(animal.position)<130:
        var text: String=animal.data.label+" · 饱食 +%d"%animal.food.amount
        var width:=animal.ui_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
        draw_rect(Rect2(-width/2-3,-63,width+6,12),Color("152d30"))
        draw_string(animal.ui_font,Vector2(-width/2,-54),text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("d4dfb3"))
