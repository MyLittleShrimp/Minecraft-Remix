extends Node2D

@export var ui_font: Font
const SOLIDS: Array[Rect2] = [
    Rect2(-32, 0, 32, 512), Rect2(2560, 0, 32, 512),
    Rect2(0, 288, 560, 224), Rect2(640, 288, 416, 224),
    Rect2(1152, 288, 560, 224), Rect2(1792, 288, 768, 224),
    Rect2(320, 256, 64, 32), Rect2(416, 224, 64, 64),
    Rect2(768, 180, 96, 24), Rect2(1540, 208, 64, 80),
    Rect2(1984, 256, 64, 32), Rect2(2112, 224, 64, 64)
]
const PLATFORMS: Array[Rect2] = [Rect2(1280, 224, 96, 12), Rect2(1408, 176, 96, 12)]
const RETURN_POINTS: Array[Vector2] = [Vector2(96, 288), Vector2(704, 288), Vector2(1216, 288), Vector2(1856, 288)]

func _ready() -> void:
    for rect in SOLIDS:
        _add_collision(rect, false)
    for rect in PLATFORMS:
        _add_collision(rect, true)

func _add_collision(rect: Rect2, one_way: bool) -> void:
    var body := StaticBody2D.new()
    body.position = rect.get_center()
    body.collision_layer = 2 if one_way else 1
    body.collision_mask = 0
    if one_way:
        body.add_to_group("one_way")
    var shape := RectangleShape2D.new()
    shape.size = rect.size
    var collider := CollisionShape2D.new()
    collider.shape = shape
    collider.one_way_collision = one_way
    collider.one_way_collision_margin = 6.0
    body.add_child(collider)
    add_child(body)

func _draw() -> void:
    for rect in SOLIDS:
        if rect.size.y >= 400:
            continue
        draw_rect(rect, Color("6f5941"))
        for row in range(0, int(rect.size.y), 32):
            for col in range(0, int(rect.size.x), 32):
                var tile := Vector2(rect.position.x + col, rect.position.y + row)
                var seed_value := int(tile.x / 32) * 7 + row
                draw_rect(Rect2(tile, Vector2(minf(31, rect.size.x - col), minf(31, rect.size.y - row))), Color("816044") if seed_value % 3 == 0 else Color("75573f"))
                if row > 0 or rect.size.y > 32:
                    draw_rect(Rect2(tile + Vector2(5, 12), Vector2(7, 4)), Color("99734e"))
                    draw_rect(Rect2(tile + Vector2(21, 23), Vector2(6, 4)), Color("594532"))
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("a9ca68"))
        draw_rect(Rect2(rect.position + Vector2(0, 5), Vector2(rect.size.x, 5)), Color("598151"))
    for rect in PLATFORMS:
        draw_rect(rect, Color("654d3b"))
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("d8b578"))
        for offset in range(0, int(rect.size.x), 16):
            draw_rect(Rect2(rect.position + Vector2(offset + 1, 3), Vector2(14, 6)), Color("ac8051"))
        for offset in [8, int(rect.size.x) - 10]:
            draw_rect(Rect2(rect.position + Vector2(offset, 10), Vector2(3, 15)), Color("6f6450"))
    for index in RETURN_POINTS.size():
        var point := RETURN_POINTS[index]
        draw_rect(Rect2(point + Vector2(22, -36), Vector2(3, 36)), Color("4d5143"))
        draw_rect(Rect2(point + Vector2(25, -36), Vector2(21, 13)), Color("f3c979"))
        draw_string(ui_font, point + Vector2(29, -26), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("504735"))
    _sign(Vector2(184, 221), "长按跳得更高", "SPACE")
    _sign(Vector2(866, 221), "留意头顶", "短按跳跃")
    _sign(Vector2(1230, 132), "穿过木台 / 落在上面", "S + SPACE 下落")
    _sign(Vector2(1880, 188), "最后一段！", "向右抵达营地")
    # Decorative camp gate. Reaching it finishes only this movement course.
    draw_rect(Rect2(2422, 216, 7, 72), Color("4a5141"))
    draw_rect(Rect2(2429, 216, 37, 24), Color("b9d889"))
    draw_rect(Rect2(2436, 223, 6, 6), Color("4d7561"))
    draw_rect(Rect2(2448, 223, 6, 6), Color("4d7561"))
    draw_rect(Rect2(2442, 230, 6, 5), Color("4d7561"))
    for x in [34, 272, 506, 688, 962, 1200, 1648, 1830, 2290, 2518]:
        draw_rect(Rect2(x, 282, 2, 6), Color("779c55"))
        draw_rect(Rect2(x - 2, 280, 2, 4), Color("adc975"))
        draw_rect(Rect2(x + 3, 284, 2, 4), Color("779c55"))

func _sign(at: Vector2, title: String, subtitle: String) -> void:
    if not get_node("/root/ControlSettings").guide_enabled: return
    draw_string(ui_font, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("edf0c8"))
    draw_string(ui_font, at + Vector2(0, 16), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("bbd0b1"))
