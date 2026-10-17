class_name WitherArt
extends RefCounted
const SHEET=preload("res://assets/art/m4-wither/wither-skeleton.png")
static var frames: Array=[]
static func prepare() -> void:
    if frames.is_empty(): frames=JSON.parse_string(FileAccess.get_file_as_string("res://resources/wither_regions.json")).frames
static func pose(actor: WitherSkeleton) -> int:
    if not actor.active: return 7
    if actor.swing_flash>0: return 5
    if actor.state==RemixEnemy.State.AIM: return 4
    if actor.flash_left>0: return 3
    if actor.state==RemixEnemy.State.RECOVER: return 6
    if absf(actor.velocity.x)>1: return 1+posmod(int(actor.steps*1.8),2)
    return 0
static func draw_actor(canvas: CanvasItem,actor: WitherSkeleton) -> void:
    prepare()
    var info: Dictionary=frames[pose(actor)]
    var r: Array=info.rect
    var source:=Rect2(r[0],r[1],r[2],r[3])
    var scale:=64.0/400.0
    var size: Vector2=(source.size*scale).round()
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(actor.facing,1))
    canvas.draw_texture_rect_region(SHEET,Rect2(Vector2(-roundf(float(info.anchor)*scale),-size.y),size),source,Color("ffdda9") if actor.flash_left>0 else Color.WHITE)
    canvas.draw_set_transform(Vector2.ZERO)
