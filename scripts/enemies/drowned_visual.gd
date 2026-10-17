extends Node2D
func _draw() -> void:
    var actor:=get_parent() as DrownedEnemy
    if actor.state==RemixEnemy.State.DEAD: return
    var frame:=1+posmod(int(actor.steps*0.85),3) if absf(actor.velocity.x)>5 else 0
    if actor.state==RemixEnemy.State.AIM: frame=4
    elif actor.state==RemixEnemy.State.RECOVER: frame=5
    ActionArt.actor(self,"enemies",frame,45,actor.facing,Color("c6ffff") if actor.flash_left>0 else Color("6cbbbb"))
    # Kelp shoulder, pale barnacles and a separate, clearly readable raised spear.
    draw_set_transform(Vector2.ZERO,0,Vector2(actor.facing,1))
    draw_rect(Rect2(-8,-32,4,13),Color("6e9574"))
    draw_rect(Rect2(-5,-35,4,5),Color("bdcdb3"))
    draw_rect(Rect2(2,-22,3,3),Color("9ed5bc"))
    var raising:=actor.state==RemixEnemy.State.AIM
    draw_set_transform(Vector2(actor.facing*8,-26),(-0.55 if raising else 0.8)*actor.facing,Vector2(actor.facing*0.7,0.7))
    WeaponArt.trident(self,Color("a5daca"))
    draw_set_transform(Vector2.ZERO)
    draw_rect(Rect2(-17,-55,34,3),Color("102b35"))
    draw_rect(Rect2(-17,-55,34.0*actor.health.current/actor.health.max_health,3),Color("84d5be"))
    draw_string(actor.ui_font,Vector2(-17,-62),"溺尸",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("d0efda"))
    if raising:
        draw_line(Vector2(0,-22),Vector2(0,-22)+actor.locked_direction*280,Color(0.8,0.95,0.64,0.6),1)
        draw_string(actor.ui_font,Vector2(-20,-76),"投掷！",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe4a1"))
