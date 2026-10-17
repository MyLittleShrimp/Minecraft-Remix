class_name PiglinData
extends EnemyData
enum Role { SWORD, AXE, CROSSBOW }
@export var role: Role = Role.SWORD
@export var reach := 46.0
@export var damage := 3
@export var followup_aim := 0.45
@export var reload_seconds := 1.8
