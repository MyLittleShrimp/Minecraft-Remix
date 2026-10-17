extends Node2D
var camera: Camera2D
var seconds:=0.0
func _process(delta: float) -> void:
    if not get_tree().paused: seconds+=delta
    queue_redraw()
func _draw() -> void:
    draw_rect(Rect2(0,0,640,360),Color("211d30"))
    var scroll:=camera.position.x-320 if is_instance_valid(camera) else 0.0
    for layer in 3:
        var color:=Color("342438") if layer==0 else (Color("49313f") if layer==1 else Color("61404a"))
        for i in 9:
            var x:=floorf(fposmod(i*94-scroll*(0.08+layer*0.12),846)-100)
            var y: float=148+posmod(i*29+layer*13,85)
            draw_rect(Rect2(x,y,27+layer*8,360-y),color)
            draw_rect(Rect2(x+5,y-12,17+layer*8,12),color)
            draw_rect(Rect2(x+4,y+6,3,70),color.lightened(0.08))
    for i in 6:
        var x:=floorf(fposmod(i*143-scroll*0.17,860)-80)
        draw_rect(Rect2(x,302,56,4),Color("c7785d"))
        draw_rect(Rect2(x+10,308,32,3),Color("f1b471"))
    for i in 32:
        var x:=floorf(fposmod(i*41-scroll*0.32+seconds*9,640))
        var y:=floorf(115+fposmod(i*23-seconds*6,190))
        draw_rect(Rect2(x,y,2,2),Color(0.84,0.69,0.71,0.32))
