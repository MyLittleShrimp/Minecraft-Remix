extends Node2D

@export var ui_font: Font
@onready var player: RemixPlayer = $World/Steve
@onready var camera: PixelFollowCamera = $World/Camera
@onready var health: HealthComponent = $World/Steve/Health
@onready var equipment: WeaponController = $World/Steve/Equipment
@onready var course: Node2D = $World/Course
var targets: Array[Node2D] = []
var stage_id: String = "M1B"
var stage_version: String = "0.1.0-m1b"
var window_label: String = "M1-B Sword & Bow"
var course_width: float = 2240
var exit_x: float = 2100
var hud_title: String = "剑与弓 · 训练营"
var target_label: String = "木靶"
var short_stage: String = "M1-B"
var next_hint: String = "下一阶段：僵尸、骷髅射手与苦力帕"
var footer_hint: String = "R 重置训练    ESC 暂停    F11 全屏    F12 截图"
var finished_title: String = "训练完成！"
var course_paused: bool = false
var completed: bool = false
var defeated: bool = false
var play_seconds: float = 0.0
var hits_received: int = 0
var capture_busy: bool = false
var toast: String = "清除 5 个木靶，穿过训练营。J 攻击，K 切换剑弓。"
var toast_left: float = 5.0

func _ready() -> void:
    configure_view()
    var positions: Array[Vector2] = [Vector2(276, 288), Vector2(650, 288), Vector2(906, 288), Vector2(1104, 224), Vector2(1830, 288)]
    var points: Array[int] = [18, 8, 12, 10, 18]
    for index in positions.size():
        var dummy := TrainingDummy.new()
        dummy.name = "Target%d" % (index + 1)
        dummy.position = positions[index]
        dummy.hit_points = points[index]
        dummy.ui_font = ui_font
        dummy.label = "木靶 %d" % (index + 1)
        $World.add_child(dummy)
        targets.append(dummy)
    connect_run()

func configure_view() -> void:
    get_window().title = "Minecraft Remix | " + window_label
    get_window().min_size = Vector2i(640, 360)
    camera.course_width = course_width
    camera.target = player
    camera.reset_to_target()
    $Backdrop/Art.camera = camera
    $UI/HUD.level = self

func connect_run() -> void:
    health.damaged.connect(_on_damage)
    health.died.connect(_on_death)
    print("%s_READY version=%s targets=%d" % [stage_id, stage_version, targets.size()])
    if "--capture-and-exit" in OS.get_cmdline_user_args():
        _capture_and_exit()

func _physics_process(delta: float) -> void:
    if course_paused or completed or defeated:
        return
    play_seconds += delta
    toast_left = maxf(0, toast_left - delta)
    player.visual.modulate = Color("efac95") if health.invulnerability_left > 0.0 and int(health.invulnerability_left * 16) % 2 == 0 else Color.WHITE
    if player.position.x >= exit_x and player.is_on_floor():
        if cleared_count() == targets.size():
            completed = true
            equipment.suspend_input()
            clear_projectiles()
            get_tree().paused = true
            print("%s_FINISH seconds=%.2f hp=%d targets=%d" % [stage_id, play_seconds, health.current, cleared_count()])
        else:
            toast = "还有 %d 个%s，可以向左返回。" % [targets.size() - cleared_count(), target_label]
            toast_left = 2

func check_environment() -> void:
    # Called by the pausable course at priority 5, before Health resolves at 100.
    if defeated or completed:
        return
    var body_rect := Rect2(player.position + Vector2(-9, -44), Vector2(18, 44))
    if body_rect.intersects(course.SPIKES):
        var direction := -1.0 if player.position.x < course.SPIKES.get_center().x else 1.0
        health.queue_damage(DamageEvent.create(course, 0, 3, Vector2(direction * 180, -220)))
    if player.position.y > 460:
        var fall := DamageEvent.create(course, 0, 4)
        fall.bypass_invulnerability = true
        fall.protection_override = 1.0
        health.queue_damage(fall)
        equipment.suspend_input()
        clear_projectiles()
        player.reset_at(Vector2(96, 288))
        camera.reset_to_target()

func cleared_count() -> int:
    var count := 0
    for target in targets:
        if target.health.current <= 0:
            count += 1
    return count

func status_hint() -> String:
    return ""

func result_hint() -> String:
    return ""

func panel_title() -> String:
    return "倒下了，再试一次" if defeated else (finished_title if completed else "训练暂停")

func panel_controls() -> String:
    if defeated:
        return "R 恢复满血并重置训练 · Q 退出"
    return "R 再练一次 · Q 退出" if completed else "ESC 继续 · R 重新开始 · Q 退出"

func panel_detail() -> String:
    return next_hint

func _on_damage(event: DamageEvent) -> void:
    hits_received += 1
    toast = "受到 %d 点伤害 · 闪烁时有短暂保护" % event.amount
    toast_left = 2.5
    print("%s_HURT amount=%d hp=%d" % [stage_id, event.amount, health.current])

func _on_death() -> void:
    defeated = true
    equipment.suspend_input()
    clear_projectiles()
    get_tree().paused = true
    print("%s_DEATH once=true" % stage_id)

func clear_projectiles() -> void:
    for arrow in get_tree().get_nodes_in_group("projectiles"):
        if $World.is_ancestor_of(arrow):
            arrow.retire()
    for effect in get_tree().get_nodes_in_group("transient_effects"):
        if $World.is_ancestor_of(effect):
            effect.retire()

func restart_course() -> void:
    get_tree().paused = false
    course_paused = false
    completed = false
    defeated = false
    play_seconds = 0.0
    hits_received = 0
    clear_projectiles()
    health.reset_health()
    equipment.reset_equipment()
    player.reset_at(Vector2(96, 288))
    player.visual.modulate = Color.WHITE
    camera.reset_to_target()
    for target in targets:
        target.reset_target()
    toast = "训练已重置：生命、%s、武器和箭矢均已复位。" % target_label
    toast_left = 3
    print("%s_RESTART clean=true" % stage_id)

func set_paused(value: bool) -> void:
    if defeated or completed:
        return
    course_paused = value
    player.buffer_left = 0.0
    equipment.suspend_input()
    get_tree().paused = value
    print("%s_PAUSE value=%s" % [stage_id, value])

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and DisplayServer.get_name() != "headless":
        set_paused(true)

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_ESCAPE:
            set_paused(not course_paused)
        KEY_R:
            restart_course()
        KEY_Q:
            if course_paused or completed or defeated:
                get_tree().quit()
        KEY_F11:
            ScreenLayout.toggle_fullscreen()
        KEY_F12:
            capture_frame()

func capture_frame() -> void:
    if capture_busy or DisplayServer.get_name() == "headless":
        return
    capture_busy = true
    await RenderingServer.frame_post_draw
    var directory := OS.get_environment("REMIX_CAPTURE_DIR")
    if directory.is_empty():
        directory = "user://captures"
    var absolute := ProjectSettings.globalize_path(directory)
    var error := DirAccess.make_dir_recursive_absolute(absolute)
    if error == OK:
        var path := absolute.path_join("%s_%s.png" % [stage_id.to_lower(), Time.get_datetime_string_from_system().replace(":", "-")])
        error = get_viewport().get_texture().get_image().save_png(path)
        print("%s_CAPTURE result=%d path=%s" % [stage_id, error, path])
    capture_busy = false

func _capture_and_exit() -> void:
    await get_tree().create_timer(1.0).timeout
    await capture_frame()
    get_tree().quit()

func _exit_tree() -> void:
    get_tree().paused = false
