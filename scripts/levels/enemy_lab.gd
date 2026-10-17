extends "res://scripts/levels/combat_lab.gd"

@export var zombie_data: EnemyData
@export var skeleton_data: EnemyData
@export var creeper_data: EnemyData
var sound: CombatSound
var enemy_shots: int = 0
var explosions: int = 0

func _ready() -> void:
    configure_stage()
    configure_view()
    sound = CombatSound.new()
    $World.add_child(sound)
    for spec in enemy_specs():
        var enemy := create_enemy(spec)
        enemy.data = spec.data
        enemy.ui_font = ui_font
        enemy.target = player
        enemy.view_camera = camera
        enemy.position = Vector2(spec.x, spec.get("y", 288))
        $World.add_child(enemy)
        targets.append(enemy)
        enemy.fired.connect(_enemy_fired)
        enemy.exploded.connect(_enemy_exploded)
        enemy.fuse_beep.connect(func() -> void: sound.play_effect(&"fuse"))
        enemy.health.damaged.connect(func(_event: DamageEvent) -> void: sound.play_effect(&"hit"))
    equipment.swung.connect(func() -> void: sound.play_effect(&"sword"))
    equipment.shot_fired.connect(func(_damage: int, _direction: Vector2) -> void: sound.play_effect(&"arrow"))
    health.damaged.connect(func(_event: DamageEvent) -> void: sound.play_effect(&"hit"))
    _update_sound_hint()
    setup_content()
    connect_run()

func create_enemy(_spec: Dictionary) -> RemixEnemy:
    return RemixEnemy.new()

func configure_stage() -> void:
    stage_id = "M1C"
    stage_version = "0.1.0-m1c"
    window_label = "M1-C Forest Encounter"
    hud_title = "林地遭遇 · 三怪试炼"
    target_label = "敌人"
    short_stage = "M1-C"
    next_hint = "下一阶段：补给砖、蘑菇与道具玩法"
    finished_title = "林地遭遇，通关！"
    course_width = 2880
    exit_x = 2750
    toast = "前方有僵尸。J 挥剑，K 切弓；击败全部 6 只怪物。"
    toast_left = 5

func enemy_specs() -> Array[Dictionary]:
    return [
        {"data": zombie_data, "x": 420}, {"data": skeleton_data, "x": 895},
        {"data": creeper_data, "x": 1460}, {"data": zombie_data, "x": 1990},
        {"data": creeper_data, "x": 2110}, {"data": skeleton_data, "x": 2380}
    ]

func setup_content() -> void:
    pass

func _enemy_fired(_arrow: ArrowProjectile) -> void:
    enemy_shots += 1
    sound.play_effect(&"arrow")

func _enemy_exploded() -> void:
    explosions += 1
    sound.play_effect(&"explosion")

func check_environment() -> void:
    if defeated or completed:
        return
    if player.position.y > 460:
        var fall := DamageEvent.create(course, 0, 4)
        fall.bypass_invulnerability = true
        fall.protection_override = 1.0
        health.queue_damage(fall)
        equipment.suspend_input()
        clear_projectiles()
        player.reset_at(Vector2(1160, 288))
        camera.reset_to_target()

func restart_course() -> void:
    super.restart_course()
    enemy_shots = 0
    explosions = 0
    sound.clear_active()

func _unhandled_input(event: InputEvent) -> void:
    super._unhandled_input(event)
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
        sound.muted = not sound.muted
        if sound.muted:
            sound.clear_active()
        _update_sound_hint()

func _update_sound_hint() -> void:
    footer_hint = "R 重置    ESC 暂停    M 音效%s    F11 全屏    F12 截图" % ("关" if sound.muted else "开")
