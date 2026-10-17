extends Node2D
## Lightweight pixel scenery for the trial, not final chapter-five artwork.
var camera: Camera2D
var seconds:=0.0
func _process(delta: float) -> void:
    if not get_tree().paused: seconds+=delta
    queue_redraw()
func _draw() -> void:
    draw_rect(Rect2(0,0,640,360),Color("0c202c"))
    var scroll:=camera.position.x-320 if is_instance_valid(camera) else 0.0
    for layer in 3:
        var spacing:=122.0+layer*47
        for i in 7:
            var x:=floorf(fposmod(i*spacing-scroll*(0.08+layer*0.08),spacing*7)-90)
            var y:=108+layer*38+posmod(i*23,53)
            var tint:=Color("183440") if layer==0 else (Color("21515a") if layer==1 else Color("266e70"))
            draw_rect(Rect2(x+28,y,12+layer*4,300-y),tint.darkened(0.3))
            draw_rect(Rect2(x,y,80+layer*12,18),tint)
            draw_rect(Rect2(x+12,y-12,54+layer*12,14),tint.lightened(0.04))
            for j in 4:
                draw_rect(Rect2(x+8+j*19,y+18,2,14+posmod(i*13+j*7,29)),tint)
            draw_rect(Rect2(x+19,y-7,5,3),Color(tint.lightened(0.16),0.8))
    for i in 22:
        var x:=floorf(fposmod(i*37-scroll*0.3+seconds*3,640))
        var y:=floorf(120+fposmod(i*19-seconds*4,180))
        draw_rect(Rect2(x,y,2,2),Color(0.5,0.8,0.76,0.4))
