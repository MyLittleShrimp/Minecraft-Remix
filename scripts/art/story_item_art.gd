class_name StoryItemArt
extends RefCounted
const POWDER: Texture2D=preload("res://assets/art/m4-fortress-reward/blaze-powder.png")
static var powder_region:=Rect2()
static func prepare() -> void:
    if powder_region.size==Vector2.ZERO:
        powder_region=Rect2(POWDER.get_image().get_used_rect())
static func powder(canvas: CanvasItem,box: Rect2) -> void:
    prepare()
    var scale_factor: float=minf(box.size.x/powder_region.size.x,box.size.y/powder_region.size.y)
    var size: Vector2=(powder_region.size*scale_factor).round()
    canvas.draw_texture_rect_region(POWDER,Rect2((box.get_center()-size/2).round(),size),powder_region)
