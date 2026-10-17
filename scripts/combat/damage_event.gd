class_name DamageEvent
extends RefCounted
## Immutable once submitted. IDs remain unique across room resets and actors.

static var serial: int = 0
var attack_id: int
var source_id: int
var faction: int
var amount: int
var impulse: Vector2
var bypass_invulnerability: bool = false
var protection_override: float = -1.0

static func create(source: Node, team: int, damage: int, knockback: Vector2 = Vector2.ZERO) -> DamageEvent:
    serial += 1
    var event := DamageEvent.new()
    event.attack_id = serial
    event.source_id = source.get_instance_id()
    event.faction = team
    event.amount = damage
    event.impulse = knockback
    return event

func with_amount(damage: int) -> DamageEvent:
    # Keep the attack identity; one cleave can hit several victims with different bonuses.
    var copy := DamageEvent.new()
    copy.attack_id = attack_id
    copy.source_id = source_id
    copy.faction = faction
    copy.amount = damage
    copy.impulse = impulse
    copy.bypass_invulnerability = bypass_invulnerability
    copy.protection_override = protection_override
    for key in get_meta_list(): copy.set_meta(key, get_meta(key))
    return copy
