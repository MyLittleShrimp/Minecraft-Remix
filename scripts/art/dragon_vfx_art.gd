class_name DragonVfxArt
extends RefCounted
## Native pixels, driven by the existing attack clocks. No damage or extra timers.
const CHARGE: Texture2D=preload("res://assets/vfx/m4ah8/dragon-charge.png")
const BREATH: Texture2D=preload("res://assets/vfx/m4ah8/dragon-breath.png")
const BREATH_RAGE: Texture2D=preload("res://assets/vfx/m4ah8/dragon-breath-rage.png")
const LAND: Texture2D=preload("res://assets/vfx/m4ah8/dragon-breath-land.png")
const BITE: Texture2D=preload("res://assets/vfx/m4ah8/dragon-bite.png")
const TAIL: Texture2D=preload("res://assets/vfx/m4ah8/dragon-tail.png")
const DIVE: Texture2D=preload("res://assets/vfx/m4ah8/dragon-dive.png")
const RAGE: Texture2D=preload("res://assets/vfx/m4ah8/dragon-rage.png")

static func loop_frame(t: float,count: int) -> int:
    return posmod(int(t*20),count)

static func one_frame(progress: float,count: int) -> int:
    return mini(count-1,int(clampf(progress,0,1)*count))

static func charge(canvas: Node2D,at: Vector2,t: float,active: bool) -> void:
    EnemyVfxArt.frame(canvas,CHARGE,Vector2(80,80),loop_frame(t,16),at,Color(1,1,1,0.95 if active else 0.8))

static func breath(canvas: Node2D,b: EnderDragon) -> void:
    var r:=b.breath_rect
    var size:=Vector2(192,176) if b.second_phase else Vector2(168,176)
    # Both atlases fit exactly inside the current 168/192 x 176 danger zone.
    EnemyVfxArt.frame(canvas,BREATH_RAGE if b.second_phase else BREATH,size,loop_frame(b.visual_seconds,16),r.get_center(),Color(1,1,1,0.85))
    var age:=2.0-b.timer
    if age<0.42:
        EnemyVfxArt.frame(canvas,LAND,Vector2(96,64),one_frame(age/0.42,12),Vector2(r.get_center().x,r.end.y-32))

static func melee(canvas: Node2D,b: EnderDragon,tail: bool) -> void:
    var r:=b.tail_rect if tail else b.bite_rect
    var duration:=0.25 if tail else 0.2
    var facing: int=-b.facing if tail else b.facing
    canvas.draw_set_transform(r.get_center()-b.position,0,Vector2(facing,1))
    EnemyVfxArt.frame(canvas,TAIL if tail else BITE,Vector2(192,48) if tail else Vector2(128,64),one_frame(1-b.timer/duration,10),Vector2.ZERO)
    canvas.draw_set_transform(-b.position)

static func dive(canvas: Node2D,b: EnderDragon) -> void:
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(b.facing,1))
    EnemyVfxArt.frame(canvas,DIVE,Vector2(240,80),loop_frame(b.visual_seconds,12),Vector2(-122,0),Color(1,1,1,0.9))
    canvas.draw_set_transform(-b.position)

static func rage(canvas: Node2D,b: EnderDragon) -> void:
    EnemyVfxArt.frame(canvas,RAGE,Vector2(224,224),one_frame(1-b.timer/1.2,18),b.position)
