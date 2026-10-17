class_name EndermanEnemy
extends RemixEnemy
## No contact damage or projectile immunity. Both ends of a teleport stay readable.
const WARNING := 0.7
const MATERIALIZE := 0.35
const TELEPORT_COOLDOWN := 3.0
const REACH := 58.0
const MAX_TELEPORT_DISTANCE := 360.0
var guard_mode := false
var encounter_enabled := true
var encounter_bounds := Vector2(-INF,INF)
var provoked := false
var warp_left := -1.0
var warp_to := Vector2.ZERO
var warp_cooldown := 0.0
var strike_pending := false
var strike_flash := 0.0
var teleports := 0
var strikes := 0

func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/enderman_visual.gd"))
    var body := get_child(0) as CollisionShape2D
    body.position.y=-30
    body.shape.size=Vector2(20,60)
    receiver.position.y=-30
    receiver.size=Vector2(20,60)
    (receiver.get_child(0) as CollisionShape2D).shape.size=receiver.size
    if guard_mode:
        encounter_enabled=false
        receiver.collision_layer=0

func activate_guard() -> void:
    if encounter_enabled or health.current<=0: return
    encounter_enabled=true
    receiver.set_deferred("collision_layer",16)
    provoked=true
    state=State.RECOVER
    state_left=0.9 # Clear warning after the player enters, without locking controls.

func inside_encounter(at: Vector2,margin: float=0) -> bool:
    return at.x>=encounter_bounds.x+margin and at.x<=encounter_bounds.y-margin

func center() -> Vector2: return global_position+Vector2(0,-30)

func _physics_process(delta: float) -> void:
    warp_cooldown=maxf(0,warp_cooldown-delta)
    strike_flash=maxf(0,strike_flash-delta)
    super._physics_process(delta)

func landing_valid(at: Vector2) -> bool:
    if not is_instance_valid(target): return false
    if not inside_encounter(at,24): return false
    # Leave room to step off the marker; reject walls, edges, tiny ledges and bodies.
    if Rect2(at+Vector2(-22,-64),Vector2(44,64)).intersects(Rect2(target.global_position+Vector2(-12,-44),Vector2(24,44))): return false
    var space:=get_world_2d().direct_space_state
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(26,60)
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,at+Vector2(0,-31))
    query.collision_mask=3
    if not space.intersect_shape(query).is_empty(): return false
    for dx in [-24.0,0.0,24.0]:
        var ray:=PhysicsRayQueryParameters2D.create(at+Vector2(dx,-3),at+Vector2(dx,5),3)
        if space.intersect_ray(ray).is_empty(): return false
    for other in get_tree().get_nodes_in_group("enemies"):
        if other==self or other.health.current<=0: continue
        if other.global_position.distance_to(at)<36: return false
    return true

func choose_landing() -> Vector2:
    var space:=get_world_2d().direct_space_state
    # Try both sides and multiple distances; raycast derives the real floor height.
    for dx in [-52.0,52.0,-80.0,80.0,-112.0,112.0]:
        var from:=target.global_position+Vector2(dx,-18)
        var ray:=PhysicsRayQueryParameters2D.create(from,from+Vector2(0,150),3)
        var hit:=space.intersect_ray(ray)
        if hit.is_empty(): continue
        var at: Vector2=hit.position
        if at.distance_to(global_position)>MAX_TELEPORT_DISTANCE: continue
        if is_instance_valid(view_camera) and absf(at.x-view_camera.global_position.x)>280: continue
        if landing_valid(at): return at
    return Vector2.INF

func start_teleport() -> bool:
    if not encounter_enabled or warp_cooldown>0 or not provoked or health.current<=0: return false
    if not is_instance_valid(target) or not inside_encounter(target.global_position) or not on_camera(): return false
    var at:=choose_landing()
    warp_cooldown=TELEPORT_COOLDOWN
    if not at.is_finite():
        recover()
        return false
    warp_to=at
    warp_left=WARNING
    velocity=Vector2.ZERO
    state=State.CHASE
    return true

func recover() -> void:
    warp_left=-1
    strike_pending=false
    state=State.RECOVER
    state_left=1.0
    velocity.x=0

func _tick_walker() -> void:
    velocity.x=0
    if not encounter_enabled:
        state=State.PATROL
        return
    if not is_instance_valid(target) or target.dead:
        recover()
        return
    if warp_left>=0:
        warp_left=maxf(0,warp_left-get_physics_process_delta_time())
        if warp_left<=0:
            warp_left=-1
            # Player can occupy the marker during the tell. Cancel, never crush them.
            if not inside_encounter(target.global_position) or not landing_valid(warp_to) or not on_camera():
                recover()
                return
            global_position=warp_to
            velocity=Vector2.ZERO
            teleports+=1
            facing=1 if target.global_position.x>global_position.x else -1
            state=State.AIM
            state_left=MATERIALIZE
        return
    if state==State.AIM:
        if state_left<=0:
            recover()
            strike_pending=true
        return
    if state==State.RECOVER and state_left>0: return
    if not provoked:
        state=State.PATROL
        return
    if not inside_encounter(target.global_position):
        recover()
        return
    facing=1 if target.global_position.x>global_position.x else -1
    if warp_cooldown<=0 and start_teleport(): return
    if absf(target.global_position.x-global_position.x)<REACH and absf(target.global_position.y-global_position.y)<42 and clear_line(target_center()):
        state=State.AIM
        state_left=0.55
    else:
        state=State.CHASE
        velocity.x=facing*data.chase_speed if safe_step(facing) and inside_encounter(global_position+Vector2(facing*24,0)) else 0.0

func late_step() -> void:
    if not strike_pending: return
    strike_pending=false
    if not encounter_enabled or health.current<=0 or target.dead: return
    strikes+=1
    strike_flash=0.18
    var shape:=RectangleShape2D.new()
    shape.size=Vector2(REACH,48)
    var query:=PhysicsShapeQueryParameters2D.new()
    query.shape=shape
    query.transform=Transform2D(0,center()+Vector2(facing*REACH/2,0))
    query.collision_mask=8
    query.collide_with_areas=true
    query.collide_with_bodies=false
    var event:=DamageEvent.create(self,2,3,Vector2(facing*140,-100))
    for hit in get_world_2d().direct_space_state.intersect_shape(query):
        var victim:=hit.collider as CombatHurtbox
        if victim!=null and clear_line(victim.global_position): victim.receive(event)

func _on_damage(event: DamageEvent) -> void:
    if not encounter_enabled: return
    var first_hit:=not provoked
    provoked=true
    flash_left=0.25
    last_damage=event.amount
    # Telegraphs remain vulnerable but committed. Repeated sword hits must not
    # restart recovery forever and suppress the enemy's entire unique move.
    if first_hit:
        state=State.RECOVER
        state_left=0.25
        hitstun=0.12
    elif warp_left<0 and state!=State.AIM:
        hitstun=0.08

func _on_death() -> void:
    warp_left=-1
    strike_pending=false
    super._on_death()

func reset_target() -> void:
    super.reset_target()
    provoked=false
    warp_left=-1
    warp_cooldown=0
    strike_pending=false
    strike_flash=0
    teleports=0
    strikes=0
    encounter_enabled=not guard_mode
    receiver.set_deferred("collision_layer",16 if encounter_enabled else 0)
