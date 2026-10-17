class_name WildlifeArt
extends RefCounted
const TEXTURE=preload("res://assets/art/m4-wildlife/animals.png")
static var frames: Array=[]
static func prepare() -> void:
    if frames.is_empty(): frames=JSON.parse_string(FileAccess.get_file_as_string("res://resources/wildlife_regions.json"))
static func actor(canvas: CanvasItem,species: int,frame: int,height: float,facing: int,tint: Color) -> void:
    prepare()
    var cell: Dictionary=frames[(species-3)*4+posmod(frame,4)]
    var r: Array=cell.rect
    var region:=Rect2(r[0],r[1],r[2],r[3])
    var size: Vector2=(region.size*height/float(cell.height)).round()
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    canvas.draw_texture_rect_region(TEXTURE,Rect2(Vector2(-roundf(size.x/2),-size.y),size),region,tint)
    canvas.draw_set_transform(Vector2.ZERO)
