class_name WitherPillar
extends StaticBody2D
var level: Node
var integrity:=2
var rebuild_left:=0.0
var breaks:=0
func _ready() -> void:
    collision_layer=1
    collision_mask=0
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(24,58)
    var c:=CollisionShape2D.new()
    c.shape=shape
    c.position=Vector2(0,-29)
    add_child(c)
func solid() -> bool: return integrity>0
func absorb_skull() -> void:
    if not solid(): return
    integrity-=1
    if integrity<=0: break_pillar()
    queue_redraw()
func break_pillar() -> void:
    integrity=0
    rebuild_left=6.0
    breaks+=1
    set_deferred("collision_layer",0)
    queue_redraw()
func reset_pillar() -> void:
    integrity=2
    rebuild_left=0
    breaks=0
    set_deferred("collision_layer",1)
    queue_redraw()
func _physics_process(delta: float) -> void:
    if not solid() and level.arena_active and not level.defeated:
        rebuild_left=maxf(0,rebuild_left-delta)
        var area:=Rect2(global_position+Vector2(-23,-68),Vector2(46,78))
        var body:=Rect2(level.player.global_position+Vector2(-10,-44),Vector2(20,44))
        var boss: WitherBoss=level.wither_boss
        var boss_box:=Rect2(boss.center()-Vector2(42,38),Vector2(84,76))
        var guard_occupied: bool=is_instance_valid(level.reinforcements) and level.reinforcements.overlaps(area)
        if rebuild_left<=0 and not area.intersects(body) and not area.intersects(boss_box) and not guard_occupied:
            integrity=2
            set_deferred("collision_layer",1)
    queue_redraw()
func _draw() -> void:
    if solid():
        draw_rect(Rect2(-12,-58,24,58),Color("30363f"))
        for y in range(-56,-2,13):
            draw_rect(Rect2(-10,y,20,11),Color("697382"))
            draw_rect(Rect2(-8,y+1,14,2),Color("adb4ad"))
        draw_rect(Rect2(-14,-62,28,6),Color("c7b58c"))
        if integrity==1: draw_polyline(PackedVector2Array([Vector2(-2,-56),Vector2(5,-39),Vector2(-3,-28),Vector2(4,-10)]),Color("222333"),3)
    else:
        for i in 5: draw_rect(Rect2(-12+i*5,-5-posmod(i*7,8),5,5),Color("6c6a75"))
        draw_rect(Rect2(-12,-58,24,58),Color("acd0c070"),false,1)
        draw_string(level.ui_font,Vector2(-17,-69),"%.0fs"%ceilf(rebuild_left) if rebuild_left>0 else "让开重筑",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("b6ddd0"))
