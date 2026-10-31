class_name EnemyVfxArt
extends RefCounted
## Visual-only atlases. Callers supply the existing attack/status clocks.
const POTION_BURST_SECONDS := 0.42
const WITHER_BURST_SECONDS := 0.42
const HARM: Texture2D = preload("res://assets/vfx/m4ah5/potion-harm.png")
const POISON: Texture2D = preload("res://assets/vfx/m4ah5/potion-poison.png")
const WITHER_BURST: Texture2D = preload("res://assets/vfx/m4ah5/wither-burst.png")
const WITHER_BURST_CYAN: Texture2D = preload("res://assets/vfx/m4ah5/wither-burst-cyan.png")
const STATUS: Texture2D = preload("res://assets/vfx/m4ah4/poison-status.png")
const WARP: Texture2D = preload("res://assets/vfx/m4ah4/ender-warp.png")
const CHARGE: Texture2D = preload("res://assets/vfx/m4ah4/wither-charge.png")
const STREAM: Texture2D = preload("res://assets/vfx/m4ah4/wither-stream.png")
const IMPACT: Texture2D = preload("res://assets/vfx/m4ah4/wither-impact.png")

static func frame(canvas: CanvasItem, texture: Texture2D, size: Vector2, index: int, center: Vector2, tint: Color = Color.WHITE) -> void:
    canvas.draw_texture_rect_region(texture,Rect2((center-size/2).round(),size),Rect2(Vector2(index*size.x,0),size),tint)

static func potion_burst(canvas: CanvasItem, poisonous: bool, remaining: float, radius: float) -> void:
    var progress := clampf(1-remaining/POTION_BURST_SECONDS,0,1)
    frame(canvas,POISON if poisonous else HARM,Vector2(88,88),mini(11,int(progress*12)),Vector2.ZERO)
    # The initial thin boundary matches the actual circular splash (30 / 34px).
    if progress<0.3:
        canvas.draw_arc(Vector2.ZERO,radius,0,TAU,32,Color(Color("a4e878") if poisonous else Color("ff9f92"),(1-progress/0.3)*0.65),1)

static func poison_status(canvas: CanvasItem, remaining: float, tick_left: float) -> void:
    var fade := minf(1,remaining/0.6)
    frame(canvas,STATUS,Vector2(48,64),posmod(int((6-remaining)*20),16),Vector2(0,-26),Color(1,1,1,0.85*fade))
    # A few low bubbles mark the afflicted player, never a lingering ground hazard.
    var pulse := clampf((tick_left-1.65)/0.35,0,1)*fade
    if pulse>0:
        canvas.draw_arc(Vector2(0,-2),13+(1-pulse)*3,PI,TAU,12,Color(0.65,0.94,0.39,pulse*0.6),1)

static func warp(canvas: CanvasItem, at: Vector2, seconds: float, alpha: float = 0.65) -> void:
    frame(canvas,WARP,Vector2(96,96),posmod(int(seconds*20),16),at+Vector2(0,-32),Color(1,1,1,alpha))

static func warp_marker(canvas: CanvasItem, at: Vector2, remaining: float) -> void:
    var color := Color("e7b4ff")
    # Open corners keep the silhouette readable and retain the original 48px landing cue.
    for x in [-24,24]:
        for y in [-65,0]:
            var start := at+Vector2(x,y)
            canvas.draw_line(start,start+Vector2(7 if x<0 else -7,0),color,1)
            canvas.draw_line(start,start+Vector2(0,7 if y<0 else -7),color,1)
    canvas.draw_line(at+Vector2(-24,-2),at+Vector2(24,-2),Color(color,0.75),2)
    var r := 4.0+minf(remaining,1)*8
    canvas.draw_arc(at+Vector2(0,-2),r,PI,TAU,12,Color("fff0d9"),1)

static func wither_charge(canvas: CanvasItem, remaining: float) -> void:
    frame(canvas,CHARGE,Vector2(128,128),posmod(int((1.1-remaining)*20),16),Vector2.ZERO,Color(1,1,1,0.75))

static func wither_stream(canvas: CanvasItem, seconds: float, facing: int) -> void:
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    # The energy head sits inside the boss; the tail remains behind its damage rectangle.
    frame(canvas,STREAM,Vector2(192,96),posmod(int(seconds*20),12),Vector2(-14,0),Color(1,1,1,0.8))
    canvas.draw_set_transform(Vector2.ZERO)

static func wither_impact(canvas: CanvasItem, at: Vector2, remaining: float) -> void:
    frame(canvas,IMPACT,Vector2(112,112),mini(11,int(clampf(1-remaining/0.42,0,1)*12)),at)

static func wither_burst(canvas: CanvasItem, at: Vector2, remaining: float, enraged: bool) -> void:
    var progress := clampf(1-remaining/WITHER_BURST_SECONDS,0,1)
    frame(canvas,WITHER_BURST if enraged else WITHER_BURST_CYAN,Vector2(96,96),mini(11,int(progress*12)),at)
