extends Node2D
func _ready() -> void:
    var data: PickupData=get_parent().data
    if data.kind==PickupData.Kind.MUSHROOM and data.effect!=PickupData.Effect.STRENGTH:
        var palette:=ShaderMaterial.new()
        palette.shader=preload("res://scripts/items/mushroom_palette.gdshader")
        palette.set_shader_parameter("cap_color",[Color("ff82b2"),Color("ffdb67"),Color("6fceff")][data.effect-1])
        material=palette
func _draw() -> void:
    var pickup := get_parent() as RemixPickup
    if pickup.anchored:
        draw_circle(Vector2.ZERO,15,Color(0.22,1,0.66,0.09))
        for i in 3:
            var p:=Vector2.from_angle(pickup.float_seconds+i*TAU/3)*15
            draw_rect(Rect2(p.round(),Vector2(2,2)),Color(0.66,1,0.82,0.65))
    if pickup.data.kind == PickupData.Kind.BREAD:
        ActionArt.bread(self,Vector2.ZERO)
        return
    if pickup.data.kind == PickupData.Kind.MEAT:
        if pickup.data.id==&"mushroom_stew":
            draw_rect(Rect2(-10,-5,20,5),Color("dba957"))
            draw_rect(Rect2(-8,0,16,5),Color("815435"))
            draw_rect(Rect2(-5,5,10,2),Color("432a24"))
            draw_rect(Rect2(-7,-8,5,4),Color("d95042"))
            draw_rect(Rect2(2,-7,5,3),Color("f3d3a0"))
            return
        draw_rect(Rect2(-10,-6,16,13),Color("523126"))
        draw_rect(Rect2(-8,-5,12,10),Color("c77c53"))
        draw_rect(Rect2(-6,-4,7,3),Color("f0be88"))
        draw_rect(Rect2(4,-2,7,4),Color("eee0bc"))
        draw_rect(Rect2(9,-4,4,8),Color("eee0bc"))
        return
    var index := 0
    if pickup.data.kind==PickupData.Kind.MUSHROOM and pickup.data.effect!=PickupData.Effect.STRENGTH:
        _mushroom(pickup.data.effect)
        return
    match pickup.data.kind:
        PickupData.Kind.MUSHROOM: index=2
        PickupData.Kind.APPLE: index=1
        PickupData.Kind.EMERALD: index=3 if pickup.data.amount>1 else 0
    RemixArt.icon(self,index,Rect2(-11,-11,22,22))
    if pickup.data.amount>1:
        draw_rect(Rect2(-5,-14,10,2),Color("eed18b"))

func _mushroom(effect: int) -> void:
    RemixArt.icon(self,2,Rect2(-11,-11,22,22))
    # Tiny glyph remains legible even for players who cannot distinguish hues.
    draw_rect(Rect2(5,3,8,8),Color("25313a"))
    draw_set_transform(Vector2(9,11))
    var ink:=Color("fff2cb")
    if effect==PickupData.Effect.HEAL:
        draw_rect(Rect2(-1,-7,2,6),ink)
        draw_rect(Rect2(-3,-5,6,2),ink)
    elif effect==PickupData.Effect.GUARD:
        draw_rect(Rect2(-3,-7,6,4),ink)
        draw_rect(Rect2(-1,-3,2,2),ink)
    else:
        draw_rect(Rect2(0,-8,3,3),ink)
        draw_rect(Rect2(-2,-5,4,2),ink)
        draw_rect(Rect2(-2,-3,2,2),ink)
