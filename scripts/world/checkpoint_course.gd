extends "res://scripts/world/pickup_course.gd"

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    super._draw()
    var level := get_parent().get_parent()
    for index in [1, 2]:
        var x: float = level.CHECKPOINTS[index].x
        var lit: bool = level.checkpoint_index >= index
        var color := Color("f5cc78") if lit else Color("789b99")
        draw_rect(Rect2(x - 16, 284, 32, 4), Color("414c48"))
        draw_rect(Rect2(x - 11, 278, 22, 6), Color("8f6745"))
        draw_rect(Rect2(x - 7, 267, 14, 12), color)
        draw_rect(Rect2(x - 3, 259, 6, 14), Color("fff0b0") if lit else color)
        draw_string(ui_font, Vector2(x - 45, 233), "%s %s" % [level.CHECKPOINTS[index].label, "✓" if lit else "◇"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
