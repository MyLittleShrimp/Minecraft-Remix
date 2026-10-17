class_name MovementTuning
extends Resource
## Pixels and seconds. Physics stays in floating point; only visuals are rounded.

@export var run_speed: float = 190.0
@export var ground_acceleration: float = 1800.0
@export var ground_deceleration: float = 2200.0
@export var air_acceleration: float = 1100.0
@export var jump_speed: float = 460.0
@export var jump_cut_speed: float = 200.0
@export var rise_gravity: float = 1300.0
@export var fall_gravity: float = 1600.0
@export var max_fall_speed: float = 700.0
@export var coyote_seconds: float = 0.10
@export var buffer_seconds: float = 0.12
@export var drop_seconds: float = 0.18
