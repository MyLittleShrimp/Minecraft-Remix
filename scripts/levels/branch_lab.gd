extends "res://scripts/levels/checkpoint_lab.gd"

@export var cache_data: PickupData
var loot_seed: int = 0
var fragile_bricks: Array[FragileBrick] = []

func configure_stage() -> void:
    super.configure_stage()
    stage_id = "M2C"
    stage_version = "0.1.0-m2c"
    window_label = "M2-C Ruins & Breakable Bricks"
    hud_title = "遗迹林道 · 裂纹砖与奖励支路"
    short_stage = "M2-C"
    finished_title = "遗迹林道，通关！"
    toast = "裂纹砖可用剑或苦力帕爆炸破坏；高处遗迹是可选奖励支路。"
    toast_left = 8

func fragile_specs() -> Array[Dictionary]:
    return [{"id": &"ruin_seal", "at": Vector2(1312,160), "loot": false},
        {"id": &"fuse_cache", "at": Vector2(1776,208), "loot": true}]

func setup_content() -> void:
    if loot_seed<=0: loot_seed = randi_range(1,2147483647)
    for spec in fragile_specs():
        var brick := FragileBrick.new()
        brick.brick_id = spec.id
        brick.position = spec.at
        brick.drops_emerald = spec.loot
        brick.random_loot = spec.get("random_loot",false)
        brick.wooden = spec.get("wood",false)
        $World.add_child(brick)
        fragile_bricks.append(brick)
        brick.shattered.connect(_brick_shattered)
    super.setup_content()
    player.block_bumped.connect(func(block: Node2D) -> void:
        if block is FragileBrick:
            block.bump(player))

func _place_fixed_pickups() -> void:
    super._place_fixed_pickups()
    _spawn_identified(cache_data, Vector2(1372,164), 1, run_id, &"forest_ruin_cache")

func _item_data(id: StringName) -> PickupData:
    return cache_data if id == cache_data.id else super._item_data(id)

func _brick_shattered(brick: FragileBrick) -> void:
    sound.play_stream(BLOCK_SOUND)
    toast = "裂纹砖已破坏 · 墙体与奖励会随检查点一起恢复"
    if brick.wooden: toast = "木封板已劈开 · 宝石藏在支路里"
    toast_left = 3
    if brick.random_loot:
        var reward:=AdventureRewards.reward(loot_seed,str(brick.brick_id))
        _queue_drop(reward,brick.global_position,1,StringName("fragile/"+str(brick.brick_id)))
        toast="裂纹宝箱 · %s" % reward.label
    elif brick.drops_emerald:
        _queue_drop(emerald_data,brick.global_position,1,StringName("fragile/" + str(brick.brick_id)))
    print("M2C_BREAK id=%s" % brick.brick_id)

func _make_snapshot(index: int) -> CheckpointSnapshot:
    var saved := super._make_snapshot(index)
    saved.loot_seed = loot_seed
    for brick in fragile_bricks:
        saved.broken_bricks[brick.brick_id] = brick.broken
    return saved

func restore_checkpoint() -> void:
    if not defeated or snapshot == null:
        return
    loot_seed = snapshot.loot_seed
    for brick in fragile_bricks:
        brick.apply_broken(snapshot.broken_bricks.get(brick.brick_id, false))
    super.restore_checkpoint()

func restart_course() -> void:
    for brick in fragile_bricks:
        brick.apply_broken(false)
    super.restart_course()

func result_hint() -> String:
    var broken := 0
    for brick in fragile_bricks:
        broken += int(brick.broken)
    return "已结算 %d · 待结算 %d · 裂纹砖 %d/2" % [banked_emeralds,items.emeralds - banked_emeralds,broken]
