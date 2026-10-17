class_name WitherSkeleton
extends RemixEnemy
## A locked-direction long slash: bait, dodge, punish the recovery.
const REACH := 72.0
const DAMAGE := 3
var active := true
var encounter_bounds := Vector2(-INF,INF)
var provoked := false
var strike_pending := false
var swing_flash := 0.0
var strikes := 0
func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/wither_visual.gd"))
    set_active(active)
func set_active(value: bool) -> void:
    active=value
    receiver.set_deferred("collision_layer",16 if value and health.current>0 else 0)
    if value:
        provoked=true
        state=State.RECOVER
        state_left=0.65
    else:
        velocity=Vector2.ZERO
        strike_pending=false
func _physics_process(delta: float) -> void:
    if not active:
        visual.queue_redraw()
        return
    swing_flash=maxf(0,swing_flash-delta)
    super._physics_process(delta)
    global_position.x=clampf(global_position.x,encounter_bounds.x,encounter_bounds.y)
func _tick_walker() -> void:
    velocity.x=0
    if state==State.AIM:
        if state_left<=0:
            state=State.RECOVER
            state_left=data.shot_recovery
            strike_pending=true
        return
    if state==State.RECOVER and state_left>0: return
    var valid: bool=is_instance_valid(target) and not target.dead and target.position.x>=encounter_bounds.x-18 and target.position.x<=encounter_bounds.y+18
    if not valid: return
    if sees_target() or (provoked and clear_line(target_center())):
        facing=1 if target_center().x>center().x else -1
        if absf(target_center().x-center().x)<REACH-6 and absf(target.position.y-position.y)<48:
            state=State.AIM
            state_left=data.aim_seconds
        else:
            state=State.CHASE
            velocity.x=facing*data.chase_speed if safe_step(facing) else 0.0
    else: super._tick_walker()
func late_step() -> void:
    if not strike_pending: return
    strike_pending=false
    if not active or health.current<=0 or state==State.DEAD: return
    strikes+=1
    swing_flash=0.22
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
            var event:=DamageEvent.create(self,2,DAMAGE,Vector2(facing*200,-155))
            event.set_meta("wither_impact",true)
            victim.receive(event)
func _on_damage(event: DamageEvent) -> void:
    provoked=true
    if state==State.AIM:
        flash_left=0.25
        last_damage=event.amount
    else: super._on_damage(event)
func melee_opening_bonus(event: DamageEvent) -> int:
    if state==State.RECOVER and state_left>0 and not strike_pending:
        return int(event.get_meta("recovery_bonus",0))
    return 0
func _on_death() -> void:
    strike_pending=false
    swing_flash=0
    super._on_death()
func reset_target() -> void:
    super.reset_target()
    provoked=false
    strike_pending=false
    swing_flash=0
    strikes=0
    set_active(active)
