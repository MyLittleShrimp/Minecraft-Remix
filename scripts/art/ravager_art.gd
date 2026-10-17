class_name RavagerArt
extends RefCounted
## Generated PNGs remain byte-identical. Only native texture regions are drawn.
const SHEETS=[preload("res://assets/art/m4-ravager/ravager.png"),preload("res://assets/art/m4-ravager/ravager-cracked.png")]
const NAMES=["ravager","ravager-cracked"]
static var metadata: Dictionary={}

static func prepare() -> void:
    if not metadata.is_empty(): return
    metadata=JSON.parse_string(FileAccess.get_file_as_string("res://resources/ravager_regions.json"))

static func frame_rect(phase: int,frame: int) -> Rect2:
    prepare()
    var item: Dictionary=metadata[NAMES[phase]].frames[frame]
    var size:=Vector2(item.rect[2],item.rect[3])*float(metadata[NAMES[phase]].scale)
    return Rect2(Vector2(-roundf(item.anchor*float(metadata[NAMES[phase]].scale)),-roundf(size.y)),size.round())

static func actor(canvas: CanvasItem,phase: int,frame: int,facing: int,tint: Color=Color.WHITE) -> void:
    prepare()
    var item: Dictionary=metadata[NAMES[phase]].frames[frame]
    var source:=Rect2(item.rect[0],item.rect[1],item.rect[2],item.rect[3])
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    canvas.draw_texture_rect_region(SHEETS[phase],frame_rect(phase,frame),source,tint)
    canvas.draw_set_transform(Vector2.ZERO)
