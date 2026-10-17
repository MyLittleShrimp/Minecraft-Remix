class_name PortalItemArt
extends RefCounted
const SHEET: Texture2D=preload("res://assets/art/m4-portal/items.png")
static var regions: Array[Rect2]=[]
static func prepare() -> void:
    if not regions.is_empty(): return
    var source:=SHEET.get_image()
    var half:=source.get_width()/2
    for i in 2:
        var cell:=Rect2i(i*half,0,half,source.get_height())
        var used:=source.get_region(cell).get_used_rect()
        used.position+=cell.position
        regions.append(Rect2(used))
static func draw_item(canvas: CanvasItem,index: int,box: Rect2) -> void:
    prepare()
    var region:=regions[index]
    var ratio:=minf(box.size.x/region.size.x,box.size.y/region.size.y)
    var size: Vector2=(region.size*ratio).round()
    canvas.draw_texture_rect_region(SHEET,Rect2((box.get_center()-size/2).round(),size),region)
