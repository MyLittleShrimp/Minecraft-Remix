extends "res://scripts/world/movement_course.gd"

const ENEMY_SOLIDS: Array[Rect2] = [
    Rect2(-32, 0, 32, 512), Rect2(2880, 0, 32, 512),
    Rect2(0, 288, 1248, 224), Rect2(1344, 288, 1536, 224),
    Rect2(700, 240, 24, 48), Rect2(1780, 256, 32, 32)
]
const ENEMY_PLATFORMS: Array[Rect2] = [Rect2(2160, 208, 112, 12)]

func _ready() -> void:
    process_physics_priority = 5
    for rect in ENEMY_SOLIDS:
        _add_collision(rect, false)
    for rect in ENEMY_PLATFORMS:
        _add_collision(rect, true)

func _physics_process(_delta: float) -> void:
    get_parent().get_parent().check_environment()

func _draw() -> void:
    for rect in ENEMY_SOLIDS:
        if rect.size.y >= 400:
            continue
        draw_rect(rect, Color("71573f"))
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("aaca70"))
        draw_rect(Rect2(rect.position + Vector2(0, 5), Vector2(rect.size.x, 5)), Color("5b7e4c"))
        for x in range(int(rect.position.x), int(rect.end.x), 32):
            for y in range(int(rect.position.y + 14), int(rect.end.y), 32):
                draw_rect(Rect2(x + 4, y, 8, 5), Color("946e4b"))
                draw_rect(Rect2(x + 19, y + 10, 7, 4), Color("584639"))
    for rect in ENEMY_PLATFORMS:
        draw_rect(rect, Color("7d6246"))
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("dab878"))
    for x in [700, 1780]:
        var top := 240 if x == 700 else 256
        for y in range(top, 288, 16):
            draw_rect(Rect2(x, y, 24 if x == 700 else 32, 14), Color("81928a"))
    _sign(Vector2(155, 148), "01 / 僵尸来袭", "J 连斩击退 · 留意接触伤害")
    _sign(Vector2(635, 151), "02 / 骷髅哨点", "抬弓后射箭 · 借掩体与跳跃接近")
    _sign(Vector2(1100, 170), "断桥", "长按 SPACE 跳过")
    _sign(Vector2(1370, 137), "03 / 苦力帕", "满蓄力可秒杀 · 闪烁后及时退开")
    _sign(Vector2(1830, 135), "04 / 三怪组合", "先处理远程，或引爆苦力帕伤敌")
    _sign(Vector2(2480, 156), "营地就在前方", "消灭全部 6 只怪物后通关")
    draw_rect(Rect2(2750, 208, 6, 80), Color("465343"))
    draw_rect(Rect2(2756, 208, 40, 28), Color("d4cb82"))
    draw_rect(Rect2(2764, 215, 6, 6), Color("4c7054"))
    draw_rect(Rect2(2778, 215, 6, 6), Color("4c7054"))
    draw_rect(Rect2(2770, 223, 8, 6), Color("4c7054"))
