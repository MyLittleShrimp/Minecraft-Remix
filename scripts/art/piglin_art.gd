class_name PiglinArt
extends RefCounted
const SHEETS=[preload("res://assets/art/m4-piglin/sword.png"),preload("res://assets/art/m4-piglin/axe.png"),preload("res://assets/art/m4-piglin/crossbow.png")]
const KEYS=["sword","axe","crossbow"]
static var frames: Dictionary={}
static func pose(actor: PiglinBrute) -> int:
    if not actor.active: return 7
    if actor.swing_flash>0: return 5
    if actor.flash_left>0 and actor.stats.role!=PiglinData.Role.AXE: return 3
    if actor.state==RemixEnemy.State.AIM: return 4
    if actor.state==RemixEnemy.State.RECOVER: return 6
    if absf(actor.velocity.x)>1: return 1+posmod(int(actor.steps*1.8),2)
    return 0
static func draw_actor(canvas: CanvasItem,actor: PiglinBrute) -> void:
    if frames.is_empty(): frames=JSON.parse_string(FileAccess.get_file_as_string("res://resources/piglin_regions.json"))
    var info: Dictionary=frames[KEYS[actor.stats.role]][pose(actor)]
    var r: Array=info.rect
    var source:=Rect2(r[0],r[1],r[2],r[3])
    var scale:=54.0/400.0
    var size: Vector2=(source.size*scale).round()
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(actor.facing,1))
    canvas.draw_texture_rect_region(SHEETS[actor.stats.role],Rect2(Vector2(-roundf(float(info.anchor)*scale),-size.y),size),source,Color("ffdda9") if actor.flash_left>0 else Color.WHITE)
    canvas.draw_set_transform(Vector2.ZERO)
