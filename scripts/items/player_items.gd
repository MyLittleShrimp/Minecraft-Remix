class_name PlayerItems
extends Node2D
## Per-character temporary effects and unbanked room score. No global inventory.
@onready var actor: RemixPlayer = get_parent()
@onready var health: HealthComponent = actor.get_node("Health")
@onready var equipment: WeaponController = actor.get_node("Equipment")
var strength_left: float = 0.0
var haste_left: float = 0.0
var emeralds: int = 0
var collected_count: int = 0
var pickup_left: float = 0.0
var pickup_food: bool = false
var pickup_tint := Color.WHITE
var heal_left: float = 0.0
var healed_amount: int = 0
const FEEDBACK_FONT := preload("res://resources/ui_font.tres")

func _ready() -> void:
    process_physics_priority = -20
    health.died.connect(clear_strength)
    health.healed.connect(_healed)

func _healed(amount: int) -> void:
    healed_amount = amount + (healed_amount if heal_left>0 else 0)
    heal_left = ActionVfxArt.HEAL_SECONDS
    queue_redraw()

func _physics_process(delta: float) -> void:
    pickup_left = maxf(0,pickup_left-delta)
    heal_left = maxf(0,heal_left-delta)
    strength_left = maxf(0, strength_left - delta)
    haste_left = maxf(0, haste_left - delta)
    if haste_left <= 0: equipment.attack_speed = 1.0
    if strength_left <= 0:
        equipment.damage_scale = 1.0
    queue_redraw()

func accept(data: PickupData) -> int:
    if actor.dead or health.current <= 0:
        return 0
    var applied := data.amount
    match data.kind:
        PickupData.Kind.MUSHROOM:
            match data.effect:
                PickupData.Effect.STRENGTH:
                    strength_left = data.duration
                    equipment.damage_scale = data.multiplier
                PickupData.Effect.HEAL: applied = health.heal(data.amount)
                PickupData.Effect.GUARD: health.guard_left = data.duration
                PickupData.Effect.HASTE:
                    haste_left = data.duration
                    equipment.attack_speed = data.multiplier
        PickupData.Kind.APPLE:
            applied = health.heal(data.amount)
        PickupData.Kind.BREAD, PickupData.Kind.MEAT:
            var hunger := actor.get_node_or_null("Hunger") as HungerComponent
            applied = hunger.feed(data.amount) if hunger != null else 0
        PickupData.Kind.EMERALD:
            emeralds += data.amount
    if applied > 0:
        collected_count += 1
        # Healing gets its own feedback from the actual health delta.
        if data.kind!=PickupData.Kind.APPLE and not (data.kind==PickupData.Kind.MUSHROOM and data.effect==PickupData.Effect.HEAL):
            pickup_left = ActionVfxArt.LOOT_SECONDS
            pickup_food = data.kind in [PickupData.Kind.BREAD,PickupData.Kind.MEAT]
            pickup_tint = Color.WHITE if pickup_food else Color("66ffc6")
            if data.kind==PickupData.Kind.MUSHROOM:
                pickup_tint = [Color("ffb275"),Color.WHITE,Color("ffe28a"),Color("83dfff")][data.effect]
        queue_redraw()
    return applied

func clear_strength() -> void:
    pickup_left = 0
    heal_left = 0
    healed_amount = 0
    strength_left = 0
    haste_left = 0
    health.guard_left = 0
    equipment.attack_speed = 1.0
    equipment.damage_scale = 1.0
    queue_redraw()

func reset_items() -> void:
    clear_strength()
    emeralds = 0
    collected_count = 0

func buff_summary() -> String:
    var parts: PackedStringArray=[]
    if strength_left>0: parts.append("力量 %ds" % ceili(strength_left))
    if haste_left>0: parts.append("迅捷 %ds" % ceili(haste_left))
    if health.guard_left>0: parts.append("无敌 %ds" % ceili(health.guard_left))
    return " · ".join(parts)

func _draw() -> void:
    if actor.dead: return
    if pickup_left>0: ActionVfxArt.loot(self,pickup_left,pickup_food,pickup_tint)
    if heal_left>0:
        ActionVfxArt.heal(self,heal_left)
        var alpha:=minf(1,heal_left/0.2)
        draw_string(FEEDBACK_FONT,Vector2(15,-46-(1-heal_left/ActionVfxArt.HEAL_SECONDS)*13),"+%d"%healed_amount,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color(0.80,1,0.64,alpha))
    if strength_left>0:
        draw_rect(Rect2(-13,-49,26,51),Color("eea163"),false,1)
    if haste_left>0:
        for i in 3:
            draw_line(Vector2(-actor.facing*(14+i*3),-8-i*10),Vector2(-actor.facing*(21+i*3),-8-i*10),Color("70d6ff"),2)
    if health.guard_left>0:
        var fade:=1.0 if health.guard_left>0.7 else 0.35+0.65*absf(sin(health.guard_left*24))
        draw_polyline(PackedVector2Array([Vector2(-18,-43),Vector2(-10,-53),Vector2(10,-53),Vector2(18,-43),Vector2(18,-5),Vector2(10,5),Vector2(-10,5),Vector2(-18,-5),Vector2(-18,-43)]),Color(1,0.88,0.45,fade),2)
