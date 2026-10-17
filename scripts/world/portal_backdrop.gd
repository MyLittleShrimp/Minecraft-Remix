extends "res://scripts/world/warped_backdrop.gd"
const STRONGHOLD=preload("res://assets/art/m4-portal/stronghold.png")
const END=preload("res://assets/art/m4-portal/end.png")
func _draw() -> void:
    var scroll:=camera.position.x-320 if is_instance_valid(camera) else 0.0
    var in_end:=scroll>=2200
    _panorama(END if in_end else STRONGHOLD,scroll,1.0)
    draw_rect(Rect2(0,0,640,360),Color(0.01,0.03,0.06,0.14))
    for i in 18:
        var x:=floorf(fposmod(i*73-scroll*0.24+seconds*2,640))
        var y:=floorf(116+fposmod(i*31-seconds*4,166))
        draw_rect(Rect2(x,y,1+i%2,1+i%2),Color(0.69,0.45,0.95,0.45) if in_end else Color(0.34,0.90,0.82,0.24))
