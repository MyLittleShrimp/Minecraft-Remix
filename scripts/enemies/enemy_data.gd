class_name EnemyData
extends Resource

enum Kind { ZOMBIE, SKELETON, CREEPER, SPIDER, WITCH, VINDICATOR, RAVAGER, DROWNED, ELDER_GUARDIAN, ENDERMAN, GHAST, BLAZE, WITHER_SKELETON, PIGLIN_BRUTE, WITHER_BOSS, ENDER_DRAGON }
@export var kind: Kind = Kind.ZOMBIE
@export var label: String = "僵尸"
@export var max_health: int = 12
@export var patrol_speed: float = 35.0
@export var chase_speed: float = 65.0
@export var awareness: float = 210.0
@export var patrol_radius: float = 56.0
@export var contact_damage: int = 2
@export var aim_seconds: float = 0.55
@export var shot_recovery: float = 1.25
@export var arrow_speed: float = 300.0
@export var retreat_distance: float = 95.0
@export var ignition_distance: float = 72.0
@export var extinguish_distance: float = 100.0
@export var extinguish_seconds: float = 0.35
@export var fuse_seconds: float = 1.2
@export var committed_seconds: float = 0.25
@export var blast_radius: float = 80.0
@export var inner_radius: float = 42.0
@export var inner_damage: int = 6
@export var outer_damage: int = 3
