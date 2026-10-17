class_name WitherCharge
extends Node2D
var level: Node
var lever_x:=352.0
var spent:=false
var fuse_left:=0.0
var blast_left:=0.0
var detonations:=0
func available() -> bool:
    return not spent and level.arena_active and level.intro_left<=0 and level.wither_boss.active and not level.defeated and not level.completed
func nearby() -> bool:
    return level.player.is_on_floor() and absf(level.player.position.x-lever_x)<=30
func interact() -> bool:
    if not available() or not nearby(): return false
    fuse_left=0.0 if fuse_left>0 else 2.0
    level.sound.play_effect(&"fuse")
    return true
func reset_charge() -> void:
    spent=false
    fuse_left=0
    blast_left=0
    detonations=0
    queue_redraw()
func stop() -> void:
    fuse_left=0
    blast_left=0
func _physics_process(delta: float) -> void:
    blast_left=maxf(0,blast_left-delta)
    if fuse_left>0 and available():
        fuse_left=maxf(0,fuse_left-delta)
        if fuse_left<=0: detonate()
    queue_redraw()
func detonate() -> void:
    if spent or not available(): return
    spent=true
    fuse_left=0
    detonations+=1
    blast_left=0.25
    var impacts:=BlastQuery.actors(self,global_position,112,56,6,3)
    for impact in impacts:
        if impact.health==level.wither_boss.health:
            impact.event=impact.event.with_amount(30)
            impact.event.set_meta("wither_demolition",true)
    # Enemy deaths clear pending attacks before any simultaneous self-damage.
    impacts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.health.faction>b.health.faction)
    for impact in impacts:
        if level.wither_boss.health.current<=0: break
        BlastQuery.apply([impact])
    level.sound.play_effect(&"explosion")
func _draw() -> void:
    var lever:=Vector2(lever_x-global_position.x,16)
    draw_line(lever,Vector2(0,16),Color("876650"),1)
    draw_rect(Rect2(lever+Vector2(-8,-6),Vector2(16,6)),Color("667674"))
    draw_line(lever-Vector2(0,6),lever+Vector2(4 if fuse_left>0 else -4,-17),Color("dbb77a"),3)
    draw_rect(Rect2(-12,8,24,8),Color("55565e"))
    if not spent:
        draw_rect(Rect2(-10,-9,20,19),Color("d06a4d") if fuse_left<=0 or int(fuse_left*8)%2==0 else Color("fff0bd"))
        draw_rect(Rect2(-10,-4,20,8),Color("f6d5a1"))
        draw_string(level.ui_font,Vector2(-9,3),"TNT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("53283a"))
    if fuse_left>0:
        draw_arc(Vector2.ZERO,112,PI,TAU,40,Color("ff9469"),2)
        draw_string(level.ui_font,Vector2(-16,-17),"%.1f秒"%fuse_left,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff0c7"))
    if blast_left>0: draw_circle(Vector2.ZERO,112*(1-blast_left/0.3),Color(1,0.6,0.25,blast_left))
    if available() and nearby():
        var settings: Node=get_node("/root/ControlSettings")
        var button: String=settings.hint("aim_up") if settings.gamepad_active() else "E"
        draw_string(level.ui_font,lever+Vector2(-10,-27),button+(" 取消" if fuse_left>0 else " 引爆"),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe0a2"))
