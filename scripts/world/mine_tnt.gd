class_name MineTNT
extends Node2D
const FUSE_SECONDS:=2.0
const RADIUS:=112.0
var mechanism_id: String
var wall_x: float
var lever_x: float
var ui_font: Font
var active:=false
var fuse_left:=0.0
var detonations:=0
var wall: StaticBody2D

func _ready() -> void:
    process_physics_priority=80
    wall=StaticBody2D.new()
    wall.position=Vector2(wall_x,176)
    wall.collision_layer=1
    wall.collision_mask=0
    var collider:=CollisionShape2D.new()
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(32,224)
    collider.shape=shape
    wall.add_child(collider)
    add_child(wall)

func bomb_center() -> Vector2: return Vector2(wall_x-38,272)

func interact() -> void:
    if active: return
    fuse_left=FUSE_SECONDS if fuse_left<=0 else 0.0
    var level:=get_parent().get_parent().get_parent()
    level.toast="TNT 已点燃！退到金色标线外；再次操作可取消。" if fuse_left>0 else "引信已取消 · TNT 保留，可再次启动。"
    level.toast_left=3
    level.sound.play_effect(&"fuse")

func _physics_process(delta: float) -> void:
    if fuse_left>0:
        fuse_left=maxf(0,fuse_left-delta)
        if fuse_left<=0: detonate()
    queue_redraw()

func detonate() -> void:
    if active: return
    var at:=to_global(bomb_center())
    var impacts:=BlastQuery.actors(self,at,RADIUS,56,6,3)
    # Walls still block this explosion. Never remove structural ground.
    var fragile:=FragileBrick.blast_candidates(get_world_2d().direct_space_state,at,RADIUS)
    BlastQuery.apply(impacts)
    for brick in fragile: brick.break_brick()
    apply_state(true)
    detonations+=1
    var effect:=BlastEffect.new()
    effect.position=at
    effect.radius=RADIUS
    get_parent().get_parent().add_child(effect)
    var level:=get_parent().get_parent().get_parent()
    level.sound.play_effect(&"explosion")
    level.toast="石墙已炸开 · 通路永久保留至本段重试"
    level.toast_left=3
    print("MINE_TNT id=%s detonations=%d" % [mechanism_id,detonations])

func apply_state(open: bool) -> void:
    active=open
    fuse_left=0
    wall.set_deferred("collision_layer",0 if active else 1)
    queue_redraw()

func _draw() -> void:
    if not is_instance_valid(wall): return
    var color:=Color("88cfb3") if active else Color("e9b569")
    draw_line(Vector2(lever_x,282),Vector2(wall_x-38,282),Color("773f3d"),2)
    draw_rect(Rect2(lever_x-10,277,20,11),Color("676e69"))
    draw_line(Vector2(lever_x,278),Vector2(lever_x+(7 if fuse_left>0 else -7),261),color,3)
    draw_rect(Rect2(lever_x-9,259,8,4),color)
    if active:
        for n in 4: draw_rect(Rect2(wall_x-16+n*9,283,7,5),Color("687379"))
        draw_string(ui_font,Vector2(lever_x-20,226),"通路已开",HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)
        return
    for y in range(64,288,16):
        draw_rect(Rect2(wall_x-16,y,32,15),Color("5e666a"))
        draw_rect(Rect2(wall_x-13,y+2,12,2),Color("8a928c"))
        draw_line(Vector2(wall_x+5,y),Vector2(wall_x-3,y+14),Color("272f38"),2)
    var at:=bomb_center()
    draw_rect(Rect2(at-Vector2(13,12),Vector2(26,24)),Color("cf654c") if fuse_left<=0 or int(fuse_left*10)%2==0 else Color("ffe0a0"))
    draw_rect(Rect2(at-Vector2(13,4),Vector2(26,10)),Color("e7d7af"))
    draw_string(ui_font,at+Vector2(-10,4),"TNT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("422e2d"))
    draw_line(Vector2(at.x-RADIUS,284),Vector2(at.x-RADIUS,267),color,2)
    if fuse_left>0:
        draw_arc(at,RADIUS,PI,TAU,32,Color(1,0.5,0.25,0.6),2)
        draw_string(ui_font,at+Vector2(-12,-26),"%.1fs"%fuse_left,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ffe1ad"))
    var settings: Node=get_node("/root/ControlSettings")
    var key: String=settings.hint("aim_up") if settings.gamepad_active() else "E"
    draw_string(ui_font,Vector2(lever_x-36,226),key+(" 取消引信" if fuse_left>0 else " 引爆 TNT"),HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)
