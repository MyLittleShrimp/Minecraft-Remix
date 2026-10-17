extends Node2D

@export var ui_font: Font
const WHITE := Color("edf1ce")
const MINT := Color("b9d889")
var level: Node

func _process(_delta: float) -> void:
    queue_redraw()

func _text(at: Vector2, value: String, size: int = 12, color: Color = WHITE) -> void:
    draw_string(ui_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
    if not is_instance_valid(level):
        return
    draw_rect(Rect2(0, 0, 640, 48), Color("183c3c"))
    draw_rect(Rect2(20, 13, 4, 23), MINT)
    _text(Vector2(32, 29), "方块远征", 20)
    _text(Vector2(133, 28), "林地试炼", 13, MINT)
    var names: Array[String] = ["01  起步与台阶", "02  低顶与断沟", "03  木台与高路", "04  林间营地"]
    _text(Vector2(259, 27), names[level.section_index()], 13)
    _text(Vector2(514, 25), "移动试玩 M1-A", 11, MINT)
    draw_rect(Rect2(259, 35, 228, 3), Color("3c5b50"))
    draw_rect(Rect2(259, 35, 228 * clampf((level.player.position.x - 96) / 2304.0, 0, 1), 3), MINT)
    draw_rect(Rect2(0, 326, 640, 34), Color("183c3c"))
    _text(Vector2(18, 347), "A / D 移动     SPACE 跳跃     S + SPACE 下落", 12)
    _text(Vector2(455, 347), "R 返回路标   ESC 暂停", 11, MINT)
    _text(Vector2(20, 69), "路标 %d / 4   ·   返回 %d 次" % [level.return_index + 1, level.falls], 11, Color("e1ebc5"))
    _text(Vector2(534, 69), "%02d:%02d" % [int(level.play_seconds) / 60, int(level.play_seconds) % 60], 12)
    if level.toast_left > 0:
        draw_rect(Rect2(202, 284, 236, 27), Color("244943"))
        _text(Vector2(218, 303), level.toast, 12, MINT)
    if level.course_paused or level.completed:
        draw_rect(Rect2(0, 48, 640, 278), Color(0.05, 0.13, 0.14, 0.83))
        draw_rect(Rect2(145, 111, 350, 142), Color("183c3c"))
        draw_rect(Rect2(145, 111, 350, 3), MINT)
        _text(Vector2(212, 147), "抵达林间营地！" if level.completed else "休息一下", 23)
        _text(Vector2(180, 178), "本段跑跳练习完成，战斗将在下一阶段加入。" if level.completed else "松开方向键后再继续，慢慢找到跳跃节奏。", 12)
        _text(Vector2(205, 210), "R  重新挑战     /     Q  退出" if level.completed else "ESC  继续     /     Q  退出", 15, MINT)
        _text(Vector2(216, 236), "F11 全屏     ·     F12 截图", 12, Color("8eb4a2"))
