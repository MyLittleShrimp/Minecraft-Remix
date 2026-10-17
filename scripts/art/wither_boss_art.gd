class_name WitherBossArt
extends RefCounted
const SHEET=preload("res://assets/art/m4-wither-boss/wither-boss.png")
static var frames: Array=[]
static func prepare() -> void:
    if frames.is_empty(): frames=JSON.parse_string(FileAccess.get_file_as_string("res://resources/wither_boss_regions.json")).frames
static func pose(actor: WitherBoss) -> int:
    if actor.second_phase:
        if actor.battle in [WitherBoss.Battle.DASH_WARNING,WitherBoss.Battle.MELEE_WARNING]: return 5
        if actor.battle in [WitherBoss.Battle.DASH,WitherBoss.Battle.MELEE]: return 6
        if actor.exposed() or actor.flash_left>0: return 7
        return 4
    if actor.flash_left>0: return 3
    if actor.exposed(): return 2
    if actor.battle==WitherBoss.Battle.MELEE: return 3
    if actor.battle in [WitherBoss.Battle.VOLLEY_WARNING,WitherBoss.Battle.VOLLEY,WitherBoss.Battle.MELEE_WARNING]: return 1
    return 0
static func draw_actor(canvas: CanvasItem,actor: WitherBoss) -> void:
    var offset:=Vector2(0,sin(actor.visual_seconds*3)*1.2)
    var tilt:=0.0
    if actor.battle==WitherBoss.Battle.DASH_WARNING:
        offset.x=-actor.dash_direction*3*(1-actor.timer/1.1)
        tilt=sin(actor.visual_seconds*35)*0.018
    elif actor.battle==WitherBoss.Battle.DASH: tilt=-0.09*actor.dash_direction
    elif actor.battle==WitherBoss.Battle.MELEE: tilt=actor.melee_direction*0.16
    draw_pose(canvas,pose(actor),actor.facing,Color("ffdcaf") if actor.flash_left>0 else Color.WHITE,offset,tilt)
static func draw_pose(canvas: CanvasItem,index: int,facing: int,tint: Color=Color.WHITE,offset: Vector2=Vector2.ZERO,tilt: float=0.0) -> void:
    prepare()
    var rect: Array=frames[index].rect
    var source:=Rect2(rect[0],rect[1],rect[2],rect[3])
    var size: Vector2=(source.size*0.265).round()
    canvas.draw_set_transform(offset.round(),tilt,Vector2(facing,1))
    canvas.draw_texture_rect_region(SHEET,Rect2((-size/2).round(),size),source,tint)
    canvas.draw_set_transform(Vector2.ZERO)
