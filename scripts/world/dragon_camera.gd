extends PixelFollowCamera
var arena_view:=false
func _physics_process(delta: float) -> void:
    zoom=zoom.move_toward(Vector2.ONE*(0.8 if arena_view else 1.0),delta*0.4)
    super._physics_process(delta)
    position.y=180-100*(1-zoom.x)
func clamped_x(value: float) -> float:
    var right:=course_width if region_right<0 else region_right
    var half:=get_viewport_rect().size.x*0.5/zoom.x
    if right-region_left<=half*2: return (right+region_left)*0.5
    return clampf(value,region_left+half,right-half)
