class_name PixelFollowCamera
extends Camera2D

@export var target: Node2D
@export var course_width: float = 2560.0
var region_left: float = 0.0
var region_right: float = -1.0
var transition_left := 0.0
var transition_duration := 1.0
var transition_from := Vector2.ZERO

func _ready() -> void:
    process_physics_priority = 10
    position_smoothing_enabled = false
    reset_to_target()

func _physics_process(_delta: float) -> void:
    if not is_instance_valid(target):
        return
    if transition_left>0:
        transition_left=maxf(0,transition_left-_delta)
        var t := 1.0-transition_left/transition_duration
        var goal := Vector2(clamped_x(target.position.x-48.0),180)
        position=transition_from.lerp(goal,t*t*(3-2*t)).round()
        return
    var next_x := position.x
    if target.position.x > position.x + 48.0:
        next_x = target.position.x - 48.0
    elif target.position.x < position.x - 80.0:
        next_x = target.position.x + 80.0
    position = Vector2(roundf(clamped_x(next_x)), 180.0)

func reset_to_target() -> void:
    transition_left=0
    if is_instance_valid(target):
        position = Vector2(roundf(clamped_x(target.position.x - 48.0)), 180.0)
        reset_smoothing()

func clamped_x(value: float) -> float:
    var right := course_width if region_right < 0 else region_right
    var half:=get_viewport_rect().size.x*0.5/zoom.x
    if right-region_left<=half*2: return (right+region_left)*0.5
    return clampf(value, region_left + half, right - half)

func refresh_bounds() -> void:
    position.x=clamped_x(position.x)
    force_update_scroll()

func set_region(left: float, right: float = -1) -> void:
    region_left = left
    region_right = right
    reset_to_target()

func set_region_smooth(left: float, right: float = -1, seconds: float = 1.2) -> void:
    region_left=left
    region_right=right
    transition_from=position
    transition_duration=maxf(0.01,seconds)
    transition_left=transition_duration
