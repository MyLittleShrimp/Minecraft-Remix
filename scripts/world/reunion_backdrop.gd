extends "res://scripts/world/portal_backdrop.gd"
func _draw() -> void:
    var scroll:=camera.position.x-320 if is_instance_valid(camera) else 0.0
    _panorama(STRONGHOLD,scroll,1.0)
    draw_rect(Rect2(0,0,640,360),Color(0.02,0.03,0.08,0.20))
