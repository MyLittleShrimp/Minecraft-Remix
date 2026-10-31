extends Node2D
## Local additive halo only: no fullscreen bloom or changes to the attack clock.
const GLOW := preload("res://scripts/art/lightning_glow.gdshader")
@onready var cast: TridentLightning = get_parent()

func _ready() -> void:
    show_behind_parent = true
    var glow_material := ShaderMaterial.new()
    glow_material.shader = GLOW
    material = glow_material

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    if not cast.struck or cast.spent: return
    for index in cast.strike_points.size():
        var head := to_local(cast.head_points[index])
        var foot := to_local(cast.foot_points[index])
        var sky := to_local(Vector2(cast.head_points[index].x,minf(cast.sky_y,cast.head_points[index].y-100)))
        PixelVfxArt.lightning(self,cast.age-cast.windup,sky,head,foot,true)
