class_name WitchEnemy
extends RemixEnemy
signal phase_changed(phase: int)
signal potion_thrown
var queen := false
var active := true
var second_phase := false
var provoked := false
var cast_poison := false
var next_poison := false
var marks: Array[Vector2] = []
var throw_due := false
var throw_flash := 0.0
var casts_total := 0
var arena_left := 8000.0
var arena_right := 9024.0

func _ready() -> void:
    super._ready()
    visual.set_script(load("res://scripts/enemies/witch_visual.gd"))
    if queen:
        active=false
        receiver.position.y=-28
        receiver.get_child(0).shape.size=Vector2(30,56)
        receiver.collision_layer=0
    state=State.RECOVER
    state_left=0.8
func center() -> Vector2: return global_position+Vector2(0,-28 if queen else -22)
func activate() -> void:
    if active or health.current<=0: return
    active=true
    provoked=true
    receiver.set_deferred("collision_layer",16)
    state=State.RECOVER
    state_left=0.9
func _physics_process(delta: float) -> void:
    flash_left=maxf(0,flash_left-delta)
    throw_flash=maxf(0,throw_flash-delta)
    visual.queue_redraw()
    if not active or state==State.DEAD or not is_instance_valid(target) or target.dead: return
    state_left=maxf(0,state_left-delta)
    hitstun=maxf(0,hitstun-delta)
    velocity.y=minf(700,velocity.y+1500*delta)
    velocity.x=0
    var distance: float=target.global_position.x-global_position.x
    facing=1 if distance>=0 else -1
    var aware: bool=provoked or sees_target()
    if queen and not second_phase and health.current<=data.max_health/2:
        second_phase=true
        _recover(1.2)
        phase_changed.emit(2)
    var visible_attack: bool=on_camera() and absf(center().x-view_camera.global_position.x)<250 and absf(distance)<270
    if aware and not visible_attack:
        # Visibility gates casts, never pursuit of a player able to hit us.
        marks.clear()
        throw_due=false
        state=State.CHASE
        if safe_step(facing): velocity.x=facing*(105 if queen else 72)
        elif is_on_floor() and queen: velocity.y=-340
    elif aware and (hitstun<=0 or queen):
        if state==State.CHASE:
            _recover(0.3)
        elif state==State.AIM:
            if state_left<=0: throw_due=true
        elif state_left<=0:
            _begin_cast()
        elif absf(distance)<115 and safe_step(-facing):
            velocity.x=-facing*(55 if queen else 30)
    elif not aware:
        state=State.RECOVER
        state_left=maxf(state_left,0.3)
    move_and_slide()
    if queen: global_position.x=clampf(global_position.x,arena_left+45,arena_right-45)
    steps+=absf(velocity.x)*delta*0.12
    visual.position=global_position.round()-global_position
    if global_position.y>480: health.queue_damage(DamageEvent.create(self,0,data.max_health))
func _begin_cast() -> void:
    cast_poison=next_poison
    next_poison=not next_poison
    state=State.AIM
    state_left=0.85 if not queen else (0.65 if second_phase else 0.95)
    marks.clear()
    var aim:=target.global_position+Vector2(0,-8)
    var offsets: Array = ([-68.0,0.0,68.0] if second_phase else [-42.0,42.0]) if queen else [0.0]
    for offset in offsets:
        var point:=aim+Vector2(offset,0)
        if queen: point.x=clampf(point.x,arena_left+26,arena_right-26)
        marks.append(point)
func late_step() -> void:
    if not throw_due or health.current<=0 or not active or state!=State.AIM: return
    throw_due=false
    if not on_camera():
        _recover(0.35)
        return
    for mark in marks:
        var bottle:=PotionProjectile.new()
        bottle.position=get_parent().to_local(global_position+Vector2(facing*10,-43 if queen else -35))
        bottle.poisonous=cast_poison
        bottle.radius=34 if queen else 30
        bottle.source=self
        var start: Vector2=get_parent().to_global(bottle.position)
        var flight:=0.8
        bottle.velocity=(mark-start-Vector2(0,0.5*PotionProjectile.GRAVITY*flight*flight))/flight
        get_parent().add_child(bottle)
    casts_total+=1
    potion_thrown.emit()
    throw_flash=0.28
    _recover(1.3 if not queen else (0.85 if second_phase else 1.25))
func _recover(seconds: float) -> void:
    state=State.RECOVER
    state_left=seconds
    marks.clear()
    throw_due=false
func _on_damage(event: DamageEvent) -> void:
    provoked=true
    if queen:
        flash_left=0.25
        last_damage=event.amount
    else:
        super._on_damage(event)
        marks.clear()
        throw_due=false
func reset_target() -> void:
    super.reset_target()
    active=not queen
    provoked=false
    second_phase=false
    next_poison=false
    throw_flash=0
    casts_total=0
    _recover(0.8)
    if queen: receiver.set_deferred("collision_layer",0)
func phase_label() -> String:
    if not active: return "等待进入庭院"
    if state==State.AIM: return ("三连" if second_phase else "双瓶")+("剧毒药水 · 离开绿色落点" if cast_poison else "伤害药水 · 离开红色落点")
    if state==State.CHASE: return "皇后正在靠近"
    return "投掷间隙 · 抓住机会反击"
