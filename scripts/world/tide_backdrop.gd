extends Node2D
const ART=preload("res://assets/art/m4-tide/tidal-ruins.png")
var camera: Camera2D
var seconds:=0.0
func _process(delta: float) -> void:
    if not get_tree().paused: seconds+=delta
    queue_redraw()
func _draw() -> void:
    var scroll:=camera.position.x-320.0 if is_instance_valid(camera) else 0.0
    var offset:=roundf(scroll*0.15)
    for tile in range(floori(offset/768)-1,floori(offset/768)+2):
        var mirrored:=posmod(tile,2)==1
        draw_set_transform(Vector2(tile*768-offset+(768 if mirrored else 0),-30),0,Vector2(-1 if mirrored else 1,1))
        draw_texture_rect(ART,Rect2(0,0,768,432),false)
    draw_set_transform(Vector2.ZERO)
    draw_rect(Rect2(0,0,640,360),Color(0.04,0.15,0.2,0.13))
    for i in 10:
        var x:=fposmod(i*79-scroll*0.27+seconds*3,640)
        draw_rect(Rect2(x,237+posmod(i*23,58),8+i%4*4,1),Color(0.7,0.93,0.92,0.3))
