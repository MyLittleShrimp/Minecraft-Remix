extends Node
## Keep the authored 640x360 interface centered while the world and backdrop
## extend to the actual display. Physics coordinates and sprite proportions stay intact.
const BASE := Vector2(640,360)
var ui_offset := Vector2.ZERO
var logical_size := BASE
var previous_mode := Window.MODE_WINDOWED
var previous_size := Vector2i(1280,720)
var previous_position := Vector2i.ZERO
var scene: Node

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    get_window().size_changed.connect(refresh)
    refresh()

func _process(_delta: float) -> void:
    if scene!=get_tree().current_scene:
        scene=get_tree().current_scene
        refresh()

func refresh() -> void:
    logical_size=get_viewport().get_visible_rect().size
    ui_offset=(logical_size-BASE)*0.5
    var active:=get_tree().current_scene
    if not is_instance_valid(active): return
    if active is Control:
        active.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        active.position=ui_offset
        active.size=BASE
        active.queue_redraw()
    var ui:=active.get_node_or_null("UI") as CanvasLayer
    if ui: ui.offset=ui_offset
    var backdrop:=active.get_node_or_null("Backdrop") as CanvasLayer
    if backdrop:
        var factor:=maxf(logical_size.x/BASE.x,logical_size.y/BASE.y)
        backdrop.scale=Vector2.ONE*factor
        backdrop.offset=(logical_size-BASE*factor)*0.5
    var camera:=get_viewport().get_camera_2d()
    if camera and camera.has_method("refresh_bounds"): camera.refresh_bounds()

func full_rect() -> Rect2:
    return Rect2(-ui_offset,logical_size)

func toggle_fullscreen() -> void:
    var window:=get_window()
    if window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]:
        window.mode=Window.MODE_WINDOWED
        window.size=previous_size
        window.position=previous_position
        if previous_mode==Window.MODE_MAXIMIZED: window.mode=Window.MODE_MAXIMIZED
    else:
        previous_mode=window.mode
        previous_size=window.size
        previous_position=window.position
        window.mode=Window.MODE_FULLSCREEN
    refresh.call_deferred()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode==KEY_F11:
        if event.pressed and not event.echo: toggle_fullscreen()
        get_viewport().set_input_as_handled()
