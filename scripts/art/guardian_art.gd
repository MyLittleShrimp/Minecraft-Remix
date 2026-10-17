class_name GuardianArt
extends RefCounted
static var texture: Texture2D
static func prepare() -> void:
    if texture==null: texture=load("res://assets/art/m4-guardian/elder-guardian.png")
static func draw_actor(canvas: CanvasItem,frame: int,facing: int,tint: Color,dead: bool) -> void:
    prepare()
    if texture==null: return
    var cell:=Vector2(texture.get_width()/4.0,texture.get_height()/2.0)
    var region:=Rect2(Vector2(frame%4,frame/4)*cell,cell)
    canvas.draw_set_transform(Vector2(0,0),0,Vector2(-facing,1))
    canvas.draw_texture_rect_region(texture,Rect2(-44,-74 if not dead else -46,112,96 if not dead else 64),region,tint if not dead else Color(0.53,0.65,0.62))
    canvas.draw_set_transform(Vector2.ZERO)
