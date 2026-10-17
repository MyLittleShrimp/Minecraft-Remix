class_name RemixArt
extends RefCounted
## Original ImageGen PNGs stay intact. Regions/anchors are computed once for drawing.
const SHEETS := {
    "characters": preload("res://assets/art/m3-art/characters.png"),
    "captain": preload("res://assets/art/m3-art/captain.png"),
    "items": preload("res://assets/art/m3-art/items.png")
}
static var regions: Dictionary = {}

static func prepare(sheet: String) -> void:
    if regions.has(sheet): return
    var texture: Texture2D = SHEETS[sheet]
    var source := texture.get_image()
    var columns := 2 if sheet=="captain" else 4
    var cell := Vector2i(source.get_width()/columns,source.get_height()/columns)
    var frames: Array[Dictionary] = []
    for index in columns*columns:
        var offset := Vector2i(index%columns,index/columns)*cell
        var sample_size := cell
        # This atlas is not a perfectly aligned grid: the foliage row starts
        # above y=939. Keep foliage out of the blocks/fire and include its tops.
        if sheet=="items" and index>=8 and index<12:
            sample_size.y=274
        elif sheet=="items" and index>=12:
            offset.y=915
            sample_size.y=source.get_height()-offset.y
        var part := source.get_region(Rect2i(offset,sample_size))
        var used := _visible_rect(part)
        var sum_x := 0.0
        var count := 0
        for y in range(used.end.y-maxi(1,int(used.size.y*0.08)),used.end.y):
            for x in range(used.position.x,used.end.x):
                if part.get_pixel(x,y).a>0.5:
                    sum_x+=x
                    count+=1
        var anchor_x: float = sum_x/count if count>0 else used.get_center().x
        frames.append({"rect":Rect2(used.position+offset,used.size),"anchor":anchor_x-used.position.x,"height":float(used.size.y)})
    for index in frames.size():
        var group_start := (index/columns)*columns if sheet=="characters" else 0
        var group_end := group_start+columns if sheet=="characters" else frames.size()
        var tallest := 1.0
        for other in range(group_start,group_end): tallest=maxf(tallest,frames[other].height)
        frames[index].scale_height=tallest
    regions[sheet]=frames

static func _visible_rect(picture: Image) -> Rect2i:
    # Near-zero alpha specks in a generated sheet must not set pose scale/feet.
    var rough := picture.get_used_rect()
    var first := rough.end
    var last := rough.position
    for y in range(rough.position.y,rough.end.y):
        for x in range(rough.position.x,rough.end.x):
            if picture.get_pixel(x,y).a>=0.25:
                first.x=mini(first.x,x)
                first.y=mini(first.y,y)
                last.x=maxi(last.x,x)
                last.y=maxi(last.y,y)
    return Rect2i(first,last-first+Vector2i.ONE) if last.x>=first.x and last.y>=first.y else rough

static func info(sheet: String, index: int) -> Dictionary:
    prepare(sheet)
    return regions[sheet][index]

static func actor(canvas: CanvasItem, sheet: String, index: int, height: float, facing: int = 1, tint: Color = Color.WHITE) -> void:
    var frame := info(sheet,index)
    var ratio: float = height/frame.scale_height
    var size: Vector2 = (frame.rect.size*ratio).round()
    var at := Vector2(-roundf(frame.anchor*ratio),-size.y)
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    canvas.draw_texture_rect_region(SHEETS[sheet],Rect2(at,size),frame.rect,tint)
    canvas.draw_set_transform(Vector2.ZERO)

static func icon(canvas: CanvasItem, index: int, box: Rect2, tint: Color = Color.WHITE) -> void:
    var region: Rect2 = info("items",index).rect
    var scale := minf(box.size.x/region.size.x,box.size.y/region.size.y)
    var size := (region.size*scale).round()
    canvas.draw_texture_rect_region(SHEETS.items,Rect2((box.get_center()-size*0.5).round(),size),region,tint)

static func block(canvas: CanvasItem, index: int) -> void:
    canvas.draw_texture_rect_region(SHEETS.items,Rect2(-16,-16,32,32),info("items",index).rect)
