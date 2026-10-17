class_name DragonCourse
extends "res://scripts/world/movement_course.gd"
var entrance: StageGate
var exit_gate: StageGate
const CRYSTAL_X: Array[float]=[444.0,612.0,828.0,996.0]
const TOWER_TOP: Array[float]=[192.0,176.0,176.0,192.0]
const STEP_Y:=240.0
static func crystal_position(index: int) -> Vector2:
    return Vector2(CRYSTAL_X[index],TOWER_TOP[index]-32)
func _ready() -> void:
    _add_collision(Rect2(0,288,1440,224),false)
    _add_collision(Rect2(-32,0,32,512),false)
    _add_collision(Rect2(1440,0,32,512),false)
    for i in CRYSTAL_X.size():
        var x:=CRYSTAL_X[i]
        _add_collision(Rect2(x-22,TOWER_TOP[i],44,6),true)
        for side in [-1,1]: _add_collision(Rect2(x+side*46-14,STEP_Y,28,6),true)
    entrance=StageGate.new()
    entrance.position=Vector2(320,288)
    add_child(entrance)
    exit_gate=StageGate.new()
    exit_gate.position=Vector2(1120,288)
    add_child(exit_gate)
    exit_gate.set_closed(true)
func _draw() -> void:
    draw_rect(Rect2(0,288,1440,224),Color("746e55"))
    for x in range(0,1440,32):
        for y in range(288,424,16):
            draw_rect(Rect2(x+1,y+1,30,14),Color("c0b688") if posmod(x/32+y/16,3)==0 else Color("a89f78"))
            draw_rect(Rect2(x+5,y+4,6,3),Color("8b8661"))
    draw_rect(Rect2(0,288,1440,3),Color("e2d8a5"))
    for i in CRYSTAL_X.size():
        var x:=CRYSTAL_X[i]
        var top:=TOWER_TOP[i]
        draw_rect(Rect2(x-22,top,44,288-top),Color("201e2b"))
        for y in range(int(top)+5,286,13):
            draw_rect(Rect2(x-19,y,38,10),Color("393043"))
            draw_line(Vector2(x-14,y+2),Vector2(x+8,y+2),Color("54425e"),1)
        for side in [-1,1]:
            draw_line(Vector2(x+side*17,top+8),Vector2(x+side*17,284),Color("705384"),1)
            draw_rect(Rect2(x+side*46-14,STEP_Y,28,7),Color("51415d"))
            draw_line(Vector2(x+side*46-14,STEP_Y),Vector2(x+side*46+14,STEP_Y),Color("b394bf"),2)
        draw_rect(Rect2(x-25,top,50,5),Color("94739e"))
        draw_line(Vector2(x-25,top),Vector2(x+25,top),Color("ebc6f6"),2)
    var formal: bool=get_parent().get_parent().get("campaign_mode")==true
    for spec in [{"x":56,"text":"末地武库 · E 五武器换装"},{"x":1200,"text":"返回传送门 →" if formal else "试炼完成 →"}]:
        if not get_node("/root/ControlSettings").guide_enabled and spec.x==56: continue
        draw_rect(Rect2(spec.x,167,184,28),Color("222034"))
        draw_string(ui_font,Vector2(spec.x+7,185),spec.text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e4d1aa"))
