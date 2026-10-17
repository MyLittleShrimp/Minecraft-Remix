extends Node2D
## Visual arrival reward; campaign settlement remains the single grant authority.
var level: Node
var seconds:=0.0
func _ready() -> void:
    StoryItemArt.prepare()
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:
    seconds+=delta
    queue_redraw()
func _draw() -> void:
    if not is_instance_valid(level.wither_boss) or level.wither_boss.health.current>0: return
    var gold:=Color("ffc879")
    draw_rect(Rect2(-25,-12,50,12),Color("50404d"))
    draw_rect(Rect2(-27,-14,54,4),gold)
    var float_y: float=sin(seconds*2.4)*2
    StoryItemArt.powder(self,Rect2(-22,-65+float_y,44,44))
    for i in 5:
        var at:=Vector2(sin(seconds+i*1.4)*25,-24-fmod(seconds*9+i*13,51))
        draw_rect(Rect2(at,Vector2(2,2)),Color(1,0.72,0.3,0.7))
    draw_string(level.ui_font,Vector2(-44,-82),"烈焰粉 ×3",HORIZONTAL_ALIGNMENT_LEFT,-1,12,gold)
    draw_string(level.ui_font,Vector2(-64,-99),"前往祭台 · 收取材料",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f7ebc7"))
