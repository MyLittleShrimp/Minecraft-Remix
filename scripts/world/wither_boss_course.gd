extends "res://scripts/world/movement_course.gd"
@export var campaign_arena := false
var entrance: StageGate
var exit_gate: StageGate
var pillars: Array[WitherPillar]=[]
var charges: Array[WitherCharge]=[]
func _ready() -> void:
    _add_collision(Rect2(0,288,1280,224),false)
    if not campaign_arena: _add_collision(Rect2(-32,0,32,512),false)
    _add_collision(Rect2(1280,0,32,512),false)
    entrance=StageGate.new()
    entrance.position=Vector2(320,288)
    add_child(entrance)
    exit_gate=StageGate.new()
    exit_gate.position=Vector2(960,288)
    add_child(exit_gate)
    exit_gate.set_closed(true)
    for x in [520,760]:
        var pillar:=WitherPillar.new()
        pillar.level=get_parent().get_parent()
        pillar.position=Vector2(x,288)
        add_child(pillar)
        pillars.append(pillar)
    for pair in [Vector2(480,352),Vector2(800,928)]:
        var charge:=WitherCharge.new()
        charge.level=get_parent().get_parent()
        charge.position=Vector2(pair.x,272)
        charge.lever_x=global_position.x+pair.y
        add_child(charge)
        charges.append(charge)
func _draw() -> void:
    draw_rect(Rect2(0,288,1280,224),Color("332630"))
    for x in range(0,1280,32):
        for y in range(288,400,16):
            draw_rect(Rect2(x+1,y+1,30,14),Color("57414e") if posmod(x/32+y/16,3)==0 else Color("45313f"))
            draw_rect(Rect2(x+4,y+3,10,2),Color("70505f"))
    draw_rect(Rect2(0,288,1280,3),Color("cfab88"))
    for spec in [{"x":60,"title":"核心门前 · 路标 / 换装" if campaign_arena else "凋灵试炼 · E 五武器换装"},{"x":1032,"title":"烈焰粉 ×3 →" if campaign_arena else "试炼出口 →"}]:
        if not get_node("/root/ControlSettings").guide_enabled: continue
        if campaign_arena and spec.x==1032: continue # The illustrated reward altar owns this label.
        draw_rect(Rect2(spec.x,165,192,29),Color("20222e"))
        draw_string(ui_font,Vector2(spec.x+8,184),spec.title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e0c98a"))
