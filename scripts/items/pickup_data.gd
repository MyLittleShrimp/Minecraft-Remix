class_name PickupData
extends Resource

enum Kind { MUSHROOM, APPLE, EMERALD, BREAD, MEAT }
enum Effect { STRENGTH, HEAL, GUARD, HASTE }
@export var effect: Effect = Effect.STRENGTH
@export var id: StringName
@export var label: String
@export var kind: Kind = Kind.MUSHROOM
@export var amount: int = 1
@export var duration: float = 12.0
@export var multiplier: float = 1.25
@export var emerge_seconds: float = 0.25
@export var walk_speed: float = 48.0

func effect_hint() -> String:
    match effect:
        Effect.HEAL: return "生命蘑菇 · 恢复 %d 生命，满血时保留" % amount
        Effect.GUARD: return "守护蘑菇 · %d 秒战斗无敌，不免坠落与饥饿" % int(duration)
        Effect.HASTE: return "迅捷蘑菇 · 攻速 / 蓄力 +25%%，持续 %d 秒" % int(duration)
    return "力量蘑菇 · 伤害 +25%%，持续 %d 秒" % int(duration)
