class_name PixelVfxArt
extends RefCounted
## Preloaded, native-pixel atlases. Combat owns the clock; drawing cannot hit targets.
const SWORD: Texture2D = preload("res://assets/vfx/m4ah3/sword-slash.png")
const GIANT: Texture2D = preload("res://assets/vfx/m4ah3/giant-slash.png")
const BOLT: Texture2D = preload("res://assets/vfx/m4ah3/sky-bolt.png")
const RING: Texture2D = preload("res://assets/vfx/m4ah3/thunder-ring.png")
const GROUND_GLOW: Texture2D = preload("res://resources/vfx/lightning_ground_glow.tres")
const LIGHTNING_TAIL := 0.38

static func sword_frame(time: float, weapon: WeaponData) -> int:
    if weapon == null or time < weapon.windup: return -1
    var duration := weapon.active_seconds + minf(0.08, weapon.recovery)
    var elapsed := time - weapon.windup
    if elapsed >= duration: return -1
    return mini(9, int(elapsed / duration * 10))

static func sword(canvas: CanvasItem, time: float, weapon: WeaponData, facing: int, giant: bool) -> void:
    var frame := sword_frame(time, weapon)
    if frame < 0: return
    var size := 160 if giant else 80
    # The larger arc wraps further above/below Steve; its forward edge stays near reach 64.
    var anchor := Vector2(6 if giant else 9, -23)
    canvas.draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
    canvas.draw_texture_rect_region(GIANT if giant else SWORD,
        Rect2(anchor - Vector2.ONE * size / 2.0, Vector2.ONE * size),
        Rect2(frame * size, 0, size, size))
    canvas.draw_set_transform(Vector2.ZERO)

static func lightning(canvas: CanvasItem, elapsed: float, sky: Vector2, head: Vector2, foot: Vector2, glow: bool = false) -> void:
    if elapsed < 0 or elapsed >= LIGHTNING_TAIL: return
    var frame := mini(11, int(elapsed / LIGHTNING_TAIL * 12))
    # Crop from the bottom of the long atlas instead of stretching pixels.
    # A very tall viewport can use multiple sections, each ending at the same X.
    var bottom := (head + Vector2(0, 5)).round()
    var top := floorf(sky.y)
    while bottom.y > top:
        var height := minf(510, bottom.y - top)
        canvas.draw_texture_rect_region(BOLT, Rect2(bottom - Vector2(48, height), Vector2(96, height)),
            Rect2(frame * 96, 510 - height, 96, height))
        bottom.y -= height
    canvas.draw_texture_rect_region(RING, Rect2(foot.round() - Vector2(48, 24), Vector2(96, 48)),
        Rect2(frame * 96, 0, 96, 48))
    if glow:
        var fade := pow(maxf(0,1-elapsed/LIGHTNING_TAIL),2)
        canvas.draw_texture_rect(GROUND_GLOW,Rect2(foot.round()-Vector2(48,24),Vector2(96,48)),false,Color(1,1,1,fade))
