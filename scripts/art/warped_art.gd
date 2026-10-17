class_name WarpedArt
extends RefCounted
## Raw ImageGen bytes preserved; measured rectangles load once, no live alpha scan.
const SHEETS := {
    "enderman": preload("res://assets/art/m4-warped/enderman.png"),
    "airborne": preload("res://assets/art/m4-warped/airborne.png"),
    "rift-warden": preload("res://assets/art/m4-warped/rift-warden.png")
}
static var regions: Dictionary = {}
static func prepare() -> void:
    if regions.is_empty():
        regions=JSON.parse_string(FileAccess.get_file_as_string("res://resources/warped_regions.json"))
static func frame_info(sheet: String,index: int) -> Dictionary:
    prepare()
    return regions[sheet].frames[index]
static func draw_actor(canvas: CanvasItem,sheet: String,index: int,facing: int=1,tint: Color=Color.WHITE,at: Vector2=Vector2.ZERO) -> void:
    var info:=frame_info(sheet,index)
    var r: Array=info.rect
    var source:=Rect2(r[0],r[1],r[2],r[3])
    var scale:=64.0/397.0 if sheet=="enderman" else 68.0/392.0
    var top:=0.0
    if sheet=="airborne":
        scale=78.0/380.0 if index<4 else 62.0/371.0
        top=-29.0 if index<4 else -30.0
    var size: Vector2=(source.size*scale).round()
    if sheet!="airborne": top=-size.y
    var dest:=Rect2(Vector2(-roundf(float(info.anchor)*scale),top),size)
    canvas.draw_set_transform(at.round(),0,Vector2(facing,1))
    canvas.draw_texture_rect_region(SHEETS[sheet],dest,source,tint)
    canvas.draw_set_transform(Vector2.ZERO)
static func enderman_pose(actor: EndermanEnemy) -> int:
    if actor.strike_flash>0: return 5
    if actor.state==RemixEnemy.State.AIM: return 4
    if actor.warp_left>=0: return 7
    if actor.flash_left>0: return 3
    if actor.state==RemixEnemy.State.RECOVER: return 6
    if absf(actor.velocity.x)>1: return 1+posmod(int(actor.steps*1.8),2)
    return 0
static func warden_pose(actor: EndermanElite) -> int:
    var pose:=0
    if actor.strike_flash>0: pose=2
    elif actor.state==RemixEnemy.State.AIM or actor.warp_left>=0 or actor.support.rift_left>0: pose=1
    elif actor.state==RemixEnemy.State.RECOVER and not actor.waking: pose=3
    return pose+(4 if actor.second_phase else 0)
static func ghast_pose(actor: GhastEnemy) -> int:
    if actor.flight==GhastEnemy.Flight.CHARGE: return 2
    if actor.flight in [GhastEnemy.Flight.LOW,GhastEnemy.Flight.DESCEND]: return 3
    return posmod(int(actor.steps*1.6),2)
static func blaze_pose(actor: BlazeEnemy) -> int:
    if actor.flight in [BlazeEnemy.Flight.CHARGE,BlazeEnemy.Flight.BURST]: return 6
    if actor.flight in [BlazeEnemy.Flight.LOW,BlazeEnemy.Flight.DESCEND]: return 7
    return 4+posmod(int(actor.steps*1.6),2)
