extends Node2D
## M0: a visual input probe, not a character controller or a gameplay level.

const ACTIONS: Array[StringName] = [
    &"move_left", &"move_right", &"aim_up", &"aim_down",
    &"jump", &"attack", &"switch_weapon", &"interact", &"pause"
]
const LABELS: Array[String] = ["A / LEFT", "D / RIGHT", "W / AIM UP", "S / AIM DOWN", "SPACE / JUMP", "J / ATTACK", "K / WEAPON", "E / INTERACT", "ESC / PAUSE"]
const INK := Color("142831")
const CREAM := Color("edf2d5")
const MINT := Color("b9ed97")
const GOLD := Color("e8be71")

var action_count: Dictionary = {}
var flash_remaining: Dictionary = {}
var last_action: String = "WAITING FOR INPUT"
var probe_paused: bool = false
var facing: int = 1
var selected_slot: int = 0
var elapsed: float = 0.0
var capture_in_progress: bool = false
var current_frame_size := Vector2i.ZERO
var font: Font


func _ready() -> void:
    font = ThemeDB.fallback_font
    for action: StringName in ACTIONS:
        action_count[action] = 0
        flash_remaining[action] = 0.0
    get_window().min_size = Vector2i(640, 360)
    get_window().title = "Minecraft Remix | M0 Input Lab"
    print("M0_READY version=%s renderer=%s viewport=%s" % [
        ProjectSettings.get_setting("application/config/version"),
        RenderingServer.get_current_rendering_method(), get_viewport_rect().size
    ])
    if "--capture-and-exit" in OS.get_cmdline_user_args():
        _capture_and_exit()


func _process(delta: float) -> void:
    elapsed += delta
    for action: StringName in ACTIONS:
        flash_remaining[action] = maxf(0.0, float(flash_remaining[action]) - delta)
    var window_size: Vector2i = get_window().size
    if current_frame_size != window_size:
        current_frame_size = window_size
        print("M0_WINDOW size=%s viewport=%s" % [window_size, get_viewport_rect().size])
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        print("M0_KEY logical=%d physical=%d" % [event.keycode, event.physical_keycode])
        last_action = "KEY %d / PHYSICAL %d" % [event.keycode, event.physical_keycode]
        if event.keycode == KEY_F11:
            var fullscreen := get_window().mode == Window.MODE_FULLSCREEN
            get_window().mode = Window.MODE_WINDOWED if fullscreen else Window.MODE_FULLSCREEN
            get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_F12:
            capture_frame()
            get_viewport().set_input_as_handled()
            return
        if probe_paused and event.keycode == KEY_Q:
            print("M0_QUIT clean=true")
            get_tree().quit()
            return
    for action: StringName in ACTIONS:
        if not event.is_action_pressed(action, false):
            continue
        if probe_paused and action != &"pause":
            return
        action_count[action] = int(action_count[action]) + 1
        flash_remaining[action] = 0.8
        last_action = String(action).to_upper()
        if action == &"pause":
            probe_paused = not probe_paused
        elif action == &"move_left":
            facing = -1
        elif action == &"move_right":
            facing = 1
        elif action == &"switch_weapon":
            selected_slot = 1 - selected_slot
        print("M0_INPUT action=%s count=%d paused=%s" % [action, action_count[action], probe_paused])
        get_viewport().set_input_as_handled()
        queue_redraw()
        return


func capture_frame() -> void:
    if capture_in_progress or DisplayServer.get_name() == "headless":
        return
    capture_in_progress = true
    await RenderingServer.frame_post_draw
    var directory := OS.get_environment("REMIX_CAPTURE_DIR")
    if directory.is_empty():
        directory = "user://captures"
    var absolute := ProjectSettings.globalize_path(directory)
    var directory_error := DirAccess.make_dir_recursive_absolute(absolute)
    if directory_error != OK:
        push_error("Cannot create capture directory: %s" % directory_error)
        capture_in_progress = false
        return
    var path := absolute.path_join("m0_%s.png" % Time.get_datetime_string_from_system().replace(":", "-"))
    var error := get_viewport().get_texture().get_image().save_png(path)
    print("M0_CAPTURE result=%s path=%s" % [error, path])
    capture_in_progress = false


