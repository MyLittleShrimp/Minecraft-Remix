extends Node2D
const FOREST := preload("res://assets/art/m3-art/forest-background.png")
var camera: Camera2D
var seconds: float = 0

func _process(delta: float) -> void:
    if not get_tree().paused: seconds+=delta
    queue_redraw()

func _draw() -> void:
    var scroll := camera.position.x-320.0 if is_instance_valid(camera) else 0.0
    var offset := roundf(scroll*0.16)
    # Mirrored repeat shares identical edge pixels and avoids a scrolling seam.
    for tile in range(floori(offset/768)-1,floori(offset/768)+2):
        var x := tile*768-offset
        var mirrored := posmod(tile,2)==1
        draw_set_transform(Vector2(x+(768 if mirrored else 0),0),0,Vector2(-1 if mirrored else 1,1))
        draw_texture_rect(FOREST,Rect2(0,-90,768,512),false)
    draw_set_transform(Vector2.ZERO)
    draw_rect(Rect2(0,130,640,190),Color(0.08,0.18,0.18,0.13))
    # Small foliage accents move separately from the generated distant forest.
    for i in range(-1,5):
        var x := i*224-posmod(int(scroll*0.42),224)
        RemixArt.icon(self,15,Rect2(x,-12,30,100),Color(0.6,0.8,0.66,0.7))
    for i in 12:
        var x := posmod(int(i*61-scroll*0.24+seconds*3),640)
        var y := 112+posmod(i*37,142)+roundf(sin(seconds*0.4+i)*7)
        draw_rect(Rect2(x,y,2,2),Color(1,0.91,0.64,0.25+sin(seconds+i)*0.12))
