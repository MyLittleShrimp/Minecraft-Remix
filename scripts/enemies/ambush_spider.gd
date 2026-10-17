class_name AmbushSpider
extends SpiderEnemy
## A visible tree ambush: telegraph, commit to a marked landing, then recover.
var perched := true
var warning_left := -1.0
var landing := Vector2.ZERO
var ambushes := 0

func _physics_process(delta: float) -> void:
    if not perched or state == State.DEAD:
        super._physics_process(delta)
        queue_redraw()
        return
    velocity=Vector2.ZERO
    flash_left=maxf(0,flash_left-delta)
    if warning_left<0 and sees_target() and absf(target.position.x-position.x)<185:
        warning_left=0.85
        landing=Vector2(clampf(target.position.x,spawn_point.x-110,spawn_point.x+110),288)
        facing=1 if landing.x>=position.x else -1
        state=State.POUNCE_WARNING
    elif warning_left>=0:
        warning_left-=delta
        if warning_left<=0:
            perched=false
            state=State.POUNCE
            state_left=0.15
            # Constant horizontal commitment; the player can dodge after the cue.
            velocity=Vector2((landing.x-position.x)/0.48,-30)
            ambushes+=1
    visual.queue_redraw()
    queue_redraw()

func _on_damage(event: DamageEvent) -> void:
    perched=false
    warning_left=-1
    super._on_damage(event)
    queue_redraw()

func reset_target() -> void:
    super.reset_target()
    perched=true
    warning_left=-1
    ambushes=0
    queue_redraw()

func _draw() -> void:
    if state==State.DEAD: return
    if perched:
        draw_line(Vector2(0,-48),Vector2(0,-28),Color("b6d6cf"),1)
    if perched and warning_left>=0:
        var spot:=to_local(landing)
        draw_line(spot+Vector2(-25,-2),spot+Vector2(25,-2),Color("ffc88b"),3)
        draw_line(Vector2(0,-14),spot,Color(1,0.77,0.50,0.3),1)
        draw_string(ui_font,spot+Vector2(-29,-12),"落点 · 躲开",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe5b2"))
