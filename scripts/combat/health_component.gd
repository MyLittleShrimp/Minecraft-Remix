class_name HealthComponent
extends Node
## Sources enqueue during physics; this component resolves after all sources.
## Player: strongest ordinary hit per tick. Targets may accept independent hits.

signal health_changed(current: int, maximum: int)
signal damaged(event: DamageEvent)
signal healed(amount: int)
signal died

@export var max_health: int = 20
@export var faction: int = 1
@export var invulnerability_seconds: float = 0.8
@export var strongest_per_tick: bool = true
var current: int
var invulnerability_left: float = 0.0
var guard_left: float = 0.0
var pending: Array[DamageEvent] = []
var seen: Dictionary = {}

func _ready() -> void:
    process_physics_priority = 100
    reset_health()

func queue_damage(event: DamageEvent) -> void:
    if current <= 0 or event.amount <= 0 or event.faction == faction or seen.has(event.attack_id):
        return
    seen[event.attack_id] = true
    if seen.size() > 256:
        seen.erase(seen.keys()[0])
    if invulnerability_left > 0.0 and not event.bypass_invulnerability:
        return
    if guard_left>0 and (not event.bypass_invulnerability or event.get_meta("poison_tick",false) or event.get_meta("wither_tick",false)):
        return
    pending.append(event)

func _physics_process(delta: float) -> void:
    invulnerability_left = maxf(0.0, invulnerability_left - delta)
    guard_left = maxf(0.0, guard_left - delta)
    resolve_pending()

func resolve_pending() -> void:
    # Enemies resolve weapon hits before detonation. Blast victims can resolve
    # immediately so a killed armed neighbour cannot detonate later this tick.
    if pending.is_empty():
        return
    # Stable tie break makes equal hits independent of node traversal order.
    pending.sort_custom(func(a: DamageEvent, b: DamageEvent) -> bool:
        return a.amount > b.amount if a.amount != b.amount else a.attack_id < b.attack_id)
    var events: Array[DamageEvent] = pending.duplicate()
    pending.clear()
    for event in events:
        if current <= 0:
            break
        current = maxi(damage_floor(), current - event.amount)
        if not event.get_meta("starvation",false) and not event.get_meta("poison_tick",false) and not event.get_meta("wither_tick",false):
            invulnerability_left = event.protection_override if event.protection_override >= 0 else invulnerability_seconds
        health_changed.emit(current, max_health)
        damaged.emit(event)
        if current == 0:
            died.emit()
        if strongest_per_tick:
            break

func damage_floor() -> int:
    return 0

func heal(amount: int) -> int:
    if current <= 0 or amount <= 0:
        return 0
    var restored := mini(amount, max_health - current)
    if restored > 0:
        current += restored
        health_changed.emit(current, max_health)
        healed.emit(restored)
    return restored

func reset_health() -> void:
    current = max_health
    invulnerability_left = 0.0
    guard_left = 0.0
    pending.clear()
    seen.clear()
    health_changed.emit(current, max_health)
