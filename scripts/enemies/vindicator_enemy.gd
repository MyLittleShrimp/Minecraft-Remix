class_name VindicatorEnemy
extends RemixEnemy
## A committed, directional heavy attack. Damage resolves before the strike.
const REACH := 62.0
const DAMAGE := 4
var provoked := false
var strike_pending := false
var swing_flash := 0.0
var strikes := 0

func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/vindicator_visual.gd"))

func _physics_process(delta: float) -> void:
    swing_flash=maxf(0,swing_flash-delta)
    super._physics_process(delta)

func _tick_walker() -> void:
    velocity.x=0
    if state==State.AIM:
        if state_left<=0:
            state=State.RECOVER
            state_left=data.shot_recovery
            strike_pending=true
        return
    if state==State.RECOVER and state_left>0: return
    var aware: bool=sees_target() or (provoked and is_instance_valid(target) and not target.dead and clear_line(target_center()))
    if aware:
        facing=1 if target_center().x>center().x else -1
        if absf(target_center().x-center().x)<58 and absf(target.position.y-position.y)<48:
            state=State.AIM
            state_left=data.aim_seconds
            return
        state=State.CHASE
        velocity.x=facing*data.chase_speed if safe_step(facing) else 0.0
    else:
        super._tick_walker()

func late_step() -> void:
    if not strike_pending: return
    strike_pending=false
    if health.current<=0 or state==State.DEAD: return
    strikes+=1
    swing_flash=0.18
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(REACH,46)
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,center()+Vector2(facing*REACH*0.5,0))
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var victim:=hit.collider as CombatHurtbox
        if victim!=null and clear_line(victim.global_position):
            victim.receive(DamageEvent.create(self,2,DAMAGE,Vector2(facing*230,-170)))

func _on_damage(event: DamageEvent) -> void:
    provoked=true
    # Raised axe has poise, but ordinary chase/recovery can be interrupted.
    if state==State.AIM:
        flash_left=0.25
        last_damage=event.amount
    else: super._on_damage(event)

func melee_opening_bonus(event: DamageEvent) -> int:
    # Only a completed, missed strike exposes this opening, never the raised axe.
    if state == State.RECOVER and state_left > 0 and not strike_pending:
        return int(event.get_meta("recovery_bonus", 0))
    return 0

func _on_death() -> void:
    strike_pending=false
    super._on_death()

func reset_target() -> void:
    super.reset_target()
    provoked=false
    strike_pending=false
    swing_flash=0
    strikes=0
