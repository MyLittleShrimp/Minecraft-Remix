extends "res://scripts/levels/pickup_lab.gd"

const CHECKPOINTS: Array[Dictionary] = [
    {"id": &"forest_start", "label": "林道入口", "x": 96.0},
    {"id": &"forest_camp_a", "label": "林间营火", "x": 784.0},
    {"id": &"forest_camp_b", "label": "断桥前哨", "x": 1408.0}
]
const ENEMY_IDS: Array[StringName] = [&"forest_zombie", &"forest_skeleton", &"forest_creeper"]
var snapshot: CheckpointSnapshot
var checkpoint_index: int = 0
var banked_emeralds: int = 0
var deaths: int = 0
var consumed_ids: Dictionary = {}
var pending_drops: Dictionary = {}

func checkpoint_specs() -> Array[Dictionary]:
    return CHECKPOINTS

func enemy_id(index: int) -> StringName:
    return ENEMY_IDS[index]

func checkpoint_requirements(index: int) -> Array:
    return range(index)

func configure_stage() -> void:
    super.configure_stage()
    stage_id = "M2B"
    stage_version = "0.1.0-m2b"
    window_label = "M2-B Checkpoint Trail"
    hud_title = "营火林道 · 检查点与重试"
    short_stage = "M2-B"
    next_hint = "下一阶段：脆弱砖与首关内容编排"
    finished_title = "营火林道，通关！"
    toast = "清除前段敌人，点亮营火。死亡按 Enter 回检查点；R 整关重来。"
    toast_left = 8

func setup_content() -> void:
    for i in targets.size():
        targets[i].set_meta("object_id", enemy_id(i))
    super.setup_content()
    snapshot = _make_snapshot(0)

func _place_fixed_pickups() -> void:
    _spawn_identified(emerald_data, Vector2(1688, 189), 1, run_id, &"forest_platform_gem")

func _block_opened(block: SupplyBlock, actor: RemixPlayer) -> void:
    sound.play_stream(BLOCK_SOUND)
    toast = "%s已弹出 · 到营火结算收集" % block.content.label
    toast_left = 2.5
    _queue_drop(block.content, block.global_position, actor.facing, StringName("block/" + str(block.block_id)))
    print("M2B_BLOCK id=%s" % block.block_id)

func _enemy_loot(enemy: RemixEnemy) -> void:
    _queue_drop(emerald_data, enemy.center(), 1, StringName("enemy/" + str(enemy.get_meta("object_id"))))

func _queue_drop(data: PickupData, at: Vector2, direction: int, id: StringName) -> void:
    if consumed_ids.has(id) or pending_drops.has(id):
        return
    # Register immediately: a checkpoint later in this same physics tick must
    # include the reward even if its deferred node does not exist yet.
    pending_drops[id] = {"id": id, "data": data.id, "position": at, "origin": at,
        "direction": direction, "velocity": Vector2.ZERO, "emerge_left": data.emerge_seconds}
    _flush_drop.call_deferred(id, run_id)

func _flush_drop(id: StringName, epoch: int) -> void:
    # A same-tick return to menu detaches the scene before deferred work runs.
    # The checkpoint already contains this pending reward for the next resume.
    if not is_inside_tree() or epoch != run_id or not pending_drops.has(id):
        return
    var record: Dictionary = pending_drops[id]
    pending_drops.erase(id)
    _spawn_identified(_item_data(record.data), record.origin, record.direction, epoch, id)

func _spawn_identified(data: PickupData, at: Vector2, direction: int, epoch: int, id: StringName) -> RemixPickup:
    if epoch != run_id or consumed_ids.has(id):
        return null
    for existing in get_tree().get_nodes_in_group("pickups"):
        if $World.is_ancestor_of(existing) and not existing.retired and existing.get_meta("object_id", &"") == id:
            return null
    var pickup := super.spawn_pickup(data, at, direction, epoch)
    if pickup != null:
        pickup.set_meta("object_id", id)
        _apply_pickup_layout(pickup)
    return pickup

func _apply_pickup_layout(_pickup: RemixPickup) -> void: pass

func _item_data(id: StringName) -> PickupData:
    for data in [mushroom_data, apple_data, emerald_data]:
        if data.id == id:
            return data
    return null

