extends "res://scripts/world/checkpoint_course.gd"

const RUIN_SOLIDS: Array[Rect2] = [
    Rect2(1296,176,128,12), Rect2(1264,112,160,12), Rect2(1412,124,12,52)
]
const RUIN_STEPS: Array[Rect2] = [Rect2(1216,224,64,12)]

func _ready() -> void:
    super._ready()
    for rect in RUIN_SOLIDS:
        _add_collision(rect, false)
    for rect in RUIN_STEPS:
        _add_collision(rect, true)

func _draw() -> void:
    super._draw()
    draw_rect(Rect2(1296,124,116,52), Color("335853"))
    for rect in RUIN_SOLIDS:
        draw_rect(rect, Color("617e73"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("bbca94"))
    for rect in RUIN_STEPS:
        draw_rect(rect, Color("795f43"))
        draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color("d8b978"))
    draw_string(ui_font,Vector2(1340,139),"宝库 +3",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("dbcd89"))

func draw_signs() -> void:
    _sign(Vector2(150,138),"01 / 顶砖取补给","绿宝石会滑下空砖，走近拾取")
    _sign(Vector2(822,137),"02 / 留一口苹果","满血时保留，可受伤后回取")
    _sign(Vector2(1160,154),"↑ 可选遗迹","跳上木台 · 跳跃挥剑破裂纹砖")
    _sign(Vector2(1455,142),"继续向右","支路可跳过 · 主路始终开放")
    _sign(Vector2(1750,145),"裂纹藏宝砖","跳跃剑击 / 借苦力帕爆破")
    _sign(Vector2(2110,163),"前方营地","两处营火、三只怪物完成后通关")
