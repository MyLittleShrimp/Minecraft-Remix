extends Node2D

@export var ui_font: Font
const WHITE := Color("edf1ce")
const MINT := Color("b9d889")
var level: Node
const HEART: Array[String] = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]

func _process(_delta: float) -> void:
    queue_redraw()

func _text(at: Vector2, value: String, size: int = 12, color: Color = WHITE) -> void:
    draw_string(ui_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
    if not is_instance_valid(level):
        return
    draw_rect(Rect2(0, 0, 640, 56), Color("183c3c"))
    draw_rect(Rect2(16, 12, 3, 30), MINT)
    _text(Vector2(27, 28), "方块远征", 19)
    _text(Vector2(28, 44), level.hud_title, 10, MINT)
    for index in 10:
        var amount: int = clampi(level.health.current - index * 2, 0, 2)
        _heart(Vector2(172 + index * 17, 15), amount)
    _text(Vector2(172, 44), "%d / 20 HP" % level.health.current, 10, MINT)
    _text(Vector2(257, 44), "0.8 秒受击保护", 10, Color("adbdad"))
    _text(Vector2(391, 26), "%s %d / %d" % [level.target_label, level.cleared_count(), level.targets.size()], 14)
    _text(Vector2(391, 43), "%02d:%02d" % [int(level.play_seconds) / 60, int(level.play_seconds) % 60], 10, MINT)
    var weapon: WeaponData = level.equipment.equipped()
    draw_rect(Rect2(492, 9, 132, 37), Color("31564e"))
    _text(Vector2(503, 25), weapon.label, 13)
    var state := "K 切换武器"
    if level.equipment.charging:
        var ratio: float = level.equipment.charge / weapon.charge_seconds
        draw_rect(Rect2(503, 35, 109 * ratio, 4), Color("f2d086"))
        state = ""
    elif level.equipment.cooldowns[weapon.id] > 0:
        state = "准备中…"
    _text(Vector2(503, 40), state, 9, MINT)
    draw_rect(Rect2(0, 323, 640, 37), Color("183c3c"))
    _text(Vector2(17, 338), "A D 移动    SPACE 跳跃    J 攻击    K 切武器    W / 空中 S 瞄准", 11)
    _text(Vector2(17, 353), level.footer_hint, 9, MINT)
    _text(Vector2(501, 353), level.short_stage + "  /  非官方原型", 9, Color("a7bbab"))
    if level.toast_left > 0 and not level.course_paused and not level.defeated and not level.completed:
        draw_rect(Rect2(16, 64, 608, 23), Color(0.08, 0.20, 0.19, 0.90))
        _text(Vector2(26, 80), level.toast, 11)
    if level.course_paused or level.defeated or level.completed:
        draw_rect(Rect2(0, 56, 640, 267), Color(0.05, 0.13, 0.14, 0.72))
        draw_rect(Rect2(142, 114, 356, 149), Color("183c3c"))
        draw_rect(Rect2(142, 114, 356, 3), Color("dc9974") if level.defeated else MINT)
        var title: String = level.panel_title()
        var subtitle: String = level.panel_controls()
        _text(Vector2(176, 155), title, 22)
        _text(Vector2(176, 185), "%s %d / %d   ·   生命 %d / 20" % [level.target_label, level.cleared_count(), level.targets.size(), level.health.current], 13, MINT)
        if not level.result_hint().is_empty():
            _text(Vector2(176, 201), level.result_hint(), 10, Color("f3cf87"))
        _text(Vector2(176, 218), subtitle, 12)
        _text(Vector2(176, 243), level.panel_detail(), 10, Color("a7bbab"))
    elif not level.status_hint().is_empty():
        draw_rect(Rect2(16, 90, 608, 19), Color(0.08, 0.20, 0.19, 0.85))
        _text(Vector2(26, 104), level.status_hint(), 10, MINT)

func _heart(at: Vector2, amount: int) -> void:
    for row in HEART.size():
        for col in HEART[row].length():
            if HEART[row][col] != "1":
                continue
            var filled := amount == 2 or (amount == 1 and col < 3)
            var color := Color("ef795e") if filled else Color("405952")
            if filled and row == 1 and col == 1:
                color = Color("ffbaa0")
            draw_rect(Rect2(at + Vector2(col * 2, row * 2), Vector2(2, 2)), color)