func _picked_up(pickup: RemixPickup, actor: RemixPlayer, amount: int) -> void:
    consumed_ids[pickup.get_meta("object_id")] = true
    super._picked_up(pickup, actor, amount)

func _make_snapshot(index: int) -> CheckpointSnapshot:
    var saved := CheckpointSnapshot.new()
    saved.checkpoint_index = index
    saved.checkpoint_id = checkpoint_specs()[index].id
    saved.spawn = Vector2(checkpoint_specs()[index].x, checkpoint_specs()[index].get("y", 288))
    saved.emeralds = items.emeralds
    if is_instance_valid(equipment.wallet): saved.emeralds_spent = equipment.wallet.spent
    saved.collected_count = items.collected_count
    saved.collected_kinds = collected_kinds.duplicate(true)
    saved.consumed_ids = consumed_ids.duplicate(true)
    saved.weapon_id = equipment.equipped().id
    saved.player_health = health.current
    var food := player.get_node_or_null("Hunger") as HungerComponent
    if food != null: saved.player_food = food.value
    for enemy in targets:
        saved.enemy_health[enemy.get_meta("object_id")] = enemy.health.current
    for block in blocks:
        saved.used_blocks[block.block_id] = block.used
    for pickup in get_tree().get_nodes_in_group("pickups"):
        if not $World.is_ancestor_of(pickup) or pickup.retired:
            continue
        saved.pickups.append({"id": pickup.get_meta("object_id"), "data": pickup.data.id,
            "position": pickup.global_position, "origin": pickup.origin, "direction": pickup.direction,
            "velocity": pickup.velocity, "emerge_left": pickup.emerge_left})
    for record in pending_drops.values():
        saved.pickups.append(record.duplicate(true))
    return saved

func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed:
        return
    if checkpoint_index < checkpoint_specs().size() - 1 and player.is_on_floor():
        var next := checkpoint_index + 1
        if absf(player.position.x - checkpoint_specs()[next].x) <= 24 and absf(player.position.y - checkpoint_specs()[next].get("y", 288)) <= 8:
            var cleared := true
            for i in checkpoint_requirements(next):
                cleared = cleared and targets[i].health.current <= 0
            if cleared:
                _activate_checkpoint(next)
            else:
                toast = "先击败这一段的敌人，再激活检查点。"
                toast_left = 2
    # A skipped/locked camp cannot be bypassed by killing enemies at the exit.
    if player.position.x >= exit_x and checkpoint_index < checkpoint_specs().size() - 1:
        play_seconds += delta
        toast = "先回头激活剩余路标，再前往出口。"
        toast_left = 2
        return
    super._physics_process(delta)
    if completed:
        banked_emeralds = items.emeralds

func can_activate_checkpoint(index: int) -> bool:
    return index == checkpoint_index + 1

func _activate_checkpoint(index: int) -> void:
    if not can_activate_checkpoint(index) or defeated or completed:
        return
    checkpoint_index = index
    snapshot = _make_snapshot(index)
    banked_emeralds = snapshot.emeralds
    var heals: bool = checkpoint_specs()[index].get("heals",true)
    if heals:
        health.heal(health.max_health)
        health.invulnerability_left = maxf(health.invulnerability_left, 1.0)
        clear_projectiles()
        equipment.suspend_input()
    toast = "%s已激活 · %s · 已结算 %d 绿宝石" % [checkpoint_specs()[index].label,"恢复满血" if heals else "不回血",banked_emeralds]
    toast_left = 5
    print("M2B_CHECKPOINT id=%s banked=%d pickups=%d" % [snapshot.checkpoint_id, banked_emeralds, snapshot.pickups.size()])

func _on_death() -> void:
    if defeated:
        return
    deaths += 1
    super._on_death()

