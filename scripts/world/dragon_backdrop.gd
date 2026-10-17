extends "res://scripts/world/warped_backdrop.gd"
const END=preload("res://assets/art/m4-portal/end.png")
func _draw() -> void:
    var scroll:=camera.position.x-320 if is_instance_valid(camera) else 0.0
    _panorama(END,scroll,1.0)
    draw_rect(Rect2(0,0,640,360),Color(0.035,0.01,0.07,0.20))
    for i in 24:
        var x:=fposmod(i*73-scroll*0.18+seconds*2,640)
        var y:=90+fposmod(i*41-seconds*3,200)
        draw_rect(Rect2(x,y,1,2),Color(0.73,0.49,0.91,0.4))
