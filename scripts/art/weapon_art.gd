class_name WeaponArt
extends RefCounted
## Pixel geometry around a real grip; local +X is always the firing direction.
static func crossbow(canvas: CanvasItem, loaded: bool, pull: float = 0.0, tint: Color = Color.WHITE) -> void:
    canvas.draw_rect(Rect2(-15,-3,35,7),Color("1b2529")*tint)
    canvas.draw_rect(Rect2(-14,-2,30,5),Color("85532e")*tint)
    canvas.draw_rect(Rect2(-10,-2,26,2),Color("d2a263")*tint)
    canvas.draw_rect(Rect2(-9,3,5,7),Color("573820")*tint)
    var limb:=PackedVector2Array([Vector2(0,-13),Vector2(6,-11),Vector2(10,-5),Vector2(10,5),Vector2(6,11),Vector2(0,13)])
    canvas.draw_polyline(limb,Color("202e31")*tint,5)
    canvas.draw_polyline(limb,Color("a4b4b4")*tint,3)
    canvas.draw_line(Vector2(1,-12),Vector2(6,-10),Color("e5e6ce")*tint,1)
    var nock:=Vector2(-2-9*(1.0 if loaded else pull),0)
    canvas.draw_polyline(PackedVector2Array([Vector2(0,-13),nock,Vector2(0,13)]),Color("dfdfcb")*tint,1)
    canvas.draw_rect(Rect2(12,-4,3,9),Color("5e828b")*tint)
    if loaded:
        canvas.draw_line(Vector2(-10,0),Vector2(24,0),Color("efd58f")*tint,2)
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(28,0),Vector2(22,-3),Vector2(22,3)]),Color("b1f1ec")*tint)

static func icon(canvas: CanvasItem, weapon: WeaponData, rect: Rect2, tint: Color = Color.WHITE) -> void:
    if weapon.kind==WeaponData.Kind.TRIDENT:
        canvas.draw_set_transform(rect.get_center(),-0.8,Vector2.ONE*(rect.size.x/58.0))
        trident(canvas,tint)
        canvas.draw_set_transform(Vector2.ZERO)
        return
    if weapon.kind == WeaponData.Kind.AXE:
        canvas.draw_set_transform(rect.get_center()+Vector2(-3,9),0.4,Vector2.ONE*(rect.size.x/34.0))
        axe(canvas,tint)
        canvas.draw_set_transform(Vector2.ZERO)
    elif weapon.kind==WeaponData.Kind.CROSSBOW:
        canvas.draw_set_transform(rect.get_center(),-0.55,Vector2.ONE*(rect.size.x/44.0))
        crossbow(canvas,true,0,tint)
        canvas.draw_set_transform(Vector2.ZERO)
    else:
        RemixArt.icon(canvas,4 if weapon.kind==WeaponData.Kind.SWORD else 5,rect,tint)

static func trident(canvas: CanvasItem,tint: Color=Color.WHITE) -> void:
    # Grip at zero, all three prongs point along local +X.
    canvas.draw_rect(Rect2(-24,-3,53,6),Color("142f3e")*tint)
    canvas.draw_rect(Rect2(-23,-1,51,3),Color("427e80")*tint)
    canvas.draw_rect(Rect2(-21,-1,47,1),Color("99daca")*tint)
    for x in [-16,-11,-6]: canvas.draw_rect(Rect2(x,-2,2,5),Color("bca473")*tint)
    canvas.draw_rect(Rect2(18,-11,7,23),Color("163941")*tint)
    canvas.draw_rect(Rect2(20,-9,3,19),Color("58aba8")*tint)
    for y in [-10,0,10]:
        canvas.draw_rect(Rect2(22,y-2,14 if y==0 else 10,5),Color("183a45")*tint)
        canvas.draw_rect(Rect2(23,y-1,12 if y==0 else 8,3),Color("6ececb")*tint)
        canvas.draw_line(Vector2(24,y-1),Vector2(36 if y==0 else 32,y-1),Color("dcfff1")*tint,1)
    canvas.draw_rect(Rect2(-25,-2,4,5),Color("70bcbc")*tint)

static func axe(canvas: CanvasItem, tint: Color = Color.WHITE) -> void:
    canvas.draw_rect(Rect2(-3,-31,6,42),Color("17272e")*tint)
    canvas.draw_rect(Rect2(-1,-29,3,39),Color("89614a")*tint)
    canvas.draw_rect(Rect2(-1,-27,1,30),Color("d8ad6d")*tint)
    var edge := PackedVector2Array([Vector2(-7,-30),Vector2(9,-32),Vector2(17,-28),Vector2(20,-16),Vector2(15,-10),Vector2(6,-13),Vector2(3,-20),Vector2(-7,-20)])
    canvas.draw_colored_polygon(edge,Color("192532")*tint)
    canvas.draw_colored_polygon(PackedVector2Array([Vector2(-5,-28),Vector2(8,-30),Vector2(15,-26),Vector2(17,-17),Vector2(13,-13),Vector2(8,-15),Vector2(5,-22),Vector2(-5,-22)]),Color("665a81")*tint)
    canvas.draw_polyline(PackedVector2Array([Vector2(9,-29),Vector2(15,-25),Vector2(17,-17),Vector2(13,-13)]),Color("ccc7de")*tint,2)
    canvas.draw_rect(Rect2(-3,-24,6,4),Color("bd9b67")*tint)
    for y in [1,5,9]: canvas.draw_rect(Rect2(-2,y,5,1),Color("423743")*tint)
