extends "res://scripts/world/movement_course.gd"
## Same terrain builder, with a continuous floor for combat practice.
const COMBAT_SOLIDS: Array[Rect2] = [
    Rect2(-32, 0, 32, 512), Rect2(2240, 0, 32, 512),
    Rect2(0, 288, 2240, 224), Rect2(850, 224, 16, 64)
]
const COMBAT_PLATFORMS: Array[Rect2] = [Rect2(1040, 224, 128, 12)]
const SPIKES := Rect2(1420, 274, 76, 14)

func _ready() -> void:
    process_physics_priority = 5
    for rect in COMBAT_SOLIDS:
        _add_collision(rect, false)
    for rect in COMBAT_PLATFORMS:
        _add_collision(rect, true)

func _physics_process(_delta: float) -> void:
    get_parent().get_parent().check_environment()

func _draw() -> void:
    # Reuse the block palette, without importing the movement trial's layout.
    draw_rect(Rect2(0, 288, 2240, 224), Color("725740"))
    for x in range(0, 2240, 32):
        draw_rect(Rect2(x, 288, 31, 5), Color("aacb6b"))
        draw_rect(Rect2(x, 293, 31, 5), Color("597e4f"))
        for y in range(306, 520, 32):
            draw_rect(Rect2(x + 4, y, 9, 5), Color("936d47"))
            draw_rect(Rect2(x + 21, y + 13, 6, 4), Color("5d4939"))
    draw_rect(Rect2(844, 220, 28, 68), Color("465b5b"))
    for y in range(224, 288, 16):
        draw_rect(Rect2(848, y, 20, 13), Color("7d8e88"))
        draw_rect(Rect2(848, y, 20, 3), Color("abb9a0"))
    for rect in COMBAT_PLATFORMS:
        draw_rect(rect, Color("765a40"))
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("d3b272"))
    draw_rect(SPIKES.grow(3), Color("563f3b"))
    for x in range(1420, 1496, 9):
        draw_colored_polygon(PackedVector2Array([Vector2(x, 288), Vector2(x + 4, 274), Vector2(x + 8, 288)]), Color("d78b71"))
    _sign(Vector2(156, 163), "01 / 下界合金剑", "靠近木靶 · J 挥砍 / 按住连斩")
    _sign(Vector2(497, 150), "02 / 弓与掩体", "K 切弓 · J 松开发射 / 长按蓄力")
    _sign(Vector2(776, 174), "实心墙会挡住剑和箭", "越过矮墙，或跳起射击")
    _sign(Vector2(1022, 123), "03 / 高处目标", "W 斜上 · 空中 S 斜下")
    _sign(Vector2(1340, 171), "04 / 受击练习", "跳过尖刺 · 接触 -3 HP")
    _sign(Vector2(1710, 169), "05 / 最后一靶", "清除 5 个木靶，再前往营地")
    draw_rect(Rect2(2100, 213, 6, 75), Color("455c4b"))
    draw_rect(Rect2(2106, 213, 40, 28), Color("b9d889"))
    draw_rect(Rect2(2114, 220, 5, 5), Color("4e7860"))
    draw_rect(Rect2(2129, 220, 5, 5), Color("4e7860"))
    draw_rect(Rect2(2120, 229, 9, 5), Color("4e7860"))
