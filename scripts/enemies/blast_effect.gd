class_name BlastEffect
extends Node2D

var radius: float = 80.0
var creeper: bool = false
var duration: float = 0.64
var remaining: float = 0.64

func _ready() -> void:
    duration = 0.56 if creeper else 0.64
    remaining = duration
    process_mode = Node.PROCESS_MODE_PAUSABLE
    z_index = 6
    add_to_group("transient_effects")

func _physics_process(delta: float) -> void:
    remaining -= delta
    queue_redraw()
    if remaining <= 0:
        queue_free()

func retire() -> void:
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    ActionVfxArt.blast(self,creeper,1-remaining/duration,radius)
