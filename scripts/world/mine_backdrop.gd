extends Node2D
const MINE=preload("res://assets/art/m4-mine/abandoned-mine.png")
var camera: Camera2D
var seconds:=0.0
func _process(delta: float) -> void:
    if not get_tree().paused: seconds+=delta
    queue_redraw()
func _draw() -> void:
    var scroll:=camera.position.x-320.0 if is_instance_valid(camera) else 0.0
    var offset:=roundf(scroll*0.17)
    for tile in range(floori(offset/768)-1,floori(offset/768)+2):
        var x:=tile*768-offset
        var mirrored:=posmod(tile,2)==1
        draw_set_transform(Vector2(x+(768 if mirrored else 0),-8),0,Vector2(-1 if mirrored else 1,1))
        draw_texture_rect(MINE,Rect2(0,0,768,432),false)
    draw_set_transform(Vector2.ZERO)
    for i in 16:
        var x:=posmod(int(i*61-scroll*0.3+seconds*2),640)
        var y:=100+posmod(i*37,172)+sin(seconds*0.5+i)*4
        draw_rect(Rect2(x,y,1,1),Color(0.92,0.75,0.42,0.25))
