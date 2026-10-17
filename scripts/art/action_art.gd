class_name ActionArt
extends RefCounted
## Frame selection uses authored poses; no physics transform is scaled/rotated.
const SHEETS := {
    "steve": preload("res://assets/art/m3-action/steve.png"),
    "enemies": preload("res://assets/art/m3-action/enemies.png"),
    "captain": preload("res://assets/art/m3-action/captain.png")
}
static var frames: Dictionary = {}

static func prepare(sheet: String) -> void:
    if frames.has(sheet): return
    var image: Image = SHEETS[sheet].get_image()
    var columns := 4 if sheet=="captain" else 6
    var row_edges: Array = [0,335,630,935,image.get_height()] if sheet=="steve" else ([0,340,640,947,image.get_height()] if sheet=="captain" else [0,280,548,809,image.get_height()])
    var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/action_regions.json"))
    var result: Array[Dictionary] = []
    for row in 4:
        for col in columns:
            var x := int(float(image.get_width())*col/columns)
            var end_x := int(float(image.get_width())*(col+1)/columns)
            var offset := Vector2i(x,row_edges[row])
            var part := image.get_region(Rect2i(offset,Vector2i(end_x-x,row_edges[row+1]-row_edges[row])))
            var crop: Array = metadata[sheet][row*columns+col]
            var used := Rect2i(Vector2i(crop[0],crop[1])-offset,Vector2i(crop[2],crop[3]))
            var anchor := float(used.get_center().x)
            # Feet, not cape/bow, define the horizontal anchor for bipeds.
            var sum_x := 0.0
            var count := 0
            for y in range(used.end.y-maxi(1,int(used.size.y*0.08)),used.end.y):
                for px in range(used.position.x,used.end.x):
                    if part.get_pixel(px,y).a>0.5:
                        sum_x+=px
                        count+=1
            if count>0: anchor=sum_x/count
            result.append({"rect":Rect2(used.position+offset,used.size),"anchor":anchor-used.position.x,"height":float(used.size.y),"clips":metadata["_clips"][sheet][row*columns+col]})
    for i in result.size():
        var start := (i/6)*6 if sheet=="enemies" else 0
        var end := start+6 if sheet=="enemies" else result.size()
        var tallest := 1.0
        for j in range(start,end): tallest=maxf(tallest,result[j].height)
        result[i].scale_height=tallest
    frames[sheet]=result

static func actor(canvas: CanvasItem, sheet: String, frame: int, height: float, facing: int, tint: Color = Color.WHITE, squash: Vector2 = Vector2.ONE) -> void:
    prepare(sheet)
    var item: Dictionary = frames[sheet][frame]
    var ratio: float = height/item.scale_height
    var size: Vector2 = (item.rect.size*ratio).round()
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1)*squash)
    var origin := Vector2(-roundf(item.anchor*ratio),-size.y)
    if item.clips.is_empty():
        canvas.draw_texture_rect_region(SHEETS[sheet],Rect2(origin,size),item.rect,tint)
    else:
        # Native render-time strip regions remove neighbouring atlas fragments.
        # The original generated texture bytes remain untouched.
        for clip in item.clips:
            var source := Rect2(clip[0],clip[1],clip[2],clip[3])
            var pixel_scale: Vector2 = size/item.rect.size
            canvas.draw_texture_rect_region(SHEETS[sheet],Rect2(origin+(source.position-item.rect.position)*pixel_scale,source.size*pixel_scale),source,tint)
    canvas.draw_set_transform(Vector2.ZERO)

static func bread(canvas: CanvasItem, at: Vector2, scale: float = 1.0, tint: Color = Color.WHITE) -> void:
    canvas.draw_set_transform(at,0,Vector2.ONE*scale)
    canvas.draw_colored_polygon(PackedVector2Array([Vector2(-10,-3),Vector2(-7,-7),Vector2(5,-7),Vector2(10,-2),Vector2(10,4),Vector2(6,7),Vector2(-7,7),Vector2(-10,3)]),Color("493021")*tint)
    canvas.draw_rect(Rect2(-8,-2,16,7),Color("b67939")*tint)
    canvas.draw_rect(Rect2(-6,-5,12,7),Color("dea952")*tint)
    for x in [-4,1,6]: canvas.draw_line(Vector2(x-2,-4),Vector2(x,0),Color("f6d18a")*tint,2)
    canvas.draw_set_transform(Vector2.ZERO)
