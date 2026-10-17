class_name DrownedEnemy
extends RemixEnemy
## A visible, interruptible throw, aimed once at the beginning of the tell.
var locked_direction:=Vector2.LEFT
var throw_pending:=false
var provoked:=false
var throws:=0

func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/drowned_visual.gd"))

func _tick_walker() -> void:
    velocity.x=0
    if state==State.AIM:
        if state_left<=0:
            state=State.RECOVER
            state_left=data.shot_recovery
            throw_pending=true
        return
    if state==State.RECOVER and state_left>0: return
    var aware:=sees_target() or (provoked and is_instance_valid(target) and not target.dead and clear_line(target_center()))
    if aware:
        facing=1 if target_center().x>center().x else -1
        if center().distance_to(target_center())<=400:
            locked_direction=(target_center()-center()).normalized()
            state=State.AIM
            state_left=data.aim_seconds
        else:
            state=State.CHASE
            velocity.x=facing*data.chase_speed if safe_step(facing) else 0.0
    else: super._tick_walker()

func late_step() -> void:
    if not throw_pending: return
    throw_pending=false
    if health.current<=0 or not is_instance_valid(target) or target.dead: return
    var spear:=ArrowProjectile.new()
    spear.set_script(load("res://scripts/enemies/drowned_spear.gd"))
    spear.position=get_parent().to_local(center())
    spear.velocity=locked_direction*data.arrow_speed
    spear.event=DamageEvent.create(self,2,3,Vector2(facing*145,-100))
    spear.lifetime=1.5
    get_parent().add_child(spear)
    throws+=1
    fired.emit(spear)

func _on_damage(event: DamageEvent) -> void:
    provoked=true
    throw_pending=false
    super._on_damage(event)
    if state==State.RECOVER: state_left=maxf(state_left,0.7)

func _on_death() -> void:
    throw_pending=false
    super._on_death()

func reset_target() -> void:
    super.reset_target()
    throw_pending=false
    provoked=false
    throws=0
    locked_direction=Vector2.LEFT
