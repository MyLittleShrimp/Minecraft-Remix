class_name HungerComponent
extends Node
## Action-based food budget: idle/reading and walking never consume food.
signal changed(value: float)
const MAXIMUM := 20.0
const JUMP_COST := 0.45
const SWORD_COST := 0.20
const ARROW_COST := 0.30
const STARVE_INTERVAL := 10.0
var value := MAXIMUM
var empty_seconds := 0.0
var spent := 0.0
var eaten := 0.0
var enabled := true
@onready var actor: RemixPlayer = get_parent()
@onready var health: HealthComponent = actor.get_node("Health")

func _ready() -> void:
    process_physics_priority = 90
    actor.jumped.connect(func() -> void: consume(JUMP_COST))
    var weapon: WeaponController = actor.get_node("Equipment")
    weapon.swung.connect(func() -> void: consume(SWORD_COST))
    weapon.shot_fired.connect(func(_damage: int, _direction: Vector2) -> void: consume(ARROW_COST))

func consume(amount: float) -> void:
    if not enabled or actor.dead or actor.controls_locked or get_tree().paused: return
    var actual := minf(value, maxf(0, amount))
    value = maxf(0, value - actual)
    spent += actual
    changed.emit(value)

func feed(amount: float) -> int:
    if actor.dead or health.current <= 0 or amount <= 0: return 0
    var actual := minf(amount, MAXIMUM - value)
    if actual <= 0.001: return 0
    value += actual
    eaten += actual
    empty_seconds = 0
    changed.emit(value)
    return ceili(actual)

func restore(amount: float, reset_totals: bool = false) -> void:
    value = clampf(amount,0,MAXIMUM)
    empty_seconds = 0
    if reset_totals:
        spent = 0
        eaten = 0
    changed.emit(value)

func _physics_process(delta: float) -> void:
    if not enabled or actor.dead or actor.controls_locked or health.current <= 0: return
    if value > 0.001:
        empty_seconds = 0
        return
    empty_seconds += delta
    if empty_seconds >= STARVE_INTERVAL:
        empty_seconds -= STARVE_INTERVAL
        var event := DamageEvent.create(self,0,1)
        event.bypass_invulnerability = true
        event.protection_override = 0
        event.set_meta("starvation",true)
        health.queue_damage(event)
