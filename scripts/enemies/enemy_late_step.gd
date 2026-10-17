extends Node

func _ready() -> void:
    process_physics_priority = 80

func _physics_process(_delta: float) -> void:
    get_parent().late_step()
