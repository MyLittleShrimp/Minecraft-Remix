class_name CheckpointSnapshot
extends RefCounted
## Detached values. RunSaveCodec converts committed snapshots to validated JSON.
var checkpoint_index: int = 0
var checkpoint_id: StringName = &"forest_start"
var spawn: Vector2 = Vector2(96, 288)
var enemy_health: Dictionary = {}
var used_blocks: Dictionary = {}
var loot_seed: int = 1
var broken_bricks: Dictionary = {}
var pickups: Array[Dictionary] = []
var consumed_ids: Dictionary = {}
var emeralds: int = 0
var collected_count: int = 0
var collected_kinds: Dictionary = {}
var weapon_id: StringName = &"netherite_sword"
var loadout_ids: Array[String] = ["netherite_sword","bow"]
var crossbow_ammo: int = 0
var player_health: int = 20
var player_food: float = 20.0
var emeralds_spent: int = 0
var mechanisms: Dictionary = {}
var wildlife_health: Dictionary = {}

var optional_health: Dictionary = {}
var story_items: Dictionary = {"ender_pearl":0}
