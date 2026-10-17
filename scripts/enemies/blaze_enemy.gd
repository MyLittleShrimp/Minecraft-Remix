class_name BlazeEnemy
extends RemixEnemy
## Short two-shot volleys, then a guaranteed low window; finite introduction.
enum Flight { DORMANT, READY, CHARGE, BURST, DESCEND, LOW, ASCEND, DEAD }
const HIGH_Y:=132.0
const LOW_Y:=244.0
var cool_behind_cover:=false
var flight:=Flight.DORMANT
var active:=false
var arena_bounds:=Vector2(8256,8896)
var timer:=0.0
var mark:=Vector2.ZERO
var pending_shot:=false
var volley_count:=0
var shots:=0
var low_windows:=0
var reflections:=0
var broken_balls:=0
var balls: Array[GhastFireball]=[]
func _ready() -> void:
    super._ready()
    collision_layer=0
    collision_mask=0
    receiver.position=Vector2.ZERO
    receiver.size=Vector2(28,36)
    receiver.get_child(0).shape.size=receiver.size
    receiver.collision_layer=0
    visual.set_script(load("res://scripts/enemies/blaze_visual.gd"))
func center() -> Vector2: return global_position
func can_fire() -> bool:
    return active and health.current>0 and not target.dead and target.position.x>arena_bounds.x and target.position.x<arena_bounds.y and on_camera() and clear_line(target_center())
func activate() -> void:
    if active or health.current<=0: return
    active=true
    flight=Flight.READY
    timer=1.0
    receiver.set_deferred("collision_layer",16)
func _physics_process(delta: float) -> void:
    flash_left=maxf(0,flash_left-delta)
    visual.queue_redraw()
    if not active or flight==Flight.DEAD or target.dead: return
    steps+=delta*3
    timer=maxf(0,timer-delta)
    facing=1 if target.position.x>position.x else -1
    if not can_fire():
        pending_shot=false
        if flight in [Flight.CHARGE,Flight.BURST]:
            flight=Flight.DESCEND
        # Fortress pillars should block shots, not freeze an already-started cooldown.
        if not cool_behind_cover or not flight in [Flight.DESCEND,Flight.LOW,Flight.ASCEND] or target.position.x<=arena_bounds.x or target.position.x>=arena_bounds.y: return
    match flight:
        Flight.READY:
            if timer<=0:
                flight=Flight.CHARGE
                timer=0.9
                mark=target_center()
        Flight.CHARGE:
            # Track only during the visible tell; the two-shot burst is committed.
            mark=target_center()
            if timer<=0:
                volley_count=0
                flight=Flight.BURST
                pending_shot=true
        Flight.BURST:
            if timer<=0 and volley_count<2: pending_shot=true
            elif volley_count>=2 and timer<=0: flight=Flight.DESCEND
        Flight.DESCEND:
            position.y=move_toward(position.y,LOW_Y,160*delta)
            if is_equal_approx(position.y,LOW_Y):
                flight=Flight.LOW
                timer=2.2
                low_windows+=1
        Flight.LOW:
            if timer<=0: flight=Flight.ASCEND
        Flight.ASCEND:
            position.y=move_toward(position.y,HIGH_Y,160*delta)
            if is_equal_approx(position.y,HIGH_Y):
                flight=Flight.READY
                timer=0.7
func late_step() -> void:
    if not pending_shot: return
    pending_shot=false
    if not can_fire() or flight!=Flight.BURST or volley_count>=2: return
    var ball:=GhastFireball.new()
    ball.shooter=self
    ball.arena_bounds=arena_bounds
    ball.position=center()+Vector2(0,10)
    ball.velocity=(mark-ball.position).normalized()*200
    ball.event=DamageEvent.create(self,2,2)
    ball.event.set_meta("blaze_fireball",true)
    get_parent().add_child(ball)
    balls.append(ball)
    balls=balls.filter(func(b) -> bool: return is_instance_valid(b) and not b.spent)
    volley_count+=1
    shots+=1
    timer=0.32
func ball_reflected() -> void: reflections+=1
func ball_destroyed() -> void: broken_balls+=1
func clear_balls() -> void:
    for ball in balls:
        if is_instance_valid(ball): ball.retire()
    balls.clear()
func _on_damage(event: DamageEvent) -> void:
    flash_left=0.25
    last_damage=event.amount
    hitstun=0
func _on_death() -> void:
    pending_shot=false
    active=false
    flight=Flight.DEAD
    clear_balls()
    super._on_death()
func reset_target() -> void:
    clear_balls()
    super.reset_target()
    active=false
    flight=Flight.DORMANT
    timer=0
    pending_shot=false
    volley_count=0
    shots=0
    low_windows=0
    reflections=0
    broken_balls=0
    receiver.set_deferred("collision_layer",0)
