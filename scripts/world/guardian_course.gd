extends "res://scripts/world/ravager_course.gd"
func _draw() -> void:
    draw_rect(Rect2(0,288,1600,224),Color("234c53"))
    for x in range(0,1600,32):
        for y in range(288,400,16):
            draw_rect(Rect2(x+1,y+1,30,14),Color("427570") if posmod(x/32+y/16,3)==0 else Color("345f61"))
            draw_rect(Rect2(x+4,y+3,10,2),Color("6ba098"))
    draw_rect(Rect2(0,288,1600,3),Color("c5c8a4"))
    for x in range(376,1250,64):
        draw_rect(Rect2(x,282,22,4),Color("6fbab4"))
        draw_rect(Rect2(x+7,273,8,8),Color("416d6a"))
    var level:=get_parent().get_parent()
    for request in level.pending_guards:
        draw_rect(Rect2(request.x-19,283,38,5),Color("f1cf85"))
        draw_string(ui_font,Vector2(request.x-24,224),"溺尸将至",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f1cf85"))
    for spec in [{"x":68,"title":"神殿试炼 · E 换装"},{"x":1320,"title":"试炼出口 →"}]:
        draw_rect(Rect2(spec.x,165,180,29),Color("152d35"))
        draw_string(ui_font,Vector2(spec.x+8,184),spec.title,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ddcc9b"))