func restore_checkpoint() -> void:
    if not defeated or snapshot == null:
        return
    run_id += 1
    pending_drops.clear()
    clear_projectiles()
    sound.clear_active()
    for pickup in get_tree().get_nodes_in_group("pickups"):
        if $World.is_ancestor_of(pickup):
            pickup.retire()
    consumed_ids = snapshot.consumed_ids.duplicate(true)
    items.reset_items()
    items.emeralds = snapshot.emeralds
    if is_instance_valid(equipment.wallet): equipment.wallet.spent = snapshot.emeralds_spent
    items.collected_count = snapshot.collected_count
    collected_kinds = snapshot.collected_kinds.duplicate(true)
    banked_emeralds = snapshot.emeralds
    checkpoint_index = snapshot.checkpoint_index
    for block in blocks:
        block.reset_block()
        block.used = snapshot.used_blocks[block.block_id]
    for enemy in targets:
        enemy.reset_target()
        enemy.health.current = snapshot.enemy_health[enemy.get_meta("object_id")]
        if enemy.health.current <= 0:
            # Do not emit death again: that would create a duplicate reward.
            enemy.state = RemixEnemy.State.DEAD
            enemy.receiver.set_deferred("collision_layer", 0)
        enemy.health.health_changed.emit(enemy.health.current, enemy.health.max_health)
    health.reset_health()
    if not checkpoint_specs()[checkpoint_index].get("heals",true):
        health.current = clampi(snapshot.player_health,10,health.max_health)
        health.health_changed.emit(health.current,health.max_health)
    health.invulnerability_left = 1.0
    var food := player.get_node_or_null("Hunger") as HungerComponent
    if food != null: food.restore(maxf(8.0,snapshot.player_food))
    equipment.reset_equipment()
    for i in equipment.weapons.size():
        if equipment.weapons[i].id == snapshot.weapon_id:
            equipment.slot = i
    player.reset_at(snapshot.spawn)
    player.visual.modulate = Color.WHITE
    camera.reset_to_target()
    defeated = false
    completed = false
    course_paused = false
    # Restore emerging as well as settled pickups; shared Resources stay immutable.
    for record in snapshot.pickups:
        var pickup := _spawn_identified(_item_data(record.data), record.origin, record.direction, run_id, record.id)
        if pickup != null:
            pickup.global_position = record.position
            pickup.origin = record.origin
            pickup.velocity = record.velocity
            pickup.emerge_left = record.emerge_left
            pickup.collision_mask = 0 if pickup.emerge_left > 0 else 3
            _apply_pickup_layout(pickup)
    get_tree().paused = false
    toast = "已回到%s · 生命 %d；强化清除，未结算收益回滚" % [checkpoint_specs()[checkpoint_index].label,health.current]
    toast_left = 5
    print("M2B_RESTORE id=%s banked=%d deaths=%d" % [snapshot.checkpoint_id, banked_emeralds, deaths])

func restart_course() -> void:
    pending_drops.clear()
    consumed_ids.clear()
    checkpoint_index = 0
    banked_emeralds = 0
    deaths = 0
    super.restart_course()
    snapshot = _make_snapshot(0)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
        restore_checkpoint()
        return
    super._unhandled_input(event)

func _update_sound_hint() -> void:
    footer_hint = "R 整关重来    ESC 暂停    M 音效%s    F11 全屏    F12 截图" % ("关" if sound.muted else "开")

func status_hint() -> String:
    if not is_instance_valid(items):
        return ""
    var effect := "力量 无" if items.strength_left <= 0 else "力量 %.1fs" % items.strength_left
    return "第 %d 段 · 检查点 %d/%d   |   绿宝石 已结算 %d + 待结算 %d   |   %s" % [checkpoint_index + 1, checkpoint_index, checkpoint_specs().size()-1, banked_emeralds, items.emeralds - banked_emeralds, effect]

func result_hint() -> String:
    return "已结算 %d · 待结算 %d · 倒下 %d 次" % [banked_emeralds, items.emeralds - banked_emeralds, deaths]

func panel_title() -> String:
    return "倒下了，再试一次" if defeated else (finished_title if completed else "林道暂停")

func panel_controls() -> String:
    if defeated:
        return "Enter 继续 · R 整关重来 · Q 退出"
    return "R 整关重来 · Q 退出" if completed else "ESC 继续 · R 整关重来 · Q 退出"

func panel_detail() -> String:
    if defeated:
        return "返回%s · 满血 · 本段奖励回滚" % checkpoint_specs()[checkpoint_index].label
    return "检查点仅在本次游玩中保留" if not completed else "奖励已结算 · 下一步：首关内容编排"
