extends "res://scripts/levels/enemy_lab.gd"

const BLOCK_SCENE = preload("res://scenes/items/supply_block.tscn")
const BLOCK_SOUND = preload("res://assets/audio/block.wav")
const PICKUP_SOUND = preload("res://assets/audio/pickup.wav")
@export var mushroom_data: PickupData
@export var apple_data: PickupData
@export var emerald_data: PickupData
@onready var items: PlayerItems = $World/Steve/ItemEffects
var blocks: Array[SupplyBlock] = []
var run_id: int = 0
var drops_spawned: int = 0
var collected_kinds: Dictionary = {}

func configure_stage() -> void:
    stage_id = "M2A"
    stage_version = "0.1.0-m2a.1"
    window_label = "M2-A.1 Blocks & Pickups"
    hud_title = "补给林道 · 顶砖与道具"
    target_label = "敌人"
    short_stage = "M2-A"
    next_hint = "下一阶段：检查点与首关闭环"
    finished_title = "补给林道，通关！"
    course_width = 2400
    exit_x = 2280
    toast = "在问号砖下跳跃。红蘑菇强化剑弓；所有补给均可选。"
    toast_left = 6

func enemy_specs() -> Array[Dictionary]:
    return [{"data": zombie_data, "x": 650}, {"data": skeleton_data, "x": 1200}, {"data": creeper_data, "x": 1800}]

func block_specs() -> Array[Dictionary]:
    return [
        {"id": &"intro_strength", "x": 224, "data": mushroom_data},
        {"id": &"pair_left", "x": 352, "data": emerald_data},
        {"id": &"pair_right", "x": 384, "data": emerald_data},
        {"id": &"recovery", "x": 896, "data": apple_data},
        {"id": &"second_strength", "x": 1496, "data": mushroom_data}
    ]
func setup_content() -> void:
    for spec in block_specs():
        var block: SupplyBlock = BLOCK_SCENE.instantiate()
        block.position = Vector2(spec.x, spec.get("y", 208))
        block.block_id = spec.id
        block.content = spec.data
        $World.add_child(block)
        blocks.append(block)
        block.opened.connect(_block_opened)
    player.block_bumped.connect(func(block: Node2D) -> void:
        if block is SupplyBlock and blocks.has(block):
            block.bump(player))
    for enemy in targets:
        enemy.defeated.connect(_enemy_loot)
    _place_fixed_pickups()

func _place_fixed_pickups() -> void:
    spawn_pickup(emerald_data, Vector2(1688, 189), 1, run_id)

func _block_opened(block: SupplyBlock, actor: RemixPlayer) -> void:
    sound.play_stream(BLOCK_SOUND)
    toast = "%s已弹出 · 空砖不会重复掉落" % block.content.label
    toast_left = 2.5
    # Epoch prevents a deferred opening from producing a ghost item after R.
    spawn_pickup.call_deferred(block.content, block.global_position, actor.facing, run_id)
    print("M2A_BLOCK id=%s" % block.block_id)

func _enemy_loot(enemy: RemixEnemy) -> void:
    spawn_pickup.call_deferred(emerald_data, enemy.center(), 1, run_id)

func spawn_pickup(data: PickupData, at: Vector2, facing: int, epoch: int) -> RemixPickup:
    if epoch != run_id or defeated or completed:
        return null
    var pickup := RemixPickup.new()
    pickup.data = data
    pickup.direction = facing
    pickup.position = at
    pickup.collected.connect(_picked_up)
    $World.add_child(pickup)
    drops_spawned += 1
    return pickup

func _picked_up(pickup: RemixPickup, _actor: RemixPlayer, amount: int) -> void:
    collected_kinds[pickup.data.id] = int(collected_kinds.get(pickup.data.id, 0)) + 1
    sound.play_stream(PICKUP_SOUND)
    match pickup.data.kind:
        PickupData.Kind.MUSHROOM:
            toast = pickup.data.effect_hint()
        PickupData.Kind.APPLE:
            toast = "苹果恢复 %d HP · 满血的苹果会留在原地" % amount
        PickupData.Kind.BREAD:
            toast = "面包恢复 %d 饱食度 · 不自动回血" % amount
        PickupData.Kind.MEAT:
            toast = "%s恢复 %d 饱食度" % [pickup.data.label,amount]
        PickupData.Kind.EMERALD:
            toast = "绿宝石 +%d · 本关收集 %d，R 重试归零" % [amount, items.emeralds]
    toast_left = 3
    print("M2A_PICKUP kind=%s amount=%d hp=%d emeralds=%d" % [pickup.data.id, amount, health.current, items.emeralds])

func status_hint() -> String:
    if not is_instance_valid(items):
        return ""
    var opened := 0
    for block in blocks:
        opened += int(block.used)
    var effect := "力量：无" if items.strength_left <= 0 else "力量 ×1.25  %.1f 秒" % items.strength_left
    return "%s    |    绿宝石 %d    |    补给砖 %d / %d" % [effect, items.emeralds, opened, blocks.size()]

func check_environment() -> void:
    if not defeated and not completed and player.position.y > 460:
        var fall := DamageEvent.create(course, 0, 4)
        fall.bypass_invulnerability = true
        fall.protection_override = 1.0
        health.queue_damage(fall)
        equipment.suspend_input()
        clear_projectiles()
        player.reset_at(Vector2(1860, 288))
        camera.reset_to_target()

func result_hint() -> String:
    var opened := 0
    for block in blocks:
        opened += int(block.used)
    return "绿宝石 %d  ·  拾取 %d  ·  补给砖 %d / %d" % [items.emeralds, items.collected_count, opened, blocks.size()]

func restart_course() -> void:
    run_id += 1
    for pickup in get_tree().get_nodes_in_group("pickups"):
        if $World.is_ancestor_of(pickup):
            pickup.retire()
    items.reset_items()
    collected_kinds.clear()
    drops_spawned = 0
    super.restart_course()
    for block in blocks:
        block.reset_block()
    _place_fixed_pickups()
    toast = "已重置：补给砖、道具、强化、收集数与敌人全部复位。"
