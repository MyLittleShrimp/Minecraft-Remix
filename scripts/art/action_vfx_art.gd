class_name ActionVfxArt
extends RefCounted
const TNT: Texture2D=preload("res://assets/vfx/m4ah7/tnt-blast.png")
const CREEPER: Texture2D=preload("res://assets/vfx/m4ah6/creeper-blast.png")
const FIRE: Texture2D=preload("res://assets/vfx/m4ah6/fire-tail.png")
const RETURN: Texture2D=preload("res://assets/vfx/m4ah6/return-tail.png")
const REFLECT: Texture2D=preload("res://assets/vfx/m4ah6/reflect-flash.png")
const FIRE_HIT: Texture2D=preload("res://assets/vfx/m4ah6/fire-impact.png")
const LOOT: Texture2D=preload("res://assets/vfx/m4ah6/loot-spark.png")
const FOOD: Texture2D=preload("res://assets/vfx/m4ah6/food-motes.png")
const HEAL: Texture2D=preload("res://assets/vfx/m4ah6/heal-rise.png")
const LOOT_SECONDS:=0.48
const HEAL_SECONDS:=0.64

static func one_shot(canvas: CanvasItem, texture: Texture2D, size: Vector2, count: int, progress: float, at: Vector2=Vector2.ZERO, tint: Color=Color.WHITE) -> void:
    EnemyVfxArt.frame(canvas,texture,size,mini(count-1,int(clampf(progress,0,1)*count)),at,tint)

static func blast(canvas: CanvasItem, creeper: bool, progress: float, radius: float) -> void:
    var size:=160 if creeper else 176
    one_shot(canvas,CREEPER if creeper else TNT,Vector2(size,size),14 if creeper else 16,progress)
    # This brief, fine perimeter records the actual hit radius, never a new hitbox.
    if progress<0.20:
        canvas.draw_arc(Vector2.ZERO,radius,0,TAU,48,Color(0.98,0.90,0.64,(1-progress/0.20)*0.5),1)

static func fireball(canvas: CanvasItem, velocity: Vector2, age: float, reflected: bool) -> void:
    canvas.draw_set_transform(Vector2.ZERO,velocity.angle())
    EnemyVfxArt.frame(canvas,RETURN if reflected else FIRE,Vector2(96,48),posmod(int(age*20),8),Vector2(-16,0))
    canvas.draw_set_transform(Vector2.ZERO)

static func flash(canvas: CanvasItem, kind: StringName, progress: float) -> void:
    var fire:=kind==&"fire_hit"
    one_shot(canvas,FIRE_HIT if fire else REFLECT,Vector2(64,64) if fire else Vector2(72,72),10,progress)

static func loot(canvas: CanvasItem, remaining: float, food: bool, tint: Color) -> void:
    one_shot(canvas,FOOD if food else LOOT,Vector2(64,64),12,1-remaining/LOOT_SECONDS,Vector2(0,-24),tint)

static func heal(canvas: CanvasItem, remaining: float) -> void:
    one_shot(canvas,HEAL,Vector2(64,80),16,1-remaining/HEAL_SECONDS,Vector2(0,-26))