func _capture_and_exit() -> void:
    await get_tree().create_timer(1.0).timeout
    await capture_frame()
    get_tree().quit()


func _text(at: Vector2, value: String, size: int = 12, color: Color = CREAM) -> void:
    draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _box(rect: Rect2, color: Color) -> void:
    draw_rect(rect, color)


func _tree(x: int, y: int, tint: Color) -> void:
    _box(Rect2(x + 19, y + 34, 10, 60), tint.darkened(0.4))
    _box(Rect2(x + 5, y + 18, 39, 39), tint)
    _box(Rect2(x + 12, y + 4, 27, 19), tint.lightened(0.08))
    _box(Rect2(x, y + 29, 48, 17), tint)
    _box(Rect2(x + 10, y + 21, 9, 6), tint.lightened(0.12))


func _draw_world() -> void:
    _box(Rect2(0, 0, 640, 360), Color("18313c"))
    _box(Rect2(0, 84, 640, 165), Color("315359"))
    _box(Rect2(299, 105, 36, 36), Color("cbbf8d"))
    _box(Rect2(293, 111, 48, 24), Color("cbbf8d"))
    for cloud: Rect2 in [Rect2(72, 105, 66, 7), Rect2(207, 128, 48, 5), Rect2(355, 90, 67, 7)]:
        _box(cloud, Color("567077"))
    draw_polygon(PackedVector2Array([Vector2(0, 190), Vector2(42, 153), Vector2(87, 173), Vector2(126, 132), Vector2(182, 180), Vector2(235, 149), Vector2(313, 198), Vector2(379, 155), Vector2(452, 190), Vector2(640, 162), Vector2(640, 258), Vector2(0, 258)]), PackedColorArray([Color("294a4c")]))
    for x: int in [0, 75, 115, 256, 353, 408, 555]:
        _tree(x, 156 + (x % 19), Color("2d5349"))
    _tree(44, 131, Color("416b4b"))
    _tree(351, 141, Color("416b4b"))
    for col: int in range(20):
        var x := col * 32
        _box(Rect2(x, 254, 32, 106), Color("503e32") if col % 2 == 0 else Color("574333"))
        _box(Rect2(x, 254, 32, 7), Color("92bf68"))
        _box(Rect2(x, 261, 32, 6), Color("587644"))
        _box(Rect2(x + 5, 270 + col % 3 * 6, 8, 5), Color("7a5840"))
        _box(Rect2(x + 21, 281 + col % 4 * 8, 6, 4), Color("352f2b"))
    for x: int in [127, 148, 280, 304, 324]:
        _box(Rect2(x, 249, 2, 5), Color("a2c779"))
        _box(Rect2(x - 2, 247, 2, 3), Color("79a363"))
    # A small, original placeholder: all geometry is in logical pixels.
    var origin := Vector2(213, 206)
    draw_set_transform(origin)
    _box(Rect2(-4, 46, 34, 3), Color("304334"))
    _box(Rect2(4, 0, 20, 17), Color("a77c58"))
    _box(Rect2(4, 0, 20, 5), Color("493d36"))
    _box(Rect2(4 if facing == 1 else 19, 5, 5, 10), Color("594638"))
    _box(Rect2(18 if facing == 1 else 7, 8, 4, 3), Color("c6d8dc"))
    _box(Rect2(20 if facing == 1 else 7, 8, 2, 3), Color("56659a"))
    _box(Rect2(4, 17, 20, 18), Color("46a6a8"))
    _box(Rect2(0, 18, 6, 16), Color("388387"))
    _box(Rect2(0, 30, 6, 8), Color("b68b66"))
    _box(Rect2(22, 18, 6, 18), Color("53b8b7"))
    _box(Rect2(22, 30, 6, 8), Color("b68b66"))
    _box(Rect2(5, 35, 8, 11), Color("505c8c"))
    _box(Rect2(15, 35, 8, 11), Color("424f7d"))
    _box(Rect2(4, 44, 10, 4), Color("303b49"))
    _box(Rect2(15, 44, 10, 4), Color("303b49"))
    if selected_slot == 0:
        _box(Rect2(30, 17, 4, 23), Color("8c8fa9"))
        _box(Rect2(31, 13, 2, 8), Color("c0bdcf"))
        _box(Rect2(27, 35, 10, 3), Color("5b536b"))
    else:
        _box(Rect2(30, 12, 3, 30), Color("a9835f"))
        _box(Rect2(33, 15, 3, 24), Color("a9835f"))
        _box(Rect2(29, 13, 1, 28), Color("c6d8bd"))
    draw_set_transform(Vector2.ZERO)
    if float(flash_remaining.get(&"attack", 0.0)) > 0.0:
        _box(Rect2(253 if facing == 1 else 175, 224, 28, 3), GOLD)
    if float(flash_remaining.get(&"jump", 0.0)) > 0.0:
        _text(Vector2(203, 197), "JUMP", 10, MINT)


