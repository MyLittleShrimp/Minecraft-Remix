extends Node2D
## Generated scenery stays behind geometry and combat telegraphs.
const FOREST=preload("res://assets/art/m4-warped/warped-forest.png")
const CITADEL=preload("res://assets/art/m4-warped/ash-citadel.png")
var camera: Camera2D
var seconds:=0.0
func _process(delta: float) -> void:
    if not get_tree().paused: seconds+=delta
    queue_redraw()
func ash_blend() -> float:
    return smoothstep(3500,4300,camera.position.x) if is_instance_valid(camera) else 0.0
func _panorama(texture: Texture2D,scroll: float,alpha: float) -> void:
    if alpha<=0: return
    var offset:=roundf(scroll*0.16)
    for tile in range(floori(offset/768)-1,floori(offset/768)+2):
        var mirrored:=posmod(tile,2)==1
        draw_set_transform(Vector2(tile*768-offset+(768 if mirrored else 0),-24),0,Vector2(-1 if mirrored else 1,1))
        draw_texture_rect(texture,Rect2(0,0,768,432),false,Color(1,1,1,alpha))
    draw_set_transform(Vector2.ZERO)
func _draw() -> void:
    var scroll:=camera.position.x-320 if is_instance_valid(camera) else 0.0
    var blend:=ash_blend()
    _panorama(FOREST,scroll,1.0)
    _panorama(CITADEL,scroll,blend)
    draw_rect(Rect2(0,0,640,360),Color(0.03,0.09,0.13,0.14))
    var rift:=smoothstep(8900,9550,scroll+320)
    if rift>0: draw_rect(Rect2(0,0,640,360),Color(0.16,0.05,0.24,rift*0.19))
    for i in 22:
        var x:=floorf(fposmod(i*71-scroll*0.30+seconds*3,640))
        var y:=floorf(115+fposmod(i*29-seconds*5,180))
        var color:=Color("93d3ca").lerp(Color("e9a36f"),blend)
        draw_rect(Rect2(x,y,1+i%2,1+i%2),Color(color,0.18+0.12*(0.5+0.5*sin(seconds+i))))
