class_name WildlifeActor
extends RemixEnemy
var species := 0 # rabbit, sheep, pig, chicken, cow, mooshroom
var food: PickupData
var roam_left := 0.0
var roam_right := 0.0
var hop_left := 0.4
func _ready() -> void:
    super._ready()
    remove_from_group("enemies")
    add_to_group("wildlife")
    visual.set_script(load("res://scripts/enemies/wildlife_visual.gd"))
    get_child(0).position.y=-13
    get_child(0).shape.size=Vector2(24,26)
    receiver.position.y=-13
    receiver.get_child(0).shape.size=Vector2(26,26)
func center() -> Vector2: return global_position+Vector2(0,-13)
func _physics_process(delta: float) -> void:
    flash_left=maxf(0,flash_left-delta)
    visual.queue_redraw()
    if state==State.DEAD: return
    velocity.y=minf(700,velocity.y+1500*delta)
    hop_left-=delta
    if not on_camera(): velocity.x=0
    else:
        if position.x<=roam_left: facing=1
        elif position.x>=roam_right: facing=-1
        elif is_on_floor() and not safe_step(facing): facing*=-1
        velocity.x=facing*[105,82,88,96,62,60][species]
        if species in [0,3] and is_on_floor() and hop_left<=0:
            velocity.y=-220 if species==0 else -135
            hop_left=0.75 if species==0 else 1.15
    move_and_slide()
    steps+=absf(velocity.x)*delta*0.12
    visual.position=global_position.round()-global_position
func _on_damage(event: DamageEvent) -> void:
    flash_left=0.2
    last_damage=event.amount
func reset_target() -> void:
    super.reset_target()
    hop_left=0.4
