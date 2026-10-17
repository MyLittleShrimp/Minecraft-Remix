class_name CombatHurtbox
extends Area2D
## A query-only receiver; it does not push bodies or deal contact damage.

@export var health: HealthComponent
@export var size: Vector2 = Vector2(18, 40)
var hit_priority: int = 0 # A shared-health weak point wins an overlapping melee query.

func _ready() -> void:
    collision_layer = 8 if health.faction == 1 else 16
    collision_mask = 0
    monitoring = false
    var rectangle := RectangleShape2D.new()
    rectangle.size = size
    var collider := CollisionShape2D.new()
    collider.shape = rectangle
    add_child(collider)

func receive(event: DamageEvent) -> void:
    health.queue_damage(event)
