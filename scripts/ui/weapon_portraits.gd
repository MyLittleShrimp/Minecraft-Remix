class_name WeaponPortraits
extends RefCounted
const ATLAS := preload("res://assets/art/m4ab-armory/weapon-atlas.png")
const IDS := ["netherite_sword","bow","crossbow","axe","trident"]
static func texture(id: String) -> AtlasTexture:
    var index:=IDS.find(id)
    if index<0: return null
    var result:=AtlasTexture.new()
    result.atlas=ATLAS
    result.region=Rect2((index%3)*512,(index/3)*512,512,512)
    result.filter_clip=true
    return result

static func picture(parent: Control, id: String, rect: Rect2) -> TextureRect:
    var node:=TextureRect.new()
    node.texture=texture(id)
    node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    node.mouse_filter=Control.MOUSE_FILTER_IGNORE
    node.position=rect.position
    node.size=rect.size
    parent.add_child(node)
    return node
