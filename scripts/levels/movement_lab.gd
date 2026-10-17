extends Node2D

@onready var player: RemixPlayer = $World/Steve
@onready var camera: PixelFollowCamera = $World/Camera
@onready var course: Node2D = $World/Course
var return_index: int = 0
var falls: int = 0
var jumps: int = 0
var play_seconds: float = 0.0
var course_paused: bool = false
var completed: bool = false
var toast: String = "向右出发：长按空格可以跳得更高"
var toast_left: float = 5.0
var capture_busy: bool = false

func _ready() -> void:
    get_window().title = "Minecraft Remix | M1-A Forest Trial"
    get_window().min_size = Vector2i(640, 360)
    $Backdrop/Art.camera = camera
    $UI/HUD.level = self
    player.jumped.connect(_on_jump)
    camera.target = player
    camera.reset_to_target()
    print("M1A_READY version=0.1.0-m1a viewport=%s" % get_viewport_rect().size)
    if "--capture-and-exit" in OS.get_cmdline_user_args():
        _capture_and_exit()

func _physics_process(delta: float) -> void:
    if course_paused or completed:
        return
    play_seconds += delta
    toast_left = maxf(0.0, toast_left - delta)
    if player.position.y > 460.0:
        respawn()
        return
    for index in range(return_index + 1, course.RETURN_POINTS.size()):
        var point: Vector2 = course.RETURN_POINTS[index]
        if player.is_on_floor() and absf(player.position.x - point.x) <= 28.0 and absf(player.position.y - point.y) < 5.0:
            return_index = index
            toast = "路标 %d 已点亮，掉落后从这里继续" % (index + 1)
            toast_left = 3.0
            print("M1A_RETURN_POINT index=%d x=%.1f" % [index, player.position.x])
    if player.position.x >= 2400.0 and player.is_on_floor():
        completed = true
        player.clear_jump_memory()
        get_tree().paused = true
        print("M1A_FINISH seconds=%.2f jumps=%d returns=%d" % [play_seconds, jumps, falls])

func _on_jump() -> void:
    jumps += 1
    print("M1A_JUMP x=%.1f y=%.1f" % [player.position.x, player.position.y])

func section_index() -> int:
    if player.position.x < 640:
        return 0
    if player.position.x < 1152:
        return 1
    if player.position.x < 1792:
        return 2
    return 3

func respawn() -> void:
    falls += 1
    player.reset_at(course.RETURN_POINTS[return_index])
    camera.reset_to_target()
    toast = "已返回路标 %d，再试一次吧" % (return_index + 1)
    toast_left = 2.5
    print("M1A_RESPAWN index=%d count=%d" % [return_index, falls])

func restart_course() -> void:
    get_tree().paused = false
    course_paused = false
    completed = false
    return_index = 0
    falls = 0
    jumps = 0
    play_seconds = 0
    player.reset_at(course.RETURN_POINTS[0])
    camera.reset_to_target()
    toast = "新的尝试，从林地出发"
    toast_left = 3

func set_paused(value: bool) -> void:
    course_paused = value
    # Discard queued jumps, but keep the in-flight jump state for release-to-cut.
    player.buffer_left = 0.0
    get_tree().paused = value
    print("M1A_PAUSE value=%s position=%s" % [value, player.position])

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE and not completed:
        set_paused(not course_paused)
    elif event.keycode == KEY_R and not course_paused:
        if completed:
            restart_course()
        else:
            respawn()
    elif event.keycode == KEY_Q and (course_paused or completed):
        print("M1A_QUIT clean=true")
        get_tree().quit()
    elif event.keycode == KEY_F11:
        ScreenLayout.toggle_fullscreen()
    elif event.keycode == KEY_F12:
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
        var path := absolute.path_join("m1a_%s.png" % Time.get_datetime_string_from_system().replace(":", "-"))
        error = get_viewport().get_texture().get_image().save_png(path)
        print("M1A_CAPTURE result=%d path=%s" % [error, path])
    else:
        push_error("Capture directory failed: %d" % error)
    capture_busy = false

func _capture_and_exit() -> void:
    await get_tree().create_timer(1.0).timeout
    await capture_frame()
    get_tree().quit()

func _exit_tree() -> void:
    get_tree().paused = false
