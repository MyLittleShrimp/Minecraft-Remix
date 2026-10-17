class_name WeaponData
extends Resource

enum Kind { SWORD, BOW, CROSSBOW, AXE, TRIDENT }
@export var id: StringName
@export var label: String
@export var kind: Kind = Kind.SWORD
@export var damage: int = 6
@export_range(0, 20, 1) var airborne_damage_bonus: int = 0
@export var windup: float = 0.07
@export var active_seconds: float = 0.10
@export var recovery: float = 0.17
@export var reach: float = 40.0
@export var hit_height: float = 38.0
@export var stagger_seconds: float = 0.18
@export var recovery_bonus: int = 0
@export var wood_power: int = 1
@export var melee_move_scale: float = 1.0
@export var ultimate: UltimateData
@export var quick_cooldown: float = 0.45
@export var charged_recovery: float = 0.25
@export var charge_seconds: float = 0.65
@export var charged_damage: int = 10
@export var arrow_speed: float = 480.0
@export var charged_arrow_speed: float = 650.0
@export var charge_move_scale: float = 0.70
@export var throw_distance: float = 320.0
@export var return_speed: float = 720.0

func is_melee() -> bool:
    return kind in [Kind.SWORD, Kind.AXE, Kind.TRIDENT]
