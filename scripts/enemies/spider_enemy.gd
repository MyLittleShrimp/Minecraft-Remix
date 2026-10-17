class_name SpiderEnemy
extends RemixEnemy
## Low profile, readable crouch, one committed leap, then a punishable recovery.
var pounces := 0

func _ready() -> void:
    super._ready()
    for child in get_children():
        if child is CollisionShape2D:
            child.position.y = -14
            child.shape.size = Vector2(32,26)
    receiver.position.y = -14
    receiver.get_child(0).shape.size = Vector2(32,26)

func center() -> Vector2:
    return global_position + Vector2(0,-14)

func _safe_landing(direction: int) -> bool:
    var at := global_position + Vector2(direction*95,0)
    var ray := PhysicsRayQueryParameters2D.create(at+Vector2(0,-12),at+Vector2(0,24),3)
    return not get_world_2d().direct_space_state.intersect_ray(ray).is_empty() and clear_line(center()+Vector2(direction*95,0))

func _tick_walker() -> void:
    if state == State.POUNCE:
        if is_on_floor() and state_left <= 0:
            state = State.RECOVER
            state_left = 0.8
            velocity.x = 0
        return
    if state == State.POUNCE_WARNING:
        velocity.x = 0
        if not sees_target() or not _safe_landing(facing):
            state = State.RECOVER
            state_left = 0.6
        elif state_left <= 0:
            state = State.POUNCE
            state_left = 0.12
            velocity = Vector2(facing*215,-250)
            pounces += 1
        return
    if state == State.RECOVER and state_left > 0:
        velocity.x = 0
        return
    if sees_target() and is_on_floor() and absf(target.global_position.y-global_position.y)<48:
        var distance := target.global_position.x-global_position.x
        facing = 1 if distance>=0 else -1
        if absf(distance)>=52 and absf(distance)<=175 and _safe_landing(facing):
            state = State.POUNCE_WARNING
            state_left = 0.5
            velocity.x = 0
            return
    super._tick_walker()

func _contact_damage() -> void:
    if not is_instance_valid(target) or target.dead: return
    var body := Rect2(global_position+Vector2(-17,-27),Vector2(34,27))
    var victim := Rect2(target.global_position+Vector2(-9,-44),Vector2(18,44))
    if body.intersects(victim) and clear_line(target_center()):
        target.get_node("Health").queue_damage(DamageEvent.create(self,2,data.contact_damage,Vector2(facing*140,-100)))

func _on_damage(event: DamageEvent) -> void:
    super._on_damage(event)
    state = State.RECOVER
    state_left = 0.7

func reset_target() -> void:
    super.reset_target()
    pounces = 0
