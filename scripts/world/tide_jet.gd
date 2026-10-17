class_name TideJet
extends Node2D
const PERIOD:=6.0
var clock:=0.0
var touched:=false
var level: Node
var offset:=0.0
func phase() -> float: return fposmod(clock+offset,PERIOD)
func dangerous() -> bool: return phase()>=4.4 and phase()<5.4
func warning() -> bool: return phase()>=3.4 and phase()<4.4
func reset_cycle() -> void:
    clock=0
    touched=false
func _physics_process(delta: float) -> void:
    if level.defeated or level.completed or level.transitioning: return
    clock+=delta
    if not dangerous(): touched=false
    elif not touched:
        var player_box:=Rect2(level.player.global_position+Vector2(-9,-43),Vector2(18,42))
        if player_box.intersects(Rect2(global_position+Vector2(-32,-96),Vector2(64,96))):
            touched=true
            level.health.queue_damage(DamageEvent.create(self,0,2,Vector2(0,-160)))
    queue_redraw()
func _draw() -> void:
    draw_rect(Rect2(-34,-3,68,6),Color("172c35"))
    for i in 8: draw_rect(Rect2(-30+i*8,-2,4,3),Color("74adb0"))
    if warning():
        draw_rect(Rect2(-32,-4,64,3),Color("f3ce81"))
        for i in 6: draw_rect(Rect2(-26+i*10,-8-int(phase()*12+i*3)%9,3,3),Color("bce8dd"))
        draw_string(level.ui_font,Vector2(-26,-30),"即将喷涌",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f3ce81"))
    if dangerous():
        draw_rect(Rect2(-32,-96,64,96),Color(0.3,0.7,0.8,0.35))
        for i in 9:
            var y: float=-12-fposmod(clock*170+i*17,84)
            draw_rect(Rect2(-28+i*7,y,4,21),Color("a2e2da"))
        draw_line(Vector2(-34,-96),Vector2(34,-96),Color("ddfff0"),2)
