class_name GhastEnemy
extends RemixEnemy
signal cue(id: StringName)
enum Flight { DORMANT, READY, CHARGE, FLIGHT, DESCEND, LOW, ASCEND, DEAD }
const HIGH_Y := 104.0
const LOW_Y := 196.0
const CHARGE_SECONDS := 1.0
const LOW_SECONDS := 2.0
var flight: Flight=Flight.DORMANT
var active := false
var timer := 0.0
var pending_shot := false
var ball: GhastFireball
var arena_bounds:=Vector2(320,960)
var cruise_bounds:=Vector2(-INF,INF)
var volley: GhastVolley
var shots:=0
var reflections:=0
var broken_balls:=0
var low_windows:=0
var mark:=Vector2.ZERO

func _ready() -> void:
    super._ready()
    collision_layer=0
    collision_mask=0
    receiver.position=Vector2.ZERO
    receiver.size=Vector2(48,48)
    (receiver.get_child(0) as CollisionShape2D).shape.size=receiver.size
    receiver.collision_layer=0
    visual.set_script(load("res://scripts/enemies/ghast_visual.gd"))

func center() -> Vector2: return global_position
func in_arena(at: Vector2) -> bool: return at.x>=arena_bounds.x+12 and at.x<=arena_bounds.y-12
func can_fire() -> bool:
    return active and health.current>0 and is_instance_valid(target) and not target.dead and in_arena(target.global_position) and on_camera() and clear_line(target_center())
func activate() -> void:
    if active or health.current<=0: return
    active=true
    receiver.set_deferred("collision_layer",16)
    flight=Flight.READY
    timer=0.9

func _physics_process(delta: float) -> void:
    flash_left=maxf(0,flash_left-delta)
    visual.queue_redraw()
    if flight==Flight.DEAD or not active: return
    if not is_instance_valid(target) or target.dead: return
    steps+=delta*3
    timer=maxf(0,timer-delta)
    facing=1 if target.global_position.x>global_position.x else -1
    if not in_arena(target.global_position) or not on_camera():
        pending_shot=false
        retire_ball()
        flight=Flight.READY
        timer=0.9
        return
    match flight:
        Flight.READY:
            # Move toward a visible shot line, keeping a fair gap and room bounds.
            var desired:=clampf(target.global_position.x-facing*180,arena_bounds.x+80,arena_bounds.y-80)
            desired=clampf(desired,cruise_bounds.x,cruise_bounds.y)
            global_position.x=move_toward(global_position.x,desired,65*delta)
            if timer<=0 and can_fire() and (volley==null or volley.claim_warning()):
                flight=Flight.CHARGE
                timer=CHARGE_SECONDS
                mark=target_center()
                cue.emit(&"ghast_warn")
        Flight.CHARGE:
            mark=target_center()
            if not can_fire():
                flight=Flight.READY
                timer=0.6
            elif timer<=0: pending_shot=true
        Flight.FLIGHT:
            # Hold the source still while its ball travels, so reflected aim stays fair.
            if not is_instance_valid(ball) or ball.spent:
                flight=Flight.DESCEND
        Flight.DESCEND:
            global_position.y=move_toward(global_position.y,LOW_Y,120*delta)
            if is_equal_approx(global_position.y,LOW_Y):
                flight=Flight.LOW
                timer=LOW_SECONDS
                low_windows+=1
        Flight.LOW:
            if timer<=0: flight=Flight.ASCEND
        Flight.ASCEND:
            global_position.y=move_toward(global_position.y,HIGH_Y,120*delta)
            if is_equal_approx(global_position.y,HIGH_Y):
                flight=Flight.READY
                timer=0.7

func late_step() -> void:
    if not pending_shot: return
    pending_shot=false
    if not can_fire() or flight!=Flight.CHARGE: return
    ball=GhastFireball.new()
    ball.shooter=self
    ball.arena_bounds=arena_bounds
    ball.position=get_parent().to_local(center()+Vector2(0,12))
    ball.velocity=(mark-(center()+Vector2(0,12))).normalized()*GhastFireball.HOSTILE_SPEED
    ball.event=DamageEvent.create(self,2,3)
    ball.event.set_meta("ghast_fireball",true)
    get_parent().add_child(ball)
    shots+=1
    cue.emit(&"ghast_fire")
    flight=Flight.FLIGHT

func ball_reflected() -> void:
    reflections+=1
    cue.emit(&"ghast_reflect")
func ball_destroyed() -> void:
    broken_balls+=1
    cue.emit(&"hit")
func retire_ball() -> void:
    if is_instance_valid(ball): ball.retire()
func _on_damage(event: DamageEvent) -> void:
    flash_left=0.22
    last_damage=event.amount
    # Telegraph remains vulnerable, but repeated hits cannot cancel every shot.
func _on_death() -> void:
    pending_shot=false
    active=false
    flight=Flight.DEAD
    retire_ball()
    super._on_death()
func reset_target() -> void:
    retire_ball()
    super.reset_target()
    active=false
    flight=Flight.DORMANT
    pending_shot=false
    timer=0
    shots=0
    reflections=0
    broken_balls=0
    low_windows=0
    receiver.set_deferred("collision_layer",0)