func _draw() -> void:
    if font == null:
        return
    _draw_world()
    _box(Rect2(0, 0, 640, 76), INK)
    _box(Rect2(24, 21, 5, 30), MINT)
    _text(Vector2(40, 36), "MINECRAFT REMIX", 22)
    _text(Vector2(41, 55), "A BLOCK-BUILT SIDE-SCROLLING ADVENTURE", 10, Color("90b5ad"))
    _box(Rect2(508, 22, 108, 25), Color("2d4e46"))
    _text(Vector2(521, 39), "M0 / INPUT LAB", 11, MINT)
    _box(Rect2(438, 91, 178, 151), Color("182f36"))
    _text(Vector2(450, 110), "INPUT MONITOR", 12, MINT)
    for i: int in range(ACTIONS.size()):
        var active := float(flash_remaining[ACTIONS[i]]) > 0.0
        _box(Rect2(450, 119 + i * 12, 4, 4), MINT if active else Color("3d5455"))
        _text(Vector2(461, 124 + i * 12), LABELS[i], 9, MINT if active else Color("9bb2af"))
        _text(Vector2(591, 124 + i * 12), str(action_count[ACTIONS[i]]), 9, MINT)
    _box(Rect2(20, 94, 107, 20), Color("223e40"))
    _text(Vector2(29, 108), "FOREST / TEST 00", 10, Color("c5d5bd"))
    _text(Vector2(168, 285), "INPUT PROBE  /  " + ("SWORD" if selected_slot == 0 else "BOW"), 10, GOLD)
    _box(Rect2(20, 301, 596, 43), INK)
    _box(Rect2(20, 301, 3, 43), MINT)
    _text(Vector2(33, 318), "LAST: " + last_action, 11, MINT)
    _text(Vector2(33, 334), "F11 fullscreen    F12 capture    ESC pause / quit", 10, Color("a1b9b4"))
    _text(Vector2(405, 318), "640 x 360  /  PIXEL VIEW", 10, Color("a1b9b4"))
    _text(Vector2(405, 334), "Movement & combat arrive in M1", 9, Color("8baba5"))
    if probe_paused:
        _box(Rect2(0, 76, 640, 225), Color(0.04, 0.09, 0.12, 0.86))
        _box(Rect2(177, 136, 286, 96), INK)
        _box(Rect2(177, 136, 286, 3), MINT)
        _text(Vector2(273, 170), "PAUSED", 22)
        _text(Vector2(230, 197), "ESC  resume    /    Q  quit", 13, MINT)
        _text(Vector2(210, 217), "M0 checks input, rendering and export.", 11, Color("a1b9b4"))
