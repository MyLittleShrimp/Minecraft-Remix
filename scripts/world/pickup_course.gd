extends "res://scripts/world/movement_course.gd"

const ITEM_SOLIDS: Array[Rect2] = [
    Rect2(-32, 0, 32, 512), Rect2(2400, 0, 32, 512),
    Rect2(0, 288, 1904, 224), Rect2(2000, 288, 400, 224),
    Rect2(1060, 240, 24, 48)
]
const ITEM_PLATFORMS: Array[Rect2] = [Rect2(1648, 208, 96, 12)]

func _ready() -> void:
    process_physics_priority = 5
    for rect in ITEM_SOLIDS:
        _add_collision(rect, false)
    for rect in ITEM_PLATFORMS:
        _add_collision(rect, true)

func _physics_process(_delta: float) -> void:
    get_parent().get_parent().check_environment()

func _draw() -> void:
    for rect in ITEM_SOLIDS:
        if rect.size.y >= 400:
            continue
        draw_rect(rect, Color("71573f"))
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("aaca70"))
        draw_rect(Rect2(rect.position + Vector2(0, 5), Vector2(rect.size.x, 5)), Color("5b7e4c"))
        for x in range(int(rect.position.x), int(rect.end.x), 32):
            for y in range(int(rect.position.y + 14), int(rect.end.y), 32):
                draw_rect(Rect2(x + 4, y, 8, 5), Color("946e4b"))
                draw_rect(Rect2(x + 19, y + 10, 7, 4), Color("584639"))
    for rect in ITEM_PLATFORMS:
        draw_rect(rect, Color("7d6246"))
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("dab878"))
    for y in range(240, 288, 16):
        draw_rect(Rect2(1060, y, 24, 14), Color("81928a"))
    draw_signs()
    draw_rect(Rect2(2280, 208, 6, 80), Color("465343"))
    draw_rect(Rect2(2286, 208, 40, 28), Color("d4cb82"))
    draw_rect(Rect2(2294, 215, 6, 6), Color("4c7054"))
    draw_rect(Rect2(2308, 215, 6, 6), Color("4c7054"))
    draw_rect(Rect2(2300, 223, 8, 6), Color("4c7054"))

func draw_signs() -> void:
    _sign(Vector2(150, 138), "01 / 顶砖取补给", "红蘑菇强化 12 秒 · 绿宝石计分")
    _sign(Vector2(540, 148), "力量试炼", "剑伤害 6 → 8 · 不会变大")
    _sign(Vector2(822, 137), "02 / 留一口苹果", "恢复 4 HP · 满血时保留，可回取")
    _sign(Vector2(1360, 138), "03 / 再次补给", "强化只刷新时间 · 木平台上有奖励")
    _sign(Vector2(1810, 150), "留意引信与断桥", "道具非必需 · 长按 SPACE 跨越")
    _sign(Vector2(2110, 163), "前方营地", "击败 3 只怪物后抵达出口")
