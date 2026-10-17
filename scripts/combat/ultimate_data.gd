class_name UltimateData
extends Resource
## Per-weapon ability tuning. Future weapons register their own effect here.
enum Effect { NONE, GIANT_SWORD, MULTISHOT, PIERCING_BOLT, HEAVY_CLEAVE, TRIPLE_LIGHTNING }
@export var label: String = "大招"
@export var effect: Effect = Effect.NONE
@export var emerald_cost: int = 20
@export var duration: float = 6.0
@export var damage_multiplier: float = 2.0
@export var reach_multiplier: float = 1.6
@export var arrow_count: int = 5
@export var spread_degrees: float = 7.0
@export var arrow_damage: int = 10
@export var recovery: float = 0.8
@export_range(1, 8) var pierce_targets: int = 3
@export var melee_damage: int = 28
@export var melee_reach: float = 100.0
@export var melee_windup: float = 0.45
@export var melee_stagger: float = 1.0
@export var target_range: float = 640.0
@export_range(1, 3) var lightning_targets: int = 3
@export var splash_radius: float = 48.0
@export var splash_damage: int = 12
